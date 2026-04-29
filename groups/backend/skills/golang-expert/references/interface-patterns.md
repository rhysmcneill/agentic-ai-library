# Interface & Composition Patterns

Covers rules: `iface-small`, `iface-accept-return`, `iface-define-at-use`, `iface-composition`

---

## `iface-small` — Prefer single-method interfaces

The smaller the interface, the more types can satisfy it. Go's standard library leads by example: `io.Reader`, `io.Writer`, `fmt.Stringer` each have exactly one method.

**Anti-pattern:**
```go
type UserRepository interface {
    GetUser(id string) (*User, error)
    ListUsers() ([]*User, error)
    CreateUser(u *User) error
    UpdateUser(u *User) error
    DeleteUser(id string) error
    // ...many more methods — every implementor must satisfy all of them
}
```

**Best practice:**
```go
// Split by usage at the call site:
type UserGetter interface {
    GetUser(ctx context.Context, id string) (*User, error)
}

type UserCreator interface {
    CreateUser(ctx context.Context, u *User) error
}

// A function that only reads should only require UserGetter:
func buildProfile(ctx context.Context, repo UserGetter, id string) (*Profile, error) {
    u, err := repo.GetUser(ctx, id)
    // ...
}
```

---

## `iface-accept-return` — Accept interfaces, return concrete types

Functions that accept interfaces are flexible (any implementation works). Functions that return concrete types are explicit (callers know exactly what they get and can access all methods).

**Anti-pattern:**
```go
// Returning an interface hides the concrete type unnecessarily
func NewStore() DataStore {
    return &postgresStore{}
}

// Accepting a concrete type restricts callers
func processItems(s *postgresStore) error { ... }
```

**Best practice:**
```go
// Return concrete — callers that need the interface can hold it themselves
func NewStore(dsn string) (*PostgresStore, error) {
    // ...
    return &PostgresStore{db: db}, nil
}

// Accept interface — any store implementation works
func processItems(ctx context.Context, s ItemReader) error {
    items, err := s.ListItems(ctx)
    // ...
}
```

---

## `iface-define-at-use` — Define interfaces where they are consumed

Interfaces belong to the package that depends on the behaviour, not the package that provides it. This avoids import cycles and keeps packages decoupled.

**Anti-pattern:**
```go
// package storage — defines the interface
package storage

type Repository interface { // storage shouldn't know about its consumers
    GetUser(id string) (*User, error)
}
```

**Best practice:**
```go
// package service — defines the interface it needs
package service

// Repository is the subset of storage behaviour this package requires.
type Repository interface {
    GetUser(ctx context.Context, id string) (*User, error)
}

type UserService struct {
    repo Repository
}
```

The `storage.PostgresStore` satisfies `service.Repository` implicitly — no import of `service` required from `storage`.

---

## `iface-composition` — Compose interfaces from smaller ones

When a single call site genuinely needs multiple behaviours, compose interfaces rather than defining a monolithic one.

**Anti-pattern:**
```go
type Store interface {
    Get(ctx context.Context, key string) ([]byte, error)
    Set(ctx context.Context, key string, val []byte) error
    Delete(ctx context.Context, key string) error
    List(ctx context.Context, prefix string) ([]string, error)
    Watch(ctx context.Context, key string) (<-chan Event, error)
}
// Hard to mock, hard to implement partially
```

**Best practice:**
```go
type Getter interface {
    Get(ctx context.Context, key string) ([]byte, error)
}

type Setter interface {
    Set(ctx context.Context, key string, val []byte) error
}

type Deleter interface {
    Delete(ctx context.Context, key string) error
}

// Compose only where needed:
type ReadWriter interface {
    Getter
    Setter
}

type Store interface {
    Getter
    Setter
    Deleter
}
```
