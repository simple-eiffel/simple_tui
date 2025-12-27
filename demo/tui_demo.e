note
	description: "[
		Interactive demo application for simple_tui library

		Showcases all widgets:
		- Labels with different alignments
		- Buttons with click handlers
		- Text fields with editing
		- Checkboxes with toggles
		- Progress bars (animated)
		- Lists with scrolling

		Navigation: Tab to move focus, Enter/Space to activate
		Quit: Ctrl+Q or press the Quit button
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_DEMO

create
	make

feature {NONE} -- Initialization

	make
			-- Run the demo.
		do
			setup_logging
			log.info ("=== TUI_DEMO starting ===")
			create_widgets
			setup_handlers
			run_demo
			log.info ("=== TUI_DEMO exiting ===")
		end

	setup_logging
			-- Initialize file-based logging.
		do
			create log.make_to_file ("tui_demo.log")
			log.set_level (log.Level_debug)
		end

feature {NONE} -- Logging

	log: SIMPLE_LOGGER
			-- File logger for debugging.

feature {NONE} -- Widgets

	app: TUI_APPLICATION
	root_box: TUI_VBOX

	-- Header
	title_label: TUI_LABEL
	subtitle_label: TUI_LABEL

	-- Main content
	content_hbox: TUI_HBOX

	-- Left panel - Form
	form_box: TUI_BOX
	name_label: TUI_LABEL
	name_field: TUI_TEXT_FIELD
	password_label: TUI_LABEL
	password_field: TUI_TEXT_FIELD
	checkbox1: TUI_CHECKBOX
	checkbox2: TUI_CHECKBOX
	submit_button: TUI_BUTTON

	-- Middle panel - Progress
	progress_box: TUI_BOX
	progress_label: TUI_LABEL
	progress1: TUI_PROGRESS
	progress2: TUI_PROGRESS
	progress3: TUI_PROGRESS
	start_button: TUI_BUTTON

	-- Right panel - List
	list_box: TUI_BOX
	demo_list: TUI_LIST
	list_status: TUI_LABEL

	-- Second row panels
	content_hbox2: TUI_HBOX

	-- Left panel - Radio buttons
	radio_box: TUI_BOX
	radio_group: TUI_RADIO_GROUP
	radio1: TUI_RADIO_BUTTON
	radio2: TUI_RADIO_BUTTON
	radio3: TUI_RADIO_BUTTON
	radio_sep: TUI_SEPARATOR

	-- Middle panel - Combo box
	combo_box_panel: TUI_BOX
	combo_label: TUI_LABEL
	theme_combo: TUI_COMBO_BOX
	combo_sep: TUI_SEPARATOR

	-- Footer
	footer_hbox: TUI_HBOX
	quit_button: TUI_BUTTON
	status_label: TUI_LABEL

feature {NONE} -- Widget Creation

	create_widgets
			-- Create all widgets.
		local
			l_top, l_mid: STRING_32
		do
			log.info ("create_widgets starting")

			-- Initialize color theme
			setup_color_theme

			-- Create application
			create app.make
			log.info ("app created")

			-- Root container
			create root_box.make (80, 24)
			root_box.set_gap (1)
			log.info ("root_box created: 80x24")

			-- === Header ===
			-- Use Unicode escapes for box drawing to avoid UTF-8 source file issues
			l_top := double_box_top (78)
			log_string32_codes ("double_box_top result", l_top)
			create title_label.make_with_text (l_top)
			title_label.set_style (header_style)
			log_string32_codes ("title_label.text", title_label.text)

			l_mid := double_box_middle ("simple_tui Interactive Demo", 78)
			log_string32_codes ("double_box_middle result", l_mid)
			create subtitle_label.make_with_text (l_mid)
			subtitle_label.set_style (header_style)
			log_string32_codes ("subtitle_label.text", subtitle_label.text)

			-- Header box
			root_box.add_child (title_label)
			root_box.add_child (subtitle_label)

			-- === Content Area ===
			create content_hbox.make (80, 15)
			content_hbox.set_gap (2)

			-- Left Panel: Form
			create form_box.make_with_title ("Login Form", 24, 13)
			form_box.set_padding (1)
			form_box.set_border_style (form_border_style)
			form_box.set_title_style (form_title_style)

			create name_label.make_with_text ("Name:")
			name_label.set_style (label_style)
			create name_field.make (18)
			name_field.set_placeholder ("Enter name...")
			name_field.set_normal_style (input_style)
			name_field.set_focused_style (input_focused_style)

			create password_label.make_with_text ("Password:")
			password_label.set_style (label_style)
			create password_field.make (18)
			password_field.set_password (True)
			password_field.set_placeholder ("Secret...")
			password_field.set_normal_style (input_style)
			password_field.set_focused_style (input_focused_style)

			create checkbox1.make ("Remember me")
			checkbox1.set_normal_style (checkbox_style)
			checkbox1.set_focused_style (checkbox_focused_style)
			create checkbox2.make ("Send newsletter")
			checkbox2.set_normal_style (checkbox_style)
			checkbox2.set_focused_style (checkbox_focused_style)

			create submit_button.make ("Submit")
			submit_button.set_normal_style (button_style)
			submit_button.set_focused_style (button_focused_style)
			submit_button.set_pressed_style (button_pressed_style)

			-- Add to form
			form_box.add_child (name_label)
			form_box.add_child (name_field)
			form_box.add_child (password_label)
			form_box.add_child (password_field)
			form_box.add_child (checkbox1)
			form_box.add_child (checkbox2)
			form_box.add_child (submit_button)
			layout_form

			-- Middle Panel: Progress
			create progress_box.make_with_title ("Progress", 24, 13)
			progress_box.set_padding (1)
			progress_box.set_border_style (progress_border_style)
			progress_box.set_title_style (progress_title_style)

			create progress_label.make_with_text ("Progress Bars:")
			progress_label.set_style (label_style)

			create progress1.make (20)
			progress1.set_value (0)
			progress1.set_show_percentage (True)
			progress1.set_fill_style (progress_fill_style)
			progress1.set_empty_style (progress_empty_style)

			create progress2.make (20)
			progress2.set_value (25)
			progress2.set_fill_char ('%/0x2593/')  -- Dark shade
			progress2.set_empty_char ('%/0x2591/')  -- Light shade
			progress2.set_fill_style (progress2_fill_style)
			progress2.set_empty_style (progress_empty_style)

			create progress3.make (20)
			progress3.set_indeterminate (True)
			progress3.set_show_percentage (False)
			progress3.set_fill_style (progress3_fill_style)
			progress3.set_empty_style (progress_empty_style)

			create start_button.make ("Start")
			start_button.set_normal_style (button_style)
			start_button.set_focused_style (button_focused_style)
			start_button.set_pressed_style (button_pressed_style)

			progress_box.add_child (progress_label)
			progress_box.add_child (progress1)
			progress_box.add_child (progress2)
			progress_box.add_child (progress3)
			progress_box.add_child (start_button)
			layout_progress

			-- Right Panel: List
			create list_box.make_with_title ("Items", 26, 13)
			list_box.set_padding (1)
			list_box.set_border_style (list_border_style)
			list_box.set_title_style (list_title_style)

			create demo_list.make (22, 8)
			demo_list.set_normal_style (list_item_style)
			demo_list.set_selected_style (list_selected_style)
			demo_list.add_item ("First item")
			demo_list.add_item ("Second item")
			demo_list.add_item ("Third item")
			demo_list.add_item ("Fourth item")
			demo_list.add_item ("Fifth item")
			demo_list.add_item ("Sixth item")
			demo_list.add_item ("Seventh item")
			demo_list.add_item ("Eighth item")
			demo_list.add_item ("Ninth item")
			demo_list.add_item ("Tenth item")

			create list_status.make (22)  -- Wide enough for "Selected: Seventh item"
			list_status.set_text ("Selected: 1")
			list_status.set_style (status_style)

			list_box.add_child (demo_list)
			list_box.add_child (list_status)
			layout_list

			-- Add panels to content
			content_hbox.add_child (form_box)
			log.info ("form_box added to content_hbox, form_box.x=" + form_box.x.out + " form_box.width=" + form_box.width.out)
			content_hbox.add_child (progress_box)
			log.info ("progress_box added to content_hbox, progress_box.x=" + progress_box.x.out + " progress_box.width=" + progress_box.width.out)
			content_hbox.add_child (list_box)
			log.info ("list_box added to content_hbox, list_box.x=" + list_box.x.out + " list_box.width=" + list_box.width.out)

			root_box.add_child (content_hbox)

			-- === Second Content Row ===
			create content_hbox2.make (80, 7)
			content_hbox2.set_gap (2)

			-- Radio button panel
			create radio_box.make_with_title ("Display Mode", 26, 6)
			radio_box.set_padding (1)
			radio_box.set_border_style (radio_border_style)
			radio_box.set_title_style (radio_title_style)

			create radio_group.make
			create radio1.make ("Normal")
			create radio2.make ("Compact")
			create radio3.make ("Detailed")
			radio1.set_normal_style (radio_style)
			radio1.set_focused_style (radio_focused_style)
			radio2.set_normal_style (radio_style)
			radio2.set_focused_style (radio_focused_style)
			radio3.set_normal_style (radio_style)
			radio3.set_focused_style (radio_focused_style)
			radio_group.add_button (radio1)
			radio_group.add_button (radio2)
			radio_group.add_button (radio3)

			create radio_sep.make_horizontal (22)
			radio_sep.set_style (separator_style)

			radio_box.add_child (radio_group)
			radio_box.add_child (radio_sep)
			radio_group.set_position (1, 1)
			radio_sep.set_position (1, 4)
			radio_group.layout

			-- Combo box panel
			create combo_box_panel.make_with_title ("Theme", 26, 6)
			combo_box_panel.set_padding (1)
			combo_box_panel.set_border_style (combo_border_style)
			combo_box_panel.set_title_style (combo_title_style)

			create combo_label.make_with_text ("Select theme:")
			combo_label.set_style (label_style)

			create theme_combo.make (20)
			theme_combo.add_item ("Default")
			theme_combo.add_item ("Dark Mode")
			theme_combo.add_item ("Light Mode")
			theme_combo.add_item ("High Contrast")
			theme_combo.add_item ("Ocean Blue")
			theme_combo.set_normal_style (combo_style)
			theme_combo.set_focused_style (combo_focused_style)

			create combo_sep.make_horizontal (22)
			combo_sep.set_line_style ({TUI_SEPARATOR}.Style_double)
			combo_sep.set_style (separator_style)

			combo_box_panel.add_child (combo_label)
			combo_box_panel.add_child (theme_combo)
			combo_box_panel.add_child (combo_sep)
			combo_label.set_position (1, 1)
			theme_combo.set_position (1, 2)
			combo_sep.set_position (1, 4)

			-- Add second row panels
			content_hbox2.add_child (radio_box)
			content_hbox2.add_child (combo_box_panel)

			root_box.add_child (content_hbox2)

			-- === Footer ===
			create footer_hbox.make (80, 3)
			footer_hbox.set_gap (2)

			create quit_button.make ("Quit")
			quit_button.set_normal_style (quit_button_style)
			quit_button.set_focused_style (quit_button_focused_style)
			quit_button.set_pressed_style (quit_button_pressed_style)

			create status_label.make_with_text ("Tab: Navigate | Enter/Space: Activate | Ctrl+Q: Quit")
			status_label.set_style (footer_style)

			footer_hbox.add_child (quit_button)
			footer_hbox.add_child (status_label)

			root_box.add_child (footer_hbox)

			-- Set root
			app.set_root (root_box)
		end

	layout_form
			-- Position form widgets.
		do
			name_label.set_position (1, 1)
			name_field.set_position (1, 2)
			password_label.set_position (1, 4)
			password_field.set_position (1, 5)
			checkbox1.set_position (1, 7)
			checkbox2.set_position (1, 8)
			submit_button.set_position (1, 10)
		end

	layout_progress
			-- Position progress widgets.
		do
			progress_label.set_position (1, 1)
			progress1.set_position (1, 3)
			progress2.set_position (1, 5)
			progress3.set_position (1, 7)
			start_button.set_position (1, 9)
		end

	layout_list
			-- Position list widgets.
		do
			demo_list.set_position (1, 1)
			list_status.set_position (1, 10)
		end

feature {NONE} -- Color Theme

	setup_color_theme
			-- Initialize all color styles.
		local
			c_blue, c_cyan, c_green, c_yellow, c_red, c_magenta, c_white, c_black, c_gray: TUI_COLOR
		do
			-- Create base colors using 256-color palette
			create c_blue.make_index (12)      -- Bright blue
			create c_cyan.make_index (14)      -- Bright cyan
			create c_green.make_index (10)     -- Bright green
			create c_yellow.make_index (11)    -- Bright yellow
			create c_red.make_index (9)        -- Bright red
			create c_magenta.make_index (13)   -- Bright magenta
			create c_white.make_index (15)     -- Bright white
			create c_black.make_index (0)      -- Black
			create c_gray.make_index (8)       -- Gray

			-- Header style (bright cyan on default, bold)
			create header_style.make
			header_style.set_foreground (c_cyan)
			header_style.set_bold (True)

			-- Label style (white)
			create label_style.make
			label_style.set_foreground (c_white)

			-- Status style (yellow)
			create status_style.make
			status_style.set_foreground (c_yellow)

			-- Footer style (cyan, dim)
			create footer_style.make
			footer_style.set_foreground (c_cyan)

			-- Form panel styles
			create form_border_style.make
			form_border_style.set_foreground (c_green)
			create form_title_style.make
			form_title_style.set_foreground (c_green)
			form_title_style.set_bold (True)

			-- Progress panel styles
			create progress_border_style.make
			progress_border_style.set_foreground (c_yellow)
			create progress_title_style.make
			progress_title_style.set_foreground (c_yellow)
			progress_title_style.set_bold (True)

			-- List panel styles
			create list_border_style.make
			list_border_style.set_foreground (c_magenta)
			create list_title_style.make
			list_title_style.set_foreground (c_magenta)
			list_title_style.set_bold (True)

			-- Input field styles
			create input_style.make
			input_style.set_foreground (c_white)
			create input_focused_style.make
			input_focused_style.set_foreground (c_cyan)
			input_focused_style.set_reverse (True)

			-- Checkbox styles
			create checkbox_style.make
			checkbox_style.set_foreground (c_green)
			create checkbox_focused_style.make
			checkbox_focused_style.set_foreground (c_green)
			checkbox_focused_style.set_reverse (True)
			checkbox_focused_style.set_bold (True)

			-- Button styles (green)
			create button_style.make
			button_style.set_foreground (c_green)
			create button_focused_style.make
			button_focused_style.set_foreground (c_green)
			button_focused_style.set_reverse (True)
			button_focused_style.set_bold (True)
			create button_pressed_style.make
			button_pressed_style.set_foreground (c_white)
			button_pressed_style.set_background (c_green)
			button_pressed_style.set_bold (True)

			-- Quit button styles (red)
			create quit_button_style.make
			quit_button_style.set_foreground (c_red)
			create quit_button_focused_style.make
			quit_button_focused_style.set_foreground (c_red)
			quit_button_focused_style.set_reverse (True)
			quit_button_focused_style.set_bold (True)
			create quit_button_pressed_style.make
			quit_button_pressed_style.set_foreground (c_white)
			quit_button_pressed_style.set_background (c_red)
			quit_button_pressed_style.set_bold (True)

			-- Progress bar styles
			create progress_fill_style.make
			progress_fill_style.set_foreground (c_cyan)
			create progress2_fill_style.make
			progress2_fill_style.set_foreground (c_yellow)
			create progress3_fill_style.make
			progress3_fill_style.set_foreground (c_magenta)
			create progress_empty_style.make
			progress_empty_style.set_foreground (c_gray)

			-- List styles
			create list_item_style.make
			list_item_style.set_foreground (c_white)
			create list_selected_style.make
			list_selected_style.set_foreground (c_cyan)
			list_selected_style.set_reverse (True)
			list_selected_style.set_bold (True)

			-- Radio button styles (blue theme)
			create radio_border_style.make
			radio_border_style.set_foreground (c_blue)
			create radio_title_style.make
			radio_title_style.set_foreground (c_blue)
			radio_title_style.set_bold (True)
			create radio_style.make
			radio_style.set_foreground (c_cyan)
			create radio_focused_style.make
			radio_focused_style.set_foreground (c_cyan)
			radio_focused_style.set_reverse (True)
			radio_focused_style.set_bold (True)

			-- Combo box styles (orange/yellow theme)
			create combo_border_style.make
			combo_border_style.set_foreground (c_yellow)
			create combo_title_style.make
			combo_title_style.set_foreground (c_yellow)
			combo_title_style.set_bold (True)
			create combo_style.make
			combo_style.set_foreground (c_white)
			create combo_focused_style.make
			combo_focused_style.set_foreground (c_yellow)
			combo_focused_style.set_reverse (True)

			-- Separator style
			create separator_style.make
			separator_style.set_foreground (c_gray)
		end

	-- Style attributes
	header_style: TUI_STYLE
	label_style: TUI_STYLE
	status_style: TUI_STYLE
	footer_style: TUI_STYLE

	form_border_style: TUI_STYLE
	form_title_style: TUI_STYLE
	progress_border_style: TUI_STYLE
	progress_title_style: TUI_STYLE
	list_border_style: TUI_STYLE
	list_title_style: TUI_STYLE

	input_style: TUI_STYLE
	input_focused_style: TUI_STYLE

	checkbox_style: TUI_STYLE
	checkbox_focused_style: TUI_STYLE

	button_style: TUI_STYLE
	button_focused_style: TUI_STYLE
	button_pressed_style: TUI_STYLE

	quit_button_style: TUI_STYLE
	quit_button_focused_style: TUI_STYLE
	quit_button_pressed_style: TUI_STYLE

	progress_fill_style: TUI_STYLE
	progress2_fill_style: TUI_STYLE
	progress3_fill_style: TUI_STYLE
	progress_empty_style: TUI_STYLE

	list_item_style: TUI_STYLE
	list_selected_style: TUI_STYLE

	radio_border_style: TUI_STYLE
	radio_title_style: TUI_STYLE
	radio_style: TUI_STYLE
	radio_focused_style: TUI_STYLE

	combo_border_style: TUI_STYLE
	combo_title_style: TUI_STYLE
	combo_style: TUI_STYLE
	combo_focused_style: TUI_STYLE

	separator_style: TUI_STYLE

feature {NONE} -- Event Handlers

	setup_handlers
			-- Setup event handlers.
		do
			submit_button.set_on_click (agent on_submit)
			start_button.set_on_click (agent on_start_progress)
			quit_button.set_on_click (agent on_quit)
			demo_list.set_on_select (agent on_list_select)

			checkbox1.set_on_change (agent on_checkbox1_change)
			checkbox2.set_on_change (agent on_checkbox2_change)

			radio_group.set_on_change (agent on_radio_change)
			theme_combo.set_on_change (agent on_theme_change)

			app.set_on_tick (agent on_tick)
		end

	on_submit
			-- Handle form submission.
		local
			msg: STRING_32
		do
			create msg.make (50)
			msg.append ("Form: ")
			msg.append (name_field.text)
			if checkbox1.is_checked then
				msg.append (" [Remember]")
			end
			if checkbox2.is_checked then
				msg.append (" [Newsletter]")
			end
			status_label.set_text (msg)
		end

	on_start_progress
			-- Start/stop progress animation.
		do
			progress_running := not progress_running
			if progress_running then
				start_button.set_label ("Stop")
				progress1.set_value (0)
			else
				start_button.set_label ("Start")
			end
		end

	on_quit
			-- Quit application.
		do
			app.quit
		end

	on_list_select (index: INTEGER)
			-- Handle list selection.
		local
			l_text: STRING_32
		do
			if attached demo_list.selected_item as l_item then
				create l_text.make (20)
				l_text.append ("Selected: ")
				l_text.append (l_item)
				list_status.set_text (l_text)
			end
		end

	on_checkbox1_change (checked: BOOLEAN)
			-- Handle checkbox 1 change.
		do
			if checked then
				status_label.set_text ("Remember me: ON")
			else
				status_label.set_text ("Remember me: OFF")
			end
		end

	on_checkbox2_change (checked: BOOLEAN)
			-- Handle checkbox 2 change.
		do
			if checked then
				status_label.set_text ("Newsletter: ON")
			else
				status_label.set_text ("Newsletter: OFF")
			end
		end

	on_radio_change (index: INTEGER)
			-- Handle radio button change.
		local
			mode_name: STRING
		do
			inspect index
			when 1 then mode_name := "Normal"
			when 2 then mode_name := "Compact"
			when 3 then mode_name := "Detailed"
			else mode_name := "Unknown"
			end
			status_label.set_text ("Display: " + mode_name)
		end

	on_theme_change (index: INTEGER)
			-- Handle theme combo change.
		do
			if attached theme_combo.selected_text as sel then
				status_label.set_text ({STRING_32} "Theme: " + sel)
			end
		end

feature {NONE} -- Animation

	progress_running: BOOLEAN
			-- Is progress animation running?

	tick_count: INTEGER
			-- Frame counter.

	on_tick
			-- Called each frame.
		do
			tick_count := tick_count + 1

			if progress_running then
				-- Animate progress bars
				if tick_count \\ 3 = 0 then  -- Every 3 frames
					progress1.increment (1)
					if progress1.current_value >= 100 then
						progress1.set_value (0)
					end

					progress2.increment (2)
					if progress2.current_value >= 100 then
						progress2.set_value (0)
					end
				end
			end

			-- Always animate indeterminate
			if tick_count \\ 2 = 0 then
				progress3.tick
			end
		end

feature {NONE} -- Execution

	run_demo
			-- Run the demo application.
		do
			log.info ("run_demo: calling app.initialize")
			app.initialize
			log.info ("run_demo: app.initialize complete, starting event loop")
			log.info ("run_demo: root_box.x=" + root_box.x.out + " root_box.y=" + root_box.y.out)
			log.info ("run_demo: form_box.x=" + form_box.x.out + " form_box.absolute_x=" + form_box.absolute_x.out)
			log.info ("run_demo: progress_box.x=" + progress_box.x.out + " progress_box.absolute_x=" + progress_box.absolute_x.out)
			log.info ("run_demo: list_box.x=" + list_box.x.out + " list_box.absolute_x=" + list_box.absolute_x.out)
			log.info ("run_demo: content_hbox children count=" + content_hbox.children.count.out)
			app.run
			log.info ("run_demo: event loop ended")
			app.shutdown
		end

feature {NONE} -- Box Drawing Helpers

	double_box_top (w: INTEGER): STRING_32
			-- Create top border: ╔═══...═══╗
		local
			i: INTEGER
		do
			create Result.make (w + 2)
			Result.append_character ('%/0x2554/')  -- ╔
			from i := 1 until i > w loop
				Result.append_character ('%/0x2550/')  -- ═
				i := i + 1
			end
			Result.append_character ('%/0x2557/')  -- ╗
		end

	double_box_middle (text: STRING; w: INTEGER): STRING_32
			-- Create middle row: ║  text  ║
		local
			pad_left, pad_right: INTEGER
		do
			create Result.make (w + 2)
			Result.append_character ('%/0x2551/')  -- ║
			pad_left := (w - text.count) // 2
			pad_right := w - text.count - pad_left
			Result.append (create {STRING_32}.make_filled (' ', pad_left))
			Result.append_string_general (text)
			Result.append (create {STRING_32}.make_filled (' ', pad_right))
			Result.append_character ('%/0x2551/')  -- ║
		end

feature {NONE} -- Logging Helpers

	log_string32_codes (a_label: STRING; s: STRING_32)
			-- Log first 5 characters of STRING_32 with their codepoints.
		local
			i, limit: INTEGER
			msg: STRING
			code: NATURAL_32
		do
			create msg.make (200)
			msg.append (a_label)
			msg.append (" (count=")
			msg.append (s.count.out)
			msg.append ("): ")
			limit := s.count.min (5)
			from i := 1 until i > limit loop
				code := s.item (i).natural_32_code
				msg.append ("[")
				msg.append (i.out)
				msg.append ("]=U+")
				msg.append (code.to_hex_string)
				msg.append (" ")
				i := i + 1
			end
			if s.count > 5 then
				msg.append ("...")
			end
			log.info (msg)
		end

end
