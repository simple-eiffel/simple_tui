<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_tui

**[Documentation](https://simple-eiffel.github.io/simple_tui/)** | **[GitHub](https://github.com/simple-eiffel/simple_tui)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

Terminal User Interface library for Eiffel with EiffelVision2-compatible API.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Phase 2** - Core widgets complete, expanding widget library

## Overview

SIMPLE_TUI provides a modern terminal-based UI framework for Eiffel applications. It features **EiffelVision2-compatible API** (extend/prune naming), **256-color support**, **mouse input**, **keyboard navigation**, and **Unicode rendering**. Designed for developers familiar with EV_* widgets who want terminal UIs.

## Quick Start

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
            create box.make (40, 10, "My App")
            create btn.make_with_text ("Click Me")
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

## Features

### Core
- **TUI_APPLICATION** - Main application class with event loop
- **TUI_BUFFER** - Rendering buffer with Unicode support
- **TUI_STYLE** - Text styling (colors, bold, underline, reverse)
- **TUI_COLOR** - 256-color palette support
- **TUI_EVENT** - Keyboard and mouse events

### Widgets
- **TUI_LABEL** - Static text display
- **TUI_BUTTON** - Clickable button with focus indication
- **TUI_TEXT_FIELD** - Single-line text input
- **TUI_CHECKBOX** - Toggle checkbox
- **TUI_RADIO_BUTTON** - Mutually exclusive selection
- **TUI_RADIO_GROUP** - Container for radio buttons
- **TUI_LIST** - Scrollable list selection
- **TUI_COMBO_BOX** - Dropdown selection
- **TUI_PROGRESS** - Progress bar
- **TUI_SEPARATOR** - Horizontal/vertical divider
- **TUI_TABS** - Tabbed panel container

### Menus
- **TUI_MENU_BAR** - Horizontal menu bar with Alt+key shortcuts
- **TUI_MENU** - Drop-down menu container
- **TUI_MENU_ITEM** - Menu item with text, action, and & shortcut marker

### Layout
- **TUI_BOX** - Container with optional border and title
- **TUI_VBOX** - Vertical layout container
- **TUI_HBOX** - Horizontal layout container

## EiffelVision2 Compatibility

For EV developers, the API uses familiar naming:

| EV Pattern | TUI Equivalent |
|-----------|----------------|
| `container.extend (widget)` | `box.extend (widget)` |
| `container.prune (widget)` | `box.prune (widget)` |
| `EV_BUTTON` | `TUI_BUTTON` |
| `EV_CHECK_BUTTON` | `TUI_CHECKBOX` |
| `EV_RADIO_BUTTON` | `TUI_RADIO_BUTTON` |
| `EV_LIST` | `TUI_LIST` |
| `EV_COMBO_BOX` | `TUI_COMBO_BOX` |
| `EV_NOTEBOOK` | `TUI_TABS` |
| `EV_MENU_BAR` | `TUI_MENU_BAR` |
| `EV_MENU` | `TUI_MENU` |
| `EV_MENU_ITEM` | `TUI_MENU_ITEM` |

See [EV_TUI_WIDGET_MAPPING.md](docs/EV_TUI_WIDGET_MAPPING.md) for complete mapping.

## Color Themes

```eiffel
local
    style: TUI_STYLE
    color: TUI_COLOR
do
    create style.make_default
    style.set_fg (color.cyan)
    style.set_bg (color.blue)
    style.set_bold (True)

    button.set_style (style)
end
```

## Installation

1. Set the ecosystem environment variable (one-time setup for all simple_* libraries):
```
SIMPLE_EIFFEL=D:\prod
```

2. Add to ECF:
```xml
<library name="simple_tui" location="$SIMPLE_EIFFEL/simple_tui/simple_tui.ecf"/>
```

## Dependencies

None (standalone library)

## Platform Support

- **Windows** - Full support via Win32 Console API
- **Linux/macOS** - Planned (ANSI escape sequences)

## License

MIT License
