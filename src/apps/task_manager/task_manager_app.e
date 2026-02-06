note
	description: "[
		TASK_MANAGER_APP - TUI Task Manager with full task management features.

		Features:
		- Create tasks with l_title, description, l_priority, l_due date, l_context
		- Edit existing tasks
		- Subtask support (parent/child relationships)
		- Multiple view filters (all, pending, completed, by l_context)
		- Status workflow (pending, in_progress, waiting, completed, archived)
		- AI assistance (optional) for task parsing, subtask suggestions, block l_resolution
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TASK_MANAGER_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Create and run the task manager.
		do
			initialize_database
			initialize_ai
			create_ui
			load_tasks
			tui.run
			cleanup
		end

feature {NONE} -- Database

	l_db: detachable SIMPLE_SQL_DATABASE
			-- Database connection.

	l_repo: detachable TODO_REPOSITORY
			-- Task repository.

	initialize_database
			-- Open database and create tables.
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TODO_REPOSITORY
		do
			create l_db.make ("tasks.db")
			l_db := l_db

			create l_repo.make (l_db)
			l_repo.create_table
			-- Migrate schema for existing databases
			l_repo.migrate_schema
			l_repo := l_repo
		end

	cleanup
			-- Close database.
		do
			if attached l_db as al_d then
				al_d.close
			end
		end

feature {NONE} -- AI

	ai_config: TASK_AI_CONFIG
			-- AI provider configuration.

	ai_router: detachable TASK_AI_ROUTER
			-- AI router for task operations.

	initialize_ai
			-- Initialize AI configuration.
		do
			create ai_config.make
			-- Load saved config if exists
			ai_config.load_from_file
			-- Create router
			create ai_router.make (ai_config)
		end

feature {NONE} -- UI

	tui: TUI_QUICK
			-- The TUI builder.

	task_dialog: detachable TUI_INPUT_DIALOG
			-- Task creation/edit dialog.

	current_filter: INTEGER
			-- Current view filter (0=all, 1=pending, 2=in_progress, 3=completed).

	editing_task_id: INTEGER_64
			-- ID of task being edited (0 = creating new).

	create_ui
			-- Build the user interface.
		local
			l_q: TUI_QUICK
		do
			current_filter := 0
			editing_task_id := 0

			create tui.make ("Task Manager")

			-- Menu bar
			l_q := tui.menu ("&File")
					.item ("&New Task...", agent on_new_task)
					.item ("&Edit Task...", agent on_edit_task)
					.separator
					.item ("&Start Task", agent on_start_task)
					.item ("&Complete Task", agent on_complete_task)
					.separator
					.item ("&Delete Task", agent on_delete_task)
					.item ("Delete All &Completed", agent on_delete_completed)
					.separator
					.item ("E&xit", agent on_exit)
				.menu ("&View")
					.item ("&All Tasks", agent on_view_all)
					.item ("&Pending Only", agent on_view_pending)
					.item ("&In Progress", agent on_view_in_progress)
					.item ("&Completed Only", agent on_view_completed)
					.separator
					.item ("By &Context: Office", agent on_view_context_office)
					.item ("By Context: &Home", agent on_view_context_home)
				.menu ("&AI")
					.item ("&Create from Text...", agent on_ai_create_from_text)
					.item ("&Suggest Subtasks", agent on_ai_suggest_subtasks)
					.item ("&Help with Block", agent on_ai_help_block)
					.separator
					.item ("AI &Status", agent on_ai_status)
				.menu ("&Help")
					.item ("&Keyboard Shortcuts", agent on_shortcuts)
					.item ("&About", agent on_about)

			-- Main layout
			l_q := tui.vbox.gap (1)
					.label ("=== Task Manager ===")
					.label ("N=New  E=Edit  S=Start  C=Complete  D=Delete  Q=Quit")
					.label ("")
					.hbox.gap (1)
						.label ("Filter: ")
						.label ("All Tasks").named ("filter_label")
					.end_box
					.label ("-------------------------------------------------")
					.list_box (8).named ("task_list")
					.label ("-------------------------------------------------")
					.hbox.gap (2)
						.label ("Tasks: 0").named ("count_label")
						.button ("&New", agent on_new_task)
						.button ("&Edit", agent on_edit_task)
						.button ("&Start", agent on_start_task)
						.button ("&Complete", agent on_complete_task)
					.end_box
				.end_box

			-- Create task dialog (reused for new and edit)
			create_task_dialog
		end

	create_task_dialog
			-- Create the task creation/edit dialog.
		local
			l_dlg: TUI_INPUT_DIALOG
			priority_opts, context_opts, energy_opts: ARRAY [STRING_8]
		do
			create l_dlg.make ("New Task")
			l_dlg.add_text_field ("title", "Title:", 35)
			l_dlg.add_text_field ("description", "Description:", 35)
			priority_opts := <<"1 - Highest", "2 - High", "3 - Medium", "4 - Low", "5 - Lowest">>
			l_dlg.add_combo_field ("priority", "Priority:", priority_opts)
			l_dlg.add_text_field ("due_date", "Due Date:", 12)
			context_opts := <<"", "office", "home", "phone", "errands">>
			l_dlg.add_combo_field ("context", "Context:", context_opts)
			energy_opts := <<"1 - Low", "2 - Medium", "3 - High">>
			l_dlg.add_combo_field ("energy", "Energy:", energy_opts)
			l_dlg.set_on_submit (agent on_task_dialog_submit)
			l_dlg.set_on_cancel (agent on_task_dialog_cancel)
			task_dialog := l_dlg
		end

feature {NONE} -- Data Loading

	load_tasks
			-- Load tasks from database into list.
		local
			l_items: ARRAYED_LIST [TODO_ITEM]
			l_display_text: STRING_32
			l_status_char: STRING_32
		do
			if attached l_repo as r and attached tui.list_named ("task_list") as al_task_list then
				al_task_list.clear_items

				-- Get items based on filter
				inspect current_filter
				when 0 then
					l_items := r.find_all
				when 1 then
					l_items := r.find_by_status ("pending")
				when 2 then
					l_items := r.find_in_progress
				when 3 then
					l_items := r.find_completed
				when 4 then
					l_items := r.find_by_context ("office")
				when 5 then
					l_items := r.find_by_context ("home")
				else
					l_items := r.find_all
				end

				-- Add to list with enhanced display
				across l_items as ic loop
					create l_display_text.make (60)

					-- Status indicator
					if ic.is_completed then
						l_status_char := "[X]"
					elseif ic.is_in_progress then
						l_status_char := "[>]"
					elseif ic.is_waiting then
						l_status_char := "[?]"
					else
						l_status_char := "[ ]"
					end
					l_display_text.append (l_status_char)
					l_display_text.append (" ")

					-- Priority
					l_display_text.append ("P")
					l_display_text.append_integer (ic.priority)
					l_display_text.append (" ")

					-- Subtask indent
					if ic.is_subtask then
						l_display_text.append ("  +- ")
					end

					-- Title
					l_display_text.append_string_general (ic.title)

					-- Context badge
					if not ic.context.is_empty then
						l_display_text.append (" @")
						l_display_text.append_string_general (ic.context)
					end

					-- Due date
					if attached ic.due_date as al_dd then
						l_display_text.append (" [")
						l_display_text.append_string_general (dd)
						l_display_text.append ("]")
					end

					task_list.add_item (l_display_text)
				end

				-- Update count label
				update_count_label (l_items.count)

				-- Store items for later reference
				current_items := l_items
			end
		end

	current_items: detachable ARRAYED_LIST [TODO_ITEM]
			-- Currently displayed items.

	update_count_label (a_count: INTEGER)
			-- Update the task count label.
		local
			l_text: STRING_32
		do
			if attached {TUI_LABEL} tui.widget ("count_label") as al_lbl then
				create l_text.make (20)
				l_text.append ("Tasks: ")
				l_text.append_integer (a_count)
				al_lbl.set_text (l_text)
			end
		end

	update_filter_label
			-- Update the filter label.
		local
			l_text: STRING_32
		do
			if attached {TUI_LABEL} tui.widget ("filter_label") as al_lbl then
				inspect current_filter
				when 0 then l_text := "All Tasks"
				when 1 then l_text := "Pending Only"
				when 2 then l_text := "In Progress"
				when 3 then l_text := "Completed Only"
				when 4 then l_text := "Context: Office"
				when 5 then l_text := "Context: Home"
				else l_text := "All Tasks"
				end
				lbl.set_text (l_text)
			end
		end

feature {NONE} -- Menu Handlers

	on_new_task
			-- Show dialog to create a new task.
		do
			editing_task_id := 0
			if attached task_dialog as al_dlg then
				al_dlg.set_title ("New Task")
				-- Reset fields
				al_dlg.set_field_value ("title", "")
				al_dlg.set_field_value ("description", "")
				al_dlg.set_field_value ("priority", "3 - Medium")
				al_dlg.set_field_value ("due_date", "")
				al_dlg.set_field_value ("context", "")
				al_dlg.set_field_value ("energy", "2 - Medium")
				al_dlg.show_centered (tui.screen_width, tui.screen_height)
				tui.set_modal (l_dlg)
			end
		end

	on_edit_task
			-- Show dialog to edit the selected task.
		local
			l_item: TODO_ITEM
		do
			if attached get_selected_task as al_sel_item then
				l_item := sel_item
				editing_task_id := l_item.id
				if attached task_dialog as al_dlg then
					l_dlg.set_title ("Edit Task")
					l_dlg.set_field_value ("title", l_item.title)
					if attached l_item.description as al_desc then
						l_dlg.set_field_value ("description", l_desc)
					else
						l_dlg.set_field_value ("description", "")
					end
					l_dlg.set_field_value ("priority", priority_to_display (l_item.priority))
					if attached l_item.due_date as al_dd then
						l_dlg.set_field_value ("due_date", dd)
					else
						l_dlg.set_field_value ("due_date", "")
					end
					l_dlg.set_field_value ("context", l_item.context)
					l_dlg.set_field_value ("energy", energy_to_display (l_item.energy_level))
					l_dlg.show_centered (tui.screen_width, tui.screen_height)
					tui.set_modal (l_dlg)
				end
			end
		end

	on_start_task
			-- Mark selected task as in progress.
		local
			l_ok: BOOLEAN
		do
			if attached get_selected_task as l_item and attached l_repo as al_r then
				l_ok := al_r.set_status (l_item.id, "in_progress")
				load_tasks
			end
		end

	on_complete_task
			-- Mark selected task as completed.
		local
			l_ok: BOOLEAN
		do
			if attached get_selected_task as l_item and attached l_repo as al_r then
				l_ok := al_r.set_status (l_item.id, "completed")
				load_tasks
			end
		end

	on_toggle_complete
			-- Toggle completion status of selected task.
		local
			l_ok: BOOLEAN
		do
			if attached get_selected_task as l_item and attached l_repo as al_r then
				if l_item.is_completed then
					l_ok := al_r.set_status (l_item.id, "pending")
				else
					l_ok := al_r.set_status (l_item.id, "completed")
				end
				load_tasks
			end
		end

	on_delete_task
			-- Delete selected task.
		local
			l_ok: BOOLEAN
		do
			if attached get_selected_task as l_item and attached l_repo as al_r then
				l_ok := al_r.delete (l_item.id)
				load_tasks
			end
		end

	on_delete_completed
			-- Delete all completed tasks.
		local
			l_count: INTEGER
		do
			if attached l_repo as al_r then
				l_count := al_r.delete_completed
				load_tasks
			end
		end

	on_exit
			-- Exit the application.
		do
			tui.quit
		end

	on_view_all
			-- Show all tasks.
		do
			current_filter := 0
			update_filter_label
			load_tasks
		end

	on_view_pending
			-- Show only pending tasks.
		do
			current_filter := 1
			update_filter_label
			load_tasks
		end

	on_view_in_progress
			-- Show only in-progress tasks.
		do
			current_filter := 2
			update_filter_label
			load_tasks
		end

	on_view_completed
			-- Show only completed tasks.
		do
			current_filter := 3
			update_filter_label
			load_tasks
		end

	on_view_context_office
			-- Show tasks with office context.
		do
			current_filter := 4
			update_filter_label
			load_tasks
		end

	on_view_context_home
			-- Show tasks with home context.
		do
			current_filter := 5
			update_filter_label
			load_tasks
		end

	on_shortcuts
			-- Show keyboard shortcuts.
		do
			tui.show_message ("Keyboard Shortcuts",
				"N - New Task%N" +
				"E - Edit Task%N" +
				"S - Start Task (mark in progress)%N" +
				"C - Complete Task%N" +
				"D - Delete Task%N" +
				"Q - Quit%N" +
				"Tab - Navigate between fields%N" +
				"Enter - Activate/Submit%N" +
				"Escape - Cancel dialog")
		end

	on_about
			-- Show about dialog.
		do
			tui.show_message ("About", "Task Manager v2.0%N%NBuilt with simple_tui and simple_sql%N%NFeatures:%N- Full task management%N- Status workflow%N- Context tagging%N- Subtask support%N- AI assistance (optional)")
		end

feature {NONE} -- AI Handlers

	on_ai_create_from_text
			-- Create task from natural language input.
		local
			l_dlg: TUI_INPUT_DIALOG
		do
			create l_dlg.make ("AI: Create from Text")
			l_dlg.add_text_field ("text", "Describe your task:", 50)
			l_dlg.set_on_submit (agent on_ai_text_submit)
			l_dlg.set_on_cancel (agent on_task_dialog_cancel)
			l_dlg.show_centered (tui.screen_width, tui.screen_height)
			tui.set_modal (l_dlg)
		end

	on_ai_text_submit (a_values: HASH_TABLE [STRING_32, STRING_32])
			-- Handle AI text input submission.
		local
			l_text: STRING_8
			l_item: detachable TODO_ITEM
			l_id: INTEGER_64
		do
			tui.clear_modal

			if attached a_values.item ("text") as al_v then
				l_text := al_v.to_string_8
			else
				l_text := ""
			end

			if not l_text.is_empty then
				if attached ai_router as al_router then
					l_item := al_router.parse_task (l_text)
					if attached l_item as l_item and attached l_repo as al_r then
						l_id := r.insert (l_item)
						load_tasks
						if al_router.is_ai_available then
							tui.show_message ("AI Task Created", "Created: " + l_item.title)
						else
							tui.show_message ("Task Created", "Created (no AI): " + l_item.title + "%N%N(AI not configured - used keyword parsing)")
						end
					elseif router.has_error then
						tui.show_message ("AI Error", router.last_error.to_string_8)
					end
				end
			end
		end

	on_ai_suggest_subtasks
			-- Suggest subtasks for selected task using AI.
		local
			l_subtasks: ARRAYED_LIST [TODO_ITEM]
			l_msg: STRING_32
			l_id: INTEGER_64
		do
			if attached get_selected_task as al_item then
				if attached ai_router as al_router then
					l_subtasks := router.suggest_subtasks (l_item, Void)
					if l_subtasks.is_empty then
						if router.is_ai_available then
							tui.show_message ("No Suggestions", "AI couldn't suggest subtasks for this task.")
						else
							tui.show_message ("AI Not Available", "Configure an AI provider to get subtask suggestions.%N%N(Menu: AI > AI Status)")
						end
					else
						-- Show suggestions and offer to create them
						create l_msg.make (200)
						l_msg.append ("AI suggests these subtasks:%N%N")
						across l_subtasks as s loop
							l_msg.append ("- ")
							l_msg.append_string_general (s.title)
							l_msg.append ("%N")
						end
						l_msg.append ("%NCreate these subtasks?")
						tui.show_confirm ("Subtask Suggestions", l_msg, agent on_confirm_subtasks (?, l_subtasks, l_item.id))
					end
				end
			else
				tui.show_message ("No Selection", "Select a task first to get subtask suggestions.")
			end
		end

	on_confirm_subtasks (a_confirmed: BOOLEAN; a_subtasks: ARRAYED_LIST [TODO_ITEM]; a_parent_id: INTEGER_64)
			-- Handle confirmation of subtask creation.
		local
			l_id: INTEGER_64
		do
			if a_confirmed and attached l_repo as al_r then
				across a_subtasks as s loop
					s.set_parent_id (a_parent_id)
					l_id := r.insert (s)
				end
				load_tasks
				tui.show_message ("Created", "Created " + a_subtasks.count.out + " subtasks.")
			end
		end

	on_ai_help_block
			-- Get AI help for a blocked task.
		local
			l_resolution: detachable TASK_BLOCK_RESOLUTION
			l_blockers: ARRAYED_LIST [TODO_ITEM]
		do
			if attached get_selected_task as al_item then
				if al_item.is_waiting then
					if attached ai_router as router and attached l_repo as al_r then
						-- Find potential blockers (tasks in progress or pending)
						l_blockers := r.find_in_progress
						if l_blockers.is_empty then
							l_blockers := r.find_by_status ("pending")
						end

						l_resolution := router.resolve_block (l_item, l_blockers, r.find_all)
						if attached l_resolution as al_res then
							tui.show_message ("AI Block Resolution", al_res.full_description)
						else
							tui.show_message ("No Suggestions", "AI couldn't suggest a resolution.")
						end
					end
				else
					tui.show_message ("Not Blocked", "This task is not marked as waiting/blocked.%N%NTo mark as blocked, change status to 'waiting'.")
				end
			else
				tui.show_message ("No Selection", "Select a blocked task first.")
			end
		end

	on_ai_status
			-- Show AI configuration status.
		local
			l_msg: STRING_32
		do
			create l_msg.make (200)
			l_msg.append ("AI Provider Status%N%N")

			if ai_config.is_ready then
				l_msg.append ("Status: READY%N")
				l_msg.append ("Provider: ")
				l_msg.append_string_general (ai_config.active_provider)
				l_msg.append ("%N")
				if attached ai_config.current_model as al_m then
					l_msg.append ("Model: ")
					l_msg.append_string_general (m)
					l_msg.append ("%N")
				end
			else
				l_msg.append ("Status: NOT CONFIGURED%N%N")
				l_msg.append ("To enable AI features:%N")
				l_msg.append ("1. Set environment variable:%N")
				l_msg.append ("   ANTHROPIC_API_KEY (for Claude)%N")
				l_msg.append ("   XAI_API_KEY (for Grok)%N")
				l_msg.append ("2. Or install Ollama locally%N")
			end

			l_msg.append ("%NAll features work without AI,")
			l_msg.append ("%Nbut AI enhances task parsing,")
			l_msg.append ("%Nsubtask suggestions, and more.")

			tui.show_message ("AI Status", l_msg)
		end

feature {NONE} -- Dialog Handlers

	on_task_dialog_submit (a_values: HASH_TABLE [STRING_32, STRING_32])
			-- Handle task dialog submission.
		local
			l_new_item: TODO_ITEM
			l_id: INTEGER_64
			l_title, l_desc, l_due, l_context: STRING_8
			l_priority, l_energy: INTEGER
			l_ok: BOOLEAN
		do
			tui.clear_modal

			-- Extract values with safe handling of Void
			if attached a_values.item ("title") as al_v then
				l_title := al_v.to_string_8
			else
				l_title := ""
			end
			if l_title.is_empty then
				l_title := "Untitled Task"
			end

			if attached a_values.item ("description") as al_v then
				l_desc := al_v.to_string_8
			else
				l_desc := ""
			end
			if attached a_values.item ("priority") as al_v then
				l_priority := extract_number (v, 3)
			else
				l_priority := 3
			end
			if attached a_values.item ("due_date") as al_v then
				l_due := al_v.to_string_8
			else
				l_due := ""
			end
			if attached a_values.item ("context") as al_v then
				l_context := al_v.to_string_8
			else
				l_context := ""
			end
			if attached a_values.item ("energy") as al_v then
				l_energy := extract_number (v, 2)
			else
				l_energy := 2
			end

			if attached l_repo as al_r then
				if editing_task_id > 0 then
					-- Update existing task
					if attached al_r.find_by_id (editing_task_id) as al_existing then
						existing.set_title (l_title)
						if l_desc.is_empty then
							existing.set_description (Void)
						else
							existing.set_description (l_desc)
						end
						existing.set_priority (l_priority)
						if l_due.is_empty then
							existing.set_due_date (Void)
						else
							existing.set_due_date (l_due)
						end
						existing.set_context (l_context)
						existing.set_energy_level (l_energy)
						l_ok := r.update (existing)
					end
				else
					-- Create new task
					create l_new_item.make_new (l_title, l_priority)
					if not l_desc.is_empty then
						l_new_item.set_description (l_desc)
					end
					if not l_due.is_empty then
						l_new_item.set_due_date (l_due)
					end
					l_new_item.set_context (l_context)
					l_new_item.set_energy_level (l_energy)
					l_id := r.insert (l_new_item)
				end
				load_tasks
			end
		end

	on_task_dialog_cancel
			-- Handle task dialog cancellation.
		do
			tui.clear_modal
		end

feature {NONE} -- Helpers

	get_selected_task: detachable TODO_ITEM
			-- Get the currently selected task.
		do
			if attached tui.list_named ("task_list") as al_task_list then
				if attached current_items as al_items then
					if al_task_list.selected_index > 0 and al_task_list.selected_index <= l_items.count then
						Result := l_items.i_th (al_task_list.selected_index)
					end
				end
			end
		end

	extract_number (a_text: STRING_32; a_default: INTEGER): INTEGER
			-- Extract leading number from text like "3 - Medium".
		local
			l_str: STRING_32
			l_pos: INTEGER
		do
			l_str := a_text.twin
			l_str.left_adjust
			l_pos := l_str.index_of (' ', 1)
			if l_pos > 1 then
				l_str := l_str.substring (1, l_pos - 1)
			end
			if l_str.is_integer then
				Result := l_str.to_integer
			else
				Result := a_default
			end
		end

	priority_to_display (a_priority: INTEGER): STRING_32
			-- Convert priority number to display string.
		do
			inspect a_priority
			when 1 then Result := "1 - Highest"
			when 2 then Result := "2 - High"
			when 3 then Result := "3 - Medium"
			when 4 then Result := "4 - Low"
			when 5 then Result := "5 - Lowest"
			else Result := "3 - Medium"
			end
		end

	energy_to_display (a_energy: INTEGER): STRING_32
			-- Convert energy level to display string.
		do
			inspect a_energy
			when 1 then Result := "1 - Low"
			when 2 then Result := "2 - Medium"
			when 3 then Result := "3 - High"
			else Result := "2 - Medium"
			end
		end

end
