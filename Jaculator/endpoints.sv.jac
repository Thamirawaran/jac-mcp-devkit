"""Jaculator - Server-Side Calculator Backend.

Provides calculator operations: add, subtract, multiply, divide, and reset.
"""

# ========================================
# Data Models
# ========================================
node CalculatorState {
    has current_value: float = 0.0,
        last_operation: str = "",
        pending_value: float = 0.0;
}

# ========================================
# Walkers (Calculator Operations)
# ========================================
walker:pub Calculate {
    """Perform a calculator operation."""
    has operation: str,
        value: float = 0.0;

    can execute with Root entry {
        # Get or create calculator state
        calc_nodes = [-->][?:CalculatorState];
        if len(calc_nodes) == 0 {
            calc_created = here ++> CalculatorState();
            calc = calc_created[0];
        } else {
            calc = calc_nodes[0];
        }

        # Perform operation
        result = 0.0;
        match self.operation {
            case "add":
                calc.pending_value = calc.current_value;
                calc.current_value = self.value;
                calc.last_operation = "add";
                result = calc.current_value;
            case "subtract":
                calc.pending_value = calc.current_value;
                calc.current_value = self.value;
                calc.last_operation = "subtract";
                result = calc.current_value;
            case "multiply":
                calc.pending_value = calc.current_value;
                calc.current_value = self.value;
                calc.last_operation = "multiply";
                result = calc.current_value;
            case "divide":
                calc.pending_value = calc.current_value;
                calc.current_value = self.value;
                calc.last_operation = "divide";
                result = calc.current_value;
            case "equals":
                if calc.last_operation == "add" {
                    result = calc.pending_value + self.value;
                } elif calc.last_operation == "subtract" {
                    result = calc.pending_value - self.value;
                } elif calc.last_operation == "multiply" {
                    result = calc.pending_value * self.value;
                } elif calc.last_operation == "divide" {
                    if self.value != 0.0 {
                        result = calc.pending_value / self.value;
                    } else {
                        result = 0.0;
                    }
                } else {
                    result = self.value;
                }
                calc.current_value = result;
                calc.last_operation = "";
                calc.pending_value = 0.0;
            case "clear":
                calc.current_value = 0.0;
                calc.last_operation = "";
                calc.pending_value = 0.0;
                result = 0.0;
            case _:
                result = calc.current_value;
        }

        report result;
    }
}

walker:pub GetCalculatorState {
    """Get current calculator display value."""

    can fetch with Root entry {
        calc_nodes = [-->][?:CalculatorState];
        if len(calc_nodes) > 0 {
            report calc_nodes[0].current_value;
        } else {
            report 0.0;
        }
    }
}
