"""LearnHub LMS Frontend."""

import from "@jac/runtime" {
    jacLogin,
    jacLogout,
    jacSignup,
    jacIsLoggedIn,
    Router,
    Routes,
    Route,
    Link,
    Outlet,
    useNavigate,
    useParams
}

sv import from .main {
    get_courses,
    get_course,
    create_course,
    delete_course,
    add_lesson,
    get_lessons,
    toggle_lesson_complete,
    delete_lesson,
    add_assignment,
    get_assignments,
    submit_assignment,
    add_discussion,
    get_discussions,
    add_discussion_post,
    get_discussion_posts
}

# ==================== AUTH PAGES ====================

def LoginPage() -> JsxElement {
    has username: str = "";
    has password: str = "";
    has error: str = "";
    has loading: bool = False;

    navigate = useNavigate();

    can with entry {
        if jacIsLoggedIn() {
            navigate("/");
        }
    }

    async def handleLogin(e: any) -> None {
        e.preventDefault();
        error = "";
        if not username.trim() or not password {
            error = "Please fill in all fields";
            return;
        }
        loading = True;
        success = await jacLogin(username, password);
        loading = False;
        if success {
            navigate("/");
        } else {
            error = "Invalid username or password";
        }
    }

    return <div className="auth-container">
        <h2>Welcome to LearnHub</h2>
        <p>Sign in to continue</p>
        <form onSubmit={handleLogin}>
            {error and <div style={{"color": "var(--danger)", "marginBottom": "1rem"}}>{error}</div>}
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
            <button className="btn btn-primary btn-block" type="submit" disabled={loading}>
                {(loading and "Signing in..." or "Sign In")}
            </button>
        </form>
        <div className="auth-link">
            No account? <Link to="/signup">Create one</Link>
        </div>
    </div>;
}

def SignupPage() -> JsxElement {
    has username: str = "";
    has password: str = "";
    has confirm_password: str = "";
    has error: str = "";
    has loading: bool = False;

    navigate = useNavigate();

    async def handleSignup(e: any) -> None {
        e.preventDefault();
        error = "";
        if not username.trim() or not password {
            error = "Please fill in all fields";
            return;
        }
        if password != confirm_password {
            error = "Passwords don't match";
            return;
        }
        loading = True;
        result = await jacSignup(username, password);
        loading = False;
        if result["success"] {
            navigate("/");
        } else {
            error = result["error"] if "error" in result else "Signup failed";
        }
    }

    return <div className="auth-container">
        <h2>Create Account</h2>
        <p>Join LearnHub today</p>
        <form onSubmit={handleSignup}>
            {error and <div style={{"color": "var(--danger)", "marginBottom": "1rem"}}>{error}</div>}
            <div className="form-group">
                <label>Username</label>
                <input
                    className="form-input"
                    type="text"
                    value={username}
                    onChange={lambda e: any -> None { username = e.target.value; }}
                    placeholder="Choose a username"
                />
            </div>
            <div className="form-group">
                <label>Password</label>
                <input
                    className="form-input"
                    type="password"
                    value={password}
                    onChange={lambda e: any -> None { password = e.target.value; }}
                    placeholder="Choose a password"
                />
            </div>
            <div className="form-group">
                <label>Confirm Password</label>
                <input
                    className="form-input"
                    type="password"
                    value={confirm_password}
                    onChange={lambda e: any -> None { confirm_password = e.target.value; }}
                    placeholder="Confirm password"
                />
            </div>
            <button className="btn btn-primary btn-block" type="submit" disabled={loading}>
                {(loading and "Creating account..." or "Sign Up")}
            </button>
        </form>
        <div className="auth-link">
            Already have an account? <Link to="/login">Sign in</Link>
        </div>
    </div>;
}

# ==================== PROTECTED LAYOUT ====================

def ProtectedLayout() -> JsxElement {
    navigate = useNavigate();
    is_logged_in = jacIsLoggedIn();

    can with entry {
        if not is_logged_in {
            navigate("/login");
        }
    }

    if not is_logged_in {
        return <p>Redirecting...</p>;
    }

    def handleLogout() -> None {
        jacLogout();
        navigate("/login");
    }

    return <div>
        <nav className="navbar">
            <Link to="/" className="navbar-brand">LearnHub</Link>
            <div className="navbar-links">
                <Link to="/">Courses</Link>
            </div>
            <div className="navbar-right">
                <button
                    className="btn btn-sm"
                    style={{"color": "white", "background": "rgba(255,255,255,0.2)"}}
                    onClick={lambda -> None { handleLogout(); }}
                >
                    Logout
                </button>
            </div>
        </nav>
        <Outlet />
    </div>;
}

# ==================== DASHBOARD ====================

def Dashboard() -> JsxElement {
    has courses: list = [];
    has loading: bool = True;
    has show_create: bool = False;
    has new_title: str = "";
    has new_desc: str = "";
    has new_category: str = "General";
    has new_instructor: str = "";

    navigate = useNavigate();

    async def load_courses() -> None {
        loading = True;
        result = await get_courses();
        courses = result if result else [];
        loading = False;
    }

    async can with entry {
        await load_courses();
    }

    async def handle_create() -> None {
        if not new_title.trim() {
            return;
        }
        await create_course(
            title=new_title.trim(),
            description=new_desc.trim(),
            category=new_category,
            instructor_name=new_instructor.trim()
        );
        new_title = "";
        new_desc = "";
        new_category = "General";
        new_instructor = "";
        show_create = False;
        await load_courses();
    }

    async def handle_delete(cid: str) -> None {
        await delete_course(course_id=cid);
        await load_courses();
    }

    return <div className="page-container">
        <div className="page-header">
            <h1>My Courses</h1>
            <button
                className="btn btn-primary"
                onClick={lambda -> None { show_create = True; }}
            >
                + New Course
            </button>
        </div>

        {loading and <div className="loading">Loading courses...</div>}

        {not loading and courses.length == 0 and (
            <div className="empty-state">
                <h3>No courses yet</h3>
                <p>Create your first course to get started</p>
            </div>
        )}

        {not loading and courses.length > 0 and (
            <div className="course-grid">
                {[
                    <div
                        key={c["id"]}
                        className="card course-card"
                        onClick={lambda -> None { navigate(f"/course/{c['id']}"); }}
                    >
                        <div className="card-body">
                            <div className="course-card-category">{c["category"]}</div>
                            <div className="course-card-title">{c["title"]}</div>
                            <div className="course-card-desc">{c["description"]}</div>
                            <div className="course-card-meta">
                                <span>{c["lesson_count"]} lessons</span>
                                <span>{c["assignment_count"]} assignments</span>
                            </div>
                        </div>
                    </div>
                    for c in courses
                ]}
            </div>
        )}

        {show_create and (
            <div className="modal-overlay" onClick={lambda -> None { show_create = False; }}>
                <div className="modal" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                    <h3>Create New Course</h3>
                    <div className="form-group">
                        <label>Title</label>
                        <input
                            className="form-input"
                            value={new_title}
                            onChange={lambda e: any -> None { new_title = e.target.value; }}
                            placeholder="Course title"
                        />
                    </div>
                    <div className="form-group">
                        <label>Description</label>
                        <textarea
                            className="form-textarea"
                            value={new_desc}
                            onChange={lambda e: any -> None { new_desc = e.target.value; }}
                            placeholder="Course description"
                        ></textarea>
                    </div>
                    <div className="form-group">
                        <label>Category</label>
                        <select
                            className="form-select"
                            value={new_category}
                            onChange={lambda e: any -> None { new_category = e.target.value; }}
                        >
                            <option value="General">General</option>
                            <option value="Programming">Programming</option>
                            <option value="Design">Design</option>
                            <option value="Business">Business</option>
                            <option value="Science">Science</option>
                        </select>
                    </div>
                    <div className="form-group">
                        <label>Instructor Name</label>
                        <input
                            className="form-input"
                            value={new_instructor}
                            onChange={lambda e: any -> None { new_instructor = e.target.value; }}
                            placeholder="Instructor name"
                        />
                    </div>
                    <div className="modal-actions">
                        <button
                            className="btn btn-secondary"
                            onClick={lambda -> None { show_create = False; }}
                        >
                            Cancel
                        </button>
                        <button
                            className="btn btn-primary"
                            onClick={lambda -> None { handle_create(); }}
                        >
                            Create
                        </button>
                    </div>
                </div>
            </div>
        )}
    </div>;
}

# ==================== COURSE DETAIL ====================

def CourseDetail() -> JsxElement {
    has course: dict = {};
    has lessons: list = [];
    has assignments: list = [];
    has discussions: list = [];
    has active_tab: str = "lessons";
    has loading: bool = True;

    # Form state
    has show_modal: str = "";
    has form_title: str = "";
    has form_content: str = "";
    has form_order: int = 0;
    has form_duration: int = 0;
    has form_due_date: str = "";
    has form_max_score: int = 100;

    # Lesson viewer
    has selected_lesson: dict = {};

    # Discussion state
    has selected_disc: dict = {};
    has posts: list = [];
    has new_post: str = "";

    params = useParams();
    navigate = useNavigate();
    cid = params["id"];

    async def load_all() -> None {
        loading = True;
        r1 = await get_course(course_id=cid);
        course = r1 if r1 else {};
        r2 = await get_lessons(course_id=cid);
        lessons = r2 if r2 else [];
        r3 = await get_assignments(course_id=cid);
        assignments = r3 if r3 else [];
        r4 = await get_discussions(course_id=cid);
        discussions = r4 if r4 else [];
        loading = False;
    }

    async can with entry {
        await load_all();
    }

    # -- Lesson handlers --
    async def handle_add_lesson() -> None {
        if not form_title.trim() {
            return;
        }
        await add_lesson(
            course_id=cid,
            title=form_title.trim(),
            content=form_content.trim(),
            lesson_order=form_order,
            duration_minutes=form_duration
        );
        form_title = "";
        form_content = "";
        show_modal = "";
        await load_all();
    }

    async def handle_toggle_lesson(lid: str) -> None {
        await toggle_lesson_complete(course_id=cid, lesson_id=lid);
        await load_all();
    }

    async def handle_delete_lesson(lid: str) -> None {
        await delete_lesson(course_id=cid, lesson_id=lid);
        await load_all();
    }

    # -- Assignment handlers --
    async def handle_add_assignment() -> None {
        if not form_title.trim() {
            return;
        }
        await add_assignment(
            course_id=cid,
            title=form_title.trim(),
            description=form_content.trim(),
            due_date=form_due_date,
            max_score=form_max_score
        );
        form_title = "";
        form_content = "";
        form_due_date = "";
        form_max_score = 100;
        show_modal = "";
        await load_all();
    }

    async def handle_submit_assignment(aid: str) -> None {
        if not form_content.trim() {
            return;
        }
        await submit_assignment(
            course_id=cid,
            assignment_id=aid,
            content=form_content.trim()
        );
        form_content = "";
        show_modal = "";
        await load_all();
    }

    # -- Discussion handlers --
    async def handle_add_discussion() -> None {
        if not form_title.trim() {
            return;
        }
        await add_discussion(course_id=cid, title=form_title.trim());
        form_title = "";
        show_modal = "";
        await load_all();
    }

    async def handle_load_posts(disc: dict) -> None {
        selected_disc = disc;
        r = await get_discussion_posts(
            course_id=cid,
            discussion_id=disc["id"]
        );
        posts = r if r else [];
    }

    async def handle_add_post() -> None {
        if not new_post.trim() or not selected_disc["id"] {
            return;
        }
        await add_discussion_post(
            course_id=cid,
            discussion_id=selected_disc["id"],
            content=new_post.trim(),
            author="Me"
        );
        new_post = "";
        r = await get_discussion_posts(
            course_id=cid,
            discussion_id=selected_disc["id"]
        );
        posts = r if r else [];
    }

    if loading {
        return <div className="page-container">
            <div className="loading">Loading course...</div>
        </div>;
    }

    if not course or not ("id" in course) {
        return <div className="page-container">
            <button className="back-btn" onClick={lambda -> None { navigate("/"); }}>
                Back to courses
            </button>
            <div className="empty-state"><h3>Course not found</h3></div>
        </div>;
    }

    progress = course["progress"] if "progress" in course else 0;

    return <div className="page-container">
        <button className="back-btn" onClick={lambda -> None { navigate("/"); }}>
            Back to courses
        </button>

        <div className="card" style={{"marginBottom": "1.5rem"}}>
            <div className="card-body">
                <div className="course-card-category">{course["category"]}</div>
                <h1 style={{"margin": "0.5rem 0"}}>{course["title"]}</h1>
                <p className="text-muted">{course["description"]}</p>
                {course["instructor_name"] and (
                    <p className="text-sm text-muted mt-1">
                        Instructor: {course["instructor_name"]}
                    </p>
                )}
                <div className="progress-bar-container mt-2">
                    <div
                        className="progress-bar-fill"
                        style={{"width": f"{progress}%"}}
                    ></div>
                </div>
                <p className="text-sm text-muted mt-1">
                    {course["completed_lessons"]} of {course["lesson_count"]} lessons completed
                </p>
            </div>
        </div>

        <div className="tabs">
            <button
                className={"tab" + (" active" if active_tab == "lessons" else "")}
                onClick={lambda -> None { active_tab = "lessons"; }}
            >
                Lessons ({course["lesson_count"]})
            </button>
            <button
                className={"tab" + (" active" if active_tab == "assignments" else "")}
                onClick={lambda -> None { active_tab = "assignments"; }}
            >
                Assignments ({course["assignment_count"]})
            </button>
            <button
                className={"tab" + (" active" if active_tab == "discussions" else "")}
                onClick={lambda -> None { active_tab = "discussions"; }}
            >
                Discussions ({course["discussion_count"]})
            </button>
        </div>

        {active_tab == "lessons" and (
            <div>
                <div className="flex-between mb-2">
                    <h3>Lessons</h3>
                    <button
                        className="btn btn-primary btn-sm"
                        onClick={lambda -> None {
                            form_title = "";
                            form_content = "";
                            form_order = lessons.length;
                            form_duration = 0;
                            show_modal = "addLesson";
                        }}
                    >
                        + Add Lesson
                    </button>
                </div>

                {lessons.length == 0 and (
                    <div className="empty-state"><p>No lessons yet</p></div>
                )}

                {selected_lesson and ("id" in selected_lesson) and (
                    <div className="lesson-content-view mb-2">
                        <div className="flex-between">
                            <h2>{selected_lesson["title"]}</h2>
                            <button
                                className="btn btn-secondary btn-sm"
                                onClick={lambda -> None { selected_lesson = {}; }}
                            >
                                Close
                            </button>
                        </div>
                        <div className="lesson-content-body mt-1">
                            {selected_lesson["content"] or "No content yet."}
                        </div>
                    </div>
                )}

                <div className="card">
                    {[
                        <div key={l["id"]} className="lesson-item">
                            <div
                                className={"lesson-check" + (" completed" if l["completed"] else "")}
                                onClick={lambda -> None { handle_toggle_lesson(l["id"]); }}
                            >
                                {l["completed"] and "✓"}
                            </div>
                            <div
                                className="lesson-info"
                                onClick={lambda -> None { selected_lesson = l; }}
                            >
                                <div className="lesson-title">{l["title"]}</div>
                                <div className="lesson-meta">
                                    Lesson {l["lesson_order"] + 1}
                                </div>
                            </div>
                            <span className="lesson-duration">
                                {l["duration_minutes"] > 0 and f"{l['duration_minutes']} min"}
                            </span>
                        </div>
                        for l in lessons
                    ]}
                </div>
            </div>
        )}

        {active_tab == "assignments" and (
            <div>
                <div className="flex-between mb-2">
                    <h3>Assignments</h3>
                    <button
                        className="btn btn-primary btn-sm"
                        onClick={lambda -> None {
                            form_title = "";
                            form_content = "";
                            form_due_date = "";
                            form_max_score = 100;
                            show_modal = "addAssignment";
                        }}
                    >
                        + Add Assignment
                    </button>
                </div>

                {assignments.length == 0 and (
                    <div className="empty-state"><p>No assignments yet</p></div>
                )}

                <div className="card">
                    {[
                        <div key={a["id"]} className="assignment-item">
                            <div className="assignment-header">
                                <span className="assignment-title">{a["title"]}</span>
                                <span className="badge badge-warning">Max: {a["max_score"]}</span>
                            </div>
                            <p className="assignment-meta">{a["description"]}</p>
                            {a["due_date"] and (
                                <p className="assignment-meta">Due: {a["due_date"]}</p>
                            )}
                            <div className="mt-1 flex gap-1">
                                <span className="text-sm text-muted">
                                    {a["submission_count"]} submissions
                                </span>
                                {a["latest_submission"] and (
                                    <span className={
                                        "badge " + (
                                            "badge-success"
                                            if a["latest_submission"]["graded"]
                                            else "badge-warning"
                                        )
                                    }>
                                        {(
                                            f"Score: {a['latest_submission']['score']}"
                                            if a["latest_submission"]["graded"]
                                            else "Pending"
                                        )}
                                    </span>
                                )}
                            </div>
                        </div>
                        for a in assignments
                    ]}
                </div>
            </div>
        )}

        {active_tab == "discussions" and (
            <div>
                <div className="flex-between mb-2">
                    <h3>Discussions</h3>
                    <button
                        className="btn btn-primary btn-sm"
                        onClick={lambda -> None {
                            form_title = "";
                            show_modal = "addDiscussion";
                        }}
                    >
                        + New Discussion
                    </button>
                </div>

                {selected_disc and ("id" in selected_disc) and (
                    <div className="card mb-2">
                        <div className="card-header flex-between">
                            <span>{selected_disc["title"]}</span>
                            <button
                                className="btn btn-secondary btn-sm"
                                onClick={lambda -> None {
                                    selected_disc = {};
                                    posts = [];
                                }}
                            >
                                Close
                            </button>
                        </div>
                        {[
                            <div key={p["id"]} className="post-item">
                                <span className="post-author">
                                    {p["author"] if p["author"] else "Anonymous"}
                                </span>
                                <span className="post-date">{p["created_at"]}</span>
                                <div className="post-content">{p["content"]}</div>
                            </div>
                            for p in posts
                        ]}
                        <div style={{"padding": "1rem", "display": "flex", "gap": "0.5rem"}}>
                            <input
                                className="form-input"
                                value={new_post}
                                onChange={lambda e: any -> None { new_post = e.target.value; }}
                                placeholder="Write a reply..."
                                onKeyDown={lambda e: any -> None {
                                    if e.key == "Enter" {
                                        handle_add_post();
                                    }
                                }}
                            />
                            <button
                                className="btn btn-primary"
                                onClick={lambda -> None { handle_add_post(); }}
                            >
                                Post
                            </button>
                        </div>
                    </div>
                )}

                {discussions.length == 0 and not ("id" in selected_disc) and (
                    <div className="empty-state"><p>No discussions yet</p></div>
                )}

                <div className="card">
                    {[
                        <div
                            key={d["id"]}
                            className="discussion-item"
                            onClick={lambda -> None { handle_load_posts(d); }}
                        >
                            <span className="discussion-title">{d["title"]}</span>
                            <span className="discussion-count">{d["post_count"]} posts</span>
                        </div>
                        for d in discussions
                    ]}
                </div>
            </div>
        )}

        {show_modal == "addLesson" and (
            <div className="modal-overlay" onClick={lambda -> None { show_modal = ""; }}>
                <div className="modal" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                    <h3>Add Lesson</h3>
                    <div className="form-group">
                        <label>Title</label>
                        <input
                            className="form-input"
                            value={form_title}
                            onChange={lambda e: any -> None { form_title = e.target.value; }}
                        />
                    </div>
                    <div className="form-group">
                        <label>Content</label>
                        <textarea
                            className="form-textarea"
                            value={form_content}
                            onChange={lambda e: any -> None { form_content = e.target.value; }}
                        ></textarea>
                    </div>
                    <div className="form-group">
                        <label>Duration (minutes)</label>
                        <input
                            className="form-input"
                            type="number"
                            value={form_duration}
                            onChange={lambda e: any -> None {
                                form_duration = parseInt(e.target.value) or 0;
                            }}
                        />
                    </div>
                    <div className="modal-actions">
                        <button
                            className="btn btn-secondary"
                            onClick={lambda -> None { show_modal = ""; }}
                        >
                            Cancel
                        </button>
                        <button
                            className="btn btn-primary"
                            onClick={lambda -> None { handle_add_lesson(); }}
                        >
                            Add Lesson
                        </button>
                    </div>
                </div>
            </div>
        )}

        {show_modal == "addAssignment" and (
            <div className="modal-overlay" onClick={lambda -> None { show_modal = ""; }}>
                <div className="modal" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                    <h3>Add Assignment</h3>
                    <div className="form-group">
                        <label>Title</label>
                        <input
                            className="form-input"
                            value={form_title}
                            onChange={lambda e: any -> None { form_title = e.target.value; }}
                        />
                    </div>
                    <div className="form-group">
                        <label>Description</label>
                        <textarea
                            className="form-textarea"
                            value={form_content}
                            onChange={lambda e: any -> None { form_content = e.target.value; }}
                        ></textarea>
                    </div>
                    <div className="form-group">
                        <label>Due Date</label>
                        <input
                            className="form-input"
                            type="date"
                            value={form_due_date}
                            onChange={lambda e: any -> None { form_due_date = e.target.value; }}
                        />
                    </div>
                    <div className="form-group">
                        <label>Max Score</label>
                        <input
                            className="form-input"
                            type="number"
                            value={form_max_score}
                            onChange={lambda e: any -> None {
                                form_max_score = parseInt(e.target.value) or 100;
                            }}
                        />
                    </div>
                    <div className="modal-actions">
                        <button
                            className="btn btn-secondary"
                            onClick={lambda -> None { show_modal = ""; }}
                        >
                            Cancel
                        </button>
                        <button
                            className="btn btn-primary"
                            onClick={lambda -> None { handle_add_assignment(); }}
                        >
                            Add Assignment
                        </button>
                    </div>
                </div>
            </div>
        )}

        {show_modal == "addDiscussion" and (
            <div className="modal-overlay" onClick={lambda -> None { show_modal = ""; }}>
                <div className="modal" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                    <h3>New Discussion</h3>
                    <div className="form-group">
                        <label>Title</label>
                        <input
                            className="form-input"
                            value={form_title}
                            onChange={lambda e: any -> None { form_title = e.target.value; }}
                        />
                    </div>
                    <div className="modal-actions">
                        <button
                            className="btn btn-secondary"
                            onClick={lambda -> None { show_modal = ""; }}
                        >
                            Cancel
                        </button>
                        <button
                            className="btn btn-primary"
                            onClick={lambda -> None { handle_add_discussion(); }}
                        >
                            Create
                        </button>
                    </div>
                </div>
            </div>
        )}
    </div>;
}

# ==================== MAIN APP ====================

def:pub App() -> JsxElement {
    return <Router>
        <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/signup" element={<SignupPage />} />
            <Route path="/" element={<ProtectedLayout />}>
                <Route index element={<Dashboard />} />
                <Route path="course/:id" element={<CourseDetail />} />
            </Route>
        </Routes>
    </Router>;
}
