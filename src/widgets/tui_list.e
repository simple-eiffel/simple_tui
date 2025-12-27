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

	on_select: detachable PROCEDURE [INTEGER]
			-- Called when selection changes.

	on_activate: detachable PROCEDURE [INTEGER]
			-- Called when item is activated (Enter/double-click).

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

	is_selected (index: INTEGER): BOOLEAN
			-- Is item at index selected (in multi-select mode)?
		require
			valid_index: index >= 1 and index <= count
		do
			if is_multi_select then
				Result := selected_indices.has (index)
			else
				Result := selected_index = index
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

	add_item (item: READABLE_STRING_GENERAL)
			-- Add item to list.
		require
			item_exists: item /= Void
		do
			items.extend (item.to_string_32)
			if selected_index = 0 and not items.is_empty then
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
			valid_index: index >= 1 and index <= count
		local
			i: INTEGER
		do
			items.go_i_th (index)
			items.remove
			-- Adjust selection
			if selected_index > items.count then
				selected_index := items.count
			end
			selected_indices.prune_all (index)
			-- Adjust indices in multi-select
			from i := 1 until i > selected_indices.count loop
				if selected_indices.i_th (i) > index then
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

	set_selected_index (index: INTEGER)
			-- Set selected index.
		require
			valid_index: index >= 0 and index <= count
		do
			selected_index := index
			ensure_visible (index)
			notify_select
		ensure
			selected: selected_index = index
		end

	toggle_selection (index: INTEGER)
			-- Toggle selection of item (multi-select mode).
		require
			valid_index: index >= 1 and index <= count
			multi_select: is_multi_select
		do
			if selected_indices.has (index) then
				selected_indices.prune_all (index)
			else
				selected_indices.extend (index)
			end
		end

	clear_selection
			-- Clear all selections.
		do
			selected_indices.wipe_out
		ensure
			no_selections: selected_indices.is_empty
		end

	set_multi_select (v: BOOLEAN)
			-- Set multi-select mode.
		do
			is_multi_select := v
			if not v then
				selected_indices.wipe_out
			end
		ensure
			multi_select_set: is_multi_select = v
		end

	set_show_scrollbar (v: BOOLEAN)
			-- Set scrollbar visibility.
		do
			show_scrollbar := v
		ensure
			show_scrollbar_set: show_scrollbar = v
		end

	set_on_select (handler: PROCEDURE [INTEGER])
			-- Set selection change handler.
		do
			on_select := handler
		ensure
			handler_set: on_select = handler
		end

	set_on_activate (handler: PROCEDURE [INTEGER])
			-- Set activation handler.
		do
			on_activate := handler
		ensure
			handler_set: on_activate = handler
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
			new_index: INTEGER
		do
			new_index := (selected_index - height).max (1)
			if new_index /= selected_index then
				selected_index := new_index
				ensure_visible (selected_index)
				notify_select
			end
		end

	page_down
			-- Move selection down by page.
		local
			new_index: INTEGER
		do
			new_index := (selected_index + height).min (items.count)
			if new_index /= selected_index then
				selected_index := new_index
				ensure_visible (selected_index)
				notify_select
			end
		end

feature -- Rendering

	render (buffer: TUI_BUFFER)
			-- Render list to buffer.
		local
			ax, ay: INTEGER
			i, draw_y: INTEGER
			item_text: STRING_32
			item_style: TUI_STYLE
			display_width: INTEGER
			needs_scrollbar: BOOLEAN
		do
			ax := absolute_x
			ay := absolute_y

			needs_scrollbar := show_scrollbar and items.count > height
			if needs_scrollbar then
				display_width := width - 1  -- Reserve space for scrollbar
			else
				display_width := width
			end

			-- Draw visible items
			from
				i := scroll_offset + 1
				draw_y := 0
			until
				draw_y >= height or i > items.count
			loop
				item_text := items.i_th (i)

				-- Choose style
				if is_selected (i) then
					item_style := selected_style
					if is_focused then
						item_style := item_style.merged (focused_style)
					end
				else
					item_style := normal_style
				end

				-- Prepare display text
				item_text := padded_text (item_text, display_width)

				buffer.put_string (ax, ay + draw_y, item_text, item_style)

				draw_y := draw_y + 1
				i := i + 1
			end

			-- Fill remaining space
			from until draw_y >= height loop
				buffer.put_string (ax, ay + draw_y, spaces (display_width), normal_style)
				draw_y := draw_y + 1
			end

			-- Draw scrollbar
			if needs_scrollbar then
				render_scrollbar (buffer, ax + width - 1, ay)
			end
		end

feature -- Event Handling

	handle_key (event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_focused and not items.is_empty then
				if event.is_up then
					select_previous
					Result := True
				elseif event.is_down then
					select_next
					Result := True
				elseif event.is_home then
					select_first
					Result := True
				elseif event.is_end_key then
					select_last
					Result := True
				elseif event.is_page_up then
					page_up
					Result := True
				elseif event.is_page_down then
					page_down
					Result := True
				elseif event.is_enter or event.is_space then
					if is_multi_select and event.is_space then
						toggle_selection (selected_index)
					end
					activate_current
					Result := True
				end
			end
		end

	handle_mouse (event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			my: INTEGER
			clicked_index: INTEGER
		do
			if contains_point (event.mouse_x, event.mouse_y) then
				if event.is_mouse_press and event.mouse_button = 1 then
					-- Calculate clicked item
					my := event.mouse_y - absolute_y
					clicked_index := scroll_offset + my + 1

					if clicked_index >= 1 and clicked_index <= items.count then
						if is_multi_select then
							toggle_selection (clicked_index)
						end
						set_selected_index (clicked_index)
						Result := True
					end
				elseif event.is_mouse_scroll then
					-- Scroll with mouse wheel
					if event.mouse_scroll_delta < 0 then
						scroll_up (3)
					else
						scroll_down (3)
					end
					Result := True
				end
			end
		end

feature {NONE} -- Implementation

	ensure_visible (index: INTEGER)
			-- Scroll to ensure item at index is visible.
		do
			if index > 0 then
				if index <= scroll_offset then
					scroll_offset := index - 1
				elseif index > scroll_offset + height then
					scroll_offset := index - height
				end
				scroll_offset := scroll_offset.max (0).min ((items.count - height).max (0))
			end
		end

	scroll_up (lines: INTEGER)
			-- Scroll up by lines.
		do
			scroll_offset := (scroll_offset - lines).max (0)
		end

	scroll_down (lines: INTEGER)
			-- Scroll down by lines.
		do
			scroll_offset := (scroll_offset + lines).min ((items.count - height).max (0))
		end

	notify_select
			-- Notify selection handler.
		do
			if attached on_select as handler then
				handler.call ([selected_index])
			end
		end

	activate_current
			-- Activate currently selected item.
		do
			if selected_index > 0 and attached on_activate as handler then
				handler.call ([selected_index])
			end
		end

	padded_text (text: STRING_32; target_width: INTEGER): STRING_32
			-- Pad or truncate text to target width.
		do
			if text.count >= target_width then
				Result := text.substring (1, target_width)
			else
				create Result.make (target_width)
				Result.append (text)
				from until Result.count >= target_width loop
					Result.append_character (' ')
				end
			end
		end

	spaces (n: INTEGER): STRING_32
			-- Create string of n spaces.
		do
			create Result.make_filled (' ', n)
		end

	render_scrollbar (buffer: TUI_BUFFER; sx, sy: INTEGER)
			-- Render vertical scrollbar.
		local
			i: INTEGER
			thumb_pos, thumb_size: INTEGER
			scrollable_range: INTEGER
			char: CHARACTER_32
		do
			scrollable_range := items.count - height
			if scrollable_range > 0 then
				thumb_size := (height * height // items.count).max (1)
				thumb_pos := (scroll_offset * (height - thumb_size)) // scrollable_range
			else
				thumb_size := height
				thumb_pos := 0
			end

			from i := 0 until i >= height loop
				if i >= thumb_pos and i < thumb_pos + thumb_size then
					char := '%/0x2588/'  -- Full block
				else
					char := '%/0x2591/'  -- Light shade
				end
				buffer.put_char (sx, sy + i, char, normal_style)
				i := i + 1
			end
		end

invariant
	items_exist: items /= Void
	selected_indices_exist: selected_indices /= Void
	valid_selection: selected_index >= 0 and selected_index <= count
	valid_scroll: scroll_offset >= 0
	normal_style_exists: normal_style /= Void
	selected_style_exists: selected_style /= Void
	focused_style_exists: focused_style /= Void

end
