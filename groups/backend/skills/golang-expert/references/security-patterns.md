# Security Patterns

Covers rules: `sec-no-hardcoded-secrets`, `sec-crypto-rand`, `sec-constant-time`, `sec-tls-config`, `sec-exec-no-shell`, `sec-sql-parameterised`, `sec-input-validation`

---

## `sec-no-hardcoded-secrets` — Never hardcode secrets

Secrets in source code leak into version control, logs, and compiled binaries.

**Anti-pattern:**
```go
const apiKey = "sk-prod-abc123secret"   // committed to git forever

db, err := sql.Open("postgres", "postgres://admin:hunter2@prod-db/app")
```

**Best practice:**
```go
// Read from environment at startup:
apiKey := os.Getenv("API_KEY")
if apiKey == "" {
    return fmt.Errorf("API_KEY environment variable is required")
}

// Or use a secrets manager (AWS Secrets Manager, Vault, etc.):
secret, err := secretsClient.GetSecret(ctx, "prod/db/password")
if err != nil {
    return fmt.Errorf("fetch db secret: %w", err)
}
```

Never log secrets, include them in error messages, or expose them in HTTP responses.

---

## `sec-crypto-rand` — Use `crypto/rand` for security-sensitive values

`math/rand` is a pseudorandom number generator seeded deterministically — its output is predictable. Use `crypto/rand` for tokens, nonces, salts, and session IDs.

**Anti-pattern:**
```go
import "math/rand"

token := fmt.Sprintf("%d", rand.Int63()) // predictable, not cryptographically secure
```

**Best practice:**
```go
import (
    "crypto/rand"
    "encoding/base64"
)

func generateToken(n int) (string, error) {
    b := make([]byte, n)
    if _, err := rand.Read(b); err != nil {
        return "", fmt.Errorf("generate token: %w", err)
    }
    return base64.URLEncoding.EncodeToString(b), nil
}

token, err := generateToken(32) // 32 bytes → 256 bits of entropy
```

---

## `sec-constant-time` — Constant-time comparison for secrets

Normal string comparison (`==`) short-circuits on the first differing byte, leaking timing information that attackers can exploit to guess tokens byte by byte.

**Anti-pattern:**
```go
if providedToken == storedToken { // timing attack vulnerability
    grantAccess()
}
```

**Best practice:**
```go
import "crypto/subtle"

if subtle.ConstantTimeCompare([]byte(providedToken), []byte(storedToken)) == 1 {
    grantAccess()
}

// For HMAC-based tokens, use hmac.Equal:
import "crypto/hmac"
if hmac.Equal(expected, received) {
    grantAccess()
}
```

---

## `sec-tls-config` — Enforce minimum TLS version

Never disable certificate verification or allow weak TLS versions in production.

**Anti-pattern:**
```go
tr := &http.Transport{
    TLSClientConfig: &tls.Config{
        InsecureSkipVerify: true, // disables all certificate validation
    },
}
```

**Best practice:**
```go
tlsCfg := &tls.Config{
    MinVersion: tls.VersionTLS12,
    CurvePreferences: []tls.CurveID{
        tls.X25519,
        tls.CurveP256,
    },
}

// Client:
tr := &http.Transport{TLSClientConfig: tlsCfg}
client := &http.Client{Transport: tr}

// Server:
srv := &http.Server{
    Addr:      ":443",
    TLSConfig: tlsCfg,
}
```

For testing against self-signed certs, load the CA cert explicitly rather than skipping verification.

---

## `sec-exec-no-shell` — Never interpolate user input into shell commands

Passing user input to a shell (`sh -c "..."`) enables command injection.

**Anti-pattern:**
```go
// User controls `filename` — they can pass "file.txt; rm -rf /"
cmd := exec.Command("sh", "-c", "process "+filename)
```

**Best practice:**
```go
// Pass each argument separately — the OS never invokes a shell
cmd := exec.CommandContext(ctx, "process", filename)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
if err := cmd.Run(); err != nil {
    return fmt.Errorf("process %s: %w", filename, err)
}
```

If you genuinely need shell features (pipes, globs), use a dedicated library or handle them explicitly in Go rather than delegating to `sh`.

---

## `sec-sql-parameterised` — Always use parameterised queries

String-concatenated SQL enables SQL injection — one of the most critical vulnerability classes.

**Anti-pattern:**
```go
query := "SELECT * FROM users WHERE email = '" + email + "'"
rows, err := db.QueryContext(ctx, query)
// email = "' OR '1'='1" dumps the entire table
```

**Best practice:**
```go
// Positional placeholder (PostgreSQL: $1, MySQL/SQLite: ?)
rows, err := db.QueryContext(ctx,
    "SELECT id, name FROM users WHERE email = $1 AND active = $2",
    email, true,
)
if err != nil {
    return nil, fmt.Errorf("query users: %w", err)
}
defer rows.Close()

// Named parameters with sqlx:
users, err := db.NamedQueryContext(ctx,
    "SELECT * FROM users WHERE org_id = :org_id",
    map[string]any{"org_id": orgID},
)
```

---

## `sec-input-validation` — Validate all external input at the boundary

Trust nothing from outside the process: HTTP request bodies, CLI flags, environment variables, file content, and gRPC messages must all be validated before use.

**Best practice:**
```go
type CreateUserRequest struct {
    Email string `json:"email"`
    Age   int    `json:"age"`
}

func (r *CreateUserRequest) Validate() error {
    if r.Email == "" {
        return &ValidationError{Field: "email", Message: "is required"}
    }
    if !strings.Contains(r.Email, "@") {
        return &ValidationError{Field: "email", Message: "is invalid"}
    }
    if r.Age < 0 || r.Age > 150 {
        return &ValidationError{Field: "age", Message: "must be between 0 and 150"}
    }
    return nil
}

func handleCreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "invalid JSON", http.StatusBadRequest)
        return
    }
    if err := req.Validate(); err != nil {
        http.Error(w, err.Error(), http.StatusUnprocessableEntity)
        return
    }
    // safe to use req from here
}
```

Consider using a validation library (`go-playground/validator`) for complex structs with struct tags.
