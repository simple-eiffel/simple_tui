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

	set_text (t: READABLE_STRING_GENERAL)
			-- Set text content.
		require
			t_exists: t /= Void
		do
			text := t.to_string_32
			if max_length > 0 and text.count > max_length then
				text := text.substring (1, max_length)
			end
			cursor_position := text.count
			adjust_scroll
		ensure
			text_set: text.same_string_general (t) or (max_length > 0 and text.count = max_length)
		end

	set_placeholder (p: READABLE_STRING_GENERAL)
			-- Set placeholder text.
		require
			p_exists: p /= Void
		do
			placeholder := p.to_string_32
		ensure
			placeholder_set: placeholder.same_string_general (p)
		end

	set_password (v: BOOLEAN)
			-- Set password mode.
		do
			is_password := v
		ensure
			password_set: is_password = v
		end

	set_max_length (n: INTEGER)
			-- Set maximum length (0 = unlimited).
		require
			valid: n >= 0
		do
			max_length := n
			if max_length > 0 and text.count > max_length then
				text := text.substring (1, max_length)
				cursor_position := cursor_position.min (text.count)
			end
		ensure
			max_length_set: max_length = n
		end

	set_on_change (handler: PROCEDURE [STRING_32])
			-- Set change handler.
		do
			on_change := handler
		ensure
			handler_set: on_change = handler
		end

	set_on_submit (handler: PROCEDURE [STRING_32])
			-- Set submit handler.
		do
			on_submit := handler
		ensure
			handler_set: on_submit = handler
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

feature -- Editing

	insert_char (c: CHARACTER_32)
			-- Insert character at cursor.
		do
			if max_length = 0 or text.count < max_length then
				text.insert_character (c, cursor_position + 1)
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

	render (buffer: TUI_BUFFER)
			-- Render text field to buffer.
		local
			ax, ay: INTEGER
			current_style: TUI_STYLE
			display: STRING_32
			visible_width: INTEGER
			i: INTEGER
			char: CHARACTER_32
		do
			ax := absolute_x
			ay := absolute_y

			-- Choose style
			if is_focused then
				current_style := focused_style
			else
				current_style := normal_style
			end

			visible_width := width
			create display.make (visible_width)

			if text.is_empty and not placeholder.is_empty and not is_focused then
				-- Show placeholder
				display.append (placeholder)
			else
				-- Show text (or masked)
				from i := scroll_offset + 1 until i > text.count or display.count >= visible_width loop
					if is_password then
						char := '%/0x25CF/'  -- Black circle (bullet)
					else
						char := text.item (i)
					end
					display.append_character (char)
					i := i + 1
				end
			end

			-- Pad with spaces to fill width
			from until display.count >= visible_width loop
				display.append_character (' ')
			end

			-- Truncate if needed
			if display.count > visible_width then
				display := display.substring (1, visible_width)
			end

			buffer.put_string (ax, ay, display, current_style)

			-- Draw cursor (if focused)
			if is_focused then
				-- Cursor position relative to visible area
				i := cursor_position - scroll_offset
				if i >= 0 and i < visible_width then
					-- Use underline or block cursor
					if i < display.count then
						char := display.item (i + 1)
					else
						char := ' '
					end
					-- Draw inverted cursor
					buffer.put_char (ax + i, ay, char, current_style.inverted)
				end
			end
		end

feature -- Event Handling

	handle_key (event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_focused then
				-- Check special keys first (works for both key and char events)
				if event.is_tab then
					-- Let parent handle tab navigation
					Result := False
				elseif event.is_backspace then
					backspace
					Result := True
				elseif event.is_enter then
					if attached on_submit as handler then
						handler.call ([text])
					end
					Result := True
				elseif event.is_left then
					move_left
					Result := True
				elseif event.is_right then
					move_right
					Result := True
				elseif event.is_home then
					move_home
					Result := True
				elseif event.is_end_key then
					move_end
					Result := True
				elseif event.is_delete then
					delete_char
					Result := True
				elseif event.is_char_event and event.char.natural_32_code >= 32 then
					-- Regular printable character input (code >= 32)
					insert_char (event.char)
					Result := True
				else
					Result := False
				end
			end
		end

	handle_mouse (event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			mx: INTEGER
			click_pos: INTEGER
		do
			if event.is_mouse_press and event.mouse_button = 1 then
				if contains_point (event.mouse_x, event.mouse_y) then
					-- Calculate cursor position from click
					mx := event.mouse_x - absolute_x
					click_pos := scroll_offset + mx
					cursor_position := click_pos.min (text.count).max (0)
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
			visible_width: INTEGER
		do
			visible_width := width - 1  -- Leave room for cursor at end

			if cursor_position < scroll_offset then
				scroll_offset := cursor_position
			elseif cursor_position > scroll_offset + visible_width then
				scroll_offset := cursor_position - visible_width
			end

			scroll_offset := scroll_offset.max (0)
		end

	notify_change
			-- Notify change handler.
		do
			if attached on_change as handler then
				handler.call ([text])
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
