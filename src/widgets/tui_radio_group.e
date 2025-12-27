note
	description: "[
		TUI_RADIO_GROUP - Container for mutually exclusive radio buttons

		Manages a group of radio buttons ensuring only one is selected.

		EV equivalent: Implicit via EV_RADIO_BUTTON peers
		Other frameworks: RadioGroup, RadioSet, RadioButtonGroup

		Features:
		- Mutual exclusion enforcement
		- Selection tracking
		- Change callback with selected index
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_RADIO_GROUP

inherit
	TUI_WIDGET
		redefine
			preferred_width,
			preferred_height,
			layout
		end

create
	make

feature {NONE} -- Initialization

	make
			-- Create empty radio group.
		do
			make_widget
			create buttons.make (5)
			create change_actions
			selected_index := 0
			is_horizontal := False
			gap := 0
		ensure
			empty: buttons.is_empty
			no_selection: selected_index = 0
		end

feature -- Access

	buttons: ARRAYED_LIST [TUI_RADIO_BUTTON]
			-- Radio buttons in this group.
			-- Aliases: items, options

	items: ARRAYED_LIST [TUI_RADIO_BUTTON]
			-- Alias for buttons.
		do
			Result := buttons
		end

	selected_index: INTEGER
			-- Index of selected button (1-based, 0 = none).
			-- Aliases: value, selected_item_index

	value: INTEGER
			-- Alias for selected_index (web frameworks).
		do
			Result := selected_index
		end

	selected_button: detachable TUI_RADIO_BUTTON
			-- Currently selected button.
			-- Aliases: selected_item
		do
			if selected_index > 0 and selected_index <= buttons.count then
				Result := buttons.i_th (selected_index)
			end
		end

	selected_item: detachable TUI_RADIO_BUTTON
			-- Alias for selected_button.
		do
			Result := selected_button
		end

	is_horizontal: BOOLEAN
			-- Arrange buttons horizontally?

	gap: INTEGER
			-- Gap between buttons.

feature -- Actions (EV compatible)

	change_actions: ACTION_SEQUENCE [TUPLE [INTEGER]]
			-- Actions to execute when selection changes.
			-- Passes new selected index to handlers.
			-- Use `extend' to add handlers, `prune' to remove.

	select_actions: ACTION_SEQUENCE [TUPLE [INTEGER]]
			-- Alias for change_actions (EV compatibility).
		do
			Result := change_actions
		end

feature -- Modification

	add_button (button: TUI_RADIO_BUTTON)
			-- Add radio button to group.
		require
			button_exists: button /= Void
			not_in_group: button.group = Void
		do
			buttons.extend (button)
			button.set_group (Current)
			add_child (button)
			-- Select first button by default
			if buttons.count = 1 then
				select_index (1)
			end
		ensure
			button_added: buttons.has (button)
			button_grouped: button.group = Current
		end

	remove_button (button: TUI_RADIO_BUTTON)
			-- Remove radio button from group.
		require
			button_exists: button /= Void
			in_group: buttons.has (button)
		local
			idx: INTEGER
		do
			idx := buttons.index_of (button, 1)
			buttons.prune_all (button)
			button.set_group (Void)
			remove_child (button)
			-- Adjust selection
			if selected_index = idx then
				selected_index := 0
			elseif selected_index > idx then
				selected_index := selected_index - 1
			end
		ensure
			button_removed: not buttons.has (button)
			button_ungrouped: button.group = Void
		end

	select_index, set_value (idx: INTEGER)
			-- Select button at index.
		require
			valid_index: idx >= 0 and idx <= buttons.count
		local
			i: INTEGER
		do
			-- Deselect all
			from i := 1 until i > buttons.count loop
				buttons.i_th (i).deselect
				i := i + 1
			end
			-- Select the one
			selected_index := idx
			if idx > 0 then
				buttons.i_th (idx).internal_select
			end
			notify_change
		ensure
			index_set: selected_index = idx
		end

	select_button (button: TUI_RADIO_BUTTON)
			-- Select specified button.
		require
			button_exists: button /= Void
			in_group: buttons.has (button)
		do
			select_index (buttons.index_of (button, 1))
		ensure
			button_selected: button.is_selected
		end

	set_horizontal (v: BOOLEAN)
			-- Set horizontal layout.
		do
			is_horizontal := v
		ensure
			horizontal_set: is_horizontal = v
		end

	set_gap (g: INTEGER)
			-- Set gap between buttons.
		require
			valid: g >= 0
		do
			gap := g
		ensure
			gap_set: gap = g
		end

	set_on_change, set_on_select (handler: PROCEDURE [INTEGER])
			-- Set change handler (clears previous handlers).
			-- For multiple handlers, use change_actions.extend directly.
		do
			change_actions.wipe_out
			change_actions.extend (handler)
		end

feature -- Layout

	layout
			-- Position buttons vertically or horizontally.
		local
			i, pos: INTEGER
			btn: TUI_RADIO_BUTTON
		do
			pos := 1
			from i := 1 until i > buttons.count loop
				btn := buttons.i_th (i)
				if is_horizontal then
					btn.set_position (pos, 1)
					pos := pos + btn.preferred_width + gap
				else
					btn.set_position (1, pos)
					pos := pos + 1 + gap
				end
				i := i + 1
			end
		end

	preferred_width: INTEGER
			-- Preferred width.
		local
			i, max_w, total_w: INTEGER
		do
			if is_horizontal then
				total_w := 0
				from i := 1 until i > buttons.count loop
					total_w := total_w + buttons.i_th (i).preferred_width
					if i < buttons.count then
						total_w := total_w + gap
					end
					i := i + 1
				end
				Result := total_w
			else
				max_w := 0
				from i := 1 until i > buttons.count loop
					max_w := max_w.max (buttons.i_th (i).preferred_width)
					i := i + 1
				end
				Result := max_w
			end
			Result := Result.max (width)
		end

	preferred_height: INTEGER
			-- Preferred height.
		do
			if is_horizontal then
				Result := 1
			else
				Result := buttons.count
				if buttons.count > 1 then
					Result := Result + (buttons.count - 1) * gap
				end
			end
			Result := Result.max (1)
		end

feature -- Rendering

	render (buffer: TUI_BUFFER)
			-- Render radio group (just renders children).
		do
			render_children (buffer)
		end

feature {NONE} -- Implementation

	notify_change
			-- Notify change handlers.
		do
			change_actions.call ([selected_index])
		end

invariant
	buttons_exist: buttons /= Void
	change_actions_exists: change_actions /= Void
	valid_selection: selected_index >= 0 and selected_index <= buttons.count

end
