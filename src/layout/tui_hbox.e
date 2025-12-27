note
	description: "[
		TUI_HBOX - Horizontal box layout

		Arranges children horizontally from left to right.
		Supports:
		- Gap between children
		- Alignment (top, middle, bottom)
		- Distribution (start, center, end, space-between)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_HBOX

inherit
	TUI_BOX
		redefine
			layout
		end

create
	make,
	make_with_title

feature -- Access

	gap: INTEGER
			-- Space between children.

	valign: INTEGER
			-- Vertical alignment of children.

feature -- Alignment constants

	Align_top: INTEGER = 0
	Align_middle: INTEGER = 1
	Align_bottom: INTEGER = 2

feature -- Modification

	set_gap (g: INTEGER)
			-- Set gap between children.
		require
			valid: g >= 0
		do
			gap := g
		ensure
			gap_set: gap = g
		end

	set_valign (a: INTEGER)
			-- Set vertical alignment.
		require
			valid: a >= Align_top and a <= Align_bottom
		do
			valign := a
		ensure
			valign_set: valign = a
		end

feature -- Layout

	layout
			-- Arrange children horizontally, then recursively layout each child.
		local
			current_x: INTEGER
			child_y: INTEGER
			ih: INTEGER
			i: INTEGER
		do
			ih := inner_height
			current_x := 1

			from i := 1 until i > children.count loop
				-- Calculate Y based on alignment
				inspect valign
				when Align_top then
					child_y := 1
				when Align_middle then
					child_y := ((ih - children.i_th (i).height) // 2) + 1
				when Align_bottom then
					child_y := ih - children.i_th (i).height + 1
				end

				children.i_th (i).set_position (current_x, child_y.max (1))
				-- Recursively layout child
				children.i_th (i).layout
				current_x := current_x + children.i_th (i).width + gap
				i := i + 1
			end
		end

feature -- Convenience

	add (child: TUI_WIDGET)
			-- Add child and relayout.
		do
			add_child (child)
			layout
		end

invariant
	valid_gap: gap >= 0
	valid_valign: valign >= Align_top and valign <= Align_bottom

end
