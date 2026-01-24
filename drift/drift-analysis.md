# Drift Analysis: simple_tui

Generated: 2026-01-24
Method: `ec.exe -flatshort` vs `specs/*.md` + `research/*.md`

## Specification Sources

| Source | Files | Lines |
|--------|-------|-------|
| specs/*.md | 8 | 831 |
| research/*.md | 1 | 184 |

## Classes Analyzed

| Class | Spec'd Features | Actual Features | Drift |
|-------|-----------------|-----------------|-------|
| SIMPLE_TUI | 34 | 0 | -34 |

## Feature-Level Drift

### Specified, Implemented ✓
- (none matched)

### Specified, NOT Implemented ✗
- `clear_modal` ✗
- `end_box` ✗
- `handle_event` ✗
- `is_focused` ✗
- `is_visible` ✗
- `list_box` ✗
- `list_named` ✗
- `menu_bar` ✗
- `password_field` ✗
- `progress_bar` ✗
- ... and 24 more

### Implemented, NOT Specified
- (none)

## Summary

| Category | Count |
|----------|-------|
| Spec'd, implemented | 0 |
| Spec'd, missing | 34 |
| Implemented, not spec'd | 0 |
| **Overall Drift** | **HIGH** |

## Conclusion

**simple_tui** has high drift. Significant gaps between spec and implementation.
