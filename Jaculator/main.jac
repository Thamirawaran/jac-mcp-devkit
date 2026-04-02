"""Jaculator - Entry Point.

Combines server-side calculator backend with client-side UI.
"""

# Import server-side calculator operations
sv {
    import from endpoints { CalculatorState, Calculate, GetCalculatorState }
}

# Client-side UI
cl {
    import from .frontend { app as ClientApp }

    def:pub app() -> JsxElement {
        return <ClientApp />;
    }
}
