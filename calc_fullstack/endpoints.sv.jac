"""Calculator App - Server-Side Logic.

Provides basic arithmetic operations and expression evaluation.
"""

# ========================================
# Walkers (API Operations)
# ========================================

walker:pub Add {
    """Add two numbers."""
    has a: float, b: float;
    can with Root entry {
        report {"result": self.a + self.b};
    }
}

walker:pub Subtract {
    """Subtract b from a."""
    has a: float, b: float;
    can with Root entry {
        report {"result": self.a - self.b};
    }
}

walker:pub Multiply {
    """Multiply two numbers."""
    has a: float, b: float;
    can with Root entry {
        report {"result": self.a * self.b};
    }
}

walker:pub Divide {
    """Divide a by b."""
    has a: float, b: float;
    can with Root entry {
        if self.b == 0.0 {
            report {"error": "Division by zero"};
        } else {
            report {"result": self.a / self.b};
        }
    }
}

walker:pub EvalExpr {
    """Evaluate a simple arithmetic expression (safe)."""
    has expr: str;
    can with Root entry {
        # Only allow numbers and operators
        allowed = set("0123456789.+-*/() ");
        if all([c in allowed for c in self.expr]) {
            result = eval(self.expr);
            if result is not None {
                report {"result": result};
            } else {
                report {"error": "Invalid expression"};
            }
        } else {
            report {"error": "Invalid characters in expression"};
        }
    }
}

def:pub EvalExprFn(expr: str) -> dict {
    allowed = set("0123456789.+-*/() ");
    if all([c in allowed for c in expr]) {
        try {
            result = eval(expr);
            if result is not None {
                return {"result": result};
            }
            return {"error": "Invalid expression"};
        } except Exception {
            return {"error": "Invalid expression"};
        }
    }
    return {"error": "Invalid characters in expression"};
}
