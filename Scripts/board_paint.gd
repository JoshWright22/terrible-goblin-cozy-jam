class_name BoardPaint

# Makes text on the wooden boards look hand painted: cream paint, soft brown edge,
# a little tilt, dry brush grain, and a left-to-right "painting on" reveal.

const PAINT := Color(1.0, 0.97, 0.9)
const ACCENT_PAINT := Color(1.0, 0.84, 0.45)
const EDGE := Color(0.24, 0.13, 0.05, 0.75)
const SHADOW := Color(0.18, 0.1, 0.04, 0.35)

static var _material: ShaderMaterial = null

static func apply(root: Node, reveal: bool = true, delay: float = 0.15) -> void:
	var i := 0
	for lbl in _text_nodes(root):
		style(lbl)
		if reveal and lbl.is_visible_in_tree():
			paint_on(lbl, delay + i * 0.18)
			i += 1

static func style(lbl: Control, accent: bool = false) -> void:
	var color_key := "default_color" if lbl is RichTextLabel else "font_color"
	# Keep any colour the scene set on purpose (e.g. gold headings), otherwise cream paint
	if not lbl.has_theme_color_override(color_key) or lbl.get_theme_color(color_key) == Color.WHITE:
		lbl.add_theme_color_override(color_key, ACCENT_PAINT if accent else PAINT)
	lbl.add_theme_color_override("font_outline_color", EDGE)
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.add_theme_color_override("font_shadow_color", SHADOW)
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	lbl.material = _paint_material()
	# Hand-placed, not perfectly level
	if lbl.rotation == 0.0:
		lbl.pivot_offset = lbl.size / 2.0
		lbl.rotation_degrees = randf_range(-1.2, 1.2)

static func paint_on(lbl: Control, delay: float = 0.0) -> void:
	if not "visible_ratio" in lbl:
		return
	lbl.visible_ratio = 0.0
	var chars: int = maxi(1, lbl.get_total_character_count())
	var time := clampf(chars * 0.03, 0.25, 1.2)
	var tw := lbl.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(lbl, "visible_ratio", 1.0, time)

static func _paint_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://Shaders/painted_text.gdshader")
	return _material

static func _text_nodes(root: Node) -> Array:
	var found: Array = []
	for child in root.get_children():
		if child is Label or child is RichTextLabel:
			found.append(child)
		found.append_array(_text_nodes(child))
	return found
