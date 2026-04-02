# Jaculator

A full-stack calculator application built with Jac language, featuring a React-style frontend and server-side calculation logic.

## Project Structure

```
Jaculator/
├── jac.toml              # Project configuration
├── main.jac              # Main entry point (combines server + client)
├── endpoints.sv.jac      # Server-side calculator backend (walkers + data models)
├── frontend.cl.jac       # Client-side calculator UI (React JSX)
├── frontend.impl.jac     # Implementation stubs
├── components/           # Reusable client components directory
└── assets/               # Static assets (images, fonts, etc.)
```

## Getting Started

Start the development server with the `jaclocal` conda environment:

```bash
conda activate jaclocal
jac start main.jac
```

Then open your browser to the URL shown in the terminal (typically `http://localhost:8080`).

## Features

- **Full-Stack Calculation**: Server-side walkers handle calculation logic
- **React-Style UI**: Client-side JSX component with real-time display updates
- **Grid Layout**: Professional calculator design with organized button layout
- **Operations Supported**:
  - Addition (+)
  - Subtraction (−)
  - Multiplication (×)
  - Division (÷)
  - Decimal values (.)
  - Clear function

## Architecture

### Server-Side (endpoints.sv.jac)

- **`CalculatorState` Node**: Stores current value, pending operation, and pending value
- **`Calculate` Walker**: Public walker that performs calculator operations
- **`GetCalculatorState` Walker**: Fetches the current display value

Operations handled:
- `add`, `subtract`, `multiply`, `divide` - Set pending operation
- `equals` - Perform pending calculation
- `clear` - Reset calculator state

### Client-Side (frontend.cl.jac)

- **React-style UI**: Built with JSX syntax in a single `app()` component
- **State Management**: Uses `has` declarations for reactive state
- **Event Handlers**: Lambda functions handle button clicks
- **Grid Layout**: CSS Grid for 4-column button layout

### Jac Patterns Demonstrated

- **`sv import`**: Importing server-side walkers into client code
- **`root() spawn`**: Calling server walkers from client UI
- **`has` State**: Client-side reactive state management
- **JSX Comprehensions**: Dynamic button rendering with list comprehensions
- **Inline Styling**: CSS-in-JS for component styling
- **Async Functions**: Async handler functions in client components

## Building

To build the project:

```bash
jac build main.jac
```

## Testing

To run tests (if any):

```bash
jac test
```

## Notes

- The calculator maintains state on the server per session
- All calculations are performed server-side via walker invocations
- The UI displays the calculated result in the display area at the top
