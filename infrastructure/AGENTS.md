# AGENTS.md — infra

## Context

Infrastructure domain rules for AI coding agents at IriusRisk. Loaded after `company/AGENTS.md`.
Rules here extend or override the global baseline for this team's repositories.

To override a global rule, reference its Rule ID explicitly:

```
<!-- override: GBL-001 -->
1. <Your replacement rule here>
```

To add a new team rule, use a team-prefixed ID:

```
<!-- rule: INFRA-001 -->
1. <Your new rule here>
```

## Team-specific Overrides

<!-- No overrides yet. Add entries here using the override comment syntax above. -->

## Team-specific Rules

<!-- rule: INFRA-001 -->
1. **Terramate First:** Always check for Terramate code generation (`terramate generate`) when working with Terraform files. Do not manually edit generated files.

<!-- rule: INFRA-002 -->
2. **Helm Charts:** Follow standard Helm chart structures. Validate changes with `helm lint` before completing a task. Keep `values.yaml` well-documented.

<!-- rule: INFRA-003 -->
3. **ArgoCD Apps:** Ensure ArgoCD Application manifests are declarative and point to valid paths/revisions.

<!-- rule: INFRA-004 -->
4. **Immutability:** Treat infrastructure as immutable. Prefer replacing resources over making manual, undocumented in-place modifications.

<!-- rule: INFRA-005 -->
5. **Least Privilege:** When creating IAM roles, ServiceAccounts, or RBAC policies, adhere strictly to the principle of least privilege.
