# Parcel shipping, rates, and tracking

All paths below are relative to `https://ship.stallion.ca/api/v5`. Read the
linked operation before generating code; see [Operations](operations.md) for
retry rules and [Commerce](commerce.md) for imported orders and customs.

## Choose the right quote

| Need | Endpoint | Input |
| --- | --- | --- |
| Early checkout estimate | [`POST /rates/estimate`](https://docs.stallion.ca/openapi/rates/paths/~1rates~1estimate/post.md) | `to_address.country_code`, `to_address.postal_code`, `packages[]`; send actual package weight and dimensions to avoid nominal defaults. No street address needed. |
| Quote without a draft | [`POST /rates`](https://docs.stallion.ca/openapi/rates/paths/~1rates/post.md) | One flat shipment object with `to_address` and `packages[]`. Not a `shipments` wrapper; `store_order_id` is ignored when rating. |
| Re-quote an existing draft | [`GET /rates/{shipment_id}`](https://docs.stallion.ca/openapi/rates/paths/~1rates~1%7Bshipment_id%7D/get.md) | Numeric shipment ID; this is a live quote, not the purchased rate. |

All three require `rates:read`. Neither POST quote creates a shipment or buys
a label. The estimator may backfill cosmetic address fields; don't promise its
price or service availability once the full address is known. `region` on
`POST /rates` is the Stallion drop-off region, not `to_address.province_code`.
Use `type: regular` for regular parcel routing or `type: courier` for courier
routing, including a later carrier pickup. One `packages[]` entry per physical
package. Weight units: `lbs`, `kg`, `oz`, `g`; dimension units: `in`, `cm`.
For cross-border quotes, provide the documented customs fields for the lane.

Example JSON for a `POST /rates` mock; synthetic recipient, not a live smoke test:

```json
{
  "type": "regular",
  "region": "QC",
  "to_address": {
    "name": "Example Recipient",
    "address1": "123 Example Street",
    "city": "Toronto",
    "province_code": "ON",
    "postal_code": "M5V 2T6",
    "country_code": "CA",
    "is_residential": true
  },
  "packages": [
    {
      "weight": 5,
      "weight_unit": "lbs",
      "length": 10,
      "width": 7,
      "height": 2,
      "size_unit": "in",
      "package_contents": "Printed acrylic box"
    }
  ],
  "timeout": 7
}
```

Read rates from `data[]`. Preserve the returned `service` exactly (including
codes like `pt.140`); don't substitute `carrier`, `service_name`, or the numeric
`postage_type_id`. Use provider `total` and `currency`; don't recompute price
from partial line items. `estimated_delivery_days` may be null and is not a
promise. The optional `services` filter uses these same slugs. Optional
`tier_pricing` is an account-enabled comparison, not the rate used to buy.

A `200` can contain zero rates or only partial results. Inspect
`meta.excluded_services[].reason` before deciding what to show or retry:

| Reason | Meaning and handling |
| --- | --- |
| `carrier_timeout`, `carrier_error` | Potentially transient. Offer a bounded retry; a longer carrier timeout may help. |
| `no_rate_for_lane` | No rate for this service on this shipment. Don't retry it as a timeout. |
| `service_unavailable` | Service not available to the account or origin region. |
| `requirements_not_met`, `declared_value_exceeds_limit`, `ddu_disabled` | Check the shipment or account constraints; retry only after correcting them. |
| Unknown | Keep any valid rates; don't infer lane coverage or retry indefinitely. |

`timeout` is seconds (1–25), set in the POST body or GET query;
`meta.timeout_seconds` reports the applied value. Set the outbound HTTP
request deadline above the carrier timeout plus network overhead when the app's
latency budget allows. Use a lower carrier timeout for latency-sensitive UIs.
Before creating a shipment, optionally call [`POST /addresses/validate`](https://docs.stallion.ca/openapi/addresses/paths/~1addresses~1validate/post.md)
(`addresses:validate`); a `200` with `valid: false` is not a validated address.

## Create a draft, then buy or retrieve its label

1. [`POST /shipments`](https://docs.stallion.ca/openapi/shipments/paths/~1shipments/post.md)
   (`shipments:write`): send `{"shipments":[{...}]}`, even for one shipment.
   `201` can be a partial success: persist `data.shipments[].id`, inspect
   `data.errors[]` and its zero-based `index`, and don't recreate successful
   rows. Successes preserve input order with failures omitted. Use `ship_code`
   as a human reference, not as the numeric ID for buying a label.
2. `GET /rates/{shipment_id}` (`rates:read`): choose a current returned
   `service`. Keep quotes separate from what was actually charged; shipment
   `rate`, `tax`, and `total_paid` are null until purchase, and on split
   multibox child rows charged on the lead shipment.
3. [`POST /labels/{shipment_id}`](https://docs.stallion.ca/openapi/labels/paths/~1labels~1%7Bshipment_id%7D/post.md)
   (`labels:create`): send `{"service":"<returned service>"}` and a durable
   `Idempotency-Key`. This debits credits and may push store fulfillment. Pass
   an explicit service for user-selected purchases. Omitting it can use the
   draft's selection or buy the cheapest tracked rate. Use `cheapest_tracked`
   or `cheapest_express_tracked` only for intentional automatic selection.
4. [`GET /labels/{shipment_id}`](https://docs.stallion.ca/openapi/labels/paths/~1labels~1%7Bshipment_id%7D/get.md)
   (`labels:create` or `shipments:read`): retrieve the existing label or refresh
   the signed `label_url` (30 minutes); don't repurchase to print again.
   `label_format: png` or `zpl` can return base64 `label`; keep the PDF URL as a
   fallback if conversion is unavailable. GET takes `label_format` in the query.

The OpenAPI models the label success as `Label` with `shipment_id`, `ship_code`,
`tracking_number`, `label_url`, and purchased `rate`; the workflow guide refers
to `data.label_url` and `data.tracking_code`. Start from the operation schema
and confirm the envelope and tracking field with a redacted response before
relying on them. If a purchase returned an unexpected success shape, reconcile
it with shipment/label reads; don't retry just because decoding failed. A
`Shipment` documents `tracking_code` as an alias of `tracking_number`.

[`POST /labels`](https://docs.stallion.ca/openapi/labels/paths/~1labels/post.md)
(`labels:create`) creates and buys in one call with a flat shipment body. The
separate draft flow makes it easier to store the ID before purchasing and
reconcile uncertain outcomes. If the combined call returns `402` or `422` with
`error.details.shipment_id`, preserve that ID. The carrier may already hold a
booking: address the reported condition, reconcile, and resume via
`POST /labels/{shipment_id}`, not another `POST /labels`. This is a new request
with its own key, not a replay of the combined call.

Fetch signed documents only after authorizing access to the related shipment.
Treat links as sensitive and short-lived. Never forward Stallion credentials to
storage URLs. If proxying a download, validate its expected HTTPS origin and
handle redirects explicitly instead of fetching arbitrary URLs supplied by a
client. Voiding a parcel uses `POST /shipments/{shipment_id}/void`
(`shipments:void`); check voidability and don't promise an immediate refund.

## Pickups and batches

- [`POST /pickups`](https://docs.stallion.ca/openapi/pickups/paths/~1pickups/post.md)
  (`pickups:write`) books a live pickup for an eligible courier shipment with
  purchased postage. The operation's `PickupCreate` body requires singular
  `shipment_id`, `pickup_date`, `ready_at`, and `close_at` (local `HH:MM`); don't
  use the guide's `shipment_ids` array. Availability depends on carrier,
  location, and time. Persist `data.id`; `DELETE /pickups/{pickup_id}` cancels
  when allowed and returns `204`.
- [Batches](https://docs.stallion.ca/openapi/batches.md): `POST /batches` with
  `name` and `shipment_ids` (`batches:write`), then
  `POST /batches/{batch_id}/process` (`batches:process`) **buys labels** and
  returns `202`. Poll `GET /batches/{batch_id}` with capped backoff and use
  `GET /batches/{batch_id}/errors` for per-shipment failures (`batches:read`).
  Reconcile state after a lost response; don't reprocess blindly.
- If all labels were bought individually, use `POST /batches/{batch_id}/close`
  (`batches:process` or `batches:write`) instead of `process`. Closing doesn't
  buy anything. `422` can list `error.details.unlabelled_shipment_ids`. When a
  `closeout_id` exists, fetch its signed PDF URL with
  `GET /batches/{batch_id}/closeout` (`batches:read`). Some batches don't need a
  closeout. `GET /locations` lists drop-off sites; `GET /postage-types` lists
  account services, not a guarantee of rates for every lane.

## Tracking and delivery proofs

- [Tracking](https://docs.stallion.ca/openapi/tracking.md): use
  `GET /tracking/{tracking_number}` with a carrier tracking number or Stallion
  `ship_code`. For reads, use `tracking:read` or `tracking:subscribe`. Ordinary
  tokens are account-scoped; `404` can mean unknown or not owned. Do not try to
  distinguish those cases. `tracking:read-any` is Stallion-admin-issued only;
  don't plan on it for ordinary apps.
- `POST /tracking/{tracking_number}/subscribe` and `DELETE` on the same path
  require `tracking:subscribe` and return `204`. Register a URL for the
  **Tracking Status Changed** event in **Settings → Integrations → Custom
  Webhooks**. Receipt of a webhook alone does not establish authenticity: use
  only a verification mechanism confirmed by Stallion. Don't guess signing
  headers. If authenticated delivery cannot be verified, use bounded polling
  or treat notifications only as hints and re-fetch trusted state for a known
  shipment before changing application state. Apply a bounded polling budget
  to hint-triggered reads and coalesce hints per shipment to prevent quota
  exhaustion. Validate input and handle duplicate or out-of-order events.
- `POST /tracking/order` looks up by exact order number plus full destination
  postal/ZIP code. Keep lookup results private; don't cache them or defeat the
  documented attempt limits. Preserve the generic `404` for invalid, unknown,
  or unauthorized pairs.
- `GET /tracking/{tracking_number}/proof-of-delivery` can return private photos,
  signatures, or PDFs via short-lived links. Check `status` and `mime_type`.
  This GET does not verify the recipient. Use app-level authorization; the
  `/proof-of-delivery/verify` POST with full recipient postal code is documented
  for Intelcom only. Its failure is intentionally a generic `404`.
