note
	description: "[
		Interactive demo application for simple_tui library

		Showcases ALL widgets:
		- Labels, Buttons, Text fields
		- Checkboxes, Radio buttons
		- Lists, Combo boxes
		- Progress bars (animated)
		- Separators (horizontal/vertical)
		- Tabbed panels

		Layout containers:
		- TUI_BOX (bordered panels)
		- TUI_VBOX (vertical)
		- TUI_HBOX (horizontal)

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

	-- Menu bar
	menu_bar: TUI_MENU_BAR
	file_menu: TUI_MENU
	edit_menu: TUI_MENU
	view_menu: TUI_MENU
	help_menu: TUI_MENU

	-- Message box for dialogs
	message_box: detachable TUI_MESSAGE_BOX

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

	-- Right panel - Tabs demo
	tabs_panel: TUI_TABS
	tab1_content: TUI_BOX
	tab1_label: TUI_LABEL
	tab2_content: TUI_BOX
	tab2_label: TUI_LABEL
	tab2_button: TUI_BUTTON
	tab3_content: TUI_BOX
	tab3_progress: TUI_PROGRESS

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

			-- Root container (gap 0 to fit in 24-row terminal)
			create root_box.make (80, 22)  -- Leave room for menu bar
			root_box.set_gap (0)
			log.info ("root_box created: 80x22")

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
			create content_hbox.make (80, 11)
			content_hbox.set_gap (2)

			-- Left Panel: Form
			create form_box.make_with_title ("Login Form", 24, 9)
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
			create progress_box.make_with_title ("Progress", 24, 9)
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
			create list_box.make_with_title ("Items", 26, 9)
			list_box.set_padding (1)
			list_box.set_border_style (list_border_style)
			list_box.set_title_style (list_title_style)

			create demo_list.make (22, 4)
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

			-- Tabs panel
			create tabs_panel.make (24, 6)
			tabs_panel.set_normal_tab_style (tabs_normal_style)
			tabs_panel.set_selected_tab_style (tabs_selected_style)

			-- Tab 1: Info
			create tab1_content.make (24, 4)
			create tab1_label.make_with_text ("Welcome to TUI!")
			tab1_label.set_style (tabs_content_style)
			tab1_content.add_child (tab1_label)
			tab1_label.set_position (1, 1)
			tabs_panel.add_tab ("Info", tab1_content)

			-- Tab 2: Action
			create tab2_content.make (24, 4)
			create tab2_label.make_with_text ("Click below:")
			tab2_label.set_style (tabs_content_style)
			create tab2_button.make ("Tab Action")
			tab2_button.set_normal_style (button_style)
			tab2_button.set_focused_style (button_focused_style)
			tab2_content.add_child (tab2_label)
			tab2_content.add_child (tab2_button)
			tab2_label.set_position (1, 1)
			tab2_button.set_position (1, 2)
			tabs_panel.add_tab ("Action", tab2_content)

			-- Tab 3: Status
			create tab3_content.make (24, 4)
			create tab3_progress.make (18)
			tab3_progress.set_value (75)
			tab3_progress.set_show_percentage (True)
			tab3_progress.set_fill_style (progress_fill_style)
			tab3_progress.set_empty_style (progress_empty_style)
			tab3_content.add_child (tab3_progress)
			tab3_progress.set_position (1, 1)
			tabs_panel.add_tab ("Status", tab3_content)

			-- Add second row panels
			content_hbox2.add_child (radio_box)
			content_hbox2.add_child (combo_box_panel)
			content_hbox2.add_child (tabs_panel)

			root_box.add_child (content_hbox2)

			-- === Footer ===
			create footer_hbox.make (80, 1)
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

			-- Initialize menu placeholders (to satisfy compiler)
			create file_menu.make
			create edit_menu.make
			create view_menu.make
			create help_menu.make

			-- Create menu bar (after widgets so agents can reference them)
			create_menu_bar

			-- Set root with menu bar
			app.set_root (root_box)
			app.set_menu_bar (menu_bar)

			-- Register keyboard shortcuts
			register_shortcuts
		end

	register_shortcuts
			-- Register global keyboard shortcuts.
		do
			-- File menu shortcuts
			app.register_shortcut ('n', True, False, False, agent on_menu_new)      -- Ctrl+N
			app.register_shortcut ('o', True, False, False, agent on_menu_open)     -- Ctrl+O
			app.register_shortcut ('s', True, False, False, agent on_menu_save)     -- Ctrl+S

			-- Edit menu shortcuts
			app.register_shortcut ('z', True, False, False, agent on_menu_undo)     -- Ctrl+Z
			app.register_shortcut ('y', True, False, False, agent on_menu_redo)     -- Ctrl+Y
			app.register_shortcut ('x', True, False, False, agent on_menu_cut)      -- Ctrl+X
			app.register_shortcut ('c', True, False, False, agent on_menu_copy)     -- Ctrl+C
			app.register_shortcut ('v', True, False, False, agent on_menu_paste)    -- Ctrl+V
		end

	layout_form
			-- Position form widgets (compact layout for 9-row box).
		do
			name_label.set_position (1, 1)
			name_field.set_position (8, 1)  -- Same row as label
			password_label.set_position (1, 2)
			password_field.set_position (8, 2)  -- Same row as label
			checkbox1.set_position (1, 3)
			checkbox2.set_position (1, 4)
			submit_button.set_position (1, 5)
		end

	layout_progress
			-- Position progress widgets (compact layout for 9-row box).
		do
			progress_label.set_position (1, 1)
			progress1.set_position (1, 2)
			progress2.set_position (1, 3)
			progress3.set_position (1, 4)
			start_button.set_position (1, 5)
		end

	layout_list
			-- Position list widgets (compact layout for 9-row box).
		do
			demo_list.set_position (1, 1)
			list_status.set_position (1, 6)
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

			-- Tabs styles (green theme)
			create tabs_normal_style.make
			tabs_normal_style.set_foreground (c_gray)
			create tabs_selected_style.make
			tabs_selected_style.set_foreground (c_green)
			tabs_selected_style.set_reverse (True)
			tabs_selected_style.set_bold (True)
			create tabs_content_style.make
			tabs_content_style.set_foreground (c_white)

			-- Menu bar styles
			create menu_bar_style.make
			menu_bar_style.set_foreground (c_white)
			menu_bar_style.set_background (c_blue)
			create menu_bar_selected_style.make
			menu_bar_selected_style.set_foreground (c_blue)
			menu_bar_selected_style.set_background (c_white)
			menu_bar_selected_style.set_bold (True)
			create menu_item_style.make
			menu_item_style.set_foreground (c_white)
			menu_item_style.set_background (c_blue)
			create menu_item_selected_style.make
			menu_item_selected_style.set_foreground (c_blue)
			menu_item_selected_style.set_background (c_cyan)
			menu_item_selected_style.set_bold (True)
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

	tabs_normal_style: TUI_STYLE
	tabs_selected_style: TUI_STYLE
	tabs_content_style: TUI_STYLE

	menu_bar_style: TUI_STYLE
	menu_bar_selected_style: TUI_STYLE
	menu_item_style: TUI_STYLE
	menu_item_selected_style: TUI_STYLE

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
			tab2_button.set_on_click (agent on_tab_action)
			tabs_panel.set_on_tab_change (agent on_tab_change)

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
				apply_theme (sel)
				status_label.set_text ({STRING_32} "Theme: " + sel)
			end
		end

	apply_theme (theme_name: STRING_32)
			-- Apply the selected color theme.
		local
			c_fg, c_bg, c_accent, c_highlight, c_dim: TUI_COLOR
		do
			if theme_name.same_string ("Dark Mode") then
				-- Dark mode: Light text on dark backgrounds
				create c_fg.make_index (15)        -- White
				create c_bg.make_index (0)         -- Black
				create c_accent.make_index (14)    -- Cyan
				create c_highlight.make_index (11) -- Yellow
				create c_dim.make_index (8)        -- Gray
			elseif theme_name.same_string ("Light Mode") then
				-- Light mode: Dark text on light backgrounds
				create c_fg.make_index (0)         -- Black
				create c_bg.make_index (15)        -- White
				create c_accent.make_index (4)     -- Blue
				create c_highlight.make_index (1)  -- Red
				create c_dim.make_index (8)        -- Gray
			elseif theme_name.same_string ("High Contrast") then
				-- High contrast: Yellow on black
				create c_fg.make_index (11)        -- Yellow
				create c_bg.make_index (0)         -- Black
				create c_accent.make_index (15)    -- White
				create c_highlight.make_index (9)  -- Bright Red
				create c_dim.make_index (7)        -- Light Gray
			elseif theme_name.same_string ("Ocean Blue") then
				-- Ocean blue: Cyan/blue tones
				create c_fg.make_index (15)        -- White
				create c_bg.make_index (17)        -- Dark blue
				create c_accent.make_index (14)    -- Cyan
				create c_highlight.make_index (51) -- Aqua
				create c_dim.make_index (67)       -- Steel blue
			else
				-- Default theme
				create c_fg.make_index (15)        -- White
				create c_bg.make_index (0)         -- Black
				create c_accent.make_index (14)    -- Cyan
				create c_highlight.make_index (10) -- Green
				create c_dim.make_index (8)        -- Gray
			end

			-- Update header styles
			header_style.set_foreground (c_accent)
			label_style.set_foreground (c_fg)
			status_style.set_foreground (c_highlight)
			footer_style.set_foreground (c_accent)

			-- Update panel borders
			form_border_style.set_foreground (c_highlight)
			form_title_style.set_foreground (c_highlight)
			progress_border_style.set_foreground (c_accent)
			progress_title_style.set_foreground (c_accent)
			list_border_style.set_foreground (c_accent)
			list_title_style.set_foreground (c_accent)

			-- Update input styles
			input_style.set_foreground (c_fg)
			input_focused_style.set_foreground (c_accent)

			-- Update button styles
			button_style.set_foreground (c_highlight)
			button_focused_style.set_foreground (c_highlight)

			-- Update list styles
			list_item_style.set_foreground (c_fg)
			list_selected_style.set_foreground (c_accent)

			-- Update separator
			separator_style.set_foreground (c_dim)
		end

	on_tab_action
			-- Handle tab button click.
		do
			status_label.set_text ("Tab Action clicked!")
		end

	on_tab_change (index: INTEGER)
			-- Handle tab change.
		local
			tab_names: ARRAY [STRING]
		do
			tab_names := <<"Info", "Action", "Status">>
			if index >= 1 and index <= 3 then
				status_label.set_text ("Tab: " + tab_names [index])
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

feature {NONE} -- Menu Creation

	create_menu_bar
			-- Create and populate menu bar.
		local
			item: TUI_MENU_ITEM
		do
			create menu_bar.make (80)
			menu_bar.set_normal_style (menu_bar_style)
			menu_bar.set_selected_style (menu_bar_selected_style)

			-- File menu
			create file_menu.make_with_title ("&File")
			file_menu.set_normal_style (menu_item_style)
			file_menu.set_selected_style (menu_item_selected_style)
			create item.make_with_text_and_action ("&New", agent on_menu_new)
			file_menu.add_item (item)
			create item.make_with_text_and_action ("&Open", agent on_menu_open)
			file_menu.add_item (item)
			create item.make_with_text_and_action ("&Save", agent on_menu_save)
			file_menu.add_item (item)
			file_menu.add_separator
			create item.make_with_text_and_action ("E&xit", agent on_quit)
			file_menu.add_item (item)
			menu_bar.add_menu (file_menu)

			-- Edit menu
			create edit_menu.make_with_title ("&Edit")
			edit_menu.set_normal_style (menu_item_style)
			edit_menu.set_selected_style (menu_item_selected_style)
			create item.make_with_text_and_action ("&Undo", agent on_menu_undo)
			edit_menu.add_item (item)
			create item.make_with_text_and_action ("&Redo", agent on_menu_redo)
			edit_menu.add_item (item)
			edit_menu.add_separator
			create item.make_with_text_and_action ("Cu&t", agent on_menu_cut)
			edit_menu.add_item (item)
			create item.make_with_text_and_action ("&Copy", agent on_menu_copy)
			edit_menu.add_item (item)
			create item.make_with_text_and_action ("&Paste", agent on_menu_paste)
			edit_menu.add_item (item)
			menu_bar.add_menu (edit_menu)

			-- View menu
			create view_menu.make_with_title ("&View")
			view_menu.set_normal_style (menu_item_style)
			view_menu.set_selected_style (menu_item_selected_style)
			create item.make_with_text_and_action ("&Toolbar", agent on_menu_toolbar)
			view_menu.add_item (item)
			create item.make_with_text_and_action ("&Status Bar", agent on_menu_statusbar)
			view_menu.add_item (item)
			view_menu.add_separator
			create item.make_with_text_and_action ("&Refresh", agent on_menu_refresh)
			view_menu.add_item (item)
			menu_bar.add_menu (view_menu)

			-- Help menu
			create help_menu.make_with_title ("&Help")
			help_menu.set_normal_style (menu_item_style)
			help_menu.set_selected_style (menu_item_selected_style)
			create item.make_with_text_and_action ("&Documentation", agent on_menu_docs)
			help_menu.add_item (item)
			help_menu.add_separator
			create item.make_with_text_and_action ("&About", agent on_menu_about)
			help_menu.add_item (item)
			menu_bar.add_menu (help_menu)
		end

feature {NONE} -- Menu Handlers

	on_menu_new
		do
			show_message_box ("New File", "Create a new file?", True)
		end

	on_menu_open
		do
			show_message_box ("Open File", "Open an existing file?", True)
		end

	on_menu_save
		do
			show_message_box ("Save", "File saved successfully!", False)
		end

	on_menu_undo
		do
			show_message_box ("Undo", "Undo last action?", True)
		end

	on_menu_redo
		do
			show_message_box ("Redo", "Redo last action?", True)
		end

	on_menu_cut
		do
			show_message_box ("Cut", "Text cut to clipboard.", False)
		end

	on_menu_copy
		do
			show_message_box ("Copy", "Text copied to clipboard.", False)
		end

	on_menu_paste
		do
			show_message_box ("Paste", "Text pasted from clipboard.", False)
		end

	on_menu_toolbar
		do
			show_message_box ("Toolbar", "Toggle toolbar visibility?", True)
		end

	on_menu_statusbar
		do
			show_message_box ("Status Bar", "Toggle status bar?", True)
		end

	on_menu_refresh
		do
			show_message_box ("Refresh", "View refreshed!", False)
		end

	on_menu_docs
		do
			show_message_box ("Documentation", "Visit: simple-eiffel.github.io", False)
		end

	on_menu_about
		do
			show_message_box ("About", "simple_tui Demo v1.0", False)
		end

	show_message_box (a_title, a_message: STRING; with_cancel: BOOLEAN)
			-- Show a message box dialog.
		local
			mb: TUI_MESSAGE_BOX
		do
			if with_cancel then
				create mb.make_ok_cancel (a_title, a_message)
			else
				create mb.make_ok (a_title, a_message)
			end
			mb.set_on_close (agent on_message_box_close)
			mb.set_border_style (create {TUI_STYLE}.make)
			mb.border_style.set_foreground (create {TUI_COLOR}.make_index (14))  -- Cyan
			mb.set_button_selected_style (create {TUI_STYLE}.make)
			mb.button_selected_style.set_reverse (True)
			mb.button_selected_style.set_bold (True)
			if attached app.backend as b then
				mb.show_centered (b.width, b.height)
			end
			message_box := mb
			app.set_modal (mb)  -- Make dialog modal
		end

	on_message_box_close (button_id: INTEGER)
			-- Handle message box close.
		do
			if button_id = {TUI_MESSAGE_BOX}.Button_ok then
				status_label.set_text ("Dialog: OK clicked")
			elseif button_id = {TUI_MESSAGE_BOX}.Button_cancel then
				status_label.set_text ("Dialog: Cancel clicked")
			end
			message_box := Void
			app.clear_modal  -- Remove modal state
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
