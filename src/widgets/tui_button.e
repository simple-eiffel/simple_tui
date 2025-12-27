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
		require
			label_exists: a_label /= Void
		do
			make_widget
			label := a_label.to_string_32
			width := label.count + 4  -- [ Label ]
			height := 1
			is_focusable := True
			is_enabled := True
			is_pressed := False
			create click_actions
			create normal_style.make_default
			create focused_style.make_default
			create pressed_style.make_default
			create disabled_style.make_default
			-- Default styles - make focus very visible with reverse video
			focused_style.set_reverse (True)
			pressed_style.set_reverse (True)
			pressed_style.set_bold (True)
			disabled_style.set_dim (True)
		ensure
			label_set: label.same_string_general (a_label)
			focusable: is_focusable
			enabled: is_enabled
		end

feature -- Access

	label: STRING_32
			-- Button label text.

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

feature -- Modification

	set_label (a_label: READABLE_STRING_GENERAL)
			-- Set button label.
		require
			label_exists: a_label /= Void
		do
			label := a_label.to_string_32
			width := label.count + 4
		ensure
			label_set: label.same_string_general (a_label)
		end

	set_enabled (v: BOOLEAN)
			-- Set enabled state.
		do
			is_enabled := v
			if not v then
				is_pressed := False
			end
		ensure
			enabled_set: is_enabled = v
		end

	set_on_click (action: PROCEDURE)
			-- Set click handler (clears previous handlers).
			-- For multiple handlers, use click_actions.extend directly.
		do
			click_actions.wipe_out
			click_actions.extend (action)
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

	set_pressed_style (s: TUI_STYLE)
			-- Set pressed style.
		require
			s_exists: s /= Void
		do
			pressed_style := s
		ensure
			style_set: pressed_style = s
		end

	set_disabled_style (s: TUI_STYLE)
			-- Set disabled style.
		require
			s_exists: s /= Void
		do
			disabled_style := s
		ensure
			style_set: disabled_style = s
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

	render (buffer: TUI_BUFFER)
			-- Render button to buffer.
		local
			ax, ay: INTEGER
			current_style: TUI_STYLE
			display: STRING_32
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

			-- Build display string: [ Label ]
			create display.make (width)
			display.append_character ('[')
			display.append_character (' ')
			display.append (label)
			display.append_character (' ')
			display.append_character (']')

			-- Truncate if needed
			if display.count > width then
				display := display.substring (1, width)
			end

			buffer.put_string (ax, ay, display, current_style)
		end

feature -- Event Handling

	handle_key (event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_enabled and is_focused then
				if event.is_enter or event.is_space then
					-- Activate button
					click
					Result := True
				end
			end
		end

	handle_mouse (event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			mx, my: INTEGER
		do
			if is_enabled then
				mx := event.mouse_x
				my := event.mouse_y

				if contains_point (mx, my) then
					if event.mouse_button = 1 then
						if event.is_mouse_press then
							is_pressed := True
							Result := True
						elseif event.is_mouse_release then
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
			-- Preferred width based on label.
		do
			Result := label.count + 4
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

end
