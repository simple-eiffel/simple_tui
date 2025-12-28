note
	description: "[
		TUI_MESSAGE_BOX - Modal message dialog

		Displays a message with configurable buttons.

		EV equivalent: EV_MESSAGE_DIALOG
		Other frameworks: MessageBox, AlertDialog, Dialog

		Features:
		- Title bar
		- Message text
		- Configurable buttons (Ok, Ok/Cancel, Yes/No, custom)
		- Modal behavior (captures focus)
		- Keyboard navigation
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_MESSAGE_BOX

inherit
	TUI_WIDGET
		redefine
			handle_key,
			handle_mouse,
			preferred_width,
			preferred_height
		end

create
	make,
	make_ok,
	make_ok_cancel,
	make_yes_no

feature {NONE} -- Initialization

	make (a_title, a_message: READABLE_STRING_GENERAL)
			-- Create message box with title and message.
		require
			title_exists: a_title /= Void
			message_exists: a_message /= Void
		do
			make_widget
			title := a_title.to_string_32
			message := a_message.to_string_32
			create buttons.make (3)
			selected_button := 0
			is_visible := False
			create title_style.make_default
			create message_style.make_default
			create border_style.make_default
			create button_style.make_default
			create button_selected_style.make_default
			create close_actions
			-- Default styles
			title_style.set_bold (True)
			border_style.set_foreground (create {TUI_COLOR}.make_index (14))  -- Cyan
			button_selected_style.set_reverse (True)
			-- Calculate size
			update_size
		ensure
			title_set: title.same_string_general (a_title)
			message_set: message.same_string_general (a_message)
			hidden: not is_visible
		end

	make_ok (a_title, a_message: READABLE_STRING_GENERAL)
			-- Create message box with Ok button.
		do
			make (a_title, a_message)
			add_button ("Ok", Button_ok)
		ensure
			has_ok: buttons.count = 1
		end

	make_ok_cancel (a_title, a_message: READABLE_STRING_GENERAL)
			-- Create message box with Ok and Cancel buttons.
		do
			make (a_title, a_message)
			add_button ("Ok", Button_ok)
			add_button ("Cancel", Button_cancel)
		ensure
			has_buttons: buttons.count = 2
		end

	make_yes_no (a_title, a_message: READABLE_STRING_GENERAL)
			-- Create message box with Yes and No buttons.
		do
			make (a_title, a_message)
			add_button ("Yes", Button_yes)
			add_button ("No", Button_no)
		ensure
			has_buttons: buttons.count = 2
		end

feature -- Access

	title: STRING_32
			-- Dialog title.

	message: STRING_32
			-- Message text.

	buttons: ARRAYED_LIST [TUPLE [label: STRING_32; id: INTEGER]]
			-- Button definitions.

	selected_button: INTEGER
			-- Currently selected button index (1-based, 0 = none).

	result_button: INTEGER
			-- Button ID that was clicked to close dialog.

feature -- Actions (EV compatible)

	close_actions: ACTION_SEQUENCE [TUPLE [INTEGER]]
			-- Actions to execute when dialog closes.
			-- Passes button ID to handlers.
			-- Use `extend' to add handlers, `prune' to remove.

feature -- Button IDs

	Button_ok: INTEGER = 1
	Button_cancel: INTEGER = 2
	Button_yes: INTEGER = 3
	Button_no: INTEGER = 4

feature -- Styles

	title_style: TUI_STYLE
			-- Style for title bar.

	message_style: TUI_STYLE
			-- Style for message text.

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

	set_message (a_message: READABLE_STRING_GENERAL)
			-- Set message text.
		require
			message_exists: a_message /= Void
		do
			message := a_message.to_string_32
			update_size
		ensure
			message_set: message.same_string_general (a_message)
		end

	add_button (a_label: READABLE_STRING_GENERAL; a_id: INTEGER)
			-- Add a button with label and ID.
		require
			label_exists: a_label /= Void
		do
			buttons.extend ([a_label.to_string_32, a_id])
			if selected_button = 0 then
				selected_button := 1
			end
			update_size
		ensure
			button_added: buttons.count = old buttons.count + 1
		end

	clear_buttons
			-- Remove all buttons.
		do
			buttons.wipe_out
			selected_button := 0
			update_size
		ensure
			no_buttons: buttons.is_empty
		end

	set_on_close (handler: PROCEDURE [INTEGER])
			-- Set close handler (clears previous handlers).
			-- For multiple handlers, use close_actions.extend directly.
		do
			close_actions.wipe_out
			close_actions.extend (handler)
		end

	set_title_style (s: TUI_STYLE)
			-- Set title style.
		require
			s_exists: s /= Void
		do
			title_style := s
		ensure
			style_set: title_style = s
		end

	set_message_style (s: TUI_STYLE)
			-- Set message style.
		require
			s_exists: s /= Void
		do
			message_style := s
		ensure
			style_set: message_style = s
		end

	set_border_style (s: TUI_STYLE)
			-- Set border style.
		require
			s_exists: s /= Void
		do
			border_style := s
		ensure
			style_set: border_style = s
		end

	set_button_style (s: TUI_STYLE)
			-- Set button style.
		require
			s_exists: s /= Void
		do
			button_style := s
		ensure
			style_set: button_style = s
		end

	set_button_selected_style (s: TUI_STYLE)
			-- Set selected button style.
		require
			s_exists: s /= Void
		do
			button_selected_style := s
		ensure
			style_set: button_selected_style = s
		end

feature -- Display

	show_centered (screen_width, screen_height: INTEGER)
			-- Show dialog centered on screen.
		local
			cx, cy: INTEGER
		do
			cx := (screen_width - width) // 2 + 1
			cy := (screen_height - height) // 2 + 1
			-- Clamp to valid position (at least 1)
			cx := cx.max (1)
			cy := cy.max (1)
			set_position (cx, cy)
			show
			if buttons.count > 0 then
				selected_button := 1
			end
		ensure
			visible: is_visible
		end

	close_with_button (button_id: INTEGER)
			-- Close dialog with specified button result.
		do
			result_button := button_id
			hide
			close_actions.call ([button_id])
		ensure
			hidden: not is_visible
			result_set: result_button = button_id
		end

feature -- Navigation

	select_next_button
			-- Select next button.
		do
			if buttons.count > 0 then
				if selected_button < buttons.count then
					selected_button := selected_button + 1
				else
					selected_button := 1
				end
			end
		end

	select_previous_button
			-- Select previous button.
		do
			if buttons.count > 0 then
				if selected_button > 1 then
					selected_button := selected_button - 1
				else
					selected_button := buttons.count
				end
			end
		end

	activate_selected
			-- Activate the selected button.
		do
			if selected_button > 0 and selected_button <= buttons.count then
				close_with_button (buttons.i_th (selected_button).id)
			end
		end

feature -- Event Handling

	handle_key (event: TUI_EVENT): BOOLEAN
			-- Handle key event.
		do
			if is_visible then
				if event.is_left or (event.is_tab and event.has_shift) then
					select_previous_button
					Result := True
				elseif event.is_right or event.is_tab then
					select_next_button
					Result := True
				elseif event.is_enter or event.is_space then
					activate_selected
					Result := True
				elseif event.is_escape then
					-- Escape closes with Cancel or last button
					if buttons.count > 0 then
						close_with_button (buttons.last.id)
					else
						hide
					end
					Result := True
				end
			end
		end

	handle_mouse (event: TUI_EVENT): BOOLEAN
			-- Handle mouse event.
		local
			ax, ay, button_y, bx, i, btn_width: INTEGER
		do
			if is_visible then
				ax := absolute_x
				ay := absolute_y
				button_y := ay + height - 2  -- Buttons are 2 rows from bottom

				if event.mouse_y = button_y then
					-- Click on button row
					bx := ax + (width - total_buttons_width) // 2
					from i := 1 until i > buttons.count loop
						btn_width := buttons.i_th (i).label.count + 4  -- [ Label ]
						if event.mouse_x >= bx and event.mouse_x < bx + btn_width then
							selected_button := i
							if event.is_mouse_press and event.mouse_button = 1 then
								activate_selected
							end
							Result := True
						end
						bx := bx + btn_width + 2  -- gap between buttons
						i := i + 1
					end
				end

				-- Consume all mouse events when visible (modal)
				if not Result and event.is_mouse_press then
					Result := True
				end
			end
		end

feature -- Rendering

	render (buffer: TUI_BUFFER)
			-- Render message box to buffer.
		local
			ax, ay, i, j, inner_width, bx, btn_width: INTEGER
			line: STRING_32
		do
			if is_visible then
				ax := absolute_x
				ay := absolute_y
				inner_width := width - 2

				-- Top border with title: ┌─ Title ─┐
				create line.make (width)
				line.append_character ('%/0x250C/')  -- ┌
				line.append_character ('%/0x2500/')  -- ─
				line.append_character (' ')
				line.append (title)
				line.append_character (' ')
				from j := line.count until j >= width - 1 loop
					line.append_character ('%/0x2500/')  -- ─
					j := j + 1
				end
				line.append_character ('%/0x2510/')  -- ┐
				buffer.put_string (ax, ay, line, border_style)

				-- Message row(s): │ Message │
				create line.make (width)
				line.append_character ('%/0x2502/')  -- │
				line.append_character (' ')
				line.append (message)
				from until line.count >= width - 1 loop
					line.append_character (' ')
				end
				line.append_character ('%/0x2502/')  -- │
				buffer.put_string (ax, ay + 1, line, message_style)
				-- Draw left/right borders with message style for content
				buffer.put_char (ax, ay + 1, '%/0x2502/', border_style)
				buffer.put_char (ax + width - 1, ay + 1, '%/0x2502/', border_style)

				-- Empty row before buttons: │         │
				create line.make (width)
				line.append_character ('%/0x2502/')  -- │
				from j := 1 until j >= width - 1 loop
					line.append_character (' ')
					j := j + 1
				end
				line.append_character ('%/0x2502/')  -- │
				buffer.put_string (ax, ay + 2, line, border_style)

				-- Button row: │  [Ok] [Cancel]  │
				create line.make (width)
				line.append_character ('%/0x2502/')  -- │
				from j := 1 until j >= width - 1 loop
					line.append_character (' ')
					j := j + 1
				end
				line.append_character ('%/0x2502/')  -- │
				buffer.put_string (ax, ay + 3, line, border_style)

				-- Render buttons centered
				bx := ax + (width - total_buttons_width) // 2
				from i := 1 until i > buttons.count loop
					render_button (buffer, bx, ay + 3, i)
					btn_width := buttons.i_th (i).label.count + 4
					bx := bx + btn_width + 2
					i := i + 1
				end

				-- Bottom border: └───────┘
				create line.make (width)
				line.append_character ('%/0x2514/')  -- └
				from j := 1 until j >= width - 1 loop
					line.append_character ('%/0x2500/')  -- ─
					j := j + 1
				end
				line.append_character ('%/0x2518/')  -- ┘
				buffer.put_string (ax, ay + 4, line, border_style)
			end
		end

feature -- Queries

	preferred_width: INTEGER
			-- Preferred width based on content.
		do
			Result := width
		end

	preferred_height: INTEGER
			-- Preferred height (fixed at 5: border + message + space + buttons + border).
		do
			Result := 5
		end

feature {NONE} -- Implementation

	update_size
			-- Update width based on title, message, and buttons.
		local
			min_width: INTEGER
		do
			-- Minimum width for title (+ borders + padding)
			min_width := title.count + 6
			-- Width for message
			min_width := min_width.max (message.count + 4)
			-- Width for buttons
			min_width := min_width.max (total_buttons_width + 4)
			width := min_width.max (20)
			height := 5
		end

	total_buttons_width: INTEGER
			-- Total width of all buttons with gaps.
		local
			i: INTEGER
		do
			from i := 1 until i > buttons.count loop
				Result := Result + buttons.i_th (i).label.count + 4  -- [ Label ]
				if i < buttons.count then
					Result := Result + 2  -- gap
				end
				i := i + 1
			end
		end

	render_button (buffer: TUI_BUFFER; bx, by, index: INTEGER)
			-- Render button at position.
		local
			btn_text: STRING_32
			btn_style: TUI_STYLE
		do
			create btn_text.make (10)
			btn_text.append ("[ ")
			btn_text.append (buttons.i_th (index).label)
			btn_text.append (" ]")

			if index = selected_button then
				btn_style := button_selected_style
			else
				btn_style := button_style
			end

			buffer.put_string (bx, by, btn_text, btn_style)
		end

invariant
	title_exists: title /= Void
	message_exists: message /= Void
	buttons_exist: buttons /= Void
	close_actions_exists: close_actions /= Void
	title_style_exists: title_style /= Void
	message_style_exists: message_style /= Void
	border_style_exists: border_style /= Void
	button_style_exists: button_style /= Void
	button_selected_style_exists: button_selected_style /= Void

end
