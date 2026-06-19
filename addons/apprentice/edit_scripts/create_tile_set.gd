#============================================================
#    Create Tile Set
#============================================================
# - author: zhangxuetu
# - datetime: 2026-05-01 22:59:51
# - version: 4.7.0.dev5
#============================================================
# 创建一个 TileSet 文件
@tool
extends EditorScript


func _run() -> void:
	var tile_size: Vector2i = Vector2i(32, 32)
	var save_file_path: String = "res://tile_set_%s.tres" % tile_size.x
	var color_count: int = 12
	
	var tile_set : TileSet = TileSet.new()
	tile_set.tile_size = tile_size
	var source : TileSetAtlasSource = TileSetAtlasSource.new()
	tile_set.add_source(source)
	var image := Image.create_empty(tile_size.x, tile_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	source.texture_region_size = tile_size
	source.texture = texture
	source.resource_name = "rectangle"
	source.create_tile(Vector2i())
	
	# 创建备选瓦片
	for __ in color_count:
		var atlas_coords : Vector2i = Vector2i(0, 0)
		var alter_id : int = source.create_alternative_tile(atlas_coords)
		var tile_data : TileData = source.get_tile_data(atlas_coords, alter_id)
		tile_data.modulate = Color.from_hsv((alter_id-1) / float(color_count), 1, 1)
	
	# 保存
	FileUtil.save_resource(tile_set, save_file_path)
	EditorUtil.scan_files()
	EditorUtil.update_file(save_file_path)
	
	print(Time.get_time_string_from_system(), "ok")
