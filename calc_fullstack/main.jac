"""calc_fullstack - Entry Point.

Combines server-side endpoints with client-side UI.
"""

# Import server-side calculator endpoints
sv {
    import from endpoints { Add, Subtract, Multiply, Divide, EvalExpr }
}

# Client-side UI
cl {
    import from .frontend { app as ClientApp }

    def:pub app -> any {
        return
            <ClientApp />;
    }
}
