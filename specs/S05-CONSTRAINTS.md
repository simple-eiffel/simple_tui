# S05 - Constraints: simple_tui

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_tui
**Date:** 2026-01-23

## Terminal Constraints

### Minimum Terminal Size
```
Width:  40 columns
Height: 10 rows
Recommended: 80x25 or larger
```

### Color Support

| Mode | Colors | Detection |
|------|--------|-----------|
| Basic | 16 | Always available |
| Extended | 256 | TERM contains "256color" |
| True Color | 16.7M | COLORTERM=truecolor |

### Character Support
- ASCII: Full support
- Unicode: Depends on terminal
- Wide characters: Handled via wcwidth

## Widget Constraints

### Dimensions
```eiffel
-- All widgets
width > 0
height > 0

-- Text field
min_width: 5
max_width: limited by container

-- List
min_height: 3 (for scrollbar)
```

### Nesting
- Maximum nesting depth: ~20 (practical)
- Container must fit children
- Overflow: clipped (not scrolled unless scrollable)

## Event Constraints

### Keyboard
```
Modifiers: Ctrl, Alt, Shift
Special keys: Arrow, Tab, Enter, Escape, F1-F12
Character keys: Printable ASCII + Unicode
```

### Mouse
```
Supported: Click, double-click, scroll
Drag: Platform-dependent
Movement: Must be enabled explicitly
```

## Focus Constraints

### Focus Chain
- Tab moves forward through focusable widgets
- Shift+Tab moves backward
- Only one widget focused at a time
- Non-focusable: labels, separators

### Modal Focus
- Modal captures all input
- Focus trapped within modal
- Escape typically closes modal

## Rendering Constraints

### Double Buffering
```
Frame rate: Limited by event loop
Diff rendering: Only changed cells written
Flicker: Eliminated by buffering
```

### Character Cell
```eiffel
TUI_CELL:
  character: CHARACTER_32  -- 1 character
  fg_color: TUI_COLOR      -- Foreground
  bg_color: TUI_COLOR      -- Background
  style: INTEGER           -- Bold, underline, etc.
```

## Platform Constraints

### Windows Console
- Requires Windows 10 1607+ for ANSI
- Uses ENABLE_VIRTUAL_TERMINAL_PROCESSING
- Mouse support via console API

### Future Platforms
- ANSI backend planned
- SSH/remote terminal support

## Threading Constraints

### Single-Threaded UI
- All UI operations on main thread
- Event loop is blocking
- For SCOOP: wrap backend in processor
