# S01 - Project Inventory: simple_tui

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_tui
**Version:** 1.0
**Date:** 2026-01-23

## Overview

Modern Terminal User Interface (TUI) library for Eiffel with Elm-style architecture, double buffering, flexbox-inspired layouts, and extensive widget support.

## Project Files

### Core Source Files
| File | Purpose |
|------|---------|
| `src/tui_quick.e` | Fluent factory facade |
| `src/core/tui_application.e` | Application lifecycle |
| `src/core/tui_backend.e` | Terminal abstraction |
| `src/core/tui_backend_windows.e` | Windows console backend |
| `src/core/tui_buffer.e` | Double buffering |
| `src/core/tui_cell.e` | Single character cell |
| `src/core/tui_color.e` | Color representation |
| `src/core/tui_event.e` | Input event handling |
| `src/core/tui_style.e` | Widget styling |

### Layout Source Files
| File | Purpose |
|------|---------|
| `src/layout/tui_box.e` | Base container |
| `src/layout/tui_hbox.e` | Horizontal layout |
| `src/layout/tui_vbox.e` | Vertical layout |

### Widget Source Files
| File | Purpose |
|------|---------|
| `src/widgets/tui_widget.e` | Base widget class |
| `src/widgets/tui_label.e` | Text label |
| `src/widgets/tui_button.e` | Clickable button |
| `src/widgets/tui_text_field.e` | Text input |
| `src/widgets/tui_checkbox.e` | Toggle checkbox |
| `src/widgets/tui_list.e` | Selectable list |
| `src/widgets/tui_progress.e` | Progress bar |
| `src/widgets/tui_menu.e` | Menu widget |
| `src/widgets/tui_menu_bar.e` | Menu bar |
| `src/widgets/tui_menu_item.e` | Menu item |
| `src/widgets/tui_message_box.e` | Modal dialogs |
| `src/widgets/tui_combo_box.e` | Dropdown selection |

### Application Source Files
| File | Purpose |
|------|---------|
| `src/apps/task_manager/` | Example task manager app |

### Configuration Files
| File | Purpose |
|------|---------|
| `simple_tui.ecf` | EiffelStudio project configuration |
| `simple_tui.rc` | Windows resource file |

## Dependencies

### ISE Libraries
- base (core Eiffel classes)

### simple_* Libraries
- simple_console (terminal I/O, ANSI codes)
- simple_logger (debug logging)

## Build Targets
- `simple_tui` - Main library
- `simple_tui_tests` - Test suite
- `simple_tui_demo` - Demo applications
