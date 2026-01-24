# S03 - Contracts: simple_tui

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_tui
**Date:** 2026-01-23

## TUI_QUICK Contracts

### Initialization

```eiffel
make (a_title: READABLE_STRING_GENERAL)
    ensure
        title_set: title.same_string_general (a_title)
```

### Menu Building

```eiffel
menu (a_title: READABLE_STRING_GENERAL): TUI_QUICK
    ensure
        result_is_current: Result = Current

item (a_label: READABLE_STRING_GENERAL; a_action: PROCEDURE): TUI_QUICK
    ensure
        result_is_current: Result = Current
```

### Layout Building

```eiffel
vbox: TUI_QUICK
    ensure
        result_is_current: Result = Current

hbox: TUI_QUICK
    ensure
        result_is_current: Result = Current

end_box: TUI_QUICK
    ensure
        result_is_current: Result = Current

gap (a_size: INTEGER): TUI_QUICK
    ensure
        result_is_current: Result = Current
```

### Widget Factory

```eiffel
label (a_text: READABLE_STRING_GENERAL): TUI_QUICK
    ensure
        result_is_current: Result = Current

button (a_label: READABLE_STRING_GENERAL; a_action: PROCEDURE): TUI_QUICK
    ensure
        result_is_current: Result = Current

text_field (a_placeholder: READABLE_STRING_GENERAL): TUI_QUICK
    ensure
        result_is_current: Result = Current

checkbox (a_label: READABLE_STRING_GENERAL): TUI_QUICK
    ensure
        result_is_current: Result = Current

list_box (a_height: INTEGER): TUI_QUICK
    ensure
        result_is_current: Result = Current

progress_bar (a_width: INTEGER): TUI_QUICK
    ensure
        result_is_current: Result = Current
```

### Naming

```eiffel
named (a_name: READABLE_STRING_GENERAL): TUI_QUICK
    ensure
        result_is_current: Result = Current
```

### Modal Dialogs

```eiffel
set_modal (a_widget: TUI_WIDGET)
    require
        widget_attached: a_widget /= Void
```

## TUI_APPLICATION Contracts

```eiffel
set_root (a_widget: TUI_WIDGET)
    require
        widget_not_void: a_widget /= Void

run
    require
        root_set: root /= Void
        initialized: is_initialized
```

## Invariants

```eiffel
class TUI_QUICK
invariant
    app_exists: app /= Void
    menu_bar_exists: menu_bar /= Void
    root_vbox_exists: root_vbox /= Void
    container_stack_exists: container_stack /= Void
    named_widgets_exists: named_widgets /= Void
end

class TUI_BUFFER
invariant
    valid_dimensions: width > 0 and height > 0
    cells_allocated: cells /= Void
end
```
