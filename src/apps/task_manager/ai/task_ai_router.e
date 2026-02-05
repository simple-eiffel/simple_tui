note
	description: "[
		TASK_AI_ROUTER - AI Router for Task Manager with RAG pattern.

		Provides AI-enhanced features with graceful degradation:
		- Parse natural language into tasks
		- Suggest subtasks for decomposition
		- Find similar past tasks
		- Resolve blocked tasks
		- All features work without AI (manual fallback)

		Based on 4-phase RAG pattern from simple_kb:
		Phase 1: Extract keywords/intent from query
		Phase 2: Search for similar past tasks
		Phase 3: If found, synthesize from context
		Phase 4: If not found, generate fresh + cache
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TASK_AI_ROUTER

create
	make

feature {NONE} -- Initialization

	make (a_config: TASK_AI_CONFIG)
			-- Initialize with AI configuration.
		require
			config_attached: a_config /= Void
		do
			ai_config := a_config
			create prompts.make (a_config.active_provider)
			create last_error.make_empty
		ensure
			config_set: ai_config = a_config
		end

feature -- Access

	ai_config: TASK_AI_CONFIG
			-- AI provider configuration.

	prompts: TASK_PROMPT_TEMPLATES
			-- Provider-specific prompts.

	last_error: STRING_32
			-- Error message from last operation.

feature -- Status

	is_ai_available: BOOLEAN
			-- Is AI configured and ready?
		do
			Result := ai_config.is_ready
		end

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := not last_error.is_empty
		end

feature -- Parse Natural Language

	parse_task (a_input: READABLE_STRING_8): detachable TODO_ITEM
			-- Parse natural language into a TODO_ITEM.
			-- Returns Void if parsing fails.
		local
			l_response: AI_RESPONSE
			l_client: detachable AI_CLIENT
		do
			last_error.wipe_out
			if is_ai_available then
				l_client := create_ai_client
				if attached l_client as al_client then
					l_response := al_client.ask_with_system (
						prompts.parse_task_system (ai_config.active_provider).to_string_32,
						prompts.parse_task_user (a_input).to_string_32
					)
					if l_response.is_success then
						Result := parse_task_response (l_response.text)
					else
						if attached l_response.error_message as al_e then
							last_error := e
						end
					end
				else
					last_error := "Failed to create AI client"
				end
			else
				-- Fallback: create simple task from input
				Result := parse_task_simple (a_input)
			end
		end

	parse_task_simple (a_input: READABLE_STRING_8): TODO_ITEM
			-- Simple non-AI task parsing (fallback).
			-- Just uses the input as title.
		local
			l_title: STRING_8
			l_priority: INTEGER
		do
			l_title := a_input.twin
			l_title.left_adjust
			l_title.right_adjust
			if l_title.count > 100 then
				l_title := l_title.head (100)
			end
			-- Detect urgency keywords
			l_priority := 3
			if a_input.as_lower.has_substring ("urgent") or else
				a_input.as_lower.has_substring ("asap") then
				l_priority := 1
			elseif a_input.as_lower.has_substring ("important") then
				l_priority := 2
			elseif a_input.as_lower.has_substring ("low priority") or else
				a_input.as_lower.has_substring ("whenever") then
				l_priority := 5
			end
			create Result.make_new (l_title, l_priority)
		ensure
			result_attached: Result /= Void
		end

feature -- Subtask Suggestions

	suggest_subtasks (a_task: TODO_ITEM; a_similar: detachable LIST [TODO_ITEM]): ARRAYED_LIST [TODO_ITEM]
			-- Suggest subtasks for decomposition.
		local
			l_response: AI_RESPONSE
			l_client: detachable AI_CLIENT
			l_similar_titles: ARRAYED_LIST [STRING_8]
			l_desc: STRING_8
		do
			create Result.make (5)
			last_error.wipe_out

			if is_ai_available then
				l_client := create_ai_client
				if attached l_client as al_client then
					-- Build similar task context
					create l_similar_titles.make (5)
					if attached a_similar as al_similar then
						across similar as s loop
							l_similar_titles.extend (s.title)
						end
					end
					-- Get description or empty string
					if attached a_task.description as al_d then
						l_desc := d
					else
						l_desc := ""
					end
					l_response := client.ask_with_system (
						prompts.suggest_subtasks_system (ai_config.active_provider).to_string_32,
						prompts.suggest_subtasks_user (a_task.title, l_desc, l_similar_titles).to_string_32
					)
					if l_response.is_success then
						Result := parse_subtasks_response (l_response.text, a_task.id)
					else
						if attached l_response.error_message as al_e then
							last_error := e
						end
					end
				end
			end
			-- No fallback for subtasks - returns empty list if AI unavailable
		ensure
			result_attached: Result /= Void
		end

feature -- Block Resolution

	resolve_block (a_blocked: TODO_ITEM; a_blockers: LIST [TODO_ITEM];
			a_all_tasks: LIST [TODO_ITEM]): detachable TASK_BLOCK_RESOLUTION
			-- Suggest how to handle a blocked task.
		local
			l_response: AI_RESPONSE
			l_client: detachable AI_CLIENT
			l_blockers_text: STRING_8
		do
			last_error.wipe_out

			if is_ai_available and then not a_blockers.is_empty then
				l_client := create_ai_client
				if attached l_client as al_client then
					-- Build blockers description
					create l_blockers_text.make (200)
					across a_blockers as b loop
						l_blockers_text.append ("- ")
						l_blockers_text.append (b.title)
						l_blockers_text.append ("%N")
					end

					l_response := client.ask_with_system (
						prompts.resolve_block_system (ai_config.active_provider).to_string_32,
						prompts.resolve_block_user (a_blocked.title, l_blockers_text).to_string_32
					)
					if l_response.is_success then
						Result := parse_block_resolution (l_response.text, a_all_tasks)
					else
						if attached l_response.error_message as al_e then
							last_error := e
						end
					end
				end
			end

			-- Fallback: simple block resolution
			if Result = Void and then not a_blockers.is_empty then
				Result := simple_block_resolution (a_blocked, a_blockers, a_all_tasks)
			end
		end

	simple_block_resolution (a_blocked: TODO_ITEM; a_blockers: LIST [TODO_ITEM];
			a_all_tasks: LIST [TODO_ITEM]): TASK_BLOCK_RESOLUTION
			-- Simple non-AI block resolution.
		local
			l_alternatives: ARRAYED_LIST [TODO_ITEM]
		do
			create Result.make
			Result.set_recommendation ("work_around")
			Result.set_explanation ("Task is blocked. Work on something else first.")

			-- Find unblocked tasks
			create l_alternatives.make (3)
			across a_all_tasks as t loop
				if t.id /= a_blocked.id and then
					not t.is_completed and then
					not across a_blockers as b some b.id = t.id end then
					l_alternatives.extend (t)
					if l_alternatives.count >= 3 then
						-- Limit to 3 alternatives
					end
				end
			end
			Result.set_alternatives (l_alternatives)
		ensure
			result_attached: Result /= Void
		end

feature -- Task Splitting

	split_task (a_task: TODO_ITEM): ARRAYED_LIST [TODO_ITEM]
			-- Suggest how to split a large task.
		local
			l_response: AI_RESPONSE
			l_client: detachable AI_CLIENT
			l_desc: STRING_8
		do
			create Result.make (4)
			last_error.wipe_out

			if is_ai_available then
				l_client := create_ai_client
				if attached l_client as al_client then
					if attached a_task.description as al_d then
						l_desc := d
					else
						l_desc := ""
					end
					l_response := client.ask_with_system (
						prompts.split_task_system (ai_config.active_provider).to_string_32,
						prompts.split_task_user (a_task.title, l_desc).to_string_32
					)
					if l_response.is_success then
						Result := parse_subtasks_response (l_response.text, a_task.id)
					else
						if attached l_response.error_message as al_e then
							last_error := e
						end
					end
				end
			end
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- AI Client Creation

	create_ai_client: detachable AI_CLIENT
			-- Create appropriate AI client based on config.
		do
			if ai_config.active_provider.same_string ("claude") then
				if attached ai_config.provider_api_key ("claude") as al_k then
					create {CLAUDE_CLIENT} Result.make_with_api_key (k)
				end
			elseif ai_config.active_provider.same_string ("grok") then
				if attached ai_config.provider_api_key ("grok") as al_k then
					create {GROK_CLIENT} Result.make_with_api_key (k)
				end
			elseif ai_config.active_provider.same_string ("ollama") then
				create {OLLAMA_CLIENT} Result.make
				if attached ai_config.current_model as m and then attached {OLLAMA_CLIENT} Result as al_oc then
					al_oc.set_model (m.to_string_32)
				end
			end
		end

feature {NONE} -- Response Parsing

	parse_task_response (a_response: STRING_32): detachable TODO_ITEM
			-- Parse AI response into TODO_ITEM.
		local
			l_title, l_line: STRING_32
			l_priority: INTEGER
			l_lines: LIST [STRING_32]
		do
			-- Try to parse structured response
			l_title := ""
			l_priority := 3
			l_lines := a_response.split ('%N')
			across l_lines as line loop
				l_line := line.twin
				l_line.left_adjust
				if l_line.as_upper.starts_with ("TITLE:") then
					l_title := l_line.substring (7, l_line.count)
					l_title.left_adjust
					l_title.right_adjust
				elseif l_line.as_upper.starts_with ("PRIORITY:") then
					l_priority := extract_integer (l_line.substring (10, l_line.count), 3)
					l_priority := l_priority.max (1).min (5)
				end
			end

			-- Try JSON if structured parse failed
			if l_title.is_empty then
				l_title := extract_json_string (a_response, "title")
				l_priority := extract_json_integer (a_response, "priority", 3)
			end

			if not l_title.is_empty then
				create Result.make_new (l_title.to_string_8, l_priority)
			end
		end

	parse_subtasks_response (a_response: STRING_32; a_parent_id: INTEGER_64): ARRAYED_LIST [TODO_ITEM]
			-- Parse AI response into list of subtasks.
		local
			l_lines: LIST [STRING_32]
			l_line, l_title: STRING_32
			l_item: TODO_ITEM
			l_num: INTEGER
		do
			create Result.make (5)
			l_lines := a_response.split ('%N')
			across l_lines as line loop
				l_line := line.twin
				l_line.left_adjust
				-- Match numbered items: "1. Do something" or "1) Do something"
				if l_line.count > 2 then
					l_num := l_line.item (1).code - ('0').code
					if l_num >= 1 and l_num <= 9 then
						if l_line.item (2) = '.' or l_line.item (2) = ')' then
							l_title := l_line.substring (3, l_line.count)
							l_title.left_adjust
							l_title.right_adjust
							if not l_title.is_empty then
								create l_item.make_new (l_title.to_string_8, 3)
								if a_parent_id > 0 then
									l_item.set_parent_id (a_parent_id)
								end
								Result.extend (l_item)
							end
						end
					end
				end
			end
		ensure
			result_attached: Result /= Void
		end

	parse_block_resolution (a_response: STRING_32; a_all_tasks: LIST [TODO_ITEM]): TASK_BLOCK_RESOLUTION
			-- Parse AI response into block resolution.
		local
			l_lines: LIST [STRING_32]
			l_line: STRING_32
		do
			create Result.make
			l_lines := a_response.split ('%N')
			across l_lines as line loop
				l_line := line.twin
				l_line.left_adjust
				if l_line.as_upper.starts_with ("WORK_ON:") then
					Result.set_recommendation ("work_around")
					Result.set_action (l_line.substring (9, l_line.count).to_string_8)
				elseif l_line.as_upper.starts_with ("SPLIT:") then
					Result.set_recommendation ("split")
					Result.set_action (l_line.substring (7, l_line.count).to_string_8)
				elseif l_line.as_upper.starts_with ("WAIT:") then
					Result.set_recommendation ("wait")
					Result.set_action (l_line.substring (6, l_line.count).to_string_8)
				end
			end
			-- Default if nothing parsed
			if Result.recommendation.is_empty then
				Result.set_recommendation ("wait")
				Result.set_explanation (a_response.to_string_8)
			end
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Parsing Helpers

	extract_integer (a_str: STRING_32; a_default: INTEGER): INTEGER
			-- Extract integer from string.
		local
			l_s: STRING_32
		do
			l_s := a_str.twin
			l_s.left_adjust
			l_s.right_adjust
			if l_s.is_integer then
				Result := l_s.to_integer
			else
				Result := a_default
			end
		end

	extract_json_string (a_json, a_key: STRING_32): STRING_32
			-- Simple JSON string extraction.
		local
			l_pattern: STRING_32
			l_pos, l_end: INTEGER
		do
			create Result.make_empty
			create l_pattern.make (a_key.count + 5)
			l_pattern.append ("%"")
			l_pattern.append (a_key)
			l_pattern.append ("%":")
			l_pos := a_json.substring_index (l_pattern, 1)
			if l_pos > 0 then
				l_pos := a_json.index_of ('"', l_pos + l_pattern.count)
				if l_pos > 0 then
					l_end := a_json.index_of ('"', l_pos + 1)
					if l_end > l_pos then
						Result := a_json.substring (l_pos + 1, l_end - 1)
					end
				end
			end
		end

	extract_json_integer (a_json, a_key: STRING_32; a_default: INTEGER): INTEGER
			-- Simple JSON integer extraction.
		local
			l_pattern: STRING_32
			l_pos, l_end: INTEGER
			l_num: STRING_32
		do
			Result := a_default
			create l_pattern.make (a_key.count + 5)
			l_pattern.append ("%"")
			l_pattern.append (a_key)
			l_pattern.append ("%":")
			l_pos := a_json.substring_index (l_pattern, 1)
			if l_pos > 0 then
				l_pos := l_pos + l_pattern.count
				-- Skip whitespace
				from until l_pos > a_json.count or else not a_json.item (l_pos).is_space loop
					l_pos := l_pos + 1
				end
				-- Find end of number
				l_end := l_pos
				from until l_end > a_json.count or else not a_json.item (l_end).is_digit loop
					l_end := l_end + 1
				end
				if l_end > l_pos then
					l_num := a_json.substring (l_pos, l_end - 1)
					if l_num.is_integer then
						Result := l_num.to_integer
					end
				end
			end
		end

invariant
	ai_config_attached: ai_config /= Void
	prompts_attached: prompts /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
