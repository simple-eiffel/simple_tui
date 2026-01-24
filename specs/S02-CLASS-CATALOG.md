# S02 - Class Catalog: simple_tui

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_tui
**Date:** 2026-01-23

## Class Hierarchy

```
TUI_QUICK (fluent facade)
|
+-- Core
|   +-- TUI_APPLICATION
|   +-- TUI_BACKEND (deferred)
|   |   +-- TUI_BACKEND_WINDOWS
|   +-- TUI_BUFFER
|   +-- TUI_CELL
|   +-- TUI_COLOR
|   +-- TUI_EVENT
|   +-- TUI_STYLE
|
+-- Layout
|   +-- TUI_BOX (deferred)
|       +-- TUI_HBOX
|       +-- TUI_VBOX
|
+-- Widgets
    +-- TUI_WIDGET (deferred)
        +-- TUI_LABEL
        +-- TUI_BUTTON
        +-- TUI_TEXT_FIELD
        +-- TUI_CHECKBOX
        +-- TUI_LIST
        +-- TUI_PROGRESS
        +-- TUI_MENU
        +-- TUI_MENU_BAR
        +-- TUI_MENU_ITEM
        +-- TUI_MESSAGE_BOX
        +-- TUI_COMBO_BOX
```

## Class Descriptions

### TUI_QUICK (Fluent Facade)
Chainable API for building TUI applications without manual widget hierarchy management.

**Creation:** `make (a_title: STRING)`

### Core Classes

**TUI_APPLICATION**
Application lifecycle management: initialize, run, shutdown, event loop.

**TUI_BACKEND**
Abstract terminal interface. Implemented by platform-specific backends.

**TUI_BACKEND_WINDOWS**
Windows console implementation using Win32 API and ANSI codes.

**TUI_BUFFER**
Double-buffered screen with cell-level diffing for flicker-free updates.

**TUI_CELL**
Single character position: character, foreground color, background color, style.

**TUI_COLOR**
Color representation supporting 16-color, 256-color, and 24-bit RGB.

**TUI_EVENT**
Input events: keyboard (key, modifiers), mouse (click, scroll), resize.

**TUI_STYLE**
Widget styling: colors, borders, alignment, padding.

### Layout Classes

**TUI_HBOX** - Horizontal child arrangement with gap spacing.

**TUI_VBOX** - Vertical child arrangement with gap spacing.

### Widget Classes

| Widget | Purpose |
|--------|---------|
| TUI_LABEL | Static text display |
| TUI_BUTTON | Clickable with action handlers |
| TUI_TEXT_FIELD | Single-line text input |
| TUI_CHECKBOX | Boolean toggle |
| TUI_LIST | Scrollable item selection |
| TUI_PROGRESS | Progress indicator |
| TUI_MENU | Dropdown menu |
| TUI_MENU_BAR | Top menu bar |
| TUI_MESSAGE_BOX | Modal OK/Yes/No dialogs |
| TUI_COMBO_BOX | Dropdown selection |

## Class Count Summary
- Facade: 1
- Core: 8
- Layout: 3
- Widgets: 12+
- **Total: 24+ classes**
