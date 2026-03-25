# Testing Patterns

Go API testing strategies and concrete examples.

## Table-Driven Tests

Use table-driven tests for handler and service methods that handle multiple cases:

```go
func TestGetUser(t *testing.T) {
    tests := []struct {
        name       string
        userID     string
        svcResult  *model.User
        svcErr     error
        wantStatus int
    }{
        {
            name:       "success",
            userID:     "abc",
            svcResult:  &model.User{ID: "abc", Name: "Alice"},
            wantStatus: http.StatusOK,
        },
        {
            name:       "not found",
            userID:     "missing",
            svcErr:     model.ErrNotFound,
            wantStatus: http.StatusNotFound,
        },
        {
            name:       "internal error",
            userID:     "fail",
            svcErr:     errors.New("db down"),
            wantStatus: http.StatusInternalServerError,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            svc := &mockUserService{
                getByIDFn: func(ctx context.Context, id string) (*model.User, error) {
                    return tt.svcResult, tt.svcErr
                },
            }
            h := handler.NewUserHandler(svc, slog.Default())

            req := httptest.NewRequest(http.MethodGet, "/users/"+tt.userID, nil)
            req.SetPathValue("id", tt.userID)
            rec := httptest.NewRecorder()

            h.GetUser(rec, req)

            if rec.Code != tt.wantStatus {
                t.Errorf("status = %d, want %d", rec.Code, tt.wantStatus)
            }
        })
    }
}
```

## Manual Interface Mocks

Define mocks as structs with function fields — no code generation required:

```go
type mockUserService struct {
    getByIDFn func(ctx context.Context, id string) (*model.User, error)
    createFn  func(ctx context.Context, input model.CreateUserInput) (*model.User, error)
}

func (m *mockUserService) GetByID(ctx context.Context, id string) (*model.User, error) {
    return m.getByIDFn(ctx, id)
}

func (m *mockUserService) Create(ctx context.Context, input model.CreateUserInput) (*model.User, error) {
    return m.createFn(ctx, input)
}
```

Place mocks in the test file that uses them (`handler/user_test.go`), not in a shared `mocks/` package.

## Integration Tests with testcontainers-go

Use `testcontainers-go` to spin up a real database for repository tests:

```go
func setupPostgres(t *testing.T) *pgxpool.Pool {
    t.Helper()
    ctx := context.Background()

    container, err := postgres.Run(ctx,
        "postgres:16-alpine",
        postgres.WithDatabase("testdb"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
        testcontainers.WithWaitStrategy(
            wait.ForLog("database system is ready to accept connections").
                WithOccurrence(2).
                WithStartupTimeout(5*time.Second),
        ),
    )
    if err != nil {
        t.Fatalf("start postgres: %v", err)
    }
    t.Cleanup(func() { container.Terminate(ctx) })

    connStr, err := container.ConnectionString(ctx, "sslmode=disable")
    if err != nil {
        t.Fatalf("connection string: %v", err)
    }

    pool, err := pgxpool.New(ctx, connStr)
    if err != nil {
        t.Fatalf("connect: %v", err)
    }
    t.Cleanup(pool.Close)

    return pool
}
```

Run integration tests with a build tag to keep them separate from unit tests:

```go
//go:build integration

package repository_test
```

Execute with: `go test -tags=integration ./internal/repository/...`

## Test Helpers

Mark helpers with `t.Helper()` so failure messages point to the calling test:

```go
func assertStatus(t *testing.T, got, want int) {
    t.Helper()
    if got != want {
        t.Errorf("status = %d, want %d", got, want)
    }
}

func assertJSON(t *testing.T, body *bytes.Buffer, key, want string) {
    t.Helper()
    var m map[string]any
    if err := json.NewDecoder(body).Decode(&m); err != nil {
        t.Fatalf("decode body: %v", err)
    }
    if got := fmt.Sprint(m[key]); got != want {
        t.Errorf("%s = %q, want %q", key, got, want)
    }
}
```
