class_name BoardPaint

# Makes text on the wooden boards look hand painted: cream paint, soft brown edge,
# a little tilt, dry brush grain, and a left-to-right "painting on" reveal.
# Buttons, stars and tiles on a board can paint on the same way with paint_tree.

const PAINT := Color(1.0, 0.97, 0.9)
const ACCENT_PAINT := Color(1.0, 0.84, 0.45)
const EDGE := Color(0.24, 0.13, 0.05, 0.75)
const STAR := "*"   # marks where star_row draws a star icon

static func apply(root: Node, reveal: bool = true, delay: float = 0.15) -> void:
	var i := 0
	for lbl in _text_nodes(root):
		style(lbl)
		if reveal and lbl.is_visible_in_tree():
			paint_on(lbl, delay + i * 0.18)
			i += 1

static func style(lbl: Control, accent: bool = false, tilt: bool = true) -> void:
	var color_key := "default_color" if lbl is RichTextLabel else "font_color"
	# Keep any colour the scene set on purpose (e.g. gold headings), otherwise cream paint
	if not lbl.has_theme_color_override(color_key) or lbl.get_theme_color(color_key) == Color.WHITE:
		lbl.add_theme_color_override(color_key, ACCENT_PAINT if accent else Cosmetics.selected(Cosmetics.PAINT)["color"])
	lbl.add_theme_color_override("font_outline_color", EDGE)
	lbl.add_theme_constant_override("outline_size", 5)
	var font_size := lbl.get_theme_font_size("normal_font_size" if lbl is RichTextLabel else "font_size")
	ButtonFx.hard_shadow(lbl, font_size, 5)
	lbl.material = _paint_material()
	# Hand-placed, not perfectly level
	if tilt and lbl.rotation == 0.0:
		lbl.pivot_offset = lbl.size / 2.0
		lbl.rotation_degrees = randf_range(-1.2, 1.2)

static func paint_on(lbl: Control, delay: float = 0.0, sound: bool = true) -> void:
	if lbl.has_meta("paint_tween"):
		var previous: Tween = lbl.get_meta("paint_tween")
		if previous.is_valid():
			previous.kill()
	var mat := lbl.material as ShaderMaterial
	if mat == null:
		return
	if not SaveManager.paint_on:
		_show_painted(mat)
		return
	if not (lbl is Label or lbl is RichTextLabel):
		_sweep(lbl, mat, delay, sound)
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
	lbl.set_meta("paint_tween", tw)
	tw.tween_interval(delay)
	for line in lines:
		if sound:
			tw.tween_callback(AudioManager.play_brush_stroke.bind(stroke))
		tw.tween_method(func(v: float): mat.set_shader_parameter("reveal", v),
			float(line) / lines, float(line + 1) / lines, stroke) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.04)

# Paints a board item and everything drawn inside it (tiles, buttons, star rows).
# Children start a little later the further right they sit, so it reads as one brush pass
static func paint_tree(root: Control, delay: float = 0.0, sound: bool = true, stroke: float = 0.22) -> void:
	var items := _drawn_items(root)
	# Hide it all now, then paint once containers have laid out their sizes
	for item in items:
		if not item.material is ShaderMaterial:
			item.material = _paint_material(0.0, 0.12)
		if SaveManager.paint_on:
			(item.material as ShaderMaterial).set_shader_parameter("reveal", 0.0)
		else:
			_show_painted(item.material)
	if not SaveManager.paint_on:
		return
	await root.get_tree().process_frame
	if not is_instance_valid(root) or root.is_queued_for_deletion():
		return
	var left := root.get_global_rect().position.x
	var width := maxf(root.size.x, 1.0)
	var first := true
	for item in items:
		if not is_instance_valid(item) or item.is_queued_for_deletion() or not item.is_visible_in_tree():
			continue
		var along := clampf((item.get_global_rect().position.x - left) / width, 0.0, 1.0)
		paint_on(item, delay + along * stroke, sound and first)
		first = false

# A row of painted text with drawn stars wherever a part is STAR, e.g. ["12 / 54", STAR]
static func star_row(parts: Array, font_size: int, accent: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", int(font_size * 0.18))
	for part in parts:
		if part == STAR:
			var star := StarIcon.new()
			star.custom_minimum_size = Vector2.ONE * font_size * 0.9
			star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			star.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(star)
		else:
			var lbl := Label.new()
			lbl.text = part
			lbl.add_theme_font_size_override("font_size", font_size)
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(lbl)
			style(lbl, accent, false)
	return row

# One sweep across a whole control, for buttons, tiles and stars
static func _sweep(item: Control, mat: ShaderMaterial, delay: float, sound: bool) -> void:
	mat.set_shader_parameter("label_width", item.size.x)
	mat.set_shader_parameter("line_count", 1.0)
	mat.set_shader_parameter("line_height", maxf(item.size.y, 1.0))
	mat.set_shader_parameter("text_top", 0.0)
	mat.set_shader_parameter("reveal", 0.0)
	var stroke := clampf(item.size.x / 2200.0, 0.12, 0.3)
	var tw := item.create_tween()
	item.set_meta("paint_tween", tw)
	tw.tween_interval(delay)
	if sound:
		tw.tween_callback(AudioManager.play_brush_stroke.bind(stroke))
	tw.tween_method(func(v: float): mat.set_shader_parameter("reveal", v), 0.0, 1.0, stroke) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Paint-on turned off in settings: skip the stroke and show it finished, however wide it is
static func _show_painted(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("label_width", 100000.0)
	mat.set_shader_parameter("line_count", 1.0)
	mat.set_shader_parameter("reveal", 1.0)

static func _paint_material(grain: float = -1.0, streaks: float = -1.0) -> ShaderMaterial:
	# Each label gets its own copy so they can paint on independently
	var mat := ShaderMaterial.new()
	mat.shader = load("res://Shaders/painted_text.gdshader")
	if grain >= 0.0:
		mat.set_shader_parameter("grain", grain)
	if streaks >= 0.0:
		mat.set_shader_parameter("streak_strength", streaks)
	return mat

# Everything under root that draws something: the root itself, labels, buttons, stars
static func _drawn_items(root: Control) -> Array:
	var found: Array = []
	if root is Label or root is RichTextLabel or root is BaseButton or root is StarIcon or root is Panel or root is Slider:
		found.append(root)
	for child in root.get_children():
		if child is Control:
			found.append_array(_drawn_items(child))
	return found

static func _text_nodes(root: Node) -> Array:
	var found: Array = []
	for child in root.get_children():
		if child is Label or child is RichTextLabel:
			found.append(child)
		found.append_array(_text_nodes(child))
	return found
