# Store orders, products, and customs

All paths are relative to `https://ship.stallion.ca/api/v5`. Check the current
operation schema and carrier requirements before building a cross-border flow.

## Ship an imported order

1. [`GET /orders`](https://docs.stallion.ca/openapi/orders/paths/~1orders/get.md)
   (`orders:read` or `orders:write`): filter with `status=awaiting_shipment`;
   use `store_id` or `search` to narrow the search. Save the Stallion order's
   `data[].id` as `store_order_id`, not the store's order number or display ID.
2. [`POST /shipments`](https://docs.stallion.ca/openapi/shipments/paths/~1shipments/post.md)
   (`shipments:write`): send `{"shipments":[{"store_order_id":12345,"packages":[...]}]}`.
   The recipient and items default to the imported values. Supplying
   `to_address` or `items` replaces the corresponding value entirely; no
   partial merge. `order_id` alone is just a reference and will not link an
   order. Check `data.errors` even on `201`, and save the result's `id` and
   `store_id`. A second create for the same order conflicts; reconcile with
   the existing shipment instead of creating an unlinked duplicate.
3. Quote the draft and buy via `POST /labels/{shipment_id}` (see
   [Shipping](shipping.md)). On a linked shipment, label purchase can fulfill
   the whole store order and push tracking according to that store's
   fulfillment settings. Do not independently mark it fulfilled unless the
   workflow explicitly calls for that. Voiding can cancel fulfillment where
   the store supports it. If the tracking push fails, inspect the store link
   and settings; don't buy another label to retry fulfillment.

`POST /labels` also accepts `store_order_id` in its flat body. If it returns
`402` or `422` with `error.details.shipment_id`, preserve the existing shipment
and recover as described in [Shipping](shipping.md). A `store_order_id` does
not populate a `POST /rates` quote; use actual recipient and package details
or quote the linked draft.

Use `POST /orders`, `PUT /orders/{order_id}`, and `DELETE /orders/{order_id}`
(`orders:write`) for pre-shipment order management. Deletion is blocked when
linked to a non-voided shipment. Direct shipment creation from an order does
not run automation rules or box presets. [Scheduled imports](https://docs.stallion.ca/openapi/crons.md)
(`automation:write` for `POST /crons/{cron_id}/run`) can sync stores, create
batches, and buy live labels when `auto_purchase` is enabled. An asynchronous
store sync can return `batch_id: null` before the batch exists; inspect
`last_batch_id` on the scheduled import instead of triggering it again.

## Product catalog and classification

Use the [Products API](https://docs.stallion.ca/openapi/products.md), keyed by
SKU. `GET /products` and `GET /products/{sku}` accept `products:read` or
`products:write`; create, update, and delete require `products:write`. Many
products are already created by store import. A duplicate create may return
`409`; inspect the existing product and its variants before updating the
resolved SKU. Approved or Ineligible DDP products have locked HS/origin values.
Don't try to bypass validation or silently overwrite declarations.

1. Use `POST /products` or `PUT /products/{sku}` to store verified description,
   value, origin, and other customs fields. Do not infer or fabricate them.
2. Submit or retry DDP classification with
   [`POST /products/{sku}/classify`](https://docs.stallion.ca/openapi/products/paths/~1products~1%7Bsku%7D~1classify/post.md)
   (`products:classify`). The schema requires at least one of `hts_code`,
   `country_of_origin`, or `unit_value`. Read the returned product's
   `ddp_status` and classification; route decisions to a user authorized to
   review the customs declaration.
3. Use [`POST /products/{sku}/approve-classification`](https://docs.stallion.ca/openapi/products/paths/~1products~1%7Bsku%7D~1approve-classification/post.md)
   (`products:approve`) with `approved`, optional `hs_code` to confirm the
   code reviewed, and `rejection_reason` when rejecting. For `Manufacturer Failed`,
   inspect the record and use the documented `POST /products/{sku}/verify-manufacturer`
   retry (the bundle lists both `products:classify` and `products:approve` in
   one security requirement). Classification and manufacturer lookup document
   `Idempotency-Key`. The unkeyed `/products/classify` and
   `/products/verify-manufacturer` in the workflow guide are not listed in the
   current v5 bundle; don't implement against them without confirmation.

## Customs and CUSMA (USMCA)

- Use verified customs `items[]` for the shipment: title, quantity, declared
  value and currency, description, origin, HS code, and SKU as required for
  the route/service. Read `CustomsItem` and the exact rate and label operations
  for requirements and linked-product defaults. Set a verified inline
  `tax_identifier` only when applicable (e.g. VAT or IOSS). A quote does not
  prove the declaration will pass at purchase time.
- EU product identifiers and exemptions vary by carrier and effective date.
  Check current `merchant_product_id` (M-PID),
  `manufacturer_product_id` (NS-PID), and `standard_product_id` (S-PID) rules
  before buying; preserve leading zeros in IDs. Never assume a missing ID or
  an exemption accepted by one service will work for another.
- CUSMA certificates are submitted and reviewed in the dashboard. The product
  API reports state, not a certificate-creation endpoint. For a workflow that
  requires CUSMA coverage, gate on **`data.cusma.active_for_duty === true`**
  for each relevant product. `cusma.status` and `ddp_status` are not the gate:
  an expiring or inherited certificate may still cover the product, and an
  approved-looking status can still lack coverage if the DDP record is not
  eligible. If coverage is absent, hold or use a separately authorized
  non-CUSMA workflow; do not claim preferential duty treatment.

Sources: [Common Workflows](https://docs.stallion.ca/common-workflows) and
[Store Settings and Fulfillment](https://help.stallion.ca/article/store-settings-and-fulfillment).
