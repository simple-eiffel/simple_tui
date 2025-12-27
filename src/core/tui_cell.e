note
	description: "[
		TUI_CELL - Single terminal cell

		Represents one character position in the terminal with:
		- A character (Unicode code point)
		- A style (foreground, background, attributes)
		- Width hint for wide characters (CJK, emoji)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_CELL

create
	make,
	make_with_char,
	make_with_styled_char

feature {NONE} -- Initialization

	make
			-- Create empty cell (space with default style).
		do
			character := ' '
			create style.make_default
			width := 1
		ensure
			is_space: character = ' '
			width_is_one: width = 1
		end

	make_with_char (c: CHARACTER_32)
			-- Create cell with character and default style.
		do
			character := c
			create style.make_default
			width := compute_width (c)
		ensure
			char_set: character = c
		end

	make_with_styled_char (c: CHARACTER_32; s: TUI_STYLE)
			-- Create cell with character and style.
		require
			s_exists: s /= Void
		do
			character := c
			style := s
			width := compute_width (c)
		ensure
			char_set: character = c
			style_set: style = s
		end

feature -- Access

	character: CHARACTER_32
			-- The character in this cell.

	char: CHARACTER_32
			-- Alias for character.
		do
			Result := character
		end

	style: TUI_STYLE
			-- The style of this cell.

	width: INTEGER
			-- Display width (1 for normal, 2 for wide characters).

	char_width: INTEGER
			-- Alias for width.
		do
			Result := width
		end

feature -- Modification

	set_character (c: CHARACTER_32)
			-- Set the character.
		do
			character := c
			width := compute_width (c)
		ensure
			char_set: character = c
		end

	set_style (s: TUI_STYLE)
			-- Set the style.
		require
			s_exists: s /= Void
		do
			style := s
		ensure
			style_set: style = s
		end

	set (c: CHARACTER_32; s: TUI_STYLE)
			-- Set both character and style.
		require
			s_exists: s /= Void
		do
			character := c
			style := s
			width := compute_width (c)
		ensure
			char_set: character = c
			style_set: style = s
		end

	clear
			-- Reset to empty cell.
		do
			character := ' '
			create style.make_default
			width := 1
		ensure
			is_space: character = ' '
		end

feature -- Status

	is_empty: BOOLEAN
			-- Is this an empty (space with default style) cell?
		do
			Result := character = ' ' and style.foreground.is_default and style.background.is_default and style.attributes = 0
		end

	is_wide: BOOLEAN
			-- Is this a wide character (takes 2 columns)?
		do
			Result := width > 1
		end

feature -- Comparison

	same_cell (other: TUI_CELL): BOOLEAN
			-- Is this the same as `other`?
		require
			other_exists: other /= Void
		do
			Result := character = other.character and style.same_style (other.style)
		end

feature -- Duplication

	twin_cell: TUI_CELL
			-- Create a copy of this cell.
		do
			create Result.make_with_styled_char (character, style.twin_style)
		ensure
			same: Result.same_cell (Current)
		end

feature {NONE} -- Implementation

	compute_width (c: CHARACTER_32): INTEGER
			-- Compute display width of character.
			-- Returns 2 for wide characters (CJK, emoji), 1 otherwise.
		local
			code: NATURAL_32
		do
			code := c.natural_32_code

			-- CJK ranges (simplified detection)
			if code >= 0x1100 and code <= 0x115F then
				-- Hangul Jamo
				Result := 2
			elseif code >= 0x2E80 and code <= 0x9FFF then
				-- CJK Radicals, Kangxi, CJK Unified
				Result := 2
			elseif code >= 0xAC00 and code <= 0xD7A3 then
				-- Hangul Syllables
				Result := 2
			elseif code >= 0xF900 and code <= 0xFAFF then
				-- CJK Compatibility
				Result := 2
			elseif code >= 0xFE10 and code <= 0xFE1F then
				-- Vertical Forms
				Result := 2
			elseif code >= 0xFF00 and code <= 0xFF60 then
				-- Fullwidth Forms
				Result := 2
			elseif code >= 0x1F300 and code <= 0x1F9FF then
				-- Emoji (common ranges)
				Result := 2
			elseif code >= 0x20000 and code <= 0x2FFFF then
				-- CJK Extension B and beyond
				Result := 2
			else
				Result := 1
			end
		ensure
			valid_width: Result >= 1 and Result <= 2
		end

invariant
	style_exists: style /= Void
	valid_width: width >= 1 and width <= 2

end
