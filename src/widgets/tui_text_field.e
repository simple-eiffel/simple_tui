note
	description: "[
		TUI_TEXT_FIELD - Single-line text input widget

		Features:
		- Cursor movement and editing
		- Text scrolling for long content
		- Optional placeholder text
		- Password masking mode
		- Change callbacks
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_TEXT_FIELD

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
			-- Create text field with width.
		require
			valid_width: a_width > 0
		do
			make_widget
			width := a_width
			height := 1
			is_focusable := True
			create text.make_empty
			cursor_position := 0
			scroll_offset := 0
			placeholder := ""
			is_password := False
			max_length := 0  -- No limit
			create normal_style.make_default
			create focused_style.make_default
			focused_style.set_reverse (True)
		ensure
			width_set: width = a_width
			focusable: is_focusable
		end

feature -- Access

	text: STRING_32
			-- Current text content.

	cursor_position: INTEGER
			-- Cursor position (0 = before first char).

	scroll_offset: INTEGER
			-- Horizontal scroll offset.

	placeholder: STRING_32
			-- Placeholder text shown when empty.

	is_password: BOOLEAN
			-- Mask input with bullets?

	max_length: INTEGER
			-- Maximum text length (0 = unlimited).

	on_change: detachable PROCEDURE [STRING_32]
			-- Called when text changes.

	on_submit: detachable PROCEDURE [STRING_32]
			-- Called when Enter is pressed.

feature -- Styles

	normal_style: TUI_STYLE
			-- Style for normal state.

	focused_style: TUI_STYLE
			-- Style for focused state.

feature -- Modification

	set_text (a_t: READABLE_STRING_GENERAL)
			-- Set text content.
		require
			t_exists: a_t /= Void
		do
			text := a_t.to_string_32
			if max_length > 0 and text.count > max_length then
				text := text.substring (1, max_length)
			end
			cursor_position := text.count
			adjust_scroll
		ensure
			text_set: text.same_string_general (a_t) or (max_length > 0 and text.count = max_length)
		end

	set_placeholder (a_p: READABLE_STRING_GENERAL)
			-- Set placeholder text.
		require
			p_exists: a_p /= Void
		do
			placeholder := a_p.to_string_32
		ensure
			placeholder_set: placeholder.same_string_general (a_p)
		end

	set_password (a_v: BOOLEAN)
			-- Set password mode.
		do
			is_password := a_v
		ensure
			password_set: is_password = a_v
		end

	set_max_length (a_n: INTEGER)
			-- Set maximum length (0 = unlimited).
		require
			valid: a_n >= 0
		do
			max_length := a_n
			if max_length > 0 and text.count > max_length then
				text := text.substring (1, max_length)
				cursor_position := cursor_position.min (text.count)
			end
		ensure
			max_length_set: max_length = a_n
		end

	set_on_change (a_handler: PROCEDURE [STRING_32])
			-- Set change handler.
		do
			on_change := a_handler
		ensure
			handler_set: on_change = a_handler
		end

	set_on_submit (a_handler: PROCEDURE [STRING_32])
			-- Set submit handler.
		do
			on_submit := a_handler
		ensure
			handler_set: on_submit = a_handler
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

	set_focused_style (a_s: TUI_STYLE)
			-- Set focused style.
		require
			s_exists: a_s /= Void
		do
			focused_style := a_s
		ensure
			style_set: focused_style = a_s
		end

feature -- Editing

	insert_char (a_c: CHARACTER_32)
			-- Insert character at cursor.
		do
			if max_length = 0 or text.count < max_length then
				text.insert_character (a_c, cursor_position + 1)
				cursor_position := cursor_position + 1
				adjust_scroll
				notify_change
			end
		end

	delete_char
			-- Delete character after cursor.
		do
			if cursor_position < text.count then
				text.remove (cursor_position + 1)
				notify_change
			end
		end

	backspace
			-- Delete character before cursor.
		do
			if cursor_position > 0 then
				text.remove (cursor_position)
				cursor_position := cursor_position - 1
				adjust_scroll
				notify_change
			end
		end

	clear
			-- Clear all text.
		do
			text.wipe_out
			cursor_position := 0
			scroll_offset := 0
			notify_change
		ensure
			empty: text.is_empty
			cursor_at_start: cursor_position = 0
		end

feature -- Cursor movement

	move_left
			-- Move cursor left.
		do
			if cursor_position > 0 then
				cursor_position := cursor_position - 1
				adjust_scroll
			end
		end

	move_right
			-- Move cursor right.
		do
			if cursor_position < text.count then
				cursor_position := cursor_position + 1
				adjust_scroll
			end
		end

	move_home
			-- Move cursor to start.
		do
			cursor_position := 0
			adjust_scroll
		ensure
			at_start: cursor_position = 0
		end

	move_end
			-- Move cursor to end.
		do
			cursor_position := text.count
			adjust_scroll
		ensure
			at_end: cursor_position = text.count
		end

feature -- Rendering

	render (a_buffer: TUI_BUFFER)
			-- Render text field to buffer.
		local
			ax, ay: INTEGER
			l_current_style: TUI_STYLE
			l_display: STRING_32
			l_visible_width: INTEGER
			i: INTEGER
			l_char: CHARACTER_32
		do
			ax := absolute_x
			ay := absolute_y

			-- Choose style
			if is_focused then
				l_current_style := focused_style
			else
				l_current_style := normal_style
			end

			l_visible_width := width
			create l_display.make (l_visible_width)

			if text.is_empty and not placeholder.is_empty and not is_focused then
				-- Show placeholder
				l_display.append (placeholder)
			else
				-- Show text (or masked)
				from i := scroll_offset + 1 until i > text.count or l_display.count >= l_visible_width loop
					if is_password then
						l_char := '%/0x25CF/'  -- Black circle (bullet)
					else
						l_char := text.item (i)
					end
					l_display.append_character (l_char)
					i := i + 1
				end
			end

			-- Pad with spaces to fill width
			from until l_display.count >= l_visible_width loop
				l_display.append_character (' ')
			end

			-- Truncate if needed
			if l_display.count > l_visible_width then
				l_display := l_display.substring (1, l_visible_width)
			end

			a_buffer.put_string (ax, ay, l_display, l_current_style)

			-- Draw cursor (if focused)
			if is_focused then
				-- Cursor position relative to visible area
				i := cursor_position - scroll_offset
				if i >= 0 and i < l_visible_width then
					-- Use underline or block cursor
					if i < l_display.count then
						l_char := l_display.item (i + 1)
					else
						l_char := ' '
					end
					-- Draw inverted cursor
					a_buffer.put_char (ax + i, ay, l_char, l_current_style.inverted)
				end
			end
		end

feature -- Event Handling

	handle_key (a_event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_focused then
				-- Check special keys first (works for both key and char events)
				if a_event.is_tab then
					-- Let parent handle tab navigation
					Result := False
				elseif a_event.is_backspace then
					backspace
					Result := True
				elseif a_event.is_enter then
					if attached on_submit as al_handler then
						al_handler.call ([text])
					end
					Result := True
				elseif a_event.is_left then
					move_left
					Result := True
				elseif a_event.is_right then
					move_right
					Result := True
				elseif a_event.is_home then
					move_home
					Result := True
				elseif a_event.is_end_key then
					move_end
					Result := True
				elseif a_event.is_delete then
					delete_char
					Result := True
				elseif a_event.is_char_event and a_event.char.natural_32_code >= 32 then
					-- Regular printable character input (code >= 32)
					insert_char (a_event.char)
					Result := True
				else
					Result := False
				end
			end
		end

	handle_mouse (a_event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			l_mx: INTEGER
			l_click_pos: INTEGER
		do
			if a_event.is_mouse_press and a_event.mouse_button = 1 then
				if contains_point (a_event.mouse_x, a_event.mouse_y) then
					-- Calculate cursor position from click
					l_mx := a_event.mouse_x - absolute_x
					l_click_pos := scroll_offset + l_mx
					cursor_position := l_click_pos.min (text.count).max (0)
					Result := True
				end
			end
		end

feature -- Queries

	preferred_width: INTEGER
			-- Preferred width.
		do
			Result := width
		end

	preferred_height: INTEGER
			-- Preferred height (always 1).
		do
			Result := 1
		end

feature {NONE} -- Implementation

	adjust_scroll
			-- Adjust scroll offset to keep cursor visible.
		local
			l_visible_width: INTEGER
		do
			l_visible_width := width - 1  -- Leave room for cursor at end

			if cursor_position < scroll_offset then
				scroll_offset := cursor_position
			elseif cursor_position > scroll_offset + l_visible_width then
				scroll_offset := cursor_position - l_visible_width
			end

			scroll_offset := scroll_offset.max (0)
		end

	notify_change
			-- Notify change handler.
		do
			if attached on_change as al_handler then
				al_handler.call ([text])
			end
		end

invariant
	text_exists: text /= Void
	placeholder_exists: placeholder /= Void
	valid_cursor: cursor_position >= 0 and cursor_position <= text.count
	valid_scroll: scroll_offset >= 0
	normal_style_exists: normal_style /= Void
	focused_style_exists: focused_style /= Void

end
