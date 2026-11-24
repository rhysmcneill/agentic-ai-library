# Compatibility research: where to look, and known gotchas

The goal here is scoped, authoritative research — look up compatibility for the specific things actually detected running in the cluster, against their own documentation, not a broad web search across "EKS upgrade issues." A component's own release notes are always a better source than a blog post about them.

## EKS-managed addons

Never hardcode or assume a compatible version — pull it live:

```bash
aws eks describe-addon-versions --addon-name vpc-cni --kubernetes-version <target> \
  --query 'addons[].addonVersions[].{version:addonVersion,defaultVersion:compatibilities[0].defaultVersion}'
```

Repeat for `kube-proxy`, `coredns`, `aws-ebs-csi-driver`, `aws-efs-csi-driver`, and any other addon actually installed (check with `aws eks list-addons` first — don't assume the standard four are the only ones in play).

## In-cluster controllers — check these every time, not just when something looks old

| Component | Where to check | Known gotcha |
|---|---|---|
| **AWS Load Balancer Controller** | GitHub releases: `kubernetes-sigs/aws-load-balancer-controller` | Notorious for lagging many minors behind — check this every single upgrade, it's a recurring finding, not an edge case. |
| **Karpenter** | GitHub releases + its own EKS compatibility table in the Karpenter docs | Karpenter versions are tied to specific EKS/Kubernetes version ranges; an old Karpenter can silently fail to provision nodes on a newer control plane rather than erroring clearly. |
| **cluster-autoscaler** (if used instead of/alongside Karpenter) | GitHub releases — versioned to match the Kubernetes minor it supports (e.g. `cluster-autoscaler` 1.35.x pairs with k8s 1.35) | Must match the **target** cluster's minor version, not the current one — this is often bumped in the same PR as the cluster version itself. |
| **cert-manager** | GitHub releases / cert-manager.io compatibility matrix | Occasionally drops support for old CRD API versions; check if CRDs need a `kubectl apply` of updated CRD manifests alongside the controller bump (this is a step the execution skill needs to know about, flag it even though this skill doesn't perform it). |
| **external-dns** | GitHub releases | Rarely version-gated to Kubernetes itself, but check anyway for CRD/API changes if it watches `Ingress`/`Gateway` resources. |
| **ingress-nginx / other ingress controllers** | Project's own compatibility matrix (ingress-nginx publishes one explicitly mapping its version to supported Kubernetes versions) | ingress-nginx in particular is strict about this — running a version outside its stated Kubernetes support window is a real risk, not theoretical. |
| **Admission webhooks (OPA/Gatekeeper, Kyverno, custom validating/mutating webhooks)** | Project release notes | A webhook built against an old API version can start silently rejecting or failing-open on objects using a new API version — check `failurePolicy` as part of this, since a misconfigured one can take down unrelated deployments cluster-wide during the rollout. |
| **Service mesh (Istio/Linkerd, if present)** | Project's own Kubernetes compatibility matrix | These are usually the most version-sensitive component in the cluster if present — treat any mesh as a Critical-severity candidate until proven otherwise. |

## How to do the lookup without turning it into an open-ended research task

1. From the cluster state snapshot, list the actual installed version/image tag for each component above that's present (don't research components that aren't running).
2. For each one, go straight to its GitHub releases page (or stated compatibility matrix if it has one) and find: is the *currently installed* version still supported against the *target* Kubernetes version, and if not, what's the minimum version that is.
3. Record the finding with a direct link to the source you used — the report should let someone verify the claim later, not just trust it.
4. If a component has no public compatibility statement at all (common for small/internal tools), say so explicitly and rate it based on general risk (e.g. "uses client-go against the Kubernetes API — recommend confirming manually, no public compatibility matrix found") rather than silently skipping it.
