---
name: software-development-recommendations
description: Use when writing, reviewing, or designing code. Provides software development recommendations inspired by TigerBeetle's Tiger Style and adapted for Go. These are recommendations, not requirements — the existing repo's style guide always takes precedence.
---

# Software Development Recommendations

## Overview

Recommendations for writing safer, faster, and more maintainable code. Inspired heavily by
[TigerBeetle's Tiger Style](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md),
with Go-specific adaptations drawn from [Effective Go](https://go.dev/doc/effective_go) and
[Go-Tiger-Style](https://github.com/Predixus/Go-Tiger-Style).

**These are recommendations, not mandates.** The existing repository's coding style, conventions,
and linter rules always take precedence. When a recommendation here conflicts with the project's
established patterns, follow the project. Use these as a lens for thinking about code quality,
not as a checklist to impose on an existing codebase.

The priorities, in order: **safety, performance, developer experience.** All three matter.

## Design Philosophy

> "Simplicity and elegance are unpopular because they require hard work and discipline to achieve"
> -- Edsger Dijkstra

- Simplicity is not the first attempt but the hardest revision. Invest thought upfront. An hour
  of design is worth weeks in production.
- Seek the "super idea" that satisfies safety, performance, and DX simultaneously rather than
  treating them as tradeoffs.
- When you find a showstopper during design or implementation, fix it now. The second chance may
  not come.
- What we ship should be solid. We may lack features, but what exists meets our standards.

## Safety

Reference: [NASA's Power of Ten -- Rules for Developing Safety Critical Code](https://spinroot.com/gerard/pdf/P10.pdf)

### Control Flow

- Prefer simple, explicit control flow. Avoid cleverness that obscures what the code actually does.
- Be cautious with recursion -- prefer iteration when the recursion depth is not obviously bounded.
- Use only a minimum of excellent abstractions. Every abstraction risks being a leaky abstraction.
  Don't abstract until the pattern is clear and the abstraction genuinely simplifies the domain.
- In Go, prefer `switch` over long `if-else-if` chains. A `switch` with no expression switches
  on `true` and reads cleanly.

### Put a Limit on Everything

- Loops should have bounded iteration counts where possible. Queues should have capacity limits.
  Timeouts should exist on network calls. Retries should have a max count. Buffers should have
  a max size. This follows the fail-fast principle.
- Where a loop genuinely cannot terminate (e.g. an event loop), document this explicitly.
- In Go, always be explicit about capacity when allocating with `make`. Pre-allocate slices and
  maps when the size is known or estimable. Pre-size channels deliberately (see Go Specifics).

### Assertions and Validation

> "Assertions downgrade catastrophic correctness bugs into liveness bugs." -- Tiger Style

- Validate function arguments and return values. A function should not operate blindly on
  unchecked data.
- Assert preconditions, postconditions, and invariants. Assertions are documentation that the
  runtime can verify.
- **Assert both the positive and negative space.** Assert what you *do* expect AND what you
  *do not* expect. Bugs often live at the boundary between valid and invalid.
- **Pair assertions** where possible. If you validate data before writing, also validate after
  reading. Two checkpoints are better than one.
- Split compound assertions: prefer separate checks over `assert(a && b)` -- the former gives
  more precise failure information.
- Assert relationships between constants and configuration values as a sanity check.
- Assertions catch programmer errors. Operating errors (expected failures like network timeouts)
  must be handled, not asserted.
- **Go note:** Go has no built-in `assert`. The Go team
  [discourages assertions as a replacement for error handling](https://go.dev/doc/faq#assertions).
  But assertions remain valuable for catching programmer errors during testing and development.
  Use build tags (`//go:build debug`) to create debug-only assertion functions that compile to
  no-ops in release builds (see Go Specifics below).

### Error Handling

> "Almost all (92%) of the catastrophic system failures are the result of incorrect handling of
> non-fatal errors explicitly signaled in software."
> -- [Yuan et al., OSDI '14](https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-yuan.pdf)

- All errors must be handled. Don't ignore error return values.
- Handle errors close to where they occur when possible. Don't let error handling be an
  afterthought.
- **In Go, always check `err` returns.** Never use the blank identifier `_` to discard an error
  unless you have a documented reason and can defend it. `fi, _ := os.Stat(path)` is dangerous.
- Return errors to the caller with context. Use `fmt.Errorf("operation failed: %w", err)` to
  wrap errors, preserving the chain for `errors.Is` and `errors.As`.
- When feasible, error strings should identify their origin: prefix with the operation or package
  that generated the error (e.g. `"image: unknown format"`).
- Guard against errors early, returning on failure so the happy path flows down the page without
  indentation. This is idiomatic Go:

  ```go
  f, err := os.Open(name)
  if err != nil {
      return err
  }
  defer f.Close()
  // happy path continues unindented
  ```

- Omit the `else` when the `if` body ends in `break`, `continue`, `goto`, or `return`.
- **Panic only for truly unrecoverable programmer errors**, not operational failures. Panics
  within a package should be caught and converted to errors at the package boundary -- never
  expose panics to callers.
- Use `recover` in deferred functions to gracefully handle panics in server goroutines without
  killing the process:

  ```go
  func safelyDo(work *Work) {
      defer func() {
          if err := recover(); err != nil {
              log.Println("work failed:", err)
          }
      }()
      do(work)
  }
  ```

### Scope and Variables

- Declare variables at the smallest possible scope.
- Minimize the number of variables in scope at any given point.
- Don't introduce variables before they are needed. Don't leave them around after they're used.
  This reduces the chance of a
  [TOCTOU](https://en.wikipedia.org/wiki/Time-of-check_to_time-of-use) style bug.
- In Go, prefer `:=` short declarations to `var` when initializing a variable with a value.
  Use `var` for zero-value declarations where the type matters.
- Use `if` init statements to limit variable scope: `if err := doThing(); err != nil { ... }`.

### Functions

- Keep functions short enough to fit on a screen. Tiger Style uses a hard limit of 70 lines.
  Whatever the limit, the principle is: if you have to scroll to see the whole function, it's
  probably too long.
- Good function shape: a few parameters, a simple return type, meaty logic in the body.
- **Centralize control flow.** When splitting a large function, keep branching logic (if/switch)
  in the parent and move non-branchy logic into helpers.
  ["Push ifs up and fors down."](https://matklad.github.io/2023/11/15/push-ifs-up-and-fors-down.html)
- Keep leaf functions pure when possible. Let the caller own state; let helpers compute what
  should change.
- Use simpler return types to reduce branching at the call site. Complexity in return types
  propagates virally through the call chain.
- **In Go, use named return values** when they clarify which value is which, but avoid bare
  `return` in non-trivial functions -- it hurts readability.
- **Use `defer` for resource cleanup** immediately after acquisition. `defer f.Close()` right
  after `os.Open`. This groups acquisition and release together visually and guarantees cleanup
  on all return paths.

### Linting and Static Analysis

- Use Go's static analysis tools at their strictest settings: `go vet`, `staticcheck`,
  `golangci-lint`.
- Treat all warnings seriously. Run `gofmt` (or `goimports`) -- formatting is not optional in Go.

### External Events

- Don't do things directly in reaction to external events. Let your program run at its own pace,
  batching external inputs. This keeps control flow under your control and improves both safety
  and performance.

## Performance

> "The best time to solve performance, to get the huge 1000x wins, is in the design phase, which
> is precisely when we can't measure or profile." -- Tiger Style

- Think about performance from the design phase. The biggest wins come from choosing the right
  data structures and algorithms, not from micro-optimization later.
- **Do back-of-the-envelope sketches** for the four resources (network, disk, memory, CPU) and
  their two characteristics (bandwidth, latency). Sketches are cheap. Be "roughly right."
- Optimize for the slowest resource first (network > disk > memory > CPU), adjusting for
  frequency of access.
- **Batch operations.** Amortize costs across network calls, disk I/O, memory allocations, and
  CPU work. Batching is one of the most universally applicable performance techniques.
- Distinguish between **control plane** (infrequent, correctness-critical) and **data plane**
  (frequent, performance-critical). This delineation lets you be thorough on the control plane
  and fast on the data plane.
- Be predictable. Give the CPU large, regular chunks of work rather than forcing it to
  context-switch constantly.
- Be explicit about what matters for performance. Don't rely on the compiler or runtime to
  magically optimize hot paths.

## Developer Experience

### Naming

> "Great names are the essence of great code." -- Tiger Style

- **Get the nouns and verbs right.** Take time to find names that capture what a thing is or
  does, providing a crisp mental model. Good names show you understand the domain.
- Add units or qualifiers to variable names where ambiguity exists: `timeoutMs`, `bufferSizeBytes`.
- Don't overload names with multiple context-dependent meanings.
- Think about how names read in documentation and conversation, not just in code.
- **Order matters for readability.** Put important things near the top of the file. The entry
  point or primary public API goes first.

**Go-specific naming conventions** (these override the general Tiger Style "never abbreviate"
advice -- Go has its own strong conventions):

- **MixedCaps / mixedCaps, never underscores.** This is non-negotiable in Go.
- **Short package names:** lower case, single-word, no underscores or mixedCaps. Err on the
  side of brevity (`bufio`, `fmt`, `strconv`). The package name is part of every qualified
  reference.
- **Don't stutter.** An exported name is qualified by its package: `bufio.Reader` not
  `bufio.BufReader`. `ring.New` not `ring.NewRing`.
- **Getters drop "Get":** a getter for field `owner` is `Owner()`, not `GetOwner()`. Setters
  keep the prefix: `SetOwner()`.
- **One-method interfaces** use the method name + `-er`: `Reader`, `Writer`, `Formatter`,
  `Stringer`.
- **Local variables can be short** when context makes them clear: `i` for index, `r` for reader,
  `buf` for buffer. But exported names and function parameters should be descriptive.
- **Acronyms are all-caps:** `URL`, `HTTP`, `ID` -- `ServeHTTP` not `ServeHttp`, `userID` not
  `userId`.

### Comments and Documentation

- **Always say why.** Code alone is not documentation. Comments explain rationale, not just
  mechanics. Show your workings.
- **Also say how.** For tests especially, write a description at the top explaining the goal
  and methodology so readers can orient without diving into every line.
- Comments are well-written prose, not scribblings in the margin. Capital letter, full stop,
  proper sentences.
- **In Go, doc comments** precede the declaration with no blank line. They begin with the name
  of the thing being documented: `// Reader implements buffered reading.`
- Write descriptive commit messages. A PR description is not stored in `git blame` and is not
  a substitute for a good commit message.

### Avoiding Stale State

- Don't duplicate variables or alias mutable state. Duplicated state gets out of sync.
- Calculate or check values close to where they are used. Proximity in space and time reduces
  the semantic gap where bugs hide.
- Group resource acquisition and release together visually. In Go, `defer` is your primary tool
  for this.

### Off-by-one Awareness

- Treat `index`, `count`, and `size` as conceptually distinct types even when they share the
  same numeric type. An index is 0-based, a count is 1-based, and a size requires multiplying
  by a unit. Naming them clearly prevents confusion.
- Be explicit about rounding behavior in division. Show the reader you've considered what
  happens at the boundaries.

### Conditions and Negation

- Split compound boolean conditions into nested `if/else` branches when it improves clarity
  about which cases are handled.
- State invariants positively. `if index < length` is easier to reason about than
  `if !(index >= length)`.
- Consider whether every `if` needs a corresponding `else`, even if just for an assertion,
  to ensure both positive and negative spaces are addressed.

### Be Explicit

- Prefer passing explicit options to library/framework functions at the call site rather than
  relying on defaults. This improves readability and protects against breaking changes if
  defaults change.

### Dependencies and Tooling

- Be conservative about adding dependencies. Each dependency is a liability: supply chain risk,
  maintenance burden, install time, potential version conflicts.
- Prefer a small, well-understood toolbox over an array of specialized instruments.

> "The right tool for the job is often the tool you are already using -- adding new tools has a
> higher cost than many people appreciate." -- John Carmack

## Testing

- Tests must test exhaustively: not only valid inputs but also invalid inputs, and the
  transitions as valid data becomes invalid.
- Assertions in production code are a force multiplier for fuzz testing and property-based
  testing. The more invariants you assert, the more bugs fuzzing will find.
- Build a mental model first. Encode it as assertions. Write code and comments to justify the
  model. Use automated testing as the final line of defense.
- **In Go, use table-driven tests** as the baseline, but complement them with fuzz tests
  (`func FuzzXxx`) for property-based testing.
- Key properties to fuzz for: **invariants** (always true), **inverse operations** (encode/decode),
  **idempotency** (apply twice = apply once), and **non-idempotency** (hashing should differ).
- Use `t.Helper()` in test helper functions so failures report the caller's line.
- Use `t.Parallel()` where safe to catch concurrency bugs and speed up the suite.

## Go-Specific Recommendations

These are Go-specific adaptations of Tiger Style principles.

### Explicit Allocation with `make`

Pre-allocate capacity when the size is known or estimable:

```go
// Good: single allocation
data := make([]int, 0, expectedSize)
users := make(map[string]User, expectedCount)

// Bad: multiple re-allocations as it grows
data := make([]int, 0)
users := make(map[string]User)
```

### Slice Capacity Sharing

Understand that sub-slices share backing arrays. When independence is required for correctness,
copy explicitly:

```go
// Safe: independent slice
slice2 := make([]int, len(original[0:3]))
copy(slice2, original[0:3])

// Fast but dangerous: shared backing array
slice2 := original[0:3]
slice2 = append(slice2, 42) // may mutate original's memory
```

Choose copy-based independence when correctness matters. Use sharing only when performance is
critical and the relationship is well-documented.

### Channel Discipline

Be explicit about channel buffering intent:

```go
chSync := make(chan int)        // unbuffered: synchronous handoff
chAsync := make(chan int, 100)  // buffered: async up to capacity
```

Name or comment channels to convey their synchronization role. A buffered channel can serve as
a semaphore to limit concurrency:

```go
var sem = make(chan struct{}, maxConcurrent)
// acquire: sem <- struct{}{}
// release: <-sem
```

### Concurrency

> "Do not communicate by sharing memory; instead, share memory by communicating." -- Effective Go

- Prefer channels for coordination between goroutines. Use mutexes for simple shared counters
  or when channel overhead is unjustified.
- **Don't confuse concurrency with parallelism.** Concurrency is about structure; parallelism
  is about execution. Not all problems benefit from Go's concurrency model.
- Start a fixed number of worker goroutines reading from a shared channel rather than spawning
  unbounded goroutines per request.
- Always ensure goroutines can terminate. Provide cancellation via `context.Context` or a
  `done`/`quit` channel.
- Use `select` with a `default` case for non-blocking channel operations.

### Interfaces

- Accept interfaces, return structs. This maximizes flexibility for callers while keeping
  implementations concrete.
- Keep interfaces small. One or two methods is the sweet spot. Compose larger interfaces from
  smaller ones via embedding.
- If a type exists only to implement an interface, return the interface type from the
  constructor and don't export the struct.
- Use compile-time interface checks when there are no static conversions to verify conformance:

  ```go
  var _ json.Marshaler = (*MyType)(nil)
  ```

### Embedding

- Use struct embedding to compose behavior, not to simulate inheritance. The embedded type's
  methods promote but the receiver is always the inner type.
- Be aware of name conflicts: a field in the outer struct shadows same-named fields/methods
  from embedded types.

### Zero Values

- Design structs so the zero value is useful. `sync.Mutex{}` is an unlocked mutex,
  `bytes.Buffer{}` is an empty buffer ready to use. Follow this pattern in your own types.
- Use `new(T)` or `&T{}` to get a pointer to a zero-value `T`. Use `make` only for slices,
  maps, and channels.

### Debug Assertions via Build Tags

Go lacks built-in assertions, but build tags give you debug-only checks:

```go
// assert_debug.go
//go:build debug

package mypackage

func assert(condition bool, msg string) {
    if !condition {
        panic("assertion failed: " + msg)
    }
}

// assert_release.go
//go:build !debug

package mypackage

func assert(condition bool, msg string) {}
```

Run tests with `-tags debug` to activate assertions. This makes assertions a force multiplier
for fuzz testing.

### `init` Functions

- Use `init()` sparingly. Prefer explicit initialization in `main` or constructors.
- When you do use `init()`, limit it to verifying program state or registering handlers.
  Never do I/O or anything that can fail silently.

### `defer` Patterns

- `defer` immediately after resource acquisition. Don't let other code separate open from close.
- Remember: deferred function arguments are evaluated at the `defer` statement, not at execution.
- Deferred functions run LIFO. Use this to your advantage for nested resource cleanup.

## Reminder

These recommendations draw from TigerBeetle's
[Tiger Style](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md),
[Effective Go](https://go.dev/doc/effective_go), and
[Go-Tiger-Style](https://github.com/Predixus/Go-Tiger-Style). Not every recommendation applies
to every project. Use judgment. Adapt to context. But the core principles -- think upfront, be
explicit, handle all errors, assert invariants, name things well, say why -- are universal.

**When in doubt, follow the existing codebase's conventions.**
