note
	description: "[
		TUI_MENU_BAR - Horizontal menu bar

		Top-of-screen menu bar containing drop-down menus.

		EV equivalent: EV_MENU_BAR
		Other frameworks: MenuBar, MainMenu, AppMenu

		Features:
		- Horizontal menu bar at top
		- Contains TUI_MENUs
		- Keyboard navigation (arrows, Alt+key shortcuts)
		- Mouse click to open menus
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_MENU_BAR

inherit
	TUI_WIDGET
		redefine
			handle_key,
			handle_mouse,
			preferred_width,
			preferred_height
		end

create
	make

feature {NONE} -- Initialization

	make (a_width: INTEGER)
			-- Create menu bar with width.
		require
			valid_width: a_width > 0
		do
			make_widget
			width := a_width
			height := 1
			is_focusable := True
			create menus.make (5)
			selected_menu := 0
			is_menu_open := False
			create normal_style.make_default
			create selected_style.make_default
			create open_style.make_default
			selected_style.set_reverse (True)
			open_style.set_reverse (True)
			open_style.set_bold (True)
		ensure
			width_set: width = a_width
			focusable: is_focusable
		end

feature -- Access

	menus: ARRAYED_LIST [TUI_MENU]
			-- Menus in the bar.

	selected_menu: INTEGER
			-- Currently selected/open menu index (1-based, 0 = none).

	current_menu: detachable TUI_MENU
			-- Currently selected menu.
		do
			if selected_menu > 0 and selected_menu <= menus.count then
				Result := menus.i_th (selected_menu)
			end
		end

	is_menu_open: BOOLEAN
			-- Is a menu currently open/dropped down?

feature -- Styles

	normal_style: TUI_STYLE
			-- Style for unselected menu titles.

	selected_style: TUI_STYLE
			-- Style for selected menu title.

	open_style: TUI_STYLE
			-- Style for open menu title.

feature -- Modification

	add_menu (menu: TUI_MENU)
			-- Add menu to bar.
		require
			menu_exists: menu /= Void
		do
			menus.extend (menu)
			add_child (menu)
			menu.hide
			menu.set_on_close (agent on_menu_closed)
		ensure
			menu_added: menus.has (menu)
		end

	remove_menu (menu: TUI_MENU)
			-- Remove menu from bar.
		require
			menu_exists: menu /= Void
		do
			menus.prune_all (menu)
			remove_child (menu)
		ensure
			menu_removed: not menus.has (menu)
		end

	set_normal_style (s: TUI_STYLE)
			-- Set normal style.
		require
			s_exists: s /= Void
		do
			normal_style := s
		ensure
			style_set: normal_style = s
		end

	set_selected_style (s: TUI_STYLE)
			-- Set selected style.
		require
			s_exists: s /= Void
		do
			selected_style := s
		ensure
			style_set: selected_style = s
		end

	set_open_style (s: TUI_STYLE)
			-- Set open menu style.
		require
			s_exists: s /= Void
		do
			open_style := s
		ensure
			style_set: open_style = s
		end

feature -- Menu Control

	open_menu (index: INTEGER)
			-- Open menu at index.
		require
			valid_index: index >= 1 and index <= menus.count
		local
			menu: TUI_MENU
			menu_x: INTEGER
		do
			-- Close any open menu first
			close_menu

			selected_menu := index
			is_menu_open := True
			menu := menus.i_th (index)

			-- Position menu below its title
			menu_x := menu_position_x (index)
			menu.show_at (menu_x, absolute_y + 1)
		ensure
			menu_open: is_menu_open
			menu_selected: selected_menu = index
		end

	close_menu
			-- Close currently open menu.
		do
			if is_menu_open and then attached current_menu as menu then
				menu.hide
			end
			is_menu_open := False
		ensure
			menu_closed: not is_menu_open
		end

	select_next_menu
			-- Select next menu.
		do
			if menus.count > 0 then
				if selected_menu < menus.count then
					selected_menu := selected_menu + 1
				else
					selected_menu := 1
				end
				if is_menu_open then
					open_menu (selected_menu)
				end
			end
		end

	select_previous_menu
			-- Select previous menu.
		do
			if menus.count > 0 then
				if selected_menu > 1 then
					selected_menu := selected_menu - 1
				else
					selected_menu := menus.count
				end
				if is_menu_open then
					open_menu (selected_menu)
				end
			end
		end

feature -- Event Handling

	handle_key (event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_focused or is_menu_open then
				if is_menu_open then
					-- Let open menu handle keys first
					if attached current_menu as menu then
						Result := menu.handle_key (event)
					end
					-- Handle left/right to switch menus
					if not Result then
						if event.is_left then
							select_previous_menu
							Result := True
						elseif event.is_right then
							select_next_menu
							Result := True
						elseif event.is_escape then
							close_menu
							Result := True
						end
					end
				else
					-- Menu bar focused but no menu open
					if event.is_left then
						select_previous_menu
						Result := True
					elseif event.is_right then
						select_next_menu
						Result := True
					elseif event.is_enter or event.is_space or event.is_down then
						if selected_menu > 0 then
							open_menu (selected_menu)
						elseif menus.count > 0 then
							selected_menu := 1
							open_menu (1)
						end
						Result := True
					else
						-- Check Alt+key shortcuts
						Result := try_menu_shortcut (event)
					end
				end
			end
		end

	handle_mouse (event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			mx, clicked_menu: INTEGER
		do
			if event.is_mouse_press and event.mouse_button = 1 then
				if event.mouse_y = absolute_y then
					-- Click on menu bar
					mx := event.mouse_x - absolute_x
					clicked_menu := menu_at_position (mx)
					if clicked_menu > 0 then
						if is_menu_open and clicked_menu = selected_menu then
							close_menu
						else
							open_menu (clicked_menu)
						end
						Result := True
					end
				end
			end
		end

feature -- Rendering

	render (buffer: TUI_BUFFER)
			-- Render menu bar to buffer.
		local
			ax, ay, i, menu_x: INTEGER
			l_menu: TUI_MENU
			title_style: TUI_STYLE
			padded_title: STRING_32
		do
			ax := absolute_x
			ay := absolute_y

			-- Fill background
			buffer.put_string (ax, ay, create {STRING_32}.make_filled (' ', width), normal_style)

			-- Draw menu titles
			menu_x := ax
			from i := 1 until i > menus.count loop
				l_menu := menus.i_th (i)

				-- Choose style
				if i = selected_menu then
					if is_menu_open then
						title_style := open_style
					else
						title_style := selected_style
					end
				else
					title_style := normal_style
				end

				-- Draw title with padding
				create padded_title.make (l_menu.title.count + 2)
				padded_title.append_character (' ')
				padded_title.append (l_menu.title)
				padded_title.append_character (' ')

				buffer.put_string (menu_x, ay, padded_title, title_style)
				menu_x := menu_x + padded_title.count

				i := i + 1
			end

			-- Render open menu
			if is_menu_open and then attached current_menu as cur_menu then
				cur_menu.render (buffer)
			end
		end

feature -- Queries

	preferred_width: INTEGER
			-- Width for all menu titles.
		local
			i, total: INTEGER
		do
			total := 0
			from i := 1 until i > menus.count loop
				total := total + menus.i_th (i).title.count + 2  -- padding
				i := i + 1
			end
			Result := total.max (width)
		end

	preferred_height: INTEGER
			-- Height is always 1 for bar, plus open menu if any.
		do
			if is_menu_open and then attached current_menu as menu then
				Result := 1 + menu.preferred_height
			else
				Result := 1
			end
		end

feature {NONE} -- Implementation

	menu_position_x (index: INTEGER): INTEGER
			-- X position of menu at index.
		local
			i: INTEGER
		do
			Result := absolute_x
			from i := 1 until i >= index loop
				Result := Result + menus.i_th (i).title.count + 2
				i := i + 1
			end
		end

	menu_at_position (mx: INTEGER): INTEGER
			-- Menu index at x position, 0 if none.
		local
			i, pos, title_width: INTEGER
		do
			pos := 0
			from i := 1 until i > menus.count or Result > 0 loop
				title_width := menus.i_th (i).title.count + 2
				if mx >= pos and mx < pos + title_width then
					Result := i
				end
				pos := pos + title_width
				i := i + 1
			end
		end

	try_menu_shortcut (event: TUI_EVENT): BOOLEAN
			-- Try Alt+key shortcut to open menu.
		local
			i: INTEGER
			menu: TUI_MENU
			key_lower: CHARACTER_32
			title_shortcut: CHARACTER_32
		do
			if event.has_alt then
				key_lower := event.char.as_lower
				from i := 1 until i > menus.count or Result loop
					menu := menus.i_th (i)
					title_shortcut := extract_shortcut (menu.title)
					if title_shortcut /= '%U' and then title_shortcut.as_lower = key_lower then
						open_menu (i)
						Result := True
					end
					i := i + 1
				end
			end
		end

	extract_shortcut (title: STRING_32): CHARACTER_32
			-- Extract shortcut character from title (after &).
		local
			i: INTEGER
		do
			Result := '%U'
			from i := 1 until i >= title.count loop
				if title.item (i) = '&' then
					Result := title.item (i + 1)
					i := title.count  -- exit loop
				end
				i := i + 1
			end
		end

	on_menu_closed
			-- Called when open menu closes itself.
		do
			is_menu_open := False
		end

invariant
	menus_exist: menus /= Void
	normal_style_exists: normal_style /= Void
	selected_style_exists: selected_style /= Void

end
