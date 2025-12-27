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

	set_root (widget: TUI_WIDGET)
			-- Set root widget.
		require
			widget_exists: widget /= Void
		do
			root := widget
			collect_focusable_widgets
		ensure
			root_set: root = widget
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

	set_target_fps (fps: INTEGER)
			-- Set target frame rate.
		require
			valid_fps: fps > 0 and fps <= 120
		do
			target_fps := fps
		ensure
			fps_set: target_fps = fps
		end

	set_on_tick (handler: PROCEDURE)
			-- Set tick handler.
		do
			on_tick := handler
		ensure
			handler_set: on_tick = handler
		end

	set_on_resize (handler: PROCEDURE [INTEGER, INTEGER])
			-- Set resize handler.
		do
			on_resize := handler
		ensure
			handler_set: on_resize = handler
		end

	set_on_quit (handler: PROCEDURE)
			-- Set quit handler.
		do
			on_quit := handler
		ensure
			handler_set: on_quit = handler
		end

	set_modal (widget: detachable TUI_WIDGET)
			-- Set modal widget (captures all input when visible).
		do
			modal_widget := widget
		ensure
			modal_set: modal_widget = widget
		end

	clear_modal
			-- Clear modal widget.
		do
			modal_widget := Void
		ensure
			modal_cleared: modal_widget = Void
		end

feature -- Keyboard Shortcuts

	register_shortcut (key: CHARACTER_32; ctrl, alt, shift: BOOLEAN; handler: PROCEDURE)
			-- Register a global keyboard shortcut.
			-- Example: register_shortcut ('s', True, False, False, agent on_save) for Ctrl+S
		local
			shortcut_key: STRING_32
		do
			shortcut_key := make_shortcut_key (key, ctrl, alt, shift)
			shortcuts.force (handler, shortcut_key)
		end

	unregister_shortcut (key: CHARACTER_32; ctrl, alt, shift: BOOLEAN)
			-- Remove a registered shortcut.
		local
			shortcut_key: STRING_32
		do
			shortcut_key := make_shortcut_key (key, ctrl, alt, shift)
			shortcuts.remove (shortcut_key)
		end

	has_shortcut (key: CHARACTER_32; ctrl, alt, shift: BOOLEAN): BOOLEAN
			-- Is shortcut registered?
		local
			shortcut_key: STRING_32
		do
			shortcut_key := make_shortcut_key (key, ctrl, alt, shift)
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

	set_focus (widget: TUI_WIDGET)
			-- Set focus to specific widget.
		require
			widget_exists: widget /= Void
			is_focusable: widget.is_focusable
		local
			i: INTEGER
		do
			if attached focused_widget as fw then
				fw.unfocus
			end

			-- Find widget in focusable list
			from i := 1 until i > focusable_widgets.count loop
				if focusable_widgets.i_th (i) = widget then
					focused_widget_index := i
					i := focusable_widgets.count + 1  -- Exit loop
				else
					i := i + 1
				end
			end

			focused_widget := widget
			widget.focus
		ensure
			widget_focused: focused_widget = widget
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

	handle_event (event: TUI_EVENT)
			-- Process input event.
		require
			event_exists: event /= Void
		local
			handled: BOOLEAN
		do
			if event.is_resize_event then
				handle_resize (event)
			elseif event.is_key_event or event.is_char_event then
				log_key_event (event)
				handled := handle_key (event)
			elseif event.is_mouse_event then
				log_mouse_event (event)
				handled := handle_mouse (event)
			end
		end

	log_key_event (event: TUI_EVENT)
			-- Log key event details to file.
		local
			l_file: PLAIN_TEXT_FILE
			msg: STRING
		do
			create msg.make (100)
			msg.append ("KEY: type=")
			if event.is_key_event then
				msg.append ("key")
			else
				msg.append ("char")
			end
			msg.append (" key=")
			msg.append (event.key.out)
			msg.append (" char=")
			msg.append (event.char.natural_32_code.out)
			msg.append (" mods=")
			msg.append (event.modifiers.out)
			if event.has_shift then msg.append (" SHIFT") end
			if event.has_ctrl then msg.append (" CTRL") end
			if event.has_alt then msg.append (" ALT") end

			create l_file.make_open_append ("tui_demo.log")
			if l_file.is_open_write then
				l_file.put_string (msg)
				l_file.put_new_line
				l_file.close
			end
		end

	log_mouse_event (event: TUI_EVENT)
			-- Log mouse event details to file.
		local
			l_file: PLAIN_TEXT_FILE
			msg: STRING
		do
			create msg.make (100)
			msg.append ("MOUSE: x=")
			msg.append (event.mouse_x.out)
			msg.append (" y=")
			msg.append (event.mouse_y.out)
			msg.append (" btn=")
			msg.append (event.mouse_button.out)
			if event.is_mouse_press then msg.append (" PRESS") end
			if event.is_mouse_release then msg.append (" RELEASE") end

			create l_file.make_open_append ("tui_demo.log")
			if l_file.is_open_write then
				l_file.put_string (msg)
				l_file.put_new_line
				l_file.close
			end
		end

	handle_key (event: TUI_EVENT): BOOLEAN
			-- Handle key event. Return True if handled.
		do
			-- Check for quit (Ctrl+Q or Ctrl+C) - always available
			if event.has_ctrl then
				if event.char = 'q' or event.char = 'Q' or event.char = '%/3/' then
					quit
					Result := True
				end
			end

			-- Modal widget captures all input when visible
			if not Result and attached modal_widget as mw then
				if mw.is_visible then
					Result := mw.handle_key (event)
					-- Modal consumes all key events
					Result := True
				end
			end

			if not Result then
				-- Check registered global shortcuts
				if not Result then
					Result := try_shortcut (event)
				end

				-- Let menu bar handle if open
				if not Result and attached menu_bar as mb then
					if mb.is_menu_open then
						Result := mb.handle_key (event)
					end
				end

				-- Check Alt+key for menu shortcuts
				if not Result and event.has_alt and attached menu_bar as mb then
					Result := mb.handle_key (event)
				end

				-- Dispatch to focused widget FIRST (widgets may handle Tab internally)
				if not Result and attached focused_widget as fw then
					Result := fw.handle_key (event)
				end

				-- Check for Tab (focus cycling) only if widget didn't handle it
				if not Result and event.is_tab then
					if event.has_shift then
						focus_previous
					else
						focus_next
					end
					Result := True
				end
			end
		end

	handle_mouse (event: TUI_EVENT): BOOLEAN
			-- Handle mouse event. Return True if handled.
		local
			target: detachable TUI_WIDGET
		do
			-- Modal widget captures all mouse input when visible
			if attached modal_widget as mw then
				if mw.is_visible then
					Result := mw.handle_mouse (event)
					-- Modal consumes all mouse events
					Result := True
				end
			end

			if not Result then
				-- Check menu bar first
				if attached menu_bar as mb then
					if event.mouse_y = 1 or mb.is_menu_open then
						Result := mb.handle_mouse (event)
					end
				end

				-- Find widget under mouse
				if not Result and attached root as r then
					target := r.find_widget_at (event.mouse_x, event.mouse_y)
					if attached target as t then
						-- Focus clicked widget if focusable
						if event.is_mouse_press and event.mouse_button = 1 then
							if t.is_focusable and t /= focused_widget then
								set_focus (t)
							end
						end
						Result := t.handle_mouse (event)
					end
				end
			end
		end

	handle_resize (event: TUI_EVENT)
			-- Handle terminal resize.
		do
			if attached backend as b and attached buffer as buf then
				buf.resize (event.resize_width, event.resize_height)

				-- Resize root widget
				if attached root as r then
					r.set_size (event.resize_width, event.resize_height)
					r.layout
				end

				-- Notify handler
				if attached on_resize as handler then
					handler.call ([event.resize_width, event.resize_height])
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

	make_shortcut_key (key: CHARACTER_32; ctrl, alt, shift: BOOLEAN): STRING_32
			-- Create unique key for shortcut lookup.
		do
			create Result.make (10)
			if ctrl then Result.append ("C-") end
			if alt then Result.append ("A-") end
			if shift then Result.append ("S-") end
			Result.append_character (key.as_lower)
		end

	try_shortcut (event: TUI_EVENT): BOOLEAN
			-- Try to execute registered shortcut. Return True if found and executed.
		local
			shortcut_key: STRING_32
		do
			shortcut_key := make_shortcut_key (event.char, event.has_ctrl, event.has_alt, event.has_shift)
			if shortcuts.has (shortcut_key) then
				if attached shortcuts.item (shortcut_key) as handler then
					handler.call (Void)
					Result := True
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

	collect_from_widget (widget: TUI_WIDGET)
			-- Recursively collect focusable widgets.
		local
			i: INTEGER
		do
			if widget.is_focusable then
				focusable_widgets.extend (widget)
			end
			from i := 1 until i > widget.children.count loop
				collect_from_widget (widget.children.i_th (i))
				i := i + 1
			end
		end

invariant
	focusable_widgets_exist: focusable_widgets /= Void
	shortcuts_exist: shortcuts /= Void
	valid_fps: target_fps > 0 and target_fps <= 120

end
