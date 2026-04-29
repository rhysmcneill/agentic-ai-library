# Concurrency Patterns

Covers rules: `conc-context`, `conc-goroutine-cleanup`, `conc-channel-ownership`, `conc-mutex-vs-channel`, `conc-race-detector`

---

## `conc-context` — Context as first parameter

`context.Context` must be the first parameter of any function that does I/O, calls external services, or can be cancelled. Never store a context in a struct field.

**Anti-pattern:**
```go
type Client struct {
    ctx context.Context // don't store context in structs
}

func fetchUser(id string) (*User, error) { // no context — cannot be cancelled
    resp, err := http.Get("https://api.example.com/users/" + id)
    // ...
}
```

**Best practice:**
```go
// ctx is always first, followed by other parameters
func fetchUser(ctx context.Context, id string) (*User, error) {
    req, err := http.NewRequestWithContext(ctx, http.MethodGet,
        "https://api.example.com/users/"+id, nil)
    if err != nil {
        return nil, fmt.Errorf("build request: %w", err)
    }
    resp, err := http.DefaultClient.Do(req)
    // ...
}

// Propagate deadlines through the call chain:
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()
user, err := fetchUser(ctx, id)
```

---

## `conc-goroutine-cleanup` — Every goroutine has a defined exit path

A goroutine leak is as bad as a memory leak. Always ensure goroutines can exit cleanly.

**Anti-pattern:**
```go
go func() {
    for msg := range messages {
        process(msg) // leaks if nothing closes messages
    }
}()
```

**Best practice:**
```go
// Use errgroup for a group of goroutines that can fail:
g, ctx := errgroup.WithContext(ctx)

g.Go(func() error {
    for {
        select {
        case msg, ok := <-messages:
            if !ok {
                return nil
            }
            if err := process(ctx, msg); err != nil {
                return err
            }
        case <-ctx.Done():
            return ctx.Err()
        }
    }
})

if err := g.Wait(); err != nil {
    log.Printf("worker error: %v", err)
}
```

---

## `conc-channel-ownership` — The sender closes the channel

Only the goroutine that creates and sends on a channel should close it. Closing from the receiver causes a panic.

**Anti-pattern:**
```go
func consumer(ch chan int) {
    for v := range ch {
        fmt.Println(v)
    }
    close(ch) // panic: close of closed channel / wrong owner
}
```

**Best practice:**
```go
func producer(ctx context.Context) <-chan int {
    ch := make(chan int)
    go func() {
        defer close(ch) // producer closes its own channel
        for i := 0; i < 10; i++ {
            select {
            case ch <- i:
            case <-ctx.Done():
                return
            }
        }
    }()
    return ch
}

func consumer(ctx context.Context) {
    for v := range producer(ctx) {
        fmt.Println(v)
    }
}
```

---

## `conc-mutex-vs-channel` — Channel vs Mutex

| Use channels for... | Use mutex for... |
|---------------------|-----------------|
| Transferring ownership of data | Protecting shared state |
| Signalling between goroutines | Caches, counters, maps |
| Pipelines and fan-out/fan-in | Simple read/write guards |

**Anti-pattern (wrong tool):**
```go
// Using a channel as a mutex for a shared counter — overcomplicated
counter := make(chan int, 1)
counter <- 0
go func() {
    v := <-counter
    counter <- v + 1
}()
```

**Best practice:**
```go
// Shared state → mutex
type SafeCounter struct {
    mu    sync.Mutex
    count int
}

func (c *SafeCounter) Inc() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.count++
}

// Ownership transfer → channel
results := make(chan Result)
go func() {
    results <- compute()
}()
r := <-results
```

---

## `conc-race-detector` — Always run with `-race`

The Go race detector catches data races that are invisible at compile time.

```bash
# Locally:
go test -race ./...

# CI (GitHub Actions):
- run: go test -race -count=1 ./...

# Integration tests:
go run -race ./cmd/server
```

Any race condition reported by `-race` is a bug — fix it before merging.
