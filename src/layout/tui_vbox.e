note
	description: "[
		TUI_VBOX - Vertical box layout

		Arranges children vertically from top to bottom.
		Supports:
		- Gap between children
		- Alignment (left, center, right)
		- Distribution (start, center, end, space-between)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_VBOX

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

	align: INTEGER
			-- Horizontal alignment of children.

feature -- Alignment constants

	Align_left: INTEGER = 0
	Align_center: INTEGER = 1
	Align_right: INTEGER = 2

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

	set_align (a: INTEGER)
			-- Set horizontal alignment.
		require
			valid: a >= Align_left and a <= Align_right
		do
			align := a
		ensure
			align_set: align = a
		end

feature -- Layout

	layout
			-- Arrange children vertically, then recursively layout each child.
		local
			current_y: INTEGER
			child_x: INTEGER
			iw: INTEGER
			i: INTEGER
		do
			iw := inner_width
			current_y := 1

			from i := 1 until i > children.count loop
				-- Calculate X based on alignment
				inspect align
				when Align_left then
					child_x := 1
				when Align_center then
					child_x := ((iw - children.i_th (i).width) // 2) + 1
				when Align_right then
					child_x := iw - children.i_th (i).width + 1
				end

				children.i_th (i).set_position (child_x.max (1), current_y)
				-- Recursively layout child
				children.i_th (i).layout
				current_y := current_y + children.i_th (i).height + gap
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
	valid_align: align >= Align_left and align <= Align_right

end
