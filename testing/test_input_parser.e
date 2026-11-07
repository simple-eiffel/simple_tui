note
	description: "Tests for TUI_INPUT_PARSER. Pure Eiffel, so these run on every platform."
	testing: "covers"

class
	TEST_INPUT_PARSER

inherit
	TEST_SET_BASE

feature -- Tests: keys

	test_arrow_and_home_keys
			-- Cursor keys in both their forms.
		do
			assert_integers_equal ("CSI up", {TUI_EVENT}.Key_up, parsed ("%/27/[A").key_code)
			assert_integers_equal ("CSI left", {TUI_EVENT}.Key_left, parsed ("%/27/[D").key_code)
			assert_integers_equal ("SS3 down", {TUI_EVENT}.Key_down, parsed ("%/27/OB").key_code)
			assert_integers_equal ("CSI home", {TUI_EVENT}.Key_home, parsed ("%/27/[H").key_code)
			assert_integers_equal ("tilde end", {TUI_EVENT}.Key_end, parsed ("%/27/[4~").key_code)
		end

	test_function_and_edit_keys
			-- F keys and the tilde family.
		do
			assert_integers_equal ("F1", {TUI_EVENT}.Key_f1, parsed ("%/27/OP").key_code)
			assert_integers_equal ("F5", {TUI_EVENT}.Key_f5, parsed ("%/27/[15~").key_code)
			assert_integers_equal ("F12", {TUI_EVENT}.Key_f12, parsed ("%/27/[24~").key_code)
			assert_integers_equal ("delete", {TUI_EVENT}.Key_delete, parsed ("%/27/[3~").key_code)
			assert_integers_equal ("page up", {TUI_EVENT}.Key_page_up, parsed ("%/27/[5~").key_code)
		end

	test_modifiers
			-- xterm's modifier parameter.
		local
			l_event: TUI_EVENT
		do
			l_event := parsed ("%/27/[1;5A")
			assert_integers_equal ("ctrl up", {TUI_EVENT}.Key_up, l_event.key_code)
			assert_integers_equal ("ctrl", {TUI_EVENT}.Mod_ctrl, l_event.modifiers)
			l_event := parsed ("%/27/[1;2C")
			assert_integers_equal ("shift", {TUI_EVENT}.Mod_shift, l_event.modifiers)
			l_event := parsed ("%/27/[Z")
			assert_integers_equal ("back tab", {TUI_EVENT}.Key_tab, l_event.key_code)
			assert_integers_equal ("shift tab", {TUI_EVENT}.Mod_shift, l_event.modifiers)
		end

feature -- Tests: characters

	test_control_characters
			-- Enter, Tab and Backspace read as the Windows console gives them.
		local
			l_event: TUI_EVENT
		do
			assert_true ("enter", parsed ("%R").is_enter)
			assert_true ("tab", parsed ("%T").is_tab)
			assert_true ("del is backspace", parsed ("%/127/").is_backspace)
			l_event := parsed ("%/3/")
			assert_integers_equal ("ctrl-c code", 3, l_event.character.code)
			assert_integers_equal ("ctrl-c", {TUI_EVENT}.Mod_ctrl, l_event.modifiers)
		end

	test_utf_8_text
			-- Plain, two, three and four byte characters.
		do
			assert_integers_equal ("ascii", 0x41, parsed ("A").character.code)
			assert_integers_equal ("e acute", 0xE9, parsed ("%/195/%/169/").character.code)
			assert_integers_equal ("euro", 0x20AC, parsed ("%/226/%/130/%/172/").character.code)
			assert_integers_equal ("emoji", 0x1F4D6, parsed ("%/240/%/159/%/147/%/150/").character.code)
		end

	test_alt_key
			-- ESC then a key is Alt with that key.
		local
			l_event: TUI_EVENT
		do
			l_event := parsed ("%/27/x")
			assert_integers_equal ("x", 0x78, l_event.character.code)
			assert_integers_equal ("alt", {TUI_EVENT}.Mod_alt, l_event.modifiers)
		end

feature -- Tests: mouse

	test_mouse_press_and_release
			-- SGR reports, with the button numbering the Windows backend uses.
		local
			l_event: TUI_EVENT
		do
			l_event := parsed ("%/27/[<0;12;7M")
			assert_integers_equal ("press type", {TUI_EVENT}.Type_mouse_press, l_event.event_type)
			assert_integers_equal ("x", 12, l_event.mouse_x)
			assert_integers_equal ("y", 7, l_event.mouse_y)
			assert_integers_equal ("left", 1, l_event.mouse_button)
			l_event := parsed ("%/27/[<2;3;4m")
			assert_integers_equal ("release type", {TUI_EVENT}.Type_mouse_release, l_event.event_type)
			assert_integers_equal ("right", 2, l_event.mouse_button)
			l_event := parsed ("%/27/[<1;3;4M")
			assert_integers_equal ("middle", 3, l_event.mouse_button)
			l_event := parsed ("%/27/[<32;9;9M")
			assert_integers_equal ("move type", {TUI_EVENT}.Type_mouse_move, l_event.event_type)
		end

feature -- Tests: split input

	test_lone_escape_waits_then_settles
			-- ESC alone may be the start of a sequence, until no more can come.
		local
			l_parser: TUI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.append_bytes ("%/27/")
			assert_void ("may be a sequence", l_parser.next_event (True))
			assert_true ("kept", l_parser.has_pending)
			if attached l_parser.next_event (False) as al_event then
				assert_integers_equal ("escape", {TUI_EVENT}.Key_escape, al_event.key_code)
			else
				assert_true ("settled", False)
			end
			assert_false ("consumed", l_parser.has_pending)
		end

	test_sequence_split_across_reads
			-- A sequence and a character each arrive in two reads.
		local
			l_parser: TUI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.append_bytes ("%/27/[1")
			assert_void ("unfinished", l_parser.next_event (True))
			l_parser.append_bytes ("5~")
			if attached l_parser.next_event (True) as al_event then
				assert_integers_equal ("F5", {TUI_EVENT}.Key_f5, al_event.key_code)
			else
				assert_true ("finished", False)
			end
			l_parser.append_bytes ("%/226/%/130/")
			assert_void ("half a character", l_parser.next_event (True))
			l_parser.append_bytes ("%/172/")
			if attached l_parser.next_event (True) as al_event then
				assert_integers_equal ("euro", 0x20AC, al_event.character.code)
			else
				assert_true ("whole", False)
			end
		end

	test_two_events_in_one_read
			-- Bytes for two events come out one at a time, in order.
		local
			l_parser: TUI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.append_bytes ("%/27/[Aq")
			if attached l_parser.next_event (True) as al_event then
				assert_integers_equal ("first", {TUI_EVENT}.Key_up, al_event.key_code)
			else
				assert_true ("first arrived", False)
			end
			if attached l_parser.next_event (True) as al_event then
				assert_integers_equal ("second", 0x71, al_event.character.code)
			else
				assert_true ("second arrived", False)
			end
			assert_false ("empty", l_parser.has_pending)
		end

	test_malformed_bytes_are_dropped
			-- A stray continuation byte makes no character.
		local
			l_event: TUI_EVENT
		do
			l_event := parsed ("%/128/")
			assert_integers_equal ("none", {TUI_EVENT}.Type_none, l_event.event_type)
		end

feature {NONE} -- Implementation

	parsed (a_bytes: STRING_8): TUI_EVENT
			-- The event `a_bytes' makes when no more input follows.
		local
			l_parser: TUI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.append_bytes (a_bytes)
			if attached l_parser.next_event (False) as al_event then
				Result := al_event
			else
				create Result.make_none
			end
		end

end
