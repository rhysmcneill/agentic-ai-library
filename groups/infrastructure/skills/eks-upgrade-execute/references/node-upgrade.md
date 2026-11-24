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

Karpenter does **not** automatically replace nodes just because the control plane's Kubernetes version changed. It provisions nodes from an EKS-optimized AMI referenced by the NodePool/EC2NodeClass, and only replaces existing nodes if something tells it to.

```bash
# Check whether drift detection already flagged existing nodes
kubectl get nodeclaims -o json | jq '.items[] | {name: .metadata.name, drifted: .status.conditions[] | select(.type=="Drifted")}'

# If AMI drift isn't yet reflected (new AMI release may lag the control-plane version slightly),
# confirm the EC2NodeClass is pointing at an AMI family/alias that will resolve to the target version
kubectl get ec2nodeclass -o yaml

# If nothing is drifting automatically, force replacement explicitly rather than waiting indefinitely:
kubectl annotate node <node-name> karpenter.sh/do-not-disrupt-
kubectl delete nodeclaim <nodeclaim-name>   # Karpenter provisions a replacement
```

Replace nodes incrementally, not all at once — check pod health against the gates in `references/checkpoints.md` between batches, same as you would for a managed node group's rolling update. "Done" means no nodeclaims report drift and all nodes are on the target version.

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
