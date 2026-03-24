# Project Manager — Development Complexities & Learnings

A project management application built entirely in Jac (fullstack), using `jac-client` for the React-based frontend and `jac-scale` for the backend API layer.

---

## 1. Jac Is Not Python — Syntax Traps Everywhere

The single biggest friction point. Jac looks like Python at a glance but breaks in non-obvious ways:

- **Semicolons required on every statement** — missing one causes cascading parse errors that are hard to trace back to the source line.
- **Braces instead of indentation** — familiar concept, but mixing habits from Python leads to subtle block-scoping bugs.
- **`self` is implicit in `obj` method signatures** — declaring `def method(self, x: int)` is wrong; the correct form is `def method(x: int)`. The compiler error message for this is not immediately obvious.
- **No `import:py` prefix** — older Jac docs and examples still show `import:py from os { path }`, but modern Jac uses plain `import from os { path }`. Using the deprecated form causes silent or confusing failures.
- **`can` vs `def`** — `can` is exclusively for data-spatial event-driven abilities (walker entry/exit). Using `can` for a regular method causes a compiler error: *"Expected 'with' after 'can' ability name"*. Switching everything to `def` and reserving `can` for walker abilities resolved this.

---

## 2. Data-Spatial Programming Mental Model

Jac's graph-based execution model (Object-Spatial Programming) is fundamentally different from REST or OOP patterns:

- **Nodes as persistent data** — `ProjectNode` and `TaskNode` are not just data structures; they live in a persistent graph rooted at `root`. Connecting them with `++>` edges is how relationships are modelled, not foreign keys.
- **Walkers as API endpoints** — each walker (e.g. `get_projects`, `create_task`) is spawned on `root` and traverses the graph to gather or mutate data. Thinking of walkers as "functions that walk a graph" rather than controllers took adjustment.
- **`report` instead of `return`** — walkers accumulate results via `report`, not `return`. Forgetting this means the API response is empty even when logic is correct.
- **Per-user graph isolation** — `jac-scale` automatically roots each authenticated user's graph separately. This means `root` is always the current user's root, which is powerful but required understanding that data created by one user is invisible to another without explicit design.

---

## 3. Frontend Client Code (`cl { }` blocks)

The `cl { }` block system compiles Jac to JavaScript/React, but has its own quirks:

- **CSS not loading** — the compiled client bundle (`main.js`) does not automatically include CSS. Inline styles via the `style` JSX attribute were needed as a workaround since the CSS import mechanism behaved differently than expected in the dev server setup.
- **`react-router-dom` circular JSON error** — using `Router` from `@jac/runtime` caused a *"Converting circular structure to JSON"* crash in the browser. This is a known issue with how the jac-client runtime serialises router context. The fix is to avoid passing Router objects through state or serialisation boundaries.
- **Lambda syntax for event handlers** — JSX event handlers must use Jac's lambda syntax: `onClick={lambda -> None { do_thing(); }}`. Python-style `lambda` with implicit returns does not work.
- **`useState` import** — React hooks like `useState` must be imported from `@jac/runtime`, not directly from `react`. The jac-client runtime re-exports them with the correct bridge.

---

## 4. Authentication Integration

`jac-scale` provides built-in auth (`jacLogin`, `jacSignup`, `jacLogout`, `jacIsLoggedIn`) via `@jac/runtime` on the client side:

- **Session persistence** — login state is managed by the runtime and persists across page reloads, but only within the same browser session. Understanding when `jacIsLoggedIn()` returns stale state required testing.
- **`def:priv` vs `def:pub`** — walkers marked `:priv` require authentication; `:pub` walkers are open. Getting this distinction right is critical for security. Accidentally marking data-mutation walkers as `:pub` would expose them without auth.
- **Default admin credentials warning** — on first start, `jac-scale` creates an admin user with default credentials and logs a warning. This is expected in dev but must be addressed before any production deployment.

---

## 5. Dev Server Behaviour

- **Port splitting** — `jac start --port 8003 --dev` runs the Vite frontend on 8003 and auto-assigns the API to 8004. This is not configurable without `--api_port`, which can cause confusion when firewall rules or proxies expect a single port.
- **HMR (Hot Module Replacement)** — file changes to `.jac` files trigger automatic recompilation and browser refresh. However, changes to the graph schema (node fields) sometimes require a full server restart and database reset to take effect.
- **`.jac/` cache directory** — the compiler caches compiled output and node_modules under `.jac/client/`. Stale cache caused mysterious runtime errors that only cleared after deleting this directory.

---

## 6. Tooling & Validation Workflow

- **`validate_jac` is mandatory** — Jac's type system is strict. The `validate_jac` MCP tool was essential for catching errors before running the server. A single syntax error in an `.impl.jac` file silently breaks the entire implementation file.
- **Error messages are cryptic** — compiler errors often point to the wrong line or give messages that refer to internal parser state rather than the user's mistake. Cross-referencing with `explain_error` helped decode them.
- **No incremental compilation** — every save triggers a full recompile of the module. For larger files this adds latency to the dev loop.

---

## Summary

| Area | Complexity Level | Key Issue |
|------|-----------------|-----------|
| Jac syntax vs Python habits | High | Semicolons, `self`, `can` vs `def` |
| Data-spatial / graph model | High | Walkers, `report`, per-user root |
| Client `cl {}` / CSS | Medium | CSS not auto-bundled, router circular ref |
| Auth integration | Medium | `:priv`/`:pub` distinction, session state |
| Dev server setup | Low-Medium | Port splitting, HMR cache issues |
| Compiler/tooling | Medium | Cryptic errors, full recompile on save |
