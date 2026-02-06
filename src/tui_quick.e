note
	description: "[
		TUI_QUICK - Fluent factory for rapid TUI application construction

		Provides a simple, chainable API for building TUI applications
		without manually managing widget hierarchies.

		Usage:
			create tui.make ("My App")
			q := tui.menu ("&File")
					.item ("&New", agent on_new)
					.item ("E&xit", agent on_exit)
			q := tui.vbox.gap (1)
					.label ("Welcome")
					.text_field ("Name").named ("name")
					.hbox
						.button ("&Ok", agent on_ok)
						.button ("&Cancel", agent on_cancel)
					.end_box
				.end_box
			tui.run
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_QUICK

create
	make

feature {NONE} -- Initialization

	make (a_title: READABLE_STRING_GENERAL)
			-- Create application with title.
		do
			title := a_title.to_string_32
			create app.make
			create menu_bar.make (80)
			create container_stack.make (5)
			create named_widgets.make (10)

			-- Create root container (TUI_VBOX)
			create root_vbox.make (80, 25)
			root_vbox.set_gap (0)
			container_stack.extend (root_vbox)
			current_vbox := root_vbox
		ensure
			title_set: title.same_string_general (a_title)
		end

feature -- Access

	title: STRING_32
			-- Application title.

	app: TUI_APPLICATION
			-- The application instance.

	menu_bar: TUI_MENU_BAR
			-- Menu bar.

	root_vbox: TUI_VBOX
			-- Root container.

feature -- Widget Access

	last_widget: detachable TUI_WIDGET
			-- Last created widget.

	last_label: detachable TUI_LABEL
			-- Last created label.

	last_button: detachable TUI_BUTTON
			-- Last created button.

	last_text_field: detachable TUI_TEXT_FIELD
			-- Last created text field.

	last_checkbox: detachable TUI_CHECKBOX
			-- Last created checkbox.

	last_list: detachable TUI_LIST
			-- Last created list.

	last_progress: detachable TUI_PROGRESS
			-- Last created progress bar.

	widget (a_name: READABLE_STRING_GENERAL): detachable TUI_WIDGET
			-- Get widget by name.
		do
			Result := named_widgets.item (a_name.to_string_32)
		end

	text_field_named (a_name: READABLE_STRING_GENERAL): detachable TUI_TEXT_FIELD
			-- Get text field by name.
		do
			if attached {TUI_TEXT_FIELD} widget (a_name) as al_tf then
				Result := l_tf
			end
		end

	list_named (a_name: READABLE_STRING_GENERAL): detachable TUI_LIST
			-- Get list by name.
		do
			if attached {TUI_LIST} widget (a_name) as al_l then
				Result := l_l
			end
		end

feature -- Application

	run
			-- Initialize and start the application.
		do
			logger.debug_log ("TUI_QUICK.run: root_vbox.w=" + root_vbox.width.out + " h=" + root_vbox.height.out + " children=" + root_vbox.children.count.out)
			app.set_menu_bar (menu_bar)
			app.set_root (root_vbox)
			logger.debug_log ("TUI_QUICK.run: calling app.initialize")
			app.initialize
			logger.debug_log ("TUI_QUICK.run: after initialize, calling app.run")
			app.run
			app.shutdown
		end

	logger: SIMPLE_LOGGER
			-- Shared logger instance.
		once
			create Result.make_to_file ("task_manager.log")
			Result.set_level (Result.Level_debug)
		end

	quit
			-- Stop the application.
		do
			app.quit
		end

feature -- Menu Building

	l_menu (a_title: READABLE_STRING_GENERAL): TUI_QUICK
			-- Add a menu to the menu bar.
		local
			l_menu: TUI_MENU
		do
			create l_menu.make_with_title (a_title)
			current_menu := l_menu
			menu_bar.add_menu (l_menu)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	l_item (a_label: READABLE_STRING_GENERAL; a_action: PROCEDURE): TUI_QUICK
			-- Add item to current menu.
		local
			l_item: TUI_MENU_ITEM
		do
			if attached current_menu as al_m then
				create l_item.make_with_text (a_label)
				l_item.set_on_select (a_action)
				al_m.add_item (l_item)
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	separator: TUI_QUICK
			-- Add separator to current menu.
		do
			if attached current_menu as al_m then
				al_m.add_separator
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Layout Building

	vbox: TUI_QUICK
			-- Start a vertical box container.
		local
			l_box: TUI_VBOX
		do
			create l_box.make (80, 25)
			l_box.set_gap (1)
			add_to_current (l_box)
			container_stack.extend (l_box)
			current_vbox := l_box
			current_hbox := Void
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	hbox: TUI_QUICK
			-- Start a horizontal box container.
		local
			l_box: TUI_HBOX
		do
			create l_box.make (80, 1)
			l_box.set_gap (2)
			add_to_current (l_box)
			container_stack.extend (l_box)
			current_hbox := l_box
			current_vbox := Void
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	end_box: TUI_QUICK
			-- End current container and return to parent.
		do
			if container_stack.count > 1 then
				container_stack.finish
				container_stack.remove
				container_stack.finish
				if attached {TUI_VBOX} container_stack.item as al_v then
					current_vbox := v
					current_hbox := Void
				elseif attached {TUI_HBOX} container_stack.item as al_h then
					current_hbox := h
					current_vbox := Void
				end
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	gap (a_size: INTEGER): TUI_QUICK
			-- Set gap for current container.
		do
			if attached current_vbox as al_box then
				al_box.set_gap (a_size)
			elseif attached current_hbox as al_box then
				al_box.set_gap (a_size)
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Widget Factory

	label (a_text: READABLE_STRING_GENERAL): TUI_QUICK
			-- Add a label widget.
		local
			l_l: TUI_LABEL
		do
			create l_l.make_with_text (a_text)
			add_to_current (l_l)
			last_widget := l_l
			last_label := l_l
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	button (a_label: READABLE_STRING_GENERAL; a_action: PROCEDURE): TUI_QUICK
			-- Add a button widget.
		local
			l_b: TUI_BUTTON
		do
			create l_b.make (a_label)
			l_b.click_actions.extend (a_action)
			add_to_current (l_b)
			last_widget := l_b
			last_button := l_b
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	text_field (a_placeholder: READABLE_STRING_GENERAL): TUI_QUICK
			-- Add a text field widget.
		local
			l_tf: TUI_TEXT_FIELD
		do
			create l_tf.make (20)
			-- placeholder could be shown when empty
			add_to_current (l_tf)
			last_widget := l_tf
			last_text_field := l_tf
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	password_field (a_placeholder: READABLE_STRING_GENERAL): TUI_QUICK
			-- Add a password field widget.
		local
			l_tf: TUI_TEXT_FIELD
		do
			create l_tf.make (20)
			l_tf.set_password (True)
			add_to_current (l_tf)
			last_widget := l_tf
			last_text_field := l_tf
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	checkbox (a_label: READABLE_STRING_GENERAL): TUI_QUICK
			-- Add a checkbox widget.
		local
			l_cb: TUI_CHECKBOX
		do
			create l_cb.make (a_label)
			add_to_current (l_cb)
			last_widget := l_cb
			last_checkbox := l_cb
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	list_box (a_height: INTEGER): TUI_QUICK
			-- Add a list widget.
		local
			l_l: TUI_LIST
		do
			create l_l.make (30, a_height)
			add_to_current (l_l)
			last_widget := l_l
			last_list := l_l
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	progress_bar (a_width: INTEGER): TUI_QUICK
			-- Add a progress bar widget.
		local
			l_p: TUI_PROGRESS
		do
			create l_p.make (a_width)
			add_to_current (l_p)
			last_widget := l_p
			last_progress := l_p
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Naming

	named (a_name: READABLE_STRING_GENERAL): TUI_QUICK
			-- Name the last created widget for later retrieval.
		do
			if attached last_widget as al_w then
				named_widgets.force (w, a_name.to_string_32)
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Screen Info

	screen_width: INTEGER
			-- Current screen width.
		do
			if attached app.backend as al_b then
				Result := al_b.width
			else
				Result := 80
			end
		end

	screen_height: INTEGER
			-- Current screen height.
		do
			if attached app.backend as al_b then
				Result := al_b.height
			else
				Result := 25
			end
		end

feature -- Modal Dialogs

	set_modal (a_widget: TUI_WIDGET)
			-- Set modal widget (captures all input).
		require
			widget_attached: a_widget /= Void
		do
			app.set_modal (a_widget)
		end

	clear_modal
			-- Clear modal widget.
		do
			app.clear_modal
		end

	show_message (a_title, a_message: READABLE_STRING_GENERAL)
			-- Show a message box with OK button.
		local
			l_msg: TUI_MESSAGE_BOX
		do
			create l_msg.make_ok (a_title, a_message)
			if attached app.backend as al_b then
				l_msg.show_centered (al_b.width, al_b.height)
			end
			app.set_modal (l_msg)
			-- Note: Modal will be cleared when message box closes
			l_msg.set_on_close (agent on_message_closed)
		end

	show_confirm (a_title, a_message: READABLE_STRING_GENERAL; a_on_result: PROCEDURE [BOOLEAN])
			-- Show a Yes/No confirmation dialog.
		local
			l_msg: TUI_MESSAGE_BOX
		do
			create l_msg.make_yes_no (a_title, a_message)
			if attached app.backend as al_b then
				l_msg.show_centered (al_b.width, al_b.height)
			end
			app.set_modal (l_msg)
			l_msg.set_on_close (agent on_confirm_closed (?, a_on_result))
		end

feature {NONE} -- Implementation

	current_vbox: detachable TUI_VBOX
			-- Current vbox container for adding widgets.

	current_hbox: detachable TUI_HBOX
			-- Current hbox container for adding widgets.

	current_menu: detachable TUI_MENU
			-- Current menu being built.

	container_stack: ARRAYED_LIST [TUI_WIDGET]
			-- Stack of containers for nesting.

	named_widgets: HASH_TABLE [TUI_WIDGET, STRING_32]
			-- Named widgets for retrieval.

	add_to_current (a_w: TUI_WIDGET)
			-- Add widget to current container.
		do
			if attached current_vbox as al_box then
				al_box.add_child (a_w)
			elseif attached current_hbox as al_box then
				al_box.add_child (a_w)
			end
		end

	on_message_closed (a_button_id: INTEGER)
			-- Handle message box closed.
		do
			app.clear_modal
		end

	on_confirm_closed (a_button_id: INTEGER; a_callback: PROCEDURE [BOOLEAN])
			-- Handle confirm dialog closed.
		do
			app.clear_modal
			a_callback.call ([a_button_id = {TUI_MESSAGE_BOX}.Button_yes])
		end

invariant
	app_exists: app /= Void
	menu_bar_exists: menu_bar /= Void
	root_vbox_exists: root_vbox /= Void
	container_stack_exists: container_stack /= Void
	named_widgets_exists: named_widgets /= Void

end
