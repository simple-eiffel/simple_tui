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
	TUI_BACKEND_ANSI

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

feature -- Output

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

feature -- Input

	has_event: BOOLEAN
			-- Is there an event waiting?
		do
			Result := c_has_console_input (stdin_handle)
		end

feature {NONE} -- Implementation

	stdout_handle: POINTER
	stdin_handle: POINTER
	old_console_mode: INTEGER
	old_output_mode: INTEGER
	read_event: TUI_EVENT
			-- <Precursor>
		local
			key_code, char_code, ctrl_keys: INTEGER
			l_event_type: INTEGER
			x, y, button_state, event_flags: INTEGER
			l_mouse_type: INTEGER
		do
			c_read_console_input (stdin_handle, $l_event_type, $key_code, $char_code, $ctrl_keys, $x, $y, $button_state, $event_flags)

			inspect l_event_type
			when 1 then -- KEY_EVENT
				if char_code > 0 then
					create Result.make_char (char_code.to_character_32, modifiers_from_ctrl_keys (ctrl_keys))
				else
					create Result.make_key (translate_key (key_code), modifiers_from_ctrl_keys (ctrl_keys))
				end
			when 2 then -- MOUSE_EVENT
				-- Determine mouse event type based on button state and flags
				if (event_flags & 1) /= 0 then
					-- MOUSE_MOVED flag (0x0001) - mouse move event
					l_mouse_type := {TUI_EVENT}.Type_mouse_move
				elseif button_state /= last_button_state then
					if button_state /= 0 then
						-- Button newly pressed - remember which button
						l_mouse_type := {TUI_EVENT}.Type_mouse_press
						last_pressed_button := button_state
					else
						-- Button released
						l_mouse_type := {TUI_EVENT}.Type_mouse_release
					end
					last_button_state := button_state
				else
					-- No change in button state, treat as move
					l_mouse_type := {TUI_EVENT}.Type_mouse_move
				end
				-- Determine which button (1=left, 2=right, 3=middle)
				-- For release events, use the last pressed button state
				if l_mouse_type = {TUI_EVENT}.Type_mouse_release then
					-- Use last_pressed_button to know which was released
					if (last_pressed_button & 1) /= 0 then
						create Result.make_mouse (x + 1, y + 1, 1, l_mouse_type, 0)
					elseif (last_pressed_button & 2) /= 0 then
						create Result.make_mouse (x + 1, y + 1, 2, l_mouse_type, 0)
					elseif (last_pressed_button & 4) /= 0 then
						create Result.make_mouse (x + 1, y + 1, 3, l_mouse_type, 0)
					else
						create Result.make_mouse (x + 1, y + 1, 0, l_mouse_type, 0)
					end
				elseif (button_state & 1) /= 0 then
					create Result.make_mouse (x + 1, y + 1, 1, l_mouse_type, 0)
				elseif (button_state & 2) /= 0 then
					create Result.make_mouse (x + 1, y + 1, 2, l_mouse_type, 0)
				elseif (button_state & 4) /= 0 then
					create Result.make_mouse (x + 1, y + 1, 3, l_mouse_type, 0)
				else
					create Result.make_mouse (x + 1, y + 1, 0, l_mouse_type, 0)
				end
			when 4 then -- WINDOW_BUFFER_SIZE_EVENT
				refresh_size
				create Result.make_resize (cached_width, cached_height)
			else
				create Result.make_none
			end
		end

	last_button_state: INTEGER
			-- Previous mouse button state for detecting press/release.

	last_pressed_button: INTEGER
			-- Button state when last pressed (for reporting on release).

	modifiers_from_ctrl_keys (a_ctrl_keys: INTEGER): INTEGER
			-- Convert Win32 control key state to our modifiers.
		do
			Result := 0
			if (a_ctrl_keys & 0x0008) /= 0 or (a_ctrl_keys & 0x0004) /= 0 then -- LEFT/RIGHT_CTRL
				Result := Result | {TUI_EVENT}.Mod_ctrl
			end
			if (a_ctrl_keys & 0x0002) /= 0 or (a_ctrl_keys & 0x0001) /= 0 then -- LEFT/RIGHT_ALT
				Result := Result | {TUI_EVENT}.Mod_alt
			end
			if (a_ctrl_keys & 0x0010) /= 0 then -- SHIFT
				Result := Result | {TUI_EVENT}.Mod_shift
			end
		end

	translate_key (a_vk: INTEGER): INTEGER
			-- Translate Win32 virtual key code to TUI key code.
		do
			inspect a_vk
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
			else Result := a_vk
			end
		end

feature {NONE} -- External

	c_get_std_handle (a_n: INTEGER): POINTER
		external "C inline use <windows.h>"
		alias "return GetStdHandle((DWORD)$a_n);"
		end

	c_get_console_mode (a_h: POINTER): INTEGER
		external "C inline use <windows.h>"
		alias "[
			DWORD mode = 0;
			GetConsoleMode((HANDLE)$a_h, &mode);
			return (EIF_INTEGER)mode;
		]"
		end

	c_set_console_mode (a_h: POINTER; mode: INTEGER)
		external "C inline use <windows.h>"
		alias "SetConsoleMode((HANDLE)$a_h, (DWORD)$mode);"
		end

	c_set_console_output_cp (a_cp: INTEGER)
		external "C inline use <windows.h>"
		alias "SetConsoleOutputCP((UINT)$a_cp);"
		end

	c_get_console_size (a_h: POINTER; w, ht: TYPED_POINTER [INTEGER])
		external "C inline use <windows.h>"
		alias "[
			CONSOLE_SCREEN_BUFFER_INFO info;
			if (GetConsoleScreenBufferInfo((HANDLE)$a_h, &info)) {
				*$w = info.srWindow.Right - info.srWindow.Left + 1;
				*$ht = info.srWindow.Bottom - info.srWindow.Top + 1;
			}
		]"
		end

	c_write_console (a_h: POINTER; s: POINTER; len: INTEGER)
		external "C inline use <windows.h>"
		alias "[
			DWORD written;
			WriteConsoleA((HANDLE)$a_h, (const char*)$s, (DWORD)$len, &written, NULL);
		]"
		end

	c_has_console_input (a_h: POINTER): BOOLEAN
		external "C inline use <windows.h>"
		alias "[
			DWORD count = 0;
			GetNumberOfConsoleInputEvents((HANDLE)$a_h, &count);
			return count > 0;
		]"
		end

	c_read_console_input (a_h: POINTER; etype, kcode, ccode, ctrl, mx, my, btn_state, evt_flags: TYPED_POINTER [INTEGER])
		external "C inline use <windows.h>"
		alias "[
			INPUT_RECORD rec;
			DWORD read;
			*$etype = 0;
			*$btn_state = 0;
			*$evt_flags = 0;
			if (ReadConsoleInputW((HANDLE)$a_h, &rec, 1, &read) && read > 0) {
				*$etype = rec.EventType;
				if (rec.EventType == KEY_EVENT && rec.Event.KeyEvent.bKeyDown) {
					*$kcode = rec.Event.KeyEvent.wVirtualKeyCode;
					*$ccode = rec.Event.KeyEvent.uChar.UnicodeChar;
					*$ctrl = rec.Event.KeyEvent.dwControlKeyState;
				} else if (rec.EventType == MOUSE_EVENT) {
					*$mx = rec.Event.MouseEvent.dwMousePosition.X;
					*$my = rec.Event.MouseEvent.dwMousePosition.Y;
					*$btn_state = rec.Event.MouseEvent.dwButtonState;
					*$evt_flags = rec.Event.MouseEvent.dwEventFlags;
				} else if (rec.EventType == WINDOW_BUFFER_SIZE_EVENT) {
					// Handled elsewhere
				}
			}
		]"
		end

	c_write_console_utf16 (a_h: POINTER; s: POINTER; len: INTEGER)
			-- Write UTF-16 string (SPECIAL [NATURAL_16]) to console using WriteConsoleW.
			-- The input is already proper 16-bit UTF-16 from UTF_CONVERTER.
		external "C inline use <windows.h>"
		alias "[
			DWORD written;
			WriteConsoleW((HANDLE)$a_h, (const wchar_t*)$s, (DWORD)$len, &written, NULL);
		]"
		end

end
