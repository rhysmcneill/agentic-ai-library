# Middleware Patterns

Reusable middleware implementations for Go API services.

## Recovery Middleware

Catch panics and return a 500 instead of crashing the server:

```go
func Recovery(logger *slog.Logger) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            defer func() {
                if rec := recover(); rec != nil {
                    logger.ErrorContext(r.Context(), "panic recovered",
                        "error", rec,
                        "stack", string(debug.Stack()),
                    )
                    http.Error(w, http.StatusText(http.StatusInternalServerError),
                        http.StatusInternalServerError)
                }
            }()
            next.ServeHTTP(w, r)
        })
    }
}
```

## Structured Logging Middleware

Log every request with duration, status, and request ID using `slog`:

```go
func Logger(logger *slog.Logger) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()
            sw := &statusWriter{ResponseWriter: w, status: http.StatusOK}

            next.ServeHTTP(sw, r)

            logger.InfoContext(r.Context(), "request",
                "method", r.Method,
                "path", r.URL.Path,
                "status", sw.status,
                "duration_ms", time.Since(start).Milliseconds(),
                "request_id", RequestIDFromCtx(r.Context()),
            )
        })
    }
}

type statusWriter struct {
    http.ResponseWriter
    status int
}

func (w *statusWriter) WriteHeader(code int) {
    w.status = code
    w.ResponseWriter.WriteHeader(code)
}
```

## Authentication Middleware

Extract and validate a bearer token, then inject the authenticated user into context:

```go
type contextKey string

const userContextKey contextKey = "authenticated_user"

func Auth(validator TokenValidator) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            token := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
            if token == "" {
                http.Error(w, "unauthorized", http.StatusUnauthorized)
                return
            }

            claims, err := validator.Validate(r.Context(), token)
            if err != nil {
                http.Error(w, "unauthorized", http.StatusUnauthorized)
                return
            }

            ctx := context.WithValue(r.Context(), userContextKey, claims)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}

func UserFromCtx(ctx context.Context) (*Claims, bool) {
    claims, ok := ctx.Value(userContextKey).(*Claims)
    return claims, ok
}
```

## Chaining Middleware

Compose middleware into a stack using a simple `Chain` helper:

```go
func Chain(h http.Handler, middlewares ...func(http.Handler) http.Handler) http.Handler {
    for i := len(middlewares) - 1; i >= 0; i-- {
        h = middlewares[i](h)
    }
    return h
}
```

Usage in `main.go`:

```go
stack := middleware.Chain(
    mux,
    middleware.Recovery(logger),
    middleware.RequestID,
    middleware.Logger(logger),
    middleware.CORS(allowedOrigins),
)

srv := &http.Server{
    Addr:         cfg.Addr,
    Handler:      stack,
    ReadTimeout:  5 * time.Second,
    WriteTimeout: 10 * time.Second,
    IdleTimeout:  120 * time.Second,
}
```

Always set explicit timeouts on `http.Server` to prevent slow-client attacks.
