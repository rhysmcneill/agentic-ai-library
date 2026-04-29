# Terraform Best Practices — Rule Index

Detailed rule files with anti-pattern and best-practice code examples. Read any rule file for the full explanation.

## CRITICAL Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `org-version-control` | [org-version-control.md](org-version-control.md) | All Terraform code in version control |
| `org-workspaces` | [org-workspaces.md](org-workspaces.md) | One workspace per environment per configuration |
| `org-access-control` | [org-access-control.md](org-access-control.md) | Control who can change what infrastructure |
| `org-change-workflow` | [org-change-workflow.md](org-change-workflow.md) | Formal process for infrastructure changes |
| `org-audit-logging` | [org-audit-logging.md](org-audit-logging.md) | Track all infrastructure changes |
| `state-remote-backend` | [state-remote-backend.md](state-remote-backend.md) | Always use remote state backends |
| `state-locking` | [state-locking.md](state-locking.md) | Enable state locking to prevent corruption |
| `state-import` | [state-import.md](state-import.md) | Import existing infrastructure into Terraform |
| `security-no-hardcoded-secrets` | [security-no-hardcoded-secrets.md](security-no-hardcoded-secrets.md) | Never hardcode secrets in code |
| `security-credentials` | [security-credentials.md](security-credentials.md) | Use OIDC, Vault, IAM roles — never static credentials |
| `security-iam-least-privilege` | [security-iam-least-privilege.md](security-iam-least-privilege.md) | Follow least privilege principle |

## HIGH Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `module-single-responsibility` | [module-single-responsibility.md](module-single-responsibility.md) | One module per logical component |
| `module-naming` | [module-naming.md](module-naming.md) | Consistent naming: `terraform-<provider>-<name>` |
| `module-versioning` | [module-versioning.md](module-versioning.md) | Version all module references |
| `module-composition` | [module-composition.md](module-composition.md) | Compose modules like building blocks |
| `module-registry` | [module-registry.md](module-registry.md) | Use existing community/shared modules |

## MEDIUM-HIGH Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `resource-naming` | [resource-naming.md](resource-naming.md) | Consistent naming conventions |
| `resource-tagging` | [resource-tagging.md](resource-tagging.md) | Tag all resources for cost tracking |
| `resource-lifecycle` | [resource-lifecycle.md](resource-lifecycle.md) | Use `prevent_destroy`, `ignore_changes` |
| `resource-count-vs-foreach` | [resource-count-vs-foreach.md](resource-count-vs-foreach.md) | Prefer `for_each` over `count` |
| `resource-immutable` | [resource-immutable.md](resource-immutable.md) | Prefer immutable infrastructure patterns |

## MEDIUM Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `variable-types` | [variable-types.md](variable-types.md) | Specific types, positive naming, nullable |
| `variable-validation` | [variable-validation.md](variable-validation.md) | Validation rules for early error detection |
| `variable-sensitive` | [variable-sensitive.md](variable-sensitive.md) | Mark secrets as sensitive, no defaults |
| `variable-descriptions` | [variable-descriptions.md](variable-descriptions.md) | Document all variables |
| `output-descriptions` | [output-descriptions.md](output-descriptions.md) | Document all outputs |
| `output-no-secrets` | [output-no-secrets.md](output-no-secrets.md) | Never output secrets directly |
| `language-no-heredoc-json` | [language-no-heredoc-json.md](language-no-heredoc-json.md) | Use `jsonencode`/`yamlencode` |
| `language-locals` | [language-locals.md](language-locals.md) | Name complex expressions with locals |
| `language-linting` | [language-linting.md](language-linting.md) | Run `terraform fmt` and `tflint` |
| `language-data-sources` | [language-data-sources.md](language-data-sources.md) | Use data sources, not hardcoded values |
| `language-dynamic-blocks` | [language-dynamic-blocks.md](language-dynamic-blocks.md) | Dynamic blocks for DRY code |
| `provider-version-constraints` | [provider-version-constraints.md](provider-version-constraints.md) | Pin provider versions |

## LOW-MEDIUM / LOW Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `perf-parallelism` | [perf-parallelism.md](perf-parallelism.md) | Tune parallelism for large deployments |
| `perf-debug` | [perf-debug.md](perf-debug.md) | Enable debug logging for troubleshooting |
| `test-strategies` | [test-strategies.md](test-strategies.md) | Validate → lint → plan → integration pyramid |
| `test-policy-as-code` | [test-policy-as-code.md](test-policy-as-code.md) | OPA, Checkov, tfsec policy checks |
