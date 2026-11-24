# Health gates and abort thresholds

These are starting defaults, not universal truths — every org's risk tolerance and workload sensitivity differs. Propose them to the user before the first node replacement batch and let them adjust; don't silently apply numbers that might be wrong for their environment. Once agreed, hold to them consistently rather than relitigating each time a gate is approached.

## Default gates (confirm or adjust with the user before Step 5)

| Signal | Default threshold | Action if breached |
|---|---|---|
| Node Ready count | ≥ 90% of expected nodes Ready within 10 minutes of a batch starting | Pause, do not start the next batch, escalate |
| Pod health | ≤ 5% of pods failing to reach `Running`/`Completed` within 10 minutes of node replacement | Pause, escalate |
| GitOps controller (ArgoCD or equivalent) | No new `OutOfSync` or `Degraded` applications beyond the pre-upgrade baseline from Step 1 | Pause, escalate |
| Addon status | Every addon reports `Active` (not `Degraded`/`Failed`) within 15 minutes of its version bump | Pause, escalate |

## What "escalate" actually means here

Stop advancing to the next step, summarize exactly what's unhealthy and what the numbers are (not just "something's wrong"), and ask the user what they want to do next. Plausible next steps they might choose — don't assume one for them:

- Wait longer (some transitions are just slow, not failed).
- Investigate the specific failure before deciding whether to continue.
- Pause here and resume later once it's understood.
- Accept a partial state and proceed anyway, with their explicit sign-off.

What "escalate" never means: automatically retrying the same action repeatedly, silently waiting past the threshold without saying so, or attempting to roll the control plane back (not possible — see `references/backup.md`).

## Watching between batches, not just at the end

For both managed node groups and Karpenter, don't replace every node and then check health once at the end — check after each batch (or at minimum, every few minutes during a long-running update) so a problem is caught while only a fraction of the cluster is affected, not after all of it has moved.
