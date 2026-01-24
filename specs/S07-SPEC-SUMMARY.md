# S07 - Specification Summary: simple_tui

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_tui
**Date:** 2026-01-23

## Executive Summary

simple_tui is a modern Terminal User Interface library for Eiffel featuring an Elm-inspired architecture, double buffering, flexbox-like layouts, and a fluent builder API.

## Key Statistics

| Metric | Value |
|--------|-------|
| Total Classes | 24+ |
| Public Features | ~80 |
| Widget Types | 12+ |
| LOC (estimated) | ~4000 |
| Dependencies | base, simple_console, simple_logger |

## Architecture Overview

```
+-------------------+
|    TUI_QUICK      |  <-- Fluent Facade
+-------------------+
         |
+-------------------+
|  TUI_APPLICATION  |  <-- Event Loop
+-------------------+
         |
+-------------------+
|   TUI_BACKEND     |  <-- Terminal Abstraction
+-------------------+
         |
+-------------------+
|   TUI_BUFFER      |  <-- Double Buffering
+-------------------+
         |
+--------+----------+
| Widgets | Layouts |
+---------+---------+
```

## Core Value Proposition

1. **Fluent API** - Chainable widget construction
2. **No Flicker** - Double buffered rendering
3. **Flexbox Layouts** - VBox/HBox with gaps
4. **Rich Widgets** - 12+ widget types
5. **Modal Support** - Dialogs and message boxes
6. **Contract-Driven** - DBC throughout

## Contract Summary

| Category | Preconditions | Postconditions |
|----------|---------------|----------------|
| Creation | Title provided | Ready to build |
| Building | (none) | Current returned |
| Running | Root set, initialized | App running |
| Events | (none) | Event handled |

## Feature Categories

| Category | Count | Purpose |
|----------|-------|---------|
| Application | 6 | Lifecycle |
| Menu | 4 | Menu building |
| Layout | 4 | Container building |
| Widgets | 8+ | Widget creation |
| Retrieval | 4 | Widget access |
| Modal | 4 | Dialog management |
| Screen | 2 | Size queries |

## Widget Catalog

| Widget | Focusable | Input |
|--------|-----------|-------|
| TUI_LABEL | No | None |
| TUI_BUTTON | Yes | Click, Enter |
| TUI_TEXT_FIELD | Yes | Keyboard |
| TUI_CHECKBOX | Yes | Space, Click |
| TUI_LIST | Yes | Arrows, Click |
| TUI_PROGRESS | No | None |
| TUI_COMBO_BOX | Yes | Click, Arrows |
| TUI_MESSAGE_BOX | Yes | Enter, Escape |

## Constraints Summary

1. Single-threaded UI
2. Windows 10+ required (for now)
3. Minimum terminal: 40x10
4. Focus chain via Tab/Shift+Tab

## Known Limitations

1. Windows-only currently
2. No graphics/images
3. No animation framework
4. Basic styling only

## Future Directions

1. Cross-platform ANSI backend
2. Theme system with TOML
3. Animation framework
4. More widgets (tree, table)
