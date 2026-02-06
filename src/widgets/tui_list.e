note
	description: "[
		TUI_LIST - Scrollable list widget

		Features:
		- Scrollable item list
		- Single/multi selection modes
		- Keyboard navigation
		- Mouse support
		- Custom item rendering
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_LIST

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

	make (a_width, a_height: INTEGER)
			-- Create list with size.
		require
			valid_width: a_width > 0
			valid_height: a_height > 0
		do
			make_widget
			width := a_width
			height := a_height
			is_focusable := True
			create items.make (10)
			selected_index := 0
			scroll_offset := 0
			is_multi_select := False
			create selected_indices.make (5)
			show_scrollbar := True
			create select_actions
			create activate_actions
			create normal_style.make_default
			create selected_style.make_default
			create focused_style.make_default
			selected_style.set_reverse (True)
			focused_style.set_bold (True)
		ensure
			width_set: width = a_width
			height_set: height = a_height
			focusable: is_focusable
		end

feature -- Access

	items: ARRAYED_LIST [STRING_32]
			-- List items.

	selected_index: INTEGER
			-- Currently highlighted item index (1-based, 0 = none).

	scroll_offset: INTEGER
			-- Current scroll position.

	is_multi_select: BOOLEAN
			-- Allow multiple selection?

	selected_indices: ARRAYED_LIST [INTEGER]
			-- Selected item indices (for multi-select mode).

	show_scrollbar: BOOLEAN
			-- Show scrollbar when content overflows?

feature -- Actions (EV compatible)

	select_actions: ACTION_SEQUENCE [TUPLE [INTEGER]]
			-- Actions to execute when selection changes.
			-- Passes selected index to handlers.
			-- Use `extend' to add handlers, `prune' to remove.
			-- EV equivalent: select_actions

	activate_actions: ACTION_SEQUENCE [TUPLE [INTEGER]]
			-- Actions to execute when item is activated (Enter/double-click).
			-- Passes activated index to handlers.

feature -- Styles

	normal_style: TUI_STYLE
			-- Style for normal items.

	selected_style: TUI_STYLE
			-- Style for selected/highlighted item.

	focused_style: TUI_STYLE
			-- Additional style when widget is focused.

feature -- Queries

	count: INTEGER
			-- Number of items.
		do
			Result := items.count
		end

	is_empty: BOOLEAN
			-- Is list empty?
		do
			Result := items.is_empty
		end

	selected_item: detachable STRING_32
			-- Currently selected item text.
		do
			if selected_index > 0 and selected_index <= items.count then
				Result := items.i_th (selected_index)
			end
		end

	is_selected (a_index: INTEGER): BOOLEAN
			-- Is item at index selected (in multi-select mode)?
		require
			valid_index: a_index >= 1 and a_index <= count
		do
			if is_multi_select then
				Result := selected_indices.has (a_index)
			else
				Result := selected_index = a_index
			end
		end

	visible_count: INTEGER
			-- Number of visible items.
		do
			Result := height.min (items.count)
		end

	preferred_width: INTEGER
			-- Preferred width based on content.
		local
			i, max_len: INTEGER
		do
			max_len := 0
			from i := 1 until i > items.count loop
				max_len := max_len.max (items.i_th (i).count)
				i := i + 1
			end
			Result := (max_len + 2).max (width)  -- +2 for selection indicator and scrollbar
		end

	preferred_height: INTEGER
			-- Preferred height based on content.
		do
			Result := items.count.max (1)
		end

feature -- Modification

	add_item (a_item: READABLE_STRING_GENERAL)
			-- Add item to list.
		require
			item_exists: a_item /= Void
		do
			items.extend (a_item.to_string_32)
			if selected_index = 0 and not items.is_empty then
				selected_index := 1
			end
		ensure
			item_added: items.count = old items.count + 1
		end

	add_items (a_new_items: ITERABLE [READABLE_STRING_GENERAL])
			-- Add multiple items.
		do
			across a_new_items as ic loop
				add_item (ic)
			end
		end

	remove_item (a_index: INTEGER)
			-- Remove item at index.
		require
			valid_index: a_index >= 1 and a_index <= count
		local
			i: INTEGER
		do
			items.go_i_th (a_index)
			items.remove
			-- Adjust selection
			if selected_index > items.count then
				selected_index := items.count
			end
			selected_indices.prune_all (a_index)
			-- Adjust indices in multi-select
			from i := 1 until i > selected_indices.count loop
				if selected_indices.i_th (i) > a_index then
					selected_indices.put_i_th (selected_indices.i_th (i) - 1, i)
				end
				i := i + 1
			end
		ensure
			item_removed: items.count = old items.count - 1
		end

	clear_items
			-- Remove all items.
		do
			items.wipe_out
			selected_index := 0
			scroll_offset := 0
			selected_indices.wipe_out
		ensure
			empty: items.is_empty
			no_selection: selected_index = 0
		end

	set_selected_index (a_index: INTEGER)
			-- Set selected index.
		require
			valid_index: a_index >= 0 and a_index <= count
		do
			selected_index := a_index
			ensure_visible (a_index)
			notify_select
		ensure
			selected: selected_index = a_index
		end

	toggle_selection (a_index: INTEGER)
			-- Toggle selection of item (multi-select mode).
		require
			valid_index: a_index >= 1 and a_index <= count
			multi_select: is_multi_select
		do
			if selected_indices.has (a_index) then
				selected_indices.prune_all (a_index)
			else
				selected_indices.extend (a_index)
			end
		end

	clear_selection
			-- Clear all selections.
		do
			selected_indices.wipe_out
		ensure
			no_selections: selected_indices.is_empty
		end

	set_multi_select (a_v: BOOLEAN)
			-- Set multi-select mode.
		do
			is_multi_select := a_v
			if not a_v then
				selected_indices.wipe_out
			end
		ensure
			multi_select_set: is_multi_select = a_v
		end

	set_show_scrollbar (a_v: BOOLEAN)
			-- Set scrollbar visibility.
		do
			show_scrollbar := a_v
		ensure
			show_scrollbar_set: show_scrollbar = a_v
		end

	set_on_select (a_handler: PROCEDURE [INTEGER])
			-- Set selection change handler (clears previous handlers).
			-- For multiple handlers, use select_actions.extend directly.
		do
			select_actions.wipe_out
			select_actions.extend (a_handler)
		end

	set_on_activate (a_handler: PROCEDURE [INTEGER])
			-- Set activation handler (clears previous handlers).
			-- For multiple handlers, use activate_actions.extend directly.
		do
			activate_actions.wipe_out
			activate_actions.extend (a_handler)
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

feature -- Navigation

	select_previous
			-- Move selection up.
		do
			if selected_index > 1 then
				selected_index := selected_index - 1
				ensure_visible (selected_index)
				notify_select
			end
		end

	select_next
			-- Move selection down.
		do
			if selected_index < items.count then
				selected_index := selected_index + 1
				ensure_visible (selected_index)
				notify_select
			end
		end

	select_first
			-- Select first item.
		do
			if not items.is_empty then
				selected_index := 1
				scroll_offset := 0
				notify_select
			end
		end

	select_last
			-- Select last item.
		do
			if not items.is_empty then
				selected_index := items.count
				ensure_visible (selected_index)
				notify_select
			end
		end

	page_up
			-- Move selection up by page.
		local
			l_new_index: INTEGER
		do
			l_new_index := (selected_index - height).max (1)
			if l_new_index /= selected_index then
				selected_index := l_new_index
				ensure_visible (selected_index)
				notify_select
			end
		end

	page_down
			-- Move selection down by page.
		local
			l_new_index: INTEGER
		do
			l_new_index := (selected_index + height).min (items.count)
			if l_new_index /= selected_index then
				selected_index := l_new_index
				ensure_visible (selected_index)
				notify_select
			end
		end

feature -- Rendering

	render (a_buffer: TUI_BUFFER)
			-- Render list to buffer.
		local
			ax, ay: INTEGER
			i, draw_y: INTEGER
			l_item_text: STRING_32
			l_item_style: TUI_STYLE
			l_display_width: INTEGER
			l_needs_scrollbar: BOOLEAN
		do
			ax := absolute_x
			ay := absolute_y

			l_needs_scrollbar := show_scrollbar and items.count > height
			if l_needs_scrollbar then
				l_display_width := width - 1  -- Reserve space for scrollbar
			else
				l_display_width := width
			end

			-- Draw visible items
			from
				i := scroll_offset + 1
				draw_y := 0
			until
				draw_y >= height or i > items.count
			loop
				l_item_text := items.i_th (i)

				-- Choose style
				if is_selected (i) then
					l_item_style := selected_style
					if is_focused then
						l_item_style := l_item_style.merged (focused_style)
					end
				else
					l_item_style := normal_style
				end

				-- Prepare display text
				l_item_text := padded_text (l_item_text, l_display_width)

				a_buffer.put_string (ax, ay + draw_y, l_item_text, l_item_style)

				draw_y := draw_y + 1
				i := i + 1
			end

			-- Fill remaining space
			from until draw_y >= height loop
				a_buffer.put_string (ax, ay + draw_y, spaces (l_display_width), normal_style)
				draw_y := draw_y + 1
			end

			-- Draw scrollbar
			if l_needs_scrollbar then
				render_scrollbar (a_buffer, ax + width - 1, ay)
			end
		end

feature -- Event Handling

	handle_key (a_event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_focused and not items.is_empty then
				if a_event.is_up then
					select_previous
					Result := True
				elseif a_event.is_down then
					select_next
					Result := True
				elseif a_event.is_home then
					select_first
					Result := True
				elseif a_event.is_end_key then
					select_last
					Result := True
				elseif a_event.is_page_up then
					page_up
					Result := True
				elseif a_event.is_page_down then
					page_down
					Result := True
				elseif a_event.is_enter or a_event.is_space then
					if is_multi_select and a_event.is_space then
						toggle_selection (selected_index)
					end
					activate_current
					Result := True
				end
			end
		end

	handle_mouse (a_event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			l_my: INTEGER
			l_clicked_index: INTEGER
		do
			if contains_point (a_event.mouse_x, a_event.mouse_y) then
				if a_event.is_mouse_press and a_event.mouse_button = 1 then
					-- Calculate clicked item
					l_my := a_event.mouse_y - absolute_y
					l_clicked_index := scroll_offset + l_my + 1

					if l_clicked_index >= 1 and l_clicked_index <= items.count then
						if is_multi_select then
							toggle_selection (l_clicked_index)
						end
						set_selected_index (l_clicked_index)
						Result := True
					end
				elseif a_event.is_mouse_scroll then
					-- Scroll with mouse wheel
					if a_event.mouse_scroll_delta < 0 then
						scroll_up (3)
					else
						scroll_down (3)
					end
					Result := True
				end
			end
		end

feature {NONE} -- Implementation

	ensure_visible (a_index: INTEGER)
			-- Scroll to ensure item at index is visible.
		do
			if a_index > 0 then
				if a_index <= scroll_offset then
					scroll_offset := a_index - 1
				elseif a_index > scroll_offset + height then
					scroll_offset := a_index - height
				end
				scroll_offset := scroll_offset.max (0).min ((items.count - height).max (0))
			end
		end

	scroll_up (a_lines: INTEGER)
			-- Scroll up by lines.
		do
			scroll_offset := (scroll_offset - a_lines).max (0)
		end

	scroll_down (a_lines: INTEGER)
			-- Scroll down by lines.
		do
			scroll_offset := (scroll_offset + a_lines).min ((items.count - height).max (0))
		end

	notify_select
			-- Notify selection handlers.
		do
			select_actions.call ([selected_index])
		end

	activate_current
			-- Activate currently selected item.
		do
			if selected_index > 0 then
				activate_actions.call ([selected_index])
			end
		end

	padded_text (a_text: STRING_32; target_width: INTEGER): STRING_32
			-- Pad or truncate text to target width.
		do
			if a_text.count >= target_width then
				Result := a_text.substring (1, target_width)
			else
				create Result.make (target_width)
				Result.append (a_text)
				from until Result.count >= target_width loop
					Result.append_character (' ')
				end
			end
		end

	spaces (a_n: INTEGER): STRING_32
			-- Create string of n spaces.
		do
			create Result.make_filled (' ', a_n)
		end

	render_scrollbar (a_buffer: TUI_BUFFER; sx, sy: INTEGER)
			-- Render vertical scrollbar.
		local
			i: INTEGER
			thumb_pos, thumb_size: INTEGER
			l_scrollable_range: INTEGER
			l_char: CHARACTER_32
		do
			l_scrollable_range := items.count - height
			if l_scrollable_range > 0 then
				thumb_size := (height * height // items.count).max (1)
				thumb_pos := (scroll_offset * (height - thumb_size)) // l_scrollable_range
			else
				thumb_size := height
				thumb_pos := 0
			end

			from i := 0 until i >= height loop
				if i >= thumb_pos and i < thumb_pos + thumb_size then
					l_char := '%/0x2588/'  -- Full block
				else
					l_char := '%/0x2591/'  -- Light shade
				end
				a_buffer.put_char (sx, sy + i, l_char, normal_style)
				i := i + 1
			end
		end

invariant
	items_exist: items /= Void
	selected_indices_exist: selected_indices /= Void
	select_actions_exists: select_actions /= Void
	activate_actions_exists: activate_actions /= Void
	valid_selection: selected_index >= 0 and selected_index <= count
	valid_scroll: scroll_offset >= 0
	normal_style_exists: normal_style /= Void
	selected_style_exists: selected_style /= Void
	focused_style_exists: focused_style /= Void

end
