# EKS Upgrade Execute

```
/plugin install eks-upgrade-execute --marketplace rhysmcneill/agentic-ai-library
```

A Claude Code skill that carries out an Amazon EKS cluster version upgrade through your existing IaC and CI/CD pipeline, once [`eks-upgrade-prep`](../eks-upgrade-prep/SKILL.md) has already confirmed it's safe to. It takes a fresh backup (Velero and/or AWS Backup), bumps the control-plane version via a pull request, upgrades worker nodes with logic specific to managed node groups, Karpenter, or Fargate, watches automated health gates with predefined abort thresholds, and then bumps addon versions via a second pull request.

A human approves every pull request merge and every node-disruptive action — this skill never merges anything itself, and never attempts to roll back the control plane (Amazon EKS doesn't support downgrading a cluster's Kubernetes version, so recovery means restoring workloads, not undoing the version bump). It refuses to run at all without a go/no-go readiness report already produced by `eks-upgrade-prep`.

See `SKILL.md` for the full instructions this skill follows, and `references/` for the exact commands, compute-type-specific node upgrade logic, backup procedures, and health-gate thresholds it uses.
