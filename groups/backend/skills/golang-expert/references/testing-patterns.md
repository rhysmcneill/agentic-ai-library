# Testing Patterns

Covers rules: `test-table-driven`, `test-subtests`, `test-interface-mocking`, `test-golden-files`, `test-benchmarks`

---

## `test-table-driven` — Table-driven tests

Group related test cases into a slice of structs. This eliminates repetition and makes adding new cases trivial.

**Anti-pattern:**
```go
func TestAdd(t *testing.T) {
    result := Add(1, 2)
    if result != 3 {
        t.Errorf("Add(1,2) = %d, want 3", result)
    }
    result = Add(-1, 1)
    if result != 0 {
        t.Errorf("Add(-1,1) = %d, want 0", result)
    }
    // ...copy-paste for each case
}
```

**Best practice:**
```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        a, b int
        want int
    }{
        {"positive", 1, 2, 3},
        {"zero sum", -1, 1, 0},
        {"both negative", -2, -3, -5},
    }

    for _, tc := range tests {
        t.Run(tc.name, func(t *testing.T) {
            got := Add(tc.a, tc.b)
            if got != tc.want {
                t.Errorf("Add(%d,%d) = %d, want %d", tc.a, tc.b, got, tc.want)
            }
        })
    }
}
```

---

## `test-subtests` — Use `t.Run` for isolation

`t.Run` gives each case its own isolated test context. Failures in one case do not abort others, and you can run a single case with `-run TestFoo/case_name`.

```go
for _, tc := range tests {
    tc := tc // capture loop variable (pre-Go 1.22)
    t.Run(tc.name, func(t *testing.T) {
        t.Parallel() // optional: run cases in parallel
        got, err := doThing(tc.input)
        if tc.wantErr {
            require.Error(t, err)
            return
        }
        require.NoError(t, err)
        assert.Equal(t, tc.want, got)
    })
}
```

---

## `test-interface-mocking` — Mock via interfaces

Design production code to accept interfaces. Tests provide simple fake implementations — no reflection, no monkey-patching.

**Production code:**
```go
type Emailer interface {
    Send(ctx context.Context, to, subject, body string) error
}

type UserService struct {
    email Emailer
}

func (s *UserService) Register(ctx context.Context, u *User) error {
    // ...
    return s.email.Send(ctx, u.Email, "Welcome", "Thanks for joining!")
}
```

**Test fake:**
```go
type fakeEmailer struct {
    sent []string
}

func (f *fakeEmailer) Send(_ context.Context, to, _, _ string) error {
    f.sent = append(f.sent, to)
    return nil
}

func TestRegister(t *testing.T) {
    emailer := &fakeEmailer{}
    svc := &UserService{email: emailer}

    err := svc.Register(context.Background(), &User{Email: "a@b.com"})
    require.NoError(t, err)
    assert.Equal(t, []string{"a@b.com"}, emailer.sent)
}
```

---

## `test-golden-files` — Golden files for complex outputs

When expected output is large or structured (JSON, rendered templates, generated code), store it in `testdata/*.golden` and compare against it. Update with `-update`.

```go
var update = flag.Bool("update", false, "update golden files")

func TestRender(t *testing.T) {
    got := render(input)
    golden := filepath.Join("testdata", t.Name()+".golden")

    if *update {
        os.WriteFile(golden, []byte(got), 0644)
    }

    want, err := os.ReadFile(golden)
    require.NoError(t, err)
    assert.Equal(t, string(want), got)
}
```

```bash
# Update golden files after intentional output changes:
go test ./... -update
```

---

## `test-benchmarks` — Benchmark performance-critical paths

Write benchmarks for any code on a hot path. Run them before and after optimisations to confirm improvement.

```go
func BenchmarkProcess(b *testing.B) {
    data := generateTestData(1000)
    b.ResetTimer() // exclude setup from measurement

    for i := 0; i < b.N; i++ {
        process(data)
    }
}

// With allocation reporting:
func BenchmarkMarshal(b *testing.B) {
    b.ReportAllocs()
    for i := 0; i < b.N; i++ {
        _, _ = json.Marshal(payload)
    }
}
```

```bash
go test -bench=BenchmarkProcess -benchmem -count=5 ./...
```

Compare results with `benchstat` to detect regressions in CI.
