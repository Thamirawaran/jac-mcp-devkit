"""LearnHub LMS - A Learning Management System built with Jac."""

import from datetime { datetime }

cl import "./styles.css";
cl import from .lms_fe { App }

# ==================== DATA MODELS ====================

node Course {
    has title: str,
        description: str = "",
        category: str = "General",
        instructor_name: str = "",
        created_at: str = "",
        published: bool = False;
}

node Lesson {
    has title: str,
        content: str = "",
        lesson_order: int = 0,
        duration_minutes: int = 0,
        completed: bool = False;
}

node Assignment {
    has title: str,
        description: str = "",
        due_date: str = "",
        max_score: int = 100;
}

node Submission {
    has content: str = "",
        score: int = 0,
        graded: bool = False,
        submitted_at: str = "";
}

node Discussion {
    has title: str;
}

node DiscussionPost {
    has content: str,
        author: str = "",
        created_at: str = "";
}

# ==================== HELPER ====================

def get_now -> str {
    return str(datetime.now());
}

# ==================== COURSE API ====================

"""Create a new course."""
def:pub create_course(title: str, description: str = "", category: str = "General", instructor_name: str = "") -> dict {
    now = get_now();
    course = (root ++> Course(
        title=title,
        description=description,
        category=category,
        instructor_name=instructor_name,
        created_at=now
    ))[0];
    return {
        "id": jid(course),
        "title": course.title,
        "description": course.description,
        "category": course.category,
        "instructor_name": course.instructor_name,
        "created_at": course.created_at,
        "published": course.published
    };
}

"""Get all courses."""
def:pub get_courses -> list {
    result: list = [];
    for c in [root-->[?:Course]] {
        lesson_count = len([c-->[?:Lesson]]);
        assignment_count = len([c-->[?:Assignment]]);
        result.append({
            "id": jid(c),
            "title": c.title,
            "description": c.description,
            "category": c.category,
            "instructor_name": c.instructor_name,
            "created_at": c.created_at,
            "published": c.published,
            "lesson_count": lesson_count,
            "assignment_count": assignment_count
        });
    }
    return result;
}

"""Get a single course with details."""
def:pub get_course(course_id: str) -> dict {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            lessons = [l for l in [c-->[?:Lesson]]];
            assignments = [a for a in [c-->[?:Assignment]]];
            discussions = [d for d in [c-->[?:Discussion]]];
            completed_count = len([l for l in lessons if l.completed]);
            total = len(lessons);
            return {
                "id": jid(c),
                "title": c.title,
                "description": c.description,
                "category": c.category,
                "instructor_name": c.instructor_name,
                "created_at": c.created_at,
                "published": c.published,
                "lesson_count": total,
                "assignment_count": len(assignments),
                "discussion_count": len(discussions),
                "completed_lessons": completed_count,
                "progress": (completed_count * 100 // total) if total > 0 else 0
            };
        }
    }
    return {};
}

"""Update a course."""
def:pub update_course(course_id: str, title: str = "", description: str = "", category: str = "") -> dict {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            if title {
                c.title = title;
            }
            if description {
                c.description = description;
            }
            if category {
                c.category = category;
            }
            return {
                "id": jid(c),
                "title": c.title,
                "description": c.description,
                "category": c.category
            };
        }
    }
    return {};
}

"""Toggle course publish status."""
def:pub toggle_publish(course_id: str) -> dict {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            c.published = not c.published;
            return {"id": jid(c), "published": c.published};
        }
    }
    return {};
}

"""Delete a course."""
def:pub delete_course(course_id: str) -> dict {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            del c;
            return {"deleted": course_id};
        }
    }
    return {};
}

# ==================== LESSON API ====================

"""Add a lesson to a course."""
def:pub add_lesson(course_id: str, title: str, content: str = "", lesson_order: int = 0, duration_minutes: int = 0) -> dict {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            lesson = (c ++> Lesson(
                title=title,
                content=content,
                lesson_order=lesson_order,
                duration_minutes=duration_minutes
            ))[0];
            return {
                "id": jid(lesson),
                "title": lesson.title,
                "content": lesson.content,
                "lesson_order": lesson.lesson_order,
                "duration_minutes": lesson.duration_minutes,
                "completed": lesson.completed
            };
        }
    }
    return {};
}

"""Get all lessons for a course."""
def:pub get_lessons(course_id: str) -> list {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            result: list = [];
            for l in [c-->[?:Lesson]] {
                result.append({
                    "id": jid(l),
                    "title": l.title,
                    "content": l.content,
                    "lesson_order": l.lesson_order,
                    "duration_minutes": l.duration_minutes,
                    "completed": l.completed
                });
            }
            result.sort(key=lambda x: x["lesson_order"]);
            return result;
        }
    }
    return [];
}

"""Get a single lesson."""
def:pub get_lesson(course_id: str, lesson_id: str) -> dict {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            for l in [c-->[?:Lesson]] {
                if jid(l) == lesson_id {
                    return {
                        "id": jid(l),
                        "title": l.title,
                        "content": l.content,
                        "lesson_order": l.lesson_order,
                        "duration_minutes": l.duration_minutes,
                        "completed": l.completed
                    };
                }
            }
        }
    }
    return {};
}

"""Toggle lesson completion."""
def:pub toggle_lesson_complete(course_id: str, lesson_id: str) -> dict {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            for l in [c-->[?:Lesson]] {
                if jid(l) == lesson_id {
                    l.completed = not l.completed;
                    return {"id": jid(l), "completed": l.completed};
                }
            }
        }
    }
    return {};
}

"""Delete a lesson."""
def:pub delete_lesson(course_id: str, lesson_id: str) -> dict {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            for l in [c-->[?:Lesson]] {
                if jid(l) == lesson_id {
                    del l;
                    return {"deleted": lesson_id};
                }
            }
        }
    }
    return {};
}

# ==================== ASSIGNMENT API ====================

"""Add an assignment to a course."""
def:pub add_assignment(course_id: str, title: str, description: str = "", due_date: str = "", max_score: int = 100) -> dict {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            assignment = (c ++> Assignment(
                title=title,
                description=description,
                due_date=due_date,
                max_score=max_score
            ))[0];
            return {
                "id": jid(assignment),
                "title": assignment.title,
                "description": assignment.description,
                "due_date": assignment.due_date,
                "max_score": assignment.max_score
            };
        }
    }
    return {};
}

"""Get all assignments for a course."""
def:pub get_assignments(course_id: str) -> list {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            result: list = [];
            for a in [c-->[?:Assignment]] {
                submissions = [s for s in [a-->[?:Submission]]];
                latest: dict | None = None;
                if len(submissions) > 0 {
                    s = submissions[-1];
                    latest = {
                        "id": jid(s),
                        "content": s.content,
                        "score": s.score,
                        "graded": s.graded,
                        "submitted_at": s.submitted_at
                    };
                }
                result.append({
                    "id": jid(a),
                    "title": a.title,
                    "description": a.description,
                    "due_date": a.due_date,
                    "max_score": a.max_score,
                    "submission_count": len(submissions),
                    "latest_submission": latest
                });
            }
            return result;
        }
    }
    return [];
}

"""Submit an assignment."""
def:pub submit_assignment(course_id: str, assignment_id: str, content: str) -> dict {
    now = get_now();
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            for a in [c-->[?:Assignment]] {
                if jid(a) == assignment_id {
                    submission = (a ++> Submission(
                        content=content,
                        submitted_at=now
                    ))[0];
                    return {
                        "id": jid(submission),
                        "content": submission.content,
                        "submitted_at": submission.submitted_at,
                        "graded": submission.graded,
                        "score": submission.score
                    };
                }
            }
        }
    }
    return {};
}

"""Grade a submission."""
def:pub grade_submission(course_id: str, assignment_id: str, submission_id: str, score: int) -> dict {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            for a in [c-->[?:Assignment]] {
                if jid(a) == assignment_id {
                    for s in [a-->[?:Submission]] {
                        if jid(s) == submission_id {
                            s.score = score;
                            s.graded = True;
                            return {"id": jid(s), "score": s.score, "graded": s.graded};
                        }
                    }
                }
            }
        }
    }
    return {};
}

# ==================== DISCUSSION API ====================

"""Add a discussion to a course."""
def:pub add_discussion(course_id: str, title: str) -> dict {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            disc = (c ++> Discussion(title=title))[0];
            return {"id": jid(disc), "title": disc.title};
        }
    }
    return {};
}

"""Get all discussions for a course."""
def:pub get_discussions(course_id: str) -> list {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            result: list = [];
            for d in [c-->[?:Discussion]] {
                post_count = len([d-->[?:DiscussionPost]]);
                result.append({
                    "id": jid(d),
                    "title": d.title,
                    "post_count": post_count
                });
            }
            return result;
        }
    }
    return [];
}

"""Add a post to a discussion."""
def:pub add_discussion_post(course_id: str, discussion_id: str, content: str, author: str = "") -> dict {
    now = get_now();
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            for d in [c-->[?:Discussion]] {
                if jid(d) == discussion_id {
                    post = (d ++> DiscussionPost(
                        content=content,
                        author=author,
                        created_at=now
                    ))[0];
                    return {
                        "id": jid(post),
                        "content": post.content,
                        "author": post.author,
                        "created_at": post.created_at
                    };
                }
            }
        }
    }
    return {};
}

"""Get posts for a discussion."""
def:pub get_discussion_posts(course_id: str, discussion_id: str) -> list {
    for c in [root-->[?:Course]] {
        if jid(c) == course_id {
            for d in [c-->[?:Discussion]] {
                if jid(d) == discussion_id {
                    return [
                        {
                            "id": jid(p),
                            "content": p.content,
                            "author": p.author,
                            "created_at": p.created_at
                        }
                        for p in [d-->[?:DiscussionPost]]
                    ];
                }
            }
        }
    }
    return [];
}

# ==================== CLIENT ENTRY POINT ====================

cl def:pub app -> Any {
    return App();
}
