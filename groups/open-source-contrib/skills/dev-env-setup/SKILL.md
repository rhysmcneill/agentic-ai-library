---
name: dev-env-setup
description: Installs and activates the development environment for an OSS repository, handling Python virtualenvs, Go module caches, Terraform providers, Node.js packages, and Rust toolchains. Use when asked to "set up the dev environment", "install dependencies", "prepare the repo for development", "activate the venv", "deactivate the venv", or any variant of environment setup or teardown.
---

# Dev Environment Setup

Detect the tech stack and install all dependencies into isolated environments before any code is written or tested.

## Step 1: Detect the Tech Stack

Check the repo root for these indicator files:

| File | Stack |
|------|-------|
| `pyproject.toml`, `requirements.txt`, `setup.py`, `setup.cfg`, `Pipfile` | Python |
| `go.mod` | Go |
| `*.tf`, `terraform.tfvars`, `.terraform.lock.hcl` | Terraform |
| `package.json` | Node.js / TypeScript |
| `Cargo.toml` | Rust |
| `Makefile`, `Taskfile.yml`, `justfile` | Task runner (check targets after other setup) |

A repo may use multiple stacks. Set up each one found.

---

## Python Setup

**Detect:** any of `pyproject.toml`, `requirements.txt`, `setup.py`, `setup.cfg`, `Pipfile`

### Create and activate the venv

```bash
# Create venv at .venv (skip if already exists)
python3 -m venv .venv

# Activate — ALWAYS do this before any pip/python commands
source .venv/bin/activate
```

> After activation, `which python` should resolve to `.venv/bin/python`.
> Confirm with: `python --version && echo "venv: $VIRTUAL_ENV"`

### Install dependencies (pick the first match found)

```bash
# pyproject.toml (PEP 517 / modern)
pip install -e ".[dev]"          # with dev extras
pip install -e .                  # without dev extras

# requirements.txt
pip install -r requirements.txt
# Also check for: requirements-dev.txt, requirements-test.txt, requirements-lint.txt
for f in requirements*.txt; do [ -f "$f" ] && pip install -r "$f"; done

# Pipfile
pip install pipenv && pipenv install --dev

# setup.py (legacy)
pip install -e ".[dev]" 2>/dev/null || pip install -e .
```

### Verify

```bash
pip list              # show installed packages
python -m pytest --collect-only -q 2>&1 | head -20  # confirm tests discoverable
```

### Deactivate (only when user explicitly asks)

```bash
deactivate
```

> **Rule:** The venv MUST remain active for the entire session unless the user asks to deactivate it. Never deactivate between steps.

---

## Go Setup

**Detect:** `go.mod`

```bash
# Verify Go is installed
go version

# Download all module dependencies into local module cache
go mod download

# Tidy if go.sum looks stale or is missing
go mod tidy

# Verify no issues
go build ./...
go vet ./...
```

If the `Makefile` has a `setup` or `install` target, prefer that:

```bash
make setup    # or: make install, make tools
```

### Optional: install project-specific CLI tools

Check `Makefile`, `Taskfile.yml`, or `CONTRIBUTING.md` for tool installation steps (e.g., `golangci-lint`, `mockgen`, `buf`). Install them scoped to the repo where possible:

```bash
# Example: install golangci-lint locally
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b ./bin

# Add to PATH for the session only
export PATH="$PWD/bin:$PATH"
```

---

## Terraform Setup

**Detect:** any `.tf` file or `terraform.tfvars`

```bash
# Verify Terraform is installed
terraform version

# Initialise providers and modules (run in each directory containing *.tf files)
terraform init
```

If the repo has multiple Terraform root modules (subdirectories each containing a `main.tf`), initialise each:

```bash
find . -name "main.tf" -not -path "*/\.*" | xargs -I{} dirname {} | sort -u | while read dir; do
  echo "==> terraform init in $dir"
  terraform init -input=false "$dir" 2>&1 | tail -3
done
```

### Optional: install `tflint` and `terraform-docs`

```bash
# tflint (linter)
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# terraform-docs (documentation generator)
go install github.com/terraform-docs/terraform-docs@latest
```

---

## Node.js Setup

**Detect:** `package.json`

```bash
# Detect the package manager in use
[ -f "pnpm-lock.yaml" ] && PM="pnpm"
[ -f "yarn.lock" ]      && PM="yarn"
[ -f "package-lock.json" ] && PM="npm"
PM="${PM:-npm}"   # default to npm

# Install dependencies
$PM install
```

If Node.js itself needs to match a specific version, check `.nvmrc` or `engines` in `package.json`:

```bash
[ -f ".nvmrc" ] && nvm use || true
```

---

## Rust Setup

**Detect:** `Cargo.toml`

```bash
# Verify Rust toolchain is installed
rustc --version && cargo --version

# Build all crates (downloads and compiles dependencies)
cargo build

# Run tests to confirm environment is healthy
cargo test --no-run
```

If a `rust-toolchain.toml` or `rust-toolchain` file exists, `rustup` will automatically switch to the pinned toolchain.

---

## Task Runner Targets

After stack-specific setup, check whether the project provides a convenience target:

```bash
# Common targets to try (in order)
make dev-setup
make bootstrap
make install
make setup
```

If one succeeds it may replace manual steps above — consult its output.

---

## Session State Summary

After setup, report to the user:

```
## Environment ready

| Stack      | Status | Notes |
|------------|--------|-------|
| Python     | ✅ active | venv at .venv, X packages installed |
| Go         | ✅ ready  | go X.Y, dependencies downloaded |
| Terraform  | ✅ ready  | providers initialised in N directories |
| Node.js    | ✅ ready  | npm/yarn/pnpm, X packages installed |
| Rust       | ✅ ready  | rustc X.Y, workspace compiled |
```

Skip any stack not found in the repo.

---

## Deactivate / Teardown

Only perform teardown when the user explicitly asks (e.g., "deactivate the venv", "clean up the environment", "I'm done contributing").

```bash
# Python — deactivate the virtualenv
deactivate

# Go / Node.js / Rust — no runtime deactivation needed (they use project-local dirs)

# Terraform — remove downloaded providers if asked
rm -rf .terraform

# Remove installed binaries from ./bin if they were added to PATH this session
export PATH="${PATH//$PWD\/bin:/}"
```
