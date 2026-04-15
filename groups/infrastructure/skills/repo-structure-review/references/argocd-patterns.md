# ArgoCD Structure Best Practices

## Table of Contents

- [GitOps Repo Layout](#gitops-repo-layout)
- [App-of-Apps Pattern](#app-of-apps-pattern)
- [ApplicationSets](#applicationsets)
- [Project Organisation](#project-organisation)
- [Environment Promotion](#environment-promotion)
- [Checklist](#checklist)

## GitOps Repo Layout

The GitOps repo (the repo ArgoCD watches) should be separate from the application source code repo. This separation allows independent release cadences and access controls.

### Recommended layout

```
gitops-repo/
├── apps/                           # ArgoCD Application manifests
│   ├── dev/
│   │   ├── app-frontend.yaml       # Application CR for frontend (dev)
│   │   ├── app-backend.yaml
│   │   └── app-worker.yaml
│   ├── staging/
│   │   └── ...
│   └── production/
│       └── ...
├── base/                           # Shared manifests or Helm value defaults
│   ├── frontend/
│   │   └── values.yaml
│   ├── backend/
│   │   └── values.yaml
│   └── worker/
│       └── values.yaml
├── overlays/                       # Environment-specific overrides
│   ├── dev/
│   │   ├── frontend/
│   │   │   └── values-override.yaml
│   │   └── backend/
│   │       └── values-override.yaml
│   ├── staging/
│   │   └── ...
│   └── production/
│       └── ...
└── projects/                       # ArgoCD AppProject manifests
    ├── platform.yaml
    └── applications.yaml
```

### Anti-patterns to flag

| Anti-pattern | What to look for | Severity |
|-------------|-----------------|----------|
| **GitOps mixed with app code** | ArgoCD Application manifests live in the same repo as application source code with no separation | medium |
| **Flat app directory** | All Application CRs in a single directory with no environment separation | high |
| **No base/overlay split** | Values duplicated across environments instead of using base + override pattern | high |
| **Missing AppProject** | All apps use the `default` project — no access control or resource whitelisting | high |

## App-of-Apps Pattern

The app-of-apps pattern uses a "root" Application that manages other Application CRs. This bootstraps an entire environment from a single entry point.

### Structure

```
apps/
├── root-app.yaml                 # Points to apps/dev/ directory
├── dev/
│   ├── app-frontend.yaml
│   ├── app-backend.yaml
│   ├── app-worker.yaml
│   └── app-monitoring.yaml
├── staging/
│   └── ...
└── production/
    └── ...
```

**root-app.yaml** example:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-dev
  namespace: argocd
spec:
  project: platform
  source:
    repoURL: https://github.com/org/gitops-repo.git
    targetRevision: main
    path: apps/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### When to use app-of-apps vs. ApplicationSets

| Scenario | Recommended approach |
|----------|---------------------|
| Each app needs unique config (different sources, sync policies) | App-of-apps |
| Many similar apps across environments (same chart, different values) | ApplicationSet with git or list generator |
| Bootstrapping a cluster from scratch | App-of-apps as the root entry point |
| Dynamic environments (PR previews, feature branches) | ApplicationSet with pull-request generator |

### Anti-patterns to flag

| Anti-pattern | What to look for | Severity |
|-------------|-----------------|----------|
| **No root application** | Apps are manually created via `argocd app create` or `kubectl apply`, not managed declaratively | high |
| **Root app with auto-sync + no prune** | Root app auto-syncs but never prunes deleted Application CRs — removed apps stay deployed | high |
| **Hardcoded targetRevision** | Apps pinned to a specific commit SHA instead of a branch or tag — blocks GitOps flow | medium |

## ApplicationSets

ApplicationSets generate multiple Application CRs from a single template using generators.

### Common generators

| Generator | Use case |
|-----------|---------|
| `git` (directory) | One app per directory in a path (e.g., `apps/dev/*`) |
| `git` (file) | Config-driven: one JSON/YAML file per app with parameters |
| `list` | Explicit list of clusters or environments |
| `matrix` | Combine two generators (e.g., environments x services) |
| `pullRequest` | Ephemeral preview environments per PR |

### Anti-patterns to flag

| Anti-pattern | What to look for | Severity |
|-------------|-----------------|----------|
| **ApplicationSet without syncPolicy** | Generated apps have no sync policy — requires manual sync for every change | medium |
| **Over-complex matrix generators** | Matrix of 3+ generators producing a combinatorial explosion of apps | medium |
| **No template override capability** | All generated apps are identical with no way to customize individual apps | low |

## Project Organisation

ArgoCD Projects (`AppProject`) scope access and destinations for groups of applications.

### Recommended project boundaries

| Boundary | Example |
|----------|---------|
| By team | `team-platform`, `team-application` |
| By environment | `dev`, `staging`, `production` |
| By domain | `networking`, `observability`, `workloads` |

### Required project configuration

Every AppProject should define:

1. **`sourceRepos`** — restrict which git repos apps can pull from.
2. **`destinations`** — restrict which clusters and namespaces apps can deploy to.
3. **`clusterResourceWhitelist`** — limit which cluster-scoped resources apps can create.
4. **`namespaceResourceBlacklist`** — block dangerous resources (e.g., `ResourceQuota` changes).

### Anti-patterns to flag

| Anti-pattern | What to look for | Severity |
|-------------|-----------------|----------|
| **Everything in default project** | No custom AppProject definitions — all apps use `default` | high |
| **Wildcard destinations** | `destinations: [{server: '*', namespace: '*'}]` — no scoping | critical |
| **No sourceRepos restriction** | `sourceRepos: ['*']` allows any repo | high |

## Environment Promotion

### Promotion strategies

| Strategy | How it works |
|----------|-------------|
| **Branch-per-env** | `main` = dev, `staging` branch = staging, `production` branch = production. Apps target different `targetRevision` per env. |
| **Directory-per-env** | Single branch (`main`), environments separated by directory (`overlays/dev/`, `overlays/production/`). Promotion is a file copy + PR. |
| **Tag-based** | Values reference image tags. Promotion updates the tag in the target environment's values file. |

**Recommended:** Directory-per-env on a single branch. Avoids branch drift and makes promotion a reviewable PR.

### Anti-patterns to flag

| Anti-pattern | What to look for | Severity |
|-------------|-----------------|----------|
| **No promotion path** | All environments deploy from the same values with no gating | critical |
| **Direct production edits** | Production values or manifests are modified directly without going through dev/staging first | high |
| **Branch drift** | Branch-per-env strategy with long-lived branches that have diverged significantly from each other | medium |

## Checklist

Use this checklist when reviewing an ArgoCD-based repo. Each item maps to a potential finding.

- [ ] GitOps repo is separate from application source code (or clearly separated within a monorepo)
- [ ] Application CRs are organized by environment (not flat)
- [ ] Base/overlay pattern is used for environment-specific values
- [ ] An app-of-apps or ApplicationSet bootstraps each environment declaratively
- [ ] AppProjects exist with scoped `sourceRepos`, `destinations`, and `clusterResourceWhitelist`
- [ ] No apps use the `default` project in production
- [ ] Auto-sync is enabled with `prune: true` and `selfHeal: true` where appropriate
- [ ] A clear promotion path exists from dev to staging to production
- [ ] `targetRevision` uses branches or tags, not commit SHAs (unless pinning is intentional)
- [ ] Ephemeral/preview environments use ApplicationSets with the pull-request generator (if applicable)
