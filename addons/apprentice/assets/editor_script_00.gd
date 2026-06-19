# 2026-03-07 14:54:37
@tool
extends EditorScript

# 入口函数：在编辑器中运行此脚本时执行
func _run():
	for radius in [16, 32, 64, 128, 256]:
		var img = Image.create(radius, radius, false, Image.FORMAT_RGBA8)
		CanvasUtil.draw_circle_to_image(img, Vector2i(radius, radius) /  2, radius / 2, Color.WHITE, true, 0, false)
		# 3. 保存为 PNG（请根据需要修改路径）
		var save_path = "res://addons/apprentice/assets/circle_%d.png" % radius
		var error = img.save_png(save_path)
		print(error_string(error), "  ", save_path)
	EditorUtil.scan_files()


# 核心绘制函数（含抗锯齿开关）
# 参数：
# - img: 目标 Image
# - center: 圆心坐标
# - radius: 半径
# - color: 颜色
# - is_solid: 是否实心（默认true）
# - line_width: 空心线宽（默认1，仅is_solid=false时生效）
# - antialiased: 是否开启抗锯齿（默认true）
func draw_circle_to_image(
	img: Image, 
	center: Vector2i, 
	radius: int, 
	color: Color, 
	is_solid: bool = true, 
	line_width: int = 1,
	antialiased: bool = true
):
	# 参数校验
	assert(radius >= 0, "半径不能为负数")
	assert(line_width >= 1, "线宽至少为1")

	var width = img.get_width()
	var height = img.get_height()

	if antialiased:
		# --- 抗锯齿模式 ---
		if is_solid:
			for x in range(width):
				for y in range(height):
					var dx = x - center.x
					var dy = y - center.y
					var dist = sqrt(dx * dx + dy * dy)
					var alpha = smoothstep(radius + 0.5, radius - 0.5, dist)
					if alpha > 0.0:
						img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
		else:
			var half_width = line_width / 2.0
			var inner_r = radius - half_width
			var outer_r = radius + half_width
			for x in range(width):
				for y in range(height):
					var dx = x - center.x
					var dy = y - center.y
					var dist = sqrt(dx * dx + dy * dy)
					var outer_alpha = smoothstep(outer_r + 0.5, outer_r - 0.5, dist)
					var inner_alpha = smoothstep(inner_r - 0.5, inner_r + 0.5, dist)
					var alpha = outer_alpha * inner_alpha
					if alpha > 0.0:
						img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	else:
		# --- 非抗锯齿模式（性能优先） ---
		var radius_sq = radius * radius
		if is_solid:
			for x in range(width):
				for y in range(height):
					var dx = x - center.x
					var dy = y - center.y
					if dx * dx + dy * dy <= radius_sq:
						img.set_pixel(x, y, color)
		else:
			var half_width = line_width / 2.0
			var inner_r = radius - half_width
			var outer_r = radius + half_width
			var inner_r_sq = inner_r * inner_r
			var outer_r_sq = outer_r * outer_r
			for x in range(width):
				for y in range(height):
					var dx = x - center.x
					var dy = y - center.y
					var dist_sq = dx * dx + dy * dy
					if dist_sq >= inner_r_sq and dist_sq <= outer_r_sq:
						img.set_pixel(x, y, color)
