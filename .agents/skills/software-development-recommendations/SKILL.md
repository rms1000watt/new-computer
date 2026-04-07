---
name: software-development-recommendations
description: Use when writing, reviewing, or designing code. Provides software development recommendations inspired by TigerBeetle's Tiger Style. These are recommendations, not requirements — the existing repo's style guide always takes precedence.
---

# Software Development Recommendations

## Overview

Recommendations for writing safer, faster, and more maintainable code. Inspired heavily by
[TigerBeetle's Tiger Style](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md).

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

### Put a Limit on Everything

- Loops should have bounded iteration counts where possible. Queues should have capacity limits.
  Timeouts should exist on network calls. Retries should have a max count. Buffers should have
  a max size. This follows the fail-fast principle.
- Where a loop genuinely cannot terminate (e.g. an event loop), document this explicitly.

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
- Split compound assertions: prefer `assert(a); assert(b);` over `assert(a && b);` -- the
  former gives more precise failure information.
- Assert relationships between constants and configuration values as a sanity check.
- Assertions catch programmer errors. Operating errors (expected failures like network timeouts)
  must be handled, not asserted.

### Error Handling

> "Almost all (92%) of the catastrophic system failures are the result of incorrect handling of
> non-fatal errors explicitly signaled in software."
> -- [Yuan et al., OSDI '14](https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-yuan.pdf)

- All errors must be handled. Don't swallow exceptions. Don't ignore error return values.
- Handle errors close to where they occur when possible. Don't let error handling be an
  afterthought.

### Scope and Variables

- Declare variables at the smallest possible scope.
- Minimize the number of variables in scope at any given point.
- Don't introduce variables before they are needed. Don't leave them around after they're used.
  This reduces the chance of a place-of-check to place-of-use
  ([TOCTOU](https://en.wikipedia.org/wiki/Time-of-check_to_time-of-use)) style bug.

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

### Compiler Warnings

- Treat all compiler warnings seriously. Prefer the strictest warning/lint settings the project
  supports.

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
- Do not abbreviate. `request_timeout_ms` over `req_to_ms`. Clarity beats brevity.
- Add units or qualifiers to variable names. Put qualifiers last, sorted by descending
  significance: `latency_ms_max` rather than `max_latency_ms`. This groups related variables
  naturally.
- When choosing related names, prefer names with the same character count so related variables
  align in source. `source` and `target` over `src` and `dest` -- second-order effects like
  `source_offset` and `target_offset` aligning pay off in readability.
- Don't overload names with multiple context-dependent meanings.
- Think about how names read in documentation and conversation, not just in code. Nouns
  compose better than adjectives or participles for derived identifiers.
- Callbacks go last in parameter lists. This mirrors control flow: they are invoked last.
- **Order matters for readability.** Put important things near the top of the file. The entry
  point or primary public API goes first.

### Comments and Documentation

- **Always say why.** Code alone is not documentation. Comments explain rationale, not just
  mechanics. Show your workings.
- **Also say how.** For tests especially, write a description at the top explaining the goal
  and methodology so readers can orient without diving into every line.
- Comments are well-written prose, not scribblings in the margin. Capital letter, full stop,
  proper sentences.
- Write descriptive commit messages. A PR description is not stored in `git blame` and is not
  a substitute for a good commit message.

### Avoiding Stale State

- Don't duplicate variables or alias mutable state. Duplicated state gets out of sync.
- Calculate or check values close to where they are used. Proximity in space and time reduces
  the semantic gap where bugs hide.
- Group resource acquisition and release together visually. This makes leaks easier to spot
  during review.

### Off-by-one Awareness

- Treat `index`, `count`, and `size` as conceptually distinct types even when they share the
  same numeric type. An index is 0-based, a count is 1-based, and a size requires multiplying
  by a unit. Naming them clearly prevents confusion.
- Be explicit about rounding behavior in division. Show the reader you've considered what
  happens at the boundaries.

### Conditions and Negation

- Split compound boolean conditions into nested `if/else` branches when it improves clarity
  about which cases are handled.
- State invariants positively. `if (index < length)` is easier to reason about than
  `if (!(index >= length))`.
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

## Reminder

These recommendations come from TigerBeetle's
[Tiger Style](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md), a guide
built for safety-critical systems programming. Not every recommendation applies to every project
or language. Use judgment. Adapt to context. But the core principles -- think upfront, be explicit,
handle all errors, assert invariants, name things well, say why -- are universal.

**When in doubt, follow the existing codebase's conventions.**
