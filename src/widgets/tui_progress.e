note
	description: "[
		TUI_PROGRESS - Progress bar widget

		Features:
		- Value l_range (min/max)
		- Multiple display styles (bar, blocks, percentage)
		- Indeterminate mode (spinner)
		- Custom fill characters
		- Optional label
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_PROGRESS

inherit
	TUI_WIDGET
		redefine
			preferred_width,
			preferred_height
		end

create
	make

feature {NONE} -- Initialization

	make (a_width: INTEGER)
			-- Create progress bar with width.
		require
			valid_width: a_width > 0
		do
			make_widget
			width := a_width
			height := 1
			min_value := 0.0
			max_value := 100.0
			current_value := 0.0
			is_indeterminate := False
			indeterminate_position := 0
			show_percentage := True
			label := ""
			fill_char := '%/0x2588/'      -- Full block
			empty_char := '%/0x2591/'     -- Light shade
			indeterminate_char := '%/0x2593/'  -- Dark shade
			create bar_style.make_default
			create fill_style.make_default
			create empty_style.make_default
		ensure
			width_set: width = a_width
		end

feature -- Access

	min_value: REAL_64
			-- Minimum value.

	max_value: REAL_64
			-- Maximum value.

	current_value: REAL_64
			-- Current value.

	is_indeterminate: BOOLEAN
			-- Show indeterminate (spinner) mode?

	indeterminate_position: INTEGER
			-- Current position for indeterminate animation.

	show_percentage: BOOLEAN
			-- Show percentage text?

	label: STRING_32
			-- Optional label text.

	fill_char: CHARACTER_32
			-- Character for filled portion.

	empty_char: CHARACTER_32
			-- Character for empty portion.

	indeterminate_char: CHARACTER_32
			-- Character for indeterminate indicator.

feature -- Styles

	bar_style: TUI_STYLE
			-- Overall bar style.

	fill_style: TUI_STYLE
			-- Style for filled portion.

	empty_style: TUI_STYLE
			-- Style for empty portion.

feature -- Modification

	set_range (a_min, a_max: REAL_64)
			-- Set value range.
		require
			valid_range: a_min < a_max
		do
			min_value := a_min
			max_value := a_max
			current_value := current_value.max (a_min).min (a_max)
		ensure
			min_set: min_value = a_min
			max_set: max_value = a_max
		end

	set_value (a_v: REAL_64)
			-- Set current value.
		do
			current_value := a_v.max (min_value).min (max_value)
		ensure
			value_clamped: current_value >= min_value and current_value <= max_value
		end

	set_percentage (a_p: REAL_64)
			-- Set value as percentage (0-100).
		do
			set_value (min_value + (max_value - min_value) * (a_p / 100.0))
		end

	increment (a_delta: REAL_64)
			-- Increment value by delta.
		do
			set_value (current_value + a_delta)
		end

	set_indeterminate (a_v: BOOLEAN)
			-- Set indeterminate mode.
		do
			is_indeterminate := a_v
		ensure
			indeterminate_set: is_indeterminate = a_v
		end

	set_show_percentage (a_v: BOOLEAN)
			-- Set whether to show percentage.
		do
			show_percentage := a_v
		ensure
			show_percentage_set: show_percentage = a_v
		end

	set_label (a_t: READABLE_STRING_GENERAL)
			-- Set label text.
		require
			t_exists: a_t /= Void
		do
			label := a_t.to_string_32
		ensure
			label_set: label.same_string_general (a_t)
		end

	set_fill_char (a_c: CHARACTER_32)
			-- Set fill character.
		do
			fill_char := a_c
		ensure
			fill_char_set: fill_char = a_c
		end

	set_empty_char (a_c: CHARACTER_32)
			-- Set empty character.
		do
			empty_char := a_c
		ensure
			empty_char_set: empty_char = a_c
		end

	set_bar_style (a_s: TUI_STYLE)
			-- Set bar style.
		require
			s_exists: a_s /= Void
		do
			bar_style := a_s
		ensure
			style_set: bar_style = a_s
		end

	set_fill_style (a_s: TUI_STYLE)
			-- Set fill style.
		require
			s_exists: a_s /= Void
		do
			fill_style := a_s
		ensure
			style_set: fill_style = a_s
		end

	set_empty_style (a_s: TUI_STYLE)
			-- Set empty style.
		require
			s_exists: a_s /= Void
		do
			empty_style := a_s
		ensure
			style_set: empty_style = a_s
		end

feature -- Animation

	tick
			-- Advance indeterminate animation.
		do
			indeterminate_position := (indeterminate_position + 1) \\ width
		end

feature -- Queries

	percentage: REAL_64
			-- Current value as percentage (0-100).
		local
			l_range: REAL_64
		do
			l_range := max_value - min_value
			if l_range > 0 then
				Result := ((current_value - min_value) / l_range) * 100.0
			else
				Result := 0.0
			end
		ensure
			valid_range: Result >= 0.0 and Result <= 100.0
		end

	preferred_width: INTEGER
			-- Preferred width.
		do
			Result := width
		end

	preferred_height: INTEGER
			-- Preferred height.
		do
			Result := 1
		end

feature -- Rendering

	render (a_buffer: TUI_BUFFER)
			-- Render progress bar to buffer.
		local
			ax, ay: INTEGER
			l_bar_width: INTEGER
			l_filled_count: INTEGER
			i: INTEGER
			l_pct_str: STRING_32
			l_pct_width: INTEGER
		do
			ax := absolute_x
			ay := absolute_y

			-- Calculate bar width (leave room for percentage if shown)
			if show_percentage then
				l_pct_str := formatted_percentage
				l_pct_width := l_pct_str.count + 1  -- Space + percentage
				l_bar_width := (width - l_pct_width).max (1)
			else
				l_bar_width := width
			end

			if is_indeterminate then
				render_indeterminate (a_buffer, ax, ay, l_bar_width)
			else
				-- Calculate filled portion
				l_filled_count := (l_bar_width * (percentage / 100.0)).truncated_to_integer

				-- Draw filled portion
				from i := 0 until i >= l_filled_count loop
					a_buffer.put_char (ax + i, ay, fill_char, fill_style)
					i := i + 1
				end

				-- Draw empty portion
				from until i >= l_bar_width loop
					a_buffer.put_char (ax + i, ay, empty_char, empty_style)
					i := i + 1
				end
			end

			-- Draw percentage
			if show_percentage then
				a_buffer.put_string (ax + l_bar_width + 1, ay, formatted_percentage, bar_style)
			end
		end

feature {NONE} -- Implementation

	render_indeterminate (a_buffer: TUI_BUFFER; ax, ay, l_bar_width: INTEGER)
			-- Render indeterminate progress bar.
		local
			i: INTEGER
			l_indicator_width: INTEGER
			start_pos, end_pos: INTEGER
		do
			l_indicator_width := (l_bar_width // 5).max (3)  -- Indicator is 1/5 of bar width
			start_pos := indeterminate_position
			end_pos := start_pos + l_indicator_width

			from i := 0 until i >= l_bar_width loop
				if i >= start_pos and i < end_pos then
					a_buffer.put_char (ax + i, ay, indeterminate_char, fill_style)
				elseif i >= (start_pos - l_bar_width) and i < (end_pos - l_bar_width) then
					-- Wrap around
					a_buffer.put_char (ax + i, ay, indeterminate_char, fill_style)
				else
					a_buffer.put_char (ax + i, ay, empty_char, empty_style)
				end
				i := i + 1
			end
		end

	formatted_percentage: STRING_32
			-- Percentage formatted as string.
		local
			l_pct: INTEGER
		do
			l_pct := percentage.truncated_to_integer
			create Result.make (5)
			if l_pct < 10 then
				Result.append_character (' ')
				Result.append_character (' ')
			elseif l_pct < 100 then
				Result.append_character (' ')
			end
			Result.append_integer (l_pct)
			Result.append_character ('%%')
		end

invariant
	valid_range: min_value < max_value
	value_in_range: current_value >= min_value and current_value <= max_value
	label_exists: label /= Void
	bar_style_exists: bar_style /= Void
	fill_style_exists: fill_style /= Void
	empty_style_exists: empty_style /= Void

end
