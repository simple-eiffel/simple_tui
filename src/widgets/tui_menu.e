note
	description: "[
		TUI_MENU - Drop-down/popup menu

		Contains TUI_MENU_ITEMs and can be shown at a position.

		EV equivalent: EV_MENU
		Other frameworks: Menu, PopupMenu, ContextMenu, DropdownMenu

		Features:
		- Contains menu items
		- Can have submenu items (nested TUI_MENU)
		- Show at position or relative to widget
		- Keyboard navigation and shortcuts
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_MENU

inherit
	TUI_WIDGET
		redefine
			handle_key,
			handle_mouse,
			preferred_width,
			preferred_height
		end

create
	make,
	make_with_title

feature {NONE} -- Initialization

	make
			-- Create empty menu.
		do
			make_widget
			create title.make_empty
			create items.make (10)
			selected_index := 0
			is_visible := False
			create normal_style.make_default
			create selected_style.make_default
			create disabled_style.make_default
			create border_style.make_default
			create hotkey_style.make_default
			selected_style.set_reverse (True)
			disabled_style.set_foreground (create {TUI_COLOR}.make_index (8))  -- Gray
			-- Set border to bright cyan for visibility
			border_style.set_foreground (create {TUI_COLOR}.make_index (14))
			hotkey_style.set_underline (True)
		ensure
			empty: items.is_empty
			hidden: not is_visible
		end

	make_with_title (a_title: READABLE_STRING_GENERAL)
			-- Create menu with title.
		require
			title_exists: a_title /= Void
		do
			make
			title := a_title.to_string_32
		ensure
			title_set: title.same_string_general (a_title)
		end

feature -- Access

	title: STRING_32
			-- Menu title (for menu bar display).

	items: ARRAYED_LIST [TUI_MENU_ITEM]
			-- Menu items.

	selected_index: INTEGER
			-- Currently highlighted item (1-based, 0 = none).

	selected_item: detachable TUI_MENU_ITEM
			-- Currently highlighted item.
		do
			if selected_index > 0 and selected_index <= items.count then
				Result := items.i_th (selected_index)
			end
		end

	on_close: detachable PROCEDURE
			-- Called when menu is closed.

feature -- Styles

	normal_style: TUI_STYLE
			-- Style for normal items.

	selected_style: TUI_STYLE
			-- Style for selected/highlighted item.

	disabled_style: TUI_STYLE
			-- Style for disabled items.

	border_style: TUI_STYLE
			-- Style for menu border (box drawing characters).

	hotkey_style: TUI_STYLE
			-- Style for hotkey character (underlined).

feature -- Status

	is_open: BOOLEAN
			-- Is menu currently visible?
		do
			Result := is_visible
		end

feature -- Modification

	add_item (a_item: TUI_MENU_ITEM)
			-- Add item to menu.
		require
			item_exists: a_item /= Void
		do
			items.extend (a_item)
			a_item.set_parent_menu (Current)
		ensure
			item_added: items.has (a_item)
		end

	add_separator
			-- Add separator line.
		local
			l_sep: TUI_MENU_ITEM
		do
			create sep.make_separator
			add_item (sep)
		ensure
			item_added: items.count = old items.count + 1
		end

	remove_item (a_item: TUI_MENU_ITEM)
			-- Remove item from menu.
		require
			item_exists: a_item /= Void
		do
			a_item.set_parent_menu (Void)
			items.prune_all (a_item)
		ensure
			item_removed: not items.has (a_item)
		end

	clear, wipe_out
			-- Remove all items.
		do
			across items as ic loop
				ic.set_parent_menu (Void)
			end
			items.wipe_out
			selected_index := 0
		ensure
			empty: items.is_empty
		end

	set_title (a_title: READABLE_STRING_GENERAL)
			-- Set menu title.
		require
			title_exists: a_title /= Void
		do
			title := a_title.to_string_32
		ensure
			title_set: title.same_string_general (a_title)
		end

	set_on_close (a_handler: PROCEDURE)
			-- Set close handler.
		do
			on_close := a_handler
		ensure
			handler_set: on_close = a_handler
		end

	set_normal_style (a_s: TUI_STYLE)
			-- Set normal item style.
		require
			s_exists: a_s /= Void
		do
			normal_style := a_s
		ensure
			style_set: normal_style = a_s
		end

	set_selected_style (a_s: TUI_STYLE)
			-- Set selected item style.
		require
			s_exists: a_s /= Void
		do
			selected_style := a_s
		ensure
			style_set: selected_style = a_s
		end

	set_disabled_style (a_s: TUI_STYLE)
			-- Set disabled item style.
		require
			s_exists: a_s /= Void
		do
			disabled_style := a_s
		ensure
			style_set: disabled_style = a_s
		end

feature -- Display

	show_at (a_x, a_y: INTEGER)
			-- Show menu at position.
		do
			set_position (a_x, a_y)
			show
			-- Select first selectable item
			select_first
			-- Ignore first Enter to prevent immediate execution
			ignore_next_enter := True
		ensure
			visible: is_visible
		end

	close
			-- Hide menu.
		do
			hide
			selected_index := 0
			if attached on_close as al_handler then
				al_handler.call (Void)
			end
		ensure
			hidden: not is_visible
		end

feature -- Navigation

	select_next
			-- Move selection to next enabled item.
		local
			start_idx, i: INTEGER
		do
			if items.is_empty then
				selected_index := 0
			else
				start_idx := selected_index
				from
					i := selected_index + 1
					if i > items.count then i := 1 end
				until
					i = start_idx or else (not items.i_th (i).is_separator and items.i_th (i).is_sensitive)
				loop
					i := i + 1
					if i > items.count then i := 1 end
					if start_idx = 0 and i = 1 then
						start_idx := 1  -- Prevent infinite loop when starting from 0
					end
				end
				if not items.i_th (i).is_separator and items.i_th (i).is_sensitive then
					selected_index := i
				end
			end
		end

	select_previous
			-- Move selection to previous enabled item.
		local
			start_idx, i: INTEGER
		do
			if items.is_empty then
				selected_index := 0
			else
				start_idx := selected_index
				if start_idx = 0 then start_idx := 1 end
				from
					i := selected_index - 1
					if i < 1 then i := items.count end
				until
					i = start_idx or else (not items.i_th (i).is_separator and items.i_th (i).is_sensitive)
				loop
					i := i - 1
					if i < 1 then i := items.count end
				end
				if not items.i_th (i).is_separator and items.i_th (i).is_sensitive then
					selected_index := i
				end
			end
		end

	select_first
			-- Select first enabled item.
		do
			selected_index := 0
			select_next
		end

	execute_selected
			-- Execute selected item's action.
		do
			if attached selected_item as al_item then
				al_item.execute
				close
			end
		end

feature -- Event Handling

	handle_key (a_event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_visible then
				if a_event.is_up then
					log_debug ("UP arrow, selecting previous")
					select_previous
					ignore_next_enter := False
					Result := True
				elseif a_event.is_down then
					log_debug ("DOWN arrow, selecting next")
					select_next
					ignore_next_enter := False
					Result := True
				elseif a_event.is_enter or a_event.is_space then
					if ignore_next_enter then
						-- Skip first Enter after menu opened (same key that opened it)
						log_debug ("ENTER/SPACE ignored (first after open)")
						ignore_next_enter := False
					else
						log_debug ("ENTER/SPACE executing selected")
						execute_selected
					end
					Result := True
				elseif a_event.is_escape then
					log_debug ("ESCAPE closing menu")
					close
					Result := True
				else
					-- Check shortcut keys
					log_debug ("try_shortcut called with char=" + a_event.char.natural_32_code.out)
					ignore_next_enter := False
					Result := try_shortcut (a_event.char)
				end
			end
		end

	handle_mouse (a_event: TUI_EVENT): BOOLEAN
			-- Handle mouse event for hover and click.
		local
			ax, ay, item_index, my: INTEGER
		do
			if is_visible then
				ax := absolute_x
				ay := absolute_y

				-- Check if mouse is within menu bounds
				if a_event.mouse_x >= ax and a_event.mouse_x < ax + preferred_width then
					my := a_event.mouse_y
					-- Item area is from ay+1 to ay+items.count (borders at ay and ay+items.count+1)
					if my > ay and my <= ay + items.count then
						item_index := my - ay
						-- Highlight on hover (any mouse event in item area)
						if item_index >= 1 and item_index <= items.count then
							if not items.i_th (item_index).is_separator and items.i_th (item_index).is_sensitive then
								selected_index := item_index
								ignore_next_enter := False
							end
						end
						-- Click to execute
						if a_event.is_mouse_press and a_event.mouse_button = 1 then
							if selected_index > 0 then
								execute_selected
							end
							Result := True
						else
							Result := True  -- Consume hover events too
						end
					end
				end
			end
		end

feature -- Rendering

	render (a_buffer: TUI_BUFFER)
			-- Render menu to buffer with border box.
		local
			ax, ay, i, j, item_y: INTEGER
			l_item: TUI_MENU_ITEM
			l_item_style: TUI_STYLE
			menu_width, inner_width: INTEGER
			top_border, bottom_border, sep_line: STRING_32
		do
			if is_visible then
				ax := absolute_x
				ay := absolute_y
				menu_width := preferred_width
				inner_width := menu_width - 2  -- Subtract border chars

				-- Draw top border: ┌───┐
				create top_border.make (menu_width)
				top_border.append_character ('%/0x250C/')  -- ┌
				from j := 1 until j > inner_width loop
					top_border.append_character ('%/0x2500/')  -- ─
					j := j + 1
				end
				top_border.append_character ('%/0x2510/')  -- ┐
				a_buffer.put_string (ax, ay, top_border, border_style)

				-- Draw menu items with side borders
				from i := 1 until i > items.count loop
					item := items.i_th (i)
					item_y := ay + i  -- +1 for top border

					if item.is_separator then
						-- Draw separator: ├───┤
						create sep_line.make (menu_width)
						sep_line.append_character ('%/0x251C/')  -- ├
						from j := 1 until j > inner_width loop
							sep_line.append_character ('%/0x2500/')  -- ─
							j := j + 1
						end
						sep_line.append_character ('%/0x2524/')  -- ┤
						a_buffer.put_string (ax, item_y, sep_line, border_style)
					else
						-- Choose style
						if not item.is_sensitive then
							item_style := disabled_style
						elseif i = selected_index then
							item_style := selected_style
						else
							item_style := normal_style
						end

						-- Draw item with hotkey underlining: │ item │
						a_buffer.put_char (ax, ay + i, '%/0x2502/', border_style)  -- │
						render_item_with_hotkey (a_buffer, ax + 1, ay + i, item, inner_width, item_style)
						a_buffer.put_char (ax + menu_width - 1, ay + i, '%/0x2502/', border_style)  -- │
					end
					i := i + 1
				end

				-- Draw bottom border: └───┘
				create bottom_border.make (menu_width)
				bottom_border.append_character ('%/0x2514/')  -- └
				from j := 1 until j > inner_width loop
					bottom_border.append_character ('%/0x2500/')  -- ─
					j := j + 1
				end
				bottom_border.append_character ('%/0x2518/')  -- ┘
				a_buffer.put_string (ax, ay + items.count + 1, bottom_border, border_style)
			end
		end

feature -- Queries

	preferred_width: INTEGER
			-- Width needed for widest item.
			-- Adds 4: 2 for borders (│) + 2 for left/right padding spaces.
		local
			i, max_w: INTEGER
		do
			max_w := title.count + 4
			from i := 1 until i > items.count loop
				if not items.i_th (i).is_separator then
					max_w := max_w.max (items.i_th (i).display_text.count + 4)
				end
				i := i + 1
			end
			Result := max_w.max (width)
		end

	preferred_height: INTEGER
			-- Height for all items plus borders.
		do
			Result := items.count + 2  -- +2 for top and bottom borders
		end

feature {NONE} -- Implementation

	ignore_next_enter: BOOLEAN
			-- Skip next Enter to prevent immediate execution after opening.

	format_item (a_item: TUI_MENU_ITEM; w: INTEGER): STRING_32
			-- Format item text to width with padding.
		do
			create Result.make (w)
			Result.append_character (' ')
			Result.append (a_item.display_text)
			from until Result.count >= w loop
				Result.append_character (' ')
			end
			if Result.count > w then
				Result := Result.substring (1, w)
			end
		end

	render_item_with_hotkey (a_buffer: TUI_BUFFER; start_x, start_y: INTEGER; item: TUI_MENU_ITEM; w: INTEGER; base_style: TUI_STYLE)
			-- Render menu item with hotkey character underlined.
		local
			i, pos_x, remaining: INTEGER
			c: CHARACTER_32
			l_disp: STRING_32
			l_hotkey_merged: TUI_STYLE
		do
			disp := item.display_text
			pos_x := start_x

			-- Leading space
			a_buffer.put_char (pos_x, start_y, ' ', base_style)
			pos_x := pos_x + 1

			-- Render display text with hotkey underlining
			from i := 1 until i > disp.count loop
				c := disp.item (i)
				if i = item.shortcut_position then
					-- This is the hotkey character - underline it
					hotkey_merged := base_style.twin_style
					hotkey_merged.set_underline (True)
					a_buffer.put_char (pos_x, start_y, c, hotkey_merged)
				else
					a_buffer.put_char (pos_x, start_y, c, base_style)
				end
				pos_x := pos_x + 1
				i := i + 1
			end

			-- Pad remaining width with spaces
			remaining := w - disp.count - 1  -- -1 for leading space
			from i := 1 until i > remaining loop
				a_buffer.put_char (pos_x, start_y, ' ', base_style)
				pos_x := pos_x + 1
				i := i + 1
			end
		end

	try_shortcut (a_c: CHARACTER_32): BOOLEAN
			-- Try to execute item with shortcut key c.
			-- Only matches actual letter/number shortcuts, not null character.
		local
			i: INTEGER
			l_item: TUI_MENU_ITEM
			l_key_lower: CHARACTER_32
		do
			-- Ignore null character (from key release events)
			if a_c /= '%U' then
				key_lower := a_c.as_lower
				from i := 1 until i > items.count or Result loop
					item := items.i_th (i)
					if item.is_sensitive and item.shortcut_key /= '%U' and then item.shortcut_key = key_lower then
						log_debug ("try_shortcut matched item: " + item.display_text.to_string_8)
						item.execute
						close
						Result := True
					end
					i := i + 1
				end
			else
				log_debug ("try_shortcut ignoring null char")
			end
		end

	log_debug (a_msg: STRING)
			-- Log debug message to file.
		local
			l_file: PLAIN_TEXT_FILE
		do
			create l_file.make_open_append ("tui_demo.log")
			if l_file.is_open_write then
				l_file.put_string ("  [MENU] " + a_msg)
				l_file.put_new_line
				l_file.close
			end
		end

invariant
	items_exist: items /= Void
	normal_style_exists: normal_style /= Void
	selected_style_exists: selected_style /= Void
	border_style_exists: border_style /= Void
	hotkey_style_exists: hotkey_style /= Void

end
