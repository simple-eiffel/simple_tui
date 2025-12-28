note
	description: "[
		TASK_BLOCK_RESOLUTION - Result of AI-assisted block resolution.

		Contains recommendation for how to handle a blocked task:
		- work_around: Do something else instead
		- split: Split the blocked task into smaller pieces
		- escalate: Need to escalate or delegate
		- wait: Just wait for blockers to complete
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TASK_BLOCK_RESOLUTION

create
	make

feature {NONE} -- Initialization

	make
			-- Create empty resolution.
		do
			recommendation := ""
			explanation := ""
			action := ""
			create alternatives.make (3)
			create split_tasks.make (3)
		end

feature -- Access

	recommendation: STRING_8
			-- Type of resolution: "work_around", "split", "escalate", "wait".

	explanation: STRING_8
			-- Human-readable explanation.

	action: STRING_8
			-- Specific action to take.

	alternatives: ARRAYED_LIST [TODO_ITEM]
			-- Alternative tasks to work on (for work_around).

	split_tasks: ARRAYED_LIST [TODO_ITEM]
			-- Suggested split tasks (for split recommendation).

feature -- Status Queries

	is_work_around: BOOLEAN
			-- Is this a work-around recommendation?
		do
			Result := recommendation.same_string ("work_around")
		end

	is_split: BOOLEAN
			-- Is this a split recommendation?
		do
			Result := recommendation.same_string ("split")
		end

	is_escalate: BOOLEAN
			-- Is this an escalate recommendation?
		do
			Result := recommendation.same_string ("escalate")
		end

	is_wait: BOOLEAN
			-- Is this a wait recommendation?
		do
			Result := recommendation.same_string ("wait")
		end

	has_alternatives: BOOLEAN
			-- Are there alternative tasks suggested?
		do
			Result := not alternatives.is_empty
		end

	has_split_tasks: BOOLEAN
			-- Are there split tasks suggested?
		do
			Result := not split_tasks.is_empty
		end

feature -- Modification

	set_recommendation (a_rec: READABLE_STRING_8)
			-- Set recommendation type.
		do
			recommendation := a_rec.twin
		ensure
			set: recommendation.same_string (a_rec)
		end

	set_explanation (a_exp: READABLE_STRING_8)
			-- Set explanation.
		do
			explanation := a_exp.twin
		ensure
			set: explanation.same_string (a_exp)
		end

	set_action (a_action: READABLE_STRING_8)
			-- Set specific action.
		do
			action := a_action.twin
		ensure
			set: action.same_string (a_action)
		end

	set_alternatives (a_alts: LIST [TODO_ITEM])
			-- Set alternative tasks.
		require
			alts_attached: a_alts /= Void
		do
			alternatives.wipe_out
			across a_alts as alt loop
				alternatives.extend (alt)
			end
		end

	add_alternative (a_task: TODO_ITEM)
			-- Add an alternative task.
		require
			task_attached: a_task /= Void
		do
			alternatives.extend (a_task)
		ensure
			added: alternatives.has (a_task)
		end

	set_split_tasks (a_tasks: LIST [TODO_ITEM])
			-- Set split task suggestions.
		require
			tasks_attached: a_tasks /= Void
		do
			split_tasks.wipe_out
			across a_tasks as t loop
				split_tasks.extend (t)
			end
		end

	add_split_task (a_task: TODO_ITEM)
			-- Add a split task suggestion.
		require
			task_attached: a_task /= Void
		do
			split_tasks.extend (a_task)
		ensure
			added: split_tasks.has (a_task)
		end

feature -- Output

	summary: STRING_8
			-- One-line summary of resolution.
		do
			create Result.make (100)
			if is_work_around then
				Result.append ("Work on something else: ")
				if has_alternatives then
					Result.append (alternatives.first.title)
				else
					Result.append (action)
				end
			elseif is_split then
				Result.append ("Split task into ")
				Result.append_integer (split_tasks.count)
				Result.append (" pieces")
			elseif is_escalate then
				Result.append ("Escalate: ")
				Result.append (action)
			else
				Result.append ("Wait: ")
				Result.append (action)
			end
		end

	full_description: STRING_8
			-- Full description of resolution.
		do
			create Result.make (500)
			Result.append ("Recommendation: ")
			Result.append (recommendation)
			Result.append ("%N")
			if not explanation.is_empty then
				Result.append ("Explanation: ")
				Result.append (explanation)
				Result.append ("%N")
			end
			if not action.is_empty then
				Result.append ("Action: ")
				Result.append (action)
				Result.append ("%N")
			end
			if has_alternatives then
				Result.append ("Alternatives:%N")
				across alternatives as alt loop
					Result.append ("  - ")
					Result.append (alt.title)
					Result.append ("%N")
				end
			end
			if has_split_tasks then
				Result.append ("Split into:%N")
				across split_tasks as t loop
					Result.append ("  - ")
					Result.append (t.title)
					Result.append ("%N")
				end
			end
		end

invariant
	alternatives_attached: alternatives /= Void
	split_tasks_attached: split_tasks /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
