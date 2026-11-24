# Worker node upgrade: by compute type

This is the step the parent story behind this skill specifically flagged as under-handled in most manual runbooks: "the control plane moved" and "the nodes are upgraded" are not the same event, and what bridges them differs completely by compute type. Don't apply one type's logic to another.

## Managed node groups

The version bump usually isn't automatic just because the control plane moved — managed node groups can intentionally trail the control plane by up to one minor version.

```bash
# Trigger the update (if not already driven by the same IaC change as the control plane)
aws eks update-nodegroup-version --cluster-name <cluster> --nodegroup-name <nodegroup>

# Track progress
aws eks describe-update --name <cluster> --nodegroup-name <nodegroup> --update-id <update-id> \
  --query 'update.{status:status,errors:errors}'
```

This performs a managed rolling replacement — AWS handles the drain/cordon sequencing. Your job is to watch it, not drive each node individually. "Done" means `describe-update` reports `Successful` and every node in the group reports the target version (`kubectl get nodes -o wide`).

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
