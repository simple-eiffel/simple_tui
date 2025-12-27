note
	description: "[
		TUI_COMBO_BOX - Dropdown selection widget

		Shows current selection with dropdown list on activation.

		EV equivalent: EV_COMBO_BOX
		Other frameworks: Select, Dropdown, ComboBox, Picker

		Features:
		- Single selection from list
		- Keyboard navigation (arrows, type-to-search)
		- Expandable dropdown
		- Custom styling
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_COMBO_BOX

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
			-- Create combo box with width.
		require
			valid_width: a_width > 0
		do
			make_widget
			width := a_width
			height := 1
			is_focusable := True
			create items.make (10)
			selected_index := 0
			is_expanded := False
			max_visible_items := 5
			create normal_style.make_default
			create focused_style.make_default
			create dropdown_style.make_default
			create selected_item_style.make_default
			focused_style.set_reverse (True)
			selected_item_style.set_reverse (True)
		ensure
			width_set: width = a_width
			focusable: is_focusable
		end

feature -- Access

	items: ARRAYED_LIST [STRING_32]
			-- Available items.
			-- Aliases: options, choices

	options: ARRAYED_LIST [STRING_32]
			-- Alias for items.
		do
			Result := items
		end

	selected_index: INTEGER
			-- Currently selected index (1-based, 0 = none).
			-- Aliases: value, selected_item_index

	value: INTEGER
			-- Alias for selected_index.
		do
			Result := selected_index
		end

	selected_text: detachable STRING_32
			-- Currently selected item text.
			-- Aliases: selected_item, text
		do
			if selected_index > 0 and selected_index <= items.count then
				Result := items.i_th (selected_index)
			end
		end

	text: detachable STRING_32
			-- Alias for selected_text.
		do
			Result := selected_text
		end

	is_expanded: BOOLEAN
			-- Is dropdown currently shown?
			-- Aliases: is_open

	is_open: BOOLEAN
			-- Alias for is_expanded.
		do
			Result := is_expanded
		end

	max_visible_items: INTEGER
			-- Maximum items visible in dropdown.

	on_change: detachable PROCEDURE [INTEGER]
			-- Called when selection changes.
			-- Aliases: on_select

	on_select: detachable PROCEDURE [INTEGER]
			-- Alias for on_change.
		do
			Result := on_change
		end

feature -- Styles

	normal_style: TUI_STYLE
			-- Style for normal state.

	focused_style: TUI_STYLE
			-- Style for focused state.

	dropdown_style: TUI_STYLE
			-- Style for dropdown items.

	selected_item_style: TUI_STYLE
			-- Style for selected item in dropdown.

feature -- Modification

	add_item (item: READABLE_STRING_GENERAL)
			-- Add item to the list.
		require
			item_exists: item /= Void
		do
			items.extend (item.to_string_32)
			if selected_index = 0 then
				selected_index := 1
			end
		ensure
			item_added: items.count = old items.count + 1
		end

	add_items (new_items: ITERABLE [READABLE_STRING_GENERAL])
			-- Add multiple items.
		do
			across new_items as ic loop
				add_item (ic)
			end
		end

	remove_item (index: INTEGER)
			-- Remove item at index.
		require
			valid_index: index >= 1 and index <= items.count
		do
			items.go_i_th (index)
			items.remove
			if selected_index > items.count then
				selected_index := items.count
			end
		ensure
			item_removed: items.count = old items.count - 1
		end

	clear, wipe_out
			-- Remove all items.
		do
			items.wipe_out
			selected_index := 0
		ensure
			empty: items.is_empty
			no_selection: selected_index = 0
		end

	select_index, set_value (idx: INTEGER)
			-- Select item at index.
		require
			valid_index: idx >= 0 and idx <= items.count
		do
			selected_index := idx
			notify_change
		ensure
			index_set: selected_index = idx
		end

	expand
			-- Show dropdown.
			-- Aliases: open
		do
			is_expanded := True
			dropdown_scroll := 0
		ensure
			now_expanded: is_expanded
		end

	open
			-- Alias for expand.
		do
			expand
		end

	collapse
			-- Hide dropdown.
			-- Aliases: close
		do
			is_expanded := False
		ensure
			now_collapsed: not is_expanded
		end

	close
			-- Alias for collapse.
		do
			collapse
		end

	toggle
			-- Toggle dropdown visibility.
		do
			if is_expanded then
				collapse
			else
				expand
			end
		end

	set_max_visible_items (n: INTEGER)
			-- Set maximum visible items in dropdown.
		require
			valid: n > 0
		do
			max_visible_items := n
		ensure
			max_set: max_visible_items = n
		end

	set_on_change, set_on_select (handler: PROCEDURE [INTEGER])
			-- Set change handler.
		do
			on_change := handler
		ensure
			handler_set: on_change = handler
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

	set_focused_style (s: TUI_STYLE)
			-- Set focused style.
		require
			s_exists: s /= Void
		do
			focused_style := s
		ensure
			style_set: focused_style = s
		end

	set_dropdown_style (s: TUI_STYLE)
			-- Set dropdown style.
		require
			s_exists: s /= Void
		do
			dropdown_style := s
		ensure
			style_set: dropdown_style = s
		end

feature -- Rendering

	render (buffer: TUI_BUFFER)
			-- Render combo box to buffer.
		local
			ax, ay: INTEGER
			current_style: TUI_STYLE
			display: STRING_32
		do
			ax := absolute_x
			ay := absolute_y

			-- Choose style
			if is_focused then
				current_style := focused_style
			else
				current_style := normal_style
			end

			-- Build display: [Selected Item   v]
			create display.make (width)
			if attached selected_text as sel then
				display.append (sel)
			else
				display.append ("-")
			end

			-- Pad and add dropdown indicator
			from until display.count >= width - 2 loop
				display.append_character (' ')
			end
			if display.count > width - 2 then
				display := display.substring (1, width - 2)
			end
			display.append_character (' ')
			if is_expanded then
				display.append_character ('%/0x25B2/')  -- Up arrow
			else
				display.append_character ('%/0x25BC/')  -- Down arrow
			end

			buffer.put_string (ax, ay, display, current_style)

			-- Render dropdown if expanded
			if is_expanded then
				render_dropdown (buffer, ax, ay + 1)
			end
		end

feature -- Event Handling

	handle_key (event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_focused then
				if is_expanded then
					Result := handle_key_expanded (event)
				else
					Result := handle_key_collapsed (event)
				end
			end
		end

	handle_mouse (event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			my, clicked_index: INTEGER
		do
			if event.is_mouse_press and event.mouse_button = 1 then
				if contains_point (event.mouse_x, event.mouse_y) then
					-- Click on combo box itself
					toggle
					Result := True
				elseif is_expanded then
					-- Check if click is in dropdown
					my := event.mouse_y - absolute_y - 1
					if my >= 0 and my < visible_item_count then
						clicked_index := dropdown_scroll + my + 1
						if clicked_index >= 1 and clicked_index <= items.count then
							select_index (clicked_index)
							collapse
							Result := True
						end
					else
						collapse
						Result := True
					end
				end
			end
		end

feature -- Queries

	preferred_width: INTEGER
			-- Preferred width based on items.
		local
			i, max_len: INTEGER
		do
			max_len := 0
			from i := 1 until i > items.count loop
				max_len := max_len.max (items.i_th (i).count)
				i := i + 1
			end
			Result := (max_len + 3).max (width)  -- +3 for padding and arrow
		end

	preferred_height: INTEGER
			-- Preferred height.
		do
			if is_expanded then
				Result := 1 + visible_item_count
			else
				Result := 1
			end
		end

feature {NONE} -- Implementation

	dropdown_scroll: INTEGER
			-- Scroll offset in dropdown.

	visible_item_count: INTEGER
			-- Number of visible items in dropdown.
		do
			Result := items.count.min (max_visible_items)
		end

	render_dropdown (buffer: TUI_BUFFER; dx, dy: INTEGER)
			-- Render dropdown list.
		local
			i, draw_y: INTEGER
			item_text: STRING_32
			item_style: TUI_STYLE
		do
			draw_y := 0
			from i := dropdown_scroll + 1 until draw_y >= visible_item_count or i > items.count loop
				item_text := items.i_th (i)

				-- Pad to width
				create item_text.make_from_string (item_text)
				from until item_text.count >= width loop
					item_text.append_character (' ')
				end
				if item_text.count > width then
					item_text := item_text.substring (1, width)
				end

				-- Choose style
				if i = selected_index then
					item_style := selected_item_style
				else
					item_style := dropdown_style
				end

				buffer.put_string (dx, dy + draw_y, item_text, item_style)
				draw_y := draw_y + 1
				i := i + 1
			end
		end

	handle_key_collapsed (event: TUI_EVENT): BOOLEAN
			-- Handle key when collapsed.
		do
			if event.is_enter or event.is_space then
				expand
				Result := True
			elseif event.is_up then
				if selected_index > 1 then
					select_index (selected_index - 1)
				end
				Result := True
			elseif event.is_down then
				if selected_index < items.count then
					select_index (selected_index + 1)
				end
				Result := True
			end
		end

	handle_key_expanded (event: TUI_EVENT): BOOLEAN
			-- Handle key when expanded.
		do
			if event.is_escape then
				collapse
				Result := True
			elseif event.is_enter or event.is_space then
				collapse
				Result := True
			elseif event.is_up then
				if selected_index > 1 then
					select_index (selected_index - 1)
					ensure_visible
				end
				Result := True
			elseif event.is_down then
				if selected_index < items.count then
					select_index (selected_index + 1)
					ensure_visible
				end
				Result := True
			end
		end

	ensure_visible
			-- Ensure selected item is visible in dropdown.
		do
			if selected_index <= dropdown_scroll then
				dropdown_scroll := selected_index - 1
			elseif selected_index > dropdown_scroll + visible_item_count then
				dropdown_scroll := selected_index - visible_item_count
			end
			dropdown_scroll := dropdown_scroll.max (0).min ((items.count - visible_item_count).max (0))
		end

	notify_change
			-- Notify change handler.
		do
			if attached on_change as handler then
				handler.call ([selected_index])
			end
		end

invariant
	items_exist: items /= Void
	valid_selection: selected_index >= 0 and selected_index <= items.count
	normal_style_exists: normal_style /= Void
	focused_style_exists: focused_style /= Void
	dropdown_style_exists: dropdown_style /= Void

end
