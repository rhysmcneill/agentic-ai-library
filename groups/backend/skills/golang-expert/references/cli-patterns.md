# CLI Tool Creation Patterns

Covers rules: `cli-cobra-structure`, `cli-flag-validation`, `cli-exit-codes`, `cli-stderr-stdout`, `cli-embed-config`, `cli-heredoc-templates`, `cli-shell-completion`

---

## `cli-cobra-structure` — Cobra command layout

Use `cobra` for any CLI with more than one command. Keep one command per file; wire everything in `cmd/root.go`.

**Recommended layout:**
```
mycli/
├── cmd/
│   ├── root.go       ← rootCmd, persistent flags, Execute()
│   ├── serve.go      ← serveCmd
│   ├── migrate.go    ← migrateCmd
│   └── version.go    ← versionCmd
├── internal/
│   └── ...           ← all business logic (no cobra dependency)
└── main.go           ← calls cmd.Execute()
```

**`cmd/root.go`:**
```go
package cmd

import (
    "github.com/spf13/cobra"
    "os"
)

var rootCmd = &cobra.Command{
    Use:   "mycli",
    Short: "A brief description of your application",
}

func Execute() {
    if err := rootCmd.Execute(); err != nil {
        os.Exit(1)
    }
}

func init() {
    rootCmd.PersistentFlags().StringP("config", "c", "", "config file path")
}
```

**`cmd/serve.go`:**
```go
package cmd

import "github.com/spf13/cobra"

var serveCmd = &cobra.Command{
    Use:   "serve",
    Short: "Start the HTTP server",
    RunE:  runServe,  // use RunE, not Run, to propagate errors
}

func init() {
    rootCmd.AddCommand(serveCmd)
    serveCmd.Flags().IntP("port", "p", 8080, "port to listen on")
}

func runServe(cmd *cobra.Command, args []string) error {
    port, _ := cmd.Flags().GetInt("port")
    return server.Start(cmd.Context(), port)
}
```

---

## `cli-flag-validation` — Validate flags in `RunE`, not in business logic

Catch bad inputs before any side effects occur. Use `PersistentPreRunE` for validation shared across subcommands.

**Anti-pattern:**
```go
func runCmd(cmd *cobra.Command, args []string) error {
    output, _ := cmd.Flags().GetString("output")
    // output might be "" — discovered deep inside business logic
    return doWork(output)
}
```

**Best practice:**
```go
var serveCmd = &cobra.Command{
    Use:     "export",
    RunE:    runExport,
    PreRunE: validateExportFlags,
}

func validateExportFlags(cmd *cobra.Command, args []string) error {
    output, _ := cmd.Flags().GetString("output")
    if output == "" {
        return fmt.Errorf("--output is required")
    }
    format, _ := cmd.Flags().GetString("format")
    if format != "json" && format != "csv" {
        return fmt.Errorf("--format must be json or csv, got %q", format)
    }
    return nil
}
```

---

## `cli-exit-codes` — Consistent exit codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | User/input error (bad flags, missing files) |
| `2` | Internal/unexpected error |

```go
// main.go — only place os.Exit is called
func main() {
    cmd.Execute() // cobra calls os.Exit(1) internally on RunE error
}

// For explicit control:
func main() {
    if err := run(); err != nil {
        var userErr *cli.UserError
        if errors.As(err, &userErr) {
            fmt.Fprintf(os.Stderr, "error: %v\n", err)
            os.Exit(1)
        }
        fmt.Fprintf(os.Stderr, "internal error: %v\n", err)
        os.Exit(2)
    }
}
```

Never call `os.Exit` inside a library function — it bypasses `defer` and makes the code untestable.

---

## `cli-stderr-stdout` — stdout for data, stderr for messages

Programs in pipelines: stdout is the data stream; stderr is human-readable messages.

```go
// Output that users or other programs consume:
fmt.Fprintln(os.Stdout, result)
json.NewEncoder(os.Stdout).Encode(records)

// Progress, warnings, errors:
fmt.Fprintf(os.Stderr, "Processing %d records...\n", len(records))
fmt.Fprintf(os.Stderr, "warning: skipped %d invalid rows\n", skipped)

// With cobra, use cmd.OutOrStdout() / cmd.ErrOrStderr() for testability:
fmt.Fprintln(cmd.OutOrStdout(), result)
fmt.Fprintf(cmd.ErrOrStderr(), "error: %v\n", err)
```

---

## `cli-heredoc-templates` — Raw string literals for multi-line output

Use backtick raw string literals with `text/template` for multi-line output, help text, and embedded scripts. Avoid hand-built string concatenation.

**Anti-pattern:**
```go
msg := "Usage:\n" +
    "  mycli export --output FILE\n" +
    "  mycli export --format json\n" +
    "\nFlags:\n" +
    "  --output  output file path\n"
```

**Best practice:**
```go
// Raw string literal — no escape sequences, exactly what you see:
const usageTemplate = `
Usage:
  mycli export --output FILE [--format FORMAT]

Examples:
  mycli export --output ./data.json --format json
  mycli export --output ./data.csv  --format csv

Flags:
  --output   output file path (required)
  --format   output format: json or csv (default: json)
`

// With text/template for dynamic content:
var reportTmpl = template.Must(template.New("report").Parse(`
Summary for {{ .Name }}
=======================
Total:   {{ .Total }}
Passed:  {{ .Passed }}
Failed:  {{ .Failed }}
`))

if err := reportTmpl.Execute(os.Stdout, data); err != nil {
    return fmt.Errorf("render report: %w", err)
}
```

---

## `cli-embed-config` — Bundle assets with `//go:embed`

Use `//go:embed` to include default configs, templates, and schemas in the binary. No runtime file-system dependency.

```go
package config

import _ "embed"

//go:embed defaults.yaml
var DefaultConfig []byte

//go:embed schema.json
var SchemaJSON string
```

```go
// Embedding multiple files into an fs.FS:
import "embed"

//go:embed templates/*
var templateFS embed.FS

tmpl, err := template.ParseFS(templateFS, "templates/*.tmpl")
```

---

## `cli-shell-completion` — Provide shell completion

Add a `completion` subcommand so users can install tab-completion. Cobra generates this automatically.

```go
// cmd/completion.go
var completionCmd = &cobra.Command{
    Use:   "completion [bash|zsh|fish|powershell]",
    Short: "Generate shell completion scripts",
    ValidArgs: []string{"bash", "zsh", "fish", "powershell"},
    Args:  cobra.ExactValidArgs(1),
    RunE: func(cmd *cobra.Command, args []string) error {
        switch args[0] {
        case "bash":
            return cmd.Root().GenBashCompletion(os.Stdout)
        case "zsh":
            return cmd.Root().GenZshCompletion(os.Stdout)
        case "fish":
            return cmd.Root().GenFishCompletion(os.Stdout, true)
        case "powershell":
            return cmd.Root().GenPowerShellCompletionWithDesc(os.Stdout)
        }
        return nil
    },
}
```

Register dynamic completions for flags with `RegisterFlagCompletionFunc` when flag values come from a known set (e.g. environment names, region codes).
