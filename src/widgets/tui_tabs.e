note
	description: "[
		TUI_TABS - Tabbed panel container

		Multiple panels with tab bar for navigation.

		EV equivalent: EV_NOTEBOOK
		Other frameworks: Tabs, TabView, Notebook, TabPanel

		Features:
		- Multiple tab panels
		- Tab bar with labels
		- Keyboard and mouse tab switching
		- Customizable tab appearance
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_TABS

inherit
	TUI_WIDGET
		redefine
			handle_key,
			handle_mouse,
			focus_from_next,
			focus_from_previous,
			preferred_width,
			preferred_height,
			layout
		end

create
	make

feature {NONE} -- Initialization

	make (a_width, a_height: INTEGER)
			-- Create tabs with size.
		require
			valid_width: a_width > 0
			valid_height: a_height > 2  -- At least 1 for tab bar, 1 for content
		do
			make_widget
			width := a_width
			height := a_height
			is_focusable := True
			create tabs.make (5)
			selected_tab := 0
			tab_bar_height := 1
			create tab_change_actions
			create normal_tab_style.make_default
			create selected_tab_style.make_default
			create content_style.make_default
			selected_tab_style.set_reverse (True)
			selected_tab_style.set_bold (True)
		ensure
			width_set: width = a_width
			height_set: height = a_height
			focusable: is_focusable
		end

feature -- Access

	tabs: ARRAYED_LIST [TUPLE [title: STRING_32; content: TUI_WIDGET]]
			-- Tab definitions (title + content widget).
			-- Aliases: pages, panels

	pages: ARRAYED_LIST [TUPLE [title: STRING_32; content: TUI_WIDGET]]
			-- Alias for tabs.
		do
			Result := tabs
		end

	selected_tab: INTEGER
			-- Currently selected tab index (1-based, 0 = none).
			-- Aliases: current_tab, active_tab, selected_index

	current_tab: INTEGER
			-- Alias for selected_tab.
		do
			Result := selected_tab
		end

	selected_content: detachable TUI_WIDGET
			-- Content widget of selected tab.
		do
			if selected_tab > 0 and selected_tab <= tabs.count then
				Result := tabs.i_th (selected_tab).content
			end
		end

	tab_bar_height: INTEGER
			-- Height of tab bar.

feature -- Actions (EV compatible)

	tab_change_actions: ACTION_SEQUENCE [TUPLE [INTEGER]]
			-- Actions to execute when tab changes.
			-- Passes new tab index to handlers.
			-- Use `extend' to add handlers, `prune' to remove.
			-- EV equivalent: selection_actions

	selection_actions: ACTION_SEQUENCE [TUPLE [INTEGER]]
			-- Alias for tab_change_actions (EV compatibility).
		do
			Result := tab_change_actions
		end

feature -- Styles

	normal_tab_style: TUI_STYLE
			-- Style for unselected tabs.

	selected_tab_style: TUI_STYLE
			-- Style for selected tab.

	content_style: TUI_STYLE
			-- Style for content area border.

feature -- Modification

	add_tab (a_title: READABLE_STRING_GENERAL; content: TUI_WIDGET)
			-- Add a new tab.
		require
			title_exists: a_title /= Void
			content_exists: content /= Void
		do
			tabs.extend ([a_title.to_string_32, content])
			add_child (content)
			content.hide  -- Hide initially
			if tabs.count = 1 then
				select_tab (1)
			end
		ensure
			tab_added: tabs.count = old tabs.count + 1
		end

	remove_tab (a_index: INTEGER)
			-- Remove tab at index.
		require
			valid_index: a_index >= 1 and a_index <= tabs.count
		local
			l_tab_content: TUI_WIDGET
		do
			tab_content := tabs.i_th (a_index).content
			remove_child (tab_content)
			tabs.go_i_th (a_index)
			tabs.remove
			if selected_tab > tabs.count then
				selected_tab := tabs.count
			end
			if selected_tab > 0 then
				tabs.i_th (selected_tab).content.show
			end
		ensure
			tab_removed: tabs.count = old tabs.count - 1
		end

	select_tab, set_selected_tab (a_idx: INTEGER)
			-- Select tab at index.
		require
			valid_index: a_idx >= 1 and a_idx <= tabs.count
		local
			i: INTEGER
		do
			-- Hide all
			from i := 1 until i > tabs.count loop
				tabs.i_th (i).content.hide
				i := i + 1
			end
			-- Show selected
			selected_tab := a_idx
			tabs.i_th (a_idx).content.show
			layout
			notify_change
		ensure
			tab_set: selected_tab = a_idx
		end

	select_next_tab
			-- Select next tab.
		do
			if selected_tab < tabs.count then
				select_tab (selected_tab + 1)
			end
		end

	select_previous_tab
			-- Select previous tab.
		do
			if selected_tab > 1 then
				select_tab (selected_tab - 1)
			end
		end

	set_tab_bar_height (a_h: INTEGER)
			-- Set tab bar height.
		require
			valid: a_h >= 1
		do
			tab_bar_height := a_h
		ensure
			height_set: tab_bar_height = a_h
		end

	set_on_tab_change, set_on_change (a_handler: PROCEDURE [INTEGER])
			-- Set tab change handler (clears previous handlers).
			-- For multiple handlers, use tab_change_actions.extend directly.
		do
			tab_change_actions.wipe_out
			tab_change_actions.extend (a_handler)
		end

	set_normal_tab_style (a_s: TUI_STYLE)
			-- Set normal tab style.
		require
			s_exists: a_s /= Void
		do
			normal_tab_style := a_s
		ensure
			style_set: normal_tab_style = a_s
		end

	set_selected_tab_style (a_s: TUI_STYLE)
			-- Set selected tab style.
		require
			s_exists: a_s /= Void
		do
			selected_tab_style := a_s
		ensure
			style_set: selected_tab_style = a_s
		end

feature -- Focus

	focus_from_next
			-- Focus first tab when Tab-ing forward.
		do
			Precursor
			if tabs.count > 0 and selected_tab = 0 then
				select_tab (1)
			end
		ensure then
			has_selection: tabs.count > 0 implies selected_tab >= 1
		end

	focus_from_previous
			-- Focus last tab when Shift+Tab-ing backward.
		do
			Precursor
			if tabs.count > 0 then
				select_tab (tabs.count)
			end
		ensure then
			last_selected: tabs.count > 0 implies selected_tab = tabs.count
		end

feature -- Layout

	layout
			-- Position content widgets.
		local
			content_y, content_height: INTEGER
			i: INTEGER
		do
			content_y := tab_bar_height + 1
			content_height := height - tab_bar_height

			from i := 1 until i > tabs.count loop
				tabs.i_th (i).content.set_position (1, content_y)
				tabs.i_th (i).content.set_size (width, content_height)
				tabs.i_th (i).content.layout
				i := i + 1
			end
		end

	preferred_width: INTEGER
			-- Preferred width.
		local
			i, total_tab_width: INTEGER
		do
			total_tab_width := 0
			from i := 1 until i > tabs.count loop
				total_tab_width := total_tab_width + tabs.i_th (i).title.count + 3  -- [ Title ]
				i := i + 1
			end
			Result := total_tab_width.max (width)
		end

	preferred_height: INTEGER
			-- Preferred height.
		do
			Result := height
		end

feature -- Rendering

	render (a_buffer: TUI_BUFFER)
			-- Render tabs to buffer.
		local
			ax, ay: INTEGER
		do
			ax := absolute_x
			ay := absolute_y

			-- Render tab bar
			render_tab_bar (a_buffer, ax, ay)

			-- Render selected content
			if attached selected_content as al_content then
				if al_content.is_visible then
					al_content.render (a_buffer)
				end
			end
		end

feature -- Event Handling

	handle_key (a_event: TUI_EVENT): BOOLEAN
			-- Handle key event.
			-- Tab cycles through tabs, then escapes to next widget.
		do
			if is_focused then
				if a_event.is_left then
					select_previous_tab
					Result := True
				elseif a_event.is_right then
					select_next_tab
					Result := True
				elseif a_event.is_tab and a_event.has_shift then
					-- Shift+Tab: only consume if not on first tab
					if selected_tab > 1 then
						select_previous_tab
						Result := True
					end
					-- else: let Tab escape to previous widget
				elseif a_event.is_tab then
					-- Tab: only consume if not on last tab
					if selected_tab < tabs.count then
						select_next_tab
						Result := True
					end
					-- else: let Tab escape to next widget
				end
			end
		end

	handle_mouse (a_event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			mx, clicked_tab: INTEGER
		do
			if a_event.is_mouse_press and a_event.mouse_button = 1 then
				mx := a_event.mouse_x - absolute_x
				if a_event.mouse_y = absolute_y then
					-- Click on tab bar
					clicked_tab := tab_at_position (mx)
					if clicked_tab > 0 then
						select_tab (clicked_tab)
						Result := True
					end
				end
			end
		end

feature {NONE} -- Implementation

	render_tab_bar (a_buffer: TUI_BUFFER; tx, ty: INTEGER)
			-- Render the tab bar.
		local
			i, tab_x: INTEGER
			l_tab_title: STRING_32
			l_tab_style: TUI_STYLE
		do
			tab_x := tx
			from i := 1 until i > tabs.count loop
				if i = selected_tab then
					tab_style := selected_tab_style
				else
					tab_style := normal_tab_style
				end

				-- Draw tab: [ Title ]
				a_buffer.put_char (tab_x, ty, '[', tab_style)
				tab_title := tabs.i_th (i).title
				a_buffer.put_string (tab_x + 1, ty, tab_title, tab_style)
				a_buffer.put_char (tab_x + 1 + tab_title.count, ty, ']', tab_style)

				tab_x := tab_x + tab_title.count + 3
				i := i + 1
			end

			-- Fill rest of tab bar with spaces
			from until tab_x >= tx + width loop
				a_buffer.put_char (tab_x, ty, ' ', normal_tab_style)
				tab_x := tab_x + 1
			end
		end

	tab_at_position (a_mx: INTEGER): INTEGER
			-- Return tab index at x position, 0 if none.
		local
			i, tab_x, tab_width: INTEGER
		do
			tab_x := 0
			from i := 1 until i > tabs.count or Result > 0 loop
				tab_width := tabs.i_th (i).title.count + 3
				if a_mx >= tab_x and a_mx < tab_x + tab_width then
					Result := i
				end
				tab_x := tab_x + tab_width
				i := i + 1
			end
		end

	notify_change
			-- Notify tab change handlers.
		do
			tab_change_actions.call ([selected_tab])
		end

invariant
	tabs_exist: tabs /= Void
	tab_change_actions_exists: tab_change_actions /= Void
	valid_selection: selected_tab >= 0 and selected_tab <= tabs.count
	normal_tab_style_exists: normal_tab_style /= Void
	selected_tab_style_exists: selected_tab_style /= Void

end
