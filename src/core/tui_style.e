note
	description: "[
		TUI_STYLE - Text styling for terminal cells

		Combines foreground color, background color, and text attributes
		(bold, italic, underline, etc.) into a single style object.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_STYLE

create
	make,
	make_with_colors,
	make_default

feature {NONE} -- Initialization

	make
			-- Create style with default colors and no attributes.
		do
			create foreground.make_default
			create background.make_default
			attributes := 0
		ensure
			no_attributes: attributes = 0
		end

	make_with_colors (a_fg, a_bg: TUI_COLOR)
			-- Create style with given colors.
		do
			foreground := a_fg
			background := a_bg
			attributes := 0
		ensure
			fg_set: foreground = a_fg
			bg_set: background = a_bg
		end

	make_default
			-- Create default style.
		do
			make
		end

feature -- Access

	foreground: TUI_COLOR assign set_foreground
			-- Foreground (text) color.

	background: TUI_COLOR assign set_background
			-- Background color.

	attributes: INTEGER assign set_attributes
			-- Bit flags for text attributes.

feature -- Attribute setting

	set_attributes (a_a: INTEGER)
			-- Set attribute flags directly.
		do
			attributes := a_a
		ensure
			attributes_set: attributes = a_a
		end

feature -- Status

	is_bold: BOOLEAN
			-- Is bold enabled?
		do
			Result := (attributes & Attr_bold) /= 0
		end

	is_dim: BOOLEAN
			-- Is dim enabled?
		do
			Result := (attributes & Attr_dim) /= 0
		end

	is_italic: BOOLEAN
			-- Is italic enabled?
		do
			Result := (attributes & Attr_italic) /= 0
		end

	is_underline: BOOLEAN
			-- Is underline enabled?
		do
			Result := (attributes & Attr_underline) /= 0
		end

	is_blink: BOOLEAN
			-- Is blink enabled?
		do
			Result := (attributes & Attr_blink) /= 0
		end

	is_reverse: BOOLEAN
			-- Is reverse (inverse) enabled?
		do
			Result := (attributes & Attr_reverse) /= 0
		end

	is_strikethrough: BOOLEAN
			-- Is strikethrough enabled?
		do
			Result := (attributes & Attr_strikethrough) /= 0
		end

feature -- Modification

	set_foreground (a_c: TUI_COLOR)
			-- Set foreground color.
		do
			foreground := a_c
		ensure
			foreground_set: foreground = a_c
		end

	set_background (a_c: TUI_COLOR)
			-- Set background color.
		do
			background := a_c
		ensure
			background_set: background = a_c
		end

	set_bold (a_v: BOOLEAN)
			-- Enable or disable bold.
		do
			if a_v then
				attributes := attributes | Attr_bold
			else
				attributes := attributes & (Attr_bold.bit_not)
			end
		ensure
			bold_set: is_bold = a_v
		end

	set_dim (a_v: BOOLEAN)
			-- Enable or disable dim.
		do
			if a_v then
				attributes := attributes | Attr_dim
			else
				attributes := attributes & (Attr_dim.bit_not)
			end
		ensure
			dim_set: is_dim = a_v
		end

	set_italic (a_v: BOOLEAN)
			-- Enable or disable italic.
		do
			if a_v then
				attributes := attributes | Attr_italic
			else
				attributes := attributes & (Attr_italic.bit_not)
			end
		ensure
			italic_set: is_italic = a_v
		end

	set_underline (a_v: BOOLEAN)
			-- Enable or disable underline.
		do
			if a_v then
				attributes := attributes | Attr_underline
			else
				attributes := attributes & (Attr_underline.bit_not)
			end
		ensure
			underline_set: is_underline = a_v
		end

	set_blink (a_v: BOOLEAN)
			-- Enable or disable blink.
		do
			if a_v then
				attributes := attributes | Attr_blink
			else
				attributes := attributes & (Attr_blink.bit_not)
			end
		ensure
			blink_set: is_blink = a_v
		end

	set_reverse (a_v: BOOLEAN)
			-- Enable or disable reverse.
		do
			if a_v then
				attributes := attributes | Attr_reverse
			else
				attributes := attributes & (Attr_reverse.bit_not)
			end
		ensure
			reverse_set: is_reverse = a_v
		end

	set_strikethrough (a_v: BOOLEAN)
			-- Enable or disable strikethrough.
		do
			if a_v then
				attributes := attributes | Attr_strikethrough
			else
				attributes := attributes & (Attr_strikethrough.bit_not)
			end
		ensure
			strikethrough_set: is_strikethrough = a_v
		end

feature -- Fluent API

	with_fg (a_c: TUI_COLOR): TUI_STYLE
			-- Return self with foreground set.
		do
			foreground := a_c
			Result := Current
		ensure
			result_is_self: Result = Current
		end

	with_bg (a_c: TUI_COLOR): TUI_STYLE
			-- Return self with background set.
		do
			background := a_c
			Result := Current
		ensure
			result_is_self: Result = Current
		end

	bold: TUI_STYLE
			-- Return self with bold enabled.
		do
			set_bold (True)
			Result := Current
		ensure
			result_is_self: Result = Current
			is_bold: is_bold
		end

	dim: TUI_STYLE
			-- Return self with dim enabled.
		do
			set_dim (True)
			Result := Current
		ensure
			result_is_self: Result = Current
		end

	italic: TUI_STYLE
			-- Return self with italic enabled.
		do
			set_italic (True)
			Result := Current
		ensure
			result_is_self: Result = Current
		end

	underline: TUI_STYLE
			-- Return self with underline enabled.
		do
			set_underline (True)
			Result := Current
		ensure
			result_is_self: Result = Current
		end

	reverse: TUI_STYLE
			-- Return self with reverse enabled.
		do
			set_reverse (True)
			Result := Current
		ensure
			result_is_self: Result = Current
		end

feature -- Combination

	inverted: TUI_STYLE
			-- Create copy with foreground/background swapped.
		do
			create Result.make_with_colors (background, foreground)
			Result.attributes := attributes
		ensure
			fg_swapped: Result.foreground.same_color (background)
			bg_swapped: Result.background.same_color (foreground)
		end

	merged (a_other: TUI_STYLE): TUI_STYLE
			-- Create copy with attributes merged from `other`.
			-- Other's non-default colors override ours.
		do
			create Result.make
			-- Use other's colors if set, otherwise ours
			if a_other.foreground.is_default then
				Result.foreground := foreground
			else
				Result.foreground := a_other.foreground
			end
			if a_other.background.is_default then
				Result.background := background
			else
				Result.background := a_other.background
			end
			-- Merge attributes (OR them together)
			Result.attributes := attributes | a_other.attributes
		end

feature -- Comparison

	same_style (a_other: TUI_STYLE): BOOLEAN
			-- Is this the same style as `other`?
		do
			Result := foreground.same_color (a_other.foreground) and
				background.same_color (a_other.background) and
				attributes = a_other.attributes
		end

feature -- Duplication

	twin_style: TUI_STYLE
			-- Create a copy of this style.
		do
			create Result.make_with_colors (foreground, background)
			Result.attributes := attributes
		ensure
			same: Result.same_style (Current)
		end

feature -- Attribute constants

	Attr_bold: INTEGER = 1
	Attr_dim: INTEGER = 2
	Attr_italic: INTEGER = 4
	Attr_underline: INTEGER = 8
	Attr_blink: INTEGER = 16
	Attr_reverse: INTEGER = 32
	Attr_strikethrough: INTEGER = 64

invariant
	foreground_exists: foreground /= Void
	background_exists: background /= Void

end
