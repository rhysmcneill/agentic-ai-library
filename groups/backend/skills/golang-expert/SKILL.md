---
name: golang-expert
description: Idiomatic Go best practices for writing clean, performant, and maintainable Go code. Apply when writing, reviewing, or refactoring any Go code — including modules, packages, error handling, concurrency, CLI tools, file I/O, security, and tooling.
---

# Golang Expert

Comprehensive guide to idiomatic Go, covering language best practices, design patterns, concurrency, CLI tool creation, file I/O, security, testing, and tooling. Apply these rules whenever writing or reviewing Go code to ensure correctness, clarity, and long-term maintainability.

## When to Apply

Reference these guidelines when:
- Writing new Go packages, modules, or services
- Reviewing Go code for correctness and idiomatic style
- Refactoring existing Go code
- Designing interfaces and package APIs
- Writing concurrent code with goroutines or channels
- Building CLI tools or command-line interfaces
- Handling file I/O, streaming, or file transfer
- Implementing secure Go code
- Writing tests or benchmarks
- Setting up Go tooling in CI/CD pipelines

## Rule Categories by Priority

| Priority | Category | Impact | Prefix |
|----------|----------|--------|--------|
| 1 | Code Organisation | CRITICAL | `org-` |
| 2 | Error Handling | CRITICAL | `error-` |
| 3 | Security | CRITICAL | `sec-` |
| 4 | Interfaces & Composition | HIGH | `iface-` |
| 5 | Concurrency | HIGH | `conc-` |
| 6 | CLI Tool Creation | HIGH | `cli-` |
| 7 | File I/O & Strings | HIGH | `io-` |
| 8 | Testing | MEDIUM-HIGH | `test-` |
| 9 | Performance | MEDIUM | `perf-` |
| 10 | Tooling & Linting | MEDIUM | `tool-` |

## Quick Reference

### 1. Code Organisation (CRITICAL)

- `org-module-structure` — one module per repository; `go.mod` at the root
- `org-package-naming` — short, lowercase, singular nouns; no underscores or mixedCase (`user`, not `userService`)
- `org-package-cohesion` — organise packages by domain concept, not by layer (`user/`, not `models/`, `controllers/`, `services/`)
- `org-internal` — use `internal/` to prevent external packages from importing unexported APIs
- `org-cmd` — keep `main` packages thin in `cmd/<name>/main.go`; all logic lives in importable packages

### 2. Error Handling (CRITICAL)

- `error-explicit` — never ignore an error; assign to `_` only when intentional and documented
- `error-wrapping` — add context with `fmt.Errorf("doing X: %w", err)`; preserve the original error for `errors.Is`/`errors.As`
- `error-sentinel` — define sentinel errors with `var ErrFoo = errors.New("foo")` for values callers compare against
- `error-types` — use custom error types (implementing `error`) when callers need to inspect structured error data
- `error-no-panic` — do not use `panic` for recoverable errors; reserve it for truly unrecoverable programmer mistakes

### 3. Security (CRITICAL)

- `sec-no-hardcoded-secrets` — never hardcode secrets, tokens, or passwords; read from environment variables or a secrets manager
- `sec-crypto-rand` — use `crypto/rand` for all security-sensitive random values; never use `math/rand` for tokens or nonces
- `sec-constant-time` — compare secrets and tokens with `subtle.ConstantTimeCompare` to prevent timing attacks
- `sec-tls-config` — always use `tls.Config` with `MinVersion: tls.VersionTLS12`; never set `InsecureSkipVerify: true` in production
- `sec-exec-no-shell` — use `exec.Command("bin", arg1, arg2)` with explicit args; never interpolate user input into a shell string
- `sec-sql-parameterised` — always use parameterised queries (`db.QueryContext(ctx, "SELECT ... WHERE id=?", id)`); never concatenate SQL strings
- `sec-input-validation` — validate and sanitise all external input at the boundary; fail fast with a clear error

### 4. Interfaces & Composition (HIGH)

- `iface-small` — prefer single-method interfaces (`io.Reader`, `io.Writer`); the smaller the interface, the more implementations it accepts
- `iface-accept-return` — accept interfaces, return concrete types; this maximises flexibility for callers
- `iface-define-at-use` — define interfaces in the package that uses them, not the package that implements them
- `iface-composition` — compose larger interfaces from smaller ones rather than defining monolithic interfaces

### 5. Concurrency (HIGH)

- `conc-context` — accept `context.Context` as the first parameter of any function that does I/O or can be cancelled; never store context in a struct
- `conc-goroutine-cleanup` — every goroutine must have a clear owner and a defined exit path; use `sync.WaitGroup` or `errgroup` to wait for completion
- `conc-channel-ownership` — the goroutine that creates a channel is responsible for closing it; never close a channel from the receiver side
- `conc-mutex-vs-channel` — use channels for transferring ownership or signalling; use `sync.Mutex` for protecting shared state
- `conc-race-detector` — always run tests with `-race`; enable it in CI (`go test -race ./...`)

### 6. CLI Tool Creation (HIGH)

- `cli-cobra-structure` — use `cobra` for multi-command CLIs; one `*cobra.Command` per file under `cmd/`; root command in `cmd/root.go`
- `cli-flag-validation` — validate all flags in `PersistentPreRunE` or `RunE`; return an error rather than calling `os.Exit` directly
- `cli-exit-codes` — exit 0 on success, 1 on user error, 2 on internal/unexpected error; use `os.Exit` only in `main`
- `cli-stderr-stdout` — write human-readable output to `stdout`; write errors, warnings, and progress to `stderr`
- `cli-embed-config` — use `//go:embed` to bundle default config templates, completion scripts, or static assets into the binary
- `cli-heredoc-templates` — use raw string literals (backticks) with `text/template` for multi-line output templates; avoid hand-built string concatenation
- `cli-shell-completion` — generate shell completion scripts via `cobra completion`; add a `completion` subcommand

### 7. File I/O & Strings (HIGH)

- `io-stream-not-buffer` — use `io.Copy` to stream file content; never read an entire file into memory with `os.ReadFile` unless it is provably small
- `io-buffered-rw` — wrap file reads/writes in `bufio.NewReader`/`bufio.NewWriter`; flush writers explicitly with `defer w.Flush()`
- `io-atomic-write` — write to a temp file in the same directory, then rename; this prevents partial writes corrupting the destination
- `io-close-defer` — always `defer f.Close()` immediately after a successful `os.Open`; check the error on `Close` for writers
- `io-filepath-not-path` — use `path/filepath` (not `path`) for OS file paths; use `path` only for URL path segments
- `io-heredoc-raw-strings` — use raw string literals (`` ` ``) for multi-line strings, SQL, JSON templates, and scripts; avoid escape-heavy interpreted strings
- `io-embed-assets` — use `//go:embed` to include static files, templates, and schemas in the binary at compile time

### 8. Testing (MEDIUM-HIGH)

- `test-table-driven` — use table-driven tests (`[]struct{ name, input, want }`) for all non-trivial logic
- `test-subtests` — use `t.Run(tc.name, func(t *testing.T) {...})` inside table-driven loops for isolated, named failures
- `test-interface-mocking` — mock dependencies via interfaces, not concrete types or monkey-patching
- `test-golden-files` — use golden files (`testdata/*.golden`) for complex expected outputs; update with `-update` flag
- `test-benchmarks` — write `BenchmarkXxx` functions for performance-critical paths; run with `go test -bench=.`

### 9. Performance (MEDIUM)

- `perf-avoid-allocations` — profile with `pprof` before optimising; minimise heap allocations in hot paths using `sync.Pool` or pre-allocated slices
- `perf-strings-builder` — use `strings.Builder` (or `bytes.Buffer`) for string concatenation in loops; never use `+=` in a loop
- `perf-slice-capacity` — pre-allocate slices with `make([]T, 0, n)` when the final size is known
- `perf-struct-layout` — order struct fields from largest to smallest alignment to minimise padding

### 10. Tooling & Linting (MEDIUM)

- `tool-gofmt` — always run `gofmt -s` (or `goimports`); enforce in CI with `gofmt -l .` exiting non-zero on diff
- `tool-go-vet` — run `go vet ./...` as part of every CI build; it catches correctness issues `gofmt` misses
- `tool-golangci-lint` — use `golangci-lint run` in CI with a committed `.golangci.yml`; enable at minimum `errcheck`, `staticcheck`, `gosimple`, `unused`
- `tool-go-generate` — use `//go:generate` directives for code generation; commit generated files so the build does not require external tools at runtime

## How to Use

Apply rules by ID when reviewing or writing Go code. Read individual rule files in `references/` for detailed explanations and before/after code examples:

```
references/error-handling-patterns.md
references/security-patterns.md
references/concurrency-patterns.md
references/cli-patterns.md
references/io-and-strings-patterns.md
references/interface-patterns.md
references/testing-patterns.md
references/code-organisation-patterns.md
```

See `references/rule-index.md` for the full list of all rules mapped to their local files.
