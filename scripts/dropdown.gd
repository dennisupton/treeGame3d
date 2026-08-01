class_name Dropdown
extends OptionButton

## OptionButton that keeps its list inside the viewport.
##
## The built-in list is a PopupMenu, and a PopupMenu is a Window: the rounded
## corners only look right with per-pixel transparency turned on, and because it
## lives outside the main viewport the fullscreen pixelate ColorRect never
## touches it. This swallows the click that would open that popup and builds the
## list out of ordinary Controls instead, so it pixelates and squiggles along
## with everything else.
##
## Everything else is still stock OptionButton -- the items, selected,
## item_selected, the arrow, every theme lookup -- and the list is styled from
## the theme's PopupMenu entries, so theme.tres stays in charge of the look.
## Item icons and disabled items work; separators are skipped rather than drawn.
##
## A list too tall for the screen scrolls instead of running off the edge.

## Wheel and thumb buttons shouldn't count as "clicked somewhere else".
const DISMISS_BUTTONS := [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
## Gap the list keeps from the top and bottom of the screen.
const EDGE_MARGIN := 16.0

## The list draws above the rest of the UI but below the pixelate ColorRect
## (z 4 in mainMenu), so the screen shader still catches it.
@export var list_z_index := 3

## Caps how tall the list is allowed to get, in pixels. 0 lets it grow until it
## runs out of screen. Either way, what doesn't fit scrolls.
@export var max_list_height := 0.0

## How wide the scrollbar is when there is one.
@export var scrollbar_width := 28.0

## Optional hover blip, the one the menu buttons use.
@export var hover_sound: AudioStream

var _overlay: Control       # fullscreen catcher: a click anywhere off the list closes it
var _list: PanelContainer
var _audio: AudioStreamPlayer


func _ready() -> void:
	set_process_unhandled_input(false)
	toggled.connect(_on_toggled)
	mouse_entered.connect(_play_blip)
	if hover_sound != null:
		_audio = AudioStreamPlayer.new()
		_audio.stream = hover_sound
		add_child(_audio)


## Runs before OptionButton's own handler, so accepting the event here is what
## keeps the built-in PopupMenu from ever opening. Everything else -- hover,
## focus, the pressed stylebox -- carries on as normal.
func _gui_input(event: InputEvent) -> void:
	var opening := false
	if event is InputEventMouseButton:
		if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
			return
		opening = event.is_pressed()
	elif event.is_action(&"ui_accept") and not event.is_echo():
		opening = event.is_pressed()
	else:
		return
	accept_event()
	if opening:
		button_pressed = not button_pressed


func _unhandled_input(event: InputEvent) -> void:
	if _overlay != null and event.is_action_pressed(&"ui_cancel"):
		button_pressed = false
		get_viewport().set_input_as_handled()


## Closing the settings panel with the list still down would otherwise leave it
## hanging there waiting for the next time the panel opens.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and _overlay != null and not is_visible_in_tree():
		button_pressed = false


func _on_toggled(down: bool) -> void:
	if down:
		_open()
	else:
		_close()


func _open() -> void:
	if _overlay != null:
		return
	if item_count == 0:
		set_pressed_no_signal(false)
		return

	_overlay = Control.new()
	_overlay.name = "DropdownList"
	_overlay.top_level = true       # ignore the container this button sits in
	_overlay.z_as_relative = false
	_overlay.z_index = list_z_index
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.material = material    # share the squiggle, if this button has one
	_overlay.gui_input.connect(_on_overlay_gui_input.bind(_overlay))
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var hover_style := get_theme_stylebox(&"hover", &"PopupMenu")
	var idle_style := StyleBoxEmpty.new()
	# Same padding as the hover box, so a row doesn't shift when it lights up.
	idle_style.content_margin_left = hover_style.get_margin(SIDE_LEFT)
	idle_style.content_margin_top = hover_style.get_margin(SIDE_TOP)
	idle_style.content_margin_right = hover_style.get_margin(SIDE_RIGHT)
	idle_style.content_margin_bottom = hover_style.get_margin(SIDE_BOTTOM)

	var panel_style := get_theme_stylebox(&"panel", &"PopupMenu")
	_list = PanelContainer.new()
	_list.add_theme_stylebox_override(&"panel", panel_style)
	_list.mouse_filter = Control.MOUSE_FILTER_STOP  # clicks on the padding shouldn't close it
	_list.use_parent_material = true
	_list.custom_minimum_size.x = size.x            # line up with the button above it
	_overlay.add_child(_list)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO  # bar shows only when needed
	scroll.follow_focus = true                      # arrow keys drag the view along
	scroll.use_parent_material = true
	_list.add_child(scroll)
	var bar := scroll.get_v_scroll_bar()
	bar.use_parent_material = true
	if not _project_styles_scrollbars():
		_style_scrollbar(bar, hover_style)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override(&"separation", get_theme_constant(&"v_separation", &"PopupMenu"))
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # rows span the panel, not just their text
	rows.use_parent_material = true
	scroll.add_child(rows)

	var popup := get_popup()
	var focus_row: Button = null
	for i in item_count:
		if popup.is_item_separator(i):
			continue
		var row := _make_row(i, idle_style, hover_style)
		rows.add_child(row)
		if i == maxi(selected, 0):
			focus_row = row

	_fit_list(scroll, rows, panel_style.get_margin(SIDE_TOP) + panel_style.get_margin(SIDE_BOTTOM))
	_pop_in()
	set_process_unhandled_input(true)
	if focus_row != null and not focus_row.disabled and focus_mode != Control.FOCUS_NONE:
		focus_row.grab_focus()
		# The rows have no rects yet, so let the containers lay out before asking
		# the list to scroll down to the selected one.
		scroll.ensure_control_visible.call_deferred(focus_row)


func _close() -> void:
	set_process_unhandled_input(false)
	set_pressed_no_signal(false)
	if _overlay == null:
		return
	# Hand focus back to the button, but only if the list is what is holding it.
	var focused: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var refocus := focused != null and _overlay.is_ancestor_of(focused)
	# queue_free() only lands at the end of the frame, and until then the overlay
	# would keep swallowing clicks. Hide it so it is out of the way immediately.
	_overlay.hide()
	_overlay.queue_free()
	_overlay = null
	if refocus and is_visible_in_tree() and focus_mode != Control.FOCUS_NONE:
		grab_focus()


func _make_row(index: int, idle_style: StyleBox, hover_style: StyleBox) -> Button:
	var row := Button.new()
	row.text = get_item_text(index)
	row.icon = get_item_icon(index)
	row.disabled = is_item_disabled(index)
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.use_parent_material = true
	row.add_theme_font_override(&"font", get_theme_font(&"font", &"PopupMenu"))
	row.add_theme_font_size_override(&"font_size", get_theme_font_size(&"font_size", &"PopupMenu"))
	# A row with an icon would otherwise sit its text Button/h_separation away
	# from it -- 318px in this theme, which is meant for the menu buttons. Use
	# the menu's own icon spacing instead.
	row.add_theme_constant_override(&"h_separation", get_theme_constant(&"h_separation", &"PopupMenu"))
	row.add_theme_color_override(&"font_color", get_theme_color(&"font_color", &"PopupMenu"))
	row.add_theme_color_override(&"font_focus_color", get_theme_color(&"font_color", &"PopupMenu"))
	row.add_theme_color_override(&"font_hover_color", get_theme_color(&"font_hover_color", &"PopupMenu"))
	row.add_theme_color_override(&"font_pressed_color", get_theme_color(&"font_hover_color", &"PopupMenu"))
	row.add_theme_color_override(&"font_disabled_color", get_theme_color(&"font_disabled_color", &"PopupMenu"))
	row.add_theme_stylebox_override(&"normal", idle_style)
	row.add_theme_stylebox_override(&"hover", hover_style)
	row.add_theme_stylebox_override(&"pressed", hover_style)
	row.add_theme_stylebox_override(&"focus", hover_style)  # keyboard and gamepad highlight
	row.pressed.connect(_pick.bind(index))
	row.mouse_entered.connect(_play_blip)
	return row


## Hangs the list off whichever side of the button has room for it: below by
## preference, flipped above when that fits better. When neither side is tall
## enough the list takes the roomier one, stops at the screen edge, and lets the
## ScrollContainer handle the rest.
func _fit_list(scroll: ScrollContainer, rows: Control, chrome: float) -> void:
	var button_rect := get_global_rect()
	var view := get_viewport_rect().size
	var natural := rows.get_combined_minimum_size().y + chrome
	var wanted := natural
	if max_list_height > 0.0:
		wanted = minf(wanted, max_list_height)

	var below := view.y - button_rect.end.y - EDGE_MARGIN
	var above := button_rect.position.y - EDGE_MARGIN
	var height := wanted
	var top := button_rect.end.y
	if wanted > below:
		if wanted <= above:
			top = button_rect.position.y - wanted    # flip above the button
		elif above > below:
			height = above                           # scrolls, hung off the top edge
			top = EDGE_MARGIN
		else:
			height = below                           # scrolls, hung off the button

	# A ScrollContainer set to scroll reserves room for the bar whether or not one
	# ever shows, which would leave the list sitting wider than the button it
	# hangs off. Only switch scrolling on once the rows genuinely overflow.
	scroll.vertical_scroll_mode = (ScrollContainer.SCROLL_MODE_AUTO if natural > height
			else ScrollContainer.SCROLL_MODE_DISABLED)
	scroll.custom_minimum_size.y = maxf(height - chrome, 0.0)
	_list.reset_size()
	_list.position = Vector2(button_rect.position.x, top).clamp(
		Vector2.ZERO, (view - _list.size).max(Vector2.ZERO))


## Theme lookups quietly fall back to Godot's built-in theme, so
## has_theme_stylebox() can't answer "did this project style it?". Walk the
## theme chain by hand: if the project dresses its scrollbars, leave them alone.
func _project_styles_scrollbars() -> bool:
	var node: Node = self
	while node != null:
		var owned: Theme = null
		if node is Control:
			owned = (node as Control).theme
		elif node is Window:
			owned = (node as Window).theme
		if owned != null and owned.has_stylebox(&"grabber", &"VScrollBar"):
			return true
		node = node.get_parent()
	var project := ThemeDB.get_project_theme()
	return project != null and project.has_stylebox(&"grabber", &"VScrollBar")


## No scrollbar in the theme, so mix one from the palette the list already uses:
## the accent colour for the grabber, the hover box for the trough, and the
## theme's own corner_detail so it stays as chunky as everything around it.
func _style_scrollbar(bar: VScrollBar, hover_style: StyleBox) -> void:
	var detail := 2
	var trough_color := Color(0.0, 0.0, 0.0, 0.15)
	var flat := hover_style as StyleBoxFlat
	if flat != null:
		detail = flat.corner_detail
		trough_color = flat.bg_color

	var trough := _bar_style(trough_color, detail)
	trough.content_margin_left = scrollbar_width * 0.5   # this is what sets the width
	trough.content_margin_right = scrollbar_width * 0.5

	var grabber := _bar_style(get_theme_color(&"font_color", &"OptionButton"), detail)
	grabber.content_margin_top = scrollbar_width         # keeps it a pill, never a dot
	grabber.content_margin_bottom = scrollbar_width

	var grabbed := grabber.duplicate() as StyleBoxFlat
	grabbed.bg_color = grabber.bg_color.lightened(0.2)

	bar.add_theme_stylebox_override(&"scroll", trough)
	bar.add_theme_stylebox_override(&"scroll_focus", trough)
	bar.add_theme_stylebox_override(&"grabber", grabber)
	bar.add_theme_stylebox_override(&"grabber_highlight", grabbed)
	bar.add_theme_stylebox_override(&"grabber_pressed", grabbed)


func _bar_style(color: Color, detail: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(scrollbar_width * 0.5))
	style.corner_detail = detail
	return style


func _pop_in() -> void:
	_list.pivot_offset = Vector2(_list.size.x * 0.5, 0.0)
	_list.scale = Vector2(1.0, 0.7)
	_list.modulate.a = 0.0
	var tween := _list.create_tween().set_parallel(true)
	tween.tween_property(_list, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_list, "modulate:a", 1.0, 0.1)


func _pick(index: int) -> void:
	button_pressed = false      # closes the list through _on_toggled
	if index == selected and not allow_reselect:
		return
	select(index)
	item_selected.emit(index)


func _on_overlay_gui_input(event: InputEvent, overlay: Control) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or not (click.button_index in DISMISS_BUTTONS):
		return
	overlay.accept_event()
	button_pressed = false


func _play_blip() -> void:
	if _audio == null:
		return
	_audio.pitch_scale = randf_range(0.8, 1.2)
	_audio.play()
