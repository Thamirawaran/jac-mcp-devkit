"""Jaculator - Client-Side Calculator UI."""

sv import from endpoints { Calculate, GetCalculatorState }

def:pub app() -> JsxElement {
    has display: str = "0",
        current_input: str = "",
        pending_operation: str = "",
        pending_value: float = 0.0;

    async def perform_operation(op: str, value: str) {
        num_val = 0.0;
        if value and value != "0" {
            num_val = float(value);
        }
        pending_operation = op;
        pending_value = num_val;
        current_input = "";
        display = str(pending_value);
    }

    async def press_number(num: str) {
        if num == "." {
            if "." not in current_input {
                current_input = current_input + num;
            }
        } elif current_input == "" and num != "0" {
            current_input = num;
        } elif current_input == "" and num == "0" {
            current_input = "0";
        } else {
            current_input = current_input + num;
        }
        display = current_input if current_input else "0";
    }

    async def calculate_equals() {
        if pending_operation and current_input {
            num_val = float(current_input);
            # root doesn't need to be called as a function here, just use root spawn
            root spawn Calculate(operation=pending_operation, value=num_val);
            display = str(pending_value + num_val);
            current_input = "";
            pending_operation = "";
            pending_value = 0.0;
        }
    }

    async def clear_display() {
        # root doesn't need to be called as a function here, just use root spawn
        root spawn Calculate(operation="clear", value=0.0);
        display = "0";
        current_input = "";
        pending_operation = "";
        pending_value = 0.0;
    }

    return
        <div
            style={{
                "display": "flex",
                "justifyContent": "center",
                "alignItems": "center",
                "minHeight": "100vh",
                "backgroundColor": "#f0f0f0",
                "fontFamily": "system-ui, -apple-system, sans-serif"
            }}
        >
            <div
                style={{
                    "width": "320px",
                    "backgroundColor": "white",
                    "borderRadius": "12px",
                    "boxShadow": "0 8px 24px rgba(0,0,0,0.15)",
                    "padding": "20px",
                    "boxSizing": "border-box"
                }}
            >
                <h1
                    style={{
                        "textAlign": "center",
                        "marginTop": "0",
                        "marginBottom": "1.5rem",
                        "fontSize": "1.5rem",
                        "color": "#333"
                    }}
                >
                    Jaculator
                </h1>

                <div
                    style={{
                        "backgroundColor": "#1a1a2e",
                        "color": "white",
                        "fontSize": "2rem",
                        "padding": "20px",
                        "borderRadius": "8px",
                        "textAlign": "right",
                        "marginBottom": "1rem",
                        "minHeight": "60px",
                        "display": "flex",
                        "alignItems": "center",
                        "justifyContent": "flex-end",
                        "wordWrap": "break-word",
                        "wordBreak": "break-all"
                    }}
                >
                    {display}
                </div>

                <div
                    style={{
                        "display": "grid",
                        "gridTemplateColumns": "1fr 1fr 1fr 1fr",
                        "gap": "8px"
                    }}
                >
                    {[
                        <button
                            key="clear"
                            onClick={lambda -> None { clear_display(); }}
                            style={{
                                "gridColumn": "1 / 3",
                                "padding": "16px",
                                "fontSize": "1.1rem",
                                "fontWeight": "bold",
                                "backgroundColor": "#ff6b6b",
                                "color": "white",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer",
                                "transition": "backgroundColor 0.2s"
                            }}
                        >
                            Clear
                        </button>,
                        <button
                            key="divide"
                            onClick={lambda -> None { perform_operation("divide", current_input); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "fontWeight": "bold",
                                "backgroundColor": "#ffa94d",
                                "color": "white",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            ÷
                        </button>,
                        <button
                            key="multiply"
                            onClick={lambda -> None { perform_operation("multiply", current_input); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "fontWeight": "bold",
                                "backgroundColor": "#ffa94d",
                                "color": "white",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            ×
                        </button>,
                        <button
                            key="7"
                            onClick={lambda -> None { press_number("7"); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "backgroundColor": "#e9ecef",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            7
                        </button>,
                        <button
                            key="8"
                            onClick={lambda -> None { press_number("8"); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "backgroundColor": "#e9ecef",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            8
                        </button>,
                        <button
                            key="9"
                            onClick={lambda -> None { press_number("9"); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "backgroundColor": "#e9ecef",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            9
                        </button>,
                        <button
                            key="subtract"
                            onClick={lambda -> None { perform_operation("subtract", current_input); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "fontWeight": "bold",
                                "backgroundColor": "#ffa94d",
                                "color": "white",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            −
                        </button>,
                        <button
                            key="4"
                            onClick={lambda -> None { press_number("4"); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "backgroundColor": "#e9ecef",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            4
                        </button>,
                        <button
                            key="5"
                            onClick={lambda -> None { press_number("5"); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "backgroundColor": "#e9ecef",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            5
                        </button>,
                        <button
                            key="6"
                            onClick={lambda -> None { press_number("6"); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "backgroundColor": "#e9ecef",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            6
                        </button>,
                        <button
                            key="add"
                            onClick={lambda -> None { perform_operation("add", current_input); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "fontWeight": "bold",
                                "backgroundColor": "#ffa94d",
                                "color": "white",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            +
                        </button>,
                        <button
                            key="1"
                            onClick={lambda -> None { press_number("1"); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "backgroundColor": "#e9ecef",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            1
                        </button>,
                        <button
                            key="2"
                            onClick={lambda -> None { press_number("2"); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "backgroundColor": "#e9ecef",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            2
                        </button>,
                        <button
                            key="3"
                            onClick={lambda -> None { press_number("3"); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "backgroundColor": "#e9ecef",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            3
                        </button>,
                        <button
                            key="equals"
                            onClick={lambda -> None { calculate_equals(); }}
                            style={{
                                "gridRow": "5 / 6",
                                "gridColumn": "4 / 5",
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "fontWeight": "bold",
                                "backgroundColor": "#51cf66",
                                "color": "white",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            =
                        </button>,
                        <button
                            key="0"
                            onClick={lambda -> None { press_number("0"); }}
                            style={{
                                "gridColumn": "1 / 3",
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "backgroundColor": "#e9ecef",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            0
                        </button>,
                        <button
                            key="decimal"
                            onClick={lambda -> None { press_number("."); }}
                            style={{
                                "padding": "16px",
                                "fontSize": "1.2rem",
                                "backgroundColor": "#e9ecef",
                                "border": "none",
                                "borderRadius": "8px",
                                "cursor": "pointer"
                            }}
                        >
                            .
                        </button>
                    ]}
                </div>
            </div>
        </div>;
}
