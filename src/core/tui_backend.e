note
	description: "[
		TUI_BACKEND - Abstract terminal backend

		Provides platform-independent interface for:
		- Terminal initialization/cleanup
		- Screen size queries
		- Input event polling
		- Output rendering

		Implementations: TUI_BACKEND_WINDOWS (Win32), TUI_BACKEND_ANSI (Unix)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	TUI_BACKEND

feature -- Initialization

	initialize
			-- Initialize the terminal for TUI mode.
			-- Enables raw mode, hides cursor, clears screen.
		deferred
		end

	shutdown
			-- Restore terminal to normal mode.
		deferred
		end

feature -- Screen

	width: INTEGER
			-- Terminal width in columns.
		deferred
		ensure
			positive: Result > 0
		end

	height: INTEGER
			-- Terminal height in rows.
		deferred
		ensure
			positive: Result > 0
		end

	refresh_size
			-- Update width/height from terminal.
		deferred
		end

feature -- Cursor

	set_cursor_position (x, y: INTEGER)
			-- Move cursor to position (1-based).
		require
			valid_x: x >= 1
			valid_y: y >= 1
		deferred
		end

	show_cursor
			-- Make cursor visible.
		deferred
		end

	hide_cursor
			-- Make cursor invisible.
		deferred
		end

feature -- Output

	clear_screen
			-- Clear entire screen.
		deferred
		end

	write_cell (x, y: INTEGER; cell: TUI_CELL)
			-- Write a single cell at position.
		require
			valid_x: x >= 1 and x <= width
			valid_y: y >= 1 and y <= height
			cell_exists: cell /= Void
		deferred
		end

	write_cells (cells: ARRAYED_LIST [TUPLE [x, y: INTEGER; cell: TUI_CELL]])
			-- Write multiple cells (optimized batch).
		require
			cells_exist: cells /= Void
		deferred
		end

	flush
			-- Flush output buffer to terminal.
		deferred
		end

	reset_style
			-- Reset to default terminal style.
		deferred
		end

feature -- Input

	poll_event: TUI_EVENT
			-- Poll for input event (non-blocking).
			-- Returns empty event if no input available.
		deferred
		ensure
			result_exists: Result /= Void
		end

	wait_event: TUI_EVENT
			-- Wait for input event (blocking).
		deferred
		ensure
			result_exists: Result /= Void
		end

	has_event: BOOLEAN
			-- Is there an event waiting?
		deferred
		end

feature -- Capabilities

	supports_true_color: BOOLEAN
			-- Does terminal support 24-bit color?
		deferred
		end

	supports_256_colors: BOOLEAN
			-- Does terminal support 256 colors?
		deferred
		end

	supports_mouse: BOOLEAN
			-- Does terminal support mouse input?
		deferred
		end

	enable_mouse
			-- Enable mouse event reporting.
		require
			supports: supports_mouse
		deferred
		end

	disable_mouse
			-- Disable mouse event reporting.
		deferred
		end

feature -- Alternate screen

	enter_alternate_screen
			-- Switch to alternate screen buffer.
		deferred
		end

	leave_alternate_screen
			-- Return to main screen buffer.
		deferred
		end

end
