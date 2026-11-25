---
name: eks-upgrade-prep
description: Runs a thorough, read-only readiness audit before an Amazon EKS cluster version upgrade — deprecated API usage, PDB/drain blockers, cluster health via EKS Upgrade Insights, and compatibility research for every addon and in-cluster controller (ALB controller, Karpenter/cluster-autoscaler, cert-manager, ingress controllers, admission webhooks, CSI drivers, etc.) against the target Kubernetes version. Produces a severity-rated findings report and a go/no-go recommendation. Starts every run by asking the user to confirm cluster identity, IaC tool, stack file locations, compute model, and target version first — never assumes or infers these. Use whenever the user is planning, preparing, or scoping an EKS Kubernetes version upgrade, asking "is it safe to upgrade," or invoking /eks-upgrade-prep directly. Investigates and reports only — never bumps versions, applies IaC, or merges anything; that's a separate execution step.
metadata:
  version: "1.0.2"
---

# EKS Upgrade Prep

This is the investigation phase of an EKS cluster upgrade: find out, before anyone touches a version number, whether the cluster is actually ready to move to the next Kubernetes version, and exactly what would break if it did. The value of this skill is catching the thing nobody remembered to check — the one that's always a human guessing which release notes matter — not running a few `kubectl` one-liners that could already be scripted.

**This skill is strictly read-only.** Query the cluster, AWS APIs, and the internet. Never run `kubectl apply/delete/drain/cordon`, never run any IaC apply/deploy command (`terraform apply`, `tofu apply`, `terramate run`, `terragrunt apply`, `cdk deploy`, etc. — whichever this cluster actually uses), never edit IaC files, never open a PR, never create tracking tickets. If any of that feels useful, say so in the report and stop there — that's the execution skill's job, not this one.

## Step 0: always confirm context with the user before touching anything

Don't guess at this or quietly infer it from whatever repo happens to be open — asking up front is cheap, and a wrong assumption here (wrong stack path, wrong cluster) silently invalidates the whole audit. Treat this as the mandatory first thing that happens on invocation, every time, not a fallback for when a config is missing.

Ask for:

1. **Cluster identity** — cluster name, AWS account (ID or alias), region.
2. **IaC tool** — Terraform, OpenTofu, Terramate, Terragrunt, CDK, or other.
3. **Where the version fields live** — the repo and exact file path(s) declaring the EKS cluster version and the addon versions. If the user doesn't know offhand, offer to go find it yourself (grep the repo they point you to) and show them what you found before proceeding, rather than assuming a path.
4. **Compute model** — managed node groups, Karpenter, Fargate, or mixed.
5. **Target Kubernetes version** — confirm it's the next minor (N → N+1), not a multi-minor jump; if it is a jump, say so and flag that it changes the risk profile before going further.
6. **Report location** — confirm the default (`.eks-upgrade/<aws_account_alias>/<region>/<cluster-name>/<current>-to-<target>/upgrade-prep.md` in the current repo) or ask where else they'd like it.

If `.eks-upgrade/<aws_account_alias>/<region>/<cluster-name>/config.yaml` already exists, read it and use it to pre-fill your questions rather than asking from scratch — show the user what's on file and have them confirm or correct it in one pass ("here's what I have for payments-prod, still accurate?"), rather than silently trusting a file that might be stale. Either way, write/update `.eks-upgrade/<aws_account_alias>/<region>/<cluster-name>/config.yaml` per the schema in `references/cluster-config.md` once confirmed, so next time this is a quick confirm instead of a full interview.

Only move on to the audit once the user has confirmed this context. This file is the only thing the skill persists between runs — everything else is read fresh each time.

## The audit

Work through these in order; each one feeds the next, so don't skip ahead. Full command reference, including exact `aws`/`kubectl`/`eksup` invocations, lives in `references/checks.md` — read it before running checks.

1. **Confirm current and target versions.** Read the current `eks_cluster_version` (or equivalent) from the IaC path in the config, cross-check live via `aws eks describe-cluster`, and confirm the target version with the user if it isn't obvious (usually "next minor"). EKS skips no minors on upgrade — confirm the path is N → N+1, not a multi-minor jump, since that changes the risk profile considerably and may need to be staged as several separate upgrades.

2. **Collect raw cluster state.** Nodes, pod health, PDBs, installed addons + versions, Helm releases/images for in-cluster controllers, and any `kubectl` output needed for the later steps. Do this once, up front, so later steps all work off the same snapshot rather than re-querying a cluster that may be changing under you.

3. **Deprecated/removed API check.** Run `eksup analyze` (preferred) or `kubent` if `eksup` isn't available, scoped to the current → target version gap. Anything flagged here is a hard blocker unless remediated first — there is no "proceed anyway."

4. **PDB and drain-blocker audit.** Don't stop at "does a PDB exist" — that's necessary but not sufficient. Check for: PDBs with `minAvailable`/`maxUnavailable` that would prevent a node from ever fully draining, single-replica workloads with *no* PDB at all (these drain silently with no protection, which is its own kind of risk), and anti-affinity/topology-spread rules that could strand pods on a draining node with nowhere to go. If Karpenter is in play, also check `do-not-disrupt` annotations and Karpenter's own disruption budgets.

5. **Cluster health and EKS Upgrade Insights.** `aws eks list-insights` / `describe-insight` surfaces a lot of what used to require manual digging — use it as the primary source, not an afterthought. Cross-check node and add-on health the usual way (see `references/checks.md`).

6. **Compatibility research for everything running in the cluster.** This is the step that actually requires judgment, not deterministic scripting — don't try to shortcut it with a keyword search across "all services." Instead:
   - From the state collected in step 2, build the actual list of things that matter: the EKS-managed addons (VPC CNI, kube-proxy, CoreDNS, EBS/EFS CSI, etc.) plus any cluster-critical controllers running as workloads (ALB/NLB controller, Karpenter or cluster-autoscaler, cert-manager, external-dns, ingress controllers, admission webhooks like OPA/Gatekeeper/Kyverno, service mesh if present).
   - For each one, look up its own release notes/changelog/compatibility matrix for the target Kubernetes version — its GitHub releases page is almost always the authoritative source, not a generic web search. `references/compatibility-research.md` has the known sources and gotchas for the common ones (e.g. the ALB controller's version lag is a recurring, known issue — check it every time, not just when something looks old).
   - For the EKS-managed addons specifically, pull the actual compatible version set live via `aws eks describe-addon-versions --kubernetes-version <target>` — never assume or hardcode a version pairing, these change often.

7. **Rate every finding.** Critical (blocks the upgrade outright, no safe path forward without remediation first) → High (will break post-upgrade, but a known fix exists) → Medium (deprecated or soon-removed, not an immediate break) → Low (informational/cosmetic, e.g. a controller is a few patches behind but nothing version-gated). Don't collapse this into a single "looks fine" — the report's entire value is letting a human triage by severity instead of re-deriving it.

8. **Cross-check against a lower environment, if one exists.** If dev/staging already sits on the target version, pull its history — did it hit any of the issues found here? That's free validation; use it.

## Write the report

Write a single local markdown file (don't try to push it to Confluence or anywhere else — that's for the human to do once they've reviewed it). Use the structure in `references/report-template.md`, which mirrors the team's existing upgrade runbook format so it can be pasted straight into their usual doc space. Default the path to `.eks-upgrade/<aws_account_alias>/<region>/<cluster-name>/<current>-to-<target>/upgrade-prep.md` in the current repo unless the user asks for somewhere else — everything this skill (and `eks-upgrade-execute`) writes lives under the single `.eks-upgrade/` directory, never a second `eks-upgrade/` without the dot.

Lead the report with a clear **go / no-go / go-with-conditions** recommendation and the list of anything Critical or High that needs resolving first — don't bury the verdict under the raw findings. Everything below that is the evidence for how you got there.

Once it's written, record its path in `report_path` in `.eks-upgrade/<aws_account_alias>/<region>/<cluster-name>/config.yaml` (see `references/cluster-config.md`) — this is how `eks-upgrade-execute` finds the report later, including when the user chose a non-default path. Don't skip this just because the default path is predictable; a later run shouldn't have to guess.

## When you're done

Tell the user where the report landed, summarize the verdict and any Critical/High items in a couple of sentences, and stop. Don't propose opening tickets, editing IaC, or triggering CI yourself — flag that those are the logical next step and let the human (or the execution skill, once it exists) take it from here.
