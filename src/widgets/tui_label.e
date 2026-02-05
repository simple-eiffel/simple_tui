note
	description: "[
		TUI_LABEL - Static text display widget

		Features:
		- Single or multi-line text
		- Text alignment (left, center, right)
		- Word wrapping (optional)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_LABEL

inherit
	TUI_WIDGET
		redefine
			preferred_width,
			preferred_height
		end

create
	make,
	make_with_text

feature {NONE} -- Initialization

	make (a_width: INTEGER)
			-- Create label with width.
		require
			valid_width: a_width > 0
		do
			make_widget
			width := a_width
			height := 1
			text := ""
			align := Align_left
			wrap := False
		ensure
			width_set: width = a_width
		end

	make_with_text (a_text: READABLE_STRING_GENERAL)
			-- Create label with text, auto-sizing.
			-- If input is STRING_8, it's interpreted as UTF-8 and converted.
		require
			text_exists: a_text /= Void
		do
			make_widget
			text := utf8_to_string_32 (a_text)
			width := text.count.max (1)
			height := 1
			align := Align_left
			wrap := False
		end

feature -- Access

	text: STRING_32
			-- Label text.

	align: INTEGER
			-- Text alignment.

	wrap: BOOLEAN
			-- Word wrap enabled?

feature -- Alignment constants

	Align_left: INTEGER = 0
	Align_center: INTEGER = 1
	Align_right: INTEGER = 2

feature -- Modification

	set_text (a_t: READABLE_STRING_GENERAL)
			-- Set label text.
			-- If input is STRING_8, it's interpreted as UTF-8 and converted.
		require
			t_exists: a_t /= Void
		do
			text := utf8_to_string_32 (a_t)
		end

	set_align (a_a: INTEGER)
			-- Set text alignment.
		require
			valid: a_a >= Align_left and a_a <= Align_right
		do
			align := a_a
		ensure
			align_set: align = a_a
		end

	set_wrap (a_w: BOOLEAN)
			-- Set word wrapping.
		do
			wrap := a_w
		ensure
			wrap_set: wrap = a_w
		end

feature -- Rendering

	render (a_buffer: TUI_BUFFER)
			-- Render label to buffer.
		local
			ax, ay: INTEGER
			l_lines: LIST [STRING_32]
			l_line: STRING_32
			draw_x, row, i: INTEGER
		do
			ax := absolute_x
			ay := absolute_y
			logger.debug_log ("LABEL.render: text=%"" + {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (text) + "%" ax=" + ax.out + " ay=" + ay.out + " buf_h=" + a_buffer.height.out)

			if wrap then
				lines := wrapped_lines
			else
				create {ARRAYED_LIST [STRING_32]} lines.make (1)
				lines.extend (text)
			end

			row := 0
			from i := 1 until i > lines.count loop
				if row < height then
					line := lines.i_th (i)

					-- Calculate X based on alignment
					inspect align
					when Align_left then
						draw_x := ax
					when Align_center then
						draw_x := ax + ((width - line.count) // 2).max (0)
					when Align_right then
						draw_x := ax + (width - line.count).max (0)
					end

					-- Draw line (truncate if needed)
					if line.count > width then
						line := line.substring (1, width)
					end
					a_buffer.put_string (draw_x, ay + row, line, style)

					row := row + 1
				end
				i := i + 1
			end
		end

feature -- Queries

	preferred_width: INTEGER
			-- Preferred width based on text.
		do
			Result := text.count.max (1)
		end

	preferred_height: INTEGER
			-- Preferred height based on text and wrapping.
		do
			if wrap then
				Result := wrapped_lines.count
			else
				Result := 1
			end
		end

feature {NONE} -- Implementation

	utf8_to_string_32 (a_s: READABLE_STRING_GENERAL): STRING_32
			-- Convert input to STRING_32.
			-- If STRING_8, interpret as UTF-8 and decode.
			-- If already STRING_32, use directly.
		local
			l_converter: UTF_CONVERTER
		do
			if attached {READABLE_STRING_8} a_s as al_s8 then
				create l_converter
				Result := l_converter.utf_8_string_8_to_string_32 (s8)
			else
				Result := a_s.to_string_32
			end
		end

	wrapped_lines: ARRAYED_LIST [STRING_32]
			-- Break text into lines that fit within width.
		local
			l_words: LIST [STRING_32]
			l_current_line: STRING_32
			l_word: STRING_32
			i: INTEGER
		do
			create Result.make (5)

			if width <= 0 then
				Result.extend (text)
			else
				words := text.split (' ')
				create current_line.make_empty

				from i := 1 until i > words.count loop
					word := words.i_th (i)

					if current_line.is_empty then
						current_line := word.twin
					elseif current_line.count + 1 + word.count <= width then
						current_line.append_character (' ')
						current_line.append (word)
					else
						Result.extend (current_line)
						current_line := word.twin
					end
					i := i + 1
				end

				if not current_line.is_empty then
					Result.extend (current_line)
				end
			end

			if Result.is_empty then
				Result.extend (create {STRING_32}.make_empty)
			end
		ensure
			not_empty: not Result.is_empty
		end

	logger: SIMPLE_LOGGER
			-- Shared logger instance.
		once
			create Result.make_to_file ("task_manager.log")
			Result.set_level (Result.Level_debug)
		end

invariant
	text_exists: text /= Void
	valid_align: align >= Align_left and align <= Align_right

end
