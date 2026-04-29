# Error Handling Patterns

Covers rules: `error-explicit`, `error-wrapping`, `error-sentinel`, `error-types`, `error-no-panic`

---

## `error-explicit` — Never ignore errors

Every error return must be checked. Assign to `_` only when you have a documented reason.

**Anti-pattern:**
```go
os.Remove(tmpFile)           // error silently swallowed
json.Unmarshal(data, &cfg)   // partial decode goes unnoticed
```

**Best practice:**
```go
if err := os.Remove(tmpFile); err != nil {
    log.Printf("cleanup: remove %s: %v", tmpFile, err)
}

if err := json.Unmarshal(data, &cfg); err != nil {
    return fmt.Errorf("unmarshal config: %w", err)
}
```

---

## `error-wrapping` — Add context with `%w`

Wrap errors at each layer to build a meaningful call chain. Use `%w` (not `%v`) so callers can use `errors.Is` and `errors.As`.

**Anti-pattern:**
```go
func readConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, err  // caller has no idea which operation failed
    }
    // ...
}
```

**Best practice:**
```go
func readConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("read config %s: %w", path, err)
    }

    var cfg Config
    if err := json.Unmarshal(data, &cfg); err != nil {
        return nil, fmt.Errorf("parse config %s: %w", path, err)
    }
    return &cfg, nil
}

// Caller can still inspect the underlying error:
cfg, err := readConfig("app.json")
if errors.Is(err, os.ErrNotExist) {
    // handle missing file
}
```

---

## `error-sentinel` — Sentinel errors for comparison

Define package-level sentinel errors when callers need to branch on a specific condition.

**Anti-pattern:**
```go
func findUser(id string) (*User, error) {
    if id == "" {
        return nil, errors.New("user not found") // string comparison is fragile
    }
}

// Caller:
if err.Error() == "user not found" { ... } // breaks if message changes
```

**Best practice:**
```go
// In the package that owns the domain:
var ErrUserNotFound = errors.New("user not found")

func findUser(id string) (*User, error) {
    // ...
    return nil, fmt.Errorf("findUser %s: %w", id, ErrUserNotFound)
}

// Caller:
if errors.Is(err, ErrUserNotFound) {
    http.Error(w, "not found", http.StatusNotFound)
}
```

---

## `error-types` — Custom error types for structured data

Use a custom type when callers need to extract structured information from the error.

**Anti-pattern:**
```go
return fmt.Errorf("validation failed: field %s is required", field)
// Caller cannot reliably extract the field name
```

**Best practice:**
```go
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation: field %q %s", e.Field, e.Message)
}

// Return:
return &ValidationError{Field: "email", Message: "is required"}

// Caller:
var ve *ValidationError
if errors.As(err, &ve) {
    fmt.Printf("bad field: %s\n", ve.Field)
}
```

---

## `error-no-panic` — Do not panic for recoverable errors

`panic` is for programmer mistakes (nil pointer, index out of range). Never use it to signal expected error conditions to callers.

**Anti-pattern:**
```go
func parseID(s string) int {
    n, err := strconv.Atoi(s)
    if err != nil {
        panic("invalid id: " + s) // crashes the whole program
    }
    return n
}
```

**Best practice:**
```go
func parseID(s string) (int, error) {
    n, err := strconv.Atoi(s)
    if err != nil {
        return 0, fmt.Errorf("parse id %q: %w", s, err)
    }
    return n, nil
}
```

Use `panic` only in `init()` or package-level setup where failure truly is unrecoverable, and always document why.
