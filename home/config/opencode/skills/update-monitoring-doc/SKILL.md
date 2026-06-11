---
name: update-monitoring-doc
description: Use when updating k8s-ops-infra/docs/monitoring.md, especially Catalog, Alerting, Automation, Incident.io, Grafana, VictoriaMetrics, or label-aggregator documentation. Requires source verification before edits.
compatibility: opencode
metadata:
  domain: observability
  target: monitoring-docs
  workflow: source-verified-documentation
---

# Update Monitoring Documentation Skill

Use this skill when the user asks to update `k8s-ops-infra/docs/monitoring.md` or related monitoring documentation.

## Non-negotiable rules

- Write documentation in English unless the user explicitly asks otherwise.
- Do not guess how monitoring, catalog sync, alert routing, or status page automation works.
- Verify current behavior from source files and MCPs before editing.
- If any required source is unavailable, stop and ask the user for access or clarification.
- Keep changes focused on requested sections.
- Prefer accurate current behavior over aspirational design.
- Never include secrets, tokens, kubeconfigs, decrypted `.secrets`, or sensitive payloads in documentation.

## Required source access

Before editing, confirm access to these local repositories:

- `k8s-ops-infra`
- `incident-ops`
- `label-aggregator`

Confirm access to these MCP-backed sources when relevant:

- Incident.io MCP for catalog types, catalog entries, alert sources, organization config, incident custom fields, and alert attributes.
- VictoriaMetrics MCP for live metrics, alert rules, labels, and query validation.
- Grafana MCP for datasources, alert routing, dashboards, panels, and alert rules.

If a repository or MCP is missing and the requested change depends on it, ask the user for access before continuing.

## Source files to inspect

### k8s-ops-infra

Read the target document first:

- `k8s-ops-infra/docs/monitoring.md`

Inspect deployment/config sources when updating behavior descriptions:

- `k8s-ops-infra/components/monitoring/controllers/**/label-aggregator/*.yaml`
- `k8s-ops-infra/components/monitoring/controllers/**/victoria-metrics/**/*.yaml`
- `k8s-ops-infra/components/monitoring/configs/**/victoria-metrics/**/*.yaml`
- `k8s-ops-infra/catalog/services.yaml`

Use examples from this repo only when they still match current code and runtime config.

### incident-ops

Inspect catalog sync configuration:

- `incident-ops/catalog-sync/importer.jsonnet`
- `incident-ops/catalog-sync/vars.jsonnet`
- `incident-ops/catalog-sync/schemas/*.jsonnet`
- `incident-ops/catalog-sync/scripts/python/build_all.py`
- `incident-ops/catalog-sync/scripts/python/build_services.py`
- `incident-ops/catalog-sync/scripts/python/build_components.py`
- `incident-ops/catalog-sync/scripts/python/build_component_instances.py`
- `incident-ops/catalog-sync/scripts/python/build_endpoints.py`
- `incident-ops/catalog-sync/scripts/python/build_clusters.py`
- `incident-ops/catalog-sync/scripts/python/build_hosts.py`
- `incident-ops/catalog-sync/scripts/python/build_networks.py`
- `incident-ops/catalog-sync/scripts/python/common/*.py`
- `incident-ops/catalog-sync/config/management-clusters.yaml`
- `incident-ops/catalog-sync/config/status-page-messages.yaml`
- `incident-ops/catalog/services.yaml`

Important current behavior to verify:

- `build_all.py` execution order.
- Which schemas are active in `importer.jsonnet`.
- How generated JSON files are built.
- How `catalog/services.yaml` files are discovered from repos listed in `vars.jsonnet`.
- How `Component instance` entries are generated.
- How status page components and messages are resolved.

### label-aggregator

Inspect aggregator runtime behavior:

- `label-aggregator/main.go`
- `label-aggregator/internal/app/k8s.go`
- `label-aggregator/internal/app/http.go`
- `label-aggregator/internal/aggregate/aggregator.go`
- `label-aggregator/internal/aggregate/metrics.go`
- `label-aggregator/AGENTS.md`

Important current behavior to verify:

- watched Kubernetes resources and CRDs
- exposed HTTP endpoints
- response format: YAML, not JSON
- labels and annotations read by the aggregator
- conflict and incomplete-label handling
- exported Prometheus metrics

## MCP checks

Use MCPs to validate runtime state when updating sections about live systems.

### Incident.io MCP

Use Incident.io MCP to verify:

- catalog type names and attributes
- catalog entry examples
- alert source IDs and names
- alert attributes and incident custom fields
- service/component/network/cluster/status page relationships

Recommended calls:

- list catalog types
- list Service, Component, Component instance, Network, Cluster, Endpoint entries when examples are needed
- read organization config for alert attributes and incident fields
- list alert sources when documenting Alertmanager routes

### VictoriaMetrics MCP

Use VictoriaMetrics MCP to verify:

- `label_aggregator_*` metrics exist
- alert rule names and labels, when documenting alert examples
- label names/values used in PromQL or routing examples

Recommended checks:

- list metrics matching `label_aggregator_.*`
- query `label_aggregator_services_total`, `label_aggregator_components_total`, `label_aggregator_hosts_total`
- inspect relevant alert rules if changing alert guidance

### Grafana MCP

Use Grafana MCP to verify:

- datasources names and UIDs
- alert routing/contact point behavior, if documenting Grafana-managed alerting
- dashboard or panel references, if adding links or examples

Recommended checks:

- list datasources
- inspect alert routing only when relevant
- inspect dashboards only when the doc references a dashboard

## Documentation update workflow

1. Restate requested doc sections and impacted systems.
2. Confirm required repositories and MCP sources are available.
3. Read current `monitoring.md` before editing.
4. Inspect source files listed above for the requested sections.
5. Use MCPs to verify runtime config where possible.
6. Draft concise documentation that explains current behavior.
7. Update only requested sections unless surrounding context is wrong and would mislead users.
8. Re-read edited sections.
9. Validate examples against source behavior.
10. Summarize changed sections and sources used.

## Section-specific guidance

### Catalog

Document the current catalog flow:

1. K8s resources are labeled in workload clusters.
2. `label-aggregator` exposes aggregated YAML per cluster.
3. `incident-ops` Python builders generate JSON inputs.
4. `catalog-importer` syncs entries into Incident.io.

Document stable external IDs, not display names, as the primary matching keys.

Mention these label and annotation conventions only after verifying they still exist in `label-aggregator`:

- `service` label or annotation
- `service.name` annotation
- `component` label or annotation
- `component.name` annotation
- `network` label or annotation

Document that `component` and `service` must be provided together for component discovery.

Document `catalog/services.yaml` as the place for service metadata such as:

- `name`
- `external_id`
- `aliases`
- `description`
- `team`
- `owners`

Make clear that `external_id` must match the `service` label.

### Alerting and routing

Document that Alertmanager labels populate Incident.io alert attributes.

Prefer these routing labels when still present in organization config:

- `service`
- `component`
- `network`
- `cluster`
- `severity`

Mention `runbook_url` only as an annotation, not a label, unless source config proves otherwise.

### Automation

Document status page automation using current Incident.io and `incident-ops` behavior.

Current model to verify before writing:

- `Component instance` represents `service / component / network`.
- `Component instance` can hold a resolved `Status page component`.
- status page message fields are generated from `status-page-messages.yaml`.
- `$NETWORK` is replaced with the Network full name.

Do not describe `Status Page Map` as the primary source unless source files and Incident.io config prove it is still primary. If it still exists for compatibility, describe it as compatibility/manual mapping.

### Blackbox

Before changing Blackbox docs, inspect current K8s resources and probe generation scripts. Do not assume only HTTPRoute is supported unless current source confirms it.

## Writing style

- Be direct and operational.
- Prefer bullets and short paragraphs.
- Include examples only when source-backed.
- Use exact file paths for operator actions.
- Avoid vague phrases like “should work” or “probably”.
- Call out failure modes that affect routing or automation.

## Verification checklist

Before final response, confirm:

- Edited Markdown renders valid fenced code blocks.
- YAML examples use valid syntax.
- Labels and annotations match current source code.
- Catalog type names match Incident.io live config.
- Runtime claims match source or MCP output.
- No secrets or local credential paths are included.
- User-facing summary lists changed files and why.
