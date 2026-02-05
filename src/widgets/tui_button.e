note
	description: "[
		TUI_BUTTON - Interactive button widget

		Features:
		- Click handling (mouse and keyboard)
		- Visual states (normal, focused, pressed, disabled)
		- Configurable label
		- Multiple action handlers via ACTION_SEQUENCE (EV compatible)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_BUTTON

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

	make (a_label: READABLE_STRING_GENERAL)
			-- Create button with label.
			-- Use & before character for keyboard shortcut.
		require
			label_exists: a_label /= Void
		do
			make_widget
			shortcut_key := '%U'
			shortcut_position := 0
			set_label (a_label)
			height := 1
			is_focusable := True
			is_enabled := True
			is_pressed := False
			create click_actions
			create normal_style.make_default
			create focused_style.make_default
			create pressed_style.make_default
			create disabled_style.make_default
			create hotkey_style.make_default
			-- Default styles - make focus very visible with reverse video
			focused_style.set_reverse (True)
			pressed_style.set_reverse (True)
			pressed_style.set_bold (True)
			disabled_style.set_dim (True)
			hotkey_style.set_underline (True)
		ensure
			label_set: label.same_string_general (a_label)
			focusable: is_focusable
			enabled: is_enabled
		end

feature -- Access

	label: STRING_32
			-- Button label text (may contain & for shortcut).

	display_label: STRING_32
			-- Label for display (& removed).
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (label.count)
			from i := 1 until i > label.count loop
				c := label.item (i)
				if c = '&' and i < label.count then
					-- Skip the & but include next char
					i := i + 1
					Result.append_character (label.item (i))
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

	shortcut_key: CHARACTER_32
			-- Keyboard shortcut character (from & marker).

	shortcut_position: INTEGER
			-- Position of shortcut character in display_label (0 if none).

	is_enabled: BOOLEAN
			-- Is button enabled (can be clicked)?

	is_pressed: BOOLEAN
			-- Is button currently pressed?

feature -- Actions (EV compatible)

	click_actions: ACTION_SEQUENCE [TUPLE]
			-- Actions to execute when button is clicked.
			-- Use `extend' to add handlers, `prune' to remove.
			-- EV equivalent: select_actions

	select_actions: ACTION_SEQUENCE [TUPLE]
			-- Alias for click_actions (EV compatibility).
		do
			Result := click_actions
		end

feature -- Styles

	normal_style: TUI_STYLE
			-- Style for normal state.

	focused_style: TUI_STYLE
			-- Style for focused state.

	pressed_style: TUI_STYLE
			-- Style for pressed state.

	disabled_style: TUI_STYLE
			-- Style for disabled state.

	hotkey_style: TUI_STYLE
			-- Style for hotkey character (underlined).

feature -- Modification

	set_label (a_label: READABLE_STRING_GENERAL)
			-- Set button label. Use & before character for shortcut.
		require
			label_exists: a_label /= Void
		local
			i: INTEGER
			c: CHARACTER_32
			l_found_shortcut: BOOLEAN
			l_display_pos: INTEGER
		do
			label := a_label.to_string_32
			-- Find shortcut key
			shortcut_key := '%U'
			shortcut_position := 0
			display_pos := 0
			from i := 1 until i > label.count or found_shortcut loop
				c := label.item (i)
				if c = '&' and i < label.count then
					shortcut_key := label.item (i + 1).as_lower
					shortcut_position := display_pos + 1
					found_shortcut := True
				else
					display_pos := display_pos + 1
				end
				i := i + 1
			end
			-- Width based on display_label (without &)
			width := display_label.count + 4
		ensure
			label_set: label.same_string_general (a_label)
		end

	set_enabled (a_v: BOOLEAN)
			-- Set enabled state.
		do
			is_enabled := a_v
			if not a_v then
				is_pressed := False
			end
		ensure
			enabled_set: is_enabled = a_v
		end

	set_on_click (a_action: PROCEDURE)
			-- Set click handler (clears previous handlers).
			-- For multiple handlers, use click_actions.extend directly.
		do
			click_actions.wipe_out
			click_actions.extend (a_action)
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

	set_pressed_style (a_s: TUI_STYLE)
			-- Set pressed style.
		require
			s_exists: a_s /= Void
		do
			pressed_style := a_s
		ensure
			style_set: pressed_style = a_s
		end

	set_disabled_style (a_s: TUI_STYLE)
			-- Set disabled style.
		require
			s_exists: a_s /= Void
		do
			disabled_style := a_s
		ensure
			style_set: disabled_style = a_s
		end

	set_hotkey_style (a_s: TUI_STYLE)
			-- Set hotkey style.
		require
			s_exists: a_s /= Void
		do
			hotkey_style := a_s
		ensure
			style_set: hotkey_style = a_s
		end

feature -- Actions

	click
			-- Programmatically click the button.
		do
			if is_enabled then
				click_actions.call (Void)
			end
		end

feature -- Rendering

	render (a_buffer: TUI_BUFFER)
			-- Render button to buffer with hotkey underlining.
		local
			ax, ay, i, pos_x: INTEGER
			current_style, hotkey_merged: TUI_STYLE
			c: CHARACTER_32
			l_disp: STRING_32
		do
			ax := absolute_x
			ay := absolute_y

			-- Choose style based on state
			if not is_enabled then
				current_style := disabled_style
			elseif is_pressed then
				current_style := pressed_style
			elseif is_focused then
				current_style := focused_style
			else
				current_style := normal_style
			end

			-- Draw opening bracket and space
			a_buffer.put_char (ax, ay, '[', current_style)
			a_buffer.put_char (ax + 1, ay, ' ', current_style)

			-- Draw label with hotkey underlining
			disp := display_label
			pos_x := ax + 2
			from i := 1 until i > disp.count loop
				c := disp.item (i)
				if i = shortcut_position then
					-- This is the hotkey character - underline it
					hotkey_merged := current_style.twin_style
					hotkey_merged.set_underline (True)
					a_buffer.put_char (pos_x, ay, c, hotkey_merged)
				else
					a_buffer.put_char (pos_x, ay, c, current_style)
				end
				pos_x := pos_x + 1
				i := i + 1
			end

			-- Draw closing space and bracket
			a_buffer.put_char (pos_x, ay, ' ', current_style)
			a_buffer.put_char (pos_x + 1, ay, ']', current_style)
		end

feature -- Event Handling

	handle_key (a_event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_enabled and is_focused then
				if a_event.is_enter or a_event.is_space then
					-- Activate button
					click
					Result := True
				end
			end
		end

	handle_mouse (a_event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			mx, my: INTEGER
		do
			if is_enabled then
				mx := a_event.mouse_x
				my := a_event.mouse_y

				if contains_point (mx, my) then
					if a_event.mouse_button = 1 then
						if a_event.is_mouse_press then
							is_pressed := True
							Result := True
						elseif a_event.is_mouse_release then
							if is_pressed then
								is_pressed := False
								click
							end
							Result := True
						end
					end
				else
					-- Mouse released outside
					is_pressed := False
				end
			end
		end

feature -- Queries

	preferred_width: INTEGER
			-- Preferred width based on display label.
		do
			Result := display_label.count + 4
		end

	preferred_height: INTEGER
			-- Preferred height (always 1).
		do
			Result := 1
		end

invariant
	label_exists: label /= Void
	click_actions_exists: click_actions /= Void
	normal_style_exists: normal_style /= Void
	focused_style_exists: focused_style /= Void
	pressed_style_exists: pressed_style /= Void
	disabled_style_exists: disabled_style /= Void
	hotkey_style_exists: hotkey_style /= Void

end
