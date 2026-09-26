class_name BoardPaint

# Makes text on the wooden boards look hand painted: cream paint, soft brown edge,
# a little tilt, dry brush grain, and a left-to-right "painting on" reveal.

const PAINT := Color(1.0, 0.97, 0.9)
const ACCENT_PAINT := Color(1.0, 0.84, 0.45)
const EDGE := Color(0.24, 0.13, 0.05, 0.75)
const SHADOW := Color(0.18, 0.1, 0.04, 0.35)

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
		lbl.add_theme_color_override(color_key, ACCENT_PAINT if accent else Cosmetics.selected(Cosmetics.PAINT)["color"])
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
	var mat := lbl.material as ShaderMaterial
	if mat == null:
		return
	# Width of the actual text, not the whole label box, so short text doesn't lag
	var width := lbl.size.x
	var font := lbl.get_theme_font("font") if lbl is Label else lbl.get_theme_font("normal_font")
	var font_size := lbl.get_theme_font_size("font_size") if lbl is Label else lbl.get_theme_font_size("normal_font_size")
	if lbl is Label and font:
		width = minf(width, font.get_multiline_string_size(lbl.text, lbl.horizontal_alignment, lbl.size.x, font_size).x)
	var start_x := (lbl.size.x - width) / 2.0 if lbl is Label and lbl.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER else 0.0
	var lines: int = maxi(1, lbl.get_line_count())
	# Match the shader's rows to the real text lines, not the label box, so each line paints on its own
	var line_height := lbl.size.y / lines
	var text_top := 0.0
	if lbl is Label:
		line_height = lbl.get_line_height() + lbl.get_theme_constant("line_spacing")
		var text_height := line_height * lines - lbl.get_theme_constant("line_spacing")
		match lbl.vertical_alignment:
			VERTICAL_ALIGNMENT_CENTER:
				text_top = (lbl.size.y - text_height) / 2.0
			VERTICAL_ALIGNMENT_BOTTOM:
				text_top = lbl.size.y - text_height
	elif lbl is RichTextLabel:
		line_height = lbl.get_content_height() / float(lines)
	mat.set_shader_parameter("label_width", start_x + width)
	mat.set_shader_parameter("line_count", float(lines))
	mat.set_shader_parameter("line_height", line_height)
	mat.set_shader_parameter("text_top", text_top)
	mat.set_shader_parameter("reveal", 0.0)
	# One quick brush swipe per line, each with its own swish
	var stroke := clampf(width / 2200.0, 0.14, 0.32)
	var tw := lbl.create_tween()
	tw.tween_interval(delay)
	for line in lines:
		tw.tween_callback(AudioManager.play_brush_stroke.bind(stroke))
		tw.tween_method(func(v: float): mat.set_shader_parameter("reveal", v),
			float(line) / lines, float(line + 1) / lines, stroke) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.04)

static func _paint_material() -> ShaderMaterial:
	# Each label gets its own copy so they can paint on independently
	var mat := ShaderMaterial.new()
	mat.shader = load("res://Shaders/painted_text.gdshader")
	return mat

static func _text_nodes(root: Node) -> Array:
	var found: Array = []
	for child in root.get_children():
		if child is Label or child is RichTextLabel:
			found.append(child)
		found.append_array(_text_nodes(child))
	return found
