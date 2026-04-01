"""
Calculator Full-Stack App in Jac
Backend: walkers for calculate operations
Frontend: cl block with React-style calculator UI
"""

import from time { strftime }

# ============================================================
# BACKEND: Data model and walker endpoints
# ============================================================

node CalcHistory {
    has expression: str;
    has result: str;
    has timestamp: str;
}

walker:pub calculate {
    has expression: str;

    can compute with Root entry {
        result: str = "";

        try {
            allowed_chars = set("0123456789+-*/.() ");
            if all(c in allowed_chars for c in self.expression) {
                val: float = float(eval(self.expression));
                raw: str = str(val);
                if "." in raw {
                    parts = raw.split(".");
                    decimal = parts[1].rstrip("0");
                    raw = parts[0] if decimal == "" else parts[0] + "." + decimal;
                }
                result = raw;
                ts: str = strftime("%H:%M:%S");
                root() ++> CalcHistory(
                    expression=self.expression,
                    result=result,
                    timestamp=ts
                );
                report {"success": True, "result": result, "expression": self.expression};
            } else {
                report {"success": False, "result": "Error", "expression": self.expression};
            }
        } except ZeroDivisionError {
            report {"success": False, "result": "Div/0", "expression": self.expression};
        }
    }
}

walker:pub get_history {
    has items: list = [];

    can fetch with Root entry {
        visit [-->];
    }

    can collect with CalcHistory entry {
        self.items.append({
            "expression": here.expression,
            "result": here.result,
            "timestamp": here.timestamp
        });
    }

    can finish with Root exit {
        report self.items;
    }
}

walker:pub clear_history {
    can wipe with Root entry {
        to_del: list = [];
        for h in [-->[?:CalcHistory]] {
            to_del.append(h);
        }
        for h in to_del {
            del h;
        }
        report {"success": True};
    }
}

# ============================================================
# FRONTEND: Calculator UI
# ============================================================

cl {
    def:pub app() -> JsxElement {
        has display: str = "0";
        has expression: str = "";
        has just_evaluated: bool = False;
        has loading: bool = False;
        has history: object = [];
        has show_history: bool = False;
        has has_error: bool = False;

        async can with entry {
            res0: object = root spawn get_history();
            rpts0: list = getattr(res0, "reports", []);
            if rpts0 {
                history = rpts0[0];
            }
        }

        async def do_calculate() -> None {
            if expression == "" {
                return;
            }
            loading = True;
            res1: object = root spawn calculate(expression=expression);
            loading = False;
            rpts1: list = getattr(res1, "reports", []);
            if rpts1 {
                data: object = rpts1[0];
                if data["success"] {
                    display = str(data["result"]);
                    expression = str(data["result"]);
                    just_evaluated = True;
                    has_error = False;
                    res2: object = root spawn get_history();
                    rpts2: list = getattr(res2, "reports", []);
                    if rpts2 {
                        history = rpts2[0];
                    }
                } else {
                    display = str(data["result"]);
                    has_error = True;
                    just_evaluated = False;
                }
            }
        }

        async def do_clear_history() -> None {
            root spawn clear_history();
            history = [];
        }

        # Inline styles
        nb: dict = {"width": "70px", "height": "70px", "fontSize": "22px", "fontWeight": "600", "border": "none", "borderRadius": "50%", "cursor": "pointer", "backgroundColor": "#333333", "color": "#ffffff"};
        op: dict = {"width": "70px", "height": "70px", "fontSize": "22px", "fontWeight": "600", "border": "none", "borderRadius": "50%", "cursor": "pointer", "backgroundColor": "#ff9f0a", "color": "#ffffff"};
        fn: dict = {"width": "70px", "height": "70px", "fontSize": "22px", "fontWeight": "600", "border": "none", "borderRadius": "50%", "cursor": "pointer", "backgroundColor": "#a5a5a5", "color": "#000000"};
        eq: dict = {"width": "70px", "height": "70px", "fontSize": "22px", "fontWeight": "600", "border": "none", "borderRadius": "50%", "cursor": "pointer", "backgroundColor": "#ff9f0a", "color": "#ffffff"};
        zr: dict = {"width": "150px", "height": "70px", "fontSize": "22px", "fontWeight": "600", "border": "none", "borderRadius": "35px", "cursor": "pointer", "backgroundColor": "#333333", "color": "#ffffff", "paddingLeft": "24px", "textAlign": "left"};

        return <div style={{"minHeight": "100vh", "backgroundColor": "#1c1c1e", "display": "flex", "flexDirection": "column", "alignItems": "center", "justifyContent": "center", "fontFamily": "sans-serif", "padding": "20px"}}>
            <h1 style={{"color": "#ffffff", "marginBottom": "24px", "fontSize": "28px", "fontWeight": "300", "letterSpacing": "2px"}}>JAC CALCULATOR</h1>

            <div style={{"backgroundColor": "#2c2c2e", "borderRadius": "20px", "padding": "20px", "width": "340px", "boxShadow": "0 20px 60px rgba(0,0,0,0.5)"}}>
                <div style={{"backgroundColor": "#1c1c1e", "borderRadius": "12px", "padding": "16px 20px", "marginBottom": "16px", "minHeight": "90px", "display": "flex", "flexDirection": "column", "alignItems": "flex-end", "justifyContent": "flex-end"}}>
                    <div style={{"color": "#888", "fontSize": "14px", "marginBottom": "4px"}}>
                        {(expression if not just_evaluated else "")}
                    </div>
                    <div style={{"color": ("#ff453a" if has_error else "#ffffff"), "fontSize": "42px", "fontWeight": "200", "textAlign": "right"}}>
                        {("..." if loading else display)}
                    </div>
                </div>

                <div style={{"display": "flex", "gap": "10px", "marginBottom": "10px", "justifyContent": "space-between"}}>
                    <button style={fn} onClick={lambda -> None { display = "0"; expression = ""; just_evaluated = False; has_error = False; }}>AC</button>
                    <button style={fn} onClick={lambda -> None {
                        if display != "0" and display != "" {
                            if expression.startswith("-") { expression = expression[1:]; } else { expression = "-" + expression; }
                            display = expression;
                        }
                    }}>+/-</button>
                    <button style={fn} onClick={lambda -> None {
                        if expression != "" { expression = "(" + expression + ")/100"; display = expression; }
                    }}>%</button>
                    <button style={op} onClick={lambda -> None {
                        just_evaluated = False;
                        if expression == "" { base: str = display; expression = base + "/"; } else { n = len(expression); lc: str = expression[n-1]; p: str = expression[0:n-1]; expression = (p + "/") if lc in ["+","-","*","/"] else (expression + "/"); }
                        display = expression;
                    }}>/</button>
                </div>

                <div style={{"display": "flex", "gap": "10px", "marginBottom": "10px", "justifyContent": "space-between"}}>
                    <button style={nb} onClick={lambda -> None {
                        has_error = False;
                        if just_evaluated { expression = "7"; display = "7"; just_evaluated = False; } else { if display == "0" { expression = "7"; display = "7"; } else { expression = expression + "7"; display = expression; } }
                    }}>7</button>
                    <button style={nb} onClick={lambda -> None {
                        has_error = False;
                        if just_evaluated { expression = "8"; display = "8"; just_evaluated = False; } else { if display == "0" { expression = "8"; display = "8"; } else { expression = expression + "8"; display = expression; } }
                    }}>8</button>
                    <button style={nb} onClick={lambda -> None {
                        has_error = False;
                        if just_evaluated { expression = "9"; display = "9"; just_evaluated = False; } else { if display == "0" { expression = "9"; display = "9"; } else { expression = expression + "9"; display = expression; } }
                    }}>9</button>
                    <button style={op} onClick={lambda -> None {
                        just_evaluated = False;
                        if expression == "" { base2: str = display; expression = base2 + "*"; } else { n2 = len(expression); lc2: str = expression[n2-1]; p2: str = expression[0:n2-1]; expression = (p2 + "*") if lc2 in ["+","-","*","/"] else (expression + "*"); }
                        display = expression;
                    }}>*</button>
                </div>

                <div style={{"display": "flex", "gap": "10px", "marginBottom": "10px", "justifyContent": "space-between"}}>
                    <button style={nb} onClick={lambda -> None {
                        has_error = False;
                        if just_evaluated { expression = "4"; display = "4"; just_evaluated = False; } else { if display == "0" { expression = "4"; display = "4"; } else { expression = expression + "4"; display = expression; } }
                    }}>4</button>
                    <button style={nb} onClick={lambda -> None {
                        has_error = False;
                        if just_evaluated { expression = "5"; display = "5"; just_evaluated = False; } else { if display == "0" { expression = "5"; display = "5"; } else { expression = expression + "5"; display = expression; } }
                    }}>5</button>
                    <button style={nb} onClick={lambda -> None {
                        has_error = False;
                        if just_evaluated { expression = "6"; display = "6"; just_evaluated = False; } else { if display == "0" { expression = "6"; display = "6"; } else { expression = expression + "6"; display = expression; } }
                    }}>6</button>
                    <button style={op} onClick={lambda -> None {
                        just_evaluated = False;
                        if expression == "" { base3: str = display; expression = base3 + "-"; } else { n3 = len(expression); lc3: str = expression[n3-1]; p3: str = expression[0:n3-1]; expression = (p3 + "-") if lc3 in ["+","-","*","/"] else (expression + "-"); }
                        display = expression;
                    }}>-</button>
                </div>

                <div style={{"display": "flex", "gap": "10px", "marginBottom": "10px", "justifyContent": "space-between"}}>
                    <button style={nb} onClick={lambda -> None {
                        has_error = False;
                        if just_evaluated { expression = "1"; display = "1"; just_evaluated = False; } else { if display == "0" { expression = "1"; display = "1"; } else { expression = expression + "1"; display = expression; } }
                    }}>1</button>
                    <button style={nb} onClick={lambda -> None {
                        has_error = False;
                        if just_evaluated { expression = "2"; display = "2"; just_evaluated = False; } else { if display == "0" { expression = "2"; display = "2"; } else { expression = expression + "2"; display = expression; } }
                    }}>2</button>
                    <button style={nb} onClick={lambda -> None {
                        has_error = False;
                        if just_evaluated { expression = "3"; display = "3"; just_evaluated = False; } else { if display == "0" { expression = "3"; display = "3"; } else { expression = expression + "3"; display = expression; } }
                    }}>3</button>
                    <button style={op} onClick={lambda -> None {
                        just_evaluated = False;
                        if expression == "" { base4: str = display; expression = base4 + "+"; } else { n4 = len(expression); lc4: str = expression[n4-1]; p4: str = expression[0:n4-1]; expression = (p4 + "+") if lc4 in ["+","-","*","/"] else (expression + "+"); }
                        display = expression;
                    }}>+</button>
                </div>

                <div style={{"display": "flex", "gap": "10px", "justifyContent": "space-between"}}>
                    <button style={zr} onClick={lambda -> None {
                        has_error = False;
                        if just_evaluated { expression = "0"; display = "0"; just_evaluated = False; } else { if display != "0" { expression = expression + "0"; display = expression; } }
                    }}>0</button>
                    <button style={nb} onClick={lambda -> None {
                        has_error = False;
                        if just_evaluated { expression = "."; display = "."; just_evaluated = False; } else { expression = expression + "."; display = expression; }
                    }}>.</button>
                    <button style={eq} onClick={lambda -> None { do_calculate(); }}>=</button>
                </div>

                <div style={{"display": "flex", "gap": "10px", "marginTop": "10px", "justifyContent": "space-between"}}>
                    <button style={{"flex": "1", "height": "44px", "backgroundColor": "#48484a", "color": "#fff", "border": "none", "borderRadius": "10px", "fontSize": "16px", "cursor": "pointer"}}
                        onClick={lambda -> None {
                            has_error = False; n5 = len(expression);
                            if n5 > 1 { expression = expression[0:n5-1]; display = expression; } else { expression = ""; display = "0"; }
                        }}>Backspace</button>
                    <button style={{"flex": "1", "height": "44px", "backgroundColor": "#48484a", "color": "#aaa", "border": "none", "borderRadius": "10px", "fontSize": "14px", "cursor": "pointer"}}
                        onClick={lambda -> None { show_history = not show_history; }}>
                        {("Hide History" if show_history else "History")}
                    </button>
                </div>
            </div>

            {(show_history and
                <div style={{"backgroundColor": "#2c2c2e", "borderRadius": "16px", "padding": "16px", "marginTop": "16px", "width": "340px", "maxHeight": "300px", "overflowY": "auto"}}>
                    <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "12px"}}>
                        <span style={{"color": "#fff", "fontWeight": "600", "fontSize": "16px"}}>History</span>
                        <button style={{"backgroundColor": "#ff453a", "color": "#fff", "border": "none", "borderRadius": "8px", "padding": "4px 12px", "cursor": "pointer"}}
                            onClick={lambda -> None { do_clear_history(); }}>Clear</button>
                    </div>
                    {(len(list(history)) == 0 and <p style={{"color": "#666", "textAlign": "center", "fontSize": "14px"}}>No history yet</p>)}
                    {(len(list(history)) > 0 and
                        <div>
                            {[
                                <div key={str(i)} style={{"borderBottom": "1px solid #3a3a3c", "paddingBottom": "8px", "marginBottom": "8px"}}>
                                    <div style={{"color": "#888", "fontSize": "12px"}}>{str(getattr(h, "timestamp", ""))}</div>
                                    <div style={{"color": "#aaa", "fontSize": "14px"}}>{str(getattr(h, "expression", ""))}</div>
                                    <div style={{"color": "#ff9f0a", "fontSize": "18px", "fontWeight": "600"}}>= {str(getattr(h, "result", ""))}</div>
                                </div>
                                for (i, h) in enumerate(list(history))
                            ]}
                        </div>
                    )}
                </div>
            )}
            <p style={{"color": "#555", "marginTop": "20px", "fontSize": "12px"}}>Built with Jac full-stack</p>
        </div>;
    }
}
