# Dev Notes — Jac Full-Stack Calculator

Lessons learned building a full-stack calculator in Jac (backend walkers + `cl {}` React frontend).
These are real bugs hit during development, not hypothetical ones.

---

## 1. `round()` with two args — type overload error

**Symptom:** `round(float(val), 10)` caused a type-checker error about unresolved overloads.

**Fix:** Avoid `round()` entirely. Use string manipulation instead:
```jac
raw: str = str(val);
if "." in raw {
    parts = raw.split(".");
    decimal = parts[1].rstrip("0");
    raw = parts[0] if decimal == "" else parts[0] + "." + decimal;
}
```

---

## 2. `datetime.now().strftime` — cannot access attribute

**Symptom:** `datetime.now().strftime(...)` raised "Cannot access attribute strftime for type Self".

**Fix:** Import `strftime` directly from the `time` module at the top of the file. No semicolon on module-level imports:
```jac
import from time { strftime }

# later inside walker:
ts: str = strftime("%H:%M:%S");
```

> **Rule:** Module-level `import from` statements do NOT end with a semicolon. Statement-level ones do.

---

## 3. Walker `.reports` — type checker rejection

**Symptom:** Accessing `result.reports` on a spawned walker caused type errors because the static type system doesn't know `.reports` exists on walker types.

**Fix:** Type the spawn result as `object` and use `getattr`:
```jac
res: object = root spawn my_walker();
rpts: list = getattr(res, "reports", []);
if rpts {
    data: object = rpts[0];
}
```

> **Rule:** Never access `.reports` directly on a spawned walker result. Always use `getattr`.

---

## 4. `any` as a parameter type — resolves to Python builtin

**Symptom:** `has action: any` caused an error because `any` in Jac resolves to Python's `any()` builtin function, not a type annotation.

**Fix:** Use `object` instead:
```jac
has on_click: object;
```

---

## 5. Helper `def` inside `app()` returning JSX — blank buttons, broken clicks

**Symptom:** Defining a helper function inside `app()` to return a `<button>` JSX element caused buttons to render with no labels and `onClick` handlers that never fired.

**Fix:** Do not use nested JSX-returning helpers inside `cl {}` component functions. Inline all JSX directly. Pre-define style dicts as local variables instead:
```jac
nb: dict = {"width": "70px", "height": "70px", ...};

# Then inline in JSX:
<button style={nb} onClick={lambda -> None { ... }}>7</button>
```

---

## 6. Missing npm packages — Vite build errors on startup

**Symptom:** `jac start` failed with Vite import errors for `react-hook-form`, `@hookform/resolvers`, `zod`, `react-error-boundary`, `react-router-dom`.

**Fix:** Install them manually inside the generated client directory:
```bash
cd .jac/client
bun add react-hook-form @hookform/resolvers zod react-error-boundary react-router-dom
```

---

## 7. `sv import` in same-file `cl {}` — duplicate class declaration, build failure

**Symptom:** Using `sv import from .main { calculate, get_history, clear_history }` inside a `cl {}` block in the same file caused a Rollup build error: `Identifier "calculate" has already been declared`.

**Root cause:** The compiler emits both `import { calculate } from "./main.js"` AND `class calculate {}` in the compiled JS output — one for the `sv import`, one for the walker definition — causing a name collision.

**Fix:** Remove `sv import` entirely when the walkers are defined in the same `.jac` file. They are already in scope inside `cl {}`:
```jac
cl {
    # No sv import needed — walkers from this file are already available
    def:pub app() -> JsxElement { ... }
}
```

> **Rule:** Only use `sv import` when importing walkers from a *different* file.

---

## 8. `root()` in `cl {}` — "root is not a function" runtime error

**Symptom:** Using `root()` (with parentheses) inside a `cl {}` block compiled to `root()` in JS, but `root` is not exported as a callable from `@jac/runtime`. The app crashed on load with `TypeError: root is not a function`.

**Fix:** Use bare `root` (no parentheses) inside `cl {}` blocks:
```jac
# WRONG — crashes at runtime
res: object = root() spawn get_history();

# CORRECT
res: object = root spawn get_history();
```

> **Rule:** `root()` with parentheses is for server-side walker code (Python). Inside `cl {}` client code, always use bare `root`.

---

## 9. `dict(rpts[0])` → `Object.fromEntries()` — silent data loss

**Symptom:** After pressing `=`, the display showed the expression instead of the result (e.g. `3+3` instead of `6`). The API was returning 200 with correct data.

**Root cause:** `dict(rpts[0])` in `cl {}` compiled to JS `Object.fromEntries(rpts[0])`. `Object.fromEntries` expects an array of `[key, value]` pairs, but `rpts[0]` is already a plain JS object. It returned an empty object, so `data["success"]` was always `undefined` (falsy) and the display never updated.

**Fix:** Do not cast to `dict` in client code. Type as `object` and access directly:
```jac
# WRONG
data: dict = dict(rpts[0]);

# CORRECT
data: object = rpts[0];
if data["success"] { ... }
```

> **Rule:** Avoid `dict()`, `list()`, `str()` casts on data returned from `__jacSpawn` in client code. The runtime already gives you plain JS objects/arrays — casting them with Python builtins produces wrong JS.

---

## 10. `list(rpts[0])` → `Array.from()` — wrong history type

**Symptom:** Same category as #9. `list(rpts[0])` compiled to `Array.from(rpts[0])` on a plain JS array, which worked in some cases but caused type issues when the field was typed as `list`.

**Fix:** Type the history state as `object` instead of `list`, assign the raw value directly, and cast with `list()` only at the render call site where the compiler handles `Array.from` correctly:
```jac
has history: object = [];

# On assignment — no cast
history = rpts[0];

# In JSX — cast here is fine, compiler emits Array.from correctly
{(len(list(history)) > 0 and ...)}
```

---

## Summary — Key Rules for `cl {}` Blocks

| Do | Don't |
|----|-------|
| `root spawn walker()` | `root() spawn walker()` |
| `data: object = rpts[0]` | `data: dict = dict(rpts[0])` |
| `history: object = []` then `list(history)` at render | `history: list = list(rpts[0])` |
| Inline all JSX directly | Define nested `def` helpers that return JSX |
| `sv import` only for walkers in other files | `sv import` for walkers in the same file |
| `getattr(res, "reports", [])` | `res.reports` directly |
| `import from time { strftime }` (no semicolon) | `import from time { strftime };` |
