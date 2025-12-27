note
	description: "Comprehensive tests for simple_tui library"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Test Cases: TUI_COLOR

	test_color_default
			-- Test default color.
		local
			l_color: TUI_COLOR
		do
			create l_color.make_default
			assert ("is_default", l_color.is_default)
			assert ("not_indexed", not l_color.is_indexed)
			assert ("not_rgb", not l_color.is_rgb)
		end

	test_color_indexed
			-- Test indexed color.
		local
			l_color: TUI_COLOR
		do
			create l_color.make_index (42)
			assert ("is_indexed", l_color.is_indexed)
			assert_integers_equal ("index_value", 42, l_color.index)
			assert ("not_default", not l_color.is_default)
		end

	test_color_indexed_edge_cases
			-- Test indexed color boundaries.
		local
			l_color: TUI_COLOR
		do
			-- Minimum index
			create l_color.make_index (0)
			assert_integers_equal ("min_index", 0, l_color.index)

			-- Maximum index
			create l_color.make_index (255)
			assert_integers_equal ("max_index", 255, l_color.index)
		end

	test_color_rgb
			-- Test RGB color.
		local
			l_color: TUI_COLOR
		do
			create l_color.make_rgb (128, 64, 255)
			assert ("is_rgb", l_color.is_rgb)
			assert_integers_equal ("red", 128, l_color.red_value)
			assert_integers_equal ("green", 64, l_color.green_value)
			assert_integers_equal ("blue", 255, l_color.blue_value)
		end

	test_color_rgb_edge_cases
			-- Test RGB boundaries.
		local
			l_color: TUI_COLOR
		do
			-- All zeros
			create l_color.make_rgb (0, 0, 0)
			assert_integers_equal ("black_r", 0, l_color.red_value)
			assert_integers_equal ("black_g", 0, l_color.green_value)
			assert_integers_equal ("black_b", 0, l_color.blue_value)

			-- All max
			create l_color.make_rgb (255, 255, 255)
			assert_integers_equal ("white_r", 255, l_color.red_value)
			assert_integers_equal ("white_g", 255, l_color.green_value)
			assert_integers_equal ("white_b", 255, l_color.blue_value)
		end

	test_color_named
			-- Test named colors.
		local
			l_color: TUI_COLOR
		do
			create l_color.make_named ("red")
			assert ("is_indexed", l_color.is_indexed)
			assert_integers_equal ("red_index", 1, l_color.index)

			create l_color.make_named ("bright_cyan")
			assert_integers_equal ("bright_cyan_index", 14, l_color.index)
		end

	test_color_same_color
			-- Test color comparison.
		local
			l_c1, l_c2, l_c3: TUI_COLOR
		do
			create l_c1.make_rgb (100, 100, 100)
			create l_c2.make_rgb (100, 100, 100)
			create l_c3.make_rgb (100, 100, 101)

			assert ("same_rgb", l_c1.same_color (l_c2))
			assert ("diff_rgb", not l_c1.same_color (l_c3))

			create l_c1.make_default
			create l_c2.make_default
			assert ("same_default", l_c1.same_color (l_c2))
		end

feature -- Test Cases: TUI_STYLE

	test_style_default
			-- Test default style.
		local
			l_style: TUI_STYLE
		do
			create l_style.make_default
			assert ("fg_default", l_style.foreground.is_default)
			assert ("bg_default", l_style.background.is_default)
			assert ("not_bold", not l_style.is_bold)
			assert ("not_italic", not l_style.is_italic)
		end

	test_style_attributes
			-- Test style attributes.
		local
			l_style: TUI_STYLE
		do
			create l_style.make
			l_style.set_bold (True)
			l_style.set_italic (True)
			l_style.set_underline (True)
			assert ("is_bold", l_style.is_bold)
			assert ("is_italic", l_style.is_italic)
			assert ("is_underline", l_style.is_underline)
			assert ("not_blink", not l_style.is_blink)

			-- Toggle off
			l_style.set_bold (False)
			assert ("bold_off", not l_style.is_bold)
			assert ("still_italic", l_style.is_italic)
		end

	test_style_fluent_api
			-- Test fluent style API.
		local
			l_style: TUI_STYLE
		do
			create l_style.make
			l_style := l_style.bold.italic.underline
			assert ("fluent_bold", l_style.is_bold)
			assert ("fluent_italic", l_style.is_italic)
			assert ("fluent_underline", l_style.is_underline)
		end

	test_style_inverted
			-- Test style inversion.
		local
			l_style, l_inv: TUI_STYLE
			l_fg, l_bg: TUI_COLOR
		do
			create l_fg.make_index (1)
			create l_bg.make_index (0)
			create l_style.make_with_colors (l_fg, l_bg)

			l_inv := l_style.inverted
			assert ("fg_swapped", l_inv.foreground.same_color (l_bg))
			assert ("bg_swapped", l_inv.background.same_color (l_fg))
		end

	test_style_merged
			-- Test style merging.
		local
			l_s1, l_s2, l_merged: TUI_STYLE
		do
			create l_s1.make
			l_s1.set_bold (True)

			create l_s2.make
			l_s2.set_italic (True)

			l_merged := l_s1.merged (l_s2)
			assert ("merged_bold", l_merged.is_bold)
			assert ("merged_italic", l_merged.is_italic)
		end

	test_style_same_style
			-- Test style comparison.
		local
			l_s1, l_s2: TUI_STYLE
		do
			create l_s1.make
			l_s1.set_bold (True)

			create l_s2.make
			l_s2.set_bold (True)

			assert ("same_style", l_s1.same_style (l_s2))

			l_s2.set_italic (True)
			assert ("diff_style", not l_s1.same_style (l_s2))
		end

feature -- Test Cases: TUI_CELL

	test_cell_basic
			-- Test basic cell.
		local
			l_cell: TUI_CELL
			l_style: TUI_STYLE
		do
			create l_style.make_default
			create l_cell.make_with_styled_char ('A', l_style)
			assert ("char", l_cell.char = 'A')
			assert_integers_equal ("char_width", 1, l_cell.char_width)
		end

	test_cell_wide_chars
			-- Test wide character detection.
		local
			l_cell: TUI_CELL
			l_style: TUI_STYLE
		do
			create l_style.make_default

			-- ASCII (width 1)
			create l_cell.make_with_styled_char ('X', l_style)
			assert_integers_equal ("ascii_width", 1, l_cell.char_width)

			-- CJK character (width 2) - U+4E2D
			create l_cell.make_with_styled_char ('%/0x4E2D/', l_style)
			assert_integers_equal ("cjk_width", 2, l_cell.char_width)
		end

	test_cell_same_cell
			-- Test cell comparison.
		local
			l_c1, l_c2: TUI_CELL
			l_style: TUI_STYLE
		do
			create l_style.make_default
			create l_c1.make_with_styled_char ('X', l_style)
			create l_c2.make_with_styled_char ('X', l_style)
			assert ("same_cell", l_c1.same_cell (l_c2))

			create l_c2.make_with_styled_char ('Y', l_style)
			assert ("diff_cell", not l_c1.same_cell (l_c2))
		end

feature -- Test Cases: TUI_BUFFER

	test_buffer_basic
			-- Test basic buffer operations.
		local
			l_buf: TUI_BUFFER
		do
			create l_buf.make (80, 24)
			assert_integers_equal ("width", 80, l_buf.width)
			assert_integers_equal ("height", 24, l_buf.height)
		end

	test_buffer_put_get
			-- Test put and get operations.
		local
			l_buf: TUI_BUFFER
			l_style: TUI_STYLE
			l_cell: TUI_CELL
		do
			create l_buf.make (10, 10)
			create l_style.make_default

			l_buf.put_char (5, 5, 'X', l_style)
			l_cell := l_buf.cell_at (5, 5)
			assert ("retrieved_char", l_cell.char = 'X')
		end

	test_buffer_put_string
			-- Test string operations.
		local
			l_buf: TUI_BUFFER
			l_style: TUI_STYLE
		do
			create l_buf.make (20, 5)
			create l_style.make_default

			l_buf.put_string (1, 1, "Hello", l_style)
			assert ("char_H", l_buf.cell_at (1, 1).char = 'H')
			assert ("char_e", l_buf.cell_at (2, 1).char = 'e')
			assert ("char_o", l_buf.cell_at (5, 1).char = 'o')
		end

	test_buffer_boundaries
			-- Test boundary conditions.
		local
			l_buf: TUI_BUFFER
			l_style: TUI_STYLE
		do
			create l_buf.make (10, 10)
			create l_style.make_default

			-- Corners
			l_buf.put_char (1, 1, 'A', l_style)
			l_buf.put_char (10, 10, 'Z', l_style)

			assert ("top_left", l_buf.cell_at (1, 1).char = 'A')
			assert ("bottom_right", l_buf.cell_at (10, 10).char = 'Z')
		end

	test_buffer_resize
			-- Test buffer resize.
		local
			l_buf: TUI_BUFFER
		do
			create l_buf.make (10, 10)
			l_buf.resize (20, 15)
			assert_integers_equal ("new_width", 20, l_buf.width)
			assert_integers_equal ("new_height", 15, l_buf.height)
		end

	test_buffer_resize_edge_cases
			-- Test edge case resizes.
		local
			l_buf: TUI_BUFFER
		do
			create l_buf.make (10, 10)

			-- Shrink to minimum
			l_buf.resize (1, 1)
			assert_integers_equal ("min_width", 1, l_buf.width)
			assert_integers_equal ("min_height", 1, l_buf.height)

			-- Expand large
			l_buf.resize (200, 100)
			assert_integers_equal ("large_width", 200, l_buf.width)
		end

feature -- Test Cases: TUI_LABEL

	test_label_basic
			-- Test basic label.
		local
			l_label: TUI_LABEL
		do
			create l_label.make_with_text ("Hello")
			assert ("text", l_label.text.same_string ("Hello"))
			assert_integers_equal ("width", 5, l_label.width)
		end

	test_label_empty_text
			-- Test empty label.
		local
			l_label: TUI_LABEL
		do
			create l_label.make_with_text ("")
			assert ("empty_text", l_label.text.is_empty)
			assert_integers_equal ("min_width", 1, l_label.width)  -- Minimum 1
		end

	test_label_alignment
			-- Test label alignment.
		local
			l_label: TUI_LABEL
		do
			create l_label.make (20)
			l_label.set_text ("Test")

			l_label.set_align (l_label.Align_left)
			assert_integers_equal ("align_left", l_label.Align_left, l_label.align)

			l_label.set_align (l_label.Align_center)
			assert_integers_equal ("align_center", l_label.Align_center, l_label.align)

			l_label.set_align (l_label.Align_right)
			assert_integers_equal ("align_right", l_label.Align_right, l_label.align)
		end

	test_label_wrapping
			-- Test word wrapping.
		local
			l_label: TUI_LABEL
		do
			create l_label.make (10)
			l_label.set_text ("Hello World Test")
			l_label.set_wrap (True)

			assert ("wrap_enabled", l_label.wrap)
			assert ("multi_line", l_label.preferred_height > 1)
		end

feature -- Test Cases: TUI_BUTTON

	test_button_basic
			-- Test basic button.
		local
			l_btn: TUI_BUTTON
		do
			create l_btn.make ("Click Me")
			assert ("label", l_btn.label.same_string ("Click Me"))
			assert ("focusable", l_btn.is_focusable)
			assert ("enabled", l_btn.is_enabled)
		end

	test_button_states
			-- Test button states.
		local
			l_btn: TUI_BUTTON
		do
			create l_btn.make ("Test")
			assert ("not_pressed", not l_btn.is_pressed)

			l_btn.set_enabled (False)
			assert ("disabled_not_pressed", not l_btn.is_pressed)
		end

feature -- Test Cases: TUI_TEXT_FIELD

	test_textfield_basic
			-- Test basic text field.
		local
			l_tf: TUI_TEXT_FIELD
		do
			create l_tf.make (20)
			assert_integers_equal ("width", 20, l_tf.width)
			assert ("empty", l_tf.text.is_empty)
			assert_integers_equal ("cursor_at_0", 0, l_tf.cursor_position)
		end

	test_textfield_editing
			-- Test text editing.
		local
			l_tf: TUI_TEXT_FIELD
		do
			create l_tf.make (20)

			l_tf.insert_char ('H')
			l_tf.insert_char ('i')
			assert ("text_Hi", l_tf.text.same_string ("Hi"))
			assert_integers_equal ("cursor_at_2", 2, l_tf.cursor_position)

			l_tf.backspace
			assert ("after_backspace", l_tf.text.same_string ("H"))
			assert_integers_equal ("cursor_at_1", 1, l_tf.cursor_position)
		end

	test_textfield_cursor_movement
			-- Test cursor movement.
		local
			l_tf: TUI_TEXT_FIELD
		do
			create l_tf.make (20)
			l_tf.set_text ("Hello")

			assert_integers_equal ("cursor_at_end", 5, l_tf.cursor_position)

			l_tf.move_home
			assert_integers_equal ("cursor_at_home", 0, l_tf.cursor_position)

			l_tf.move_right
			assert_integers_equal ("cursor_moved_right", 1, l_tf.cursor_position)

			l_tf.move_end
			assert_integers_equal ("cursor_at_end_again", 5, l_tf.cursor_position)
		end

	test_textfield_cursor_boundary
			-- Test cursor boundary conditions.
		local
			l_tf: TUI_TEXT_FIELD
		do
			create l_tf.make (20)
			l_tf.set_text ("ABC")

			-- Can't go past end
			l_tf.move_right
			assert_integers_equal ("cant_pass_end", 3, l_tf.cursor_position)

			-- Can't go before start
			l_tf.move_home
			l_tf.move_left
			assert_integers_equal ("cant_go_negative", 0, l_tf.cursor_position)

			-- Backspace at start does nothing
			l_tf.backspace
			assert ("text_unchanged", l_tf.text.same_string ("ABC"))
		end

	test_textfield_max_length
			-- Test max length constraint.
		local
			l_tf: TUI_TEXT_FIELD
		do
			create l_tf.make (20)
			l_tf.set_max_length (5)

			l_tf.set_text ("Hello World")  -- Should truncate
			assert ("truncated", l_tf.text.same_string ("Hello"))

			-- Can't insert more
			l_tf.insert_char ('!')
			assert_integers_equal ("still_5", 5, l_tf.text.count)
		end

	test_textfield_password_mode
			-- Test password mode.
		local
			l_tf: TUI_TEXT_FIELD
		do
			create l_tf.make (20)
			l_tf.set_password (True)
			assert ("password_mode", l_tf.is_password)

			l_tf.set_text ("secret")
			assert ("text_stored", l_tf.text.same_string ("secret"))
		end

	test_textfield_delete
			-- Test delete operation.
		local
			l_tf: TUI_TEXT_FIELD
		do
			create l_tf.make (20)
			l_tf.set_text ("ABCD")
			l_tf.move_home

			l_tf.delete_char  -- Delete 'A'
			assert ("after_delete", l_tf.text.same_string ("BCD"))

			-- Cursor stays at 0
			assert_integers_equal ("cursor_still_0", 0, l_tf.cursor_position)
		end

feature -- Test Cases: TUI_PROGRESS

	test_progress_basic
			-- Test basic progress bar.
		local
			l_prog: TUI_PROGRESS
		do
			create l_prog.make (20)
			assert_integers_equal ("width", 20, l_prog.width)
			assert ("min", l_prog.min_value = 0.0)
			assert ("max", l_prog.max_value = 100.0)
			assert ("value", l_prog.current_value = 0.0)
		end

	test_progress_set_value
			-- Test value setting.
		local
			l_prog: TUI_PROGRESS
		do
			create l_prog.make (20)
			l_prog.set_value (50.0)
			assert ("value_50", l_prog.current_value = 50.0)
			assert ("percentage_50", l_prog.percentage = 50.0)
		end

	test_progress_clamping
			-- Test value clamping.
		local
			l_prog: TUI_PROGRESS
		do
			create l_prog.make (20)

			l_prog.set_value (-10.0)  -- Below min
			assert ("clamped_to_min", l_prog.current_value = 0.0)

			l_prog.set_value (200.0)  -- Above max
			assert ("clamped_to_max", l_prog.current_value = 100.0)
		end

	test_progress_custom_range
			-- Test custom range.
		local
			l_prog: TUI_PROGRESS
		do
			create l_prog.make (20)
			l_prog.set_range (10.0, 20.0)

			l_prog.set_value (15.0)
			assert ("midpoint", l_prog.percentage = 50.0)
		end

	test_progress_increment
			-- Test increment.
		local
			l_prog: TUI_PROGRESS
		do
			create l_prog.make (20)
			l_prog.set_value (10.0)
			l_prog.increment (5.0)
			assert ("incremented", l_prog.current_value = 15.0)
		end

	test_progress_indeterminate
			-- Test indeterminate mode.
		local
			l_prog: TUI_PROGRESS
		do
			create l_prog.make (20)
			l_prog.set_indeterminate (True)
			assert ("is_indeterminate", l_prog.is_indeterminate)

			l_prog.tick
			assert_integers_equal ("position_moved", 1, l_prog.indeterminate_position)
		end

feature -- Test Cases: TUI_LIST

	test_list_basic
			-- Test basic list.
		local
			l_list: TUI_LIST
		do
			create l_list.make (20, 10)
			assert_integers_equal ("width", 20, l_list.width)
			assert_integers_equal ("height", 10, l_list.height)
			assert ("empty", l_list.is_empty)
		end

	test_list_add_items
			-- Test adding items.
		local
			l_list: TUI_LIST
		do
			create l_list.make (20, 5)
			l_list.add_item ("Item 1")
			l_list.add_item ("Item 2")
			l_list.add_item ("Item 3")

			assert_integers_equal ("count_3", 3, l_list.count)
			assert_integers_equal ("selected_1", 1, l_list.selected_index)  -- Auto-select first
		end

	test_list_navigation
			-- Test navigation.
		local
			l_list: TUI_LIST
		do
			create l_list.make (20, 5)
			l_list.add_item ("A")
			l_list.add_item ("B")
			l_list.add_item ("C")

			l_list.select_next
			assert_integers_equal ("moved_to_2", 2, l_list.selected_index)

			l_list.select_previous
			assert_integers_equal ("back_to_1", 1, l_list.selected_index)

			l_list.select_last
			assert_integers_equal ("at_last", 3, l_list.selected_index)

			l_list.select_first
			assert_integers_equal ("at_first", 1, l_list.selected_index)
		end

	test_list_navigation_boundaries
			-- Test navigation at boundaries.
		local
			l_list: TUI_LIST
		do
			create l_list.make (20, 5)
			l_list.add_item ("Only")

			l_list.select_previous  -- Can't go before first
			assert_integers_equal ("still_1", 1, l_list.selected_index)

			l_list.select_next  -- Can't go past last
			assert_integers_equal ("still_1_again", 1, l_list.selected_index)
		end

	test_list_remove_items
			-- Test item removal.
		local
			l_list: TUI_LIST
		do
			create l_list.make (20, 5)
			l_list.add_item ("A")
			l_list.add_item ("B")
			l_list.add_item ("C")

			l_list.set_selected_index (2)
			l_list.remove_item (1)

			assert_integers_equal ("count_after_remove", 2, l_list.count)
		end

	test_list_clear
			-- Test clearing list.
		local
			l_list: TUI_LIST
		do
			create l_list.make (20, 5)
			l_list.add_item ("A")
			l_list.add_item ("B")

			l_list.clear_items

			assert ("is_empty", l_list.is_empty)
			assert_integers_equal ("no_selection", 0, l_list.selected_index)
		end

	test_list_scrolling
			-- Test scroll behavior.
		local
			l_list: TUI_LIST
			i: INTEGER
		do
			create l_list.make (20, 3)  -- Only 3 visible

			from i := 1 until i > 10 loop
				l_list.add_item ("Item " + i.out)
				i := i + 1
			end

			l_list.select_last
			assert ("scrolled", l_list.scroll_offset > 0)
		end

feature -- Test Cases: TUI_CHECKBOX

	test_checkbox_basic
			-- Test basic checkbox.
		local
			l_cb: TUI_CHECKBOX
		do
			create l_cb.make ("Accept terms")
			assert ("label", l_cb.label.same_string ("Accept terms"))
			assert ("not_checked", not l_cb.is_checked)
			assert ("focusable", l_cb.is_focusable)
		end

	test_checkbox_toggle
			-- Test toggle.
		local
			l_cb: TUI_CHECKBOX
		do
			create l_cb.make ("Test")

			l_cb.toggle
			assert ("now_checked", l_cb.is_checked)

			l_cb.toggle
			assert ("now_unchecked", not l_cb.is_checked)
		end

	test_checkbox_check_uncheck
			-- Test explicit check/uncheck.
		local
			l_cb: TUI_CHECKBOX
		do
			create l_cb.make ("Test")

			l_cb.check_box
			assert ("checked", l_cb.is_checked)

			l_cb.uncheck
			assert ("unchecked", not l_cb.is_checked)
		end

	test_checkbox_indeterminate
			-- Test indeterminate state.
		local
			l_cb: TUI_CHECKBOX
		do
			create l_cb.make ("Test")

			l_cb.set_indeterminate (True)
			assert ("is_indeterminate", l_cb.is_indeterminate)

			-- Toggling clears indeterminate
			l_cb.toggle
			assert ("not_indeterminate", not l_cb.is_indeterminate)
		end

feature -- Test Cases: Layout

	test_vbox_layout
			-- Test vertical box layout.
		local
			l_box: TUI_VBOX
			l_l1, l_l2: TUI_LABEL
		do
			create l_box.make (20, 10)
			create l_l1.make_with_text ("First")
			create l_l2.make_with_text ("Second")

			l_box.add (l_l1)
			l_box.add (l_l2)

			-- Second label should be below first
			assert ("l2_below_l1", l_l2.y > l_l1.y)
		end

	test_hbox_layout
			-- Test horizontal box layout.
		local
			l_box: TUI_HBOX
			l_l1, l_l2: TUI_LABEL
		do
			create l_box.make (40, 5)
			create l_l1.make_with_text ("First")
			create l_l2.make_with_text ("Second")

			l_box.add (l_l1)
			l_box.add (l_l2)

			-- Second label should be to the right of first
			assert ("l2_right_of_l1", l_l2.x > l_l1.x)
		end

	test_box_with_gap
			-- Test box gap setting.
		local
			l_box: TUI_VBOX
			l_l1, l_l2: TUI_LABEL
		do
			create l_box.make (20, 20)
			l_box.set_gap (2)

			create l_l1.make_with_text ("A")
			create l_l2.make_with_text ("B")

			l_box.add (l_l1)
			l_box.add (l_l2)

			-- Gap of 2 + height 1 = 3 difference
			assert_integers_equal ("with_gap", 3, l_l2.y - l_l1.y)
		end

	test_nested_layout
			-- Test nested layouts.
		local
			l_outer: TUI_VBOX
			l_inner: TUI_HBOX
			l_label: TUI_LABEL
		do
			create l_outer.make (40, 20)
			create l_inner.make (40, 5)
			create l_label.make_with_text ("Nested")

			l_inner.add (l_label)
			l_outer.add (l_inner)

			assert ("parent_set", attached l_label.parent)
		end

feature -- Test Cases: Widget Base

	test_widget_position
			-- Test position setting.
		local
			l_label: TUI_LABEL
		do
			create l_label.make_with_text ("Test")
			l_label.set_position (5, 10)
			assert_integers_equal ("x", 5, l_label.x)
			assert_integers_equal ("y", 10, l_label.y)
		end

	test_widget_size
			-- Test size setting.
		local
			l_label: TUI_LABEL
		do
			create l_label.make_with_text ("Test")
			l_label.set_size (20, 3)
			assert_integers_equal ("width", 20, l_label.width)
			assert_integers_equal ("height", 3, l_label.height)
		end

	test_widget_visibility
			-- Test visibility.
		local
			l_label: TUI_LABEL
		do
			create l_label.make_with_text ("Test")
			assert ("visible_default", l_label.is_visible)

			l_label.hide
			assert ("hidden", not l_label.is_visible)

			l_label.show
			assert ("visible_again", l_label.is_visible)
		end

	test_widget_focus
			-- Test focus.
		local
			l_btn: TUI_BUTTON
		do
			create l_btn.make ("Test")
			assert ("focusable", l_btn.is_focusable)
			assert ("not_focused", not l_btn.is_focused)

			l_btn.focus
			assert ("focused", l_btn.is_focused)

			l_btn.unfocus
			assert ("unfocused", not l_btn.is_focused)
		end

	test_widget_absolute_position
			-- Test absolute position calculation.
		local
			l_box: TUI_VBOX
			l_label: TUI_LABEL
		do
			create l_box.make (40, 20)
			l_box.set_position (10, 5)

			create l_label.make_with_text ("Test")
			l_box.add (l_label)

			-- Label is at (1,1) relative to box, box is at (10,5)
			assert_integers_equal ("abs_x", 10, l_label.absolute_x)
			assert_integers_equal ("abs_y", 5, l_label.absolute_y)
		end

	test_widget_contains_point
			-- Test point containment.
		local
			l_label: TUI_LABEL
		do
			create l_label.make_with_text ("Test")
			l_label.set_position (10, 10)
			l_label.set_size (5, 2)

			-- Inside
			assert ("inside", l_label.contains_point (12, 11))

			-- Outside
			assert ("left", not l_label.contains_point (9, 10))
			assert ("right", not l_label.contains_point (15, 10))
			assert ("above", not l_label.contains_point (12, 9))
			assert ("below", not l_label.contains_point (12, 12))
		end

feature -- Test Cases: TUI_EVENT

	test_event_key
			-- Test key event creation.
		local
			l_event: TUI_EVENT
		do
			create l_event.make_key ({TUI_EVENT}.Key_enter, 0)
			assert ("is_key", l_event.is_key_event)
			assert_integers_equal ("key_enter", {TUI_EVENT}.Key_enter, l_event.key)
		end

	test_event_char
			-- Test char event.
		local
			l_event: TUI_EVENT
		do
			create l_event.make_char ('x', 0)
			assert ("is_char", l_event.is_char_event)
			assert ("char_x", l_event.char = 'x')
		end

	test_event_mouse
			-- Test mouse event.
		local
			l_event: TUI_EVENT
		do
			create l_event.make_mouse_press (10, 20, 1)
			assert ("is_mouse", l_event.is_mouse_event)
			assert ("is_press", l_event.is_mouse_press)
			assert_integers_equal ("mouse_x", 10, l_event.mouse_x)
			assert_integers_equal ("mouse_y", 20, l_event.mouse_y)
			assert_integers_equal ("button", 1, l_event.mouse_button)
		end

	test_event_modifiers
			-- Test modifier keys.
		local
			l_event: TUI_EVENT
		do
			create l_event.make_key ({TUI_EVENT}.Key_enter, {TUI_EVENT}.Mod_ctrl | {TUI_EVENT}.Mod_shift)
			assert ("has_ctrl", l_event.has_ctrl)
			assert ("has_shift", l_event.has_shift)
			assert ("no_alt", not l_event.has_alt)
		end

	test_event_resize
			-- Test resize event.
		local
			l_event: TUI_EVENT
		do
			create l_event.make_resize (120, 40)
			assert ("is_resize", l_event.is_resize_event)
			assert_integers_equal ("resize_w", 120, l_event.resize_width)
			assert_integers_equal ("resize_h", 40, l_event.resize_height)
		end

feature -- Test Cases: TUI_BACKEND_WINDOWS

	test_backend_output_buffer_type
			-- Test that output buffer is STRING_8 (not STRING_32).
			-- Bug: Using strlen() on STRING_32 gave wrong length.
		local
			l_backend: TUI_BACKEND_WINDOWS
		do
			create l_backend.make
			-- The buffer must be STRING_8 for WriteConsoleA to work
			-- This test would fail if buffer was STRING_32
			assert ("buffer_is_string_8", attached {STRING_8} l_backend.output_buffer_for_test)
		end

	test_backend_utf8_encoding_ascii
			-- Test UTF-8 encoding of ASCII characters.
		local
			l_backend: TUI_BACKEND_WINDOWS
		do
			create l_backend.make
			l_backend.test_append_char32 ('A')
			assert_integers_equal ("ascii_single_byte", 1, l_backend.output_buffer_for_test.count)
			assert ("ascii_value", l_backend.output_buffer_for_test.item (1) = 'A')
		end

	test_backend_utf8_encoding_2byte
			-- Test UTF-8 encoding of 2-byte characters (U+0080 to U+07FF).
		local
			l_backend: TUI_BACKEND_WINDOWS
		do
			create l_backend.make
			-- U+00E9 = é (Latin small letter e with acute)
			l_backend.test_append_char32 ('%/0x00E9/')
			assert_integers_equal ("2byte_char_length", 2, l_backend.output_buffer_for_test.count)
			-- UTF-8: C3 A9
			assert_integers_equal ("byte1", 0xC3, l_backend.output_buffer_for_test.item (1).code)
			assert_integers_equal ("byte2", 0xA9, l_backend.output_buffer_for_test.item (2).code)
		end

	test_backend_utf8_encoding_3byte
			-- Test UTF-8 encoding of 3-byte characters (U+0800 to U+FFFF).
		local
			l_backend: TUI_BACKEND_WINDOWS
		do
			create l_backend.make
			-- U+4E2D = 中 (CJK character)
			l_backend.test_append_char32 ('%/0x4E2D/')
			assert_integers_equal ("3byte_char_length", 3, l_backend.output_buffer_for_test.count)
			-- UTF-8: E4 B8 AD
			assert_integers_equal ("byte1", 0xE4, l_backend.output_buffer_for_test.item (1).code)
			assert_integers_equal ("byte2", 0xB8, l_backend.output_buffer_for_test.item (2).code)
			assert_integers_equal ("byte3", 0xAD, l_backend.output_buffer_for_test.item (3).code)
		end

	test_backend_utf8_encoding_box_drawing
			-- Test UTF-8 encoding of box drawing characters.
		local
			l_backend: TUI_BACKEND_WINDOWS
		do
			create l_backend.make
			-- U+2588 = █ (Full block, commonly used in TUI)
			l_backend.test_append_char32 ('%/0x2588/')
			assert_integers_equal ("box_char_length", 3, l_backend.output_buffer_for_test.count)
			-- UTF-8: E2 96 88
			assert_integers_equal ("byte1", 0xE2, l_backend.output_buffer_for_test.item (1).code)
			assert_integers_equal ("byte2", 0x96, l_backend.output_buffer_for_test.item (2).code)
			assert_integers_equal ("byte3", 0x88, l_backend.output_buffer_for_test.item (3).code)
		end

	test_backend_escape_sequence
			-- Test that ANSI escape sequences go to wide buffer.
		local
			l_backend: TUI_BACKEND_WINDOWS
		do
			create l_backend.make
			l_backend.set_cursor_position (5, 10)
			-- Should produce ESC[10;5H in wide buffer (for WriteConsoleW)
			assert ("has_content", not l_backend.wide_buffer_for_test.is_empty)
			assert ("starts_with_esc", l_backend.wide_buffer_for_test.item (1).natural_32_code = 27)
		end

	test_backend_box_drawing_chars
			-- Test box drawing characters in wide buffer.
			-- These were showing as 'â' when using UTF-8 + WriteConsoleA.
			-- Fix: Use STRING_32 + WriteConsoleW for proper Unicode output.
		local
			l_backend: TUI_BACKEND_WINDOWS
		do
			create l_backend.make
			-- U+2554 = ╔ (BOX DRAWINGS DOUBLE DOWN AND RIGHT) - used in demo title
			l_backend.test_append_char32 ('%/0x2554/')
			-- For WriteConsoleW (UTF-16), we need exactly 1 wide character
			-- The wide buffer should contain the character directly (no encoding)
			assert ("wide_buffer_has_char", l_backend.wide_buffer_for_test.count = 1)
			assert ("correct_codepoint", l_backend.wide_buffer_for_test.item (1).natural_32_code = 0x2554)
		end

	test_backend_output_is_utf16
			-- Verify output buffer uses UTF-16 for proper Windows console support.
			-- UTF-8 via WriteConsoleA was showing 'â' for box drawing chars.
		local
			l_backend: TUI_BACKEND_WINDOWS
		do
			create l_backend.make
			-- The output buffer must be STRING_32 (UTF-16 ready) for WriteConsoleW
			-- If it's STRING_8, box drawing chars will fail on Windows console
			assert ("buffer_is_utf16_ready", attached {STRING_32} l_backend.wide_buffer_for_test)
		end

	test_label_utf8_box_drawing
			-- Test that label correctly decodes UTF-8 box drawing characters.
		local
			l_label: TUI_LABEL
			l_utf8: STRING_8
		do
			-- Create UTF-8 string with ╔ (U+2554) = E2 95 94
			create l_utf8.make (3)
			l_utf8.append_character ('%/0xE2/')
			l_utf8.append_character ('%/0x95/')
			l_utf8.append_character ('%/0x94/')

			create l_label.make_with_text (l_utf8)

			-- Verify the label text has exactly 1 character (not 3 bytes)
			assert ("single_char", l_label.text.count = 1)
			-- Verify it's the correct Unicode codepoint
			assert ("correct_codepoint", l_label.text.item (1).natural_32_code = 0x2554)
		end

	test_full_render_pipeline_box_drawing
			-- Test entire render pipeline: label → buffer → backend → UTF-16 output.
		local
			l_label: TUI_LABEL
			l_buffer: TUI_BUFFER
			l_backend: TUI_BACKEND_WINDOWS
			l_cell: TUI_CELL
			l_converter: UTF_CONVERTER
			l_utf16: SPECIAL [NATURAL_16]
		do
			-- Create label with double-line corner ╔ (U+2554)
			create l_label.make_with_text ("%/0x2554/")
			l_label.set_position (1, 1)
			l_label.set_bounds (1, 1, 10, 1)

			-- Create buffer and render label to it
			create l_buffer.make (10, 1)
			l_label.render (l_buffer)

			-- Verify buffer cell has correct character
			l_cell := l_buffer.cell_at (1, 1)
			assert ("cell_correct", l_cell.character.natural_32_code = 0x2554)

			-- Simulate backend output
			create l_backend.make
			l_backend.wide_buffer_for_test.append_character (l_cell.character)

			-- Convert to UTF-16 and verify
			create l_converter
			l_utf16 := l_converter.string_32_to_utf_16 (l_backend.wide_buffer_for_test)
			assert ("utf16_single", l_utf16.count = 1)
			assert ("utf16_correct", l_utf16.item (0) = 0x2554)
		end

end
