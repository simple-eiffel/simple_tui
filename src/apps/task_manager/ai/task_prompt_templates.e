note
	description: "[
		TASK_PROMPT_TEMPLATES - Provider-specific prompt engineering.

		Different AI models need different prompting strategies:
		- Ollama (local): Narrow, single-task prompts with explicit format
		- Claude/Grok (API): Richer context, multi-step reasoning OK

		All prompts designed for task management operations:
		- Parse natural language into structured task
		- Suggest subtasks for decomposition
		- Resolve blocked tasks
		- Prioritize task lists
		- Split tasks into smaller pieces
		- Consolidate related tasks
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TASK_PROMPT_TEMPLATES

create
	make

feature {NONE} -- Initialization

	make (a_provider: READABLE_STRING_8)
			-- Initialize with provider type.
		require
			provider_not_empty: not a_provider.is_empty
		do
			provider := a_provider.twin
		end

feature -- Access

	provider: STRING_8
			-- Current provider (affects prompt style).

feature -- Parse Task Prompts

	parse_task_system (a_provider: READABLE_STRING_8): STRING_8
			-- System prompt for parsing natural language to task.
		do
			if a_provider.same_string ("ollama") then
				Result := parse_task_system_ollama
			else
				Result := parse_task_system_rich
			end
		end

	parse_task_user (a_input: READABLE_STRING_8): STRING_8
			-- User prompt for task parsing.
		do
			create Result.make (a_input.count + 20)
			Result.append ("Parse this: ")
			Result.append (a_input)
		end

feature -- Subtask Suggestion Prompts

	suggest_subtasks_system (a_provider: READABLE_STRING_8): STRING_8
			-- System prompt for suggesting subtasks.
		do
			if a_provider.same_string ("ollama") then
				Result := suggest_subtasks_system_ollama
			else
				Result := suggest_subtasks_system_rich
			end
		end

	suggest_subtasks_user (a_task_title, a_task_description: READABLE_STRING_8;
			a_similar_tasks: detachable LIST [READABLE_STRING_8]): STRING_8
			-- User prompt for subtask suggestions.
		do
			create Result.make (500)
			Result.append ("Task: ")
			Result.append (a_task_title)
			if not a_task_description.is_empty then
				Result.append ("%NDescription: ")
				Result.append (a_task_description)
			end
			if attached a_similar_tasks as similar and then not similar.is_empty then
				Result.append ("%N%NPreviously similar tasks had these subtasks:%N")
				across similar as s loop
					Result.append ("- ")
					Result.append (s)
					Result.append ("%N")
				end
			end
			Result.append ("%N%NSuggest 3-5 subtasks:")
		end

feature -- Block Resolution Prompts

	resolve_block_system (a_provider: READABLE_STRING_8): STRING_8
			-- System prompt for resolving blocked tasks.
		do
			if a_provider.same_string ("ollama") then
				Result := resolve_block_system_ollama
			else
				Result := resolve_block_system_rich
			end
		end

	resolve_block_user (a_blocked_task, a_blocking_tasks: READABLE_STRING_8): STRING_8
			-- User prompt for block resolution.
		do
			create Result.make (300)
			Result.append ("Blocked task: ")
			Result.append (a_blocked_task)
			Result.append ("%N%NBlocked by:%N")
			Result.append (a_blocking_tasks)
			Result.append ("%N%NSuggest how to proceed:")
		end

feature -- Split Task Prompts

	split_task_system (a_provider: READABLE_STRING_8): STRING_8
			-- System prompt for splitting a large task.
		do
			if a_provider.same_string ("ollama") then
				Result := split_task_system_ollama
			else
				Result := split_task_system_rich
			end
		end

	split_task_user (a_task_title, a_task_description: READABLE_STRING_8): STRING_8
			-- User prompt for task splitting.
		do
			create Result.make (200)
			Result.append ("Split this task into smaller pieces:%N%N")
			Result.append ("Task: ")
			Result.append (a_task_title)
			if not a_task_description.is_empty then
				Result.append ("%NDescription: ")
				Result.append (a_task_description)
			end
		end

feature -- Consolidate Tasks Prompts

	consolidate_tasks_system (a_provider: READABLE_STRING_8): STRING_8
			-- System prompt for consolidating tasks.
		do
			if a_provider.same_string ("ollama") then
				Result := consolidate_tasks_system_ollama
			else
				Result := consolidate_tasks_system_rich
			end
		end

	consolidate_tasks_user (a_tasks: LIST [READABLE_STRING_8]): STRING_8
			-- User prompt for task consolidation.
		local
			i: INTEGER
		do
			create Result.make (500)
			Result.append ("Consider consolidating these related tasks:%N%N")
			i := 1
			across a_tasks as t loop
				Result.append_integer (i)
				Result.append (". ")
				Result.append (t)
				Result.append ("%N")
				i := i + 1
			end
			Result.append ("%NSuggest how to combine or streamline:")
		end

feature -- Prioritization Prompts

	prioritize_system (a_provider: READABLE_STRING_8): STRING_8
			-- System prompt for prioritizing tasks.
		do
			if a_provider.same_string ("ollama") then
				Result := prioritize_system_ollama
			else
				Result := prioritize_system_rich
			end
		end

	prioritize_user (a_tasks: LIST [READABLE_STRING_8]; a_context: detachable READABLE_STRING_8): STRING_8
			-- User prompt for prioritization.
		local
			i: INTEGER
		do
			create Result.make (500)
			if attached a_context as ctx and then not ctx.is_empty then
				Result.append ("Context: ")
				Result.append (ctx)
				Result.append ("%N%N")
			end
			Result.append ("Prioritize these tasks:%N")
			i := 1
			across a_tasks as t loop
				Result.append_integer (i)
				Result.append (". ")
				Result.append (t)
				Result.append ("%N")
				i := i + 1
			end
		end

feature {NONE} -- Ollama Prompts (Narrow, Explicit)

	parse_task_system_ollama: STRING_8
			-- Ollama system prompt for task parsing.
		once
			Result := "[
Extract task info from text. Return EXACTLY this format:
TITLE: <task title>
PRIORITY: <1-5 where 1=highest>
DUE: <date or NONE>
CONTEXT: <office/home/phone/errands or NONE>

Only output the fields, nothing else.
			]"
		end

	suggest_subtasks_system_ollama: STRING_8
			-- Ollama system prompt for subtasks.
		once
			Result := "[
List 3-5 subtasks. Format:
1. <subtask>
2. <subtask>
3. <subtask>

Only output the numbered list.
			]"
		end

	resolve_block_system_ollama: STRING_8
			-- Ollama system prompt for block resolution.
		once
			Result := "[
A task is blocked. Suggest ONE of:
1. WORK_ON: <alternative task to do now>
2. SPLIT: <how to split the blocked task>
3. WAIT: <what to wait for>

Pick the best option and explain briefly.
			]"
		end

	split_task_system_ollama: STRING_8
			-- Ollama system prompt for splitting tasks.
		once
			Result := "[
Split this task into 2-4 smaller tasks. Format:
1. <smaller task>
2. <smaller task>
3. <smaller task>

Only output the numbered list.
			]"
		end

	consolidate_tasks_system_ollama: STRING_8
			-- Ollama system prompt for consolidating.
		once
			Result := "[
Look for tasks that could be combined. Output:
COMBINE: <task numbers to combine>
NEW_TITLE: <combined task title>
REASON: <brief reason>

Or output: NO_CONSOLIDATION if tasks should stay separate.
			]"
		end

	prioritize_system_ollama: STRING_8
			-- Ollama system prompt for prioritization.
		once
			Result := "[
Reorder tasks by priority. Output task numbers in order:
ORDER: 3, 1, 4, 2 (example)
TOP_REASON: <why #1 is first>

Only output ORDER and TOP_REASON.
			]"
		end

feature {NONE} -- Rich Prompts (Claude/Grok)

	parse_task_system_rich: STRING_8
			-- Rich system prompt for task parsing.
		once
			Result := "[
You are a task parsing assistant. Extract structured information from natural language task descriptions.

Parse the input and return a JSON object with these fields:
- title: The task title (required, string)
- description: Additional details (optional, string)
- priority: 1-5 where 1=highest (default 3)
- due_date: ISO date YYYY-MM-DD or null
- context: One of "office", "home", "phone", "errands" or null
- energy_level: 1=low, 2=medium, 3=high focus needed (default 2)

Examples:
- "call mom tomorrow" -> {"title": "Call mom", "priority": 3, "context": "phone", "due_date": "...tomorrow's date..."}
- "urgent: fix production bug" -> {"title": "Fix production bug", "priority": 1, "energy_level": 3}

Return only the JSON object.
			]"
		end

	suggest_subtasks_system_rich: STRING_8
			-- Rich system prompt for subtasks.
		once
			Result := "[
You are a project planning assistant. Given a task, suggest logical subtasks to break it down.

Consider:
- What are the natural steps to complete this?
- What might block progress if not done first?
- Are there parallel tasks that could be done simultaneously?

Return a JSON array of subtask objects:
[
  {"title": "...", "priority": N, "order": N},
  ...
]

Suggest 3-5 subtasks. Order them logically.
			]"
		end

	resolve_block_system_rich: STRING_8
			-- Rich system prompt for block resolution.
		once
			Result := "[
You are a productivity coach. A task is blocked by other incomplete tasks.

Analyze the situation and suggest the best approach:

1. **Work Around**: Suggest an alternative task to work on now that isn't blocked
2. **Split the Task**: If the blocked task can be partially done, suggest how to split it
3. **Escalate/Delegate**: If a blocking task could be delegated or needs attention
4. **Wait Strategically**: If waiting is truly the best option, explain what to wait for

Return a JSON object:
{
  "recommendation": "work_around" | "split" | "escalate" | "wait",
  "explanation": "...",
  "action": "..." (specific action to take),
  "alternative_tasks": [...] (if work_around)
}
			]"
		end

	split_task_system_rich: STRING_8
			-- Rich system prompt for splitting tasks.
		once
			Result := "[
You are a project planning assistant. Break down a large task into smaller, actionable pieces.

Guidelines:
- Each subtask should be completable in a single work session
- Subtasks should have clear outcomes
- Consider dependencies between subtasks
- Aim for 2-4 subtasks unless the task is very complex

Return a JSON array:
[
  {"title": "...", "description": "...", "estimated_minutes": N, "order": N},
  ...
]
			]"
		end

	consolidate_tasks_system_rich: STRING_8
			-- Rich system prompt for consolidating.
		once
			Result := "[
You are a productivity optimizer. Review these tasks for potential consolidation.

Look for:
- Tasks that are really the same thing described differently
- Tasks that could be batched together efficiently
- Tasks that are substeps of a larger implicit task

Return a JSON object:
{
  "should_consolidate": true/false,
  "groups": [
    {
      "task_indices": [0, 2],
      "new_title": "...",
      "reason": "..."
    }
  ],
  "keep_separate": [1, 3] // indices of tasks to keep as-is
}
			]"
		end

	prioritize_system_rich: STRING_8
			-- Rich system prompt for prioritization.
		once
			Result := "[
You are a productivity coach using the Eisenhower Matrix (urgent/important).

Prioritize the tasks considering:
- Urgency (deadlines, time-sensitive)
- Importance (impact, consequences of not doing)
- Dependencies (what unblocks other work)
- Energy match (hard tasks when fresh, easy when tired)

Return a JSON object:
{
  "ordered_indices": [2, 0, 3, 1],
  "reasoning": {
    "top_priority": "...",
    "can_defer": "...",
    "quick_wins": [...]
  }
}
			]"
		end

invariant
	provider_not_empty: not provider.is_empty

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
