#============================================================
#    Map Room Generator
#============================================================
# - author: zhangxuetu
# - datetime: 2025-06-02 20:57:27
# - version: 4.4.1.stable
#============================================================
## 生成的房间信息和基本的砖块瓦片。只要设置 [member group] 属性选择一个父节点，在其下边
##添加 [enum Type] 枚举里相同名称的节点，在其下边添加相同地图房间大小的预设房间地图即可
##[br]
##[br][b]注意：分组的房间的节点名要和 [enum Type] 枚举里的名字一样才能对应上！[/b]
class_name MapRoomGenerator
extends Node2D


enum Type {
	LEFT_RIGHT, ## 左右有通路的房间
	AROUND, ## 四周都有通路
	DOWN_LEFT_RIGHT, ## 顶部的房间
	TOP_LEFT_RIGHT, ## 底部的房间
}

@export var auto_start : bool = false
## 地图大小
@export var map_size: Vector2i = Vector2i(3, 3)
## 生成地图种子数
@export var seed_number : int = 0
## 地图瓦片的 ID
@export var wall_id : int = 1
## 基础模板节点，用于获取整个房间大小。可以在地图的四个角落设置一个瓦片即可
@export var base_template_map: TileMapLayer
## 地图类型分类的父节点。子节点的名字需要和上面 Type 枚举的名字保持一致
@export var group: Node
## 输出显示到的地图节点
@export var display_map: TileMapLayer
## 生成后周围包围的墙的瓦片厚度
@export var around_wall_width : int = 1
## 显示网格线
@export var show_grid_line: bool = false:
	set(v):
		show_grid_line = v
		queue_redraw()
## 显示房间信息
@export var show_room_info: bool = false:
	set(v):
		show_room_info = v
		if not coord_to_room_data_dict.is_empty():
			for coord in coord_to_room_data_dict:
				var label := coord_to_room_data_dict[coord].get("label") as Label
				if label == null:
					label = Label.new()
					display_map.add_child(label)
					coord_to_room_data_dict[coord]["label"] = label
				label.text = JSON.stringify(coord_to_room_data_dict[coord], "\t")
				label.position = coord * base_template_map.get_used_rect().size * base_template_map.tile_set.tile_size + Vector2i(64, 64)
				label.visible = show_room_info
##网格偏移
@export var line_offset : Vector2 = Vector2(0, 0):
	set(v):
		line_offset = v
		queue_redraw()

var random_number_generator := StableRandomGenerator.new()

var type_to_rooms_dict := {} #房间类型对应的地图节点列表
var coord_to_room_data_dict := {} #地图里的房间的信息
var room_rect: Rect2i  #单个房间的大小


func _ready():
	if auto_start:
		start()

func _draw():
	if show_grid_line:
		var room_size = base_template_map.get_used_rect().size
		var tile_size = base_template_map.tile_set.tile_size
		var room_grid_size = room_size * tile_size
		
		# 房间网格
		for x in map_size.x + 1:
			draw_line(Vector2(x * room_grid_size.x, 0) + line_offset, Vector2(x * room_grid_size.x, room_grid_size.y * map_size.y) + line_offset, Color.WHITE)
		for y in map_size.y + 1:
			draw_line(Vector2(0, y * room_grid_size.y) + line_offset, Vector2(room_grid_size.x * map_size.x, y * room_grid_size.y) + line_offset, Color.WHITE)
		
		# 瓦片网格
		for x in room_size.x * map_size.x + 1:
			draw_line(Vector2(x * tile_size.x, 0) + line_offset, Vector2(x * tile_size.x, room_grid_size.y * map_size.y) + line_offset, Color(1,1,1,0.2))
		for y in room_size.y * map_size.y + 1:
			draw_line(Vector2(0, y * tile_size.y) + line_offset, Vector2(room_grid_size.x * map_size.x, y * tile_size.y) + line_offset, Color(1,1,1,0.2))


func start() -> void:
	# 房间节点类型表
	for type in group.get_children():
		var key = str(type.name).to_upper()
		if Type.has(key):
			type_to_rooms_dict[Type[key]] = type.get_children()
	
	# 随机种子
	if seed_number == 0:
		seed_number = randi_range(0, 99999)
	random_number_generator.seed = seed_number
	print_debug("随机种子数：%d" % seed_number)
	
	# 开始生成
	room_rect = base_template_map.get_used_rect()
	room_rect.position = Vector2i()
	generate(map_size)
	
	# 瓦片添加到场景中
	display_map.clear()
	display_map.show()
	for coord in coord_to_room_data_dict:
		var map : TileMapLayer = coord_to_room_data_dict[coord]["map"]
		var to_room_rect : Rect2i = room_rect
		to_room_rect.position = coord * room_rect.size + Vector2i.ONE
		TileMapUtil.copy_cell_to(map, room_rect, display_map, to_room_rect)
	
	# 设置生成地图围绕一圈无法出去的墙
	var tmp_room_rect : Rect2i = room_rect
	tmp_room_rect.size *= map_size
	tmp_room_rect.size.x += 1
	tmp_room_rect.size.y += 1
	for __ in around_wall_width:
		FuncUtil.for_rect_around(tmp_room_rect, display_map.set_cell.bind(wall_id, Vector2i()))
		tmp_room_rect = tmp_room_rect.grow(1)


## 开始生成地图
func generate(size: Vector2i):
	coord_to_room_data_dict = {}
	var room_id : int = 0
	var room_size : Vector2i = base_template_map.get_used_rect().size
	for y in range(size.y):
		for x in range(size.x):
			coord_to_room_data_dict[Vector2i(x, y)] = {
				"id": room_id,
				"coord": Vector2i(x, y),
				"rect": Rect2i(Vector2i(x, y) * room_size, room_size),
			}
			room_id += 1
	
	# 生成房间和其房间类型
	generate_room_type(size)
	
	# 设置随机对应类型的房间的地图
	var type
	var map : TileMapLayer
	for coord in coord_to_room_data_dict:
		type = coord_to_room_data_dict[coord]["type"]
		map = random_number_generator.pick_random(type_to_rooms_dict[type])
		coord_to_room_data_dict[coord]["map"] = map
		coord_to_room_data_dict[coord]["type_string"] = Type.keys()[type]
	
	if show_grid_line:
		queue_redraw()
	self.show_room_info = show_room_info


## 生成整个地图的每个位置房间的类型
func generate_room_type(size: Vector2i):
	# 每行的房间随机设置几个带有向下移动通道的房间
	var room_columns := range(size.x)
	var coord := Vector2i()
	for line in range(0, size.y):
		#重新打乱这行的房间顺序
		var tmp_idx : int = -1
		var tmp_value = null
		for i in ceili(room_columns.size()/2):
			tmp_value = room_columns[i]
			tmp_idx = random_number_generator.randi() % room_columns.size()
			room_columns[i] = room_columns[tmp_idx]
			room_columns[tmp_idx] = tmp_value
		
		# 设置当前行的随机几个可以上下有通过的路口的房间
		var number : int = max(1, random_number_generator.randi_range(1, int(size.x * 0.3)))
		for i in number:
			coord = Vector2i(room_columns[i], line)
			if line == 0: # 第一行时
				coord_to_room_data_dict[coord]["type"] = Type.DOWN_LEFT_RIGHT
			elif line == size.y - 1: # 最后一行时
				coord_to_room_data_dict[coord]["type"] = Type.TOP_LEFT_RIGHT
			else: # 其他房间
				coord_to_room_data_dict[coord]["type"] = Type.AROUND
	
	var down_coords := Vector2i()
	var up_coords := Vector2i()
	for y in range(size.y):
		for x in range(size.x):
			coord = Vector2i(x, y)
			if not coord_to_room_data_dict[coord].has("type"):
				# 底部的房间
				down_coords = coord + Vector2i.DOWN
				if coord_to_room_data_dict.has(down_coords) and coord_to_room_data_dict[down_coords].has("type"):
					if coord_to_room_data_dict[down_coords]["type"] in [Type.AROUND, Type.TOP_LEFT_RIGHT]:
						coord_to_room_data_dict[coord]["type"] = Type.DOWN_LEFT_RIGHT
				
				# 顶部的房间
				up_coords = coord + Vector2i.UP
				if coord_to_room_data_dict.has(up_coords) and coord_to_room_data_dict[up_coords].has("type"):
					if coord_to_room_data_dict[up_coords]["type"] in [Type.AROUND, Type.DOWN_LEFT_RIGHT]:
						coord_to_room_data_dict[coord]["type"] = Type.TOP_LEFT_RIGHT
				
				# 其他类型则为左右普通房间
				if not coord_to_room_data_dict[coord].has("type"):
					coord_to_room_data_dict[coord]["type"] = Type.LEFT_RIGHT

## 获取房间数
func get_room_count() -> int:
	return coord_to_room_data_dict.size()

## 获取这个房间 ID 的数据
func get_room_data(room_id: int) -> Dictionary:
	for data in coord_to_room_data_dict.values():
		if data["id"] == room_id:
			return data
	return {}

## 获取这个房间坐标的数据
func get_room_data_by_coord(room_coord: Vector2i) -> Dictionary:
	return coord_to_room_data_dict.get(room_coord, {})

## 获取这个房间的所有的瓦片
func get_room_cells(room_id: int) -> Array[Vector2i]:
	var data = get_room_data(room_id)
	if data:
		return get_room_cells_by_coord(data["coord"])
	return Array([], TYPE_VECTOR2I, "", null)

func get_room_rect() -> Rect2i:
	return Rect2i(Vector2i(), map_size - Vector2i.ONE)

## 获取这个房间所在坐标的房间ID。因为整张地图是多个房间拼接而成的，这个方法可以获取对应拼接的房间坐标。
func get_room_id_by_coord(room_coord: Vector2i) -> int:
	var data : Dictionary = get_room_data_by_coord(room_coord)
	if data:
		return data["id"]
	return -1

## 获取这个瓦片位置的房间 ID。如果不存在，则返回 -1
func get_room_id_by_cell(cell: Vector2i) -> int:
	cell.y -= 1
	var room_coord : Vector2i = get_room_coord_by_cell(cell)
	return get_room_id_by_coord(room_coord)

## 获取这个位置的房间的ID
func get_room_id_by_position(pos: Vector2) -> int:
	var cell : Vector2i = display_map.local_to_map(pos)
	return get_room_id_by_cell(cell)

func get_room_coord_by_id(room_id: int) -> Vector2i:
	var room_data : Dictionary = get_room_data(room_id)
	return room_data.get("coord", Vector2i(-1, -1))

## 获取这个房间的所有的瓦片所在的坐标位置。
##[br]
##[br]- [param calculation_offset]  如果为 [code]true[/code] 返回瓦片在地图上的位置，否则按照原点为 [code]Vector2i(0, 0)[/code] 的位置返回
func get_room_cells_by_coord(room_coord: Vector2i, calculation_offset: bool = true) -> Array[Vector2i]:
	if coord_to_room_data_dict.has(room_coord):
		var map : TileMapLayer = coord_to_room_data_dict[room_coord]["map"]
		if calculation_offset:
			var offset : Vector2i = room_coord * base_template_map.get_used_rect().size
			var cells : Array = map.get_used_cells().map( func(cell): return cell + offset )
			return Array(cells, TYPE_VECTOR2I, "", null)
		return map.get_used_cells()
	return Array([], TYPE_VECTOR2I, "", null)

func get_room_cells_by_id(room_id: int, calculation_offset: bool = true) -> Array[Vector2i]:
	var room_coord : Vector2i = get_room_coord_by_id(room_id)
	return get_room_cells_by_coord(room_coord)

## 获取这个瓦片位置的房间坐标
func get_room_coord_by_cell(cell: Vector2i) -> Vector2i:
	var room_coord : Vector2i = cell / room_rect.size
	room_coord.x = clampi(room_coord.x, 0, map_size.x - 1)
	room_coord.y = clampi(room_coord.y, 0, map_size.y - 1)
	return room_coord
