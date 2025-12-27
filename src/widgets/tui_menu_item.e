note
	description: "[
		TUI_MENU_ITEM - Individual menu item

		Item for use in TUI_MENU with text, action, and optional shortcut.

		EV equivalent: EV_MENU_ITEM
		Other frameworks: MenuItem, MenuAction, Command

		Features:
		- Text label with optional & shortcut marker
		- Action callback on select
		- Enable/disable (sensitive) state
		- Separator support
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_MENU_ITEM

create
	make,
	make_with_text,
	make_with_text_and_action,
	make_separator

feature {NONE} -- Initialization

	make
			-- Create empty menu item.
		do
			create text.make_empty
			is_sensitive := True
			is_separator := False
			shortcut_key := '%U'
		ensure
			empty_text: text.is_empty
			sensitive: is_sensitive
			not_separator: not is_separator
		end

	make_with_text (a_text: READABLE_STRING_GENERAL)
			-- Create menu item with text.
			-- Use & before character for keyboard shortcut.
		require
			text_exists: a_text /= Void
		do
			make
			set_text (a_text)
		ensure
			sensitive: is_sensitive
		end

	make_with_text_and_action (a_text: READABLE_STRING_GENERAL; a_action: PROCEDURE)
			-- Create menu item with text and action.
		require
			text_exists: a_text /= Void
			action_exists: a_action /= Void
		do
			make_with_text (a_text)
			on_select := a_action
		ensure
			action_set: on_select = a_action
		end

	make_separator
			-- Create separator item.
		do
			make
			is_separator := True
		ensure
			is_separator: is_separator
		end

feature -- Access

	text: STRING_32
			-- Menu item text (may contain & for shortcut).

	display_text: STRING_32
			-- Text for display (& removed, shortcut underlined conceptually).
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (text.count)
			from i := 1 until i > text.count loop
				c := text.item (i)
				if c = '&' and i < text.count then
					-- Skip the & but include next char
					i := i + 1
					Result.append_character (text.item (i))
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

	shortcut_key: CHARACTER_32
			-- Keyboard shortcut character (from & marker).

	shortcut_position: INTEGER
			-- Position of shortcut character in display_text (0 if none).

	is_sensitive: BOOLEAN
			-- Is item enabled/selectable?
			-- Aliases: is_enabled

	is_enabled: BOOLEAN
			-- Alias for is_sensitive.
		do
			Result := is_sensitive
		end

	is_separator: BOOLEAN
			-- Is this a separator line?

	on_select: detachable PROCEDURE
			-- Called when item is selected.
			-- Aliases: select_actions (simplified to single procedure)

	parent_menu: detachable TUI_MENU
			-- Parent menu containing this item.

feature -- Modification

	set_text (a_text: READABLE_STRING_GENERAL)
			-- Set item text. Use & before character for shortcut.
		require
			text_exists: a_text /= Void
		local
			i: INTEGER
			c: CHARACTER_32
			found_shortcut: BOOLEAN
			display_pos: INTEGER
		do
			text := a_text.to_string_32
			-- Find shortcut key
			shortcut_key := '%U'
			shortcut_position := 0
			display_pos := 0
			from i := 1 until i > text.count or found_shortcut loop
				c := text.item (i)
				if c = '&' and i < text.count then
					shortcut_key := text.item (i + 1).as_lower
					shortcut_position := display_pos + 1
					found_shortcut := True
				else
					display_pos := display_pos + 1
				end
				i := i + 1
			end
		ensure
			text_set: text.same_string_general (a_text)
		end

	set_on_select (a_action: PROCEDURE)
			-- Set selection action.
		do
			on_select := a_action
		ensure
			action_set: on_select = a_action
		end

	enable_sensitive, enable
			-- Enable the item.
		do
			is_sensitive := True
		ensure
			sensitive: is_sensitive
		end

	disable_sensitive, disable
			-- Disable the item.
		do
			is_sensitive := False
		ensure
			not_sensitive: not is_sensitive
		end

feature -- Action

	execute
			-- Execute the item's action if sensitive.
		do
			if is_sensitive and then attached on_select as action then
				action.call (Void)
			end
		end

feature {TUI_MENU} -- Implementation

	set_parent_menu (a_menu: detachable TUI_MENU)
			-- Set parent menu.
		do
			parent_menu := a_menu
		ensure
			parent_set: parent_menu = a_menu
		end

invariant
	text_exists: text /= Void

end
