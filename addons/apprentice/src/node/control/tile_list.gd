#============================================================
#    Tile List
#============================================================
# - author: zhangxuetu
# - datetime: 2024-12-05 18:11:23
# - version: 4.3.0.stable
#============================================================
class_name TileList
extends HFlowContainer

signal selected(texture: Texture2D)

@export var tile_set: TileSet

var button_group := ButtonGroup.new()
var current_button_index : int = -1
var texture_list : Array[Texture2D] = []

func _ready() -> void:
	button_group.pressed.connect(
		func(button: Button):
			current_button_index = button.get_index()
			selected.emit(button.icon)
	)
	
	for source_index in tile_set.get_source_count():
		var source_id : int = tile_set.get_source_id(source_index)
		var tile_source : TileSetAtlasSource = tile_set.get_source(source_id)
		var tile_texture : Texture2D = tile_source.texture
		for tile_index in tile_source.get_tiles_count():
			var tile_button := Button.new()
			tile_button.focus_mode = Control.FOCUS_NONE
			tile_button.toggle_mode = true
			tile_button.button_group = button_group
			var texture := AtlasTexture.new()
			var atlas_coords : Vector2i = tile_source.get_tile_id(tile_index)
			texture.atlas = tile_texture
			texture.region = tile_source.get_tile_texture_region(atlas_coords, 0)
			tile_button.icon = texture
			texture_list.push_back(texture)
			add_child(tile_button)
	
	button_group.get_buttons()[0].button_pressed = true
