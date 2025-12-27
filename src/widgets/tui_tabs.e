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

	on_tab_change: detachable PROCEDURE [INTEGER]
			-- Called when tab changes.
			-- Aliases: on_change, on_select

	on_change: detachable PROCEDURE [INTEGER]
			-- Alias for on_tab_change.
		do
			Result := on_tab_change
		end

feature -- Styles

	normal_tab_style: TUI_STYLE
			-- Style for unselected tabs.

	selected_tab_style: TUI_STYLE
			-- Style for selected tab.

	content_style: TUI_STYLE
			-- Style for content area border.

feature -- Modification

	add_tab, extend (title: READABLE_STRING_GENERAL; content: TUI_WIDGET)
			-- Add a new tab.
		require
			title_exists: title /= Void
			content_exists: content /= Void
		do
			tabs.extend ([title.to_string_32, content])
			add_child (content)
			content.hide  -- Hide initially
			if tabs.count = 1 then
				select_tab (1)
			end
		ensure
			tab_added: tabs.count = old tabs.count + 1
		end

	remove_tab, prune (index: INTEGER)
			-- Remove tab at index.
		require
			valid_index: index >= 1 and index <= tabs.count
		local
			tab_content: TUI_WIDGET
		do
			tab_content := tabs.i_th (index).content
			remove_child (tab_content)
			tabs.go_i_th (index)
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

	select_tab, set_selected_tab (idx: INTEGER)
			-- Select tab at index.
		require
			valid_index: idx >= 1 and idx <= tabs.count
		local
			i: INTEGER
		do
			-- Hide all
			from i := 1 until i > tabs.count loop
				tabs.i_th (i).content.hide
				i := i + 1
			end
			-- Show selected
			selected_tab := idx
			tabs.i_th (idx).content.show
			layout
			notify_change
		ensure
			tab_set: selected_tab = idx
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

	set_tab_bar_height (h: INTEGER)
			-- Set tab bar height.
		require
			valid: h >= 1
		do
			tab_bar_height := h
		ensure
			height_set: tab_bar_height = h
		end

	set_on_tab_change, set_on_change (handler: PROCEDURE [INTEGER])
			-- Set tab change handler.
		do
			on_tab_change := handler
		ensure
			handler_set: on_tab_change = handler
		end

	set_normal_tab_style (s: TUI_STYLE)
			-- Set normal tab style.
		require
			s_exists: s /= Void
		do
			normal_tab_style := s
		ensure
			style_set: normal_tab_style = s
		end

	set_selected_tab_style (s: TUI_STYLE)
			-- Set selected tab style.
		require
			s_exists: s /= Void
		do
			selected_tab_style := s
		ensure
			style_set: selected_tab_style = s
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

	render (buffer: TUI_BUFFER)
			-- Render tabs to buffer.
		local
			ax, ay: INTEGER
		do
			ax := absolute_x
			ay := absolute_y

			-- Render tab bar
			render_tab_bar (buffer, ax, ay)

			-- Render selected content
			if attached selected_content as content then
				if content.is_visible then
					content.render (buffer)
				end
			end
		end

feature -- Event Handling

	handle_key (event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_focused then
				if event.is_left or (event.is_tab and event.has_shift) then
					select_previous_tab
					Result := True
				elseif event.is_right or event.is_tab then
					select_next_tab
					Result := True
				end
			end
		end

	handle_mouse (event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			mx, clicked_tab: INTEGER
		do
			if event.is_mouse_press and event.mouse_button = 1 then
				mx := event.mouse_x - absolute_x
				if event.mouse_y = absolute_y then
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

	render_tab_bar (buffer: TUI_BUFFER; tx, ty: INTEGER)
			-- Render the tab bar.
		local
			i, tab_x: INTEGER
			tab_title: STRING_32
			tab_style: TUI_STYLE
		do
			tab_x := tx
			from i := 1 until i > tabs.count loop
				if i = selected_tab then
					tab_style := selected_tab_style
				else
					tab_style := normal_tab_style
				end

				-- Draw tab: [ Title ]
				buffer.put_char (tab_x, ty, '[', tab_style)
				tab_title := tabs.i_th (i).title
				buffer.put_string (tab_x + 1, ty, tab_title, tab_style)
				buffer.put_char (tab_x + 1 + tab_title.count, ty, ']', tab_style)

				tab_x := tab_x + tab_title.count + 3
				i := i + 1
			end

			-- Fill rest of tab bar with spaces
			from until tab_x >= tx + width loop
				buffer.put_char (tab_x, ty, ' ', normal_tab_style)
				tab_x := tab_x + 1
			end
		end

	tab_at_position (mx: INTEGER): INTEGER
			-- Return tab index at x position, 0 if none.
		local
			i, tab_x, tab_width: INTEGER
		do
			tab_x := 0
			from i := 1 until i > tabs.count or Result > 0 loop
				tab_width := tabs.i_th (i).title.count + 3
				if mx >= tab_x and mx < tab_x + tab_width then
					Result := i
				end
				tab_x := tab_x + tab_width
				i := i + 1
			end
		end

	notify_change
			-- Notify tab change handler.
		do
			if attached on_tab_change as handler then
				handler.call ([selected_tab])
			end
		end

invariant
	tabs_exist: tabs /= Void
	valid_selection: selected_tab >= 0 and selected_tab <= tabs.count
	normal_tab_style_exists: normal_tab_style /= Void
	selected_tab_style_exists: selected_tab_style /= Void

end
