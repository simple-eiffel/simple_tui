note
	description: "Test application for simple_tui"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			print ("Running simple_tui tests...%N%N")
			passed := 0
			failed := 0

			run_lib_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_lib_tests
		do
			create lib_tests
			-- Color tests
			run_test (agent lib_tests.test_color_default, "test_color_default")
			run_test (agent lib_tests.test_color_indexed, "test_color_indexed")
			run_test (agent lib_tests.test_color_indexed_edge_cases, "test_color_indexed_edge_cases")
			run_test (agent lib_tests.test_color_rgb, "test_color_rgb")
			run_test (agent lib_tests.test_color_rgb_edge_cases, "test_color_rgb_edge_cases")
			run_test (agent lib_tests.test_color_named, "test_color_named")
			run_test (agent lib_tests.test_color_same_color, "test_color_same_color")
			-- Style tests
			run_test (agent lib_tests.test_style_default, "test_style_default")
			run_test (agent lib_tests.test_style_attributes, "test_style_attributes")
			run_test (agent lib_tests.test_style_fluent_api, "test_style_fluent_api")
			run_test (agent lib_tests.test_style_inverted, "test_style_inverted")
			run_test (agent lib_tests.test_style_merged, "test_style_merged")
			run_test (agent lib_tests.test_style_same_style, "test_style_same_style")
			-- Cell tests
			run_test (agent lib_tests.test_cell_basic, "test_cell_basic")
			run_test (agent lib_tests.test_cell_wide_chars, "test_cell_wide_chars")
			run_test (agent lib_tests.test_cell_same_cell, "test_cell_same_cell")
			-- Buffer tests
			run_test (agent lib_tests.test_buffer_basic, "test_buffer_basic")
			run_test (agent lib_tests.test_buffer_put_get, "test_buffer_put_get")
			run_test (agent lib_tests.test_buffer_put_string, "test_buffer_put_string")
			run_test (agent lib_tests.test_buffer_boundaries, "test_buffer_boundaries")
			run_test (agent lib_tests.test_buffer_resize, "test_buffer_resize")
			run_test (agent lib_tests.test_buffer_resize_edge_cases, "test_buffer_resize_edge_cases")
			-- Label tests
			run_test (agent lib_tests.test_label_basic, "test_label_basic")
			run_test (agent lib_tests.test_label_empty_text, "test_label_empty_text")
			run_test (agent lib_tests.test_label_alignment, "test_label_alignment")
			run_test (agent lib_tests.test_label_wrapping, "test_label_wrapping")
			-- Button tests
			run_test (agent lib_tests.test_button_basic, "test_button_basic")
			run_test (agent lib_tests.test_button_states, "test_button_states")
			-- Text field tests
			run_test (agent lib_tests.test_textfield_basic, "test_textfield_basic")
			run_test (agent lib_tests.test_textfield_editing, "test_textfield_editing")
			run_test (agent lib_tests.test_textfield_cursor_movement, "test_textfield_cursor_movement")
			run_test (agent lib_tests.test_textfield_cursor_boundary, "test_textfield_cursor_boundary")
			run_test (agent lib_tests.test_textfield_max_length, "test_textfield_max_length")
			run_test (agent lib_tests.test_textfield_password_mode, "test_textfield_password_mode")
			run_test (agent lib_tests.test_textfield_delete, "test_textfield_delete")
			-- Progress tests
			run_test (agent lib_tests.test_progress_basic, "test_progress_basic")
			run_test (agent lib_tests.test_progress_set_value, "test_progress_set_value")
			run_test (agent lib_tests.test_progress_clamping, "test_progress_clamping")
			run_test (agent lib_tests.test_progress_custom_range, "test_progress_custom_range")
			run_test (agent lib_tests.test_progress_increment, "test_progress_increment")
			run_test (agent lib_tests.test_progress_indeterminate, "test_progress_indeterminate")
			-- List tests
			run_test (agent lib_tests.test_list_basic, "test_list_basic")
			run_test (agent lib_tests.test_list_add_items, "test_list_add_items")
			run_test (agent lib_tests.test_list_navigation, "test_list_navigation")
			run_test (agent lib_tests.test_list_navigation_boundaries, "test_list_navigation_boundaries")
			run_test (agent lib_tests.test_list_remove_items, "test_list_remove_items")
			run_test (agent lib_tests.test_list_clear, "test_list_clear")
			run_test (agent lib_tests.test_list_scrolling, "test_list_scrolling")
			-- Checkbox tests
			run_test (agent lib_tests.test_checkbox_basic, "test_checkbox_basic")
			run_test (agent lib_tests.test_checkbox_toggle, "test_checkbox_toggle")
			run_test (agent lib_tests.test_checkbox_check_uncheck, "test_checkbox_check_uncheck")
			run_test (agent lib_tests.test_checkbox_indeterminate, "test_checkbox_indeterminate")
			-- Layout tests
			run_test (agent lib_tests.test_vbox_layout, "test_vbox_layout")
			run_test (agent lib_tests.test_hbox_layout, "test_hbox_layout")
			run_test (agent lib_tests.test_box_with_gap, "test_box_with_gap")
			run_test (agent lib_tests.test_nested_layout, "test_nested_layout")
			-- Widget tests
			run_test (agent lib_tests.test_widget_position, "test_widget_position")
			run_test (agent lib_tests.test_widget_size, "test_widget_size")
			run_test (agent lib_tests.test_widget_visibility, "test_widget_visibility")
			run_test (agent lib_tests.test_widget_focus, "test_widget_focus")
			run_test (agent lib_tests.test_widget_absolute_position, "test_widget_absolute_position")
			run_test (agent lib_tests.test_widget_contains_point, "test_widget_contains_point")
			-- Event tests
			run_test (agent lib_tests.test_event_key, "test_event_key")
			run_test (agent lib_tests.test_event_char, "test_event_char")
			run_test (agent lib_tests.test_event_mouse, "test_event_mouse")
			run_test (agent lib_tests.test_event_modifiers, "test_event_modifiers")
			run_test (agent lib_tests.test_event_resize, "test_event_resize")
			-- Backend tests (these would have caught the strlen/STRING_32 bug)
			run_test (agent lib_tests.test_backend_output_buffer_type, "test_backend_output_buffer_type")
			run_test (agent lib_tests.test_backend_utf8_encoding_ascii, "test_backend_utf8_encoding_ascii")
			run_test (agent lib_tests.test_backend_utf8_encoding_2byte, "test_backend_utf8_encoding_2byte")
			run_test (agent lib_tests.test_backend_utf8_encoding_3byte, "test_backend_utf8_encoding_3byte")
			run_test (agent lib_tests.test_backend_utf8_encoding_box_drawing, "test_backend_utf8_encoding_box_drawing")
			run_test (agent lib_tests.test_backend_escape_sequence, "test_backend_escape_sequence")
			run_test (agent lib_tests.test_backend_box_drawing_chars, "test_backend_box_drawing_chars")
			run_test (agent lib_tests.test_backend_output_is_utf16, "test_backend_output_is_utf16")
			-- Label UTF-8 test
			run_test (agent lib_tests.test_label_utf8_box_drawing, "test_label_utf8_box_drawing")
			run_test (agent lib_tests.test_full_render_pipeline_box_drawing, "test_full_render_pipeline_box_drawing")
		end

feature {NONE} -- Implementation

	lib_tests: LIB_TESTS

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
