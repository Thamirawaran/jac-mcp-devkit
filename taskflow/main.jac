"""TaskFlow - A beautiful project management application."""

import from datetime { datetime }
import uuid;

# ============================================================
# Data Model
# ============================================================

node Project {
    has id: str;
    has name: str;
    has description: str = "";
    has color: str = "#6366f1";
    has created_at: str = "";
}

node Task {
    has id: str;
    has title: str;
    has priority: str = "medium";
    has status: str = "todo";
    has completed: bool = False;
    has created_at: str = "";
}

# ============================================================
# Backend Walkers
# ============================================================

walker:pub get_projects {
    can fetch with Root entry {
        projects = [-->][?:Project];
        report [
            {
                "id": p.id,
                "name": p.name,
                "description": p.description,
                "color": p.color,
                "created_at": p.created_at,
                "task_count": len([p -->][?:Task]),
                "completed_count": len([t for t in [p -->][?:Task] if t.completed])
            }
            for p in projects
        ];
    }
}

walker:pub add_project {
    has name: str;
    has description: str = "";
    has color: str = "#6366f1";

    can create with Root entry {
        p = Project(
            id=str(uuid.uuid4()),
            name=self.name,
            description=self.description,
            color=self.color,
            created_at=datetime.now().isoformat()
        );
        root ++> p;
        report {
            "id": p.id,
            "name": p.name,
            "description": p.description,
            "color": p.color,
            "created_at": p.created_at,
            "task_count": 0,
            "completed_count": 0
        };
    }
}

walker:pub delete_project {
    has project_id: str;

    can remove with Root entry {
        for p in [-->][?:Project] {
            if p.id == self.project_id {
                for t in [p -->][?:Task] {
                    del t;
                }
                del p;
                report {"success": True};
                return;
            }
        }
        report {"success": False};
    }
}

walker:pub get_tasks {
    has project_id: str;

    can fetch with Root entry {
        for p in [-->][?:Project] {
            if p.id == self.project_id {
                tasks = [p -->][?:Task];
                report [
                    {
                        "id": t.id,
                        "title": t.title,
                        "priority": t.priority,
                        "status": t.status,
                        "completed": t.completed,
                        "created_at": t.created_at
                    }
                    for t in tasks
                ];
                return;
            }
        }
        report [];
    }
}

walker:pub add_task {
    has project_id: str;
    has title: str;
    has priority: str = "medium";

    can create with Root entry {
        for p in [-->][?:Project] {
            if p.id == self.project_id {
                t = Task(
                    id=str(uuid.uuid4()),
                    title=self.title,
                    priority=self.priority,
                    status="todo",
                    completed=False,
                    created_at=datetime.now().isoformat()
                );
                p ++> t;
                report {
                    "id": t.id,
                    "title": t.title,
                    "priority": t.priority,
                    "status": t.status,
                    "completed": t.completed,
                    "created_at": t.created_at
                };
                return;
            }
        }
        report {"error": "Project not found"};
    }
}

walker:pub toggle_task {
    has project_id: str;
    has task_id: str;

    can toggle with Root entry {
        for p in [-->][?:Project] {
            if p.id == self.project_id {
                for t in [p -->][?:Task] {
                    if t.id == self.task_id {
                        t.completed = not t.completed;
                        t.status = "done" if t.completed else "todo";
                        report {
                            "success": True,
                            "completed": t.completed,
                            "status": t.status
                        };
                        return;
                    }
                }
            }
        }
        report {"success": False};
    }
}

walker:pub delete_task {
    has project_id: str;
    has task_id: str;

    can remove with Root entry {
        for p in [-->][?:Project] {
            if p.id == self.project_id {
                for t in [p -->][?:Task] {
                    if t.id == self.task_id {
                        del t;
                        report {"success": True};
                        return;
                    }
                }
            }
        }
        report {"success": False};
    }
}

walker:pub update_task_status {
    has project_id: str;
    has task_id: str;
    has status: str;

    can update with Root entry {
        for p in [-->][?:Project] {
            if p.id == self.project_id {
                for t in [p -->][?:Task] {
                    if t.id == self.task_id {
                        t.status = self.status;
                        t.completed = (self.status == "done");
                        report {
                            "success": True,
                            "status": t.status,
                            "completed": t.completed
                        };
                        return;
                    }
                }
            }
        }
        report {"success": False};
    }
}

# ============================================================
# Frontend
# ============================================================

cl {
    import "./styles/main.css";

    def:pub app() -> JsxElement {
        # ── State ──
        has projects: list = [];
        has selected_project_id: str = "";
        has tasks: list = [];
        has loading: bool = True;
        has task_loading: bool = False;

        has show_add_project: bool = False;
        has new_project_name: str = "";
        has new_project_color: str = "#6366f1";

        has show_add_task: bool = False;
        has new_task_title: str = "";
        has new_task_priority: str = "medium";

        has active_filter: str = "all";

        # ── Load projects on mount ──
        async can with entry {
            result = root spawn get_projects();
            if result.reports and result.reports.length > 0 {
                projects = result.reports[0];
            }
            loading = False;
        }

        # ── Actions ──
        async def select_project(proj_id: str) -> None {
            selected_project_id = proj_id;
            task_loading = True;
            active_filter = "all";
            show_add_task = False;
            result = root spawn get_tasks(project_id=proj_id);
            if result.reports and result.reports.length > 0 {
                tasks = result.reports[0];
            } else {
                tasks = [];
            }
            task_loading = False;
        }

        async def handle_add_project() -> None {
            if new_project_name.trim() {
                result = root spawn add_project(
                    name=new_project_name.trim(),
                    color=new_project_color
                );
                if result.reports and result.reports.length > 0 {
                    projects = projects + [result.reports[0]];
                }
                new_project_name = "";
                new_project_color = "#6366f1";
                show_add_project = False;
            }
        }

        async def handle_delete_project(proj_id: str) -> None {
            result = root spawn delete_project(project_id=proj_id);
            if result.reports and result.reports[0]["success"] {
                projects = [p for p in projects if p["id"] != proj_id];
                if selected_project_id == proj_id {
                    selected_project_id = "";
                    tasks = [];
                }
            }
        }

        async def handle_add_task() -> None {
            if new_task_title.trim() and selected_project_id {
                result = root spawn add_task(
                    project_id=selected_project_id,
                    title=new_task_title.trim(),
                    priority=new_task_priority
                );
                if result.reports and result.reports.length > 0 {
                    tasks = tasks + [result.reports[0]];
                    projects = [
                        {**p, "task_count": p["task_count"] + 1}
                        if p["id"] == selected_project_id else p
                        for p in projects
                    ];
                }
                new_task_title = "";
                new_task_priority = "medium";
                show_add_task = False;
            }
        }

        async def handle_toggle(task_id: str) -> None {
            result = root spawn toggle_task(
                project_id=selected_project_id,
                task_id=task_id
            );
            if result.reports and result.reports[0]["success"] {
                completed_val = result.reports[0]["completed"];
                new_status = result.reports[0]["status"];
                tasks = [
                    {**t, "completed": completed_val, "status": new_status}
                    if t["id"] == task_id else t
                    for t in tasks
                ];
                delta = 1 if completed_val else -1;
                projects = [
                    {**p, "completed_count": p["completed_count"] + delta}
                    if p["id"] == selected_project_id else p
                    for p in projects
                ];
            }
        }

        async def handle_delete_task(task_id: str) -> None {
            was_completed = False;
            for t in tasks {
                if t["id"] == task_id {
                    was_completed = t["completed"];
                }
            }
            result = root spawn delete_task(
                project_id=selected_project_id,
                task_id=task_id
            );
            if result.reports and result.reports[0]["success"] {
                tasks = [t for t in tasks if t["id"] != task_id];
                projects = [
                    {**p,
                     "task_count": p["task_count"] - 1,
                     "completed_count": p["completed_count"] - (1 if was_completed else 0)}
                    if p["id"] == selected_project_id else p
                    for p in projects
                ];
            }
        }

        async def handle_status_change(task_id: str, new_status: str) -> None {
            result = root spawn update_task_status(
                project_id=selected_project_id,
                task_id=task_id,
                status=new_status
            );
            if result.reports and result.reports[0]["success"] {
                old_completed = False;
                for t in tasks {
                    if t["id"] == task_id {
                        old_completed = t["completed"];
                    }
                }
                new_completed = result.reports[0]["completed"];
                tasks = [
                    {**t, "status": result.reports[0]["status"], "completed": new_completed}
                    if t["id"] == task_id else t
                    for t in tasks
                ];
                if old_completed != new_completed {
                    delta = 1 if new_completed else -1;
                    projects = [
                        {**p, "completed_count": p["completed_count"] + delta}
                        if p["id"] == selected_project_id else p
                        for p in projects
                    ];
                }
            }
        }

        # ── Computed ──
        matching = [p for p in projects if p["id"] == selected_project_id];
        selected_project = matching[0] if len(matching) > 0 else None;

        filtered_tasks = tasks;
        if active_filter != "all" {
            filtered_tasks = [t for t in tasks if t["status"] == active_filter];
        }

        todo_count = len([t for t in tasks if t["status"] == "todo"]);
        progress_count = len([t for t in tasks if t["status"] == "in_progress"]);
        done_count = len([t for t in tasks if t["status"] == "done"]);

        progress_pct = 0;
        if selected_project and selected_project["task_count"] > 0 {
            progress_pct = selected_project["completed_count"] * 100 / selected_project["task_count"];
        }

        colors = ["#6366f1", "#ec4899", "#f59e0b", "#22c55e", "#3b82f6", "#8b5cf6", "#ef4444", "#14b8a6"];

        # ── Render ──
        return <div className="app">
            <aside className="sidebar">
                <div className="sidebar-header">
                    <div className="logo">
                        <span className="logo-icon">T</span>
                        <span className="logo-text">TaskFlow</span>
                    </div>
                    <button
                        className="btn-add"
                        onClick={lambda -> None { show_add_project = not show_add_project; }}
                        title="New Project"
                    >
                        <span className="plus-icon">{(show_add_project and "\u00d7" or "+")}</span>
                    </button>
                </div>

                {show_add_project and (
                    <div className="add-form sidebar-form">
                        <input
                            className="input-dark"
                            value={new_project_name}
                            onChange={lambda e: any -> None { new_project_name = e.target.value; }}
                            onKeyDown={lambda e: any -> None {
                                if e.key == "Enter" { handle_add_project(); }
                                if e.key == "Escape" { show_add_project = False; }
                            }}
                            placeholder="Project name..."
                            autoFocus={True}
                        />
                        <div className="color-swatches">
                            {[
                                <button
                                    key={c}
                                    className={"swatch" + (" selected" if c == new_project_color else "")}
                                    style={{"backgroundColor": c}}
                                    onClick={lambda -> None { new_project_color = c; }}
                                />
                                for c in colors
                            ]}
                        </div>
                        <div className="form-buttons">
                            <button
                                className="btn-create"
                                onClick={lambda -> None { handle_add_project(); }}
                            >Create Project</button>
                            <button
                                className="btn-cancel-dark"
                                onClick={lambda -> None { show_add_project = False; }}
                            >Cancel</button>
                        </div>
                    </div>
                )}

                <div className="sidebar-label">PROJECTS</div>

                <div className="project-list">
                    {loading and <div className="sidebar-loading">Loading...</div>}

                    {not loading and len(projects) == 0 and (
                        <div className="sidebar-empty">
                            <p>No projects yet</p>
                            <p className="hint">Click + to create one</p>
                        </div>
                    )}

                    {[
                        <div
                            key={proj["id"]}
                            className={"project-item" + (" active" if proj["id"] == selected_project_id else "")}
                            onClick={lambda -> None { select_project(proj["id"]); }}
                        >
                            <span
                                className="project-dot"
                                style={{"backgroundColor": proj["color"]}}
                            ></span>
                            <div className="project-meta">
                                <span className="project-name">{proj["name"]}</span>
                                <span className="project-stats">
                                    {proj["completed_count"]}/{proj["task_count"]}
                                </span>
                            </div>
                            <button
                                className="btn-x"
                                onClick={lambda e: any -> None {
                                    e.stopPropagation();
                                    handle_delete_project(proj["id"]);
                                }}
                            >{"\u00d7"}</button>
                        </div>
                        for proj in projects
                    ]}
                </div>
            </aside>

            <main className="main">
                {not selected_project and (
                    <div className="welcome">
                        <div className="welcome-card">
                            <div className="welcome-icon">
                                <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                                    <path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2" />
                                    <rect x="9" y="3" width="6" height="4" rx="1" />
                                    <path d="M9 14l2 2 4-4" />
                                </svg>
                            </div>
                            <h2>Welcome to TaskFlow</h2>
                            <p>Select a project from the sidebar or create a new one to start managing your tasks.</p>
                        </div>
                    </div>
                )}

                {selected_project and (
                    <div className="content">
                        <div className="content-header">
                            <div className="header-left">
                                <div className="header-title-row">
                                    <span
                                        className="header-dot"
                                        style={{"backgroundColor": selected_project["color"]}}
                                    ></span>
                                    <h2 className="header-title">{selected_project["name"]}</h2>
                                </div>
                                <div className="progress-row">
                                    <div className="progress-bar">
                                        <div
                                            className="progress-fill"
                                            style={{
                                                "width": f"{progress_pct}%",
                                                "backgroundColor": selected_project["color"]
                                            }}
                                        ></div>
                                    </div>
                                    <span className="progress-label">
                                        {selected_project["completed_count"]}/{selected_project["task_count"]} done
                                    </span>
                                </div>
                            </div>
                            <button
                                className="btn-primary"
                                onClick={lambda -> None { show_add_task = not show_add_task; }}
                            >
                                + New Task
                            </button>
                        </div>

                        <div className="filters">
                            <button
                                className={"filter-pill" + (" active" if active_filter == "all" else "")}
                                onClick={lambda -> None { active_filter = "all"; }}
                            >All ({len(tasks)})</button>
                            <button
                                className={"filter-pill todo" + (" active" if active_filter == "todo" else "")}
                                onClick={lambda -> None { active_filter = "todo"; }}
                            >To Do ({todo_count})</button>
                            <button
                                className={"filter-pill in-progress" + (" active" if active_filter == "in_progress" else "")}
                                onClick={lambda -> None { active_filter = "in_progress"; }}
                            >In Progress ({progress_count})</button>
                            <button
                                className={"filter-pill done" + (" active" if active_filter == "done" else "")}
                                onClick={lambda -> None { active_filter = "done"; }}
                            >Done ({done_count})</button>
                        </div>

                        {show_add_task and (
                            <div className="add-form task-form">
                                <div className="task-form-row">
                                    <input
                                        className="input"
                                        value={new_task_title}
                                        onChange={lambda e: any -> None { new_task_title = e.target.value; }}
                                        onKeyDown={lambda e: any -> None {
                                            if e.key == "Enter" { handle_add_task(); }
                                            if e.key == "Escape" { show_add_task = False; }
                                        }}
                                        placeholder="What needs to be done?"
                                        autoFocus={True}
                                    />
                                </div>
                                <div className="task-form-options">
                                    <div className="priority-group">
                                        <span className="option-label">Priority:</span>
                                        <button
                                            className={"priority-btn low" + (" active" if new_task_priority == "low" else "")}
                                            onClick={lambda -> None { new_task_priority = "low"; }}
                                        >Low</button>
                                        <button
                                            className={"priority-btn medium" + (" active" if new_task_priority == "medium" else "")}
                                            onClick={lambda -> None { new_task_priority = "medium"; }}
                                        >Medium</button>
                                        <button
                                            className={"priority-btn high" + (" active" if new_task_priority == "high" else "")}
                                            onClick={lambda -> None { new_task_priority = "high"; }}
                                        >High</button>
                                    </div>
                                    <div className="form-buttons">
                                        <button
                                            className="btn-primary"
                                            onClick={lambda -> None { handle_add_task(); }}
                                        >Add Task</button>
                                        <button
                                            className="btn-ghost"
                                            onClick={lambda -> None { show_add_task = False; }}
                                        >Cancel</button>
                                    </div>
                                </div>
                            </div>
                        )}

                        <div className="task-list">
                            {task_loading and (
                                <div className="loading-state">
                                    <div className="spinner"></div>
                                    <p>Loading tasks...</p>
                                </div>
                            )}

                            {not task_loading and len(filtered_tasks) == 0 and (
                                <div className="empty-state">
                                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="empty-icon">
                                        <circle cx="12" cy="12" r="10" />
                                        <path d="M8 12h8M12 8v8" />
                                    </svg>
                                    <p>{("No tasks yet. Click '+ New Task' to add one." if active_filter == "all" else "No tasks match this filter.")}</p>
                                </div>
                            )}

                            {[
                                <div
                                    key={task["id"]}
                                    className={"task-card" + (" completed" if task["completed"] else "")}
                                >
                                    <div className="task-left">
                                        <button
                                            className={"checkbox" + (" checked" if task["completed"] else "")}
                                            onClick={lambda -> None { handle_toggle(task["id"]); }}
                                            style={task["completed"] and {"borderColor": selected_project["color"], "backgroundColor": selected_project["color"]} or {}}
                                        >
                                            {task["completed"] and (
                                                <svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke="white" strokeWidth="2">
                                                    <path d="M2 6l3 3 5-5" />
                                                </svg>
                                            )}
                                        </button>
                                        <span className={"task-title" + (" done" if task["completed"] else "")}>
                                            {task["title"]}
                                        </span>
                                    </div>
                                    <div className="task-right">
                                        <span className={"badge priority-" + task["priority"]}>
                                            {task["priority"]}
                                        </span>
                                        <select
                                            className={"status-select status-" + task["status"]}
                                            value={task["status"]}
                                            onChange={lambda e: any -> None {
                                                handle_status_change(task["id"], e.target.value);
                                            }}
                                        >
                                            <option value="todo">To Do</option>
                                            <option value="in_progress">In Progress</option>
                                            <option value="done">Done</option>
                                        </select>
                                        <button
                                            className="btn-delete"
                                            onClick={lambda -> None { handle_delete_task(task["id"]); }}
                                            title="Delete task"
                                        >
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                                <path d="M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m3 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6h14" />
                                            </svg>
                                        </button>
                                    </div>
                                </div>
                                for task in filtered_tasks
                            ]}
                        </div>
                    </div>
                )}
            </main>
        </div>;
    }
}
