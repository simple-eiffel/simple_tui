note
	description: "[
		TUI_APPLICATION - Main TUI application controller

		Manages:
		- Terminal backend initialization/shutdown
		- Event loop (keyboard, mouse, resize)
		- Widget tree rendering
		- Focus management
		- Double buffering and efficient updates
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_APPLICATION

create
	make

feature {NONE} -- Initialization

	make
			-- Create application.
		do
			is_running := False
			target_fps := 30
			create focusable_widgets.make (10)
			focused_widget_index := 0
			create shortcuts.make (10)
		ensure
			not_running: not is_running
		end

feature -- Access

	backend: detachable TUI_BACKEND
			-- Terminal backend.

	buffer: detachable TUI_BUFFER
			-- Double buffer.

	root: detachable TUI_WIDGET
			-- Root widget.

	menu_bar: detachable TUI_MENU_BAR
			-- Optional menu bar at top.

	modal_widget: detachable TUI_WIDGET
			-- Modal widget that captures all input when visible.

	is_running: BOOLEAN
			-- Is event loop running?

	target_fps: INTEGER
			-- Target frames per second.

	focused_widget: detachable TUI_WIDGET
			-- Currently focused widget.

	on_tick: detachable PROCEDURE
			-- Called each frame.

	on_resize: detachable PROCEDURE [INTEGER, INTEGER]
			-- Called on terminal resize.

	on_quit: detachable PROCEDURE
			-- Called before quit.

feature -- Configuration

	set_root (a_widget: TUI_WIDGET)
			-- Set root widget.
		require
			widget_exists: a_widget /= Void
		do
			root := a_widget
			collect_focusable_widgets
		ensure
			root_set: root = a_widget
		end

	set_menu_bar (a_menu_bar: TUI_MENU_BAR)
			-- Set menu bar.
		require
			menu_bar_exists: a_menu_bar /= Void
		do
			menu_bar := a_menu_bar
			-- Add menu bar to focusable widgets
			if a_menu_bar.is_focusable and not focusable_widgets.has (a_menu_bar) then
				focusable_widgets.put_front (a_menu_bar)
			end
		ensure
			menu_bar_set: menu_bar = a_menu_bar
		end

	set_target_fps (a_fps: INTEGER)
			-- Set target frame rate.
		require
			valid_fps: a_fps > 0 and a_fps <= 120
		do
			target_fps := a_fps
		ensure
			fps_set: target_fps = a_fps
		end

	set_on_tick (a_handler: PROCEDURE)
			-- Set tick handler.
		do
			on_tick := a_handler
		ensure
			handler_set: on_tick = a_handler
		end

	set_on_resize (a_handler: PROCEDURE [INTEGER, INTEGER])
			-- Set resize handler.
		do
			on_resize := a_handler
		ensure
			handler_set: on_resize = a_handler
		end

	set_on_quit (a_handler: PROCEDURE)
			-- Set quit handler.
		do
			on_quit := a_handler
		ensure
			handler_set: on_quit = a_handler
		end

	set_modal (a_widget: detachable TUI_WIDGET)
			-- Set modal widget (captures all input when visible).
		do
			modal_widget := a_widget
		ensure
			modal_set: modal_widget = a_widget
		end

	clear_modal
			-- Clear modal widget.
		do
			modal_widget := Void
		ensure
			modal_cleared: modal_widget = Void
		end

feature -- Keyboard Shortcuts

	register_shortcut (a_key: CHARACTER_32; ctrl, alt, shift: BOOLEAN; handler: PROCEDURE)
			-- Register a global keyboard shortcut.
			-- Example: register_shortcut ('s', True, False, False, agent on_save) for Ctrl+S
		local
			shortcut_key: STRING_32
		do
			shortcut_key := make_shortcut_key (a_key, ctrl, alt, shift)
			shortcuts.force (handler, shortcut_key)
		end

	unregister_shortcut (a_key: CHARACTER_32; ctrl, alt, shift: BOOLEAN)
			-- Remove a registered shortcut.
		local
			shortcut_key: STRING_32
		do
			shortcut_key := make_shortcut_key (a_key, ctrl, alt, shift)
			shortcuts.remove (shortcut_key)
		end

	has_shortcut (a_key: CHARACTER_32; ctrl, alt, shift: BOOLEAN): BOOLEAN
			-- Is shortcut registered?
		local
			shortcut_key: STRING_32
		do
			shortcut_key := make_shortcut_key (a_key, ctrl, alt, shift)
			Result := shortcuts.has (shortcut_key)
		end

feature -- Focus Management

	focus_next
			-- Move focus to next focusable widget.
		do
			if not focusable_widgets.is_empty then
				if attached focused_widget as fw then
					fw.unfocus
				end
				focused_widget_index := ((focused_widget_index) \\ focusable_widgets.count) + 1
				focused_widget := focusable_widgets.i_th (focused_widget_index)
				if attached focused_widget as fw then
					fw.focus_from_next
				end
			end
		end

	focus_previous
			-- Move focus to previous focusable widget.
		do
			if not focusable_widgets.is_empty then
				if attached focused_widget as fw then
					fw.unfocus
				end
				focused_widget_index := focused_widget_index - 1
				if focused_widget_index < 1 then
					focused_widget_index := focusable_widgets.count
				end
				focused_widget := focusable_widgets.i_th (focused_widget_index)
				if attached focused_widget as fw then
					fw.focus_from_previous
				end
			end
		end

	set_focus (a_widget: TUI_WIDGET)
			-- Set focus to specific widget.
		require
			widget_exists: a_widget /= Void
			is_focusable: a_widget.is_focusable
		local
			i: INTEGER
		do
			if attached focused_widget as fw then
				fw.unfocus
			end

			-- Find widget in focusable list
			from i := 1 until i > focusable_widgets.count loop
				if focusable_widgets.i_th (i) = a_widget then
					focused_widget_index := i
					i := focusable_widgets.count + 1  -- Exit loop
				else
					i := i + 1
				end
			end

			focused_widget := a_widget
			a_widget.focus
		ensure
			widget_focused: focused_widget = a_widget
		end

feature -- Lifecycle

	initialize
			-- Initialize terminal and prepare for running.
		do
			create {TUI_BACKEND_WINDOWS} backend.make
			if attached backend as b then
				b.initialize
				create buffer.make (b.width, b.height)
			end

			-- Position menu bar if present
			if attached menu_bar as mb and attached backend as b then
				mb.set_position (1, 1)
				mb.set_size (b.width, 1)
			end

			-- Layout root widget (below menu bar if present)
			if attached root as r and attached backend as b then
				if attached menu_bar then
					r.set_bounds (1, 2, b.width, b.height - 1)
				else
					r.set_bounds (1, 1, b.width, b.height)
				end
				r.layout
			end

			-- Focus first widget
			if not focusable_widgets.is_empty then
				focused_widget_index := 1
				focused_widget := focusable_widgets.first
				if attached focused_widget as fw then
					fw.focus
				end
			end
		ensure
			backend_ready: backend /= Void
			buffer_ready: buffer /= Void
		end

	run
			-- Start the event loop.
		require
			initialized: backend /= Void and buffer /= Void
			has_root: root /= Void
		do
			is_running := True
			event_loop
		ensure
			stopped: not is_running
		end

	quit
			-- Stop the event loop.
		do
			is_running := False
		ensure
			not_running: not is_running
		end

	shutdown
			-- Clean up terminal.
		do
			if attached on_quit as handler then
				handler.call (Void)
			end
			if attached backend as b then
				b.shutdown
			end
		end

feature {NONE} -- Event Loop

	event_loop
			-- Main event loop.
		local
			event: detachable TUI_EVENT
			frame_time_ms: INTEGER
		do
			frame_time_ms := 1000 // target_fps

			from until not is_running loop
				-- Process events
				if attached backend as b then
					event := b.poll_event
					if event /= Void then
						handle_event (event)
					end
				end

				-- Tick callback
				if attached on_tick as handler then
					handler.call (Void)
				end

				-- Render
				render_frame
			end
		end

	handle_event (a_event: TUI_EVENT)
			-- Process input event.
		require
			event_exists: a_event /= Void
		local
			handled: BOOLEAN
		do
			if a_event.is_resize_event then
				handle_resize (a_event)
			elseif a_event.is_key_event or a_event.is_char_event then
				log_key_event (a_event)
				handled := handle_key (a_event)
			elseif a_event.is_mouse_event then
				log_mouse_event (a_event)
				handled := handle_mouse (a_event)
			end
		end

	log_key_event (a_event: TUI_EVENT)
			-- Log key event details to file.
		local
			l_file: PLAIN_TEXT_FILE
			msg: STRING
		do
			create msg.make (150)
			msg.append ("KEY: ")

			-- Describe the key
			if a_event.is_key_event then
				msg.append ("keycode=")
				msg.append (a_event.key.out)
				if a_event.key = 18 then msg.append ("(Alt)") end
				if a_event.key = 16 then msg.append ("(Shift)") end
				if a_event.key = 17 then msg.append ("(Ctrl)") end
			else
				msg.append ("char='")
				if a_event.char >= '%/32/' and a_event.char <= '%/126/' then
					msg.append_character (a_event.char.to_character_8)
				else
					msg.append ("\")
					msg.append (a_event.char.natural_32_code.out)
				end
				msg.append ("'")
			end

			-- Modifiers
			if a_event.has_shift then msg.append (" +SHIFT") end
			if a_event.has_ctrl then msg.append (" +CTRL") end
			if a_event.has_alt then msg.append (" +ALT") end

			-- Special key detection
			if a_event.is_enter then msg.append (" [ENTER]") end
			if a_event.is_escape then msg.append (" [ESC]") end
			if a_event.is_tab then msg.append (" [TAB]") end
			if a_event.is_up then msg.append (" [UP]") end
			if a_event.is_down then msg.append (" [DOWN]") end
			if a_event.is_left then msg.append (" [LEFT]") end
			if a_event.is_right then msg.append (" [RIGHT]") end

			create l_file.make_open_append ("tui_demo.log")
			if l_file.is_open_write then
				l_file.put_string (msg)
				l_file.put_new_line
				l_file.close
			end
		end

	log_mouse_event (a_event: TUI_EVENT)
			-- Log mouse event details to file.
		local
			l_file: PLAIN_TEXT_FILE
			msg: STRING
		do
			create msg.make (100)
			msg.append ("MOUSE: x=")
			msg.append (a_event.mouse_x.out)
			msg.append (" y=")
			msg.append (a_event.mouse_y.out)
			msg.append (" btn=")
			msg.append (a_event.mouse_button.out)
			if a_event.is_mouse_press then msg.append (" PRESS") end
			if a_event.is_mouse_release then msg.append (" RELEASE") end

			create l_file.make_open_append ("tui_demo.log")
			if l_file.is_open_write then
				l_file.put_string (msg)
				l_file.put_new_line
				l_file.close
			end
		end

	handle_key (a_event: TUI_EVENT): BOOLEAN
			-- Handle key event. Return True if handled.
		do
			-- Check for quit (Ctrl+Q or Ctrl+C) - always available
			if a_event.has_ctrl then
				if a_event.char = 'q' or a_event.char = 'Q' or a_event.char = '%/3/' then
					quit
					Result := True
				end
			end

			-- Modal widget captures all input when visible
			if not Result and attached modal_widget as mw then
				if mw.is_visible then
					Result := mw.handle_key (a_event)
					-- Modal consumes all key events
					Result := True
				end
			end

			if not Result then
				-- Check registered global shortcuts
				if not Result then
					Result := try_shortcut (a_event)
				end

				-- Let menu bar handle if open
				if not Result and attached menu_bar as mb then
					if mb.is_menu_open then
						Result := mb.handle_key (a_event)
					end
				end

				-- Check Alt+key for menu shortcuts
				if not Result and a_event.has_alt and attached menu_bar as mb then
					Result := mb.handle_key (a_event)
				end

				-- Check Alt+key for button/widget hotkeys (global activation)
				if not Result and a_event.has_alt and not a_event.has_ctrl then
					Result := try_widget_hotkey (a_event)
				end

				-- Dispatch to focused widget FIRST (widgets may handle Tab internally)
				if not Result and attached focused_widget as fw then
					Result := fw.handle_key (a_event)
				end

				-- Check for Tab (focus cycling) only if widget didn't handle it
				if not Result and a_event.is_tab then
					if a_event.has_shift then
						focus_previous
					else
						focus_next
					end
					Result := True
				end
			end
		end

	handle_mouse (a_event: TUI_EVENT): BOOLEAN
			-- Handle mouse event. Return True if handled.
		local
			target: detachable TUI_WIDGET
		do
			-- Modal widget captures all mouse input when visible
			if attached modal_widget as mw then
				if mw.is_visible then
					Result := mw.handle_mouse (a_event)
					-- Modal consumes all mouse events
					Result := True
				end
			end

			if not Result then
				-- Check menu bar first
				if attached menu_bar as mb then
					if a_event.mouse_y = 1 or mb.is_menu_open then
						Result := mb.handle_mouse (a_event)
					end
				end

				-- Find widget under mouse
				if not Result and attached root as r then
					target := r.find_widget_at (a_event.mouse_x, a_event.mouse_y)
					if attached target as t then
						-- Focus clicked widget if focusable
						if a_event.is_mouse_press and a_event.mouse_button = 1 then
							if t.is_focusable and t /= focused_widget then
								set_focus (t)
							end
						end
						Result := t.handle_mouse (a_event)
					end
				end
			end
		end

	handle_resize (a_event: TUI_EVENT)
			-- Handle terminal resize.
		do
			if attached backend as b and attached buffer as buf then
				buf.resize (a_event.resize_width, a_event.resize_height)

				-- Resize root widget
				if attached root as r then
					r.set_size (a_event.resize_width, a_event.resize_height)
					r.layout
				end

				-- Notify handler
				if attached on_resize as handler then
					handler.call ([a_event.resize_width, a_event.resize_height])
				end
			end
		end

	render_frame
			-- Render one frame.
		local
			changed: LIST [TUPLE [x, y: INTEGER; cell: TUI_CELL]]
			i: INTEGER
			l_tuple: TUPLE [x, y: INTEGER; cell: TUI_CELL]
		do
			if attached buffer as buf and attached backend as b then
				-- Clear next buffer
				buf.clear

				-- Render menu bar
				if attached menu_bar as mb then
					mb.render (buf)
				end

				-- Render widget tree
				if attached root as r then
					if r.is_visible then
						r.render (buf)
					end
				end

				-- Render open menu dropdown LAST (on top of everything)
				if attached menu_bar as mb and then mb.is_menu_open then
					if attached mb.current_menu as dropdown then
						dropdown.render (buf)
					end
				end

				-- Render modal widget on top of everything
				if attached modal_widget as mw then
					if mw.is_visible then
						mw.render (buf)
					end
				end

				-- Get changed cells
				changed := buf.changed_cells

				-- Write changes to terminal
				from i := 1 until i > changed.count loop
					l_tuple := changed.i_th (i)
					b.write_cell (l_tuple.x, l_tuple.y, l_tuple.cell)
					i := i + 1
				end

				-- Sync buffers
				buf.sync

				-- Flush output
				b.flush
			end
		end

feature {NONE} -- Focus Collection

	focusable_widgets: ARRAYED_LIST [TUI_WIDGET]
			-- All focusable widgets in tree order.

	focused_widget_index: INTEGER
			-- Index of currently focused widget in focusable_widgets.

feature {NONE} -- Keyboard Shortcuts Implementation

	shortcuts: HASH_TABLE [PROCEDURE, STRING_32]
			-- Registered global keyboard shortcuts.

	make_shortcut_key (a_key: CHARACTER_32; ctrl, alt, shift: BOOLEAN): STRING_32
			-- Create unique key for shortcut lookup.
		do
			create Result.make (10)
			if ctrl then Result.append ("C-") end
			if alt then Result.append ("A-") end
			if shift then Result.append ("S-") end
			Result.append_character (a_key.as_lower)
		end

	try_shortcut (a_event: TUI_EVENT): BOOLEAN
			-- Try to execute registered shortcut. Return True if found and executed.
		local
			shortcut_key: STRING_32
		do
			shortcut_key := make_shortcut_key (a_event.char, a_event.has_ctrl, a_event.has_alt, a_event.has_shift)
			if shortcuts.has (shortcut_key) then
				if attached shortcuts.item (shortcut_key) as handler then
					handler.call (Void)
					Result := True
				end
			end
		end

	try_widget_hotkey (a_event: TUI_EVENT): BOOLEAN
			-- Try to activate a widget via Alt+key hotkey.
			-- Searches widget tree for buttons with matching shortcut_key.
		local
			key_lower: CHARACTER_32
		do
			key_lower := a_event.char.as_lower
			if attached root as r then
				Result := try_hotkey_in_widget (r, key_lower)
			end
		end

	try_hotkey_in_widget (a_widget: TUI_WIDGET; key_lower: CHARACTER_32): BOOLEAN
			-- Recursively search for button with matching hotkey.
		local
			i: INTEGER
		do
			-- Check if this widget is a TUI_BUTTON with matching shortcut
			if attached {TUI_BUTTON} a_widget as btn then
				if btn.is_visible and btn.shortcut_key.as_lower = key_lower then
					btn.click
					Result := True
				end
			end

			-- Recurse into children if not found
			if not Result then
				from i := 1 until i > a_widget.children.count or Result loop
					Result := try_hotkey_in_widget (a_widget.children.i_th (i), key_lower)
					i := i + 1
				end
			end
		end

	collect_focusable_widgets
			-- Collect all focusable widgets from root.
		do
			focusable_widgets.wipe_out
			if attached root as r then
				collect_from_widget (r)
			end
		end

	collect_from_widget (a_widget: TUI_WIDGET)
			-- Recursively collect focusable widgets.
		local
			i: INTEGER
		do
			if a_widget.is_focusable then
				focusable_widgets.extend (a_widget)
			end
			from i := 1 until i > a_widget.children.count loop
				collect_from_widget (a_widget.children.i_th (i))
				i := i + 1
			end
		end

invariant
	focusable_widgets_exist: focusable_widgets /= Void
	shortcuts_exist: shortcuts /= Void
	valid_fps: target_fps > 0 and target_fps <= 120

end
