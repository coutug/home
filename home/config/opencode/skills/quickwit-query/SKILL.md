---
name: quickwit-query
description: Use when querying Quickwit MCP indexes: choose indexes, inspect fields, discover dynamic fields, and build Quickwit query strings for search_logs or search.
---

# Quickwit Query Skill

Use this skill when user asks to search Quickwit data through Quickwit MCP.

## Workflow

1. Call `quickwit-pinax_list_indexes`.
   - Pick one exact `index_id`.
   - Do not use wildcard or comma multi-index targets; MCP search tools accept one exact index.
2. Call `quickwit-pinax_inspect_index`.
   - Read `timestamp_field`.
   - Read `default_search_fields`.
   - If `dynamic_mapping` is true or needed field is missing, call `quickwit-pinax_list_fields`.
3. Call `quickwit-pinax_list_fields` when field discovery matters.
   - Use `start_timestamp` and `end_timestamp` epoch seconds on large indexes.
   - Use `field_patterns` to narrow discovery, e.g. `["message", "resource_attributes.*"]`.
   - Prefer fields marked searchable for queries.
   - Prefer fields marked aggregatable/fast for sorting and terms aggregations.
4. Build Quickwit query string.
5. Use:
   - `quickwit-pinax_search_logs` for RFC3339-bounded operational log searches.
   - `quickwit-pinax_search` for low-level search, aggregations, pagination, or non-log data.

## Query syntax cheat sheet

- `*` = match all.
- `error` = search default fields.
- `field:value` = field term query.
- `field:"exact phrase"` = phrase query.
- `field:prefix*` = prefix query.
- `field:*` = field exists.
- `field:[a TO z]` = inclusive range.
- `field:{a TO z}` = exclusive range.
- `field:>=10` / `field:<10` = half-range.
- `foo AND bar` = both.
- `foo OR bar` = either.
- `NOT foo` or `-foo` = exclude.
- `(foo OR bar) AND baz` = explicit precedence.

## Escaping and quoting

Quote values containing spaces or special characters:

```text
service_name:"quickwit mcp"
container_name:"quickwit-mcp"
```

Escape `"` and `\` inside quoted values.

Special characters in unquoted values need escaping: plus, caret, backtick, colon, braces, quote, brackets, parentheses, tilde, bang, backslash, star, and space.

For JSON/nested fields, use dotted paths from `list_fields`, e.g.:

```text
resource_attributes.service.name:api
body.message:"failed request"
```

If field names themselves contain dots and index config uses `expand_dots`, follow fields returned by `list_fields` and escape literal dots only when Quickwit requires it.

## Time and sorting

- `search_logs` takes `start_time` and `end_time` as RFC3339 strings.
- `search` takes `start_timestamp` and `end_timestamp` as epoch seconds.
- Use `inspect_index.timestamp_field` as default sort field when sorting by time.
- In MCP, set `sort_field` and `sort_order`; do not handcraft Quickwit `sort_by` payloads.

## Field selection strategy

- If query is broad text search, start with default fields from `inspect_index.default_search_fields`.
- If query must be precise, use fielded clauses from `list_fields`.
- If index has dynamic mapping, do not assume `inspect_index.field_names` is complete.
- If field is absent from `list_fields` for selected time window, widen time window or field pattern before concluding it does not exist.

## Partial results

If Quickwit reports split errors or user enables failed-split tolerance, treat results as possibly incomplete. Say so in answer.
