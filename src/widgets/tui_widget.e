note
	description: "[
		TUI_WIDGET - Base class for all TUI widgets

		All widgets have:
		- Position (x, y) relative to parent
		- Size (width, height)
		- Style (foreground, background, attributes)
		- Focus state
		- Visibility
		- Parent/children relationships
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	TUI_WIDGET

feature {NONE} -- Initialization

	make_widget
			-- Initialize widget with defaults.
		do
			x := 1
			y := 1
			width := 1
			height := 1
			is_visible := True
			is_focusable := False
			is_focused := False
			create style.make_default
			create children.make (0)
		end

feature -- Access

	x: INTEGER
			-- X position (1-based, relative to parent).

	y: INTEGER
			-- Y position (1-based, relative to parent).

	width: INTEGER
			-- Widget width.

	height: INTEGER
			-- Widget height.

	style: TUI_STYLE
			-- Widget style.

	parent: detachable TUI_WIDGET
			-- Parent widget (Void if root).

	children: ARRAYED_LIST [TUI_WIDGET]
			-- Child widgets.

feature -- Status

	is_visible: BOOLEAN
			-- Is widget visible?

	is_focusable: BOOLEAN
			-- Can widget receive focus?

	is_focused: BOOLEAN
			-- Does widget have focus?

feature -- Geometry

	set_position (a_x, a_y: INTEGER)
			-- Set position.
		require
			valid_x: a_x >= 1
			valid_y: a_y >= 1
		do
			x := a_x
			y := a_y
		ensure
			x_set: x = a_x
			y_set: y = a_y
		end

	set_size (a_width, a_height: INTEGER)
			-- Set size.
		require
			valid_width: a_width >= 0
			valid_height: a_height >= 0
		do
			width := a_width
			height := a_height
		ensure
			width_set: width = a_width
			height_set: height = a_height
		end

	set_bounds (a_x, a_y, a_width, a_height: INTEGER)
			-- Set position and size.
		require
			valid_x: a_x >= 1
			valid_y: a_y >= 1
			valid_width: a_width >= 0
			valid_height: a_height >= 0
		do
			x := a_x
			y := a_y
			width := a_width
			height := a_height
		ensure
			x_set: x = a_x
			y_set: y = a_y
			width_set: width = a_width
			height_set: height = a_height
		end

	absolute_x: INTEGER
			-- Absolute X position (relative to screen).
		do
			if attached parent as p then
				Result := p.content_origin_x + x - 1
			else
				Result := x
			end
		end

	absolute_y: INTEGER
			-- Absolute Y position (relative to screen).
		do
			if attached parent as p then
				Result := p.content_origin_y + y - 1
			else
				Result := y
			end
		end

	content_origin_x: INTEGER
			-- X origin for child content (override in containers with borders/padding).
		do
			Result := absolute_x
		end

	content_origin_y: INTEGER
			-- Y origin for child content (override in containers with borders/padding).
		do
			Result := absolute_y
		end

feature -- Styling

	set_style (s: TUI_STYLE)
			-- Set widget style.
		require
			s_exists: s /= Void
		do
			style := s
		ensure
			style_set: style = s
		end

feature -- Visibility

	show
			-- Make widget visible.
		do
			is_visible := True
		ensure
			visible: is_visible
		end

	hide
			-- Make widget invisible.
		do
			is_visible := False
		ensure
			hidden: not is_visible
		end

feature -- Focus

	set_focusable (v: BOOLEAN)
			-- Set whether widget can receive focus.
		do
			is_focusable := v
		ensure
			focusable_set: is_focusable = v
		end

	focus
			-- Give focus to this widget.
		require
			focusable: is_focusable
		do
			is_focused := True
		ensure
			focused: is_focused
		end

	unfocus
			-- Remove focus from this widget.
		do
			is_focused := False
		ensure
			unfocused: not is_focused
		end

feature -- Hierarchy

	extend, add_child (child: TUI_WIDGET)
			-- Add child widget.
			-- `extend` matches EiffelVision2 container API.
		require
			child_exists: child /= Void
			not_self: child /= Current
			no_parent: child.parent = Void
		do
			children.extend (child)
			child.set_parent (Current)
		ensure
			child_added: children.has (child)
			parent_set: child.parent = Current
		end

	prune, remove_child (child: TUI_WIDGET)
			-- Remove child widget.
			-- `prune` matches EiffelVision2 container API.
		require
			child_exists: child /= Void
			is_child: children.has (child)
		do
			children.prune_all (child)
			child.set_parent (Void)
		ensure
			child_removed: not children.has (child)
			parent_cleared: child.parent = Void
		end

	set_parent (p: detachable TUI_WIDGET)
			-- Set parent widget.
		do
			parent := p
		ensure
			parent_set: parent = p
		end

feature -- Rendering

	render (buffer: TUI_BUFFER)
			-- Render this widget to the buffer.
		require
			buffer_exists: buffer /= Void
		deferred
		end

	render_children (buffer: TUI_BUFFER)
			-- Render all visible children.
		require
			buffer_exists: buffer /= Void
		local
			i: INTEGER
		do
			from i := 1 until i > children.count loop
				if children.i_th (i).is_visible then
					children.i_th (i).render (buffer)
				end
				i := i + 1
			end
		end

feature -- Event handling

	handle_event (event: TUI_EVENT): BOOLEAN
			-- Handle input event. Return True if handled.
		require
			event_exists: event /= Void
		do
			Result := False
		end

	handle_key (event: TUI_EVENT): BOOLEAN
			-- Handle key event. Return True if handled.
		require
			event_exists: event /= Void
			is_key: event.is_key_event or event.is_char_event
		do
			Result := False
		end

	handle_mouse (event: TUI_EVENT): BOOLEAN
			-- Handle mouse event. Return True if handled.
		require
			event_exists: event /= Void
			is_mouse: event.is_mouse_event
		do
			Result := False
		end

feature -- Queries

	contains_point (px, py: INTEGER): BOOLEAN
			-- Does this widget contain the point (absolute coords)?
		local
			ax, ay: INTEGER
		do
			ax := absolute_x
			ay := absolute_y
			Result := px >= ax and px < ax + width and py >= ay and py < ay + height
		end

	find_widget_at (px, py: INTEGER): detachable TUI_WIDGET
			-- Find deepest widget containing point (absolute coords).
		local
			found: detachable TUI_WIDGET
		do
			if contains_point (px, py) and is_visible then
				Result := Current
				-- Check children (last child is on top)
				from children.finish until children.before loop
					found := children.item.find_widget_at (px, py)
					if found /= Void then
						Result := found
						children.start -- Exit loop
					end
					children.back
				end
			end
		end

feature -- Layout

	preferred_width: INTEGER
			-- Preferred width for layout.
		do
			Result := width
		end

	preferred_height: INTEGER
			-- Preferred height for layout.
		do
			Result := height
		end

	layout
			-- Perform layout of children (override in container widgets).
		do
			-- Default: no-op
		end

invariant
	style_exists: style /= Void
	children_exist: children /= Void
	valid_dimensions: width >= 0 and height >= 0

end
