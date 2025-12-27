note
	description: "[
		TUI_BACKEND_WINDOWS - Windows Console API backend

		Uses Win32 Console API for terminal operations:
		- SetConsoleCursorPosition
		- WriteConsoleOutputCharacter
		- ReadConsoleInput
		- GetConsoleScreenBufferInfo

		Also supports ANSI escape codes via ENABLE_VIRTUAL_TERMINAL_PROCESSING
		(Windows 10+).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_BACKEND_WINDOWS

inherit
	TUI_BACKEND

create
	make

feature {NONE} -- Initialization

	make
			-- Create Windows backend.
		do
			cached_width := 80
			cached_height := 24
			is_initialized := False
			old_console_mode := 0
			create output_buffer.make (1024)
			create wide_output_buffer.make (1024)
		ensure
			width_default: cached_width = 80
			height_default: cached_height = 24
			not_initialized: not is_initialized
			buffers_empty: output_buffer.is_empty and wide_output_buffer.is_empty
		end

feature -- Initialization

	initialize
			-- Initialize the terminal for TUI mode.
		local
			l_out_mode, l_in_mode: INTEGER
		do
			-- Get console handles
			stdout_handle := c_get_std_handle (-11) -- STD_OUTPUT_HANDLE
			stdin_handle := c_get_std_handle (-10)  -- STD_INPUT_HANDLE

			-- Save old console modes
			old_console_mode := c_get_console_mode (stdin_handle)
			old_output_mode := c_get_console_mode (stdout_handle)

			-- Enable virtual terminal processing (ANSI) - must OR with existing mode
			l_out_mode := c_get_console_mode (stdout_handle)
			l_out_mode := l_out_mode | 0x0004  -- ENABLE_VIRTUAL_TERMINAL_PROCESSING
			c_set_console_mode (stdout_handle, l_out_mode)

			-- Enable mouse input using Windows console input records (NOT VT sequences)
			-- Note: Do NOT use ENABLE_VIRTUAL_TERMINAL_INPUT (0x0200) as it conflicts
			-- with ReadConsoleInputW - it would send mouse as ANSI sequences instead of records
			l_in_mode := c_get_console_mode (stdin_handle)
			l_in_mode := l_in_mode | 0x0010  -- ENABLE_MOUSE_INPUT
			l_in_mode := l_in_mode | 0x0080  -- ENABLE_EXTENDED_FLAGS (needed with mouse)
			l_in_mode := l_in_mode.bit_and (0x7FFFFFFF - 0x0040)  -- Disable ENABLE_QUICK_EDIT_MODE (conflicts with mouse)
			c_set_console_mode (stdin_handle, l_in_mode)

			-- Set UTF-8 code page for proper Unicode output
			c_set_console_output_cp (65001)

			-- Get initial size
			refresh_size

			-- Enter alternate screen and hide cursor
			append_escape ("[?1049h") -- Alternate screen
			append_escape ("[?25l")   -- Hide cursor
			flush

			is_initialized := True
		end

	shutdown
			-- Restore terminal to normal mode.
		do
			if is_initialized then
				-- Show cursor and leave alternate screen
				append_escape ("[?25h")   -- Show cursor
				append_escape ("[?1049l") -- Main screen
				append_escape ("[0m")     -- Reset attributes
				flush

				-- Restore old console modes
				c_set_console_mode (stdin_handle, old_console_mode)
				c_set_console_mode (stdout_handle, old_output_mode)

				is_initialized := False
			end
		end

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

	refresh_size
			-- Update width/height from terminal.
		local
			w, h: INTEGER
		do
			c_get_console_size (stdout_handle, $w, $h)
			if w > 0 then
				cached_width := w
			end
			if h > 0 then
				cached_height := h
			end
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

	write_cells (cells: ARRAYED_LIST [TUPLE [x, y: INTEGER; cell: TUI_CELL]])
			-- Write multiple cells (optimized batch).
		local
			last_x, last_y, i: INTEGER
			t: TUPLE [x, y: INTEGER; cell: TUI_CELL]
			prev_style: detachable TUI_STYLE
		do
			last_x := -1
			last_y := -1
			from i := 1 until i > cells.count loop
				t := cells.i_th (i)
				-- Only move cursor if not sequential
				if t.y /= last_y or t.x /= last_x + 1 then
					set_cursor_position (t.x, t.y)
				end
				-- Only change style if different
				if prev_style = Void or else not prev_style.same_style (t.cell.style) then
					apply_style (t.cell.style)
					prev_style := t.cell.style
				end
				wide_output_buffer.append_character (t.cell.character)
				last_x := t.x
				last_y := t.y
				i := i + 1
			end
		end

	append_char32 (c: CHARACTER_32)
			-- Append CHARACTER_32 to wide output buffer (direct UTF-16).
			-- Also maintains UTF-8 buffer for backward compatibility with tests.
		local
			code: NATURAL_32
		do
			-- Append to wide buffer (primary output)
			wide_output_buffer.append_character (c)

			-- Also maintain UTF-8 buffer for test compatibility
			code := c.natural_32_code
			if code < 0x80 then
				output_buffer.append_character (code.to_character_8)
			elseif code < 0x800 then
				output_buffer.append_character ((0xC0 | (code |>> 6)).to_character_8)
				output_buffer.append_character ((0x80 | (code & 0x3F)).to_character_8)
			elseif code < 0x10000 then
				output_buffer.append_character ((0xE0 | (code |>> 12)).to_character_8)
				output_buffer.append_character ((0x80 | ((code |>> 6) & 0x3F)).to_character_8)
				output_buffer.append_character ((0x80 | (code & 0x3F)).to_character_8)
			else
				output_buffer.append_character ((0xF0 | (code |>> 18)).to_character_8)
				output_buffer.append_character ((0x80 | ((code |>> 12) & 0x3F)).to_character_8)
				output_buffer.append_character ((0x80 | ((code |>> 6) & 0x3F)).to_character_8)
				output_buffer.append_character ((0x80 | (code & 0x3F)).to_character_8)
			end
		ensure
			wide_buffer_grew: wide_output_buffer.count > old wide_output_buffer.count
		end

	flush
			-- Flush wide output buffer to terminal using WriteConsoleW.
		local
			l_utf16: SPECIAL [NATURAL_16]
			l_converter: UTF_CONVERTER
		do
			if not wide_output_buffer.is_empty then
				-- Convert STRING_32 to proper UTF-16 using ISE's UTF_CONVERTER
				create l_converter
				l_utf16 := l_converter.string_32_to_utf_16_0 (wide_output_buffer)
				c_write_console_utf16 (stdout_handle, l_utf16.base_address, l_utf16.count - 1)  -- -1 for null terminator
				wide_output_buffer.wipe_out
				output_buffer.wipe_out  -- Keep in sync
			end
		ensure then
			buffers_empty: wide_output_buffer.is_empty and output_buffer.is_empty
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

	has_event: BOOLEAN
			-- Is there an event waiting?
		do
			Result := c_has_console_input (stdin_handle)
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

	test_append_char32 (c: CHARACTER_32)
			-- Test access to append_char32.
		do
			append_char32 (c)
		end

feature {NONE} -- Implementation

	stdout_handle: POINTER
	stdin_handle: POINTER
	old_console_mode: INTEGER
	old_output_mode: INTEGER
	cached_width: INTEGER
	cached_height: INTEGER
	is_initialized: BOOLEAN
	output_buffer: STRING_8
			-- Buffer for escape sequences (ASCII/UTF-8).

	wide_output_buffer: STRING_32
			-- Buffer for actual output (UTF-16 for WriteConsoleW).

	Esc: STRING = "%/27/"

	append_escape (seq: STRING)
			-- Append ESC + sequence to wide output buffer.
		require
			sequence_not_empty: seq /= Void and then not seq.is_empty
		local
			full_seq: STRING_32
			i: INTEGER
		do
			create full_seq.make (seq.count + 1)
			full_seq.append_character ('%/27/')
			from i := 1 until i > seq.count loop
				full_seq.append_character (seq.item (i))
				i := i + 1
			end
			wide_output_buffer.append (full_seq)
		ensure
			buffer_grew: wide_output_buffer.count >= old wide_output_buffer.count + seq.count + 1
		end

	apply_style (s: TUI_STYLE)
			-- Append ANSI codes for style to wide output buffer.
		require
			style_exists: s /= Void
		local
			codes: STRING
		do
			create codes.make_empty

			-- Reset first
			codes.append ("0")

			-- Attributes
			if s.is_bold then codes.append (";1") end
			if s.is_dim then codes.append (";2") end
			if s.is_italic then codes.append (";3") end
			if s.is_underline then codes.append (";4") end
			if s.is_blink then codes.append (";5") end
			if s.is_reverse then codes.append (";7") end
			if s.is_strikethrough then codes.append (";9") end

			-- Foreground
			if s.foreground.is_indexed then
				if s.foreground.index < 8 then
					codes.append (";" + (30 + s.foreground.index).out)
				elseif s.foreground.index < 16 then
					codes.append (";" + (90 + s.foreground.index - 8).out)
				else
					codes.append (";38;5;" + s.foreground.index.out)
				end
			elseif s.foreground.is_rgb then
				codes.append (";38;2;" + s.foreground.red.out + ";" + s.foreground.green.out + ";" + s.foreground.blue.out)
			end

			-- Background
			if s.background.is_indexed then
				if s.background.index < 8 then
					codes.append (";" + (40 + s.background.index).out)
				elseif s.background.index < 16 then
					codes.append (";" + (100 + s.background.index - 8).out)
				else
					codes.append (";48;5;" + s.background.index.out)
				end
			elseif s.background.is_rgb then
				codes.append (";48;2;" + s.background.red.out + ";" + s.background.green.out + ";" + s.background.blue.out)
			end

			append_escape ("[" + codes + "m")
		end

	read_event: TUI_EVENT
			-- Read and parse input event.
		local
			key_code, char_code, ctrl_keys: INTEGER
			event_type: INTEGER
			x, y: INTEGER
		do
			c_read_console_input (stdin_handle, $event_type, $key_code, $char_code, $ctrl_keys, $x, $y)

			inspect event_type
			when 1 then -- KEY_EVENT
				if char_code > 0 then
					create Result.make_char (char_code.to_character_32, modifiers_from_ctrl_keys (ctrl_keys))
				else
					create Result.make_key (translate_key (key_code), modifiers_from_ctrl_keys (ctrl_keys))
				end
			when 2 then -- MOUSE_EVENT
				create Result.make_mouse (x + 1, y + 1, 1, {TUI_EVENT}.Type_mouse_press, 0)
			when 4 then -- WINDOW_BUFFER_SIZE_EVENT
				refresh_size
				create Result.make_resize (cached_width, cached_height)
			else
				create Result.make_none
			end
		end

	modifiers_from_ctrl_keys (ctrl_keys: INTEGER): INTEGER
			-- Convert Win32 control key state to our modifiers.
		do
			Result := 0
			if (ctrl_keys & 0x0008) /= 0 or (ctrl_keys & 0x0004) /= 0 then -- LEFT/RIGHT_CTRL
				Result := Result | {TUI_EVENT}.Mod_ctrl
			end
			if (ctrl_keys & 0x0002) /= 0 or (ctrl_keys & 0x0001) /= 0 then -- LEFT/RIGHT_ALT
				Result := Result | {TUI_EVENT}.Mod_alt
			end
			if (ctrl_keys & 0x0010) /= 0 then -- SHIFT
				Result := Result | {TUI_EVENT}.Mod_shift
			end
		end

	translate_key (vk: INTEGER): INTEGER
			-- Translate Win32 virtual key code to TUI key code.
		do
			inspect vk
			when 0x0D then Result := {TUI_EVENT}.Key_enter
			when 0x1B then Result := {TUI_EVENT}.Key_escape
			when 0x09 then Result := {TUI_EVENT}.Key_tab
			when 0x08 then Result := {TUI_EVENT}.Key_backspace
			when 0x2E then Result := {TUI_EVENT}.Key_delete
			when 0x26 then Result := {TUI_EVENT}.Key_up
			when 0x28 then Result := {TUI_EVENT}.Key_down
			when 0x25 then Result := {TUI_EVENT}.Key_left
			when 0x27 then Result := {TUI_EVENT}.Key_right
			when 0x24 then Result := {TUI_EVENT}.Key_home
			when 0x23 then Result := {TUI_EVENT}.Key_end
			when 0x21 then Result := {TUI_EVENT}.Key_page_up
			when 0x22 then Result := {TUI_EVENT}.Key_page_down
			when 0x2D then Result := {TUI_EVENT}.Key_insert
			when 0x70 then Result := {TUI_EVENT}.Key_f1
			when 0x71 then Result := {TUI_EVENT}.Key_f2
			when 0x72 then Result := {TUI_EVENT}.Key_f3
			when 0x73 then Result := {TUI_EVENT}.Key_f4
			when 0x74 then Result := {TUI_EVENT}.Key_f5
			when 0x75 then Result := {TUI_EVENT}.Key_f6
			when 0x76 then Result := {TUI_EVENT}.Key_f7
			when 0x77 then Result := {TUI_EVENT}.Key_f8
			when 0x78 then Result := {TUI_EVENT}.Key_f9
			when 0x79 then Result := {TUI_EVENT}.Key_f10
			when 0x7A then Result := {TUI_EVENT}.Key_f11
			when 0x7B then Result := {TUI_EVENT}.Key_f12
			else Result := vk
			end
		end

feature {NONE} -- External

	c_get_std_handle (n: INTEGER): POINTER
		external "C inline use <windows.h>"
		alias "return GetStdHandle((DWORD)$n);"
		end

	c_get_console_mode (h: POINTER): INTEGER
		external "C inline use <windows.h>"
		alias "[
			DWORD mode = 0;
			GetConsoleMode((HANDLE)$h, &mode);
			return (EIF_INTEGER)mode;
		]"
		end

	c_set_console_mode (h: POINTER; mode: INTEGER)
		external "C inline use <windows.h>"
		alias "SetConsoleMode((HANDLE)$h, (DWORD)$mode);"
		end

	c_set_console_output_cp (cp: INTEGER)
		external "C inline use <windows.h>"
		alias "SetConsoleOutputCP((UINT)$cp);"
		end

	c_get_console_size (h: POINTER; w, ht: TYPED_POINTER [INTEGER])
		external "C inline use <windows.h>"
		alias "[
			CONSOLE_SCREEN_BUFFER_INFO info;
			if (GetConsoleScreenBufferInfo((HANDLE)$h, &info)) {
				*$w = info.srWindow.Right - info.srWindow.Left + 1;
				*$ht = info.srWindow.Bottom - info.srWindow.Top + 1;
			}
		]"
		end

	c_write_console (h: POINTER; s: POINTER; len: INTEGER)
		external "C inline use <windows.h>"
		alias "[
			DWORD written;
			WriteConsoleA((HANDLE)$h, (const char*)$s, (DWORD)$len, &written, NULL);
		]"
		end

	c_has_console_input (h: POINTER): BOOLEAN
		external "C inline use <windows.h>"
		alias "[
			DWORD count = 0;
			GetNumberOfConsoleInputEvents((HANDLE)$h, &count);
			return count > 0;
		]"
		end

	c_read_console_input (h: POINTER; etype, kcode, ccode, ctrl, mx, my: TYPED_POINTER [INTEGER])
		external "C inline use <windows.h>"
		alias "[
			INPUT_RECORD rec;
			DWORD read;
			*$etype = 0;
			if (ReadConsoleInputW((HANDLE)$h, &rec, 1, &read) && read > 0) {
				*$etype = rec.EventType;
				if (rec.EventType == KEY_EVENT && rec.Event.KeyEvent.bKeyDown) {
					*$kcode = rec.Event.KeyEvent.wVirtualKeyCode;
					*$ccode = rec.Event.KeyEvent.uChar.UnicodeChar;
					*$ctrl = rec.Event.KeyEvent.dwControlKeyState;
				} else if (rec.EventType == MOUSE_EVENT) {
					*$mx = rec.Event.MouseEvent.dwMousePosition.X;
					*$my = rec.Event.MouseEvent.dwMousePosition.Y;
				} else if (rec.EventType == WINDOW_BUFFER_SIZE_EVENT) {
					// Handled elsewhere
				}
			}
		]"
		end

	c_write_console_utf16 (h: POINTER; s: POINTER; len: INTEGER)
			-- Write UTF-16 string (SPECIAL [NATURAL_16]) to console using WriteConsoleW.
			-- The input is already proper 16-bit UTF-16 from UTF_CONVERTER.
		external "C inline use <windows.h>"
		alias "[
			DWORD written;
			WriteConsoleW((HANDLE)$h, (const wchar_t*)$s, (DWORD)$len, &written, NULL);
		]"
		end

end
