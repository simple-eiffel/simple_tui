note
	description: "[
		TUI_INPUT_DIALOG - Multi-field input dialog widget.

		A modal dialog supporting multiple input fields for data entry.
		Used for task creation, editing, and other forms.

		Features:
		- Multiple field types (text, combo box)
		- Tab navigation between fields
		- Submit/Cancel buttons
		- Modal behavior (captures focus)
		- Keyboard-driven input

		Example:
			create dialog.make ("New Task")
			dialog.add_text_field ("title", "Title:", 30)
			dialog.add_text_field ("description", "Description:", 40)
			dialog.add_combo_field ("priority", "Priority:", <<"Low", "Medium", "High">>)
			dialog.set_on_submit (agent handle_task_submit)
			dialog.show_centered (screen_width, screen_height)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_INPUT_DIALOG

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

	make (a_title: READABLE_STRING_GENERAL)
			-- Create dialog with title.
		require
			title_exists: a_title /= Void
		do
			make_widget
			title := a_title.to_string_32
			create fields.make (5)
			create field_values.make (5)
			focused_field := 0
			button_focused := False
			selected_button := 1  -- OK button
			is_visible := False
			create submit_actions
			create cancel_actions
			create title_style.make_default
			create label_style.make_default
			create field_style.make_default
			create field_focused_style.make_default
			create border_style.make_default
			create button_style.make_default
			create button_selected_style.make_default
			-- Default styles
			title_style.set_bold (True)
			border_style.set_foreground (create {TUI_COLOR}.make_index (14))  -- Cyan
			field_focused_style.set_reverse (True)
			button_selected_style.set_reverse (True)
			update_size
		ensure
			title_set: title.same_string_general (a_title)
			hidden: not is_visible
		end

feature -- Access

	title: STRING_32
			-- Dialog title.

	fields: ARRAYED_LIST [TUPLE [name: STRING_32; label: STRING_32; field_type: INTEGER; field_width: INTEGER; l_options: detachable ARRAYED_LIST [STRING_32]]]
			-- Field definitions.

	field_values: HASH_TABLE [STRING_32, STRING_32]
			-- Current field values keyed by name.

	focused_field: INTEGER
			-- Currently focused field index (1-based, 0 = none).

	button_focused: BOOLEAN
			-- Is focus on buttons (not fields)?

	selected_button: INTEGER
			-- Selected button (1 = OK, 2 = Cancel).

feature -- Field Types

	Field_type_text: INTEGER = 1
			-- Single-line text input.

	Field_type_combo: INTEGER = 2
			-- Dropdown selection.

	Field_type_number: INTEGER = 3
			-- Numeric input.

feature -- Actions

	submit_actions: ACTION_SEQUENCE [TUPLE [HASH_TABLE [STRING_32, STRING_32]]]
			-- Actions when OK is pressed.
			-- Passes field values to handlers.

	cancel_actions: ACTION_SEQUENCE [TUPLE]
			-- Actions when Cancel is pressed.

feature -- Styles

	title_style: TUI_STYLE
			-- Style for title bar.

	label_style: TUI_STYLE
			-- Style for field labels.

	field_style: TUI_STYLE
			-- Style for unfocused fields.

	field_focused_style: TUI_STYLE
			-- Style for focused field.

	border_style: TUI_STYLE
			-- Style for border.

	button_style: TUI_STYLE
			-- Style for unselected buttons.

	button_selected_style: TUI_STYLE
			-- Style for selected button.

feature -- Modification

	set_title (a_title: READABLE_STRING_GENERAL)
			-- Set dialog title.
		require
			title_exists: a_title /= Void
		do
			title := a_title.to_string_32
			update_size
		ensure
			title_set: title.same_string_general (a_title)
		end

	add_text_field (a_name, a_label: READABLE_STRING_GENERAL; a_width: INTEGER)
			-- Add a text input field.
		require
			name_exists: a_name /= Void
			label_exists: a_label /= Void
			valid_width: a_width > 0
		do
			fields.extend ([a_name.to_string_32, a_label.to_string_32, Field_type_text, a_width, Void])
			field_values.put (create {STRING_32}.make_empty, a_name.to_string_32)
			if focused_field = 0 then
				focused_field := 1
			end
			update_size
		ensure
			field_added: fields.count = old fields.count + 1
		end

	add_number_field (a_name, a_label: READABLE_STRING_GENERAL; a_width: INTEGER)
			-- Add a numeric input field.
		require
			name_exists: a_name /= Void
			label_exists: a_label /= Void
			valid_width: a_width > 0
		do
			fields.extend ([a_name.to_string_32, a_label.to_string_32, Field_type_number, a_width, Void])
			field_values.put (create {STRING_32}.make_empty, a_name.to_string_32)
			if focused_field = 0 then
				focused_field := 1
			end
			update_size
		ensure
			field_added: fields.count = old fields.count + 1
		end

	add_combo_field (a_name, a_label: READABLE_STRING_GENERAL; a_options: ARRAY [READABLE_STRING_GENERAL])
			-- Add a combo box field.
		require
			name_exists: a_name /= Void
			label_exists: a_label /= Void
			options_exist: a_options /= Void
		local
			l_options: ARRAYED_LIST [STRING_32]
			l_width: INTEGER
		do
			create l_options.make (a_options.count)
			across a_options as opt loop
				l_options.extend (opt.to_string_32)
				l_width := l_width.max (opt.out.count)
			end
			fields.extend ([a_name.to_string_32, a_label.to_string_32, Field_type_combo, l_width + 3, l_options])
			-- Default to first option
			if not l_options.is_empty then
				field_values.put (l_options.first, a_name.to_string_32)
			else
				field_values.put (create {STRING_32}.make_empty, a_name.to_string_32)
			end
			if focused_field = 0 then
				focused_field := 1
			end
			update_size
		ensure
			field_added: fields.count = old fields.count + 1
		end

	set_field_value (a_name, a_value: READABLE_STRING_GENERAL)
			-- Set value for a field.
		require
			name_exists: a_name /= Void
			value_exists: a_value /= Void
		do
			field_values.force (a_value.to_string_32, a_name.to_string_32)
		end

	get_field_value (a_name: READABLE_STRING_GENERAL): STRING_32
			-- Get value for a field.
		require
			name_exists: a_name /= Void
		do
			if attached field_values.item (a_name.to_string_32) as al_v then
				Result := v
			else
				create Result.make_empty
			end
		end

	get_field_integer (a_name: READABLE_STRING_GENERAL): INTEGER
			-- Get integer value for a field.
		require
			name_exists: a_name /= Void
		local
			l_val: STRING_32
		do
			l_val := get_field_value (a_name)
			if l_val.is_integer then
				Result := l_val.to_integer
			end
		end

	set_on_submit (a_handler: PROCEDURE [HASH_TABLE [STRING_32, STRING_32]])
			-- Set submit handler.
		do
			submit_actions.wipe_out
			submit_actions.extend (a_handler)
		end

	set_on_cancel (a_handler: PROCEDURE)
			-- Set cancel handler.
		do
			cancel_actions.wipe_out
			cancel_actions.extend (a_handler)
		end

feature -- Display

	show_centered (screen_width, screen_height: INTEGER)
			-- Show dialog centered on screen.
		local
			cx, cy: INTEGER
		do
			cx := (screen_width - l_width) // 2 + 1
			cy := (screen_height - height) // 2 + 1
			-- Clamp to valid position (at least 1)
			cx := cx.max (1)
			cy := cy.max (1)
			set_position (cx, cy)
			show
			if fields.count > 0 then
				focused_field := 1
				button_focused := False
			end
		ensure
			visible: is_visible
		end

	submit
			-- Submit the dialog (OK).
		do
			hide
			submit_actions.call ([field_values])
		ensure
			hidden: not is_visible
		end

	cancel
			-- Cancel the dialog.
		do
			hide
			cancel_actions.call ([])
		ensure
			hidden: not is_visible
		end

feature -- Navigation

	focus_next_field
			-- Move focus to next field or button.
		do
			if button_focused then
				if selected_button = 1 then
					selected_button := 2  -- Move to Cancel
				else
					-- Wrap to first field
					button_focused := False
					if fields.count > 0 then
						focused_field := 1
					end
				end
			else
				if focused_field < fields.count then
					focused_field := focused_field + 1
				else
					-- Move to buttons
					button_focused := True
					selected_button := 1
				end
			end
		end

	focus_previous_field
			-- Move focus to previous field or button.
		do
			if button_focused then
				if selected_button = 2 then
					selected_button := 1  -- Move to OK
				else
					-- Wrap to last field
					button_focused := False
					focused_field := fields.count
				end
			else
				if focused_field > 1 then
					focused_field := focused_field - 1
				else
					-- Move to buttons (Cancel)
					button_focused := True
					selected_button := 2
				end
			end
		end

feature -- Event Handling

	handle_key (a_event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_visible then
				if a_event.is_escape then
					cancel
					Result := True
				elseif a_event.is_tab then
					if a_event.has_shift then
						focus_previous_field
					else
						focus_next_field
					end
					Result := True
				elseif button_focused then
					Result := handle_button_key (a_event)
				else
					Result := handle_field_key (a_event)
				end
			end
		end

	handle_mouse (a_event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			ax, ay, field_y, i, button_row, bx: INTEGER
		do
			if is_visible then
				ax := absolute_x
				ay := absolute_y

				if a_event.is_mouse_press and a_event.mouse_button = 1 then
					-- Check field clicks
					from i := 1 until i > fields.count loop
						field_y := ay + 1 + i
						if a_event.mouse_y = field_y then
							focused_field := i
							button_focused := False
							Result := True
						end
						i := i + 1
					end

					-- Check button clicks
					button_row := ay + height - 2
					if a_event.mouse_y = button_row then
						bx := ax + (l_width - 20) // 2  -- Approximate button area
						button_focused := True
						if a_event.mouse_x < bx + 8 then
							selected_button := 1
							submit
						else
							selected_button := 2
							cancel
						end
						Result := True
					end
				end

				-- Consume all mouse events when visible (modal)
				if not Result then
					Result := True
				end
			end
		end

feature -- Rendering

	render (a_buffer: TUI_BUFFER)
			-- Render dialog to buffer.
		local
			ax, ay, i, row: INTEGER
			l_line: STRING_32
			j: INTEGER
			l_f: TUPLE [name: STRING_32; label: STRING_32; field_type: INTEGER; field_width: INTEGER; options: detachable ARRAYED_LIST [STRING_32]]
		do
			if is_visible then
				ax := absolute_x
				ay := absolute_y

				-- Top border with title
				create l_line.make (l_width)
				l_line.append_character ('%/0x250C/')  -- ┌
				l_line.append_character ('%/0x2500/')  -- ─
				l_line.append_character (' ')
				l_line.append (title)
				l_line.append_character (' ')
				from j := l_line.count until j >= l_width - 1 loop
					l_line.append_character ('%/0x2500/')  -- ─
					j := j + 1
				end
				l_line.append_character ('%/0x2510/')  -- ┐
				a_buffer.put_string (ax, ay, l_line, border_style)

				-- Render each field
				row := 1
				from i := 1 until i > fields.count loop
					l_f := fields.i_th (i)
					render_field_row (a_buffer, ax, ay + row, i, l_f)
					row := row + 1
					i := i + 1
				end

				-- Empty row before buttons
				render_empty_row (a_buffer, ax, ay + row)
				row := row + 1

				-- Button row
				render_button_row (a_buffer, ax, ay + row)
				row := row + 1

				-- Bottom border
				create l_line.make (l_width)
				l_line.append_character ('%/0x2514/')  -- └
				from j := 1 until j >= l_width - 1 loop
					l_line.append_character ('%/0x2500/')  -- ─
					j := j + 1
				end
				l_line.append_character ('%/0x2518/')  -- ┘
				a_buffer.put_string (ax, ay + row, l_line, border_style)
			end
		end

feature -- Queries

	preferred_width: INTEGER
			-- Preferred width based on content.
		do
			Result := l_width
		end

	preferred_height: INTEGER
			-- Preferred height based on fields.
		do
			Result := height
		end

feature {NONE} -- Implementation

	label_width: INTEGER
			-- Width of label column.

	update_size
			-- Update dialog size based on content.
		local
			min_width, max_label, max_field: INTEGER
			l_f: TUPLE [name: STRING_32; label: STRING_32; field_type: INTEGER; field_width: INTEGER; options: detachable ARRAYED_LIST [STRING_32]]
			i: INTEGER
		do
			-- Calculate label width
			max_label := 0
			max_field := 0
			from i := 1 until i > fields.count loop
				l_f := fields.i_th (i)
				max_label := max_label.max (l_f.label.count)
				max_field := max_field.max (l_f.field_width)
				i := i + 1
			end
			label_width := max_label + 2  -- Label + ": "

			-- Minimum width for title
			min_width := title.count + 6

			-- Width for fields: border + label + field + border
			min_width := min_width.max (2 + label_width + max_field + 2)

			-- Width for buttons ([ OK ] [ Cancel ])
			min_width := min_width.max (24)

			l_width := min_width.max (30)

			-- Height: border + fields + empty + buttons + border
			height := 2 + fields.count + 2
		end

	handle_button_key (a_event: TUI_EVENT): BOOLEAN
			-- Handle key when focus is on buttons.
		do
			if a_event.is_enter or a_event.is_space then
				if selected_button = 1 then
					submit
				else
					cancel
				end
				Result := True
			elseif a_event.is_left then
				selected_button := 1
				Result := True
			elseif a_event.is_right then
				selected_button := 2
				Result := True
			end
		end

	handle_field_key (a_event: TUI_EVENT): BOOLEAN
			-- Handle key when focus is on a field.
		local
			l_f: TUPLE [name: STRING_32; label: STRING_32; field_type: INTEGER; field_width: INTEGER; options: detachable ARRAYED_LIST [STRING_32]]
		do
			if focused_field > 0 and focused_field <= fields.count then
				l_f := fields.i_th (focused_field)
				if l_f.field_type = Field_type_combo then
					Result := handle_combo_key (a_event, l_f)
				else
					Result := handle_text_key (a_event, l_f)
				end
			end
		end

	handle_text_key (a_event: TUI_EVENT; l_f: TUPLE [name: STRING_32; label: STRING_32; field_type: INTEGER; field_width: INTEGER; l_options: detachable ARRAYED_LIST [STRING_32]]): BOOLEAN
			-- Handle key for text field.
		local
			l_val: STRING_32
			l_char: CHARACTER_32
		do
			if attached field_values.item (l_f.name) as al_current_val then
				l_val := current_val
			else
				create l_val.make_empty
			end

			if a_event.is_backspace then
				if not l_val.is_empty then
					l_val.remove_tail (1)
					field_values.force (l_val, l_f.name)
				end
				Result := True
			elseif a_event.is_enter then
				-- Submit on Enter
				submit
				Result := True
			elseif a_event.is_char_event then
				l_char := a_event.char
				-- Only accept printable characters
				if l_char.natural_32_code >= 32 then
					-- For number fields, only accept digits
					if l_f.field_type = Field_type_number then
						if l_char.is_digit then
							l_val.append_character (l_char)
							field_values.force (l_val, l_f.name)
						end
					else
						l_val.append_character (l_char)
						field_values.force (l_val, l_f.name)
					end
				end
				Result := True
			end
		end

	handle_combo_key (a_event: TUI_EVENT; l_f: TUPLE [name: STRING_32; label: STRING_32; field_type: INTEGER; field_width: INTEGER; l_options: detachable ARRAYED_LIST [STRING_32]]): BOOLEAN
			-- Handle key for combo box field.
		local
			l_current: STRING_32
			l_index, l_new_index: INTEGER
		do
			if attached l_f.options as opts and then not opts.is_empty then
				l_current := get_field_value (l_f.name)
				l_index := opts.index_of (l_current, 1)
				if l_index = 0 then
					l_index := 1
				end

				if a_event.is_up or a_event.is_left then
					l_new_index := l_index - 1
					if l_new_index < 1 then
						l_new_index := opts.count
					end
					field_values.force (opts.i_th (l_new_index), l_f.name)
					Result := True
				elseif a_event.is_down or a_event.is_right or a_event.is_space then
					l_new_index := l_index + 1
					if l_new_index > opts.count then
						l_new_index := 1
					end
					field_values.force (opts.i_th (l_new_index), l_f.name)
					Result := True
				elseif a_event.is_enter then
					submit
					Result := True
				end
			end
		end

	render_field_row (a_buffer: TUI_BUFFER; ax, ay, l_index: INTEGER;
			l_f: TUPLE [name: STRING_32; label: STRING_32; field_type: INTEGER; field_width: INTEGER; l_options: detachable ARRAYED_LIST [STRING_32]])
			-- Render a field row.
		local
			line, field_display: STRING_32
			l_current_style: TUI_STYLE
			l_field_x: INTEGER
		do
			-- Left border and label
			create l_line.make (l_width)
			l_line.append_character ('%/0x2502/')  -- │
			l_line.append_character (' ')
			l_line.append (l_f.label)
			-- Pad label to label_width
			from until l_line.count >= label_width + 1 loop
				l_line.append_character (' ')
			end

			-- Get field value
			if attached field_values.item (l_f.name) as al_v then
				field_display := al_v.twin
			else
				create field_display.make_empty
			end

			-- Pad/truncate field display
			from until field_display.count >= l_f.field_width loop
				field_display.append_character (' ')
			end
			if field_display.count > l_f.field_width then
				field_display := field_display.substring (1, l_f.field_width)
			end

			-- Add combo indicator if combo
			if l_f.field_type = Field_type_combo then
				field_display.append (" v")
			end

			-- Pad rest of line
			l_field_x := l_line.count
			l_line.append (field_display)
			from until l_line.count >= l_width - 1 loop
				l_line.append_character (' ')
			end
			l_line.append_character ('%/0x2502/')  -- │

			-- Render line with label style
			a_buffer.put_string (ax, ay, l_line, label_style)

			-- Render borders
			a_buffer.put_char (ax, ay, '%/0x2502/', border_style)
			a_buffer.put_char (ax + l_width - 1, ay, '%/0x2502/', border_style)

			-- Render field value with field style
			if not button_focused and l_index = focused_field then
				l_current_style := field_focused_style
			else
				l_current_style := field_style
			end
			a_buffer.put_string (ax + l_field_x, ay, field_display, l_current_style)
		end

	render_empty_row (a_buffer: TUI_BUFFER; ax, ay: INTEGER)
			-- Render an empty row.
		local
			l_line: STRING_32
			j: INTEGER
		do
			create l_line.make (l_width)
			l_line.append_character ('%/0x2502/')  -- │
			from j := 1 until j >= l_width - 1 loop
				l_line.append_character (' ')
				j := j + 1
			end
			l_line.append_character ('%/0x2502/')  -- │
			a_buffer.put_string (ax, ay, l_line, border_style)
		end

	render_button_row (a_buffer: TUI_BUFFER; ax, ay: INTEGER)
			-- Render the button row.
		local
			line, ok_btn, cancel_btn: STRING_32
			ok_style, cancel_style: TUI_STYLE
			j, btn_start: INTEGER
		do
			-- Prepare buttons
			ok_btn := "[ OK ]"
			cancel_btn := "[ Cancel ]"

			-- Choose styles
			if button_focused then
				if selected_button = 1 then
					ok_style := button_selected_style
					cancel_style := button_style
				else
					ok_style := button_style
					cancel_style := button_selected_style
				end
			else
				ok_style := button_style
				cancel_style := button_style
			end

			-- Render empty row first
			create l_line.make (l_width)
			l_line.append_character ('%/0x2502/')  -- │
			from j := 1 until j >= l_width - 1 loop
				l_line.append_character (' ')
				j := j + 1
			end
			l_line.append_character ('%/0x2502/')  -- │
			a_buffer.put_string (ax, ay, l_line, border_style)

			-- Center buttons
			btn_start := ax + (l_width - ok_btn.count - cancel_btn.count - 3) // 2
			a_buffer.put_string (btn_start, ay, ok_btn, ok_style)
			a_buffer.put_string (btn_start + ok_btn.count + 2, ay, cancel_btn, cancel_style)
		end

invariant
	title_exists: title /= Void
	fields_exist: fields /= Void
	field_values_exist: field_values /= Void
	submit_actions_exist: submit_actions /= Void
	cancel_actions_exist: cancel_actions /= Void
	valid_focused_field: focused_field >= 0 and focused_field <= fields.count
	valid_selected_button: selected_button >= 1 and selected_button <= 2

end
