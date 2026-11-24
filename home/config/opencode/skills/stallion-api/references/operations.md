# Operations, billing, LTL, and migration

All API paths are relative to `https://ship.stallion.ca/api/v5`. Never use a
production write as a test. Use the [v5 OpenAPI](https://docs.stallion.ca/openapi)
to confirm scopes, request fields, and response shapes for each operation.

## Idempotency and reconciliation

- For a supported mutation, generate and persist one `Idempotency-Key` per
  logical operation **before** sending it. Persist the method, path, and
  original request or reconstruct it deterministically. Persist only data needed
  for replay, protect PII in either case, and purge payloads after retry and
  reconciliation finish.
  Use a local uniqueness constraint or equivalent to prevent concurrent workers
  generating different keys for the same purchase or booking.
- Within 24 hours, retry the exact same operation and body with the same key.
  A cached replay carries `Idempotent-Replay: true`; the same key with a
  different body returns `409 idempotency_conflict`. `5xx` responses are not
  cached. A timeout, transport error, or `5xx` can occur after an upstream side
  effect. Reconcile before retrying any money-moving operation in those cases
  unless the provider explicitly guarantees deduplication for that failure;
  retain the original key. If the outcome remains uncertain, stop for review.
- The bundle explicitly documents the header for shipment creation, label
  purchases, pickups, LTL bookings, credit top-ups, and per-SKU classification
  and manufacturer verification. For other writes, check the current operation
  before relying on replay protection; the workflow guide's blanket claim is
  broader than the operation schemas. Don't generate a new key to bypass an
  error on an operation whose outcome is unknown.
- If the response cannot be decoded, the replay window expired, retries are
  exhausted, or the endpoint has no confirmed retry guarantee, reconcile with
  the shipment, purchased label, batch, or billing ledger before trying
  anything new. A cached replay can include an expired signed URL: re-fetch the
  document without buying it again. For bulk creates, a corrected subset is a
  new operation: use a new key only after identifying the failed rows.

## Error handling

| Signal | Action |
| --- | --- |
| `401` / `unauthenticated`, `token_revoked`, `token_expired` | Check the production API v5 credential and Bearer header. A key working on v5 production is not a v3/v4 key merely because another environment rejected it with a generic message. Don't print the token. |
| `403` / `scope_missing` | Compare the token's scopes to the operation, and request only the missing access. Account restrictions may also result in `403`. |
| HTML `403` with `error code: 1010` | Cloudflare blocked the request before it reached Stallion. Verify the Bearer header and use a named integration `User-Agent`; don't treat HTML as a JSON auth error. |
| `402` / `insufficient_credits` | Check the account ledger. Don't automatically top up without an authorized billing workflow. Check for an existing shipment ID on a combined label purchase error. |
| `409` | Distinguish `idempotency_conflict` from other state conflicts. Inspect current state and any `Retry-After`; do not blindly retry. |
| `422` / `validation_failed` or `rate_failed` | Surface field errors or carrier restrictions. Correct the data or select a valid service; don't loop on invalid input. |
| `429` / `too_many_requests` | Honor `Retry-After` and the documented `error.details.retry_after_seconds` fallback. Use capped exponential backoff with jitter and a retry budget. The published general limit is 600 requests per minute per authenticated user; some tracking lookups have stricter limits. |
| Timeout, transport error, or `5xx` | Bounded retries for non-mutating requests; for money-moving writes reconcile first unless deduplication for that failure is explicitly guaranteed. For other mutations use confirmed idempotency or reconcile first. If persistent, report HTTP status, stable code, and request ID if present, without credentials or PII. |

## Credits and financial reporting

Use the current [Credits API](https://docs.stallion.ca/openapi/credits.md), not
the `/credits/...` examples in the workflow guide:

1. `GET /billing/credits/balance` (`credits:read` or `credits:write`) reports
   `data.balances`, `billing_currency_mode`, and `top_up_currencies`. Legacy
   `data.balance` and `data.currency` refer to CAD even on multi-ledger accounts.
2. If an authorized top-up is needed, `GET /billing/payment-methods` can list
   saved methods with the same scopes. `POST /billing/credits` (`credits:write`)
   actually charges a saved payment method. Body: `amount` (at most two decimal
   places), optional `currency` (defaults to CAD), optional `payment_method_id`
   (defaults to the account's default). Check `top_up_currencies` before using
   USD; USD top-ups are card-only. Use a durable `Idempotency-Key`; never retry a
   top-up with a new key while its outcome is unknown.
3. [`GET /billing/transactions`](https://docs.stallion.ca/openapi/transactions.md)
   (`billing:read`) is the ledger for charges, refunds, top-ups, and adjustments.
   Reconcile by transaction ID, currency, and `shipment_id` where present;
   don't use a rate quote or a shipment's CAD-equivalent `total_paid` as a USD
   ledger entry. [Statements](https://docs.stallion.ca/openapi/statements.md)
   use `billing:read` and return short-lived signed PDF/CSV links on download
   routes.

## LTL freight

Use [LTL operations](https://docs.stallion.ca/openapi/ltl-shipping.md) for
palletized freight, not parcel pickups:

1. `POST /ltl/quote` (`ltl:read` or `ltl:write`) is stateless. Supply origin,
   destination, pallets, accessorials, and intended pickup date/window as
   applicable. `pickup.ready_at` / `close_at` use local `HH:MM`; quote the same
   window you intend to book. Distinguish `validation_failed` from `rate_failed`.
2. `POST /ltl/shipments` (`ltl:write`) books and charges. Send the quote body
   plus the selected `service` and required booking data, including
   `pickup_date` and a description for every pallet. Use an `Idempotency-Key`.
   Persist `data.id`, the bill-of-lading number, and pickup confirmation; a PRO
   number may only arrive later.
3. `GET /ltl/shipments/{shipment_id}` (`ltl:read` or `ltl:write`) returns state
   and a fresh signed `bol_url` (30 minutes). Read `charges.adjustments` for
   later carrier adjustments and reconcile with `/billing/transactions`.
   `DELETE /ltl/shipments/{shipment_id}` (`ltl:write`) voids eligible bookings
   while still `booked`. Don't assume voidability after handoff.

## Migrate from v4

V4 remains live; don't mix its contract with v5. For an authorized migration,
issue a scoped v5 token, move to the dedicated v5 resource routes, and update
request/response adapters: `packages[]`, bulk `POST /shipments`, paginated list
responses, and `error.code` handling. Some reads accept legacy `ship_code`;
use numeric IDs on v5 mutation routes whose schema requires them. Stored
shipment costs can be null before purchase (v4 used zero); don't substitute a
live re-quote. Verify the flow with fixtures before replacing a live integration.

Sources: [Errors & Idempotency](https://docs.stallion.ca/errors-idempotency),
[Migrating from v4](https://docs.stallion.ca/migrating-from-v4), and
[Stallion status](https://status.stallion.ca/).
