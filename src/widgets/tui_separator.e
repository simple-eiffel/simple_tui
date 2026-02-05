note
	description: "[
		TUI_SEPARATOR - Visual divider line

		Horizontal or vertical line to separate content.

		EV equivalent: EV_HORIZONTAL_SEPARATOR, EV_VERTICAL_SEPARATOR
		Other frameworks: Separator, Divider, Rule, HR

		Features:
		- Horizontal or vertical orientation
		- Multiple line styles (single, double, dashed)
		- Custom character support
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_SEPARATOR

inherit
	TUI_WIDGET
		redefine
			preferred_width,
			preferred_height
		end

create
	make,
	make_horizontal,
	make_vertical

feature {NONE} -- Initialization

	make (a_length: INTEGER; a_horizontal: BOOLEAN)
			-- Create separator with length and orientation.
		require
			valid_length: a_length > 0
		do
			make_widget
			is_horizontal := a_horizontal
			if is_horizontal then
				width := a_length
				height := 1
			else
				width := 1
				height := a_length
			end
			line_style := Style_single
			update_line_char
		ensure
			horizontal_set: is_horizontal = a_horizontal
		end

	make_horizontal (a_width: INTEGER)
			-- Create horizontal separator.
		require
			valid_width: a_width > 0
		do
			make (a_width, True)
		ensure
			horizontal: is_horizontal
			width_set: width = a_width
		end

	make_vertical (a_height: INTEGER)
			-- Create vertical separator.
		require
			valid_height: a_height > 0
		do
			make (a_height, False)
		ensure
			vertical: not is_horizontal
			height_set: height = a_height
		end

feature -- Access

	is_horizontal: BOOLEAN
			-- Is this a horizontal separator?

	is_vertical: BOOLEAN
			-- Is this a vertical separator?
		do
			Result := not is_horizontal
		end

	line_style: INTEGER
			-- Line style (single, double, dashed, etc.)

	line_char: CHARACTER_32
			-- Character used to draw the line.

feature -- Line style constants

	Style_single: INTEGER = 1
			-- Single line (thin).

	Style_double: INTEGER = 2
			-- Double line.

	Style_dashed: INTEGER = 3
			-- Dashed line.

	Style_thick: INTEGER = 4
			-- Thick/bold line.

	Style_ascii: INTEGER = 5
			-- ASCII characters (- or |).

feature -- Modification

	set_horizontal
			-- Set to horizontal orientation.
		do
			is_horizontal := True
			height := 1
			update_line_char
		ensure
			horizontal: is_horizontal
		end

	set_vertical
			-- Set to vertical orientation.
		do
			is_horizontal := False
			width := 1
			update_line_char
		ensure
			vertical: is_vertical
		end

	set_line_style (a_s: INTEGER)
			-- Set line style.
		require
			valid_style: a_s >= Style_single and a_s <= Style_ascii
		do
			line_style := a_s
			update_line_char
		ensure
			style_set: line_style = a_s
		end

	set_line_char (a_c: CHARACTER_32)
			-- Set custom line character.
		do
			line_char := a_c
		ensure
			char_set: line_char = a_c
		end

	set_length (a_len: INTEGER)
			-- Set separator length.
		require
			valid_length: a_len > 0
		do
			if is_horizontal then
				width := a_len
			else
				height := a_len
			end
		end

feature -- Rendering

	render (a_buffer: TUI_BUFFER)
			-- Render separator to buffer.
		local
			ax, ay, i: INTEGER
		do
			ax := absolute_x
			ay := absolute_y

			if is_horizontal then
				from i := 0 until i >= width loop
					a_buffer.put_char (ax + i, ay, line_char, style)
					i := i + 1
				end
			else
				from i := 0 until i >= height loop
					a_buffer.put_char (ax, ay + i, line_char, style)
					i := i + 1
				end
			end
		end

feature -- Queries

	preferred_width: INTEGER
			-- Preferred width.
		do
			Result := width
		end

	preferred_height: INTEGER
			-- Preferred height.
		do
			Result := height
		end

feature {NONE} -- Implementation

	update_line_char
			-- Update line character based on style and orientation.
		do
			if is_horizontal then
				inspect line_style
				when Style_single then
					line_char := '%/0x2500/'  -- BOX DRAWINGS LIGHT HORIZONTAL
				when Style_double then
					line_char := '%/0x2550/'  -- BOX DRAWINGS DOUBLE HORIZONTAL
				when Style_dashed then
					line_char := '%/0x2504/'  -- BOX DRAWINGS LIGHT TRIPLE DASH HORIZONTAL
				when Style_thick then
					line_char := '%/0x2501/'  -- BOX DRAWINGS HEAVY HORIZONTAL
				when Style_ascii then
					line_char := '-'
				else
					line_char := '%/0x2500/'
				end
			else
				inspect line_style
				when Style_single then
					line_char := '%/0x2502/'  -- BOX DRAWINGS LIGHT VERTICAL
				when Style_double then
					line_char := '%/0x2551/'  -- BOX DRAWINGS DOUBLE VERTICAL
				when Style_dashed then
					line_char := '%/0x2506/'  -- BOX DRAWINGS LIGHT TRIPLE DASH VERTICAL
				when Style_thick then
					line_char := '%/0x2503/'  -- BOX DRAWINGS HEAVY VERTICAL
				when Style_ascii then
					line_char := '|'
				else
					line_char := '%/0x2502/'
				end
			end
		end

invariant
	valid_style: line_style >= Style_single and line_style <= Style_ascii

end
