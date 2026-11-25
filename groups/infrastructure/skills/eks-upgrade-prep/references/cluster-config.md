# Cluster config schema

Stored at `.eks-upgrade/<aws_account_alias>/<region>/<cluster-name>/config.yaml` in the repo that holds the cluster's IaC. One file per cluster. This is the only state the prep skill persists between runs — everything else is re-derived fresh each time so it can never go stale in a way that matters.

```yaml
cluster_name: payments-prod
aws_account_id: "123456789012"
aws_account_alias: example-corp-prod
region: eu-west-1

iac:
  tool: terramate   # terraform | opentofu | terramate | terragrunt | cdk | other
  cluster_version_path: stacks/accounts/example-corp-prod/eu-west-1/platform/eks/stack.tm.hcl
  cluster_version_key: eks_cluster_version
  addons_path: stacks/accounts/example-corp-prod/eu-west-1/platform/eks/stack.tm.hcl
  addon_keys:
    vpc_cni: eks_addon_vpc_cni_version
    kube_proxy: eks_addon_kube_proxy_version
    coredns: eks_addon_coredns_version
    ebs_csi: eks_addon_ebs_csi_version

compute:
  model: mixed        # managed_node_group | karpenter | fargate | mixed
  details: "Karpenter for general workloads, one managed node group for system pods"

# Optional: a lower environment that typically validates a version before this cluster does.
# If set, the prep skill will check its upgrade history as a cross-check (step 8).
reference_environment:
  cluster_name: payments-staging
  config_path: .eks-upgrade/example-corp-prod/eu-west-1/payments-staging/config.yaml

# Written after the report is produced (see "Write the report" below) — this is how
# eks-upgrade-execute finds it later, including when the path isn't the default one.
report_path: .eks-upgrade/example-corp-prod/eu-west-1/payments-prod/1.34-to-1.35/upgrade-prep.md
```

## Notes

- `iac.tool` determines which syntax patterns to grep for when confirming the current version live — see the "Locating version fields by IaC tool" section in `references/checks.md`.
- `report_path` won't exist yet the first time you write this file for a cluster (you haven't produced the report yet at that point) — add it once the report's actually written, not before.
- `addon_keys` only needs entries for addons actually managed in this repo's IaC. Don't invent keys for addons that aren't present — note their absence in the report instead (e.g. if there's no EFS CSI driver, say so, don't pad the config).
- If the user can't immediately tell you all of this (common for a cluster inherited from someone else), it's fine to go find it yourself by grepping the IaC repo for the current version string (e.g. `grep -rn "eks_cluster_version\|cluster_version\|kubernetes_version" .`) and confirming with `aws eks describe-cluster` — then show the user what you found before writing the config, since the point of the file is accuracy, not just having one.
- Treat this file like any other repo file: if it already exists, read it before editing it, and keep it in sync if the IaC paths move.
