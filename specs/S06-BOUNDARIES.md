# S06 - Boundaries: simple_tui

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_tui
**Date:** 2026-01-23

## Scope Boundaries

### In Scope
- Terminal UI application framework
- Widget system (label, button, text, checkbox, list, progress)
- Layout containers (vbox, hbox)
- Menu bar and menus
- Modal dialogs
- Double buffering
- Keyboard and mouse input
- Color support (16, 256, 24-bit)
- Fluent builder API

### Out of Scope
- **Graphics** - No sixel, images, or graphics
- **Audio** - No terminal bell management
- **Networking** - Use other libraries
- **Persistence** - No config save/load
- **Themes** - Basic styling only
- **Animation framework** - Manual updates only
- **Drag and drop** - Not implemented
- **Rich text** - No markdown rendering

## API Boundaries

### Public API (TUI_QUICK facade)
- Application creation and lifecycle
- Menu building
- Layout building
- Widget creation
- Widget retrieval by name
- Modal dialog management
- Screen size queries

### Internal API (not exported)
- Buffer implementation
- Event dispatch
- Rendering internals

## Integration Boundaries

### Input Boundaries

| Input Type | Format | Validation |
|------------|--------|------------|
| Title | STRING | Any string |
| Dimensions | INTEGER | > 0 |
| Colors | TUI_COLOR | Valid color object |
| Events | TUI_EVENT | Backend-generated |

### Output Boundaries

| Output Type | Format | Notes |
|-------------|--------|-------|
| Screen | Terminal | Via backend |
| Widget ref | TUI_WIDGET | May be Void |
| Dimensions | INTEGER | Current terminal size |

## Performance Boundaries

### Expected Performance

| Operation | Time | Notes |
|-----------|------|-------|
| Full render | < 16 ms | 60fps target |
| Event process | < 1 ms | Interactive |
| Widget create | < 1 ms | Allocation only |

### Memory Usage

| Component | Per Instance | Notes |
|-----------|--------------|-------|
| Cell | ~16 bytes | Character + colors |
| Buffer (80x25) | ~32 KB | 2000 cells |
| Widget | ~100-500 bytes | Varies by type |

## Extension Points

### Custom Widgets
1. Inherit from TUI_WIDGET
2. Override `render(buffer)`
3. Override `handle_event(event)`
4. Add to container

### Custom Backends
1. Inherit from TUI_BACKEND
2. Implement terminal operations
3. Inject into TUI_APPLICATION

## Dependency Boundaries

### Required Dependencies
- EiffelBase
- simple_console (ANSI codes)
- simple_logger (debug output)

### Optional Dependencies
- simple_toml (theme files, future)

## Platform Support

### Current
- Windows 10+ (console API)

### Planned
- Linux (ANSI terminal)
- macOS (ANSI terminal)
- SSH/remote terminals
