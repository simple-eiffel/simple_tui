note
	description: "[
		TUI_EVENT - Terminal input event

		Represents keyboard, mouse, and system events:
		- Key press/release with modifiers
		- Mouse click/move/scroll
		- Terminal resize
		- Focus gain/loss
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_EVENT

create
	make_key,
	make_char,
	make_mouse,
	make_mouse_press,
	make_mouse_release,
	make_resize,
	make_focus,
	make_none

feature {NONE} -- Initialization

	make_key (a_key: INTEGER; a_modifiers: INTEGER)
			-- Create key event for special keys.
		do
			event_type := Type_key
			key_code := a_key
			modifiers := a_modifiers
			character := '%U'
			mouse_x := 0
			mouse_y := 0
			mouse_button := 0
			resize_width := 0
			resize_height := 0
		ensure
			is_key: is_key_event
		end

	make_char (c: CHARACTER_32; a_modifiers: INTEGER)
			-- Create character input event.
		do
			event_type := Type_char
			character := c
			modifiers := a_modifiers
			key_code := 0
			mouse_x := 0
			mouse_y := 0
			mouse_button := 0
			resize_width := 0
			resize_height := 0
		ensure
			is_char: is_char_event
		end

	make_mouse (x, y, button: INTEGER; a_type: INTEGER; a_modifiers: INTEGER)
			-- Create mouse event.
		require
			valid_type: a_type >= Type_mouse_press and a_type <= Type_mouse_scroll
		do
			event_type := a_type
			mouse_x := x
			mouse_y := y
			mouse_button := button
			modifiers := a_modifiers
			key_code := 0
			character := '%U'
			resize_width := 0
			resize_height := 0
		ensure
			is_mouse: is_mouse_event
		end

	make_mouse_press (x, y, button: INTEGER)
			-- Create mouse press event.
		do
			make_mouse (x, y, button, Type_mouse_press, 0)
		ensure
			is_press: is_mouse_press
		end

	make_mouse_release (x, y, button: INTEGER)
			-- Create mouse release event.
		do
			make_mouse (x, y, button, Type_mouse_release, 0)
		ensure
			is_release: is_mouse_release
		end

	make_resize (w, h: INTEGER)
			-- Create resize event.
		require
			valid_size: w > 0 and h > 0
		do
			event_type := Type_resize
			resize_width := w
			resize_height := h
			key_code := 0
			character := '%U'
			modifiers := 0
			mouse_x := 0
			mouse_y := 0
			mouse_button := 0
		ensure
			is_resize: is_resize_event
		end

	make_focus (gained: BOOLEAN)
			-- Create focus event.
		do
			if gained then
				event_type := Type_focus_gained
			else
				event_type := Type_focus_lost
			end
			key_code := 0
			character := '%U'
			modifiers := 0
			mouse_x := 0
			mouse_y := 0
			mouse_button := 0
			resize_width := 0
			resize_height := 0
		ensure
			is_focus: is_focus_event
		end

	make_none
			-- Create empty/no event.
		do
			event_type := Type_none
			key_code := 0
			character := '%U'
			modifiers := 0
			mouse_x := 0
			mouse_y := 0
			mouse_button := 0
			resize_width := 0
			resize_height := 0
		end

feature -- Access

	event_type: INTEGER
			-- Type of event.

	key_code: INTEGER
			-- Special key code.

	key: INTEGER
			-- Alias for key_code.
		do
			Result := key_code
		end

	character: CHARACTER_32
			-- Character for char events.

	char: CHARACTER_32
			-- Alias for character.
		do
			Result := character
		end

	modifiers: INTEGER
			-- Modifier keys (Ctrl, Alt, Shift).

	mouse_x: INTEGER
			-- Mouse X position (1-based).

	mouse_y: INTEGER
			-- Mouse Y position (1-based).

	mouse_button: INTEGER
			-- Mouse button (1=left, 2=middle, 3=right).

	mouse_scroll_delta: INTEGER
			-- Scroll delta for scroll events (+/- for direction).

	resize_width: INTEGER
			-- New width for resize events.

	resize_height: INTEGER
			-- New height for resize events.

feature -- Event type queries

	is_key_event: BOOLEAN
			-- Is this a special key event?
		do
			Result := event_type = Type_key
		end

	is_char_event: BOOLEAN
			-- Is this a character input event?
		do
			Result := event_type = Type_char
		end

	is_mouse_event: BOOLEAN
			-- Is this any mouse event?
		do
			Result := event_type >= Type_mouse_press and event_type <= Type_mouse_scroll
		end

	is_mouse_press: BOOLEAN
			-- Is this a mouse press event?
		do
			Result := event_type = Type_mouse_press
		end

	is_mouse_release: BOOLEAN
			-- Is this a mouse release event?
		do
			Result := event_type = Type_mouse_release
		end

	is_mouse_move: BOOLEAN
			-- Is this a mouse move event?
		do
			Result := event_type = Type_mouse_move
		end

	is_mouse_scroll: BOOLEAN
			-- Is this a mouse scroll event?
		do
			Result := event_type = Type_mouse_scroll
		end

	is_resize_event: BOOLEAN
			-- Is this a resize event?
		do
			Result := event_type = Type_resize
		end

	is_focus_event: BOOLEAN
			-- Is this a focus event?
		do
			Result := event_type = Type_focus_gained or event_type = Type_focus_lost
		end

	is_focus_gained: BOOLEAN
			-- Did terminal gain focus?
		do
			Result := event_type = Type_focus_gained
		end

	is_focus_lost: BOOLEAN
			-- Did terminal lose focus?
		do
			Result := event_type = Type_focus_lost
		end

	is_none: BOOLEAN
			-- Is this an empty event?
		do
			Result := event_type = Type_none
		end

feature -- Modifier queries

	has_ctrl: BOOLEAN
			-- Is Ctrl pressed?
		do
			Result := (modifiers & Mod_ctrl) /= 0
		end

	has_alt: BOOLEAN
			-- Is Alt pressed?
		do
			Result := (modifiers & Mod_alt) /= 0
		end

	has_shift: BOOLEAN
			-- Is Shift pressed?
		do
			Result := (modifiers & Mod_shift) /= 0
		end

feature -- Key queries

	is_key (k: INTEGER): BOOLEAN
			-- Is this a key event for key `k`?
		do
			Result := is_key_event and key_code = k
		end

	is_enter: BOOLEAN do Result := is_key (Key_enter) or (is_char_event and (character = '%N' or character = '%/13/')) end
	is_escape: BOOLEAN do Result := is_key (Key_escape) end
	is_tab: BOOLEAN do Result := is_key (Key_tab) or (is_char_event and character = '%T') end
	is_backspace: BOOLEAN do Result := is_key (Key_backspace) or (is_char_event and character = '%/8/') end
	is_delete: BOOLEAN do Result := is_key (Key_delete) end
	is_space: BOOLEAN do Result := is_char_event and character = ' ' end
	is_up: BOOLEAN do Result := is_key (Key_up) end
	is_down: BOOLEAN do Result := is_key (Key_down) end
	is_left: BOOLEAN do Result := is_key (Key_left) end
	is_right: BOOLEAN do Result := is_key (Key_right) end
	is_home: BOOLEAN do Result := is_key (Key_home) end
	is_end_key: BOOLEAN do Result := is_key (Key_end) end
	is_page_up: BOOLEAN do Result := is_key (Key_page_up) end
	is_page_down: BOOLEAN do Result := is_key (Key_page_down) end
	is_insert: BOOLEAN do Result := is_key (Key_insert) end

feature -- Event type constants

	Type_none: INTEGER = 0
	Type_key: INTEGER = 1
	Type_char: INTEGER = 2
	Type_mouse_press: INTEGER = 3
	Type_mouse_release: INTEGER = 4
	Type_mouse_move: INTEGER = 5
	Type_mouse_scroll: INTEGER = 6
	Type_resize: INTEGER = 7
	Type_focus_gained: INTEGER = 8
	Type_focus_lost: INTEGER = 9

feature -- Modifier constants

	Mod_none: INTEGER = 0
	Mod_ctrl: INTEGER = 1
	Mod_alt: INTEGER = 2
	Mod_shift: INTEGER = 4

feature -- Key constants

	Key_enter: INTEGER = 13
	Key_escape: INTEGER = 27
	Key_tab: INTEGER = 9
	Key_backspace: INTEGER = 8
	Key_delete: INTEGER = 127
	Key_up: INTEGER = 256
	Key_down: INTEGER = 257
	Key_left: INTEGER = 258
	Key_right: INTEGER = 259
	Key_home: INTEGER = 260
	Key_end: INTEGER = 261
	Key_page_up: INTEGER = 262
	Key_page_down: INTEGER = 263
	Key_insert: INTEGER = 264
	Key_space: INTEGER = 32
	Key_f1: INTEGER = 265
	Key_f2: INTEGER = 266
	Key_f3: INTEGER = 267
	Key_f4: INTEGER = 268
	Key_f5: INTEGER = 269
	Key_f6: INTEGER = 270
	Key_f7: INTEGER = 271
	Key_f8: INTEGER = 272
	Key_f9: INTEGER = 273
	Key_f10: INTEGER = 274
	Key_f11: INTEGER = 275
	Key_f12: INTEGER = 276

feature -- Mouse button constants

	Button_left: INTEGER = 1
	Button_middle: INTEGER = 2
	Button_right: INTEGER = 3
	Button_scroll_up: INTEGER = 4
	Button_scroll_down: INTEGER = 5

end
