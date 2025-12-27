note
	description: "[
		TUI_CHECKBOX - Toggle checkbox widget

		Features:
		- Binary checked/unchecked state
		- Optional indeterminate state
		- Keyboard and mouse toggle
		- Custom check characters
		- Change callback
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_CHECKBOX

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
			-- Create checkbox with label.
		require
			label_exists: a_label /= Void
		do
			make_widget
			label := a_label.to_string_32
			width := label.count + 4  -- [x] Label
			height := 1
			is_focusable := True
			is_checked := False
			is_indeterminate := False
			checked_char := '%/0x2713/'     -- Check mark
			unchecked_char := ' '
			indeterminate_char := '-'
			create normal_style.make_default
			create focused_style.make_default
			-- Make focus very visible with reverse video
			focused_style.set_reverse (True)
		ensure
			label_set: label.same_string_general (a_label)
			focusable: is_focusable
			unchecked: not is_checked
		end

feature -- Access

	label: STRING_32
			-- Checkbox label text.

	is_checked: BOOLEAN
			-- Is checkbox checked?

	is_indeterminate: BOOLEAN
			-- Is checkbox in indeterminate state?

	checked_char: CHARACTER_32
			-- Character for checked state.

	unchecked_char: CHARACTER_32
			-- Character for unchecked state.

	indeterminate_char: CHARACTER_32
			-- Character for indeterminate state.

	on_change: detachable PROCEDURE [BOOLEAN]
			-- Called when checked state changes.

feature -- Styles

	normal_style: TUI_STYLE
			-- Style for normal state.

	focused_style: TUI_STYLE
			-- Style for focused state.

feature -- Modification

	set_label (a_label: READABLE_STRING_GENERAL)
			-- Set checkbox label.
		require
			label_exists: a_label /= Void
		do
			label := a_label.to_string_32
			width := label.count + 4
		ensure
			label_set: label.same_string_general (a_label)
		end

	set_checked (v: BOOLEAN)
			-- Set checked state.
		do
			is_checked := v
			is_indeterminate := False
		ensure
			checked_set: is_checked = v
			not_indeterminate: not is_indeterminate
		end

	set_indeterminate (v: BOOLEAN)
			-- Set indeterminate state.
		do
			is_indeterminate := v
		ensure
			indeterminate_set: is_indeterminate = v
		end

	check_box
			-- Set to checked.
		do
			set_checked (True)
			notify_change
		ensure
			checked: is_checked
		end

	uncheck
			-- Set to unchecked.
		do
			set_checked (False)
			notify_change
		ensure
			unchecked: not is_checked
		end

	toggle
			-- Toggle checked state.
		do
			is_indeterminate := False
			is_checked := not is_checked
			notify_change
		ensure
			toggled: is_checked = not old is_checked
			not_indeterminate: not is_indeterminate
		end

	set_checked_char (c: CHARACTER_32)
			-- Set checked character.
		do
			checked_char := c
		ensure
			checked_char_set: checked_char = c
		end

	set_unchecked_char (c: CHARACTER_32)
			-- Set unchecked character.
		do
			unchecked_char := c
		ensure
			unchecked_char_set: unchecked_char = c
		end

	set_on_change (handler: PROCEDURE [BOOLEAN])
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

feature -- Rendering

	render (buffer: TUI_BUFFER)
			-- Render checkbox to buffer.
		local
			ax, ay: INTEGER
			current_style: TUI_STYLE
			display: STRING_32
			check_char: CHARACTER_32
		do
			ax := absolute_x
			ay := absolute_y

			-- Choose style
			if is_focused then
				current_style := focused_style
			else
				current_style := normal_style
			end

			-- Determine check character
			if is_indeterminate then
				check_char := indeterminate_char
			elseif is_checked then
				check_char := checked_char
			else
				check_char := unchecked_char
			end

			-- Build display string: [x] Label
			create display.make (width)
			display.append_character ('[')
			display.append_character (check_char)
			display.append_character (']')
			display.append_character (' ')
			display.append (label)

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
			if is_focused then
				if event.is_enter or event.is_space then
					toggle
					Result := True
				end
			end
		end

	handle_mouse (event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		do
			if event.is_mouse_press and event.mouse_button = 1 then
				if contains_point (event.mouse_x, event.mouse_y) then
					toggle
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

feature {NONE} -- Implementation

	notify_change
			-- Notify change handler.
		do
			if attached on_change as handler then
				handler.call ([is_checked])
			end
		end

invariant
	label_exists: label /= Void
	normal_style_exists: normal_style /= Void
	focused_style_exists: focused_style /= Void

end
