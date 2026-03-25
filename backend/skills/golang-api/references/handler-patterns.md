# Handler Patterns

Detailed patterns for HTTP handlers in Go API services.

## JSON Response Encoding

Use a generic `encode` function to standardize all JSON responses:

```go
func encode[T any](w http.ResponseWriter, r *http.Request, status int, v T) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    if err := json.NewEncoder(w).Encode(v); err != nil {
        slog.ErrorContext(r.Context(), "encode response", "error", err)
    }
}
```

## JSON Request Decoding

Use a generic `decode` function with size limits:

```go
func decode[T any](r *http.Request) (T, error) {
    var v T
    r.Body = http.MaxBytesReader(nil, r.Body, 1<<20) // 1 MB limit
    dec := json.NewDecoder(r.Body)
    dec.DisallowUnknownFields()
    if err := dec.Decode(&v); err != nil {
        return v, fmt.Errorf("%w: %s", model.ErrInvalidInput, err)
    }
    return v, nil
}
```

## Input Validation

Validate decoded input at the handler level before passing to the service:

```go
type CreateUserRequest struct {
    Email string `json:"email"`
    Name  string `json:"name"`
}

func (r CreateUserRequest) Validate() error {
    var errs []string
    if r.Email == "" {
        errs = append(errs, "email is required")
    }
    if r.Name == "" {
        errs = append(errs, "name is required")
    }
    if len(errs) > 0 {
        return fmt.Errorf("%w: %s", model.ErrInvalidInput, strings.Join(errs, "; "))
    }
    return nil
}
```

Call `Validate()` right after `decode()`:

```go
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    req, err := decode[CreateUserRequest](r)
    if err != nil {
        encodeError(w, r, err)
        return
    }
    if err := req.Validate(); err != nil {
        encodeError(w, r, err)
        return
    }
    // proceed with service call
}
```

## Pagination

Use cursor-based pagination for list endpoints:

```go
type PageRequest struct {
    Cursor string
    Limit  int
}

type PageResponse[T any] struct {
    Items      []T    `json:"items"`
    NextCursor string `json:"next_cursor,omitempty"`
}

func parsePagination(r *http.Request) PageRequest {
    limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
    if limit <= 0 || limit > 100 {
        limit = 20
    }
    return PageRequest{
        Cursor: r.URL.Query().Get("cursor"),
        Limit:  limit,
    }
}
```

## Router Registration

Group handler registration by resource to keep routing declarative:

```go
func RegisterRoutes(mux *http.ServeMux, userH *handler.UserHandler, orderH *handler.OrderHandler) {
    mux.HandleFunc("GET /users/{id}", userH.GetUser)
    mux.HandleFunc("POST /users", userH.CreateUser)
    mux.HandleFunc("GET /users", userH.ListUsers)

    mux.HandleFunc("GET /orders/{id}", orderH.GetOrder)
    mux.HandleFunc("POST /orders", orderH.CreateOrder)
}
```

Use Go 1.22+ enhanced routing patterns (`METHOD /path`) on `http.ServeMux` when no external router is needed.
