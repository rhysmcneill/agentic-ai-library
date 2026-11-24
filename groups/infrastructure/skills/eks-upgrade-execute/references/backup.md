# Backup: commands and what they actually protect

Run this before any version bump, every execution run. The point isn't ceremony — it's that a backup taken *after* something's already gone wrong is useless, so it has to happen while the cluster is still known-healthy (confirmed by Step 1's fresh check).

## What a backup here protects, and what it doesn't

- **Does protect:** workload manifests, persistent volume data, and cluster-scoped resources — recoverable by restoring into a new or the same cluster.
- **Does not protect:** the control-plane version itself. Amazon EKS does not support downgrading a cluster's Kubernetes version. Once the control plane moves, there is no "restore the control plane to its previous version" option — backups exist so that if something is unrecoverable at the workload level, you can rebuild elsewhere, not so the upgrade itself can be undone.

Say this plainly to the user before proceeding, not just in passing — it changes what "recovery" means if something goes wrong later in the run.

## Velero (workload + PV backup)

```bash
# Confirm Velero is actually installed and healthy before relying on it
kubectl get pods -n velero
velero backup-location get

# Trigger an on-demand backup
velero backup create "eks-upgrade-<cluster-name>-<date>" \
  --include-cluster-resources=true \
  --wait

# Confirm it actually completed, don't just trust the command returned 0
velero backup describe "eks-upgrade-<cluster-name>-<date>" --details
```

A backup status of anything other than `Completed` (e.g. `PartiallyFailed`) needs the user's attention before you proceed — don't treat "it ran" as "it succeeded."

## AWS Backup (for EBS volumes / resources Velero doesn't cover)

```bash
# If an on-demand backup job rather than a scheduled plan is what's needed:
aws backup start-backup-job \
  --backup-vault-name <vault> \
  --resource-arn <ebs-volume-or-resource-arn> \
  --iam-role-arn <backup-role-arn>

# Poll until completed
aws backup describe-backup-job --backup-job-id <job-id> --query 'State'
```

If the cluster relies on EBS-backed PVs for anything Velero's CSI snapshot integration doesn't already cover, check whether an AWS Backup plan exists and covers the relevant volumes; if not, this is worth flagging to the user as a gap even if it's out of scope to fix as part of this run.

## If no backup tooling is present at all

Don't skip this step silently — tell the user there's no backup mechanism in place for this cluster and ask explicitly whether they want to proceed without one, or set one up first. Proceeding without any backup is a real decision they should make knowingly, not one made for them by omission.
