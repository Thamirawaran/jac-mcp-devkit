
sv import from endpoints { EvalExpr }



cl def:pub app -> JsxElement {
    has display: str = "",
        error: str = "",
        buttons: list[list[str]] = [
            ["7", "8", "9", "/"],
            ["4", "5", "6", "*"],
            ["1", "2", "3", "-"],
            ["0", ".", "=", "+"],
            ["C"]
        ];

    async def handleButton(val: str) {
        error = "";
        if val == "C" {
            display = "";
        }
        elif val == "=" {
            await evalExpr();
        }
        else {
            display = display + val;
        }
    }

    async def evalExpr() {
        if display.strip() == "" {
            return;
        }
        # no need to call root() here. root is enough
        resp = root spawn EvalExpr(expr=display);
        payload = None;

        if resp and "reports" in resp and resp["reports"] and resp["reports"].length > 0 {
            payload = resp["reports"][0];
        }
        elif resp and "result" in resp {
            payload = resp;
        }
        elif resp and "error" in resp {
            payload = resp;
        }

        if payload and "result" in payload {
            display = str(payload["result"]);
            return;
        }
        if payload and "error" in payload {
            error = str(payload["error"]);
            return;
        }
        error = "Invalid expression";
    }

    return <div
        style={{
            "maxWidth": "340px",
            "margin": "4rem auto",
            "padding": "2rem",
            "fontFamily": "system-ui, -apple-system, sans-serif",
            "backgroundColor": "#fff",
            "borderRadius": "12px",
            "boxShadow": "0 4px 6px rgba(0,0,0,0.1)"
        }}
    >
        <h1 style={{"textAlign": "center", "color": "#1a1a2e"}}>Jac Calculator</h1>
        <div
            style={{
                "margin": "1.5rem 0 1rem 0",
                "padding": "1rem",
                "backgroundColor": "#f8f9fa",
                "borderRadius": "8px",
                "fontSize": "2rem",
                "textAlign": "right",
                "minHeight": "2.5rem",
                "border": "1px solid #e9ecef"
            }}
        >
            {display}
        </div>
        {<div style={{"color": "#dc3545", "textAlign" : "center", "marginBottom": "1rem"}}>{error}</div> if error != "" else None}
        <div>
            {[
                <div style={{"display": "flex", "gap": "0.5rem", "marginBottom": "0.5rem"}}>
                    {[
                        <button
                            style={{
                                "flex": "1",
                                "padding": "1rem",
                                "fontSize": "1.25rem",
                                "backgroundColor": ("#3b82f6" if btn == "=" else "#ef4444" if btn == "C" else "#e5e7eb"),
                                "color": ("#fff" if btn == "=" || btn == "C" else "#333"),
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer",
                                "fontWeight": "bold"
                            }}
                            onClick={lambda -> None { handleButton(btn); }}
                            key={btn}
                        >
                            {btn}
                        </button>
                        for btn in row
                    ]}
                </div>
                for row in buttons
            ]}
        </div>
    </div>;
}
