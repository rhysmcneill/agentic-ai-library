# File I/O & Strings Patterns

Covers rules: `io-stream-not-buffer`, `io-buffered-rw`, `io-atomic-write`, `io-close-defer`, `io-filepath-not-path`, `io-heredoc-raw-strings`, `io-embed-assets`

---

## `io-stream-not-buffer` — Stream with `io.Copy`, don't buffer entire files

Reading a whole file into memory with `os.ReadFile` allocates the full file size. For large files, use `io.Copy` to stream between readers and writers.

**Anti-pattern:**
```go
// Loads the entire 2GB file into RAM:
data, err := os.ReadFile("large-export.csv")
if err != nil {
    return err
}
_, err = remoteStorage.Write(data)
```

**Best practice:**
```go
// Stream directly — constant memory usage regardless of file size:
src, err := os.Open("large-export.csv")
if err != nil {
    return fmt.Errorf("open source: %w", err)
}
defer src.Close()

dst, err := remoteStorage.NewWriter(ctx, "export.csv")
if err != nil {
    return fmt.Errorf("open destination: %w", err)
}
defer dst.Close()

if _, err := io.Copy(dst, src); err != nil {
    return fmt.Errorf("transfer: %w", err)
}
```

For file transfers with progress reporting, wrap with `io.TeeReader` or a custom `io.Reader`.

---

## `io-buffered-rw` — Wrap file I/O in `bufio`

Unbuffered reads and writes issue a syscall per call — expensive for line-by-line or small-chunk I/O.

**Anti-pattern:**
```go
f, _ := os.Open("data.txt")
buf := make([]byte, 1)
for {
    _, err := f.Read(buf) // one syscall per byte
    if err == io.EOF { break }
}
```

**Best practice:**
```go
// Reading line by line:
f, err := os.Open("data.txt")
if err != nil {
    return fmt.Errorf("open: %w", err)
}
defer f.Close()

scanner := bufio.NewScanner(f)
for scanner.Scan() {
    line := scanner.Text()
    process(line)
}
if err := scanner.Err(); err != nil {
    return fmt.Errorf("scan: %w", err)
}

// Writing with buffered writer:
f, err := os.Create("output.txt")
if err != nil {
    return fmt.Errorf("create: %w", err)
}
defer f.Close()

w := bufio.NewWriter(f)
defer w.Flush() // always flush before close

fmt.Fprintln(w, "line 1")
fmt.Fprintln(w, "line 2")
```

---

## `io-atomic-write` — Write atomically with temp file + rename

Writing directly to the target file leaves a window where the file is partially written. A crash or error leaves the destination corrupt. Write to a temp file in the same directory, then `os.Rename`.

**Anti-pattern:**
```go
// If this crashes halfway, config.json is corrupted:
f, _ := os.Create("config.json")
json.NewEncoder(f).Encode(cfg)
f.Close()
```

**Best practice:**
```go
func writeAtomic(path string, data []byte) error {
    dir := filepath.Dir(path)

    // Temp file in the same directory (same filesystem → rename is atomic)
    tmp, err := os.CreateTemp(dir, ".tmp-*")
    if err != nil {
        return fmt.Errorf("create temp: %w", err)
    }
    tmpName := tmp.Name()

    // Clean up temp file if we fail before rename:
    defer func() {
        tmp.Close()
        os.Remove(tmpName) // no-op if rename succeeded
    }()

    if _, err := tmp.Write(data); err != nil {
        return fmt.Errorf("write temp: %w", err)
    }
    if err := tmp.Sync(); err != nil { // flush to disk
        return fmt.Errorf("sync temp: %w", err)
    }
    if err := tmp.Close(); err != nil {
        return fmt.Errorf("close temp: %w", err)
    }

    // Atomic on POSIX; best-effort on Windows
    return os.Rename(tmpName, path)
}
```

---

## `io-close-defer` — Always defer `Close`; check error for writers

For readers, `defer f.Close()` immediately after a successful open is sufficient. For writers, also check the error returned by `Close` — it flushes OS buffers and can surface write errors.

```go
// Reader — defer is sufficient:
f, err := os.Open(path)
if err != nil {
    return err
}
defer f.Close()

// Writer — check Close error:
f, err := os.Create(path)
if err != nil {
    return err
}
defer func() {
    if cerr := f.Close(); cerr != nil && err == nil {
        err = fmt.Errorf("close %s: %w", path, cerr)
    }
}()
```

---

## `io-filepath-not-path` — Use `path/filepath` for OS paths

`path` uses forward slashes and is for URL segments. `filepath` is OS-aware (handles `\` on Windows, symlinks, relative paths).

```go
// Wrong — breaks on Windows:
import "path"
full := path.Join(baseDir, "subdir", "file.txt")

// Correct:
import "path/filepath"
full := filepath.Join(baseDir, "subdir", "file.txt")
abs, err := filepath.Abs(full)
clean := filepath.Clean(userInput) // normalise and remove ../ traversal
```

---

## `io-heredoc-raw-strings` — Raw string literals for multi-line content

Go backtick strings are raw string literals: no escape sequences, no interpretation. Use them for SQL, JSON templates, shell scripts, help text, and any multi-line content.

```go
// SQL — readable, no escaping:
const createTable = `
    CREATE TABLE IF NOT EXISTS users (
        id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email       TEXT NOT NULL UNIQUE,
        created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
`

// JSON template:
const defaultConfig = `{
    "log_level": "info",
    "timeout":   "30s",
    "retries":   3
}`

// Shell script embedded in Go:
const setupScript = `#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/.config/myapp"
echo "Setup complete."
`

// With text/template (raw string + template actions):
var emailTmpl = template.Must(template.New("email").Parse(`
Hello {{ .Name }},

Your account has been created. Your username is {{ .Username }}.

Regards,
The Team
`))
```

---

## `io-embed-assets` — Embed static files with `//go:embed`

Bundle files into the binary at compile time. No runtime file-system dependency, no deployment of separate asset directories.

```go
package assets

import (
    "embed"
    "io/fs"
)

// Single file:
//go:embed schema.sql
var SchemaSQLBytes []byte

// Single file as string:
//go:embed version.txt
var Version string

// Directory tree (access via fs.FS):
//go:embed templates
var TemplateFS embed.FS

// Exported sub-FS (strips the "templates" prefix):
func Templates() fs.FS {
    sub, _ := fs.Sub(TemplateFS, "templates")
    return sub
}
```

```go
// Usage in a handler:
tmpl, err := template.ParseFS(assets.Templates(), "*.html")
if err != nil {
    log.Fatal(err)
}
```

Patterns supported: `//go:embed file.txt`, `//go:embed dir/`, `//go:embed *.json`. Multiple directives on the same `var` are OR-ed together.
