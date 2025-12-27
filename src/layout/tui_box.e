note
	description: "[
		TUI_BOX - Container widget with optional border and title

		Features:
		- Optional border (single or double line)
		- Optional title
		- Padding
		- Can contain child widgets
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_BOX

inherit
	TUI_WIDGET
		redefine
			preferred_width,
			preferred_height,
			layout,
			content_origin_x,
			content_origin_y
		end

create
	make,
	make_with_title

feature {NONE} -- Initialization

	make (a_width, a_height: INTEGER)
			-- Create box with size.
		require
			valid_width: a_width >= 0
			valid_height: a_height >= 0
		do
			make_widget
			width := a_width
			height := a_height
			title := ""
			border_style := Border_none
			padding_left := 0
			padding_right := 0
			padding_top := 0
			padding_bottom := 0
		ensure
			width_set: width = a_width
			height_set: height = a_height
		end

	make_with_title (a_title: STRING; a_width, a_height: INTEGER)
			-- Create box with title and size.
		require
			title_exists: a_title /= Void
			valid_width: a_width >= 0
			valid_height: a_height >= 0
		do
			make (a_width, a_height)
			title := a_title
			border_style := Border_single
		ensure
			title_set: title = a_title
			has_border: border_style = Border_single
		end

feature -- Access

	title: STRING
			-- Box title (shown in border).

	border_style: INTEGER
			-- Border style (none, single, double, rounded).

	padding_left: INTEGER
	padding_right: INTEGER
	padding_top: INTEGER
	padding_bottom: INTEGER

	border_color_style: detachable TUI_STYLE
			-- Style for drawing border (if Void, uses inherited `style`).

	title_color_style: detachable TUI_STYLE
			-- Style for drawing title (if Void, uses border_color_style or `style`).

feature -- Border styles

	Border_none: INTEGER = 0
	Border_single: INTEGER = 1
	Border_double: INTEGER = 2
	Border_rounded: INTEGER = 3

feature -- Modification

	set_title (t: STRING)
			-- Set box title.
		require
			t_exists: t /= Void
		do
			title := t
		ensure
			title_set: title = t
		end

	set_border (bs: INTEGER)
			-- Set border style.
		require
			valid_style: bs >= Border_none and bs <= Border_rounded
		do
			border_style := bs
		ensure
			border_set: border_style = bs
		end

	set_padding (p: INTEGER)
			-- Set uniform padding.
		require
			valid: p >= 0
		do
			padding_left := p
			padding_right := p
			padding_top := p
			padding_bottom := p
		end

	set_padding_horizontal (p: INTEGER)
			-- Set left/right padding.
		require
			valid: p >= 0
		do
			padding_left := p
			padding_right := p
		end

	set_padding_vertical (p: INTEGER)
			-- Set top/bottom padding.
		require
			valid: p >= 0
		do
			padding_top := p
			padding_bottom := p
		end

	set_border_style (s: TUI_STYLE)
			-- Set style for drawing the border.
		require
			s_exists: s /= Void
		do
			border_color_style := s
		ensure
			style_set: border_color_style = s
		end

	set_title_style (s: TUI_STYLE)
			-- Set style for drawing the title.
		require
			s_exists: s /= Void
		do
			title_color_style := s
		ensure
			style_set: title_color_style = s
		end

feature -- Queries

	inner_x: INTEGER
			-- X position of content area.
		do
			Result := absolute_x + padding_left
			if border_style /= Border_none then
				Result := Result + 1
			end
		end

	inner_y: INTEGER
			-- Y position of content area.
		do
			Result := absolute_y + padding_top
			if border_style /= Border_none then
				Result := Result + 1
			end
		end

	inner_width: INTEGER
			-- Width of content area.
		do
			Result := width - padding_left - padding_right
			if border_style /= Border_none then
				Result := Result - 2
			end
			Result := Result.max (0)
		end

	inner_height: INTEGER
			-- Height of content area.
		do
			Result := height - padding_top - padding_bottom
			if border_style /= Border_none then
				Result := Result - 2
			end
			Result := Result.max (0)
		end

	content_origin_x: INTEGER
			-- X origin for child content (inside border and padding).
		do
			Result := inner_x
		end

	content_origin_y: INTEGER
			-- Y origin for child content (inside border and padding).
		do
			Result := inner_y
		end

feature -- Rendering

	render (buffer: TUI_BUFFER)
			-- Render box to buffer.
		local
			ax, ay, i: INTEGER
			chars: TUPLE [tl, tr, bl, br, h, v: CHARACTER_32]
			l_border_style, l_title_style: TUI_STYLE
		do
			ax := absolute_x
			ay := absolute_y

			-- Draw border if enabled
			if border_style /= Border_none then
				chars := border_chars (border_style)

				-- Resolve styles
				if attached border_color_style as bs then
					l_border_style := bs
				else
					l_border_style := style
				end
				if attached title_color_style as ts then
					l_title_style := ts
				else
					l_title_style := l_border_style
				end

				-- Top border
				buffer.put_char (ax, ay, chars.tl, l_border_style)
				from i := 1 until i >= width - 1 loop
					buffer.put_char (ax + i, ay, chars.h, l_border_style)
					i := i + 1
				end
				if width > 1 then
					buffer.put_char (ax + width - 1, ay, chars.tr, l_border_style)
				end

				-- Title (if any)
				if not title.is_empty and width > 4 then
					buffer.put_string (ax + 2, ay, title.substring (1, (width - 4).min (title.count)), l_title_style)
				end

				-- Side borders
				from i := 1 until i >= height - 1 loop
					buffer.put_char (ax, ay + i, chars.v, l_border_style)
					buffer.put_char (ax + width - 1, ay + i, chars.v, l_border_style)
					i := i + 1
				end

				-- Bottom border
				if height > 1 then
					buffer.put_char (ax, ay + height - 1, chars.bl, l_border_style)
					from i := 1 until i >= width - 1 loop
						buffer.put_char (ax + i, ay + height - 1, chars.h, l_border_style)
						i := i + 1
					end
					if width > 1 then
						buffer.put_char (ax + width - 1, ay + height - 1, chars.br, l_border_style)
					end
				end
			end

			-- Render children
			render_children (buffer)
		end

feature -- Layout

	preferred_width: INTEGER
		do
			Result := width
		end

	preferred_height: INTEGER
		do
			Result := height
		end

	layout
			-- Perform layout of children.
		do
			-- Override in subclasses (TUI_VBOX, TUI_HBOX)
		end

feature {NONE} -- Implementation

	border_chars (bs: INTEGER): TUPLE [tl, tr, bl, br, h, v: CHARACTER_32]
			-- Get border characters for style.
		do
			inspect bs
			when Border_single then
				-- Single line: top-left, top-right, bottom-left, bottom-right, horizontal, vertical
				Result := ['%/0x250C/', '%/0x2510/', '%/0x2514/', '%/0x2518/', '%/0x2500/', '%/0x2502/']
			when Border_double then
				-- Double line
				Result := ['%/0x2554/', '%/0x2557/', '%/0x255A/', '%/0x255D/', '%/0x2550/', '%/0x2551/']
			when Border_rounded then
				-- Rounded corners
				Result := ['%/0x256D/', '%/0x256E/', '%/0x2570/', '%/0x256F/', '%/0x2500/', '%/0x2502/']
			else
				Result := [{CHARACTER_32} ' ', {CHARACTER_32} ' ', {CHARACTER_32} ' ', {CHARACTER_32} ' ', {CHARACTER_32} ' ', {CHARACTER_32} ' ']
			end
		end

invariant
	title_exists: title /= Void
	valid_border: border_style >= Border_none and border_style <= Border_rounded
	valid_padding: padding_left >= 0 and padding_right >= 0 and padding_top >= 0 and padding_bottom >= 0

end
