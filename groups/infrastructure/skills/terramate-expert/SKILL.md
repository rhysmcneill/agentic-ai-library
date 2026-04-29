---
name: terramate-expert
description: Terramate CLI, Cloud, and Catalyst best practices and usage guides. This skill should be used when working with Terramate stacks, orchestration, code generation, Cloud integration, or Catalyst components and bundles.
license: MIT
metadata:
  source: https://github.com/terramate-io/agent-skills
  author: terramate
  version: "1.0.0"
---

# Terramate Expert

Comprehensive guide for Terramate CLI, Cloud, and Catalyst, maintained by Terramate. Contains best practices and usage patterns for stack management, orchestration, code generation, Cloud integration, and Catalyst components/bundles.

## When to Apply

Reference these guidelines when:
- Creating and organizing Terramate stacks
- Orchestrating commands across multiple stacks
- Using code generation to keep configurations DRY
- Integrating with Terramate Cloud for observability
- Creating Catalyst components and bundles
- Setting up CI/CD workflows with Terramate
- Managing stack dependencies and execution order

## Rule Categories by Priority

| Priority | Category | Impact | Prefix |
|----------|----------|--------|--------|
| 1 | CLI Fundamentals | CRITICAL | `cli-` |
| 2 | CLI Orchestration | HIGH | `cli-orchestration-` |
| 3 | CLI Code Generation | HIGH | `cli-codegen-` |
| 4 | CLI Configuration | MEDIUM-HIGH | `cli-config-` |
| 5 | Terramate Cloud | MEDIUM-HIGH | `cloud-` |
| 6 | Terramate Catalyst | MEDIUM | `catalyst-` |
| 7 | CI/CD Integration | MEDIUM | `cicd-` |
| 8 | Advanced Patterns | LOW-MEDIUM | `advanced-` |

## Quick Reference

### 1. CLI Fundamentals (CRITICAL)

- `cli-stack-structure` — Organize stacks with clear directory structure
- `cli-stack-config` — Configure stacks with proper stack blocks
- `cli-stack-metadata` — Use metadata for stack identification and filtering

### 2. CLI Orchestration (HIGH)

- `cli-orchestration-run` — Run commands across stacks efficiently
- `cli-orchestration-change-detection` — Use change detection to limit execution scope
- `cli-orchestration-parallel` — Leverage parallel execution for independent stacks
- `cli-orchestration-dependencies` — Manage stack dependencies and execution order

### 3. CLI Code Generation (HIGH)

- `cli-codegen-hcl` — Use `generate_hcl` for DRY Terraform code
- `cli-codegen-file` — Use `generate_file` for file generation patterns
- `cli-codegen-provider` — Generate provider configurations dynamically

### 4. CLI Configuration (MEDIUM-HIGH)

- `cli-config-globals` — Use globals for shared configuration across stacks
- `cli-config-lets` — Use lets for stack-local computed values
- `cli-config-metadata` — Leverage metadata for stack information

### 5. Terramate Cloud (MEDIUM-HIGH)

- `cloud-integration` — Set up Cloud connection and authentication
- `cloud-drift-management` — Configure drift detection and reconciliation
- `cloud-observability` — Use Cloud dashboard for stack visibility

### 6. Terramate Catalyst (MEDIUM)

- `catalyst-components` — Create reusable component blueprints
- `catalyst-bundles` — Define bundles for component composition
- `catalyst-instantiation` — Instantiate bundles correctly

### 7. CI/CD Integration (MEDIUM)

- `cicd-github-actions` — Set up GitHub Actions workflows
- `cicd-preview-workflows` — Create preview workflows for PRs
- `cicd-deployment-workflows` — Configure deployment automation

### 8. Advanced Patterns (LOW-MEDIUM)

- `advanced-workflows` — Create complex multi-step workflows
- `advanced-codegen-patterns` — Advanced code generation techniques

## How to Use

Apply rules by ID when working with Terramate configurations. Each rule ID maps to a specific pattern:

- **CRITICAL rules** — always apply; these are foundational to correct Terramate usage
- **HIGH rules** — apply by default for any orchestration or code generation task
- **MEDIUM-HIGH rules** — apply when configuring Cloud integration or complex globals
- **MEDIUM rules** — apply for CI/CD setup and Catalyst work
- **LOW-MEDIUM rules** — apply for advanced workflows and complex code generation

Read individual rule files in `references/` for detailed explanations and code examples:

```
references/cli-stack-structure.md
references/cli-orchestration-change-detection.md
references/cli-codegen-hcl.md
references/cloud-integration.md
```

See `references/rule-index.md` for the full list of all rules mapped to their local files. Rules without a local file can be applied using the summary in the Quick Reference above.
