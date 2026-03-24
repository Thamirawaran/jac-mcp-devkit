# TaskFlow — Development Notes

Challenges and non-obvious decisions encountered while building this app with Jac fullstack.

---

## 1. `root` vs `root()` syntax

Early test code used bare `root` as a node reference, which caused compilation errors. Newer Jac requires `root()` in some contexts. This was subtle because the error message didn't point directly at `root` — it surfaced as a generic parse failure.

---

## 2. Walker result access pattern

The walker API returns `result.reports` as a list where each `report` call adds one entry. So if a walker calls `report [list_of_items]` once, the result is `result.reports[0]` — not `result.reports`. Getting this wrong means silently receiving `undefined` in the UI with no error.

---

## 3. State updates with spread syntax

Updating a specific field on an item inside a list required creating a new list with new dicts:

```jac
tasks = [
    {**t, "completed": True} if t["id"] == task_id else t
    for t in tasks
];
```

Mutating `t` in-place did not trigger a re-render because Jac reactive state (`has`) tracks by reference, not by deep equality.

---

## 4. Closures in list comprehension event handlers

Lambdas inside a list comprehension need to capture the loop variable correctly:

```jac
{[
    <button onClick={lambda -> None { remove_task(task["id"]); }}>
    for task in tasks
]}
```

This works because the Jac compiler compiles list comprehensions to `.map()` in JavaScript, which creates a proper closure per iteration. A naive Python-style mental model would suggest all lambdas capture the last value — they don't here.

---

## 5. `jac start` requires `cwd` to be the project directory

Running `jac start main.jac` from the MCP server's working directory fails with "No jac.toml found". The server must be started from the directory that contains `jac.toml`. This was the root cause of `start_server` failing in the MCP tool until we fixed it to set `cwd=project_dir`.

---

## 6. `jac_to_js` only works on `.cl.jac` files

The JS transpiler only activates when the temp file has a `.cl.jac` suffix. Using `.jac` produces empty output with no error. This affected the MCP `jac_to_js` tool and was fixed by changing the temp file suffix.

---

## 7. Progress bar percentage in JSX

Computing a percentage for the progress bar inside JSX required extracting it as a variable first. Trying to write the full expression inline inside the `style` prop made the JSX unreadable and error-prone:

```jac
progress = 0;
if selected_project and selected_project["task_count"] > 0 {
    progress = selected_project["completed_count"] * 100 / selected_project["task_count"];
}
# then use {progress} in JSX
```

---

## 8. Port conflicts on restart

`jac start` does not always bind exclusively to the requested port. When a previous server process was still in the kernel's TIME_WAIT state, the next start silently incremented to the next available port (8002 → 8003). The fix was to explicitly kill all processes on the port before restarting.

---

## 9. `graph_visualize` MCP tool always returned empty

The `graph_viz_snippet` implementation used `printgraph(nd=None)` from the Jac Python API, which tried to resolve a root node anchor by UUID from a stale runtime context. The fix was to switch to subprocess `jac dot`, which writes a clean `.dot` file from a fully isolated run.

---

## 10. Filtering tasks without `filter` keyword collision

`filter` is a Python/Jac built-in. Using it as a state variable name (`has filter: str = "all"`) caused a backtick-escaping issue. Renamed to `active_filter` to avoid the conflict.
