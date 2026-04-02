"""Jaculator - Client-Side Calculator UI."""

sv import from endpoints { Calculate, GetCalculatorState }

def:pub app() -> JsxElement {
    has current_input: str = "0",
        pending_value: float = 0.0,
        pending_operation: str = "",
        should_reset_display: bool = False;

    def format_number(num: float) -> str {
        num_str = str(num);
        if num == int(num) {
            return str(int(num));
        }
        return num_str;
    }

    def get_display_value() -> str {
        if current_input != "" {
            return current_input;
        } elif pending_operation != "" {
            return format_number(pending_value) + " " + get_op_symbol(pending_operation);
        } else {
            return "0";
        }
    }

    def get_op_symbol(op: str) -> str {
        if op == "add" {
            return "+";
        } elif op == "subtract" {
            return "−";
        } elif op == "multiply" {
            return "×";
        } elif op == "divide" {
            return "÷";
        } else {
            return "";
        }
    }

    def press_number(num: str) {
        if should_reset_display {
            current_input = "";
            should_reset_display = False;
        }

        if num == "." {
            if "." not in current_input {
                if current_input == "" {
                    current_input = "0.";
                } else {
                    current_input = current_input + ".";
                }
            }
        } elif current_input == "0" and num != "0" {
            current_input = num;
        } elif current_input == "" and num == "0" {
            current_input = "0";
        } else {
            current_input = current_input + num;
        }
    }

    def perform_operation(op: str) {
        if current_input == "" {
            if pending_operation != "" {
                pending_operation = op;
            }
            return;
        }

        input_num = 0.0;
        try {
            input_num = float(current_input);
        } except ValueError {
            return;
        }

        if pending_operation != "" and pending_operation != "" {
            result = 0.0;
            if pending_operation == "add" {
                result = pending_value + input_num;
            } elif pending_operation == "subtract" {
                result = pending_value - input_num;
            } elif pending_operation == "multiply" {
                result = pending_value * input_num;
            } elif pending_operation == "divide" {
                if input_num != 0.0 {
                    result = pending_value / input_num;
                } else {
                    current_input = "Error: Div by 0";
                    should_reset_display = True;
                    return;
                }
            }
            pending_value = result;
            current_input = "";
        } else {
            pending_value = input_num;
            current_input = "";
        }

        pending_operation = op;
        should_reset_display = False;
    }

    def calculate_equals() {
        if pending_operation == "" or current_input == "" {
            return;
        }

        input_num = 0.0;
        try {
            input_num = float(current_input);
        } except ValueError {
            return;
        }

        result = 0.0;
        if pending_operation == "add" {
            result = pending_value + input_num;
        } elif pending_operation == "subtract" {
            result = pending_value - input_num;
        } elif pending_operation == "multiply" {
            result = pending_value * input_num;
        } elif pending_operation == "divide" {
            if input_num != 0.0 {
                result = pending_value / input_num;
            } else {
                current_input = "Error: Div by 0";
                pending_operation = "";
                should_reset_display = True;
                return;
            }
        }

        current_input = format_number(result);
        pending_operation = "";
        pending_value = 0.0;
        should_reset_display = True;
    }

    def clear_display() {
        current_input = "0";
        pending_value = 0.0;
        pending_operation = "";
        should_reset_display = False;
    }

    display_value = get_display_value();

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
                        "wordBreak": "break-all",
                        "overflow": "hidden"
                    }}
                >
                    {display_value}
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
                            onClick={lambda -> None { perform_operation("divide"); }}
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
                            onClick={lambda -> None { perform_operation("multiply"); }}
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
                            onClick={lambda -> None { perform_operation("subtract"); }}
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
                            onClick={lambda -> None { perform_operation("add"); }}
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
