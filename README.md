<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_tui

**[Documentation](https://simple-eiffel.github.io/simple_tui/)** | **[Cookbook](https://simple-eiffel.github.io/simple_tui/cookbook.html)** | **[GitHub](https://github.com/simple-eiffel/simple_tui)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

Terminal User Interface library for Eiffel with EiffelVision2-inspired API.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Phase 2** - Core widgets complete, expanding widget library

## Overview

**simple_tui** provides a modern terminal-based UI framework for Eiffel applications. Build interactive console applications with:

- **EiffelVision2-inspired API** - Familiar `extend`/`prune` naming for EV developers
- **256-color support** - Full terminal color palette
- **Mouse input** - Click, drag, and hover support
- **Keyboard navigation** - Tab, arrows, shortcuts, and focus management
- **Unicode rendering** - Box drawing characters and special symbols
- **Menu system** - Drop-down menus with keyboard shortcuts
- **Modal dialogs** - Message boxes and custom dialogs

## Quick Start

### Minimal Application

```eiffel
class MY_APP

inherit
    TUI_APPLICATION
        redefine
            setup
        end

create
    make

feature {NONE} -- Initialization

    setup
            -- Build the UI.
        local
            box: TUI_BOX
            btn: TUI_BUTTON
        do
            create box.make_with_title ("My App", 40, 10)
            create btn.make ("Click Me")
            btn.set_on_click (agent on_click)
            box.extend (btn)  -- EV-compatible API
            root.extend (box)
        end

    on_click
            -- Button clicked.
        do
            quit
        end

end
```

### Running the Demo

```bash
cd D:\prod\simple_tui\demo
# Compile
D:\prod\ec.sh -batch -config tui_demo.ecf -target tui_demo -c_compile
# Run
./EIFGENs/tui_demo/W_code/tui_demo.exe
```

## Widget Reference

### Input Widgets

| Widget | EV Equivalent | Description |
|--------|---------------|-------------|
| `TUI_BUTTON` | EV_BUTTON | Clickable button with press animation |
| `TUI_TEXT_FIELD` | EV_TEXT_FIELD | Single-line text input with cursor |
| `TUI_CHECKBOX` | EV_CHECK_BUTTON | Toggle checkbox `[X]` / `[ ]` |
| `TUI_RADIO_BUTTON` | EV_RADIO_BUTTON | Mutually exclusive selection `(*)` / `( )` |
| `TUI_LIST` | EV_LIST | Scrollable selection list |
| `TUI_COMBO_BOX` | EV_COMBO_BOX | Dropdown selection with popup |

### Display Widgets

| Widget | EV Equivalent | Description |
|--------|---------------|-------------|
| `TUI_LABEL` | EV_LABEL | Static text display |
| `TUI_PROGRESS` | EV_PROGRESS_BAR | Progress bar with percentage |
| `TUI_SEPARATOR` | EV_HORIZONTAL_SEPARATOR | Horizontal/vertical divider |
| `TUI_MESSAGE_BOX` | EV_MESSAGE_DIALOG | Modal dialog with buttons |

### Container Widgets

| Widget | EV Equivalent | Description |
|--------|---------------|-------------|
| `TUI_BOX` | EV_FRAME | Container with optional border and title |
| `TUI_VBOX` | EV_VERTICAL_BOX | Vertical layout container |
| `TUI_HBOX` | EV_HORIZONTAL_BOX | Horizontal layout container |
| `TUI_TABS` | EV_NOTEBOOK | Tabbed panel container |
| `TUI_RADIO_GROUP` | (implicit) | Container for radio buttons |

### Menu Widgets

| Widget | EV Equivalent | Description |
|--------|---------------|-------------|
| `TUI_MENU_BAR` | EV_MENU_BAR | Horizontal menu bar with Alt+key shortcuts |
| `TUI_MENU` | EV_MENU | Drop-down menu container |
| `TUI_MENU_ITEM` | EV_MENU_ITEM | Menu item with `&` shortcut marker |

## Core Classes

### TUI_APPLICATION

Main application controller with event loop.

```eiffel
class MY_APP inherit TUI_APPLICATION redefine setup end

create make

feature
    setup
        do
            -- Build widgets here
            root.extend (my_widget)
        end
end
```

**Key Features:**
- `make` - Initialize and run the application
- `setup` - Override to build your UI
- `root` - The root container widget
- `set_menu_bar (bar)` - Set the menu bar
- `set_modal (widget)` - Show modal dialog
- `clear_modal` - Close modal dialog
- `quit` - Exit the event loop
- `register_shortcut (char, ctrl, alt, shift, agent)` - Register global shortcut
- `set_on_tick (agent)` - Called each frame for animations

### TUI_WIDGET

Base class for all widgets.

```eiffel
widget.set_position (x, y)      -- Position within parent
widget.set_size (w, h)          -- Size
widget.show / widget.hide       -- Visibility
widget.focus / widget.unfocus   -- Focus state
widget.extend (child)           -- Add child (EV compatible)
widget.prune (child)            -- Remove child (EV compatible)
```

### TUI_STYLE

Text styling with colors and attributes.

```eiffel
local
    style: TUI_STYLE
    color: TUI_COLOR
do
    create style.make_default

    -- Colors (256-color palette)
    create color.make_index (14)  -- Bright cyan
    style.set_foreground (color)
    style.set_background (create {TUI_COLOR}.make_index (0))  -- Black

    -- Attributes
    style.set_bold (True)
    style.set_reverse (True)      -- Swap fg/bg
    style.set_underline (True)

    widget.set_style (style)
end
```

### TUI_COLOR

256-color terminal palette.

```eiffel
-- Standard 16 colors (indices 0-15)
create color.make_index (0)   -- Black
create color.make_index (1)   -- Red
create color.make_index (2)   -- Green
create color.make_index (3)   -- Yellow
create color.make_index (4)   -- Blue
create color.make_index (5)   -- Magenta
create color.make_index (6)   -- Cyan
create color.make_index (7)   -- White
create color.make_index (8)   -- Bright black (gray)
create color.make_index (9)   -- Bright red
create color.make_index (10)  -- Bright green
create color.make_index (11)  -- Bright yellow
create color.make_index (12)  -- Bright blue
create color.make_index (13)  -- Bright magenta
create color.make_index (14)  -- Bright cyan
create color.make_index (15)  -- Bright white

-- Extended colors (indices 16-255)
create color.make_index (202) -- Orange
create color.make_index (51)  -- Aqua
```

## Widget Examples

### TUI_BUTTON

```eiffel
local
    btn: TUI_BUTTON
do
    create btn.make ("Submit")
    btn.set_on_click (agent on_submit)

    -- Styling
    btn.set_normal_style (normal_style)
    btn.set_focused_style (focused_style)
    btn.set_pressed_style (pressed_style)

    container.extend (btn)
end
```

### TUI_TEXT_FIELD

```eiffel
local
    field: TUI_TEXT_FIELD
do
    create field.make (30)  -- Width in characters
    field.set_placeholder ("Enter name...")
    field.set_text ("Default value")

    -- Password mode
    field.set_password (True)

    -- Get value
    print (field.text)
end
```

### TUI_CHECKBOX

```eiffel
local
    cb: TUI_CHECKBOX
do
    create cb.make ("Remember me")
    cb.set_checked (True)
    cb.set_on_change (agent on_remember_change)

on_remember_change (checked: BOOLEAN)
    do
        if checked then
            -- Save settings
        end
    end
end
```

### TUI_RADIO_BUTTON and TUI_RADIO_GROUP

```eiffel
local
    group: TUI_RADIO_GROUP
    r1, r2, r3: TUI_RADIO_BUTTON
do
    create group.make
    create r1.make ("Option A")
    create r2.make ("Option B")
    create r3.make ("Option C")

    group.add_button (r1)
    group.add_button (r2)
    group.add_button (r3)
    group.set_on_change (agent on_option_change)

    container.extend (group)
end

on_option_change (index: INTEGER)
    do
        -- index is 1-based
    end
```

### TUI_LIST

```eiffel
local
    list: TUI_LIST
do
    create list.make (30, 10)  -- Width, visible height
    list.add_item ("First item")
    list.add_item ("Second item")
    list.add_item ("Third item")
    list.set_on_select (agent on_item_selected)

    -- Get selection
    if attached list.selected_item as item then
        print (item)
    end
    print (list.selected_index)  -- 1-based
end
```

### TUI_COMBO_BOX

```eiffel
local
    combo: TUI_COMBO_BOX
do
    create combo.make (20)  -- Width
    combo.add_item ("Light")
    combo.add_item ("Dark")
    combo.add_item ("System")
    combo.set_on_change (agent on_theme_change)

    -- Get selection
    if attached combo.selected_text as theme then
        print (theme)
    end
end
```

### TUI_PROGRESS

```eiffel
local
    progress: TUI_PROGRESS
do
    create progress.make (40)  -- Width
    progress.set_value (75)
    progress.set_show_percentage (True)

    -- Indeterminate mode (spinner)
    progress.set_indeterminate (True)

    -- Custom characters
    progress.set_fill_char ('#')
    progress.set_empty_char ('-')

    -- Animate (call in on_tick)
    progress.increment (1)
    progress.tick  -- For indeterminate
end
```

### TUI_TABS

```eiffel
local
    tabs: TUI_TABS
    tab1, tab2: TUI_BOX
do
    create tabs.make (60, 20)

    create tab1.make (60, 18)
    -- Add widgets to tab1...
    tabs.add_tab ("Settings", tab1)

    create tab2.make (60, 18)
    -- Add widgets to tab2...
    tabs.add_tab ("About", tab2)

    tabs.set_on_tab_change (agent on_tab_changed)
end
```

### TUI_MESSAGE_BOX

```eiffel
local
    mb: TUI_MESSAGE_BOX
do
    -- OK-only dialog
    create mb.make_ok ("Info", "Operation completed!")

    -- OK/Cancel dialog
    create mb.make_ok_cancel ("Confirm", "Delete this file?")

    mb.set_on_close (agent on_dialog_close)

    -- Center on screen
    if attached app.backend as b then
        mb.show_centered (b.width, b.height)
    end
    app.set_modal (mb)
end

on_dialog_close (button_id: INTEGER)
    do
        if button_id = {TUI_MESSAGE_BOX}.Button_ok then
            -- User clicked OK
        elseif button_id = {TUI_MESSAGE_BOX}.Button_cancel then
            -- User clicked Cancel
        end
        app.clear_modal
    end
```

## Menu System

### Creating a Menu Bar

```eiffel
local
    menu_bar: TUI_MENU_BAR
    file_menu: TUI_MENU
    item: TUI_MENU_ITEM
do
    create menu_bar.make (80)  -- Width

    -- Create File menu (& marks shortcut key)
    create file_menu.make_with_title ("&File")

    -- Add menu items
    create item.make_with_text_and_action ("&New", agent on_new)
    file_menu.add_item (item)

    create item.make_with_text_and_action ("&Open", agent on_open)
    file_menu.add_item (item)

    file_menu.add_separator

    create item.make_with_text_and_action ("E&xit", agent on_exit)
    file_menu.add_item (item)

    menu_bar.add_menu (file_menu)

    -- Set the menu bar
    app.set_menu_bar (menu_bar)
end
```

### Menu Navigation

- **Alt+key** - Open menu by shortcut (e.g., Alt+F for &File)
- **Left/Right** - Switch between menus
- **Up/Down** - Navigate menu items
- **Enter/Space** - Activate item
- **Escape** - Close menu

## Keyboard Shortcuts

### Global Shortcuts

```eiffel
-- Register in setup or create_widgets
app.register_shortcut ('s', True, False, False, agent on_save)   -- Ctrl+S
app.register_shortcut ('z', True, False, False, agent on_undo)   -- Ctrl+Z
app.register_shortcut ('q', True, False, False, agent on_quit)   -- Ctrl+Q
```

### Focus Navigation

- **Tab** - Move to next focusable widget
- **Shift+Tab** - Move to previous focusable widget
- **Enter/Space** - Activate focused widget
- **Arrow keys** - Navigate within widgets (lists, tabs, menus)

## Layout System

### Manual Positioning

```eiffel
widget.set_position (10, 5)  -- x=10, y=5 within parent
```

### TUI_VBOX (Vertical Layout)

```eiffel
local
    vbox: TUI_VBOX
do
    create vbox.make (60, 20)
    vbox.set_gap (1)  -- Spacing between children

    vbox.extend (label)
    vbox.extend (field)
    vbox.extend (button)
end
```

### TUI_HBOX (Horizontal Layout)

```eiffel
local
    hbox: TUI_HBOX
do
    create hbox.make (60, 10)
    hbox.set_gap (2)  -- Spacing between children

    hbox.extend (left_panel)
    hbox.extend (middle_panel)
    hbox.extend (right_panel)
end
```

### TUI_BOX (Bordered Container)

```eiffel
local
    box: TUI_BOX
do
    -- With title
    create box.make_with_title ("Settings", 40, 15)

    -- Without title
    create box.make (40, 15, "")

    box.set_padding (1)  -- Inner padding
    box.set_border_style (my_border_style)
    box.set_title_style (my_title_style)
end
```

## Animation

Use `set_on_tick` for frame-based animations:

```eiffel
feature {NONE} -- Initialization

    setup
        do
            -- ...
            app.set_on_tick (agent on_tick)
        end

feature {NONE} -- Animation

    tick_count: INTEGER

    on_tick
        do
            tick_count := tick_count + 1

            -- Update every 3 frames
            if tick_count \\ 3 = 0 then
                progress.increment (1)
                if progress.current_value >= 100 then
                    progress.set_value (0)
                end
            end

            -- Animate indeterminate progress
            progress2.tick
        end
```

## Event Handling

simple_tui uses EiffelVision2-style `ACTION_SEQUENCE` for event handling, allowing multiple handlers per event.

### Simple Approach (Single Handler)

Use the convenience setters for a single handler (clears previous handlers):

```eiffel
button.set_on_click (agent on_button_clicked)
checkbox.set_on_change (agent on_checked (?, BOOLEAN))
list.set_on_select (agent on_selected (?, INTEGER))
combo.set_on_change (agent on_changed (?, INTEGER))
tabs.set_on_tab_change (agent on_tab (?, INTEGER))
dialog.set_on_close (agent on_close (?, INTEGER))
```

### ACTION_SEQUENCE Approach (Multiple Handlers)

For EV-style multiple handlers, use the action sequences directly:

```eiffel
-- Add multiple click handlers
button.click_actions.extend (agent log_click)
button.click_actions.extend (agent update_ui)
button.click_actions.extend (agent save_state)

-- Remove a handler
button.click_actions.prune (agent log_click)

-- Clear all handlers
button.click_actions.wipe_out
```

### Available Action Sequences

| Widget | Action Sequence | EV Alias | Argument |
|--------|-----------------|----------|----------|
| `TUI_BUTTON` | `click_actions` | `select_actions` | `TUPLE` |
| `TUI_CHECKBOX` | `change_actions` | `check_actions` | `TUPLE [BOOLEAN]` |
| `TUI_RADIO_GROUP` | `change_actions` | `select_actions` | `TUPLE [INTEGER]` |
| `TUI_LIST` | `select_actions` | - | `TUPLE [INTEGER]` |
| `TUI_LIST` | `activate_actions` | - | `TUPLE [INTEGER]` |
| `TUI_COMBO_BOX` | `change_actions` | `select_actions` | `TUPLE [INTEGER]` |
| `TUI_TABS` | `tab_change_actions` | `selection_actions` | `TUPLE [INTEGER]` |
| `TUI_MESSAGE_BOX` | `close_actions` | - | `TUPLE [INTEGER]` |

## Installation

1. Set the ecosystem environment variable (one-time setup):
```
SIMPLE_EIFFEL=D:\prod
```

2. Add to your ECF:
```xml
<library name="simple_tui" location="$SIMPLE_EIFFEL/simple_tui/simple_tui.ecf"/>
```

## Dependencies

- **simple_logging** - Optional, for debug logging

## Platform Support

| Platform | Status | Backend |
|----------|--------|---------|
| Windows | Full support | Win32 Console API |
| Linux | Planned | ANSI escape sequences |
| macOS | Planned | ANSI escape sequences |

## License

MIT License

## See Also

- [Cookbook](https://simple-eiffel.github.io/simple_tui/cookbook.html) - Practical recipes
- [User Guide](https://simple-eiffel.github.io/simple_tui/user-guide.html) - Detailed how-to
- [API Reference](https://simple-eiffel.github.io/simple_tui/) - Full API documentation
- [EV Widget Mapping](docs/EV_TUI_WIDGET_MAPPING.md) - EiffelVision2 equivalents
