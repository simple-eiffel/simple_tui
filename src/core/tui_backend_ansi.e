note
	description: "[
		TUI_BACKEND_ANSI - What every terminal backend shares

		Output as ANSI escape sequences into a buffer, and the capability
		answers. A descendant supplies how the terminal is set up, how the
		buffer reaches it and how input arrives: TUI_BACKEND_WINDOWS (Win32
		console) and TUI_BACKEND_POSIX (macOS and Linux).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	TUI_BACKEND_ANSI

inherit
	TUI_BACKEND

feature -- Screen

	width: INTEGER
			-- Terminal width in columns.
		do
			Result := cached_width
		end

	height: INTEGER
			-- Terminal height in rows.
		do
			Result := cached_height
		end

feature -- Cursor

	set_cursor_position (x, y: INTEGER)
			-- Move cursor to position (1-based).
		do
			append_escape ("[" + y.out + ";" + x.out + "H")
		end

	show_cursor
			-- Make cursor visible.
		do
			append_escape ("[?25h")
		end

	hide_cursor
			-- Make cursor invisible.
		do
			append_escape ("[?25l")
		end

feature -- Output

	clear_screen
			-- Clear entire screen.
		do
			append_escape ("[2J")
			append_escape ("[H")
		end

	write_cell (x, y: INTEGER; cell: TUI_CELL)
			-- Write a single cell at position.
		do
			set_cursor_position (x, y)
			apply_style (cell.style)
			wide_output_buffer.append_character (cell.character)
		end

	write_cells (a_cells: ARRAYED_LIST [TUPLE [x, y: INTEGER; cell: TUI_CELL]])
			-- Write multiple cells (optimized batch).
		local
			last_x, last_y, i: INTEGER
			l_t: TUPLE [x, y: INTEGER; cell: TUI_CELL]
			l_prev_style: detachable TUI_STYLE
		do
			last_x := -1
			last_y := -1
			from i := 1 until i > a_cells.count loop
				l_t := a_cells.i_th (i)
				-- Only move cursor if not sequential
				if l_t.y /= last_y or l_t.x /= last_x + 1 then
					set_cursor_position (l_t.x, l_t.y)
				end
				-- Only change style if different
				if l_prev_style = Void or else not l_prev_style.same_style (l_t.cell.style) then
					apply_style (l_t.cell.style)
					l_prev_style := l_t.cell.style
				end
				wide_output_buffer.append_character (l_t.cell.character)
				last_x := l_t.x
				last_y := l_t.y
				i := i + 1
			end
		end

	append_char32 (a_c: CHARACTER_32)
			-- Append CHARACTER_32 to wide output buffer (direct UTF-16).
			-- Also maintains UTF-8 buffer for backward compatibility with tests.
		local
			l_code: NATURAL_32
		do
			-- Append to wide buffer (primary output)
			wide_output_buffer.append_character (a_c)

			-- Also maintain UTF-8 buffer for test compatibility
			l_code := a_c.natural_32_code
			if l_code < 0x80 then
				output_buffer.append_character (l_code.to_character_8)
			elseif l_code < 0x800 then
				output_buffer.append_character ((0xC0 | (l_code |>> 6)).to_character_8)
				output_buffer.append_character ((0x80 | (l_code & 0x3F)).to_character_8)
			elseif l_code < 0x10000 then
				output_buffer.append_character ((0xE0 | (l_code |>> 12)).to_character_8)
				output_buffer.append_character ((0x80 | ((l_code |>> 6) & 0x3F)).to_character_8)
				output_buffer.append_character ((0x80 | (l_code & 0x3F)).to_character_8)
			else
				output_buffer.append_character ((0xF0 | (l_code |>> 18)).to_character_8)
				output_buffer.append_character ((0x80 | ((l_code |>> 12) & 0x3F)).to_character_8)
				output_buffer.append_character ((0x80 | ((l_code |>> 6) & 0x3F)).to_character_8)
				output_buffer.append_character ((0x80 | (l_code & 0x3F)).to_character_8)
			end
		ensure
			wide_buffer_grew: wide_output_buffer.count > old wide_output_buffer.count
		end

	reset_style
			-- Reset to default terminal style.
		do
			append_escape ("[0m")
		end

feature -- Input

	poll_event: TUI_EVENT
			-- Poll for input event (non-blocking).
		do
			if has_event then
				Result := read_event
			else
				create Result.make_none
			end
		end

	wait_event: TUI_EVENT
			-- Wait for input event (blocking).
		do
			Result := read_event
		end

feature -- Capabilities

	supports_true_color: BOOLEAN
			-- Does terminal support 24-bit color?
		do
			Result := True -- Windows Terminal supports it
		end

	supports_256_colors: BOOLEAN
			-- Does terminal support 256 colors?
		do
			Result := True
		end

	supports_mouse: BOOLEAN
			-- Does terminal support mouse input?
		do
			Result := True
		end

	enable_mouse
			-- Enable mouse event reporting.
		do
			append_escape ("[?1000h") -- Basic mouse
			append_escape ("[?1006h") -- SGR extended
			flush
		end

	disable_mouse
			-- Disable mouse event reporting.
		do
			append_escape ("[?1000l")
			append_escape ("[?1006l")
			flush
		end

feature -- Alternate screen

	enter_alternate_screen
			-- Switch to alternate screen buffer.
		do
			append_escape ("[?1049h")
			flush
		end

	leave_alternate_screen
			-- Return to main screen buffer.
		do
			append_escape ("[?1049l")
			flush
		end

feature {ANY} -- Test Access

	output_buffer_for_test: STRING_8
			-- Access to output buffer for testing (UTF-8).
		do
			Result := output_buffer
		end

	wide_buffer_for_test: STRING_32
			-- Access to wide output buffer for testing (UTF-16).
		do
			Result := wide_output_buffer
		end

	test_append_char32 (a_c: CHARACTER_32)
			-- Test access to append_char32.
		do
			append_char32 (a_c)
		end

feature {NONE} -- Implementation

	cached_width: INTEGER
	cached_height: INTEGER
	is_initialized: BOOLEAN
	output_buffer: STRING_8
			-- Buffer for escape sequences (ASCII/UTF-8).

	wide_output_buffer: STRING_32
			-- Buffer for actual output.

	Esc: STRING = "%/27/"

	read_event: TUI_EVENT
			-- Read and parse input event, waiting for one.
		deferred
		ensure
			result_exists: Result /= Void
		end

	append_escape (a_seq: STRING)
			-- Append ESC + sequence to wide output buffer.
		require
			sequence_not_empty: a_seq /= Void and then not a_seq.is_empty
		local
			l_full_seq: STRING_32
			i: INTEGER
		do
			create l_full_seq.make (a_seq.count + 1)
			l_full_seq.append_character ('%/27/')
			from i := 1 until i > a_seq.count loop
				l_full_seq.append_character (a_seq.item (i))
				i := i + 1
			end
			wide_output_buffer.append (l_full_seq)
		ensure
			buffer_grew: wide_output_buffer.count >= old wide_output_buffer.count + a_seq.count + 1
		end

	apply_style (a_s: TUI_STYLE)
			-- Append ANSI codes for style to wide output buffer.
		require
			style_exists: a_s /= Void
		local
			l_codes: STRING
		do
			create l_codes.make_empty

			-- Reset first
			l_codes.append ("0")

			-- Attributes
			if a_s.is_bold then l_codes.append (";1") end
			if a_s.is_dim then l_codes.append (";2") end
			if a_s.is_italic then l_codes.append (";3") end
			if a_s.is_underline then l_codes.append (";4") end
			if a_s.is_blink then l_codes.append (";5") end
			if a_s.is_reverse then l_codes.append (";7") end
			if a_s.is_strikethrough then l_codes.append (";9") end

			-- Foreground
			if a_s.foreground.is_indexed then
				if a_s.foreground.index < 8 then
					l_codes.append (";" + (30 + a_s.foreground.index).out)
				elseif a_s.foreground.index < 16 then
					l_codes.append (";" + (90 + a_s.foreground.index - 8).out)
				else
					l_codes.append (";38;5;" + a_s.foreground.index.out)
				end
			elseif a_s.foreground.is_rgb then
				l_codes.append (";38;2;" + a_s.foreground.red.out + ";" + a_s.foreground.green.out + ";" + a_s.foreground.blue.out)
			end

			-- Background
			if a_s.background.is_indexed then
				if a_s.background.index < 8 then
					l_codes.append (";" + (40 + a_s.background.index).out)
				elseif a_s.background.index < 16 then
					l_codes.append (";" + (100 + a_s.background.index - 8).out)
				else
					l_codes.append (";48;5;" + a_s.background.index.out)
				end
			elseif a_s.background.is_rgb then
				l_codes.append (";48;2;" + a_s.background.red.out + ";" + a_s.background.green.out + ";" + a_s.background.blue.out)
			end

			append_escape ("[" + l_codes + "m")
		end

end
