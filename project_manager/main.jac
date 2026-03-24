"""JacPM - Project Management Application."""

import from datetime { datetime }
import uuid;

# ============================================================
# BACKEND: Data Model (Nodes & Edges)
# ============================================================

enum Priority {
    LOW = "low",
    MEDIUM = "medium",
    HIGH = "high",
    URGENT = "urgent"
}

enum TaskStatus {
    TODO = "todo",
    IN_PROGRESS = "in_progress",
    IN_REVIEW = "in_review",
    DONE = "done"
}

node Project {
    has id: str,
        name: str,
        description: str = "",
        color: str = "#6366f1",
        created_at: str = "",
        archived: bool = False;
}

node Task {
    has id: str,
        title: str,
        description: str = "",
        status: str = "todo",
        priority: str = "medium",
        due_date: str = "",
        created_at: str = "",
        project_id: str = "",
        completed: bool = False;
}

edge HasTask {}
edge BelongsToProject {}

# ============================================================
# BACKEND: Walker APIs
# ============================================================

walker:pub create_project {
    has name: str;
    has description: str = "";
    has color: str = "#6366f1";

    can create with Root entry {
        proj = Project(
            id=str(uuid.uuid4()),
            name=self.name,
            description=self.description,
            color=self.color,
            created_at=str(datetime.now())
        );
        root() ++> proj;
        report {
            "id": proj.id,
            "name": proj.name,
            "description": proj.description,
            "color": proj.color,
            "created_at": proj.created_at,
            "archived": proj.archived,
            "task_count": 0,
            "done_count": 0
        };
    }
}

walker:pub get_projects {
    can fetch with Root entry {
        projects = [];
        for proj in [-->][?:Project] {
            if not proj.archived {
                tasks = [proj -->][?:Task];
                done_count = len([t for t in tasks if t.completed]);
                projects.append({
                    "id": proj.id,
                    "name": proj.name,
                    "description": proj.description,
                    "color": proj.color,
                    "created_at": proj.created_at,
                    "archived": proj.archived,
                    "task_count": len(tasks),
                    "done_count": done_count
                });
            }
        }
        report projects;
    }
}

walker:pub update_project {
    has project_id: str;
    has name: str = "";
    has description: str = "";
    has color: str = "";

    can update with Root entry {
        for proj in [-->][?:Project] {
            if proj.id == self.project_id {
                if self.name { proj.name = self.name; }
                if self.description { proj.description = self.description; }
                if self.color { proj.color = self.color; }
                report {"success": True, "id": proj.id};
                return;
            }
        }
        report {"success": False, "error": "Project not found"};
    }
}

walker:pub delete_project {
    has project_id: str;

    can remove with Root entry {
        for proj in [-->][?:Project] {
            if proj.id == self.project_id {
                for task in [proj -->][?:Task] {
                    del task;
                }
                del proj;
                report {"success": True};
                return;
            }
        }
        report {"success": False, "error": "Project not found"};
    }
}

walker:pub create_task {
    has title: str;
    has project_id: str;
    has description: str = "";
    has priority: str = "medium";
    has due_date: str = "";

    can create with Root entry {
        for proj in [-->][?:Project] {
            if proj.id == self.project_id {
                task = Task(
                    id=str(uuid.uuid4()),
                    title=self.title,
                    description=self.description,
                    status="todo",
                    priority=self.priority,
                    due_date=self.due_date,
                    created_at=str(datetime.now()),
                    project_id=self.project_id
                );
                proj ++> task;
                report {
                    "id": task.id,
                    "title": task.title,
                    "description": task.description,
                    "status": task.status,
                    "priority": task.priority,
                    "due_date": task.due_date,
                    "created_at": task.created_at,
                    "project_id": task.project_id,
                    "completed": task.completed
                };
                return;
            }
        }
        report {"error": "Project not found"};
    }
}

walker:pub get_tasks {
    has project_id: str = "";

    can fetch with Root entry {
        all_tasks: list = [];
        for proj in [-->][?:Project] {
            if self.project_id and proj.id != self.project_id {
                continue;
            }
            for task in [proj -->][?:Task] {
                all_tasks.append({
                    "id": task.id,
                    "title": task.title,
                    "description": task.description,
                    "status": task.status,
                    "priority": task.priority,
                    "due_date": task.due_date,
                    "created_at": task.created_at,
                    "project_id": task.project_id,
                    "completed": task.completed
                });
            }
        }
        report all_tasks;
    }
}

walker:pub update_task {
    has task_id: str;
    has title: str = "";
    has description: str = "";
    has status: str = "";
    has priority: str = "";
    has due_date: str = "";

    can update with Root entry {
        for proj in [-->][?:Project] {
            for task in [proj -->][?:Task] {
                if task.id == self.task_id {
                    if self.title { task.title = self.title; }
                    if self.description { task.description = self.description; }
                    if self.status {
                        task.status = self.status;
                        task.completed = (self.status == "done");
                    }
                    if self.priority { task.priority = self.priority; }
                    if self.due_date { task.due_date = self.due_date; }
                    report {
                        "success": True,
                        "id": task.id,
                        "title": task.title,
                        "status": task.status,
                        "priority": task.priority,
                        "completed": task.completed
                    };
                    return;
                }
            }
        }
        report {"success": False, "error": "Task not found"};
    }
}

walker:pub delete_task {
    has task_id: str;

    can remove with Root entry {
        for proj in [-->][?:Project] {
            for task in [proj -->][?:Task] {
                if task.id == self.task_id {
                    del task;
                    report {"success": True};
                    return;
                }
            }
        }
        report {"success": False, "error": "Task not found"};
    }
}

walker:pub get_dashboard_stats {
    can stats with Root entry {
        total_projects = 0;
        total_tasks = 0;
        done_tasks = 0;
        in_progress_tasks = 0;
        urgent_tasks = 0;
        overdue_tasks = 0;
        now_str = str(datetime.now());

        for proj in [-->][?:Project] {
            if not proj.archived {
                total_projects += 1;
                for task in [proj -->][?:Task] {
                    total_tasks += 1;
                    if task.completed { done_tasks += 1; }
                    if task.status == "in_progress" { in_progress_tasks += 1; }
                    if task.priority == "urgent" and not task.completed { urgent_tasks += 1; }
                    if task.due_date and task.due_date < now_str and not task.completed {
                        overdue_tasks += 1;
                    }
                }
            }
        }
        report {
            "total_projects": total_projects,
            "total_tasks": total_tasks,
            "done_tasks": done_tasks,
            "in_progress_tasks": in_progress_tasks,
            "urgent_tasks": urgent_tasks,
            "overdue_tasks": overdue_tasks,
            "completion_rate": (done_tasks * 100 // total_tasks) if total_tasks > 0 else 0
        };
    }
}

# ============================================================
# FRONTEND: UI Components (State-based navigation, no Router)
# ============================================================

cl import from "@jac/runtime" {
    jacLogin,
    jacSignup,
    jacLogout,
    jacIsLoggedIn
}

cl import "./styles.css";

cl {


    # ============================================================
    # STAT CARD COMPONENT
    # ============================================================

    def:pub StatCard(props: dict) -> JsxElement {
        return <div className="stat-card" style={{"borderTop": f"3px solid {props['color']}"}}>
            <div className="stat-icon" style={{"background": f"{props['color']}20", "color": props["color"]}}>
                {props["icon"]}
            </div>
            <div className="stat-info">
                <span className="stat-value">{props["value"]}</span>
                <span className="stat-label">{props["label"]}</span>
            </div>
        </div>;
    }

    # ============================================================
    # DASHBOARD PAGE
    # ============================================================

    def:pub DashboardPage(props: dict) -> JsxElement {
        has stats: dict = {};
        has projects: list = [];
        has recent_tasks: list = [];
        has loading: bool = True;

        async can with entry {
            result = root spawn get_dashboard_stats();
            if result.reports and result.reports.length > 0 {
                stats = result.reports[0];
            }
            proj_result = root spawn get_projects();
            if proj_result.reports and proj_result.reports.length > 0 {
                projects = proj_result.reports[0];
            }
            task_result = root spawn get_tasks();
            if task_result.reports and task_result.reports.length > 0 {
                all = task_result.reports[0];
                recent_tasks = all.slice(0, 5);
            }
            loading = False;
        }

        if loading {
            return <div className="page-loading">
                <div className="spinner"></div>
                <p>Loading dashboard...</p>
            </div>;
        }

        return <div className="page">
            <div className="page-header">
                <div>
                    <h1 className="page-title">Dashboard</h1>
                    <p className="page-subtitle">Overview of your projects and tasks</p>
                </div>
            </div>

            <div className="stats-grid">
                <StatCard
                    value={stats["total_projects"] or 0}
                    label="Projects"
                    color="#6366f1"
                    icon={<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"></path></svg>}
                />
                <StatCard
                    value={stats["total_tasks"] or 0}
                    label="Total Tasks"
                    color="#3b82f6"
                    icon={<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 11l3 3L22 4"></path><path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"></path></svg>}
                />
                <StatCard
                    value={stats["done_tasks"] or 0}
                    label="Completed"
                    color="#10b981"
                    icon={<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="20 6 9 17 4 12"></polyline></svg>}
                />
                <StatCard
                    value={stats["in_progress_tasks"] or 0}
                    label="In Progress"
                    color="#f59e0b"
                    icon={<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>}
                />
                <StatCard
                    value={stats["urgent_tasks"] or 0}
                    label="Urgent"
                    color="#ef4444"
                    icon={<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>}
                />
                <StatCard
                    value={f"{stats['completion_rate'] or 0}%"}
                    label="Completion Rate"
                    color="#8b5cf6"
                    icon={<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="14"></line></svg>}
                />
            </div>

            <div className="dashboard-grid">
                <div className="card">
                    <div className="card-header">
                        <h2>Projects</h2>
                        <button className="card-link" onClick={lambda -> None { props["navigate"]("projects"); }}>View All</button>
                    </div>
                    <div className="card-body">
                        {projects.length == 0 and (
                            <p className="empty-text">No projects yet. Create your first project!</p>
                        )}
                        {[
                            <div className="project-row" key={p["id"]}>
                                <div className="project-color" style={{"background": p["color"]}}></div>
                                <div className="project-info">
                                    <span className="project-name">{p["name"]}</span>
                                    <span className="project-meta">{p["task_count"]} tasks - {p["done_count"]} done</span>
                                </div>
                                <div className="progress-mini">
                                    <div
                                        className="progress-fill"
                                        style={{"width": f"{(p['done_count'] * 100 // p['task_count']) if p['task_count'] > 0 else 0}%"}}
                                    ></div>
                                </div>
                            </div>
                            for p in projects
                        ]}
                    </div>
                </div>

                <div className="card">
                    <div className="card-header">
                        <h2>Recent Tasks</h2>
                        <button className="card-link" onClick={lambda -> None { props["navigate"]("tasks"); }}>View All</button>
                    </div>
                    <div className="card-body">
                        {recent_tasks.length == 0 and (
                            <p className="empty-text">No tasks yet.</p>
                        )}
                        {[
                            <div className="task-row" key={t["id"]}>
                                <div className={"priority-dot priority-" + t["priority"]}></div>
                                <span className={"task-title" + (" completed" if t["completed"] else "")}>{t["title"]}</span>
                                <span className={"status-badge status-" + t["status"]}>{t["status"].replace("_", " ")}</span>
                            </div>
                            for t in recent_tasks
                        ]}
                    </div>
                </div>
            </div>
        </div>;
    }

    # ============================================================
    # PROJECTS PAGE
    # ============================================================

    def:pub ProjectsPage(props: dict) -> JsxElement {
        has projects: list = [];
        has loading: bool = True;
        has show_form: bool = False;
        has new_name: str = "";
        has new_desc: str = "";
        has new_color: str = "#6366f1";
        has colors: list = ["#6366f1", "#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#8b5cf6", "#ec4899", "#14b8a6"];

        async can with entry {
            await load_projects();
        }

        async def load_projects() -> None {
            loading = True;
            result = root spawn get_projects();
            if result.reports and result.reports.length > 0 {
                projects = result.reports[0];
            }
            loading = False;
        }

        async def handle_create() -> None {
            if new_name.trim() {
                result = root spawn create_project(
                    name=new_name.trim(),
                    description=new_desc.trim(),
                    color=new_color
                );
                if result.reports and result.reports.length > 0 {
                    projects = projects.concat([result.reports[0]]);
                    new_name = "";
                    new_desc = "";
                    new_color = "#6366f1";
                    show_form = False;
                }
            }
        }

        async def handle_delete(pid: str) -> None {
            result = root spawn delete_project(project_id=pid);
            if result.reports and result.reports[0]["success"] {
                projects = projects.filter(lambda p: any -> bool { return p["id"] != pid; });
            }
        }

        if loading {
            return <div className="page-loading">
                <div className="spinner"></div>
                <p>Loading projects...</p>
            </div>;
        }

        return <div className="page">
            <div className="page-header">
                <div>
                    <h1 className="page-title">Projects</h1>
                    <p className="page-subtitle">Manage your project portfolio</p>
                </div>
                <button className="btn btn-primary" onClick={lambda -> None { show_form = not show_form; }}>
                    {show_form and "Cancel" or "+ New Project"}
                </button>
            </div>

            {show_form and (
                <div className="card form-card">
                    <h3>Create New Project</h3>
                    <div className="form-group">
                        <label>Project Name</label>
                        <input
                            className="form-input"
                            value={new_name}
                            onChange={lambda e: any -> None { new_name = e.target.value; }}
                            placeholder="Enter project name..."
                        />
                    </div>
                    <div className="form-group">
                        <label>Description</label>
                        <textarea
                            className="form-input form-textarea"
                            value={new_desc}
                            onChange={lambda e: any -> None { new_desc = e.target.value; }}
                            placeholder="Brief description..."
                        ></textarea>
                    </div>
                    <div className="form-group">
                        <label>Color</label>
                        <div className="color-picker">
                            {[
                                <button
                                    key={c}
                                    className={"color-swatch" + (" selected" if c == new_color else "")}
                                    style={{"background": c}}
                                    onClick={lambda -> None { new_color = c; }}
                                    type="button"
                                ></button>
                                for c in colors
                            ]}
                        </div>
                    </div>
                    <button className="btn btn-primary" onClick={lambda -> None { handle_create(); }}>
                        Create Project
                    </button>
                </div>
            )}

            <div className="projects-grid">
                {projects.length == 0 and not show_form and (
                    <div className="empty-state">
                        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="#475569" strokeWidth="1.5"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"></path></svg>
                        <h3>No projects yet</h3>
                        <p>Create your first project to get started</p>
                        <button className="btn btn-primary" onClick={lambda -> None { show_form = True; }}>
                            + Create Project
                        </button>
                    </div>
                )}
                {[
                    <div className="project-card" key={p["id"]} style={{"borderTop": f"4px solid {p['color']}"}}>
                        <div className="project-card-header">
                            <h3>{p["name"]}</h3>
                            <button
                                className="icon-btn danger"
                                onClick={lambda -> None { handle_delete(p["id"]); }}
                                title="Delete project"
                            >
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"></path></svg>
                            </button>
                        </div>
                        <p className="project-card-desc">{p["description"] or "No description"}</p>
                        <div className="project-card-stats">
                            <span>{p["task_count"]} tasks</span>
                            <span className="dot"></span>
                            <span>{p["done_count"]} done</span>
                        </div>
                        <div className="progress-bar">
                            <div
                                className="progress-fill"
                                style={{"width": f"{(p['done_count'] * 100 // p['task_count']) if p['task_count'] > 0 else 0}%"}}
                            ></div>
                        </div>
                        <button className="btn btn-outline btn-sm" onClick={lambda -> None { props["navigateWithProject"](p["id"]); }}>
                            View Tasks
                        </button>
                    </div>
                    for p in projects
                ]}
            </div>
        </div>;
    }

    # ============================================================
    # TASKS PAGE
    # ============================================================

    def:pub TasksPage(props: dict) -> JsxElement {
        has tasks: list = [];
        has projects: list = [];
        has loading: bool = True;
        has show_form: bool = False;
        has filter_status: str = "all";
        has filter_priority: str = "all";
        has new_title: str = "";
        has new_desc: str = "";
        has new_priority: str = "medium";
        has new_project: str = "";
        has new_due: str = "";

        async can with entry {
            proj_result = root spawn get_projects();
            if proj_result.reports and proj_result.reports.length > 0 {
                projects = proj_result.reports[0];
            }

            project_filter = props["projectFilter"] or "";
            if project_filter {
                new_project = project_filter;
            }

            task_result = root spawn get_tasks(project_id=project_filter);
            if task_result.reports and task_result.reports.length > 0 {
                tasks = task_result.reports[0];
            }
            loading = False;
        }

        async def handle_create() -> None {
            if new_title.trim() and new_project {
                result = root spawn create_task(
                    title=new_title.trim(),
                    project_id=new_project,
                    description=new_desc.trim(),
                    priority=new_priority,
                    due_date=new_due
                );
                if result.reports and result.reports.length > 0 {
                    resp = result.reports[0];
                    if not resp["error"] {
                        tasks = tasks.concat([resp]);
                        new_title = "";
                        new_desc = "";
                        new_priority = "medium";
                        new_due = "";
                        show_form = False;
                    }
                }
            }
        }

        async def handle_status_change(task_id: str, new_status: str) -> None {
            result = root spawn update_task(task_id=task_id, status=new_status);
            if result.reports and result.reports[0]["success"] {
                tasks = tasks.map(lambda t: any -> any {
                    if t["id"] == task_id {
                        return {**t, "status": new_status, "completed": new_status == "done"};
                    }
                    return t;
                });
            }
        }

        async def handle_delete_task(task_id: str) -> None {
            result = root spawn delete_task(task_id=task_id);
            if result.reports and result.reports[0]["success"] {
                tasks = tasks.filter(lambda t: any -> bool { return t["id"] != task_id; });
            }
        }

        def get_filtered_tasks() -> list {
            filtered = tasks;
            if filter_status != "all" {
                filtered = filtered.filter(lambda t: any -> bool { return t["status"] == filter_status; });
            }
            if filter_priority != "all" {
                filtered = filtered.filter(lambda t: any -> bool { return t["priority"] == filter_priority; });
            }
            return filtered;
        }

        def get_project_name(pid: str) -> str {
            for p in projects {
                if p["id"] == pid {
                    return p["name"];
                }
            }
            return "Unknown";
        }

        def get_project_color(pid: str) -> str {
            for p in projects {
                if p["id"] == pid {
                    return p["color"];
                }
            }
            return "#6366f1";
        }

        if loading {
            return <div className="page-loading">
                <div className="spinner"></div>
                <p>Loading tasks...</p>
            </div>;
        }

        filtered = get_filtered_tasks();

        return <div className="page">
            <div className="page-header">
                <div>
                    <h1 className="page-title">Tasks</h1>
                    <p className="page-subtitle">{filtered.length} task(s) shown</p>
                </div>
                <button className="btn btn-primary" onClick={lambda -> None { show_form = not show_form; }}>
                    {show_form and "Cancel" or "+ New Task"}
                </button>
            </div>

            {show_form and (
                <div className="card form-card">
                    <h3>Create New Task</h3>
                    <div className="form-row">
                        <div className="form-group flex-2">
                            <label>Title</label>
                            <input
                                className="form-input"
                                value={new_title}
                                onChange={lambda e: any -> None { new_title = e.target.value; }}
                                placeholder="Task title..."
                            />
                        </div>
                        <div className="form-group flex-1">
                            <label>Project</label>
                            <select className="form-input" value={new_project} onChange={lambda e: any -> None { new_project = e.target.value; }}>
                                <option value="">Select project...</option>
                                {[
                                    <option key={p["id"]} value={p["id"]}>{p["name"]}</option>
                                    for p in projects
                                ]}
                            </select>
                        </div>
                    </div>
                    <div className="form-group">
                        <label>Description</label>
                        <textarea
                            className="form-input form-textarea"
                            value={new_desc}
                            onChange={lambda e: any -> None { new_desc = e.target.value; }}
                            placeholder="Task details..."
                        ></textarea>
                    </div>
                    <div className="form-row">
                        <div className="form-group flex-1">
                            <label>Priority</label>
                            <select className="form-input" value={new_priority} onChange={lambda e: any -> None { new_priority = e.target.value; }}>
                                <option value="low">Low</option>
                                <option value="medium">Medium</option>
                                <option value="high">High</option>
                                <option value="urgent">Urgent</option>
                            </select>
                        </div>
                        <div className="form-group flex-1">
                            <label>Due Date</label>
                            <input
                                className="form-input"
                                type="date"
                                value={new_due}
                                onChange={lambda e: any -> None { new_due = e.target.value; }}
                            />
                        </div>
                    </div>
                    <button className="btn btn-primary" onClick={lambda -> None { handle_create(); }}>
                        Create Task
                    </button>
                </div>
            )}

            <div className="filters-bar">
                <div className="filter-group">
                    <label>Status:</label>
                    <select className="filter-select" value={filter_status} onChange={lambda e: any -> None { filter_status = e.target.value; }}>
                        <option value="all">All</option>
                        <option value="todo">To Do</option>
                        <option value="in_progress">In Progress</option>
                        <option value="in_review">In Review</option>
                        <option value="done">Done</option>
                    </select>
                </div>
                <div className="filter-group">
                    <label>Priority:</label>
                    <select className="filter-select" value={filter_priority} onChange={lambda e: any -> None { filter_priority = e.target.value; }}>
                        <option value="all">All</option>
                        <option value="low">Low</option>
                        <option value="medium">Medium</option>
                        <option value="high">High</option>
                        <option value="urgent">Urgent</option>
                    </select>
                </div>
            </div>

            <div className="tasks-list">
                {filtered.length == 0 and (
                    <div className="empty-state">
                        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="#475569" strokeWidth="1.5"><path d="M9 11l3 3L22 4"></path><path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"></path></svg>
                        <h3>No tasks found</h3>
                        <p>Create a task or adjust your filters</p>
                    </div>
                )}
                {[
                    <div className={"task-card" + (" task-done" if t["completed"] else "")} key={t["id"]}>
                        <div className="task-card-left">
                            <div className={"priority-indicator priority-" + t["priority"]}></div>
                            <div className="task-card-info">
                                <h4 className="task-card-title">{t["title"]}</h4>
                                {t["description"] and (
                                    <p className="task-card-desc">{t["description"]}</p>
                                )}
                                <div className="task-card-meta">
                                    <span className="task-project-badge" style={{"borderColor": get_project_color(t["project_id"])}}>
                                        {get_project_name(t["project_id"])}
                                    </span>
                                    {t["due_date"] and (
                                        <span className="task-due">Due: {t["due_date"]}</span>
                                    )}
                                    <span className={"priority-badge priority-" + t["priority"]}>{t["priority"]}</span>
                                </div>
                            </div>
                        </div>
                        <div className="task-card-right">
                            <select
                                className={"status-select status-" + t["status"]}
                                value={t["status"]}
                                onChange={lambda e: any -> None { handle_status_change(t["id"], e.target.value); }}
                            >
                                <option value="todo">To Do</option>
                                <option value="in_progress">In Progress</option>
                                <option value="in_review">In Review</option>
                                <option value="done">Done</option>
                            </select>
                            <button
                                className="icon-btn danger"
                                onClick={lambda -> None { handle_delete_task(t["id"]); }}
                                title="Delete task"
                            >
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"></path></svg>
                            </button>
                        </div>
                    </div>
                    for t in filtered
                ]}
            </div>
        </div>;
    }

    # ============================================================
    # LOGIN PAGE
    # ============================================================

    def:pub LoginPage(props: dict) -> JsxElement {
        has username: str = "";
        has password: str = "";
        has error: str = "";
        has loading: bool = False;
        has is_signup: bool = False;

        async def handleLogin() -> None {
            error = "";
            if not username.trim() or not password {
                error = "Please fill in all fields";
                return;
            }
            loading = True;
            success = await jacLogin(username, password);
            loading = False;
            if success {
                props["navigate"]("dashboard");
            } else {
                error = "Invalid credentials";
            }
        }

        async def handleSignup() -> None {
            error = "";
            if not username.trim() or not password {
                error = "Please fill in all fields";
                return;
            }
            if password.length < 4 {
                error = "Password must be at least 4 characters";
                return;
            }
            loading = True;
            result = await jacSignup(username, password);
            loading = False;
            if result["success"] {
                props["navigate"]("dashboard");
            } else {
                error = result["error"] or "Signup failed";
            }
        }

        def handleSubmit(e: any) -> None {
            e.preventDefault();
            if is_signup {
                handleSignup();
            } else {
                handleLogin();
            }
        }

        return <div className="auth-page">
            <div className="auth-card">
                <div className="auth-brand">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#6366f1" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M12 2L2 7l10 5 10-5-10-5z"></path>
                        <path d="M2 17l10 5 10-5"></path>
                        <path d="M2 12l10 5 10-5"></path>
                    </svg>
                    <h1>JacPM</h1>
                    <p>Project Management</p>
                </div>

                <form onSubmit={handleSubmit}>
                    <h2>{is_signup and "Create Account" or "Welcome Back"}</h2>

                    {error and <div className="alert alert-error">{error}</div>}

                    <div className="form-group">
                        <label>Username</label>
                        <input
                            className="form-input"
                            type="text"
                            value={username}
                            onChange={lambda e: any -> None { username = e.target.value; }}
                            placeholder="Enter username"
                        />
                    </div>

                    <div className="form-group">
                        <label>Password</label>
                        <input
                            className="form-input"
                            type="password"
                            value={password}
                            onChange={lambda e: any -> None { password = e.target.value; }}
                            placeholder="Enter password"
                        />
                    </div>

                    <button type="submit" className="btn btn-primary btn-full" disabled={loading}>
                        {loading and "Please wait..." or (is_signup and "Sign Up" or "Login")}
                    </button>

                    <p className="auth-switch">
                        {is_signup and "Already have an account? " or "Don't have an account? "}
                        <button type="button" className="link-btn" onClick={lambda -> None { is_signup = not is_signup; error = ""; }}>
                            {is_signup and "Login" or "Sign Up"}
                        </button>
                    </p>
                </form>
            </div>
        </div>;
    }

    # ============================================================
    # MAIN APP (State-based navigation)
    # ============================================================

    def:pub app() -> JsxElement {
        has current_page: str = "dashboard";
        has project_filter: str = "";

        is_logged_in = jacIsLoggedIn();

        def navigate(page: str) -> None {
            project_filter = "";
            current_page = page;
        }

        def navigateWithProject(pid: str) -> None {
            project_filter = pid;
            current_page = "tasks";
        }

        def handleLogout() -> None {
            jacLogout();
            current_page = "login";
        }

        # Show login if not authenticated
        if not is_logged_in {
            return <LoginPage navigate={navigate} />;
        }

        # Determine active nav class
        def navClass(page: str) -> str {
            if current_page == page {
                return "nav-item active";
            }
            return "nav-item";
        }

        return <div className="app-layout">
            <aside className="sidebar">
                <div className="sidebar-brand">
                    <div className="brand-icon">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                            <path d="M12 2L2 7l10 5 10-5-10-5z"></path>
                            <path d="M2 17l10 5 10-5"></path>
                            <path d="M2 12l10 5 10-5"></path>
                        </svg>
                    </div>
                    <span className="brand-text">JacPM</span>
                </div>
                <nav className="sidebar-nav">
                    <button className={navClass("dashboard")} onClick={lambda -> None { navigate("dashboard"); }}>
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect></svg>
                        <span>Dashboard</span>
                    </button>
                    <button className={navClass("projects")} onClick={lambda -> None { navigate("projects"); }}>
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"></path></svg>
                        <span>Projects</span>
                    </button>
                    <button className={navClass("tasks")} onClick={lambda -> None { navigate("tasks"); }}>
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 11l3 3L22 4"></path><path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"></path></svg>
                        <span>Tasks</span>
                    </button>
                </nav>
                <div className="sidebar-footer">
                    <button
                        className="logout-btn"
                        onClick={lambda -> None { handleLogout(); }}
                    >
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
                        <span>Logout</span>
                    </button>
                </div>
            </aside>
            <main className="main-content">
                {current_page == "dashboard" and (
                    <DashboardPage navigate={navigate} />
                )}
                {current_page == "projects" and (
                    <ProjectsPage navigate={navigate} navigateWithProject={navigateWithProject} />
                )}
                {current_page == "tasks" and (
                    <TasksPage navigate={navigate} projectFilter={project_filter} />
                )}
            </main>
        </div>;
    }
}
