---
name: eks-upgrade-execute
description: Executes an already-prepared Amazon EKS cluster version upgrade through IaC and CI/CD, with a human approving every PR merge and every node-disruptive step — never autonomous, never skips a checkpoint. Takes a fresh backup (Velero/AWS Backup), bumps the EKS control-plane version via IaC and opens a PR, waits for human merge, upgrades worker nodes with compute-type-aware logic (managed node groups vs. Karpenter vs. Fargate), runs automated health gates with predefined abort thresholds, then bumps addon versions via a second PR, again waiting for human merge. Requires a go/no-go readiness report from the eks-upgrade-prep skill first — refuses to proceed without one, or if it says no-go. Use whenever the user wants to actually carry out, run, kick off, or execute an EKS Kubernetes version upgrade (as opposed to just preparing/auditing for one). Never merges a pull request, never bypasses a required human checkpoint, and never attempts a control-plane downgrade (EKS doesn't support that) — only forward fixes.
metadata:
  version: "1.0.0"
---

# EKS Upgrade Execute

This is the half of an EKS upgrade that actually touches the cluster, after `eks-upgrade-prep` has already said it's safe to. The two skills are a pair: prep investigates and reports, this one carries the plan out — through the same IaC/CI pipeline a human would use, with a human approving every point where the blast radius is real. Nothing here is a shortcut around that pipeline; it's a thin layer that drives it and watches the result so a human doesn't have to babysit every command and PR by hand.

**Every PR merge and every node-disruptive action needs an explicit human go-ahead.** Opening a PR, running read-only checks, and triggering a backup are fine to do on your own initiative as part of the flow below — merging anything, and triggering worker node replacement, are not. If you ever find yourself about to do either without the human having just said yes to that specific thing, stop and ask instead.

## Step 0: Load context and refuse to proceed without a go

1. Read `.eks-upgrade/<cluster-name>.yaml` (same file `eks-upgrade-prep` writes — see `references/cluster-config.md` for the schema). If it doesn't exist, tell the user to run `eks-upgrade-prep` first and stop here; don't try to reconstruct this from scratch.
2. Find that cluster's prep report (the path is recorded in the config, or defaults to `./eks-upgrade/<cluster-name>-<current>-to-<target>-prep.md`). Read it.
3. Check the verdict:
   - **NO-GO** — stop immediately and say why. Don't offer to proceed anyway.
   - **GO WITH CONDITIONS** — list the conditions back to the user and get explicit confirmation each one is actually resolved before continuing. Don't take their word for "yes it's fine" without naming what was supposedly fixed.
   - **GO** — continue.
4. If the report is more than a few days old, say so and ask whether to re-run the relevant prep checks (cluster state drifts — an addon could have changed, a new workload could have appeared with no PDB) rather than silently trusting a stale report.

## Step 1: Fresh final check

Re-run the fast subset of prep's checks against current state — not the whole compatibility research, just: node health, pod health, PDB/drain-blocker status, and ArgoCD (or whatever GitOps controller) sync state. This is specifically to catch drift since the prep report was written, not to redo the full audit. If anything's unhealthy here, stop and surface it — don't proceed into an upgrade on top of an already-unhealthy cluster.

## Step 2: Backup

Trigger a fresh on-demand backup before touching anything — every run, regardless of whether a recent one exists. See `references/backup.md` for the Velero and AWS Backup commands and how to confirm completion before moving on.

Be precise with the user about what this backup buys them: it's workload and data recovery (restore into a new or the same cluster), **not** a way to undo the control-plane version bump — EKS does not support downgrading a cluster's Kubernetes version. If anything goes wrong after the control plane moves, the path forward is fixing forward or restoring workloads elsewhere, never rolling the control plane back.

## Step 3: Control-plane version bump

1. Locate the version field using the path recorded in the cluster config (see `references/cluster-config.md` if you need to re-derive it).
2. Edit it to the target version, open a PR with a clear description (what's changing, link to the prep report), and **stop**.
3. Tell the user the PR is ready and that you need them to review and merge it — then wait. Don't poll aggressively; ask them to let you know once it's merged, or check back at a reasonable interval.
4. Once merged, confirm the CI/CD pipeline actually ran and the control plane reports the target version (`aws eks describe-cluster`) before moving on.

## Step 4: Checkpoint — confirm before touching nodes

Worker node replacement is the step that actually disrupts running pods. Even though the control-plane PR is already merged, get an explicit, separate go-ahead from the user before triggering it — summarize current cluster health first so they're deciding with current information, not the state from an hour ago.

## Step 5: Worker node upgrade

Branch by compute type (recorded in the cluster config) — see `references/node-upgrade.md` for the exact commands and what "done" looks like for each:

- **Managed node groups** — trigger the node group version update and track its progress.
- **Karpenter** — check for drift detection/consolidation already handling it; if not, trigger replacement explicitly. Don't assume it happens on its own just because the control plane moved.
- **Fargate** — no persistent nodes to replace, but existing pods keep running under the old version context until rescheduled; trigger a controlled rollout of Fargate-backed workloads.
- **Mixed** — handle each piece according to its own type; don't apply managed-node-group logic to a Karpenter-managed pool or vice versa.

Monitor against the health gates and abort thresholds in `references/checkpoints.md` throughout. If a threshold is breached, **stop and escalate to the user — don't try to self-correct or push through.** There's no automatic rollback available here (see Step 2); the only way out of a bad state is a human deciding the next move with full information.

## Step 6: Addon version bump

Once nodes are healthy on the target version: bump the addon versions (pulled fresh from `aws eks describe-addon-versions --kubernetes-version <target>`, same as prep did — don't reuse prep's numbers without reconfirming, time may have passed), open a second PR, and **stop** for human merge, exactly as in Step 3. Never merge this one either.

## Step 7: Final validation

After the addon PR is merged: confirm every addon reports the target version and `Active` status, nodes are all on the target Kubernetes version, and pod health matches the Step 1 baseline (or better).

## Step 8: Close out

1. Append an "Execution Log" section to the same report file `eks-upgrade-prep` wrote — what actually happened, timings, anything that deviated from plan, any threshold that got close to breaching even if it didn't. This is as valuable as the prep findings for whoever runs the next upgrade.
2. Remind the user which tracking tickets raised in the prep report (if any) should now be closed — don't close or edit them yourself, just list them.
3. Summarize the outcome in a couple of sentences and stop.
