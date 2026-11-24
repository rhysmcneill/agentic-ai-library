# Worker node upgrade: by compute type

This is the step the parent story behind this skill specifically flagged as under-handled in most manual runbooks: "the control plane moved" and "the nodes are upgraded" are not the same event, and what bridges them differs completely by compute type. Don't apply one type's logic to another.

## Managed node groups

In a properly configured IaC setup, the node group's version/AMI release is tied to the same variable as the control-plane version (or to a Terraform/Terramate module that does this for you). That means merging the Step 3 PR already started the replacement — AWS handles draining old nodes and bringing up new ones as part of that same apply. There's nothing for this skill to separately trigger here; the job is to gather context before it starts, then watch it happen.

Before the Step 3 PR gets merged, check and tell the user:

```bash
# Confirm the node group's version is actually coupled to the cluster version in this IaC,
# not pinned independently — this determines whether merging Step 3 starts the node rollout too
grep -n "version\|ami_release" <node-group IaC file>

aws eks describe-nodegroup --cluster-name <cluster> --nodegroup-name <nodegroup> \
  --query 'nodegroup.{version:version,amiReleaseVersion:releaseVersion}'
```

- **Coupled to the cluster version** (the common case): tell the user plainly that merging the control-plane PR will also kick off the node group's rolling replacement in the same apply — their merge decision in Step 3 already covers this disruption, there's no separate action later to gate. Once merged, just track it:

  ```bash
  aws eks describe-update --name <cluster> --nodegroup-name <nodegroup> --update-id <update-id> \
    --query 'update.{status:status,errors:errors}'
  ```

  "Done" means `describe-update` reports `Successful` and every node in the group reports the target version (`kubectl get nodes -o wide`).

- **Pinned independently** (its own version field, not derived from the cluster version): this needs its own IaC edit and PR, exactly like Step 3 — bump it, open a PR, and get a separate explicit merge from the user before it starts. Never bypass IaC by calling `aws eks update-nodegroup-version` directly; that would change live state out from under the next `terraform plan`/`terramate run` and cause drift.

Either way, AWS handles the drain/cordon sequencing itself once the update is underway — your job is to watch it against the gates in `references/checkpoints.md`, not drive individual nodes.

## Karpenter

Like managed node groups, this is usually automatic too — don't assume otherwise by default. When the EC2NodeClass references an AMI family/alias (rather than a pinned AMI ID), Karpenter's own drift detection notices the control-plane version change, marks existing nodeclaims `Drifted`, and replaces them itself — at whatever rate the NodePool's `spec.disruption.budgets` allows (e.g. 10% of nodes at a time is a common setting). That's the same kind of built-in, paced rollout as a managed node group's update, just driven by Karpenter's disruption controller instead of the EKS API. If that's how this cluster is set up, merging the Step 3 PR is what starts it — there's nothing further for this skill to trigger.

Before the Step 3 PR gets merged, check and tell the user which case applies:

```bash
# Confirm the EC2NodeClass resolves to a new AMI once the control plane moves
# (an alias like al2023@latest will; a pinned AMI ID won't)
kubectl get ec2nodeclass -o yaml

# Confirm disruption is actually enabled and at what rate
kubectl get nodepool -o yaml | grep -A5 "disruption:"
```

- **AMI alias + a nonzero disruption budget** (the common case): tell the user plainly that merging the control-plane PR will also set drift-based replacement in motion automatically, at the configured rate — their merge decision in Step 3 already covers this disruption. Once merged, just track it:

  ```bash
  kubectl get nodeclaims -o json | jq '.items[] | {name: .metadata.name, drifted: .status.conditions[] | select(.type=="Drifted")}'
  ```

  "Done" means no nodeclaims report drift and every node is on the target version.

- **Pinned AMI ID, a zero/blocking disruption budget, or `do-not-disrupt` annotations present**: drift won't resolve on its own, and this cluster is supposed to be fully IaC/GitOps-managed — so the fix is an IaC change, the same way an independently-versioned managed node group gets one, not an imperative `kubectl delete nodeclaim`. Deleting a nodeclaim by hand bypasses the same GitOps path every other change in this skill goes through, for no good reason here: the underlying config (the NodePool's `disruption.budgets`, the EC2NodeClass's AMI selector, or a workload's `do-not-disrupt` annotation if that's what's blocking it) is ordinary IaC/manifest state, so fix *that*, open a PR, and get the same explicit merge go-ahead as Step 3. Once merged, Karpenter's own disruption controller takes it from there — same automatic, paced replacement as the common case above, just one PR later than it could have been.

Either way, replace incrementally and check pod health against the gates in `references/checkpoints.md` between batches — don't let a loose disruption budget replace everything at once without checking in.

## Fargate

There's no persistent node to replace — each pod runs in its own isolated compute environment sized at pod creation, using the Kubernetes version active on the control plane at that time. Existing pods keep running under their original version context until they're rescheduled.

```bash
# Trigger a controlled rollout of Fargate-backed workloads so they pick up the new version context
kubectl rollout restart deployment <deployment> -n <namespace>

# Confirm all pods in the Fargate profile are now on fresh compute
kubectl get pods -n <namespace> -o wide
```

Roll these out deliberately (one deployment/namespace at a time, checking health between), not as one blanket restart across every Fargate-backed workload simultaneously.

## Mixed compute

Treat each pool according to its own type — a cluster with both Karpenter and a managed system-pod node group needs both procedures above, run against their respective pools, not one applied to the whole cluster.
