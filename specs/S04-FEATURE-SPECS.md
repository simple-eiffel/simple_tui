# S04 - Feature Specifications: simple_tui

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_tui
**Date:** 2026-01-23

## Core Features

### TUI_QUICK (Fluent Facade)

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `(title: STRING)` | Create application |
| `title` | `: STRING_32` | Application title |
| `app` | `: TUI_APPLICATION` | App instance |
| `menu_bar` | `: TUI_MENU_BAR` | Menu bar |
| `root_vbox` | `: TUI_VBOX` | Root container |
| `run` | `()` | Start event loop |
| `quit` | `()` | Stop application |
| `menu` | `(title: STRING): TUI_QUICK` | Add menu |
| `item` | `(label: STRING; action: PROCEDURE): TUI_QUICK` | Add menu item |
| `separator` | `: TUI_QUICK` | Add menu separator |
| `vbox` | `: TUI_QUICK` | Start vertical box |
| `hbox` | `: TUI_QUICK` | Start horizontal box |
| `end_box` | `: TUI_QUICK` | End current box |
| `gap` | `(size: INTEGER): TUI_QUICK` | Set container gap |
| `label` | `(text: STRING): TUI_QUICK` | Add label |
| `button` | `(label: STRING; action: PROCEDURE): TUI_QUICK` | Add button |
| `text_field` | `(placeholder: STRING): TUI_QUICK` | Add text input |
| `password_field` | `(placeholder: STRING): TUI_QUICK` | Add password input |
| `checkbox` | `(label: STRING): TUI_QUICK` | Add checkbox |
| `list_box` | `(height: INTEGER): TUI_QUICK` | Add list |
| `progress_bar` | `(width: INTEGER): TUI_QUICK` | Add progress |
| `named` | `(name: STRING): TUI_QUICK` | Name last widget |
| `widget` | `(name: STRING): TUI_WIDGET` | Get by name |
| `text_field_named` | `(name: STRING): TUI_TEXT_FIELD` | Get text field |
| `list_named` | `(name: STRING): TUI_LIST` | Get list |
| `set_modal` | `(widget: TUI_WIDGET)` | Show modal |
| `clear_modal` | `()` | Hide modal |
| `show_message` | `(title, message: STRING)` | Show message box |
| `show_confirm` | `(title, message: STRING; callback: PROCEDURE)` | Yes/No dialog |
| `screen_width` | `: INTEGER` | Terminal width |
| `screen_height` | `: INTEGER` | Terminal height |

### TUI_APPLICATION

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `()` | Create application |
| `initialize` | `()` | Setup terminal |
| `run` | `()` | Event loop |
| `shutdown` | `()` | Cleanup |
| `quit` | `()` | Signal exit |
| `set_root` | `(widget: TUI_WIDGET)` | Set root widget |
| `set_menu_bar` | `(bar: TUI_MENU_BAR)` | Set menu |
| `set_modal` | `(widget: TUI_WIDGET)` | Show modal |
| `clear_modal` | `()` | Hide modal |
| `backend` | `: TUI_BACKEND` | Terminal backend |

### Widget Base (TUI_WIDGET)

| Feature | Signature | Description |
|---------|-----------|-------------|
| `x`, `y` | `: INTEGER` | Position |
| `width`, `height` | `: INTEGER` | Size |
| `is_focused` | `: BOOLEAN` | Has focus? |
| `is_visible` | `: BOOLEAN` | Visible? |
| `render` | `(buffer: TUI_BUFFER)` | Draw to buffer |
| `handle_event` | `(event: TUI_EVENT): BOOLEAN` | Process input |
| `set_style` | `(style: TUI_STYLE)` | Apply style |

### TUI_BUFFER

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `(w, h: INTEGER)` | Create buffer |
| `width`, `height` | `: INTEGER` | Dimensions |
| `put_char` | `(x, y: INTEGER; c: CHARACTER_32)` | Set character |
| `put_string` | `(x, y: INTEGER; s: STRING)` | Write string |
| `set_fg` | `(color: TUI_COLOR)` | Foreground |
| `set_bg` | `(color: TUI_COLOR)` | Background |
| `clear` | `()` | Clear buffer |
| `flush` | `(backend: TUI_BACKEND)` | Write to terminal |

### TUI_EVENT Types

| Event | Fields | Description |
|-------|--------|-------------|
| Key | key, modifiers | Keyboard input |
| Mouse | x, y, button | Mouse click |
| Resize | width, height | Terminal resize |
| Focus | gained | Focus change |
