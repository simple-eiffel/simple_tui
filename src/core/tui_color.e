note
	description: "[
		TUI_COLOR - Terminal color representation

		Supports:
		- 16 standard colors (0-15)
		- 256 color palette (0-255)
		- 24-bit true color (RGB)
		- Named semantic colors
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_COLOR

create
	make_default,
	make_index,
	make_rgb,
	make_named

feature {NONE} -- Initialization

	make_default
			-- Create default color (terminal default).
		do
			mode := Mode_default
			index := 0
			red_value := 0
			green_value := 0
			blue_value := 0
		ensure
			is_default: is_default
		end

	make_index (a_index: INTEGER)
			-- Create indexed color (0-255).
		require
			valid_index: a_index >= 0 and a_index <= 255
		do
			mode := Mode_indexed
			index := a_index
			red_value := 0
			green_value := 0
			blue_value := 0
		ensure
			is_indexed: is_indexed
			index_set: index = a_index
		end

	make_rgb (a_red, a_green, a_blue: INTEGER)
			-- Create true color from RGB values.
		require
			valid_red: a_red >= 0 and a_red <= 255
			valid_green: a_green >= 0 and a_green <= 255
			valid_blue: a_blue >= 0 and a_blue <= 255
		do
			mode := Mode_rgb
			index := 0
			red_value := a_red
			green_value := a_green
			blue_value := a_blue
		ensure
			is_rgb: is_rgb
			red_set: red_value = a_red
			green_set: green_value = a_green
			blue_set: blue_value = a_blue
		end

	make_named (a_name: STRING)
			-- Create color from name.
		require
			valid_name: is_valid_name (a_name)
		do
			if a_name.same_string ("black") then
				make_index (0)
			elseif a_name.same_string ("red") then
				make_index (1)
			elseif a_name.same_string ("green") then
				make_index (2)
			elseif a_name.same_string ("yellow") then
				make_index (3)
			elseif a_name.same_string ("blue") then
				make_index (4)
			elseif a_name.same_string ("magenta") then
				make_index (5)
			elseif a_name.same_string ("cyan") then
				make_index (6)
			elseif a_name.same_string ("white") then
				make_index (7)
			elseif a_name.same_string ("bright_black") or a_name.same_string ("gray") then
				make_index (8)
			elseif a_name.same_string ("bright_red") then
				make_index (9)
			elseif a_name.same_string ("bright_green") then
				make_index (10)
			elseif a_name.same_string ("bright_yellow") then
				make_index (11)
			elseif a_name.same_string ("bright_blue") then
				make_index (12)
			elseif a_name.same_string ("bright_magenta") then
				make_index (13)
			elseif a_name.same_string ("bright_cyan") then
				make_index (14)
			elseif a_name.same_string ("bright_white") then
				make_index (15)
			else
				make_default
			end
		end

feature -- Access

	mode: INTEGER
			-- Color mode.

	index: INTEGER
			-- Color index (0-255) for indexed mode.

	red_value: INTEGER
			-- Red component (0-255) for RGB mode.

	green_value: INTEGER
			-- Green component (0-255) for RGB mode.

	blue_value: INTEGER
			-- Blue component (0-255) for RGB mode.

feature -- Status

	is_default: BOOLEAN
			-- Is this the terminal default color?
		do
			Result := mode = Mode_default
		end

	is_indexed: BOOLEAN
			-- Is this an indexed color?
		do
			Result := mode = Mode_indexed
		end

	is_rgb: BOOLEAN
			-- Is this a true color (RGB)?
		do
			Result := mode = Mode_rgb
		end

feature -- Query

	is_valid_name (a_name: STRING): BOOLEAN
			-- Is `a_name` a valid color name?
		do
			Result := a_name.same_string ("black") or
				a_name.same_string ("red") or
				a_name.same_string ("green") or
				a_name.same_string ("yellow") or
				a_name.same_string ("blue") or
				a_name.same_string ("magenta") or
				a_name.same_string ("cyan") or
				a_name.same_string ("white") or
				a_name.same_string ("bright_black") or
				a_name.same_string ("gray") or
				a_name.same_string ("bright_red") or
				a_name.same_string ("bright_green") or
				a_name.same_string ("bright_yellow") or
				a_name.same_string ("bright_blue") or
				a_name.same_string ("bright_magenta") or
				a_name.same_string ("bright_cyan") or
				a_name.same_string ("bright_white") or
				a_name.same_string ("default")
		end

	same_color (a_other: TUI_COLOR): BOOLEAN
			-- Is this the same color as `other`?
		require
			other_exists: a_other /= Void
		do
			if mode /= a_other.mode then
				Result := False
			elseif is_default then
				Result := True
			elseif is_indexed then
				Result := index = a_other.index
			else
				Result := red_value = a_other.red_value and green_value = a_other.green_value and blue_value = a_other.blue_value
			end
		end

feature -- Constants

	Mode_default: INTEGER = 0
	Mode_indexed: INTEGER = 1
	Mode_rgb: INTEGER = 2

feature -- Standard colors

	Black: TUI_COLOR once create Result.make_index (0) end
	Red: TUI_COLOR once create Result.make_index (1) end
	Green: TUI_COLOR once create Result.make_index (2) end
	Yellow: TUI_COLOR once create Result.make_index (3) end
	Blue: TUI_COLOR once create Result.make_index (4) end
	Magenta: TUI_COLOR once create Result.make_index (5) end
	Cyan: TUI_COLOR once create Result.make_index (6) end
	White: TUI_COLOR once create Result.make_index (7) end
	Bright_black: TUI_COLOR once create Result.make_index (8) end
	Gray: TUI_COLOR once create Result.make_index (8) end
	Bright_red: TUI_COLOR once create Result.make_index (9) end
	Bright_green: TUI_COLOR once create Result.make_index (10) end
	Bright_yellow: TUI_COLOR once create Result.make_index (11) end
	Bright_blue: TUI_COLOR once create Result.make_index (12) end
	Bright_magenta: TUI_COLOR once create Result.make_index (13) end
	Bright_cyan: TUI_COLOR once create Result.make_index (14) end
	Bright_white: TUI_COLOR once create Result.make_index (15) end
	Default_color: TUI_COLOR once create Result.make_default end

invariant
	valid_mode: mode = Mode_default or mode = Mode_indexed or mode = Mode_rgb
	valid_index: mode = Mode_indexed implies (index >= 0 and index <= 255)
	valid_rgb: mode = Mode_rgb implies (red_value >= 0 and red_value <= 255 and green_value >= 0 and green_value <= 255 and blue_value >= 0 and blue_value <= 255)

end
