# Report template

Mirrors the team's existing manual upgrade runbook format so it can be pasted straight into their usual doc space (e.g. Confluence) with minimal reformatting. Fill in every section — if a check found nothing, say "Nothing to action" explicitly rather than omitting the section, so a reader can tell "checked, clean" apart from "not checked."

````markdown
# <cluster-name> — EKS Upgrade Prep (<current-version> → <target-version>)

**AWS Account:** <alias> (<account-id>)
**Cluster:** <cluster-name>
**Region:** <region>
**Compute:** <managed node groups / Karpenter / Fargate / mixed>
**Generated:** <date>

## Recommendation: <GO / NO-GO / GO WITH CONDITIONS>

<1-3 sentences: the verdict and why. If NO-GO or conditional, list exactly what must be resolved first, referencing the Critical/High items below by number.>

| Severity | Count |
|---|---|
| Critical | <n> |
| High | <n> |
| Medium | <n> |
| Low | <n> |

## Prerequisites

### Deprecated / removed APIs

| # | Deprecated API | Suggested remediation | Severity |
|---|---|---|---|
| | | | |

### Service-level blockers

| # | Issue | Mitigation | Recommendation | Severity | Source |
|---|---|---|---|---|---|

### PDB / drain-blocker audit

<Findings, or "Nothing to action.">

### Cluster health / EKS Upgrade Insights

<Summary of insights returned, including informational ones.>

## Addon & controller compatibility

| Component | Installed version | Target-compatible? | Recommended version | Source | Severity |
|---|---|---|---|---|---|

## Target versions

```
# Control plane
eks_cluster_version = "<target>"

# Add-ons (only list the ones this cluster actually manages)
eks_addon_vpc_cni_version    = "<version>"
eks_addon_kube_proxy_version = "<version>"
eks_addon_coredns_version    = "<version>"
eks_addon_ebs_csi_version    = "<version>"
```

## Reference environment cross-check

<If a lower environment already validated this version jump, summarize what it hit, if anything. Otherwise: "No reference environment available at this version yet.">

## Open items for follow-up (not blocking)

<Anything Medium/Low that's worth a ticket but doesn't need to happen before this upgrade — list them, don't file them.>
````
