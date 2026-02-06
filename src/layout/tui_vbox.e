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

	set_gap (a_g: INTEGER)
			-- Set gap between children.
		require
			valid: a_g >= 0
		do
			gap := a_g
		ensure
			gap_set: gap = a_g
		end

	set_align (a_a: INTEGER)
			-- Set horizontal alignment.
		require
			valid: a_a >= Align_left and a_a <= Align_right
		do
			align := a_a
		ensure
			align_set: align = a_a
		end

feature -- Layout

	layout
			-- Arrange children vertically, then recursively layout each child.
		local
			l_current_y: INTEGER
			l_child_x: INTEGER
			l_iw: INTEGER
			i: INTEGER
		do
			logger.debug_log ("VBOX.layout: children=" + children.count.out + " abs_x=" + absolute_x.out + " abs_y=" + absolute_y.out + " w=" + width.out + " h=" + height.out)
			l_iw := inner_width
			l_current_y := 1

			from i := 1 until i > children.count loop
				-- Calculate X based on alignment
				inspect align
				when Align_left then
					l_child_x := 1
				when Align_center then
					l_child_x := ((l_iw - children.i_th (i).width) // 2) + 1
				when Align_right then
					l_child_x := l_iw - children.i_th (i).width + 1
				end

				children.i_th (i).set_position (l_child_x.max (1), l_current_y)
				logger.debug_log ("  child[" + i.out + "] pos=(" + l_child_x.max (1).out + "," + l_current_y.out + ") abs=(" + children.i_th (i).absolute_x.out + "," + children.i_th (i).absolute_y.out + ") h=" + children.i_th (i).height.out)
				-- Recursively layout child
				children.i_th (i).layout
				l_current_y := l_current_y + children.i_th (i).height + gap
				i := i + 1
			end
		end

	logger: SIMPLE_LOGGER
			-- Shared logger instance.
		once
			create Result.make_to_file ("task_manager.log")
			Result.set_level (Result.Level_debug)
		end

feature -- Convenience

	add (a_child: TUI_WIDGET)
			-- Add child and relayout.
		do
			add_child (a_child)
			layout
		end

invariant
	valid_gap: gap >= 0
	valid_align: align >= Align_left and align <= Align_right

end
