#============================================================
#    Identical Room Map Generator
#============================================================
# - author: zhangxuetu
# - datetime: 2026-03-01 18:48:02
# - version: 4.6.1.stable
#============================================================
## 全等大小房间地图生成器
##
##地图的大小都是相同的，而且要设置房间的上下左右通道，否则有可能连接起来墙堵住了。
class_name IdenticalRoomMapGenerator
extends MyNode

enum Type {
	LEFT_RIGHT, # 左右有通路的房间
	AROUND, # 四周都有通路
	DOWN_LEFT_RIGHT, # 顶部的房间
	TOP_LEFT_RIGHT, # 底部的房间
}


@export var auto_start: bool = false
## 地图大小
@export var map_size: Vector2i = Vector2i(3, 3)
## 基础模板节点，用于获取整个房间大小
@export var base_template_map: TileMapLayer
## 地图类型分类的父节点。子节点的名字需要和上面 Type 枚举的名字保持一致
@export var group: Node
## 输出显示到的地图节点
@export var display_map: TileMapLayer
## 生成地图种子数
@export var seed_number : int = 0


## 房间类型对应的地图节点列表
var type_to_rooms_dict : Dictionary = {}
## 房间数据
var map_room_dict : Dictionary = {}


func _ready() -> void:
	# 房间节点类型表
	for type in group.get_children():
		# 按照 Type 类型下的子节点名称，来获取对应类型的房间模板列表
		var key = str(type.name).to_upper() 
		if Type.has(key):
			type_to_rooms_dict[Type[key]] = type.get_children()
	if auto_start:
		start()


## 开始准备地图
func start() -> void:
	# 开始生成
	var rnd := RandomNumberGenerator.new()
	if seed_number == 0:
		seed_number = randi_range(0, 99999)
		print("随机种子数：%d" % seed_number)
	rnd.seed = seed_number
	generate(map_size, rnd)
	
	# 设置生成地图围绕一圈无法出去的墙
	var room_rect := base_template_map.get_used_rect()
	room_rect.size *= map_size
	room_rect.size += Vector2i(1, 0)
	const WALL_ID = 1
	FuncUtil.for_rect_around(room_rect, display_map.set_cell.bind(WALL_ID, Vector2i()))
	
	# 更新地形瓦片看起来更自然
	display_map.set_cells_terrain_connect(display_map.get_used_cells_by_id(WALL_ID), 0, 0, true)


## 开始生成地图
func generate(
	size: Vector2i, 
	random_number_generator: RandomNumberGenerator = null, 
	to_map: TileMapLayer = null,
):
	if random_number_generator == null:
		random_number_generator = RandomNumberGenerator.new()
	map_room_dict = {}
	var room_id = 0
	for y in range(size.y):
		for x in range(size.x):
			map_room_dict[Vector2i(x, y)] = {
				"id": room_id,
				"coord": Vector2i(x, y),
			}
			room_id += 1
	
	# 生成房间和其房间类型
	generate_room_type(map_room_dict, size, random_number_generator)
	
	# 设置随机对应类型的房间的地图
	var type
	var map : TileMapLayer
	for coords in map_room_dict:
		type = map_room_dict[coords]["type"]
		map = Array(type_to_rooms_dict[type]).pick_random()
		map_room_dict[coords]["map"] = map
	
	# 生成到场景中
	if to_map:
		display_map = to_map
	display_map.clear()
	display_map.show()
	var room_rect : Rect2i = base_template_map.get_used_rect()
	for coords in map_room_dict:
		map = map_room_dict[coords]["map"]
		var to_room_rect = room_rect
		to_room_rect.position = coords * room_rect.size + Vector2i.ONE
		TileMapUtil.copy_cell_to(map, room_rect, display_map, to_room_rect)


## 生成整个地图的每个位置房间的类型
func generate_room_type(data: Dictionary, size: Vector2i, random_number_generator: RandomNumberGenerator):
	# 每行的房间随机设置几个带有向下移动通道的房间
	var room_columns := range(size.x)
	var coords := Vector2i()
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
			coords = Vector2i(room_columns[i], line)
			if line == 0: # 第一行时
				data[coords]["type"] = Type.DOWN_LEFT_RIGHT
			elif line == size.y - 1: # 最后一行时
				data[coords]["type"] = Type.TOP_LEFT_RIGHT
			else: # 其他房间
				data[coords]["type"] = Type.AROUND
	
	var down_coords := Vector2i()
	var up_coords := Vector2i()
	for y in range(size.y):
		for x in range(size.x):
			coords = Vector2i(x, y)
			if not data[coords].has("type"):
				# 底部的房间
				down_coords = coords + Vector2i.DOWN
				if data.has(down_coords) and data[down_coords].has("type"):
					if data[down_coords]["type"] in [Type.AROUND, Type.TOP_LEFT_RIGHT]:
						data[coords]["type"] = Type.DOWN_LEFT_RIGHT
				
				# 顶部的房间
				up_coords = coords + Vector2i.UP
				if data.has(up_coords) and data[up_coords].has("type"):
					if data[up_coords]["type"] in [Type.AROUND, Type.DOWN_LEFT_RIGHT]:
						data[coords]["type"] = Type.TOP_LEFT_RIGHT
				
				# 其他类型则为左右普通房间
				if not data[coords].has("type"):
					data[coords]["type"] = Type.LEFT_RIGHT
	
