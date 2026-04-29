# Terramate Best Practices — Rule Index

Detailed rule files with anti-pattern and best-practice code examples. Read any rule file for the full explanation.

> **Note:** Rules marked _(no local file)_ do not yet have a detailed rule file in the upstream repo. Apply them using the summary description in SKILL.md.

## CRITICAL Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `cli-stack-structure` | [cli-stack-structure.md](cli-stack-structure.md) | Organize stacks with clear directory structure |
| `cli-stack-config` | [cli-stack-config.md](cli-stack-config.md) | Configure stacks with proper stack blocks |
| `cli-stack-metadata` | [cli-stack-metadata.md](cli-stack-metadata.md) | Use metadata for stack identification and filtering |

## HIGH Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `cli-orchestration-run` | [cli-orchestration-run.md](cli-orchestration-run.md) | Run commands across stacks efficiently |
| `cli-orchestration-change-detection` | [cli-orchestration-change-detection.md](cli-orchestration-change-detection.md) | Limit execution scope with change detection |
| `cli-orchestration-parallel` | [cli-orchestration-parallel.md](cli-orchestration-parallel.md) | Parallel execution for independent stacks |
| `cli-orchestration-dependencies` | [cli-orchestration-dependencies.md](cli-orchestration-dependencies.md) | Stack dependencies and execution order |
| `cli-codegen-hcl` | [cli-codegen-hcl.md](cli-codegen-hcl.md) | `generate_hcl` for DRY Terraform code |
| `cli-codegen-file` | [cli-codegen-file.md](cli-codegen-file.md) | `generate_file` for file generation patterns |
| `cli-codegen-provider` | [cli-codegen-provider.md](cli-codegen-provider.md) | Dynamic provider configuration generation |

## MEDIUM-HIGH Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `cli-config-globals` | [cli-config-globals.md](cli-config-globals.md) | Globals for shared configuration across stacks |
| `cli-config-lets` | _(no local file)_ | Lets for stack-local computed values |
| `cli-config-metadata` | _(no local file)_ | Leverage metadata for stack information |
| `cloud-integration` | [cloud-integration.md](cloud-integration.md) | Cloud connection and authentication |
| `cloud-drift-management` | [cloud-drift-management.md](cloud-drift-management.md) | Drift detection and reconciliation |
| `cloud-observability` | _(no local file)_ | Cloud dashboard for stack visibility |

## MEDIUM Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `catalyst-components` | [catalyst-components.md](catalyst-components.md) | Reusable component blueprints |
| `catalyst-bundles` | [catalyst-bundles.md](catalyst-bundles.md) | Bundles for component composition |
| `catalyst-instantiation` | _(no local file)_ | Correct bundle instantiation |
| `cicd-github-actions` | [cicd-github-actions.md](cicd-github-actions.md) | GitHub Actions workflow setup |
| `cicd-preview-workflows` | _(no local file)_ | Preview workflows for PRs |
| `cicd-deployment-workflows` | _(no local file)_ | Deployment automation |

## LOW-MEDIUM Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `advanced-workflows` | _(no local file)_ | Complex multi-step workflows |
| `advanced-codegen-patterns` | _(no local file)_ | Advanced code generation techniques |
