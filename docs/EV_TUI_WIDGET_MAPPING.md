# EiffelVision2 to TUI Widget Mapping

This document maps EiffelVision2 (EV) widgets to their simple_tui (TUI) equivalents.

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Implemented in simple_tui |
| 🔨 | To be implemented |
| ➖ | Not applicable to TUI |
| 🔄 | Partial implementation |

---

## Primitives (Basic Controls)

| EV Widget | TUI Widget | Status | Notes |
|-----------|------------|--------|-------|
| EV_LABEL | TUI_LABEL | ✅ | Text alignment, word wrap |
| EV_BUTTON | TUI_BUTTON | ✅ | Click handlers, disabled state |
| EV_TOGGLE_BUTTON | TUI_TOGGLE_BUTTON | 🔨 | On/off button (like checkbox but button style) |
| EV_CHECK_BUTTON | TUI_CHECKBOX | ✅ | Binary + indeterminate states |
| EV_RADIO_BUTTON | TUI_RADIO_BUTTON | ✅ | With TUI_RADIO_GROUP for mutual exclusion |
| EV_TEXT_FIELD | TUI_TEXT_FIELD | ✅ | Single-line, password mode, placeholder |
| EV_TEXT | TUI_TEXT_AREA | 🔨 | Multi-line text editing |
| EV_COMBO_BOX | TUI_COMBO_BOX | ✅ | Dropdown selection |
| EV_LIST | TUI_LIST | ✅ | Scrollable, single/multi select |
| EV_MULTI_COLUMN_LIST | TUI_TABLE | 🔨 | Tabular data display |
| EV_TREE | TUI_TREE | 🔨 | Hierarchical expand/collapse |
| EV_PROGRESS_BAR | TUI_PROGRESS | ✅ | Determinate + indeterminate |
| EV_SPIN_BUTTON | TUI_SPIN_BUTTON | 🔨 | Numeric input with +/- |
| EV_RANGE / EV_HORIZONTAL_RANGE | TUI_SLIDER | 🔨 | Value selection slider |
| EV_HORIZONTAL_SEPARATOR | TUI_SEPARATOR | ✅ | Horizontal line divider |
| EV_VERTICAL_SEPARATOR | TUI_SEPARATOR | ✅ | Vertical line divider |
| EV_DRAWING_AREA | TUI_CANVAS | 🔨 | Custom drawing surface |
| EV_PIXMAP | ➖ | N/A | TUI uses text/block characters |

---

## Containers

| EV Widget | TUI Widget | Status | Notes |
|-----------|------------|--------|-------|
| EV_CONTAINER | TUI_WIDGET | ✅ | Base with children list |
| EV_BOX | TUI_BOX | ✅ | Border, title, padding |
| EV_HORIZONTAL_BOX | TUI_HBOX | ✅ | Horizontal child layout |
| EV_VERTICAL_BOX | TUI_VBOX | ✅ | Vertical child layout |
| EV_FRAME | TUI_BOX | ✅ | Same as TUI_BOX with border |
| EV_NOTEBOOK | TUI_TABS | ✅ | Tabbed panels |
| EV_HORIZONTAL_SPLIT_AREA | TUI_HSPLIT | 🔨 | Resizable horizontal split |
| EV_VERTICAL_SPLIT_AREA | TUI_VSPLIT | 🔨 | Resizable vertical split |
| EV_SCROLLABLE_AREA | TUI_SCROLLABLE | 🔨 | Scrollable viewport |
| EV_VIEWPORT | TUI_VIEWPORT | 🔨 | Clipped view region |
| EV_CELL | TUI_CELL_CONTAINER | 🔨 | Single-child wrapper |
| EV_TABLE | TUI_GRID | 🔨 | Grid-based layout |
| EV_FIXED | TUI_FIXED | 🔨 | Absolute positioning |

---

## Windows & Dialogs

| EV Widget | TUI Widget | Status | Notes |
|-----------|------------|--------|-------|
| EV_WINDOW | TUI_APPLICATION | 🔄 | Root widget serves as window |
| EV_TITLED_WINDOW | TUI_APPLICATION | 🔄 | Title shown in header |
| EV_DIALOG | TUI_DIALOG | 🔨 | Modal overlay dialog |
| EV_MESSAGE_DIALOG | TUI_MESSAGE_BOX | 🔨 | Alert/confirm/prompt |
| EV_FILE_OPEN_DIALOG | TUI_FILE_BROWSER | 🔨 | File selection |
| EV_POPUP_WINDOW | TUI_POPUP | 🔨 | Floating overlay |

---

## Menus

| EV Widget | TUI Widget | Status | Notes |
|-----------|------------|--------|-------|
| EV_MENU_BAR | TUI_MENU_BAR | ✅ | Horizontal menu bar with Alt shortcuts |
| EV_MENU | TUI_MENU | ✅ | Dropdown menu |
| EV_MENU_ITEM | TUI_MENU_ITEM | ✅ | Menu entry with & shortcut |
| EV_MENU_SEPARATOR | (via TUI_MENU_ITEM) | ✅ | Menu divider (is_separator mode) |
| EV_CHECK_MENU_ITEM | TUI_CHECK_MENU_ITEM | 🔨 | Toggleable menu item |
| EV_RADIO_MENU_ITEM | TUI_RADIO_MENU_ITEM | 🔨 | Radio group menu item |

---

## Toolbars & Status

| EV Widget | TUI Widget | Status | Notes |
|-----------|------------|--------|-------|
| EV_TOOL_BAR | TUI_TOOLBAR | 🔨 | Horizontal toolbar |
| EV_TOOL_BAR_BUTTON | TUI_TOOLBAR_BUTTON | 🔨 | Toolbar action |
| EV_TOOL_BAR_SEPARATOR | TUI_TOOLBAR_SEPARATOR | 🔨 | Toolbar divider |
| EV_STATUS_BAR | TUI_STATUS_BAR | 🔨 | Bottom status line |

---

## Priority Implementation Order

### Phase 1 - Core Widgets ✅
Implemented:
- TUI_LABEL ✅
- TUI_BUTTON ✅
- TUI_CHECKBOX ✅
- TUI_TEXT_FIELD ✅
- TUI_LIST ✅
- TUI_PROGRESS ✅
- TUI_BOX ✅
- TUI_VBOX ✅
- TUI_HBOX ✅

### Phase 2 - Essential Additions ✅
Implemented:
- TUI_RADIO_BUTTON + TUI_RADIO_GROUP ✅
- TUI_COMBO_BOX (dropdown) ✅
- TUI_SEPARATOR (horizontal/vertical) ✅
- TUI_TABS (tabbed panels) ✅
- TUI_MENU_BAR + TUI_MENU + TUI_MENU_ITEM ✅

Still to do:
- TUI_TEXT_AREA (multi-line)
- TUI_DIALOG (modal)

### Phase 3 - Advanced Widgets
For richer applications:
1. TUI_TREE (hierarchical)
2. TUI_TABLE (multi-column)
3. TUI_SLIDER
4. TUI_SPIN_BUTTON
5. TUI_STATUS_BAR
6. TUI_TOOLBAR

### Phase 4 - Specialized
For specific use cases:
1. TUI_SCROLLABLE
2. TUI_SPLIT (resizable)
3. TUI_FILE_BROWSER
4. TUI_CANVAS
5. TUI_POPUP
6. TUI_MESSAGE_BOX

---

## TUI-Specific Widgets

These have no direct EV equivalent but are useful for TUI:

| TUI Widget | Status | Description |
|------------|--------|-------------|
| TUI_SPARKLINE | 🔨 | Mini inline chart |
| TUI_GAUGE | 🔨 | Circular/arc progress |
| TUI_LOG_VIEW | 🔨 | Scrolling log display |
| TUI_CALENDAR | 🔨 | Date picker |
| TUI_CHART | 🔨 | Bar/line charts |
| TUI_BORDER_BOX | 🔨 | Decorative borders only |
| TUI_ASCII_ART | 🔨 | ASCII art display |

---

## EV-Compatible API

To help EiffelVision2 developers feel at home, TUI widgets use familiar naming:

| EV API | TUI API | Notes |
|--------|---------|-------|
| `container.extend (widget)` | `container.extend (widget)` | ✅ Same name |
| `container.prune (widget)` | `container.prune (widget)` | ✅ Same name |
| `widget.show` | `widget.show` | ✅ Same name |
| `widget.hide` | `widget.hide` | ✅ Same name |
| `widget.set_minimum_size` | `widget.set_size` | Similar |
| `widget.parent` | `widget.parent` | ✅ Same name |

## Architecture Notes

### Event System
- EV uses `EV_APPLICATION.process_events` with callbacks
- TUI uses `TUI_APPLICATION.run` with event polling and handlers

### Layout System
- EV uses packable items with expand/fill properties
- TUI uses explicit positioning + layout containers (VBOX/HBOX)

### Styling
- EV uses system themes + pixmaps
- TUI uses TUI_STYLE (fg/bg colors + attributes like bold/reverse)

### Focus Management
- Both use Tab navigation
- TUI tracks `is_focused` per widget
- TUI_APPLICATION manages focus chain

---

## Implementation Checklist for New Widgets

When implementing a new TUI widget:

1. [ ] Inherit from TUI_WIDGET
2. [ ] Implement `render (buffer: TUI_BUFFER)`
3. [ ] Override `handle_key` if interactive
4. [ ] Override `handle_mouse` if clickable
5. [ ] Override `preferred_width` / `preferred_height`
6. [ ] Add style attributes (normal, focused, etc.)
7. [ ] Add event callbacks (on_change, on_select, etc.)
8. [ ] Add to demo application
9. [ ] Write unit tests
