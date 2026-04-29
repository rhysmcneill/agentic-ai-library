# Golang Expert — Rule Index

All rule files with detailed explanations and before/after code examples.

## CRITICAL Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `org-module-structure` | [code-organisation-patterns.md](code-organisation-patterns.md) | One module per repo; standard `cmd/`, `internal/`, `pkg/` layout |
| `org-package-naming` | [code-organisation-patterns.md](code-organisation-patterns.md) | Short, lowercase, singular nouns; no underscores |
| `org-package-cohesion` | [code-organisation-patterns.md](code-organisation-patterns.md) | Organise by domain concept, not technical layer |
| `org-internal` | [code-organisation-patterns.md](code-organisation-patterns.md) | Use `internal/` to enforce package boundaries |
| `org-cmd` | [code-organisation-patterns.md](code-organisation-patterns.md) | Keep `main` packages thin; all logic in importable packages |
| `error-explicit` | [error-handling-patterns.md](error-handling-patterns.md) | Never ignore an error return |
| `error-wrapping` | [error-handling-patterns.md](error-handling-patterns.md) | Add context with `fmt.Errorf("...: %w", err)` |
| `error-sentinel` | [error-handling-patterns.md](error-handling-patterns.md) | Package-level `var ErrFoo = errors.New(...)` for comparison |
| `error-types` | [error-handling-patterns.md](error-handling-patterns.md) | Custom error types for structured error data |
| `error-no-panic` | [error-handling-patterns.md](error-handling-patterns.md) | Reserve `panic` for unrecoverable programmer mistakes |
| `sec-no-hardcoded-secrets` | [security-patterns.md](security-patterns.md) | Never hardcode secrets; read from env or secrets manager |
| `sec-crypto-rand` | [security-patterns.md](security-patterns.md) | Use `crypto/rand` for tokens, nonces, and session IDs |
| `sec-constant-time` | [security-patterns.md](security-patterns.md) | `subtle.ConstantTimeCompare` to prevent timing attacks |
| `sec-tls-config` | [security-patterns.md](security-patterns.md) | Enforce `MinVersion: tls.VersionTLS12`; never skip verification |
| `sec-exec-no-shell` | [security-patterns.md](security-patterns.md) | Explicit args to `exec.Command`; never interpolate into shell |
| `sec-sql-parameterised` | [security-patterns.md](security-patterns.md) | Parameterised queries always; never concatenate SQL |
| `sec-input-validation` | [security-patterns.md](security-patterns.md) | Validate all external input at the process boundary |

## HIGH Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `iface-small` | [interface-patterns.md](interface-patterns.md) | Prefer single-method interfaces |
| `iface-accept-return` | [interface-patterns.md](interface-patterns.md) | Accept interfaces, return concrete types |
| `iface-define-at-use` | [interface-patterns.md](interface-patterns.md) | Define interfaces in the consuming package |
| `iface-composition` | [interface-patterns.md](interface-patterns.md) | Compose interfaces from smaller ones |
| `conc-context` | [concurrency-patterns.md](concurrency-patterns.md) | `context.Context` as first parameter for I/O functions |
| `conc-goroutine-cleanup` | [concurrency-patterns.md](concurrency-patterns.md) | Every goroutine has a defined exit path |
| `conc-channel-ownership` | [concurrency-patterns.md](concurrency-patterns.md) | Only the sender closes a channel |
| `conc-mutex-vs-channel` | [concurrency-patterns.md](concurrency-patterns.md) | Channels for ownership transfer; mutex for shared state |
| `conc-race-detector` | [concurrency-patterns.md](concurrency-patterns.md) | Always run tests with `-race` |
| `cli-cobra-structure` | [cli-patterns.md](cli-patterns.md) | One cobra command per file; root in `cmd/root.go` |
| `cli-flag-validation` | [cli-patterns.md](cli-patterns.md) | Validate flags in `PreRunE` before any side effects |
| `cli-exit-codes` | [cli-patterns.md](cli-patterns.md) | 0 success, 1 user error, 2 internal error; `os.Exit` in `main` only |
| `cli-stderr-stdout` | [cli-patterns.md](cli-patterns.md) | Data to stdout; errors and progress to stderr |
| `cli-embed-config` | [cli-patterns.md](cli-patterns.md) | Bundle defaults and templates with `//go:embed` |
| `cli-heredoc-templates` | [cli-patterns.md](cli-patterns.md) | Raw string literals + `text/template` for multi-line output |
| `cli-shell-completion` | [cli-patterns.md](cli-patterns.md) | Generate shell completion via `cobra completion` |
| `io-stream-not-buffer` | [io-and-strings-patterns.md](io-and-strings-patterns.md) | `io.Copy` for large files; never load entire file into RAM |
| `io-buffered-rw` | [io-and-strings-patterns.md](io-and-strings-patterns.md) | Wrap file I/O with `bufio`; flush writers explicitly |
| `io-atomic-write` | [io-and-strings-patterns.md](io-and-strings-patterns.md) | Write to temp file then `os.Rename` for atomic updates |
| `io-close-defer` | [io-and-strings-patterns.md](io-and-strings-patterns.md) | `defer f.Close()`; check Close error for writers |
| `io-filepath-not-path` | [io-and-strings-patterns.md](io-and-strings-patterns.md) | `path/filepath` for OS paths; `path` for URL segments only |
| `io-heredoc-raw-strings` | [io-and-strings-patterns.md](io-and-strings-patterns.md) | Backtick raw strings for SQL, JSON, scripts, templates |
| `io-embed-assets` | [io-and-strings-patterns.md](io-and-strings-patterns.md) | `//go:embed` to bundle static files into the binary |

## MEDIUM-HIGH Rules

| Rule ID | Local File | Summary |
|---------|-----------|---------|
| `test-table-driven` | [testing-patterns.md](testing-patterns.md) | Table-driven tests for all non-trivial logic |
| `test-subtests` | [testing-patterns.md](testing-patterns.md) | `t.Run` for isolated, named test cases |
| `test-interface-mocking` | [testing-patterns.md](testing-patterns.md) | Mock via interfaces, not concrete types |
| `test-golden-files` | [testing-patterns.md](testing-patterns.md) | Golden files for complex expected outputs |
| `test-benchmarks` | [testing-patterns.md](testing-patterns.md) | Benchmark performance-critical paths |

## MEDIUM Rules

| Rule ID | Summary |
|---------|---------|
| `perf-avoid-allocations` | Profile first; reduce heap allocations in hot paths |
| `perf-strings-builder` | `strings.Builder` for string concatenation in loops |
| `perf-slice-capacity` | `make([]T, 0, n)` when final size is known |
| `perf-struct-layout` | Order struct fields largest-to-smallest to minimise padding |
| `tool-gofmt` | Always run `gofmt -s`; enforce in CI |
| `tool-go-vet` | `go vet ./...` on every CI build |
| `tool-golangci-lint` | `golangci-lint run` with committed `.golangci.yml` |
| `tool-go-generate` | Commit generated files; use `//go:generate` directives |
