# Check reference: commands and how to read them

All commands here are read-only. If a tool isn't installed, say so in the report rather than skipping the check silently — a missing tool is itself a finding ("couldn't verify X, no `eksup` binary available").

## Locating version fields by IaC tool

Don't assume Terramate's variable names apply everywhere — confirm the actual pattern for the tool in play:

- **Terraform / OpenTofu**: look for a variable or local like `cluster_version`, `kubernetes_version`, or a module input of the same name passed to an `aws_eks_cluster` resource or EKS module block.
- **Terramate**: variables are usually declared in `stack.tm.hcl` / `globals.tm.hcl`, commonly named `eks_cluster_version`, `eks_addon_<name>_version`.
- **Terragrunt**: check `terragrunt.hcl` `inputs = { ... }` blocks, or a `.tfvars`/`.yaml` file it reads from.
- **CDK**: look for `Version.of("1.xx")` or similar passed to a `Cluster`/`FargateCluster` construct.

When unsure, grep broadly first (`grep -rn "cluster_version\|kubernetes_version\|eks_addon" <repo>`) rather than guessing one pattern.

## Pre-flight / cluster state snapshot

```bash
kubectl get nodes -o wide
kubectl get pods -A | grep -v Running | grep -v Completed
kubectl get pods -n argocd   # or whatever the GitOps controller's namespace is
aws eks describe-cluster --name <cluster> --query 'cluster.{version:version,status:status,platformVersion:platformVersion}'
aws eks list-addons --cluster-name <cluster>
aws eks describe-addon --cluster-name <cluster> --addon-name <addon> --query 'addon.{version:addonVersion,status:status}'
```

## Deprecated / removed API check

Prefer `eksup` — it's purpose-built for EKS upgrades and already knows the AWS-specific nuances `kubent`/`pluto` don't:

```bash
eksup analyze --cluster <cluster> --region <region>
```

If `eksup` isn't available, fall back to `kubent` (generic Kubernetes deprecated-API scanner):

```bash
kubent --cluster <context>
```

Either way, cross-reference findings against the official Kubernetes deprecation guide for the target minor version (`kubernetes.io/docs/reference/using-api/deprecation-guide/`) — tool output tells you *what* is deprecated; the guide tells you whether it's deprecated-but-working or hard-removed in the target version, which changes the severity.

## PDB and drain-blocker audit

```bash
kubectl get pdb -A -o json
kubectl get deploy,sts -A -o json   # to check replica counts against PDB coverage
```

Look for:
- A PDB whose `minAvailable` equals the replica count (drain can never succeed).
- Any `Deployment`/`StatefulSet` with `replicas: 1` and no matching PDB at all — not blocked, but will cause a real outage during drain; flag it even though it won't stop the upgrade.
- Pod anti-affinity or `topologySpreadConstraints` with `whenUnsatisfiable: DoNotSchedule` that could leave evicted pods unschedulable if capacity is tight during the rollout.
- If Karpenter: `do-not-disrupt: "true"` annotations and the NodePool's own disruption budget — these behave like PDBs for Karpenter-managed nodes but live in a different place (`karpenter.sh` CRDs, not core `policy/v1` PDBs).

## Cluster health / EKS Upgrade Insights

```bash
aws eks list-insights --cluster-name <cluster>
aws eks describe-insight --cluster-name <cluster> --id <insight-id>
```

This is the first thing to check, not a backstop — AWS surfaces a meaningful chunk of what this whole audit is trying to catch (deprecated API usage, incompatible add-ons, cluster configuration issues) directly through this API now. Read every insight returned, not just ones with a non-OK status — some return informational detail worth including in the report even when passing.

## Severity rubric

| Rating | Meaning |
|---|---|
| **Critical** | Blocks the upgrade outright — there's no safe path forward until this is remediated (e.g. a hard-removed API still in active use, a PDB that makes drain mathematically impossible). |
| **High** | The upgrade can proceed, but this *will* break something afterward unless addressed — and a known fix already exists (e.g. an addon version incompatible with the target, with a documented upgrade path). |
| **Medium** | Deprecated but not yet removed, or a controller noticeably behind on versions without a known compatibility issue yet — worth fixing, not urgent. |
| **Low** | Informational — version drift with no functional risk, cosmetic, or something to track for next time. |

Every Critical/High item needs a one-line recommended remediation attached, not just the problem statement — that's what makes the report actionable instead of just alarming.
