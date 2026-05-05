---
name: build-dashboard
description: Build focused, iterative Grafana dashboards using VictoriaMetrics and Grafana MCPs
compatibility: opencode
metadata:
  domain: observability
  target: grafana
  workflow: dashboard-building
---

# Build Dashboard Skill

Use this skill when the user wants to create, review, redesign, or iterate on a Grafana dashboard.

## Core principles

- Do not invent project context, metrics, labels, datasources, dashboards, or URLs.
- Ask for missing information before designing or publishing anything.
- Prefer simple dashboards with a clear operational purpose.
- Prefer stable, low-cardinality metrics.
- Avoid expensive, noisy, or unbounded queries.
- Publish a test dashboard first.
- Never overwrite a production dashboard without explicit user approval.
- Keep the dashboard focused on the stated user goal.
- Track dashboard changes with an explicit version tag.

## Required inputs

Before implementation, identify or ask for:

- target application, service, or platform
- dashboard goal
- intended audience: SRE, ops, developers, management, customer-facing, etc.
- Grafana instance or destination
- datasource
- environment, cluster, namespace, tenant, or service filters
- required variables
- whether VictoriaMetrics MCP access is available
- whether Grafana MCP publishing is allowed
- expected dashboard JSON URL, if the final dashboard must link to its source
- whether a test dashboard may be created

## Workflow

### 1. Clarify

Restate the user goal.

Identify missing information.

Ask concise questions before doing implementation work.

Do not continue if the Grafana destination, target service, or datasource is ambiguous.

### 2. Research

If the target application is known and not fully described by the user, summarize relevant monitoring best practices.

Focus on:

- golden signals
- saturation points
- common failure modes
- useful operational views
- common dashboard anti-patterns

### 3. Metrics analysis

When metrics access is available, inspect available VictoriaMetrics metrics.

Select metrics based on:

- relevance to the stated goal
- stability
- understandable labels
- reasonable cardinality
- cost of query execution

Explicitly call out metrics that appear risky because of:

- high cardinality
- missing labels
- inconsistent naming
- noisy series
- expensive query patterns

Do not invent metric names.

If metrics are unavailable, propose query patterns only as placeholders and mark them clearly as assumptions.

### 4. Dashboard architecture

Design the dashboard reading flow.

Define:

- dashboard title
- dashboard purpose
- sections
- global variables
- default filters
- panel grouping
- ordering from high-level health to detailed diagnosis

Prefer this structure when applicable:

1. Overview / health
2. Traffic / workload
3. Errors / failures
4. Latency / performance
5. Saturation / resources
6. Dependencies
7. Detailed diagnostics

### 5. Panel design

For each panel, specify:

- title
- purpose
- panel type
- query
- unit
- legend format
- variables used
- thresholds, only when meaningful
- expected operator insight

Avoid panels that do not drive a decision.

### 6. Test implementation

Create or update a test dashboard first.

Use:

- a `-test` suffix in the title
- a stable test UID when possible
- the same test dashboard across iterations

After publishing the test dashboard, summarize:

- what changed
- dashboard URL or UID
- what the user should validate

### 7. Iteration

For every requested change:

- increment the version tag
- update only what is requested
- preserve stable dashboard identity when possible
- ask for validation again

### 8. Finalization

Only finalize when the user explicitly approves.

Final output must include:

- final dashboard title
- version
- Grafana URL or UID
- exported JSON location or URL if available
- summary of important variables and panels
- any remaining operational caveats

## Versioning policy

Use semantic draft versions:

- `v0.1` for initial draft
- increment to `v0.2`, `v0.3`, etc. for user-requested iterations
- use `v1.0` only when the user approves the final version

The version should be visible in dashboard metadata, tags, description, or annotations when practical.

## Security rules

- Do not reveal tokens, credentials, or secret values.
- Do not print environment variables containing tokens.
- Do not modify production dashboards without explicit approval.
- Prefer read-only discovery before write operations.
- Ask before using write-capable MCP operations.
- If a command may mutate infrastructure or dashboards, ask first.

## Summary format

When reporting progress, use:

```text
Goal:
Metrics:
Dashboard structure:
Panels:
Test dashboard:
Version:
Needs validation:
Risks / caveats:
```
