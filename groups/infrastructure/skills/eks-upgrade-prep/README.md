# EKS Upgrade Prep

```
/plugin install eks-upgrade-prep --marketplace rhysmcneill/agentic-ai-library
```

A Claude Code skill that runs a thorough, read-only readiness audit before you upgrade an Amazon EKS cluster's Kubernetes version. It checks for deprecated and removed API usage, Pod Disruption Budgets and other drain blockers, cluster health via AWS's EKS Upgrade Insights, and researches compatibility for every addon and in-cluster controller (the AWS Load Balancer Controller, Karpenter or cluster-autoscaler, cert-manager, ingress controllers, admission webhooks, CSI drivers, and more) against the target Kubernetes version using each project's own release notes as the source of truth.

Every run starts by confirming context with you — cluster identity, IaC tool, where the version fields live, compute model, and target version — rather than guessing, and saves that context for next time. The output is a single severity-rated findings report with a clear go/no-go recommendation, written as a local markdown file you can paste straight into your team's usual documentation.

This skill never changes anything. It doesn't run `kubectl apply`, `terraform apply`, open pull requests, or create tickets — it investigates and reports, so a human stays firmly in the loop for the actual upgrade. It works with Terraform, OpenTofu, Terramate, Terragrunt, or any other IaC tool, and with managed node groups, Karpenter, or Fargate.

See `SKILL.md` for the full instructions this skill follows, and `references/` for the detailed check commands, compatibility research sources, and report template it uses.
