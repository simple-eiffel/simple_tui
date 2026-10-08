# Changelog

simple_tui had no changelog or recorded version before this file; this entry is a patch-level change.

## 2026-10-08 (patch)

### Fixed
- Note text damaged by the 2026-02-05/06 naming-standards rename is back to its original wording, taken
  from the rename commits' own diffs (12 lines, text only): `task_ai_config.e`, `task_ai_router.e`,
  `task_manager_app.e`, `tui_backend_windows.e`, `tui_buffer.e`, `tui_cell.e`, `tui_label.e`,
  `tui_progress.e` ("API l_keys", "RAG l_pattern", "l_title, l_priority", "multi-l_line", ...).
- Kept: the same commits renamed `$n`, `$h`, `$cp` to `$a_n`, `$a_h`, `$a_cp` inside the inline C of
  `tui_backend_windows.e`. Those follow the renamed arguments and are correct.
