note
	description: "[
		TUI_INPUT_PARSER - Terminal input bytes into TUI_EVENTs

		Keys, UTF-8 text and SGR mouse reports, as a terminal sends them on
		macOS and Linux. Pure Eiffel, so it is tested on every platform.

		An escape sequence can arrive in pieces, and a lone ESC looks like the
		start of one. `next_event' therefore takes whether more bytes may
		still follow: with True an unfinished sequence answers Void and stays
		pending; with False it is settled as it stands.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_INPUT_PARSER

create
	make

feature {NONE} -- Initialization

	make
			-- Create with nothing pending.
		do
			create pending.make (64)
		ensure
			nothing_pending: not has_pending
		end

feature -- Status report

	has_pending: BOOLEAN
			-- Are bytes waiting?
		do
			Result := not pending.is_empty
		end

feature -- Element change

	append_bytes (a_bytes: READABLE_STRING_8)
			-- Add bytes read from the terminal.
		do
			pending.append (a_bytes)
		ensure
			added: pending.count = old pending.count + a_bytes.count
		end

feature -- Access

	next_event (a_more_may_follow: BOOLEAN): detachable TUI_EVENT
			-- The first event in the pending bytes, removing them; Void when
			-- nothing is pending, or only the start of a sequence and
			-- `a_more_may_follow'.
		local
			l_first: INTEGER
		do
			if has_pending then
				l_first := pending.item (1).code
				if l_first = 27 then
					Result := escape_event (a_more_may_follow)
				elseif l_first >= 0x80 then
					Result := utf_8_event (a_more_may_follow)
				else
					consume (1)
					Result := plain_event (l_first)
				end
			end
		ensure
			settled: not a_more_may_follow and (old has_pending) implies Result /= Void
		end

feature {NONE} -- Implementation

	pending: STRING_8
			-- Bytes not yet turned into events.

	consume (a_count: INTEGER)
			-- Remove the first `a_count' pending bytes.
		require
			enough: a_count <= pending.count
		do
			pending.remove_head (a_count)
		end

	plain_event (a_code: INTEGER): TUI_EVENT
			-- The event for ASCII byte `a_code'. Enter, Tab and Backspace are
			-- characters with no modifier, as the Windows console reports them.
		do
			inspect a_code
			when 8, 9, 13 then
				create Result.make_char (a_code.to_character_32, 0)
			when 127 then
				create Result.make_char ((8).to_character_32, 0)
			when 0 then
				create Result.make_char (' ', {TUI_EVENT}.Mod_ctrl)
			when 1 .. 7, 10 .. 12, 14 .. 26 then
				create Result.make_char (a_code.to_character_32, {TUI_EVENT}.Mod_ctrl)
			when 28 .. 31 then
				create Result.make_none
			else
				create Result.make_char (a_code.to_character_32, 0)
			end
		end

	escape_event (a_more_may_follow: BOOLEAN): detachable TUI_EVENT
			-- The event for pending bytes starting with ESC.
		local
			l_second: CHARACTER_8
		do
			if pending.count = 1 then
				if not a_more_may_follow then
					consume (1)
					create Result.make_key ({TUI_EVENT}.Key_escape, 0)
				end
			else
				l_second := pending.item (2)
				if l_second = '[' then
					Result := csi_event (a_more_may_follow)
				elseif l_second = 'O' then
					Result := ss3_event (a_more_may_follow)
				elseif l_second.code >= 0x20 and l_second.code < 0x7F then
					-- Alt with a key.
					consume (2)
					create Result.make_char (l_second.code.to_character_32, {TUI_EVENT}.Mod_alt)
				else
					consume (1)
					create Result.make_key ({TUI_EVENT}.Key_escape, 0)
				end
			end
		end

	ss3_event (a_more_may_follow: BOOLEAN): detachable TUI_EVENT
			-- The event for ESC O x.
		local
			l_key: INTEGER
		do
			if pending.count = 2 then
				if not a_more_may_follow then
					consume (2)
					create Result.make_char ('O', {TUI_EVENT}.Mod_alt)
				end
			else
				inspect pending.item (3)
				when 'P' then l_key := {TUI_EVENT}.Key_f1
				when 'Q' then l_key := {TUI_EVENT}.Key_f2
				when 'R' then l_key := {TUI_EVENT}.Key_f3
				when 'S' then l_key := {TUI_EVENT}.Key_f4
				else
					l_key := cursor_key (pending.item (3))
				end
				consume (3)
				if l_key /= 0 then
					create Result.make_key (l_key, 0)
				else
					create Result.make_none
				end
			end
		end

	csi_event (a_more_may_follow: BOOLEAN): detachable TUI_EVENT
			-- The event for ESC [ parameters final.
		local
			i, l_key: INTEGER
			l_parameters: STRING_8
			l_final: CHARACTER_8
			l_numbers: LIST [STRING_8]
		do
			from
				i := 3
			until
				i > pending.count or else not (pending.item (i).code >= 0x20 and pending.item (i).code <= 0x3F)
			loop
				i := i + 1
			end
			if i > pending.count then
				if not a_more_may_follow then
					consume (pending.count)
					create Result.make_none
				end
			else
				l_parameters := pending.substring (3, i - 1)
				l_final := pending.item (i)
				consume (i)
				if not l_parameters.is_empty and then l_parameters.item (1) = '<' then
					Result := mouse_event (l_parameters, l_final)
				else
					l_numbers := l_parameters.split (';')
					if l_final = '~' then
						l_key := tilde_key (number_at (l_numbers, 1))
					elseif l_final = 'Z' then
						l_key := {TUI_EVENT}.Key_tab
					else
						l_key := cursor_key (l_final)
					end
					if l_key = 0 then
						create Result.make_none
					elseif l_final = 'Z' then
						create Result.make_key (l_key, {TUI_EVENT}.Mod_shift)
					else
						create Result.make_key (l_key, modifiers (number_at (l_numbers, 2)))
					end
				end
			end
		end

	mouse_event (a_parameters: STRING_8; a_final: CHARACTER_8): TUI_EVENT
			-- The event for an SGR mouse report: "<button;x;y" then M or m.
		local
			l_numbers: LIST [STRING_8]
			l_code, l_button, l_type, l_modifiers: INTEGER
		do
			l_numbers := a_parameters.substring (2, a_parameters.count).split (';')
			l_code := number_at (l_numbers, 1)
			if l_numbers.count /= 3 or (l_code & 64) /= 0 then
				-- Malformed, or the wheel, which the Windows backend ignores too.
				create Result.make_none
			else
				inspect l_code & 3
				when 0 then l_button := 1
				when 1 then l_button := 3
				when 2 then l_button := 2
				else
					l_button := 0
				end
				if (l_code & 32) /= 0 then
					l_type := {TUI_EVENT}.Type_mouse_move
				elseif a_final = 'm' then
					l_type := {TUI_EVENT}.Type_mouse_release
				else
					l_type := {TUI_EVENT}.Type_mouse_press
				end
				if (l_code & 4) /= 0 then
					l_modifiers := l_modifiers | {TUI_EVENT}.Mod_shift
				end
				if (l_code & 8) /= 0 then
					l_modifiers := l_modifiers | {TUI_EVENT}.Mod_alt
				end
				if (l_code & 16) /= 0 then
					l_modifiers := l_modifiers | {TUI_EVENT}.Mod_ctrl
				end
				create Result.make_mouse (number_at (l_numbers, 2), number_at (l_numbers, 3), l_button, l_type, l_modifiers)
			end
		end

	utf_8_event (a_more_may_follow: BOOLEAN): detachable TUI_EVENT
			-- The event for a UTF-8 sequence. A malformed byte is dropped.
		local
			l_first, l_length, l_code, i, l_next: INTEGER
			l_valid: BOOLEAN
		do
			l_first := pending.item (1).code
			if l_first >= 0xF0 and l_first <= 0xF4 then
				l_length := 4
				l_code := l_first & 0x07
			elseif l_first >= 0xE0 and l_first < 0xF0 then
				l_length := 3
				l_code := l_first & 0x0F
			elseif l_first >= 0xC2 and l_first < 0xE0 then
				l_length := 2
				l_code := l_first & 0x1F
			end
			if l_length = 0 then
				consume (1)
				create Result.make_none
			elseif pending.count < l_length then
				if not a_more_may_follow then
					consume (1)
					create Result.make_none
				end
			else
				l_valid := True
				from
					i := 2
				until
					i > l_length or not l_valid
				loop
					l_next := pending.item (i).code
					l_valid := (l_next & 0xC0) = 0x80
					l_code := (l_code |<< 6) | (l_next & 0x3F)
					i := i + 1
				end
				if l_valid then
					consume (l_length)
					create Result.make_char (l_code.to_character_32, 0)
				else
					consume (1)
					create Result.make_none
				end
			end
		end

	cursor_key (a_final: CHARACTER_8): INTEGER
			-- The key a cursor sequence ends in; 0 if none.
		do
			inspect a_final
			when 'A' then Result := {TUI_EVENT}.Key_up
			when 'B' then Result := {TUI_EVENT}.Key_down
			when 'C' then Result := {TUI_EVENT}.Key_right
			when 'D' then Result := {TUI_EVENT}.Key_left
			when 'H' then Result := {TUI_EVENT}.Key_home
			when 'F' then Result := {TUI_EVENT}.Key_end
			else
				Result := 0
			end
		end

	tilde_key (a_number: INTEGER): INTEGER
			-- The key for ESC [ `a_number' ~; 0 if none.
		do
			inspect a_number
			when 1, 7 then Result := {TUI_EVENT}.Key_home
			when 2 then Result := {TUI_EVENT}.Key_insert
			when 3 then Result := {TUI_EVENT}.Key_delete
			when 4, 8 then Result := {TUI_EVENT}.Key_end
			when 5 then Result := {TUI_EVENT}.Key_page_up
			when 6 then Result := {TUI_EVENT}.Key_page_down
			when 11 then Result := {TUI_EVENT}.Key_f1
			when 12 then Result := {TUI_EVENT}.Key_f2
			when 13 then Result := {TUI_EVENT}.Key_f3
			when 14 then Result := {TUI_EVENT}.Key_f4
			when 15 then Result := {TUI_EVENT}.Key_f5
			when 17 then Result := {TUI_EVENT}.Key_f6
			when 18 then Result := {TUI_EVENT}.Key_f7
			when 19 then Result := {TUI_EVENT}.Key_f8
			when 20 then Result := {TUI_EVENT}.Key_f9
			when 21 then Result := {TUI_EVENT}.Key_f10
			when 23 then Result := {TUI_EVENT}.Key_f11
			when 24 then Result := {TUI_EVENT}.Key_f12
			else
				Result := 0
			end
		end

	modifiers (a_parameter: INTEGER): INTEGER
			-- Modifiers from xterm's parameter: 1 + shift 1, alt 2, ctrl 4.
		local
			l_bits: INTEGER
		do
			if a_parameter > 1 then
				l_bits := a_parameter - 1
				if (l_bits & 1) /= 0 then
					Result := Result | {TUI_EVENT}.Mod_shift
				end
				if (l_bits & 2) /= 0 then
					Result := Result | {TUI_EVENT}.Mod_alt
				end
				if (l_bits & 4) /= 0 then
					Result := Result | {TUI_EVENT}.Mod_ctrl
				end
			end
		end

	number_at (a_numbers: LIST [STRING_8]; a_index: INTEGER): INTEGER
			-- Number `a_index' of `a_numbers'; 0 if absent or not a number.
		do
			if a_index <= a_numbers.count and then a_numbers.i_th (a_index).is_integer then
				Result := a_numbers.i_th (a_index).to_integer
			end
		end

end
