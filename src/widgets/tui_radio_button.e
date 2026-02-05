note
	description: "[
		TUI_RADIO_BUTTON - Mutually exclusive selection button

		Part of a radio group where only one can be selected at a time.

		EV equivalent: EV_RADIO_BUTTON
		Other frameworks: Radio, RadioButton, OptionButton

		Features:
		- Mutually exclusive selection within group
		- Keyboard and mouse activation
		- Custom select characters
		- Change callback
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_RADIO_BUTTON

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
			-- Create radio button with label.
		require
			label_exists: a_label /= Void
		do
			make_widget
			label := a_label.to_string_32
			width := label.count + 4  -- ( ) Label
			height := 1
			is_focusable := True
			is_selected := False
			selected_char := '%/0x25CF/'    -- Black circle (filled)
			unselected_char := '%/0x25CB/'  -- White circle (empty)
			create normal_style.make_default
			create focused_style.make_default
			focused_style.set_reverse (True)
		ensure
			label_set: label.same_string_general (a_label)
			focusable: is_focusable
			not_selected: not is_selected
		end

feature -- Access

	label: STRING_32
			-- Radio button label text.
			-- Aliases: text, caption

	text: STRING_32
			-- Alias for label (web/modern frameworks).
		do
			Result := label
		end

	is_selected: BOOLEAN
			-- Is this radio button selected?
			-- Aliases: is_checked, is_active, value

	is_checked: BOOLEAN
			-- Alias for is_selected (web frameworks).
		do
			Result := is_selected
		end

	group: detachable TUI_RADIO_GROUP
			-- Radio group this button belongs to.

	selected_char: CHARACTER_32
			-- Character for selected state.

	unselected_char: CHARACTER_32
			-- Character for unselected state.

	on_select: detachable PROCEDURE
			-- Called when this button becomes selected.
			-- Aliases: on_change, on_click

	on_change: detachable PROCEDURE
			-- Alias for on_select.
		do
			Result := on_select
		end

feature -- Styles

	normal_style: TUI_STYLE
			-- Style for normal state.

	focused_style: TUI_STYLE
			-- Style for focused state.

feature -- Modification

	set_label, set_text (a_label: READABLE_STRING_GENERAL)
			-- Set radio button label.
		require
			label_exists: a_label /= Void
		do
			label := a_label.to_string_32
			width := label.count + 4
		ensure
			label_set: label.same_string_general (a_label)
		end

	select_button, check_button
			-- Select this radio button.
			-- Will deselect others in the group.
		do
			if not is_selected then
				if attached group as al_g then
					al_g.select_button (Current)
				else
					is_selected := True
					notify_select
				end
			end
		ensure
			selected: is_selected
		end

	deselect, uncheck
			-- Deselect this radio button (called by group).
		do
			is_selected := False
		ensure
			not_selected: not is_selected
		end

	set_group (a_g: detachable TUI_RADIO_GROUP)
			-- Set the radio group.
		do
			group := a_g
		ensure
			group_set: group = a_g
		end

	set_selected_char (a_c: CHARACTER_32)
			-- Set selected character.
		do
			selected_char := a_c
		ensure
			char_set: selected_char = a_c
		end

	set_unselected_char (a_c: CHARACTER_32)
			-- Set unselected character.
		do
			unselected_char := a_c
		ensure
			char_set: unselected_char = a_c
		end

	set_on_select, set_on_change (a_handler: PROCEDURE)
			-- Set selection handler.
		do
			on_select := a_handler
		ensure
			handler_set: on_select = a_handler
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

feature -- Rendering

	render (a_buffer: TUI_BUFFER)
			-- Render radio button to buffer.
		local
			ax, ay: INTEGER
			l_current_style: TUI_STYLE
			l_display: STRING_32
			l_radio_char: CHARACTER_32
		do
			ax := absolute_x
			ay := absolute_y

			-- Choose style
			if is_focused then
				current_style := focused_style
			else
				current_style := normal_style
			end

			-- Determine radio character
			if is_selected then
				radio_char := selected_char
			else
				radio_char := unselected_char
			end

			-- Build display string: (o) Label
			create display.make (width)
			display.append_character ('(')
			display.append_character (radio_char)
			display.append_character (')')
			display.append_character (' ')
			display.append (label)

			-- Truncate if needed
			if display.count > width then
				display := display.substring (1, width)
			end

			a_buffer.put_string (ax, ay, display, current_style)
		end

feature -- Event Handling

	handle_key (a_event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_focused then
				if a_event.is_enter or a_event.is_space then
					select_button
					Result := True
				end
			end
		end

	handle_mouse (a_event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		do
			if a_event.is_mouse_press and a_event.mouse_button = 1 then
				if contains_point (a_event.mouse_x, a_event.mouse_y) then
					select_button
					Result := True
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

feature {TUI_RADIO_GROUP} -- Group access

	internal_select
			-- Select without notifying group (called by group).
		do
			is_selected := True
			notify_select
		end

feature {NONE} -- Implementation

	notify_select
			-- Notify selection handler.
		do
			if attached on_select as al_handler then
				al_handler.call (Void)
			end
		end

invariant
	label_exists: label /= Void
	normal_style_exists: normal_style /= Void
	focused_style_exists: focused_style /= Void

end
