note
	description: "[
		TUI_BACKEND_POSIX - Terminal backend for macOS and Linux

		termios raw mode and UTF-8 on the terminal's streams. TUI_INPUT_PARSER
		turns the input bytes into events. A resize is seen by asking the
		terminal for its size while waiting for input, so no signal handler
		is needed.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_BACKEND_POSIX

inherit
	TUI_BACKEND_ANSI

create
	make

feature {NONE} -- Initialization

	make
			-- Create POSIX backend.
		do
			cached_width := 80
			cached_height := 24
			is_initialized := False
			create output_buffer.make (1024)
			create wide_output_buffer.make (1024)
			create parser.make
		ensure
			width_default: cached_width = 80
			height_default: cached_height = 24
			not_initialized: not is_initialized
			buffers_empty: output_buffer.is_empty and wide_output_buffer.is_empty
		end

feature -- Initialization

	initialize
			-- Initialize the terminal for TUI mode.
		do
			saved_terminal := c_raw_begin
			refresh_size
			append_escape ("[?1049h") -- Alternate screen
			append_escape ("[?25l")   -- Hide cursor
			enable_mouse
			is_initialized := True
		end

	shutdown
			-- Restore terminal to normal mode.
		do
			if is_initialized then
				disable_mouse
				append_escape ("[?25h")   -- Show cursor
				append_escape ("[?1049l") -- Main screen
				append_escape ("[0m")     -- Reset attributes
				flush
				c_raw_end (saved_terminal)
				saved_terminal := default_pointer
				is_initialized := False
			end
		end

feature -- Screen

	refresh_size
			-- Update width/height from terminal.
		local
			w, h: INTEGER
		do
			c_size ($w, $h)
			if w > 0 then
				cached_width := w
			end
			if h > 0 then
				cached_height := h
			end
		end

feature -- Output

	flush
			-- Write the output buffer to the terminal as UTF-8.
		local
			l_bytes: STRING_8
			l_converter: UTF_CONVERTER
			l_text: C_STRING
		do
			if not wide_output_buffer.is_empty then
				create l_converter
				l_bytes := l_converter.string_32_to_utf_8_string_8 (wide_output_buffer)
				create l_text.make (l_bytes)
				c_write (l_text.item, l_bytes.count)
				wide_output_buffer.wipe_out
				output_buffer.wipe_out
			end
		ensure then
			buffers_empty: wide_output_buffer.is_empty and output_buffer.is_empty
		end

feature -- Input

	has_event: BOOLEAN
			-- Is there an event waiting?
		do
			Result := parser.has_pending or else c_input_ready (0) /= 0 or else size_changed
		end

feature {NONE} -- Implementation

	parser: TUI_INPUT_PARSER
			-- Bytes read and not yet turned into events.

	saved_terminal: POINTER
			-- The terminal's settings before `initialize'.

	Escape_wait_ms: INTEGER = 25
			-- How long the rest of an escape sequence may take to arrive.

	Idle_wait_ms: INTEGER = 200
			-- How often an idle wait looks for a resize.

	Read_size: INTEGER = 4096

	size_changed: BOOLEAN
			-- Does the terminal now differ from the cached size?
		local
			w, h: INTEGER
		do
			w := cached_width
			h := cached_height
			c_size ($w, $h)
			Result := w /= cached_width or h /= cached_height
		end

	read_input: BOOLEAN
			-- Read what is waiting into `parser'. False at end of input.
		local
			l_buffer: MANAGED_POINTER
			l_bytes: STRING_8
			l_count, i: INTEGER
		do
			create l_buffer.make (Read_size)
			l_count := c_read (l_buffer.item, Read_size)
			Result := l_count > 0
			create l_bytes.make (l_count)
			from
				i := 0
			until
				i >= l_count
			loop
				l_bytes.append_character (l_buffer.read_natural_8 (i).to_character_8)
				i := i + 1
			end
			parser.append_bytes (l_bytes)
		end

	read_event: TUI_EVENT
			-- <Precursor>
		local
			l_found: detachable TUI_EVENT
			l_ended: BOOLEAN
		do
			from
			until
				l_found /= Void or l_ended
			loop
				if parser.has_pending then
					l_found := parser.next_event (True)
					if l_found = Void then
						-- The start of a sequence: give the rest a moment.
						if c_input_ready (Escape_wait_ms) /= 0 then
							l_ended := not read_input
						else
							l_found := parser.next_event (False)
						end
					end
				elseif size_changed then
					refresh_size
					create {TUI_EVENT} l_found.make_resize (cached_width, cached_height)
				elseif c_input_ready (Idle_wait_ms) /= 0 then
					l_ended := not read_input
				end
			end
			if attached l_found as al_event then
				Result := al_event
			else
				create Result.make_none
			end
		end

feature {NONE} -- External

	c_raw_begin: POINTER
		external "C inline use %"simple_tui_posix.h%""
		alias "return stp_raw_begin ();"
		end

	c_raw_end (a_saved: POINTER)
		external "C inline use %"simple_tui_posix.h%""
		alias "stp_raw_end ((void *) $a_saved);"
		end

	c_size (w, h: TYPED_POINTER [INTEGER])
		external "C inline use %"simple_tui_posix.h%""
		alias "stp_size ((int *) $w, (int *) $h);"
		end

	c_write (a_bytes: POINTER; a_count: INTEGER)
			-- May wait on a slow terminal. Safe to mark: `a_bytes' is a C_STRING.
		external "C blocking inline use %"simple_tui_posix.h%""
		alias "stp_write ((const char *) $a_bytes, (int) $a_count);"
		end

	c_input_ready (a_timeout_ms: INTEGER): INTEGER
		external "C blocking inline use %"simple_tui_posix.h%""
		alias "return stp_input_ready ((int) $a_timeout_ms);"
		end

	c_read (a_buffer: POINTER; a_capacity: INTEGER): INTEGER
			-- Safe to mark: `a_buffer' is a MANAGED_POINTER on the C heap.
		external "C blocking inline use %"simple_tui_posix.h%""
		alias "return stp_read ((void *) $a_buffer, (int) $a_capacity);"
		end

end
