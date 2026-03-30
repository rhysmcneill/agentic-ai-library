---
name: golang-api
description: Enforces Go API best practices for project structure, handlers, error handling, middleware, and testing. Use when asked to "create a Go API", "write a Go handler", "review Go API code", "scaffold a Go service", or "follow Go best practices".
---

# Go API Best Practices

Apply idiomatic Go patterns when building, reviewing, or modifying HTTP API services.

## Step 1: Determine Project Layout

Use the standard Go project layout for API services:

```
service-name/
├── cmd/
│   └── server/
│       └── main.go            # Entrypoint: config, DI wiring, server start
├── internal/
│   ├── handler/               # HTTP handlers (one file per resource)
│   ├── middleware/             # HTTP middleware (auth, logging, recovery)
│   ├── service/               # Business logic (no HTTP concerns)
│   ├── repository/            # Data access layer (DB, cache, external APIs)
│   ├── model/                 # Domain types and validation
│   └── config/                # Configuration loading
├── pkg/                       # Shared libraries safe for external import
├── api/                       # OpenAPI specs, proto files
├── migrations/                # Database migrations
├── go.mod
└── go.sum
```

**Key rules:**
- Keep `main.go` thin — only wiring and startup
- Use `internal/` to prevent external imports of implementation details
- Separate HTTP transport (`handler/`) from business logic (`service/`)
- Never import `handler` from `service` or `repository`

## Step 2: Apply Handler Patterns

Structure every HTTP handler as a method on a struct that holds its dependencies:

```go
type UserHandler struct {
    svc    service.UserService
    logger *slog.Logger
}

func NewUserHandler(svc service.UserService, logger *slog.Logger) *UserHandler {
    return &UserHandler{svc: svc, logger: logger}
}

func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")

    user, err := h.svc.GetByID(r.Context(), id)
    if err != nil {
        encodeError(w, r, err)
        return
    }

    encode(w, r, http.StatusOK, user)
}
```

**Key rules:**
- Accept interfaces, return structs for dependencies
- Always pass `context.Context` from the request to downstream calls
- Use `r.PathValue()` (Go 1.22+) or the router's equivalent — never parse the URL manually
- Return early on errors; avoid deep nesting

Read `references/handler-patterns.md` for response encoding, pagination, and input validation patterns.

## Step 3: Handle Errors Consistently

Define domain errors as sentinel values or typed errors in `internal/model/`:

```go
var (
    ErrNotFound      = errors.New("not found")
    ErrConflict      = errors.New("conflict")
    ErrUnauthorized  = errors.New("unauthorized")
    ErrInvalidInput  = errors.New("invalid input")
)
```

Map domain errors to HTTP status codes in a single `encodeError` function in the handler layer:

```go
func encodeError(w http.ResponseWriter, r *http.Request, err error) {
    status := http.StatusInternalServerError
    switch {
    case errors.Is(err, model.ErrNotFound):
        status = http.StatusNotFound
    case errors.Is(err, model.ErrConflict):
        status = http.StatusConflict
    case errors.Is(err, model.ErrUnauthorized):
        status = http.StatusUnauthorized
    case errors.Is(err, model.ErrInvalidInput):
        status = http.StatusBadRequest
    }
    encode(w, r, status, map[string]string{"error": err.Error()})
}
```

**Key rules:**
- Never expose internal error details (stack traces, SQL) to the client
- Use `errors.Is` and `errors.As` — never compare error strings
- Wrap errors with `fmt.Errorf("operation: %w", err)` to preserve the chain
- Log the full error server-side; return a sanitized message to the client

## Step 4: Apply Middleware Patterns

Write middleware using the `func(http.Handler) http.Handler` signature:

```go
func RequestID(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        id := r.Header.Get("X-Request-ID")
        if id == "" {
            id = uuid.NewString()
        }
        ctx := context.WithValue(r.Context(), requestIDKey, id)
        w.Header().Set("X-Request-ID", id)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

Apply middleware in a consistent order in `main.go` or a router setup function:

1. Recovery (panic → 500)
2. Request ID
3. Structured logging
4. CORS
5. Authentication
6. Rate limiting
7. Route-specific middleware

Read `references/middleware-patterns.md` for structured logging, auth, and recovery middleware examples.

## Step 5: Structure the Service Layer

The service layer holds all business logic and must have no knowledge of HTTP:

```go
type UserService interface {
    GetByID(ctx context.Context, id string) (*model.User, error)
    Create(ctx context.Context, input model.CreateUserInput) (*model.User, error)
}
```

**Key rules:**
- Define service interfaces in the package that uses them (handler), not the one that implements them
- Accept and return domain types, never `*http.Request` or `http.ResponseWriter`
- Validate business invariants here, not in handlers
- Use `context.Context` as the first parameter on every method

## Step 6: Write Tests

Follow this testing strategy:

| Layer | Test Type | What to Verify |
|-------|-----------|----------------|
| `handler/` | HTTP tests with `httptest` | Status codes, response bodies, error mapping |
| `service/` | Unit tests with mocked repos | Business logic, validation, edge cases |
| `repository/` | Integration tests | Queries against a real (containerized) database |

```go
func TestGetUser_NotFound(t *testing.T) {
    svc := &mockUserService{
        getByIDFn: func(ctx context.Context, id string) (*model.User, error) {
            return nil, model.ErrNotFound
        },
    }
    h := handler.NewUserHandler(svc, slog.Default())

    req := httptest.NewRequest(http.MethodGet, "/users/123", nil)
    rec := httptest.NewRecorder()

    h.GetUser(rec, req)

    if rec.Code != http.StatusNotFound {
        t.Errorf("expected 404, got %d", rec.Code)
    }
}
```

**Key rules:**
- Use table-driven tests for variations of the same behavior
- Prefer `testing` + `httptest` over external test frameworks
- Mock at interface boundaries, never patch functions
- Use `t.Helper()` in test helpers for clean stack traces
- Use `testcontainers-go` for integration tests requiring a database

Read `references/testing-patterns.md` for table-driven test examples and integration test setup.

## Step 7: Review Checklist

Before completing any Go API task, verify:

- [ ] Handlers are thin — logic lives in the service layer
- [ ] All errors are wrapped with context and mapped to HTTP codes in one place
- [ ] `context.Context` is threaded from request to every downstream call
- [ ] No exported types or functions in `internal/`
- [ ] Middleware follows `func(http.Handler) http.Handler` signature
- [ ] Structured logging uses `slog` with key-value pairs
- [ ] Tests cover happy path, error paths, and edge cases
