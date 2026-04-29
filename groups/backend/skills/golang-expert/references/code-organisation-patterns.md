# Code Organisation Patterns

Covers rules: `org-module-structure`, `org-package-naming`, `org-package-cohesion`, `org-internal`, `org-cmd`

---

## `org-module-structure` — Standard module layout

One `go.mod` per repository. The module path must match the repository URL for public modules.

**Recommended layout:**
```
my-service/
├── go.mod
├── go.sum
├── cmd/
│   └── server/
│       └── main.go        ← thin: parse flags, wire deps, call Run()
├── internal/
│   ├── handler/           ← HTTP handlers
│   ├── service/           ← business logic
│   └── store/             ← database layer
├── pkg/                   ← (optional) code safe to import externally
│   └── apierror/
└── testdata/
```

Avoid the flat layout where all files live in the root package — it makes the package boundary the entire repository.

---

## `org-package-naming` — Short, lowercase, singular

Package names are used as qualifiers: `user.Service`, `http.Client`. They must be short, lowercase, no underscores or mixedCase.

| Bad | Good | Why |
|-----|------|-----|
| `userService` | `service` | mixedCase not idiomatic |
| `user_service` | `service` | underscores not idiomatic |
| `utils` | `format`, `validate` | vague; name by what it does |
| `common` | `middleware` | vague |
| `models` | `user`, `order` | layer-name; name by domain |

---

## `org-package-cohesion` — Organise by domain, not layer

Group code by domain concept (what it represents) rather than technical layer (what tier it sits in). Layered packages create import cycles and make the codebase harder to navigate.

**Anti-pattern (layered):**
```
models/     ← User, Order, Product structs
services/   ← UserService, OrderService
handlers/   ← UserHandler, OrderHandler
```

**Best practice (domain):**
```
user/
├── user.go       ← User type + domain logic
├── store.go      ← Store interface + postgres impl
└── handler.go    ← HTTP handler
order/
├── order.go
└── ...
```

Each domain package is self-contained; dependencies flow inward (handler → service → store) within the domain.

---

## `org-internal` — Use `internal/` to enforce boundaries

Packages under `internal/` can only be imported by code in the parent tree. Use this to prevent external packages from depending on implementation details.

```
mymodule/
├── internal/
│   ├── cache/       ← private implementation; nobody outside can import this
│   └── auth/        ← private auth logic
└── pkg/
    └── client/      ← public API; uses internal/cache but hides it
```

```go
// This import is rejected by the compiler for code outside mymodule/:
import "mymodule/internal/cache" // ✗ if importer is outside mymodule/
```

---

## `org-cmd` — Keep `main` packages thin

`cmd/<name>/main.go` should only:
1. Parse flags / read env vars
2. Wire dependencies (construct structs, open DB connections)
3. Call a `Run` function that contains the actual logic

**Anti-pattern:**
```go
// main.go — 500 lines of business logic mixed with flag parsing
func main() {
    db, _ := sql.Open(...)
    rows, _ := db.Query("SELECT ...")
    // ... all logic inline
}
```

**Best practice:**
```go
// cmd/server/main.go
func main() {
    cfg := config.MustLoad()
    db := database.MustConnect(cfg.DSN)
    srv := server.New(cfg, db)
    if err := srv.Run(context.Background()); err != nil {
        log.Fatal(err)
    }
}
```

The `server` package is fully testable without touching `main`.
