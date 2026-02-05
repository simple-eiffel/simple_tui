note
	description: "[
		TUI_BUFFER - Double-buffered terminal screen

		Maintains two cell grids:
		- Current buffer: what's currently on screen
		- Next buffer: what we're drawing to

		On flush, only changed cells are written to the terminal,
		minimizing I/O and eliminating flicker.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_BUFFER

create
	make

feature {NONE} -- Initialization

	make (a_width, a_height: INTEGER)
			-- Create buffer with given dimensions.
		require
			valid_width: a_width > 0
			valid_height: a_height > 0
		local
			i: INTEGER
		do
			width := a_width
			height := a_height

			-- Create current buffer (what's on screen)
			create current_buffer.make_filled (create {TUI_CELL}.make, 1, a_width * a_height)

			-- Create next buffer (what we're drawing)
			create next_buffer.make_filled (create {TUI_CELL}.make, 1, a_width * a_height)

			-- Initialize all cells
			from i := 1 until i > a_width * a_height loop
				current_buffer.put (create {TUI_CELL}.make, i)
				next_buffer.put (create {TUI_CELL}.make, i)
				i := i + 1
			end

			cursor_x := 1
			cursor_y := 1
			cursor_visible := True
		ensure
			width_set: width = a_width
			height_set: height = a_height
		end

feature -- Access

	width: INTEGER
			-- Buffer width in columns.

	height: INTEGER
			-- Buffer height in rows.

	cursor_x: INTEGER
			-- Cursor column (1-based).

	cursor_y: INTEGER
			-- Cursor row (1-based).

	cursor_visible: BOOLEAN
			-- Is cursor visible?

	cell_at (x, y: INTEGER): TUI_CELL
			-- Get cell at position (from next buffer).
		require
			valid_x: x >= 1 and x <= width
			valid_y: y >= 1 and y <= height
		do
			Result := next_buffer.item (index_for (x, y))
		ensure
			result_exists: Result /= Void
		end

	current_cell_at (x, y: INTEGER): TUI_CELL
			-- Get cell at position (from current buffer).
		require
			valid_x: x >= 1 and x <= width
			valid_y: y >= 1 and y <= height
		do
			Result := current_buffer.item (index_for (x, y))
		ensure
			result_exists: Result /= Void
		end

feature -- Modification

	set_cell (x, y: INTEGER; cell: TUI_CELL)
			-- Set cell at position.
		require
			valid_x: x >= 1 and x <= width
			valid_y: y >= 1 and y <= height
			cell_exists: cell /= Void
		do
			next_buffer.put (cell.twin_cell, index_for (x, y))
		end

	put_char (x, y: INTEGER; c: CHARACTER_32; s: TUI_STYLE)
			-- Put character with style at position.
		require
			valid_x: x >= 1 and x <= width
			valid_y: y >= 1 and y <= height
			s_exists: s /= Void
		local
			cell: TUI_CELL
		do
			create cell.make_with_styled_char (c, s.twin_style)
			next_buffer.put (cell, index_for (x, y))
		end

	put_string (x, y: INTEGER; str: READABLE_STRING_GENERAL; s: TUI_STYLE)
			-- Put string with style starting at position.
		require
			valid_x: x >= 1 and x <= width
			valid_y: y >= 1 and y <= height
			str_exists: str /= Void
			s_exists: s /= Void
		local
			i, col: INTEGER
			c: CHARACTER_32
			cell: TUI_CELL
		do
			col := x
			from i := 1 until i > str.count or col > width loop
				c := str.item (i)
				create cell.make_with_styled_char (c, s.twin_style)
				next_buffer.put (cell, index_for (col, y))
				col := col + cell.width
				i := i + 1
			end
		end

	fill_rect (x1, y1, x2, y2: INTEGER; c: CHARACTER_32; s: TUI_STYLE)
			-- Fill rectangle with character and style.
		require
			valid_coords: x1 >= 1 and x1 <= width and y1 >= 1 and y1 <= height and x2 >= x1 and x2 <= width and y2 >= y1 and y2 <= height
			s_exists: s /= Void
		local
			row, col: INTEGER
			cell: TUI_CELL
		do
			from row := y1 until row > y2 loop
				from col := x1 until col > x2 loop
					create cell.make_with_styled_char (c, s.twin_style)
					next_buffer.put (cell, index_for (col, row))
					col := col + 1
				end
				row := row + 1
			end
		end

	clear
			-- Clear the next buffer (fill with spaces).
		local
			i: INTEGER
		do
			from i := 1 until i > width * height loop
				next_buffer.put (create {TUI_CELL}.make, i)
				i := i + 1
			end
		end

	clear_with_style (a_s: TUI_STYLE)
			-- Clear the next buffer with given style.
		require
			s_exists: a_s /= Void
		local
			i: INTEGER
			cell: TUI_CELL
		do
			from i := 1 until i > width * height loop
				create cell.make_with_styled_char (' ', a_s.twin_style)
				next_buffer.put (cell, i)
				i := i + 1
			end
		end

	set_cursor (x, y: INTEGER)
			-- Set cursor position.
		require
			valid_x: x >= 1 and x <= width
			valid_y: y >= 1 and y <= height
		do
			cursor_x := x
			cursor_y := y
		ensure
			x_set: cursor_x = x
			y_set: cursor_y = y
		end

	show_cursor
			-- Make cursor visible.
		do
			cursor_visible := True
		ensure
			visible: cursor_visible
		end

	hide_cursor
			-- Make cursor invisible.
		do
			cursor_visible := False
		ensure
			hidden: not cursor_visible
		end

feature -- Resize

	resize (new_width, new_height: INTEGER)
			-- Resize buffer, preserving content where possible.
		require
			valid_width: new_width > 0
			valid_height: new_height > 0
		local
			new_current, new_next: ARRAY [TUI_CELL]
			old_width, old_height: INTEGER
			x, y, old_idx, new_idx: INTEGER
		do
			old_width := width
			old_height := height

			-- Create new buffers
			create new_current.make_filled (create {TUI_CELL}.make, 1, new_width * new_height)
			create new_next.make_filled (create {TUI_CELL}.make, 1, new_width * new_height)

			-- Initialize new buffers
			from y := 1 until y > new_height loop
				from x := 1 until x > new_width loop
					new_idx := (y - 1) * new_width + x
					new_current.put (create {TUI_CELL}.make, new_idx)
					new_next.put (create {TUI_CELL}.make, new_idx)
					x := x + 1
				end
				y := y + 1
			end

			-- Copy old content
			from y := 1 until y > new_height.min (old_height) loop
				from x := 1 until x > new_width.min (old_width) loop
					old_idx := (y - 1) * old_width + x
					new_idx := (y - 1) * new_width + x
					new_current.put (current_buffer.item (old_idx).twin_cell, new_idx)
					new_next.put (next_buffer.item (old_idx).twin_cell, new_idx)
					x := x + 1
				end
				y := y + 1
			end

			current_buffer := new_current
			next_buffer := new_next
			width := new_width
			height := new_height

			-- Adjust cursor if out of bounds
			cursor_x := cursor_x.min (new_width)
			cursor_y := cursor_y.min (new_height)
		ensure
			width_set: width = new_width
			height_set: height = new_height
		end

feature -- Diff

	changed_cells: ARRAYED_LIST [TUPLE [x, y: INTEGER; cell: TUI_CELL]]
			-- List of cells that differ between current and next buffer.
		local
			x, y, idx: INTEGER
			curr, next: TUI_CELL
		do
			create Result.make (100)
			from y := 1 until y > height loop
				from x := 1 until x > width loop
					idx := index_for (x, y)
					curr := current_buffer.item (idx)
					next := next_buffer.item (idx)
					if not curr.same_cell (next) then
						Result.extend ([x, y, next])
					end
					x := x + 1
				end
				y := y + 1
			end
		ensure
			result_exists: Result /= Void
		end

	has_changes: BOOLEAN
			-- Are there any changes between current and next buffer?
		local
			x, y, idx: INTEGER
		do
			from y := 1 until y > height or Result loop
				from x := 1 until x > width or Result loop
					idx := index_for (x, y)
					if not current_buffer.item (idx).same_cell (next_buffer.item (idx)) then
						Result := True
					end
					x := x + 1
				end
				y := y + 1
			end
		end

feature -- Synchronization

	sync
			-- Copy next buffer to current buffer (after rendering).
		local
			i: INTEGER
		do
			from i := 1 until i > width * height loop
				current_buffer.put (next_buffer.item (i).twin_cell, i)
				i := i + 1
			end
		end

	force_full_redraw
			-- Mark all cells as changed (forces full redraw).
		local
			i: INTEGER
		do
			from i := 1 until i > width * height loop
				current_buffer.item (i).set_character ('%U')
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	current_buffer: ARRAY [TUI_CELL]
			-- What's currently displayed on screen.

	next_buffer: ARRAY [TUI_CELL]
			-- What we're drawing to.

	index_for (x, y: INTEGER): INTEGER
			-- Convert (x, y) to array index.
		require
			valid_x: x >= 1 and x <= width
			valid_y: y >= 1 and y <= height
		do
			Result := (y - 1) * width + x
		ensure
			valid_index: Result >= 1 and Result <= width * height
		end

invariant
	valid_dimensions: width > 0 and height > 0
	buffers_exist: current_buffer /= Void and next_buffer /= Void
	buffer_sizes: current_buffer.count = width * height and next_buffer.count = width * height
	valid_cursor: cursor_x >= 1 and cursor_x <= width and cursor_y >= 1 and cursor_y <= height

end
