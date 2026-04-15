# Helm Chart Structure Best Practices

## Table of Contents

- [Single Chart Layout](#single-chart-layout)
- [Chart Monorepo Layout](#chart-monorepo-layout)
- [Values Hierarchy](#values-hierarchy)
- [Dependencies and Subcharts](#dependencies-and-subcharts)
- [Checklist](#checklist)

## Single Chart Layout

Every Helm chart must follow this standard structure:

```
<chart-name>/
├── Chart.yaml            # Chart metadata, version, dependencies
├── Chart.lock            # Locked dependency versions
├── values.yaml           # Default values
├── templates/
│   ├── _helpers.tpl      # Template helpers and named templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml          # Optional
│   ├── serviceaccount.yaml
│   ├── configmap.yaml    # Optional
│   └── tests/
│       └── test-connection.yaml
├── charts/               # Dependency charts (auto-populated by helm dep update)
└── README.md             # Chart documentation
```

### Anti-patterns to flag

| Anti-pattern | What to look for | Severity |
|-------------|-----------------|----------|
| **Missing Chart.yaml** | No `Chart.yaml` in the chart root | critical |
| **No _helpers.tpl** | Templates duplicate labels, names, and selectors instead of using shared helpers | high |
| **God chart** | Single chart deploys 10+ distinct workloads (database, cache, API, worker, cron) | high |
| **Hardcoded values in templates** | Image tags, replica counts, resource limits baked into template files instead of `values.yaml` | high |
| **No values schema** | Missing `values.schema.json` for charts used by multiple teams | medium |
| **Flat templates directory** | 20+ template files with no logical grouping (acceptable to keep flat for small charts) | low |

## Chart Monorepo Layout

When a team manages multiple charts in a single repo, use this structure:

```
charts/
├── app-frontend/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── app-backend/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── app-worker/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
└── library/
    ├── common/               # Library chart with shared templates
    │   ├── Chart.yaml        # type: library
    │   └── templates/
    │       └── _helpers.tpl  # Shared labels, annotations, resource templates
    └── ...
```

### Key principles

1. **One chart per deployable unit** — each microservice, worker, or cron job gets its own chart.
2. **Library charts for shared templates** — common labels, annotations, and resource patterns live in a `type: library` chart that other charts depend on.
3. **Chart versioning** — each chart has independent semver in `Chart.yaml`. Bump the version on every change.
4. **CI per chart** — lint and template-test each chart independently. Use `ct` (chart-testing) for monorepo CI.

### Anti-patterns to flag

| Anti-pattern | What to look for | Severity |
|-------------|-----------------|----------|
| **Single chart for all services** | One `Chart.yaml` with conditionals toggling entire workloads via `values.yaml` flags | high |
| **Duplicated helpers across charts** | Identical `_helpers.tpl` content in multiple charts instead of a shared library chart | medium |
| **No chart versioning** | `version: 0.1.0` never changes across commits | medium |
| **Charts outside charts/ directory** | Chart directories scattered across the repo root with no common parent | low |

## Values Hierarchy

### Structure values.yaml for clarity

Group values by resource type, not by feature:

```yaml
# Good — grouped by Kubernetes resource
replicaCount: 1

image:
  repository: myapp
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  hosts: []

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
```

### Environment overrides

Use separate values files per environment:

```
<chart>/
├── values.yaml            # Defaults
├── values-dev.yaml        # Dev overrides
├── values-staging.yaml    # Staging overrides
└── values-production.yaml # Production overrides
```

Apply with: `helm install -f values.yaml -f values-production.yaml`

### Anti-patterns to flag

| Anti-pattern | What to look for | Severity |
|-------------|-----------------|----------|
| **Massive values.yaml** | 500+ lines with deeply nested, poorly documented sections | medium |
| **No default values** | Required values have no defaults, causing template failures without overrides | high |
| **Environment values in the chart** | `values-production.yaml` committed inside the chart instead of managed externally (in a GitOps repo or ArgoCD overlay) | medium |

## Dependencies and Subcharts

### When to use subcharts vs. separate charts

| Use case | Approach |
|----------|----------|
| App always deployed with its own Redis/Postgres | Subchart dependency in `Chart.yaml` |
| Shared database used by multiple apps | Separate chart, deployed independently |
| Common templates (labels, probes, resources) | Library chart (`type: library`) |

### Anti-patterns to flag

| Anti-pattern | What to look for | Severity |
|-------------|-----------------|----------|
| **Vendored charts in /charts** | Third-party charts committed directly into `charts/` instead of declared in `Chart.yaml` dependencies | medium |
| **Pinned to `*` version** | Dependency version is `*` or `>=0.0.0` — no version constraint | high |
| **Unused dependencies** | Charts listed in `Chart.yaml` dependencies but never referenced in templates | low |

## Checklist

Use this checklist when reviewing a Helm-based repo. Each item maps to a potential finding.

- [ ] Every chart has `Chart.yaml`, `values.yaml`, `templates/_helpers.tpl`
- [ ] One chart per deployable unit (no god charts)
- [ ] Shared template logic lives in a library chart, not duplicated
- [ ] `values.yaml` has sensible defaults for all required fields
- [ ] Values are grouped by resource type with clear documentation
- [ ] Chart versions are bumped on each change
- [ ] Dependencies are declared in `Chart.yaml` with pinned version ranges (not `*`)
- [ ] Third-party charts are pulled via `helm dep update`, not vendored
- [ ] Charts pass `helm lint` and `helm template` without errors
- [ ] Environment-specific overrides are outside the chart (GitOps repo or CI pipeline)
