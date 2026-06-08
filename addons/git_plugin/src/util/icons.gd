#============================================================
#    Icons
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-06 18:10:18
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Icons

const ICON = preload("uid://dmomu7e45rfed")

static var _handle_icon_cache: Dictionary[String, Texture2D] = {}

static func get_icon_by_path(file: String) -> Texture2D:
	var ext = file.get_extension()
	match ext:
		"gd": return get_icon("Script")
		"tscn", "scn": return get_icon("PackedScene")
		"tres", "res": return get_icon("ResourcePreloader")
		"png", "jpeg", "jpg", "bmp", "svg":
			return get_icon("Image")
		"uid":
			if not _handle_icon_cache.has(ext):
				var texture : Texture2D = get_icon("UID")
				var image : Image = texture.get_image().duplicate()
				_grayscale(image)
				_handle_icon_cache[ext] = ImageTexture.create_from_image(image)
			return _handle_icon_cache[ext]
		"import":
			return get_icon("ArrowRight")
		_:
			if file.get_file() == "":
				return get_icon("Folder")
			else:
				return get_icon("File")

static func get_icon(name: String) -> Texture2D:
	if Engine.is_editor_hint():
		return EditorInterface.get_base_control().get_theme_icon(name, "EditorIcons")
	#if DisplayServer.is_dark_mode_supported():
		#if not DisplayServer.is_dark_mode():
			#return ICON.get_icon(name, "EditorIcons")
	return ICON.get_icon(name, "EditorIcons")


# 让图片灰度化
static func _grayscale(image: Image) -> void:
	#interface/theme/base_color
	if Engine.is_editor_hint():
		var setting : EditorSettings = EditorInterface.get_editor_settings()
		var base_color : Color = setting.get_setting("interface/theme/base_color")
		var invert_color: Color = Color(1.0-base_color.r, 1.0-base_color.g, 1.0-base_color.b, 0.5)
		var size : Vector2i = image.get_size()
		var color: Color
		var v: float
		for y in size.y:
			for x in size.x:
				color = image.get_pixel(x, y)
				if color.a > 0:
					v = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
					var new_color = Color(v,v,v).blend(invert_color)
					new_color.a = color.a
					image.set_pixel(x, y, new_color)
	else:
		var size : Vector2i = image.get_size()
		var color: Color
		var v: float
		for y in size.y:
			for x in size.x:
				color = image.get_pixel(x, y)
				if color.a > 0:
					v = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
					image.set_pixel(x, y, Color(v,v,v, color.a))
