"""LinkedIn Clone - Full Stack Jac Application."""

import datetime;
import from typing { Any }

# ============================================================
# GRAPH DATA MODEL - Nodes & Edges
# ============================================================

node Profile {
    has name: str = "";
    has headline: str = "";
    has bio: str = "";
    has location: str = "";
    has created_at: str = "";
}

node Post {
    has content: str = "";
    has author_name: str = "";
    has created_at: str = "";
}

node Comment {
    has content: str = "";
    has author_name: str = "";
    has created_at: str = "";
}

edge Connects {}
edge Likes {}

# ============================================================
# HELPER WALKERS - profile access
# ============================================================

walker visit_profile {
    can ensure_profile with Root entry {
        profile_list = [root -->[?:Profile]];
        if len(profile_list) == 0 {
            new_profile = Profile();
            root ++> new_profile;
            grant(new_profile, level=ConnectPerm);
            visit new_profile;
        } else {
            visit profile_list[0];
        }
    }
}

# ============================================================
# PROFILE WALKERS
# ============================================================

walker:priv get_profile(visit_profile) {
    can fetch with Profile entry {
        report {
            "name": here.name,
            "headline": here.headline,
            "bio": here.bio,
            "location": here.location,
            "id": jid(here)
        };
        disengage;
    }
}

walker:priv update_profile(visit_profile) {
    has name: str = "";
    has headline: str = "";
    has bio: str = "";
    has location: str = "";

    can update with Profile entry {
        if self.name { here.name = self.name; }
        if self.headline { here.headline = self.headline; }
        if self.bio { here.bio = self.bio; }
        if self.location { here.location = self.location; }
        report {
            "name": here.name,
            "headline": here.headline,
            "bio": here.bio,
            "location": here.location,
            "id": jid(here)
        };
        disengage;
    }
}

# ============================================================
# POST WALKERS
# ============================================================

walker:priv create_post(visit_profile) {
    has content: str = "";

    can make_post with Profile entry {
        ts = str(datetime.datetime.now());
        new_post = Post(
            content=self.content,
            author_name=here.name,
            created_at=ts
        );
        here ++> new_post;
        grant(new_post, level=ConnectPerm);
        report {
            "id": jid(new_post),
            "content": new_post.content,
            "author_name": new_post.author_name,
            "created_at": new_post.created_at,
            "likes": 0,
            "comments": []
        };
        disengage;
    }
}

walker:priv get_feed(visit_profile) {
    has posts: list = [];

    can load_posts with Profile entry {
        for post in [here -->[?:Post]] {
            likes_count = len([post -->[?:Profile]]);
            comments_list: list = [];
            for comment in [post -->[?:Comment]] {
                comments_list.append({
                    "id": jid(comment),
                    "content": comment.content,
                    "author_name": comment.author_name,
                    "created_at": comment.created_at
                });
            }
            self.posts.append({
                "id": jid(post),
                "content": post.content,
                "author_name": post.author_name,
                "created_at": post.created_at,
                "likes": likes_count,
                "comments": comments_list
            });
        }
        report self.posts;
        disengage;
    }
}

walker:priv delete_post(visit_profile) {
    has post_id: str = "";

    can remove_post with Profile entry {
        for post in [here -->[?:Post]] {
            if jid(post) == self.post_id {
                del post;
                report {"success": True};
                disengage;
            }
        }
        report {"success": False};
        disengage;
    }
}

walker:priv add_comment {
    has post_id: str = "";
    has content: str = "";

    can post_comment with Root entry {
        current_profile = [root -->[?:Profile]];
        if len(current_profile) == 0 {
            report {"success": False};
            disengage;
        }
        author_name_str = "";
        for ap in current_profile {
            author_name_str = ap.name;
            break;
        }
        ts = str(datetime.datetime.now());
        for profile_node in [root -->[?:Profile]] {
            for post in [profile_node -->[?:Post]] {
                if jid(post) == self.post_id {
                    new_comment = Comment(
                        content=self.content,
                        author_name=author_name_str,
                        created_at=ts
                    );
                    post ++> new_comment;
                    grant(new_comment, level=ConnectPerm);
                    report {
                        "id": jid(new_comment),
                        "content": new_comment.content,
                        "author_name": new_comment.author_name,
                        "created_at": new_comment.created_at
                    };
                    disengage;
                }
            }
        }
        report {"success": False};
        disengage;
    }
}

# ============================================================
# CONNECTION WALKERS
# ============================================================

walker:pub get_all_profiles {
    can load with Root entry {
        profiles: list = [];
        for each_root in allroots() {
            profile_list = [each_root -->[?:Profile]];
            if len(profile_list) > 0 {
                p = profile_list[0];
                profiles.append({
                    "id": jid(p),
                    "name": p.name,
                    "headline": p.headline,
                    "location": p.location
                });
            }
        }
        report profiles;
        disengage;
    }
}

walker:priv get_connections(visit_profile) {
    can load_connections with Profile entry {
        connections: list = [];
        for other in [here ->:Connects:->] {
            connections.append({
                "id": jid(other),
                "name": other.name,
                "headline": other.headline,
                "location": other.location
            });
        }
        report connections;
        disengage;
    }
}

walker:priv send_connection(visit_profile) {
    has target_profile_id: str = "";

    can connect with Profile entry {
        for each_root in allroots() {
            for profile_node in [each_root -->[?:Profile]] {
                if jid(profile_node) == self.target_profile_id {
                    existing = [edge here ->:Connects:-> profile_node];
                    if len(existing) == 0 {
                        here +>:Connects():+> profile_node;
                        profile_node +>:Connects():+> here;
                        report {"success": True, "message": "Connected!"};
                    } else {
                        report {"success": False, "message": "Already connected"};
                    }
                    disengage;
                }
            }
        }
        report {"success": False, "message": "Profile not found"};
        disengage;
    }
}

# ============================================================
# FRONTEND - Client-Side (React-style)
# ============================================================

cl import from "@jac/runtime" {
    jacLogin,
    jacSignup,
    jacLogout,
    jacIsLoggedIn,
    useNavigate,
    Router,
    Routes,
    Route,
    Link
}

cl {

    # --------------------------------------------------------
    # LOGIN PAGE
    # --------------------------------------------------------
    def:pub LoginPage() -> JsxElement {
        has username: str = "";
        has password: str = "";
        has error: str = "";
        has loading: bool = False;

        navigate = useNavigate();

        can with entry {
            if jacIsLoggedIn() {
                navigate("/feed");
            }
        }

        async def handleLogin(e: Any) -> None {
            e.preventDefault();
            error = "";
            if not username or not password {
                error = "Please fill in all fields";
                return;
            }
            loading = True;
            success = await jacLogin(username, password);
            loading = False;
            if success {
                navigate("/feed");
            } else {
                error = "Invalid credentials";
            }
        }

        return <div style={{
            "minHeight": "100vh",
            "background": "linear-gradient(135deg, #0a66c2 0%, #004182 100%)",
            "display": "flex",
            "alignItems": "center",
            "justifyContent": "center"
        }}>
            <div style={{
                "background": "white",
                "borderRadius": "12px",
                "padding": "2.5rem",
                "width": "100%",
                "maxWidth": "400px",
                "boxShadow": "0 8px 32px rgba(0,0,0,0.2)"
            }}>
                <div style={{"textAlign": "center", "marginBottom": "2rem"}}>
                    <h1 style={{"color": "#0a66c2", "fontSize": "2rem", "margin": "0 0 0.5rem 0"}}>LinkedJac</h1>
                    <p style={{"color": "#666", "margin": "0"}}>Connect with professionals</p>
                </div>
                <form onSubmit={handleLogin}>
                    {error and <div style={{"color": "#cc1016", "background": "#fff0f0", "padding": "0.75rem", "borderRadius": "6px", "marginBottom": "1rem"}}>{error}</div>}
                    <div style={{"marginBottom": "1rem"}}>
                        <input
                            type="text"
                            value={username}
                            onChange={lambda e: Any -> None { username = str(e.target.value); }}
                            placeholder="Username"
                            style={{"width": "100%", "padding": "0.85rem", "border": "1px solid #ddd", "borderRadius": "6px", "fontSize": "1rem", "boxSizing": "border-box"}}
                        />
                    </div>
                    <div style={{"marginBottom": "1.5rem"}}>
                        <input
                            type="password"
                            value={password}
                            onChange={lambda e: Any -> None { password = str(e.target.value); }}
                            placeholder="Password"
                            style={{"width": "100%", "padding": "0.85rem", "border": "1px solid #ddd", "borderRadius": "6px", "fontSize": "1rem", "boxSizing": "border-box"}}
                        />
                    </div>
                    <button
                        type="submit"
                        disabled={loading}
                        style={{
                            "width": "100%",
                            "padding": "0.85rem",
                            "background": "#0a66c2",
                            "color": "white",
                            "border": "none",
                            "borderRadius": "24px",
                            "fontSize": "1rem",
                            "fontWeight": "bold",
                            "cursor": "pointer"
                        }}
                    >
                        {loading and "Signing in..." or "Sign In"}
                    </button>
                </form>
                <div style={{"textAlign": "center", "marginTop": "1.5rem"}}>
                    <span style={{"color": "#666"}}>New to LinkedJac? </span>
                    <Link to="/signup" style={{"color": "#0a66c2", "fontWeight": "bold"}}>Join now</Link>
                </div>
            </div>
        </div>;
    }

    # --------------------------------------------------------
    # SIGNUP PAGE
    # --------------------------------------------------------
    def:pub SignupPage() -> JsxElement {
        has username: str = "";
        has password: str = "";
        has confirmPass: str = "";
        has error: str = "";
        has loading: bool = False;

        navigate = useNavigate();

        async def handleSignup(e: Any) -> None {
            e.preventDefault();
            error = "";
            if not username or not password {
                error = "Please fill in all fields";
                return;
            }
            if password != confirmPass {
                error = "Passwords do not match";
                return;
            }
            if len(password) < 6 {
                error = "Password must be at least 6 characters";
                return;
            }
            loading = True;
            result = await jacSignup(username, password);
            loading = False;
            if result["success"] {
                navigate("/feed");
            } else {
                error = result["error"] or "Signup failed";
            }
        }

        return <div style={{
            "minHeight": "100vh",
            "background": "linear-gradient(135deg, #0a66c2 0%, #004182 100%)",
            "display": "flex",
            "alignItems": "center",
            "justifyContent": "center"
        }}>
            <div style={{
                "background": "white",
                "borderRadius": "12px",
                "padding": "2.5rem",
                "width": "100%",
                "maxWidth": "400px",
                "boxShadow": "0 8px 32px rgba(0,0,0,0.2)"
            }}>
                <div style={{"textAlign": "center", "marginBottom": "2rem"}}>
                    <h1 style={{"color": "#0a66c2", "fontSize": "2rem", "margin": "0 0 0.5rem 0"}}>LinkedJac</h1>
                    <p style={{"color": "#666", "margin": "0"}}>Make the most of your professional life</p>
                </div>
                <form onSubmit={handleSignup}>
                    {error and <div style={{"color": "#cc1016", "background": "#fff0f0", "padding": "0.75rem", "borderRadius": "6px", "marginBottom": "1rem"}}>{error}</div>}
                    <div style={{"marginBottom": "1rem"}}>
                        <input type="text" value={username} onChange={lambda e: Any -> None { username = str(e.target.value); }} placeholder="Username" style={{"width": "100%", "padding": "0.85rem", "border": "1px solid #ddd", "borderRadius": "6px", "fontSize": "1rem", "boxSizing": "border-box"}} />
                    </div>
                    <div style={{"marginBottom": "1rem"}}>
                        <input type="password" value={password} onChange={lambda e: Any -> None { password = str(e.target.value); }} placeholder="Password" style={{"width": "100%", "padding": "0.85rem", "border": "1px solid #ddd", "borderRadius": "6px", "fontSize": "1rem", "boxSizing": "border-box"}} />
                    </div>
                    <div style={{"marginBottom": "1.5rem"}}>
                        <input type="password" value={confirmPass} onChange={lambda e: Any -> None { confirmPass = str(e.target.value); }} placeholder="Confirm Password" style={{"width": "100%", "padding": "0.85rem", "border": "1px solid #ddd", "borderRadius": "6px", "fontSize": "1rem", "boxSizing": "border-box"}} />
                    </div>
                    <button type="submit" disabled={loading} style={{"width": "100%", "padding": "0.85rem", "background": "#0a66c2", "color": "white", "border": "none", "borderRadius": "24px", "fontSize": "1rem", "fontWeight": "bold", "cursor": "pointer"}}>
                        {loading and "Creating account..." or "Agree & Join"}
                    </button>
                </form>
                <div style={{"textAlign": "center", "marginTop": "1.5rem"}}>
                    <span style={{"color": "#666"}}>Already on LinkedJac? </span>
                    <Link to="/login" style={{"color": "#0a66c2", "fontWeight": "bold"}}>Sign in</Link>
                </div>
            </div>
        </div>;
    }

    # --------------------------------------------------------
    # NAVBAR COMPONENT
    # --------------------------------------------------------
    def:pub NavBar() -> JsxElement {
        has currentPath: str = "/feed";

        navigate = useNavigate();

        def handleLogout() -> None {
            jacLogout();
            navigate("/login");
        }

        return <nav style={{
            "background": "white",
            "borderBottom": "1px solid #e0e0e0",
            "position": "sticky",
            "top": "0",
            "zIndex": "100",
            "boxShadow": "0 1px 4px rgba(0,0,0,0.1)"
        }}>
            <div style={{"maxWidth": "1128px", "margin": "0 auto", "padding": "0 1rem", "display": "flex", "alignItems": "center", "height": "52px"}}>
                <div style={{"marginRight": "1.5rem"}}>
                    <Link to="/feed" style={{"textDecoration": "none"}}>
                        <span style={{"color": "#0a66c2", "fontWeight": "900", "fontSize": "1.5rem"}}>LinkedJac</span>
                    </Link>
                </div>
                <div style={{"flex": "1", "display": "flex", "gap": "0.5rem"}}>
                    <Link to="/feed" style={{"color": currentPath == "/feed" and "#0a66c2" or "#666", "textDecoration": "none", "fontWeight": currentPath == "/feed" and "bold" or "normal", "padding": "0.5rem 0.75rem"}}>Feed</Link>
                    <Link to="/network" style={{"color": currentPath == "/network" and "#0a66c2" or "#666", "textDecoration": "none", "fontWeight": currentPath == "/network" and "bold" or "normal", "padding": "0.5rem 0.75rem"}}>Network</Link>
                    <Link to="/profile" style={{"color": currentPath == "/profile" and "#0a66c2" or "#666", "textDecoration": "none", "fontWeight": currentPath == "/profile" and "bold" or "normal", "padding": "0.5rem 0.75rem"}}>Profile</Link>
                </div>
                <button
                    onClick={lambda -> None { handleLogout(); }}
                    style={{"padding": "0.5rem 1rem", "background": "transparent", "border": "1px solid #0a66c2", "borderRadius": "20px", "color": "#0a66c2", "cursor": "pointer", "fontWeight": "bold"}}
                >
                    Sign Out
                </button>
            </div>
        </nav>;
    }

    # --------------------------------------------------------
    # FEED PAGE
    # --------------------------------------------------------
    def:pub FeedPage() -> JsxElement {
        has posts: list = [];
        has postContent: str = "";
        has loading: bool = True;
        has submitting: bool = False;
        has commentInputs: Any = {};
        has expandedComments: Any = {};

        navigate = useNavigate();

        can with entry {
            if not jacIsLoggedIn() {
                navigate("/login");
            }
        }

        async def loadFeed() -> None {
            loading = True;
            try {
                result = root spawn get_feed();
                rpts = getattr(result, "reports", []);
                if rpts and len(rpts) > 0 {
                    posts = rpts[0];
                }
            } except Exception as e {
                print("Error loading feed:", e);
            }
            loading = False;
        }

        async can with entry {
            if jacIsLoggedIn() {
                await loadFeed();
            }
        }

        async def handleCreatePost(e: Any) -> None {
            e.preventDefault();
            if not postContent.strip() { return; }
            submitting = True;
            try {
                result = root spawn create_post(content=postContent.strip());
                rpts = getattr(result, "reports", []);
                if rpts and len(rpts) > 0 {
                    posts = [rpts[0]] + posts;
                }
                postContent = "";
            } except Exception as ex {
                print("Error creating post:", ex);
            }
            submitting = False;
        }

        async def handleDeletePost(post_id: str) -> None {
            try {
                root spawn delete_post(post_id=post_id);
                posts = [p for p in posts if p["id"] != post_id];
            } except Exception as ex {
                print("Error deleting post:", ex);
            }
        }

        async def handleAddComment(post_id: str) -> None {
            comment_text: str = str(commentInputs[post_id]) if post_id in commentInputs else "";
            if not comment_text.strip() { return; }
            try {
                trimmed: str = comment_text.strip();
                result = root spawn add_comment(post_id=post_id, content=trimmed);
                rpts = getattr(result, "reports", []);
                if rpts and len(rpts) > 0 {
                    new_comment = rpts[0];
                    updated_posts = [];
                    for p in posts {
                        old_comments = list(p["comments"]);
                        old_comments.append(new_comment);
                        new_p = {** p, "comments": old_comments} if p["id"] == post_id else p;
                        updated_posts.append(new_p);
                    }
                    posts = updated_posts;
                    commentInputs = {** commentInputs, post_id: ""};
                }
            } except Exception as ex {
                print("Error adding comment:", ex);
            }
        }

        def toggleComments(post_id: str) -> None {
            expanded = expandedComments[post_id] if post_id in expandedComments else False;
            expandedComments = {** expandedComments, post_id: not expanded};
        }

        def setCommentInput(post_id: str, val: str) -> None {
            merged: Any = {** commentInputs, post_id: val};
            commentInputs = merged;

        }

        if not jacIsLoggedIn() {
            return <div></div>;
        }

        return <div style={{"background": "#f3f2ef", "minHeight": "100vh"}}>
            {<NavBar currentPath="/feed" />}
            <div style={{"maxWidth": "600px", "margin": "1.5rem auto", "padding": "0 1rem"}}>

                <div style={{"background": "white", "borderRadius": "10px", "padding": "1.25rem", "marginBottom": "1rem", "boxShadow": "0 1px 3px rgba(0,0,0,0.08)"}}>
                    <form onSubmit={handleCreatePost}>
                        <textarea
                            value={postContent}
                            onChange={lambda e: Any -> None { postContent = str(e.target.value); }}
                            placeholder="What's on your mind?"
                            rows={3}
                            style={{"width": "100%", "border": "1px solid #ddd", "borderRadius": "8px", "padding": "0.75rem", "fontSize": "1rem", "resize": "vertical", "fontFamily": "inherit", "boxSizing": "border-box"}}
                        />
                        <div style={{"display": "flex", "justifyContent": "flex-end", "marginTop": "0.75rem"}}>
                            <button
                                type="submit"
                                disabled={submitting}
                                style={{"padding": "0.5rem 1.5rem", "background": "#0a66c2", "color": "white", "border": "none", "borderRadius": "20px", "fontWeight": "bold", "cursor": "pointer"}}
                            >
                                {submitting and "Posting..." or "Post"}
                            </button>
                        </div>
                    </form>
                </div>

                {loading and <div style={{"textAlign": "center", "padding": "2rem", "color": "#666"}}>Loading feed...</div>}

                {not loading and len(posts) == 0 and <div style={{"background": "white", "borderRadius": "10px", "padding": "2rem", "textAlign": "center", "color": "#666", "boxShadow": "0 1px 3px rgba(0,0,0,0.08)"}}>
                    <p>No posts yet. Be the first to share something!</p>
                </div>}

                {[
                    <div key={post["id"]} style={{"background": "white", "borderRadius": "10px", "padding": "1.25rem", "marginBottom": "1rem", "boxShadow": "0 1px 3px rgba(0,0,0,0.08)"}}>
                        <div style={{"display": "flex", "justifyContent": "space-between", "marginBottom": "0.75rem"}}>
                            <div>
                                <div style={{"fontWeight": "bold", "color": "#000"}}>{post["author_name"] or "Unknown User"}</div>
                                <div style={{"fontSize": "0.8rem", "color": "#888"}}>{post["created_at"]}</div>
                            </div>
                            <button
                                onClick={lambda -> None { handleDeletePost(str(post["id"])); }}
                                style={{"background": "none", "border": "none", "color": "#999", "cursor": "pointer", "fontSize": "1.1rem", "fontWeight": "bold"}}
                            >
                                x
                            </button>
                        </div>

                        <p style={{"margin": "0 0 1rem 0", "lineHeight": "1.6", "color": "#333"}}>{post["content"]}</p>

                        <div style={{"display": "flex", "gap": "1rem", "borderTop": "1px solid #e0e0e0", "paddingTop": "0.75rem", "marginBottom": "0.5rem"}}>
                            <span style={{"color": "#666", "fontSize": "0.9rem"}}>
                                {str(post["likes"])} Likes
                            </span>
                            <button
                                onClick={lambda -> None { toggleComments(str(post["id"])); }}
                                style={{"background": "none", "border": "none", "color": "#0a66c2", "cursor": "pointer", "fontSize": "0.9rem", "fontWeight": "bold"}}
                            >
                                {str(len(list(post["comments"])))} Comments
                            </button>
                        </div>

                        {(expandedComments[post["id"]] if post["id"] in expandedComments else False) and <div style={{"marginTop": "0.5rem"}}>
                            {[
                                <div key={c["id"]} style={{"background": "#f9f9f9", "borderRadius": "6px", "padding": "0.5rem 0.75rem", "marginBottom": "0.4rem"}}>
                                    <strong style={{"fontSize": "0.85rem"}}>{c["author_name"]}</strong>
                                    <span style={{"color": "#888", "fontSize": "0.75rem", "marginLeft": "0.5rem"}}>{c["created_at"]}</span>
                                    <p style={{"margin": "0.2rem 0 0 0", "fontSize": "0.9rem"}}>{c["content"]}</p>
                                </div>
                                for c in post["comments"]
                            ]}
                            <div style={{"display": "flex", "gap": "0.5rem", "marginTop": "0.5rem"}}>
                                <input
                                    type="text"
                                    value={commentInputs[post["id"]] if post["id"] in commentInputs else ""}
                                    onChange={lambda e: Any -> None { setCommentInput(str(post["id"]), str(e.target.value)); }}
                                    placeholder="Write a comment..."
                                    style={{"flex": "1", "padding": "0.5rem 0.75rem", "border": "1px solid #ddd", "borderRadius": "20px", "fontSize": "0.9rem"}}
                                />
                                <button
                                    onClick={lambda -> None { handleAddComment(str(post["id"])); }}
                                    style={{"padding": "0.5rem 1rem", "background": "#0a66c2", "color": "white", "border": "none", "borderRadius": "20px", "cursor": "pointer"}}
                                >
                                    Send
                                </button>
                            </div>
                        </div>}
                    </div>
                    for post in posts
                ]}
            </div>
        </div>;
    }

    # --------------------------------------------------------
    # PROFILE PAGE
    # --------------------------------------------------------
    def:pub ProfilePage() -> JsxElement {
        has profileData: Any = {};
        has editing: bool = False;
        has name: str = "";
        has headline: str = "";
        has bio: str = "";
        has location: str = "";
        has loading: bool = True;
        has saving: bool = False;

        navigate = useNavigate();

        can with entry {
            if not jacIsLoggedIn() {
                navigate("/login");
            }
        }

        async can with entry {
            if jacIsLoggedIn() {
                try {
                    result = root spawn get_profile();
                    rpts = getattr(result, "reports", []);
                    if rpts and len(rpts) > 0 {
                        profileData = rpts[0];
                        name = profileData["name"];
                        headline = profileData["headline"];
                        bio = profileData["bio"];
                        location = profileData["location"];
                    }
                } except Exception as ex {
                    print("Error loading profile:", ex);
                }
                loading = False;
            }
        }

        async def handleSave(e: Any) -> None {
            e.preventDefault();
            saving = True;
            try {
                result = root spawn update_profile(
                    name=name,
                    headline=headline,
                    bio=bio,
                    location=location
                );
                rpts = getattr(result, "reports", []);
                if rpts and len(rpts) > 0 {
                    profileData = rpts[0];
                }
                editing = False;
            } except Exception as ex {
                print("Error saving profile:", ex);
            }
            saving = False;
        }

        if not jacIsLoggedIn() { return <div></div>; }

        return <div style={{"background": "#f3f2ef", "minHeight": "100vh"}}>
            {<NavBar currentPath="/profile" />}
            <div style={{"maxWidth": "700px", "margin": "1.5rem auto", "padding": "0 1rem"}}>

                <div style={{"background": "white", "borderRadius": "10px", "overflow": "hidden", "boxShadow": "0 1px 3px rgba(0,0,0,0.1)"}}>
                    <div style={{"height": "120px", "background": "linear-gradient(135deg, #0a66c2, #004182)"}}></div>
                    <div style={{"padding": "0 1.5rem 1.5rem"}}>
                        <div style={{"width": "80px", "height": "80px", "background": "#0a66c2", "borderRadius": "50%", "border": "4px solid white", "marginTop": "-40px", "display": "flex", "alignItems": "center", "justifyContent": "center", "color": "white", "fontSize": "2rem", "fontWeight": "bold"}}>
                            {(str(profileData["name"])[0:1] if profileData["name"] else "?")}
                        </div>
                        <div style={{"marginTop": "0.75rem"}}>
                            {not editing and <div>
                                <h2 style={{"margin": "0 0 0.25rem 0", "fontSize": "1.4rem"}}>{profileData["name"] or "Your Name"}</h2>
                                <p style={{"margin": "0 0 0.25rem 0", "color": "#555"}}>{profileData["headline"] or "Add your headline"}</p>
                                <p style={{"margin": "0 0 0.5rem 0", "color": "#777", "fontSize": "0.9rem"}}>{profileData["location"] or "Add location"}</p>
                                <p style={{"margin": "0 0 1rem 0", "color": "#444", "lineHeight": "1.5"}}>{profileData["bio"] or "Tell your story..."}</p>
                                <button
                                    onClick={lambda -> None { editing = True; }}
                                    style={{"padding": "0.5rem 1.5rem", "background": "white", "border": "1px solid #0a66c2", "borderRadius": "20px", "color": "#0a66c2", "cursor": "pointer", "fontWeight": "bold"}}
                                >
                                    Edit Profile
                                </button>
                            </div>}
                            {editing and <form onSubmit={handleSave}>
                                <div style={{"marginBottom": "1rem"}}>
                                    <label style={{"display": "block", "fontWeight": "bold", "marginBottom": "0.25rem"}}>Name</label>
                                    <input type="text" value={name} onChange={lambda e: Any -> None { name = str(e.target.value); }} placeholder="Your full name" style={{"width": "100%", "padding": "0.5rem", "border": "1px solid #ddd", "borderRadius": "4px", "boxSizing": "border-box"}} />
                                </div>
                                <div style={{"marginBottom": "1rem"}}>
                                    <label style={{"display": "block", "fontWeight": "bold", "marginBottom": "0.25rem"}}>Headline</label>
                                    <input type="text" value={headline} onChange={lambda e: Any -> None { headline = str(e.target.value); }} placeholder="Software Engineer at Company" style={{"width": "100%", "padding": "0.5rem", "border": "1px solid #ddd", "borderRadius": "4px", "boxSizing": "border-box"}} />
                                </div>
                                <div style={{"marginBottom": "1rem"}}>
                                    <label style={{"display": "block", "fontWeight": "bold", "marginBottom": "0.25rem"}}>Location</label>
                                    <input type="text" value={location} onChange={lambda e: Any -> None { location = str(e.target.value); }} placeholder="City, Country" style={{"width": "100%", "padding": "0.5rem", "border": "1px solid #ddd", "borderRadius": "4px", "boxSizing": "border-box"}} />
                                </div>
                                <div style={{"marginBottom": "1rem"}}>
                                    <label style={{"display": "block", "fontWeight": "bold", "marginBottom": "0.25rem"}}>Bio</label>
                                    <textarea value={bio} onChange={lambda e: Any -> None { bio = str(e.target.value); }} placeholder="Tell your story..." rows={4} style={{"width": "100%", "padding": "0.5rem", "border": "1px solid #ddd", "borderRadius": "4px", "boxSizing": "border-box", "resize": "vertical", "fontFamily": "inherit"}} />
                                </div>
                                <div style={{"display": "flex", "gap": "0.75rem"}}>
                                    <button type="submit" disabled={saving} style={{"padding": "0.5rem 1.5rem", "background": "#0a66c2", "color": "white", "border": "none", "borderRadius": "20px", "cursor": "pointer", "fontWeight": "bold"}}>{saving and "Saving..." or "Save"}</button>
                                    <button type="button" onClick={lambda -> None { editing = False; }} style={{"padding": "0.5rem 1.5rem", "background": "white", "border": "1px solid #666", "borderRadius": "20px", "cursor": "pointer"}}>Cancel</button>
                                </div>
                            </form>}
                        </div>
                    </div>
                </div>
            </div>
        </div>;
    }

    # --------------------------------------------------------
    # NETWORK PAGE
    # --------------------------------------------------------
    def:pub NetworkPage() -> JsxElement {
        has allProfiles: list = [];
        has connections: list = [];
        has loading: bool = True;
        has connectingId: str = "";

        navigate = useNavigate();

        can with entry {
            if not jacIsLoggedIn() {
                navigate("/login");
            }
        }

        async can with entry {
            if jacIsLoggedIn() {
                try {
                    r1 = root spawn get_all_profiles();
                    rpts1 = getattr(r1, "reports", []);
                    if rpts1 and len(rpts1) > 0 {
                        allProfiles = rpts1[0];
                    }
                    r2 = root spawn get_connections();
                    rpts2 = getattr(r2, "reports", []);
                    if rpts2 and len(rpts2) > 0 {
                        connections = rpts2[0];
                    }
                } except Exception as ex {
                    print("Error loading network:", ex);
                }
                loading = False;
            }
        }

        async def handleConnect(profile_id: str) -> None {
            connectingId = profile_id;
            try {
                result = root spawn send_connection(target_profile_id=profile_id);
                rpts = getattr(result, "reports", []);
                if rpts and len(rpts) > 0 and rpts[0]["success"] {
                    r2 = root spawn get_connections();
                    rpts2 = getattr(r2, "reports", []);
                    if rpts2 and len(rpts2) > 0 {
                        connections = rpts2[0];
                    }
                }
            } except Exception as ex {
                print("Error connecting:", ex);
            }
            connectingId = "";
        }

        def isConnected(profile_id: str) -> bool {
            return len([c for c in connections if c["id"] == profile_id]) > 0;
        }

        if not jacIsLoggedIn() { return <div></div>; }

        return <div style={{"background": "#f3f2ef", "minHeight": "100vh"}}>
            {<NavBar currentPath="/network" />}
            <div style={{"maxWidth": "900px", "margin": "1.5rem auto", "padding": "0 1rem"}}>

                <h2 style={{"marginBottom": "1rem", "color": "#333"}}>My Connections ({str(len(connections))})</h2>
                {len(connections) > 0 and <div style={{"display": "grid", "gridTemplateColumns": "repeat(auto-fill, minmax(200px, 1fr))", "gap": "1rem", "marginBottom": "2rem"}}>
                    {[
                        <div key={c["id"]} style={{"background": "white", "borderRadius": "10px", "padding": "1.25rem", "textAlign": "center", "boxShadow": "0 1px 3px rgba(0,0,0,0.1)"}}>
                            <div style={{"width": "56px", "height": "56px", "background": "#0a66c2", "borderRadius": "50%", "display": "flex", "alignItems": "center", "justifyContent": "center", "color": "white", "fontSize": "1.4rem", "fontWeight": "bold", "margin": "0 auto 0.75rem"}}>
                                {str(c["name"])[0:1] if c["name"] else "?"}
                            </div>
                            <div style={{"fontWeight": "bold", "marginBottom": "0.25rem"}}>{c["name"]}</div>
                            <div style={{"fontSize": "0.8rem", "color": "#666", "marginBottom": "0.25rem"}}>{c["headline"]}</div>
                            <div style={{"fontSize": "0.75rem", "color": "#888"}}>{c["location"]}</div>
                            <div style={{"marginTop": "0.75rem", "padding": "0.35rem 0.75rem", "background": "#e8f0fe", "color": "#0a66c2", "borderRadius": "20px", "fontSize": "0.85rem"}}>Connected</div>
                        </div>
                        for c in connections
                    ]}
                </div>}

                <h2 style={{"marginBottom": "1rem", "color": "#333"}}>People You May Know</h2>
                {loading and <div style={{"textAlign": "center", "padding": "2rem", "color": "#666"}}>Loading...</div>}
                {not loading and len(allProfiles) == 0 and <div style={{"background": "white", "borderRadius": "10px", "padding": "2rem", "textAlign": "center", "color": "#666"}}>No profiles found yet.</div>}
                {not loading and len(allProfiles) > 0 and <div style={{"display": "grid", "gridTemplateColumns": "repeat(auto-fill, minmax(220px, 1fr))", "gap": "1rem"}}>
                    {[
                        <div key={p["id"]} style={{"background": "white", "borderRadius": "10px", "padding": "1.25rem", "textAlign": "center", "boxShadow": "0 1px 3px rgba(0,0,0,0.1)"}}>
                            <div style={{"width": "56px", "height": "56px", "background": "#7b4f9e", "borderRadius": "50%", "display": "flex", "alignItems": "center", "justifyContent": "center", "color": "white", "fontSize": "1.4rem", "fontWeight": "bold", "margin": "0 auto 0.75rem"}}>
                                {str(p["name"])[0:1] if p["name"] else "?"}
                            </div>
                            <div style={{"fontWeight": "bold", "marginBottom": "0.25rem"}}>{p["name"]}</div>
                            <div style={{"fontSize": "0.8rem", "color": "#666", "marginBottom": "0.25rem"}}>{p["headline"]}</div>
                            <div style={{"fontSize": "0.75rem", "color": "#888", "marginBottom": "0.75rem"}}>{p["location"]}</div>
                            {isConnected(str(p["id"])) and
                                <div style={{"padding": "0.4rem 1rem", "background": "#e8f0fe", "color": "#0a66c2", "borderRadius": "20px", "fontSize": "0.85rem"}}>Connected</div>
                            }
                            {not isConnected(str(p["id"])) and
                                <button
                                    onClick={lambda -> None { handleConnect(str(p["id"])); }}
                                    disabled={connectingId == p["id"]}
                                    style={{"padding": "0.4rem 1rem", "background": "white", "border": "1px solid #0a66c2", "borderRadius": "20px", "color": "#0a66c2", "cursor": "pointer", "fontWeight": "bold", "fontSize": "0.85rem"}}
                                >
                                    {connectingId == p["id"] and "Connecting..." or "+ Connect"}
                                </button>
                            }
                        </div>
                        for p in allProfiles
                    ]}
                </div>}
            </div>
        </div>;
    }

    # --------------------------------------------------------
    # ROOT APP COMPONENT
    # --------------------------------------------------------
    def:pub app() -> JsxElement {
        return <Router basename="/cl/app">
            <Routes>
                <Route path="/" element={<LoginPage />} />
                <Route path="/login" element={<LoginPage />} />
                <Route path="/signup" element={<SignupPage />} />
                <Route path="/feed" element={<FeedPage />} />
                <Route path="/profile" element={<ProfilePage />} />
                <Route path="/network" element={<NetworkPage />} />
            </Routes>
        </Router>;
    }
}
