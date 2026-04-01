# Dev Notes — LinkedIn Clone in Jac

Issues encountered and how they were resolved while building a full-stack LinkedIn clone using Jac (backend + frontend in a single `.jac` file).

---

## 1. `sv import from typing { Any }` — emits `async function Any()` in JS

**Problem:** Using `sv import from typing { Any }` makes `Any` available to the type checker, but the Jac compiler still emits `async function Any() { return await __jacCallFunction("Any", {}); }` in the compiled JS bundle. This causes a name collision and incorrect runtime behavior.

**Fix:** Use a plain top-level `import from typing { Any }` instead. The type checker accepts it and it still avoids the `cl import` path that bundles it as a JS import.

```jac
import from typing { Any }  # top-level, not sv or cl qualified
```

---

## 2. `getattr(result, "reports", []) and len(getattr(...)) > 0` — Rollup parse error

**Problem:** `getattr(result, "reports", [])` compiles to `result["reports"] ?? []` in JS. When used inline in a boolean condition like:
```js
if ((result["reports"] ?? [] && (result["reports"] ?? [].length > 0)))
```
Rollup throws: *"Nullish coalescing operator(??) requires parens when mixing with logical operators"* and refuses to build.

**Fix:** Always assign `getattr` to a local variable first before using it in conditions:

```jac
# WRONG
if getattr(result, "reports", []) and len(getattr(result, "reports", [])) > 0 {
    data = getattr(result, "reports", [])[0];
}

# RIGHT
rpts = getattr(result, "reports", []);
if rpts and len(rpts) > 0 {
    data = rpts[0];
}
```

---

## 3. `result.reports` — type checker rejection on walker spawn result

**Problem:** Spawning a walker returns a typed walker object. The Jac type system doesn't know `.reports` exists on it, causing a type error.

**Fix:** Use `getattr(result, "reports", [])` to bypass the type checker (and assign to a local var — see issue #2 above).

---

## 4. `any` as a parameter type — resolves to Python builtin `any()`

**Problem:** Using `any` as a type annotation in Jac resolves to Python's built-in `any()` function, not a generic type.

**Fix:** Use `Any` (capital A) from `typing`, or use `object` for parameters that don't need `.target` / `.preventDefault`.

---

## 5. NavBar with hooks called as a function — "Rendered fewer hooks than expected"

**Problem:** `NavBar` used `useNavigate()` internally and was called as a plain function inside JSX: `{NavBar("/feed")}`. This compiled to `NavBar("/feed")` — a regular function call — causing React to count the hooks inside NavBar as part of the parent component's hooks. On re-render, the hooks count changes and React throws: *"Rendered fewer hooks than expected"*.

**Fix:** Convert `NavBar` to a proper `def:pub` component with a `has` field for props, and call it as JSX:

```jac
# WRONG
def NavBar(currentPath: str) -> JsxElement { ... }
# called as:
{NavBar("/feed")}

# RIGHT
def:pub NavBar() -> JsxElement {
    has currentPath: str = "/feed";
    ...
}
# called as:
{<NavBar currentPath="/feed" />}
```

---

## 6. `profileData["name"][0].upper()` — `.upper()` not a JS function

**Problem:** Python string method `.upper()` does not exist in JavaScript. The Jac compiler emits it as-is (`.upper()`), causing a runtime error: *"profileData.name[0].upper is not a function"*.

**Fix:** Use a string slice instead, and rely on CSS `text-transform: uppercase` for visual uppercasing, or use `.slice(0, 1)` in the Jac source:

```jac
# WRONG
{profileData["name"][0].upper()}

# RIGHT — slice compiles to String(x).slice(0, 1) in JS
{str(profileData["name"])[0:1]}
```

The Jac runtime provides `.upper()` on bytes objects but NOT on plain strings. Avoid `.upper()`, `.lower()`, `.capitalize()`, `.title()` in `cl {}` blocks unless you verify runtime support.

---

## 7. `dict()` and `list()` on plain JS objects/arrays

**Problem:** In `cl {}` blocks, `dict(x)` compiles to `Object.fromEntries(x)` and `list(x)` compiles to `Array.from(x)`. These expect iterables of `[key, value]` pairs / iterables respectively, but walker reports return plain JS objects and arrays. Result: empty objects, broken data.

**Fix:** Assign raw values directly without conversion:

```jac
# WRONG
data: dict = dict(rpts[0])
items: list = list(rpts[0])

# RIGHT
data: object = rpts[0]
items: object = rpts[0]
```

---

## 8. `root()` in `cl {}` — "root is not a function" runtime error

**Problem:** Writing `root()` (with parentheses) in client blocks compiles to `root()` in JS, but `root` from `@jac/runtime` is not a callable function — it's exported as a string `""` representing the root node ID for `__jacSpawn`.

**Fix:** Use bare `root` (no parentheses) inside `cl {}` for walker spawning:

```jac
# WRONG
result = root() spawn get_feed();

# RIGHT
result = root spawn get_feed();
```

---

## 9. Router blank page — missing `basename`

**Problem:** The Jac dev server serves the client app at `/cl/app`, but `BrowserRouter` (aliased as `Router` from `@jac/runtime`) uses the full URL path. Routes defined as `/`, `/login`, `/feed` etc. don't match `/cl/app`, so nothing renders — blank white page.

**Fix:** Pass `basename="/cl/app"` to the Router:

```jac
def:pub app() -> JsxElement {
    return <Router basename="/cl/app">
        <Routes>
            <Route path="/" element={<LoginPage />} />
            ...
        </Routes>
    </Router>;
}
```

---

## 10. `sv import` in same-file `cl {}` — duplicate declarations (from prior Jac experience)

**Problem:** `sv import from .main { MyWalker }` in a file that also contains the `cl {}` block causes the compiler to emit both `import { MyWalker }` AND `class MyWalker {}` in the same JS file → Rollup error: *"Identifier already declared"*.

**Fix:** Walkers defined in the same `.jac` file are already in scope inside `cl {}`. Remove the `sv import` entirely.

---

## 11. `datetime.datetime.now().strftime()` in `has` field defaults

**Problem:** Using complex expressions like `datetime.datetime.now().strftime(...)` as default values in `has` field declarations is not supported by the type checker.

**Fix:** Use empty string `""` as the default and set the timestamp inside the walker body:

```jac
# WRONG
node Post {
    has created_at: str = str(datetime.datetime.now());
}

# RIGHT
node Post {
    has created_at: str = "";
}
# then in walker:
new_post = Post(...);
new_post.created_at = str(datetime.datetime.now());
```

---

## 12. Computed dict key spread `{** d, post["id"]: val}` — invalid JS

**Problem:** `{** commentInputs, post["id"]: val}` compiles to `{...commentInputs, post["id"]: val}` in JS. Computed property keys in spread syntax require bracket notation: `{[post["id"]]: val}`, but the compiler doesn't wrap it, producing a syntax error.

**Fix:** Extract the key to a local `str` variable first:

```jac
def setCommentInput(post_id: str, val: str) -> None {
    merged: Any = {** commentInputs, post_id: val};
    commentInputs = merged;
}
```

This compiles to `{...commentInputs, post_id: val}` which is valid JS (using the variable name as key).

---

## Summary — Patterns to Avoid in `cl {}` Blocks

| Avoid | Use instead |
|-------|-------------|
| `result.reports` | `getattr(result, "reports", [])` assigned to a local var |
| `dict(x)`, `list(x)` on walker reports | `x` directly, typed as `object` |
| `root()` | `root` (no parens) |
| `str.upper()`, `str.lower()` | Avoid or use CSS; slice with `[0:1]` |
| `NavBar(arg)` with hooks inside | `def:pub NavBar()` with `has` props, call as `<NavBar prop=val />` |
| `sv import` of same-file symbols | Remove — same-file walkers are in scope automatically |
| Inline `getattr(...) and len(getattr(...)) > 0` | Assign to local var first |
| `{** d, computed_key: val}` | Extract key to a `str` variable |
