---
name: eks-upgrade-execute
description: Executes an already-prepared Amazon EKS cluster version upgrade through IaC and CI/CD, with a human approving every PR merge and every node-disruptive step. Takes a fresh backup (Velero/AWS Backup), bumps the EKS control-plane version via IaC and opens a PR (flagging beforehand whether that merge also triggers node replacement for a coupled managed node group), handles Karpenter/independent-node-group/Fargate node upgrades with their own trigger and go-ahead, runs automated health gates with predefined abort thresholds, then bumps addon versions via a second PR. Requires a go/no-go report from eks-upgrade-prep first; refuses to proceed without one or if it says no-go. Use whenever the user wants to carry out, run, kick off, or execute an EKS Kubernetes version upgrade (as opposed to just preparing/auditing for one). Never merges a PR, never skips a checkpoint, never attempts a control-plane downgrade (not supported by EKS) — only forward fixes.
metadata:
  version: "1.0.1"
---

# EKS Upgrade Execute

This is the half of an EKS upgrade that actually touches the cluster, after `eks-upgrade-prep` has already said it's safe to. The two skills are a pair: prep investigates and reports, this one carries the plan out — through the same IaC/CI pipeline a human would use, with a human approving every point where the blast radius is real. Nothing here is a shortcut around that pipeline; it's a thin layer that drives it and watches the result so a human doesn't have to babysit every command and PR by hand.

**Every PR merge and every node-disruptive action needs an explicit human go-ahead.** Opening a PR, running read-only checks, and triggering a backup are fine to do on your own initiative as part of the flow below — merging anything, and triggering worker node replacement, are not. If you ever find yourself about to do either without the human having just said yes to that specific thing, stop and ask instead.

## Step 0: Load context and refuse to proceed without a go

1. Read `.eks-upgrade/<cluster-name>.yaml` (same file `eks-upgrade-prep` writes — see `references/cluster-config.md` for the schema). If it doesn't exist, tell the user to run `eks-upgrade-prep` first and stop here; don't try to reconstruct this from scratch.
2. Find that cluster's prep report: check `report_path` in the config first (recent prep runs write this), and fall back to `.eks-upgrade/<aws_account_alias>/<region>/<cluster-name>/<current>-to-<target>/upgrade-prep.md` only if that field is absent — which means this cluster's prep report predates that field, not that one doesn't exist. If neither turns up a real report, don't guess further; tell the user and ask them to point you at it or re-run prep. Read it.
3. Check the verdict:
   - **NO-GO** — stop immediately and say why. Don't offer to proceed anyway.
   - **GO WITH CONDITIONS** — list the conditions back to the user and get explicit confirmation each one is actually resolved before continuing. Don't take their word for "yes it's fine" without naming what was supposedly fixed.
   - **GO** — continue.
4. If the report is more than a few days old, say so and ask whether to re-run the relevant prep checks (cluster state drifts — an addon could have changed, a new workload could have appeared with no PDB) rather than silently trusting a stale report.

## Step 1: Fresh final check

Re-run the fast subset of prep's checks against current state — not the whole compatibility research, just: node health, pod health, PDB/drain-blocker status, and ArgoCD (or whatever GitOps controller) sync state. This is specifically to catch drift since the prep report was written, not to redo the full audit. If anything's unhealthy here, stop and surface it — don't proceed into an upgrade on top of an already-unhealthy cluster.

## Step 2: Backup

Trigger a fresh on-demand backup before touching anything — every run, regardless of whether a recent one exists. See `references/backup.md` for the Velero and AWS Backup commands and how to confirm completion before moving on. If AWS Backup is in play, confirm the vault, IAM role, and retention period with the user (defaults are a starting suggestion, not something to apply silently) and persist them to the cluster config per `references/cluster-config.md` so later runs don't re-ask.

Be precise with the user about what this backup buys them: it's workload and data recovery (restore into a new or the same cluster), **not** a way to undo the control-plane version bump — EKS does not support downgrading a cluster's Kubernetes version. If anything goes wrong after the control plane moves, the path forward is fixing forward or restoring workloads elsewhere, never rolling the control plane back.

## Step 3: Control-plane version bump

1. Locate the version field using the path recorded in the cluster config (see `references/cluster-config.md` if you need to re-derive it).
2. Before opening the PR, check whether node replacement rides along with this same change (see `references/node-upgrade.md`). This is the common case for both compute types, not an edge case: a managed node group whose version/AMI release is tied to the same IaC variable as the control plane updates in the same apply, and Karpenter whose EC2NodeClass references an AMI alias (not a pinned AMI ID) will drift-detect and start replacing nodes itself, at whatever rate its NodePool's disruption budget allows, the moment the control plane moves. Tell the user plainly which is the case for this cluster, so their merge decision in the next step already accounts for whether it also disrupts nodes — don't let that surface as a surprise after the fact.
3. Edit the version field, open a PR with a clear description (what's changing, whether it also triggers node replacement, link to the prep report), and **stop**.
4. Tell the user the PR is ready and that you need them to review and merge it — then wait. Don't poll aggressively; ask them to let you know once it's merged, or check back at a reasonable interval.
5. Once merged, confirm the CI/CD pipeline actually ran and the control plane reports the target version (`aws eks describe-cluster`) before moving on.

## Step 4: Checkpoint — confirm before anything that disrupts nodes

This gate only applies to whatever actually requires *this skill* to take an action that disrupts nodes — it is not a blanket pause after every merge, because where replacement is already automatic (a coupled managed node group, or Karpenter with an AMI alias and a working disruption budget) the disruption started the moment the human merged the Step 3 PR, and that merge was already their go-ahead for it, per Step 3.2. Where this gate does apply:

- **An independently-versioned managed node group, or Karpenter not configured for automatic drift replacement** (pinned AMI ID, a zero/blocking disruption budget, or a blocking `do-not-disrupt` annotation) — this cluster is IaC/GitOps-managed, so the fix is an IaC change (bump the node group version, adjust the NodePool/EC2NodeClass, or remove the blocking annotation from the manifest it lives in), opened as a PR exactly like Step 3. Never fix this with an imperative command like `kubectl delete nodeclaim` — that bypasses the same GitOps path every other change here goes through, for no good reason. Get the explicit merge go-ahead for this PR, same as any other.
- **Fargate** rollouts of existing workloads have no IaC-level node resource to bump — triggering the rollout restart is a direct, imperative action with no PR step, so get an explicit go-ahead before running it.

Whichever applies, summarize current cluster health first so the user is deciding with current information, not the state from an hour ago.

## Step 5: Worker node rollout — context, then monitor

Branch by compute type (recorded in the cluster config) — see `references/node-upgrade.md` for the exact commands and what "done" looks like for each. The shape of this step differs by type:

- **Managed node groups (coupled) / Karpenter (AMI alias + working disruption budget)** — already set in motion by the Step 3 merge. Nothing to trigger; gather context beforehand (node count, batch size or disruption-budget rate) and monitor the rollout against the health gates as it happens.
- **Managed node groups (independently versioned) / Karpenter (misconfigured)** — bump via IaC and merge per Step 4, then Karpenter's or the EKS API's own disruption mechanism takes it from there — monitor the same way as the automatic case.
- **Fargate** — no persistent nodes; trigger a controlled rollout of Fargate-backed workloads per Step 4's go-ahead, then monitor.
- **Mixed** — handle each pool according to its own type; don't apply managed-node-group logic to a Karpenter-managed pool or vice versa.

Monitor against the health gates and abort thresholds in `references/checkpoints.md` throughout, whether or not you were the one who triggered the rollout. If a threshold is breached, **stop and escalate to the user — don't try to self-correct or push through.** There's no automatic rollback available here (see Step 2); the only way out of a bad state is a human deciding the next move with full information.

## Step 6: Addon version bump

Once nodes are healthy on the target version: bump the addon versions (pulled fresh from `aws eks describe-addon-versions --kubernetes-version <target>`, same as prep did — don't reuse prep's numbers without reconfirming, time may have passed), open a second PR, and **stop** for human merge, exactly as in Step 3. Never merge this one either.

## Step 7: Final validation

After the addon PR is merged: confirm every addon reports the target version and `Active` status, nodes are all on the target Kubernetes version, and pod health matches the Step 1 baseline (or better).

## Step 8: Close out

1. Append an "Execution Log" section to the same report file `eks-upgrade-prep` wrote — what actually happened, timings, anything that deviated from plan, any threshold that got close to breaching even if it didn't. This is as valuable as the prep findings for whoever runs the next upgrade.
2. Remind the user which tracking tickets raised in the prep report (if any) should now be closed — don't close or edit them yourself, just list them.
3. Summarize the outcome in a couple of sentences and stop.
