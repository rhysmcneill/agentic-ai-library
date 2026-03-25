# Workflow Patterns

Patterns for structuring multi-step workflows and decision logic in skills.

## Sequential Workflows

Break complex tasks into numbered steps. Give an overview early in SKILL.md so the agent knows the full process before starting.

```markdown
Deploying a service involves these steps:

1. Validate configuration (`scripts/validate.sh`)
2. Plan changes (`terraform plan`)
3. Apply changes (`terraform apply`)
4. Verify deployment (`kubectl get pods`)
```

For particularly complex workflows, provide a checklist the agent can track:

```markdown
Copy this checklist and track progress in your task log:

- [ ] Step 1: Validate configuration
- [ ] Step 2: Plan changes
- [ ] Step 3: Apply changes
- [ ] Step 4: Verify deployment
```

## Conditional Workflows

Guide agents through decision points with clear branching:

```markdown
1. Determine the target environment:

   **Staging?** → Proceed to "Staging workflow"
   **Production?** → STOP and request explicit user approval

2. Staging workflow:
   - Use `config-staging.yaml`
   - Run deployment script

3. Production workflow:
   - Use `config-production.yaml`
   - Verify metrics before proceeding
```

When branches get large, push them into separate reference files:

```markdown
| Target | Read This Reference |
|-----------|-------------------|
| AWS | `references/deploy-aws.md` |
| GCP | `references/deploy-gcp.md` |
```

## Feedback Loops (Validate-Fix-Repeat)

Use a validate-fix-repeat pattern for tasks where output quality matters:

```markdown
## Validation loop

1. Generate the CloudFormation template.
2. Validate immediately: `cfn-lint template.yaml`
3. If validation fails:
   - Review the error message
   - Fix the issues in `template.yaml`
   - Run validation again
4. Only proceed to deployment when validation passes
```

This pattern works well for:
- Code generation (lint → fix → re-lint)
- Infrastructure as code (plan → fix → re-plan)
- Data processing (check schema → fix → re-check)

## Plan-Validate-Execute

For complex, high-stakes tasks, have the agent create a plan file before executing:

```markdown
1. Analyze the request and generate `plan.json` with requested database schema modifications
2. Validate the plan: `uv run scripts/validate_schema_plan.py plan.json`
3. If validation fails, revise the plan and re-validate
4. Execute the plan: `uv run scripts/apply_schema.py plan.json`
5. Verify the result
```

Benefits:
- Catches errors before irreversible changes are applied
- Machine-verifiable intermediate output
- Agent can iterate on the plan without touching the actual database/system
- Clear debugging — error messages point to specific plan entries

Use this pattern for: batch operations, destructive changes, complex data transformations, database migrations.
