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
			focus_from_next,
			focus_from_previous,
			unfocus,
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
			create hotkey_style.make_default
			selected_style.set_reverse (True)
			open_style.set_reverse (True)
			open_style.set_bold (True)
			hotkey_style.set_underline (True)
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

	hotkey_style: TUI_STYLE
			-- Style for hotkey character (underlined).

feature -- Modification

	add_menu (a_menu: TUI_MENU)
			-- Add menu to bar.
		require
			menu_exists: a_menu /= Void
		do
			menus.extend (a_menu)
			add_child (a_menu)
			a_menu.hide
			a_menu.set_on_close (agent on_menu_closed)
		ensure
			menu_added: menus.has (a_menu)
		end

	remove_menu (a_menu: TUI_MENU)
			-- Remove menu from bar.
		require
			menu_exists: a_menu /= Void
		do
			menus.prune_all (a_menu)
			remove_child (a_menu)
		ensure
			menu_removed: not menus.has (a_menu)
		end

	set_normal_style (a_s: TUI_STYLE)
			-- Set normal style.
		require
			s_exists: a_s /= Void
		do
			normal_style := a_s
		ensure
			style_set: normal_style = a_s
		end

	set_selected_style (a_s: TUI_STYLE)
			-- Set selected style.
		require
			s_exists: a_s /= Void
		do
			selected_style := a_s
		ensure
			style_set: selected_style = a_s
		end

	set_open_style (a_s: TUI_STYLE)
			-- Set open menu style.
		require
			s_exists: a_s /= Void
		do
			open_style := a_s
		ensure
			style_set: open_style = a_s
		end

feature -- Focus

	focus_from_next
			-- Focus first menu when Tab-ing forward.
		do
			Precursor
			if menus.count > 0 then
				selected_menu := 1
			end
		ensure then
			first_selected: menus.count > 0 implies selected_menu = 1
		end

	focus_from_previous
			-- Focus last menu when Shift+Tab-ing backward.
		do
			Precursor
			if menus.count > 0 then
				selected_menu := menus.count
			end
		ensure then
			last_selected: menus.count > 0 implies selected_menu = menus.count
		end

	unfocus
			-- Clear selection and close any open menu.
		do
			Precursor
			close_menu
			selected_menu := 0
		ensure then
			no_selection: selected_menu = 0
			menu_closed: not is_menu_open
		end

feature -- Menu Control

	open_menu (a_index: INTEGER)
			-- Open menu at index.
		require
			valid_index: a_index >= 1 and a_index <= menus.count
		local
			l_menu: TUI_MENU
			l_menu_x: INTEGER
		do
			-- Close any open menu first
			close_menu

			selected_menu := a_index
			is_menu_open := True
			menu := menus.i_th (a_index)

			-- Position menu below its title
			menu_x := menu_position_x (a_index)
			menu.show_at (menu_x, absolute_y + 1)
		ensure
			menu_open: is_menu_open
			menu_selected: selected_menu = a_index
		end

	close_menu
			-- Close currently open menu.
		do
			if is_menu_open and then attached current_menu as al_menu then
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

	handle_key (a_event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			-- F10 toggles menu bar open/close
			if a_event.is_key (a_event.Key_f10) then
				if is_menu_open then
					log_debug ("F10 pressed, closing menu")
					close_menu
				else
					log_debug ("F10 pressed, opening menu")
					if selected_menu = 0 and menus.count > 0 then
						selected_menu := 1
					end
					if selected_menu > 0 then
						open_menu (selected_menu)
					end
				end
				Result := True
			end

			-- Always check Alt+key shortcuts, even when not focused
			if not Result and a_event.has_alt and not is_menu_open then
				log_debug ("Alt+key shortcut check, char=" + a_event.char.natural_32_code.out)
				Result := try_menu_shortcut (a_event)
				if Result then
					log_debug ("Alt+key shortcut matched, opened menu")
				end
			end

			if not Result and (is_focused or is_menu_open) then
				if is_menu_open then
					-- Let open menu handle keys first
					if attached current_menu as al_menu then
						log_debug ("Delegating key to open menu")
						Result := al_menu.handle_key (a_event)
						if Result then
							log_debug ("Open menu handled key")
						end
					end
					-- Handle left/right to switch menus
					if not Result then
						if a_event.is_left then
							log_debug ("LEFT arrow, switching to previous menu")
							select_previous_menu
							Result := True
						elseif a_event.is_right then
							log_debug ("RIGHT arrow, switching to next menu")
							select_next_menu
							Result := True
						elseif a_event.is_escape then
							log_debug ("ESCAPE, closing menu")
							close_menu
							Result := True
						end
					end
				else
					-- Menu bar focused but no menu open
					if a_event.is_left then
						log_debug ("LEFT arrow (bar focused), previous menu")
						select_previous_menu
						Result := True
					elseif a_event.is_right then
						log_debug ("RIGHT arrow (bar focused), next menu")
						select_next_menu
						Result := True
					elseif a_event.is_tab and a_event.has_shift then
						-- Shift+Tab: only consume if not on first menu
						if selected_menu > 1 then
							select_previous_menu
							Result := True
						end
						-- else: let Tab escape to previous widget
					elseif a_event.is_tab then
						-- Tab: only consume if not on last menu
						if selected_menu < menus.count then
							select_next_menu
							Result := True
						end
						-- else: let Tab escape to next widget
					elseif a_event.is_enter or a_event.is_space or a_event.is_down then
						log_debug ("ENTER/SPACE/DOWN opening menu dropdown")
						if selected_menu > 0 then
							open_menu (selected_menu)
						elseif menus.count > 0 then
							selected_menu := 1
							open_menu (1)
						end
						Result := True
					else
						-- Check Alt+key shortcuts (for focused state)
						Result := try_menu_shortcut (a_event)
					end
				end
			end
		end

	handle_mouse (a_event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			mx, clicked_menu: INTEGER
		do
			-- Pass mouse events to open menu dropdown first
			if is_menu_open and attached current_menu as al_menu then
				Result := menu.handle_mouse (a_event)
			end

			if not Result then
				if a_event.mouse_y = absolute_y then
					-- Mouse on menu bar
					mx := a_event.mouse_x - absolute_x
					clicked_menu := menu_at_position (mx)
					if a_event.is_mouse_press and a_event.mouse_button = 1 then
						-- Click on menu bar
						if clicked_menu > 0 then
							if is_menu_open and clicked_menu = selected_menu then
								close_menu
							else
								open_menu (clicked_menu)
							end
							Result := True
						end
					end
				elseif is_menu_open and a_event.is_mouse_press then
					-- Click outside menu bar while menu is open - close it
					close_menu
					Result := True
				end
			end
		end

feature -- Rendering

	render (a_buffer: TUI_BUFFER)
			-- Render menu bar to buffer.
		local
			ax, ay, i, menu_x: INTEGER
			l_menu: TUI_MENU
			l_title_style: TUI_STYLE
		do
			ax := absolute_x
			ay := absolute_y

			-- Fill background
			a_buffer.put_string (ax, ay, create {STRING_32}.make_filled (' ', width), normal_style)

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

				-- Draw title with hotkey underlining
				a_buffer.put_char (menu_x, ay, ' ', title_style)
				render_with_hotkey (a_buffer, menu_x + 1, ay, l_menu.title, title_style)
				a_buffer.put_char (menu_x + 1 + display_width (l_menu.title), ay, ' ', title_style)
				menu_x := menu_x + display_width (l_menu.title) + 2

				i := i + 1
			end

			-- Note: Open menu dropdown is rendered by TUI_APPLICATION
			-- after all other widgets (so it appears on top)
		end

feature -- Queries

	preferred_width: INTEGER
			-- Width for all menu titles.
		local
			i, total: INTEGER
		do
			total := 0
			from i := 1 until i > menus.count loop
				total := total + display_width (menus.i_th (i).title) + 2  -- padding
				i := i + 1
			end
			Result := total.max (width)
		end

	preferred_height: INTEGER
			-- Height is always 1 for bar, plus open menu if any.
		do
			if is_menu_open and then attached current_menu as al_menu then
				Result := 1 + menu.preferred_height
			else
				Result := 1
			end
		end

feature {NONE} -- Implementation

	menu_position_x (a_index: INTEGER): INTEGER
			-- X position of menu at index.
		local
			i: INTEGER
		do
			Result := absolute_x
			from i := 1 until i >= a_index loop
				Result := Result + display_width (menus.i_th (i).title) + 2
				i := i + 1
			end
		end

	menu_at_position (a_mx: INTEGER): INTEGER
			-- Menu index at x position, 0 if none.
		local
			i, pos, title_width: INTEGER
		do
			pos := 0
			from i := 1 until i > menus.count or Result > 0 loop
				title_width := display_width (menus.i_th (i).title) + 2
				if a_mx >= pos and a_mx < pos + title_width then
					Result := i
				end
				pos := pos + title_width
				i := i + 1
			end
		end

	try_menu_shortcut (a_event: TUI_EVENT): BOOLEAN
			-- Try Alt+key shortcut to open menu.
		local
			i: INTEGER
			l_menu: TUI_MENU
			l_key_lower: CHARACTER_32
			l_title_shortcut: CHARACTER_32
		do
			if a_event.has_alt then
				key_lower := a_event.char.as_lower
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

	extract_shortcut (a_title: STRING_32): CHARACTER_32
			-- Extract shortcut character from title (after &).
		local
			i: INTEGER
		do
			Result := '%U'
			from i := 1 until i >= a_title.count loop
				if a_title.item (i) = '&' then
					Result := a_title.item (i + 1)
					i := a_title.count  -- exit loop
				end
				i := i + 1
			end
		end

	on_menu_closed
			-- Called when open menu closes itself.
		do
			is_menu_open := False
		end

	render_with_hotkey (a_buffer: TUI_BUFFER; start_x, start_y: INTEGER; text: STRING_32; base_style: TUI_STYLE)
			-- Render text with hotkey character underlined.
			-- Character after & is rendered with underline added to base_style.
		local
			i, pos_x: INTEGER
			c: CHARACTER_32
			l_merged_style: TUI_STYLE
		do
			pos_x := start_x
			from i := 1 until i > text.count loop
				c := text.item (i)
				if c = '&' and i < text.count then
					-- Next character is the hotkey - render with underline added
					i := i + 1
					c := text.item (i)
					merged_style := base_style.twin_style
					merged_style.set_underline (True)
					a_buffer.put_char (pos_x, start_y, c, merged_style)
					pos_x := pos_x + 1
				else
					a_buffer.put_char (pos_x, start_y, c, base_style)
					pos_x := pos_x + 1
				end
				i := i + 1
			end
		end

	display_width (a_text: STRING_32): INTEGER
			-- Calculate display width of text excluding & markers.
		local
			i: INTEGER
			c: CHARACTER_32
		do
			from i := 1 until i > a_text.count loop
				c := a_text.item (i)
				if c = '&' and i < a_text.count then
					-- Skip the &, but count the next character
					i := i + 1
					Result := Result + 1
				else
					Result := Result + 1
				end
				i := i + 1
			end
		end

	log_debug (a_msg: STRING)
			-- Log debug message to file.
		local
			l_file: PLAIN_TEXT_FILE
		do
			create l_file.make_open_append ("tui_demo.log")
			if l_file.is_open_write then
				l_file.put_string ("  [MENU_BAR] " + a_msg)
				l_file.put_new_line
				l_file.close
			end
		end

invariant
	menus_exist: menus /= Void
	normal_style_exists: normal_style /= Void
	selected_style_exists: selected_style /= Void
	hotkey_style_exists: hotkey_style /= Void

end
