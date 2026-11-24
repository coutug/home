---
name: stallion-api
description: >-
  Plan, build, review, migrate, or troubleshoot Stallion Express API v5
  integrations. Use for shipping rates and checkout estimates, parcel drafts and
  label purchases, tracking and webhooks, courier pickups, batches, store
  fulfillment, customs products and CUSMA, LTL freight, billing, or Stallion
  token and retry problems.
---

# Stallion Express API v5

Stallion Express serves Canadian shippers. Use its v5 REST API to quote rates,
create shipments, buy labels, track parcels, and connect shipping to orders.
Carrier coverage, prices, and capabilities depend on the account, origin region,
destination, and package. The [public website](https://stallion.ca/) explains
available services; use the API contract for implementation.

## Production only

Use **`https://ship.stallion.ca/api/v5`** for all Stallion API requests. Do not
switch hosts or fall back to another version when a request fails. Public docs
at `docs.stallion.ca` are for research; never send credentials there.

Treat API calls as live operations. Use a mocked HTTP transport and synthetic
fixtures for development, tests, and CI; do not use production for validation.
An integration request is not authorization to execute live calls. If the user
explicitly requests a live operation, stay within that request: creating a draft
changes the account, buying labels can debit credits and fulfill store orders,
and bookings, cancellations, top-ups, and automation have real effects.

## Start here

1. Identify the desired workflow, account/drop-off region, domestic vs.
   cross-border lane, and whether the app should quote only or also buy/fulfill.
2. Read the matching local reference below. Then open the exact method and path
   in the [v5 OpenAPI reference](https://docs.stallion.ca/openapi) or inspect its
   [JSON bundle](https://docs.stallion.ca/_bundle/@v5/openapi.json?download=).
   Check scope alternatives, body, status codes, success shape, pagination, and
   `Idempotency-Key` support. Use the operation-level contract over narrative
   examples when they disagree. If a material discrepancy remains, flag it and
   request a redacted response or vendor confirmation; don't invent a contract.
3. Implement a server-side client with a fixed HTTPS origin, bounded timeouts,
   input/output validation, and endpoint-specific error handling. Keep order,
   shipment, batch, and tracking identifiers distinct. Before serving data or
   mutating state, verify the caller's permission and tenant access to every
   affected resource (including batch members). A shared Stallion token does
   not enforce your app's tenant boundaries or authorize spending and fulfillment.
4. Verify request shapes and failure recovery with mocks. State which calls
   would change state, incur cost, or send data to a carrier or store.

| Task | Read |
| --- | --- |
| Quote or estimate rates; create, label, track, pick up, or batch parcels | [Shipping](references/shipping.md) |
| Link imported orders; manage products, DDP classification, or CUSMA | [Commerce](references/commerce.md) |
| Handle retries and API errors; use credits, billing, LTL, or migrate from v4 | [Operations](references/operations.md) |

## Authentication and HTTP basics

- Create a production token in **Settings → Integrations → API**, selecting
  **API V5**. Use a scoped personal access token, not a v3/v4 key or dashboard
  cookies. Use only the required scopes; a quote-only client needs `rates:read`.
  Keep token-management credentials separate from runtime credentials.
- Load the token from server-side secret configuration (for example
  `STALLION_TOKEN`). Never put it in source, browser code, URLs, logs, shell
  traces, or support messages. Redact recipient information and signed document
  URLs from logs and fixtures. Disable redirects for authenticated API calls;
  never forward the Bearer token to a download URL or to any other origin.
- Authorize access to the parent resource before returning or fetching any
  signed document URL, including labels, closeouts, delivery proofs, bills of
  lading, and statements. Accept only API-returned URLs on expected HTTPS
  origins; disable redirects or validate every redirect hop against that policy.
- Send `Authorization: Bearer <token>`, `Accept: application/json`, a named
  `User-Agent` such as `MyShippingApp/1.0`, and `Content-Type: application/json`
  when sending JSON. A `401 unauthenticated` means the token was not accepted;
  a `403 scope_missing` means the accepted token lacks the required scope.
- Most success responses use `data`; list routes may add `meta` and `links`.
  Paginated lists use `page` / `per_page` (documented defaults: 25, max: 100).
  Construct the next request against the known route rather than blindly
  following a URL. Don't assume every success has a `data` wrapper, or parse
  JSON on `204`. Check status and content type before decoding errors: most use
  `error.code`, `error.message`, and optional `error.details`, but edge errors
  and some privacy-preserving tracking errors have different shapes.

Official guides: [Getting Started](https://docs.stallion.ca/getting-started),
[Authentication & Scopes](https://docs.stallion.ca/authentication-scopes),
[Common Workflows](https://docs.stallion.ca/common-workflows), and
[Errors & Idempotency](https://docs.stallion.ca/errors-idempotency).
