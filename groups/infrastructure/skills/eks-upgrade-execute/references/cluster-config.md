# Cluster config schema

This is the exact same file and schema `eks-upgrade-prep` uses — `.eks-upgrade/<cluster-name>.yaml` in the repo that holds the cluster's IaC. It's duplicated here (rather than referenced across skill directories) so this skill works correctly even if installed on its own, without `eks-upgrade-prep` present.

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

reference_environment:
  cluster_name: payments-staging
  config_path: .eks-upgrade/payments-staging.yaml
```

## What this skill additionally relies on

- `iac.cluster_version_path` / `cluster_version_key` and `iac.addons_path` / `addon_keys` — exactly where to make the version bump edits in Steps 3 and 6. If these are missing or you're not confident they're still accurate, stop and confirm with the user rather than guessing at a file path for an edit that opens a real PR.
- `compute.model` — which branch of `references/node-upgrade.md` applies in Step 5.

If the file is missing entirely, that means `eks-upgrade-prep` hasn't been run for this cluster yet — don't reconstruct it from scratch here. Tell the user to run prep first; it's the one that's supposed to interview them and write this file.
