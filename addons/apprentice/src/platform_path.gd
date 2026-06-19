#============================================================
#    Platform Path
#============================================================
# - author: zhangxuetu
# - datetime: 2025-06-05 20:13:13
# - version: 4.4.1.stable
#============================================================
## 参考链接：https://www.bilibili.com/video/BV161421C7Hf
class_name PlatformPath
extends Node2D


## 地板边缘点的 AStar 权重
const EDGE_POINT_WEIGHT = 1.5
## 地板边缘点向下落的点的 AStar 权重
const FALL_POINT_WEIGHT = 1.5
## 地板边缘点向上跳跃的点的 AStar 权重
const JUMP_POINT_WEIGHT = 2

## 自动开始分析生成数据
@export var auto_start : bool = false
##分析的地图
@export var map: TileMapLayer
##瓦片ID。包含在这个列表的ID值则认为是瓦片
@export var wall_tile_ids : Array[int] = []
##边缘点的瓦片ID。如果瓦片是这个ID，则识别为边缘点
@export var edge_tile_ids : Array[int] = []
##边缘点的瓦片地图集坐标。如果瓦片是这个地图集的坐标，则识别为边缘点
@export var edge_atlas_coords : Array[Vector2i] = []
##空白的可移动通过的点，只有在这个里面的点才会添加到连通的点里。如果为空，则默认整个地图
@export var empty_passway_tiles: Array[Vector2i] = []
## 跳跃高度网格数。如果超过这个数量则代表跳不上去，则不连接这个落脚点
@export var jump_cell_count : float = 3.0


@export_group("Debug")
##显示点的连接线
@export var show_line: bool = false:
	set(v):
		show_line = v
		queue_redraw()
##绘制连接线的位置的偏移，默认绘制是以瓦片的顶点位置绘制的
@export var draw_line_offset: Vector2i = Vector2i():
	set(v):
		draw_line_offset = v
		queue_redraw()
#显示的线条粗细，如果为 -1，则是向量绘制最细宽度的线条，缩放不影响线条的显示
@export_range(-1,1,1,"or_greater") var draw_line_width: int = -1:
	set(v):
		draw_line_width = v
		queue_redraw()

var edge_floor_cells := {} #边缘的地面瓦片坐标
var edge_around_cells := {}  #边缘瓦片坐标
var fall_cells := {} #跳跃落脚点
var outside_cells := {}
var outside_empty_cells := {}
var floor_cells : Array = []

var graph := AStar2D.new()
var cell_to_graph_id_dict := {} # graph 中的点ID所在的单元格
var connect_point_ids_dict : Dictionary[Variant, Array] = {} ##连接到的点列表
var map_rect: Rect2i


func _ready():
	if auto_start:
		start()


func start():
	if wall_tile_ids.is_empty():
		push_error("没有设置砖块瓦片的 ID")
	
	print("=".repeat(40))
	print("  [ 平台地图路径 ]")
	var start_time = Time.get_ticks_msec()
	create_map_points()
	create_connects()
	queue_redraw.call_deferred()
	print_debug("地图路径分析时间： %.3f s" % [ (Time.get_ticks_msec() - start_time) / 1000.0 ])
	print("=".repeat(40))


func _draw():
	if show_line and is_instance_valid(map):
		# 连接点
		var radius : float = (draw_line_width + 3) * 1.25
		for point_id in graph.get_point_ids():
			draw_circle(graph.get_point_position(point_id) + Vector2(draw_line_offset), radius, Color.RED, true, draw_line_width, true)
		for cell in edge_floor_cells:
			draw_circle(cell * map.tile_set.tile_size + draw_line_offset + Vector2i(0, radius*2), radius, Color(1,1,1,0.7), true, draw_line_width, true)
		for cell in fall_cells:
			draw_circle(cell * map.tile_set.tile_size + draw_line_offset + Vector2i(0, radius * 4), radius, Color(1,1,1,0.2), true, draw_line_width, true)
		
		for id in connect_point_ids_dict:
			for i in connect_point_ids_dict[id]:
				draw_line(
					graph.get_point_position(id) + Vector2(draw_line_offset),
					graph.get_point_position(i) + Vector2(draw_line_offset),
					Color(1,0,0,0.5),
					draw_line_width
				)
		
		# 寻路时的周围点位置
		for cell in _visited_point_path_dict:
			draw_rect(Rect2(cell * 64, map.tile_set.tile_size * 0.5), Color(1,1,1,0.2))
		_visited_point_path_dict.clear()


## 瓦片坐标是否是空的
func is_empty(coords: Vector2i) -> bool:
	var id : int = map.get_cell_source_id(coords)
	return id == -1 or not wall_tile_ids.has(id)

## 这个坐标的瓦片是否为属性设置中的边缘点
func is_custom_edge_tile(coords: Vector2i) -> bool:
	var id : int = map.get_cell_source_id(coords)
	var atlas_coords : Vector2i = map.get_cell_atlas_coords(coords)
	return id == -1 or (edge_tile_ids.has(id) and edge_atlas_coords.is_empty() or edge_atlas_coords.has(atlas_coords))

var _visited_point_path_dict := {}  #寻路时寻找最近的点时搜索经过的瓦片坐标
func get_point_path(from_position: Vector2, to_position: Vector2) -> Array[Vector2]:
	var list : Array[Vector2] = []
	var from_point : int = find_closest_point(from_position)
	queue_redraw()
	if from_point == -1:
		return list
	var to_point : int = find_closest_point(to_position)
	queue_redraw()
	if to_point == -1:
		return list
	
	# 过滤节点
	var points : PackedVector2Array = graph.get_point_path(from_point, to_point)
	var last_id : int = 1
	for point in points:
		if list.size() >= 2:
			# 如果当前和前两个点相同，则不添加
			if list[list.size()-1].y == point.y and list[list.size()-2].y == point.y:
				list[list.size()-1] = point
			else:
				list.append(point)
		else:
			list.append(point)
	
	return list

## 找到这个位置的下面是地面瓦片的位置
func get_floor_position(position_: Vector2) -> Vector2:
	var current_cell : Vector2i = map.local_to_map(position_)
	if not is_empty(current_cell) and not is_empty(current_cell + Vector2i.UP):
		# 如果选取的位置不是空白的，则不进行查找下方的地板瓦片的位置
		return Vector2.INF
	elif not is_empty(current_cell) and is_empty(current_cell + Vector2i.UP):
		# 所在位置正是地板的位置时，直接返回对应地板瓦片左上角位置
		return (current_cell + Vector2i.UP) * map.tile_set.tile_size
	
	# 这个位置下方最底部的空白地板位置
	var floor_pos : Vector2 = _floor_empty_pos(position_)
	
	# 如果这个位置的一半的位置是瓦片，则也视为这个角色可以站到的地板瓦片
	var left_pos : Vector2 = position_ - Vector2(map.tile_set.tile_size) * Vector2(0.5, 0)
	var left_cell : Vector2i = map.local_to_map(left_pos)
	if is_empty(left_cell + Vector2i.UP) and left_cell != current_cell:
		var left_floor_pos : Vector2 = _floor_empty_pos(left_pos)
		if left_floor_pos.y < floor_pos.y:
			# 如果左侧瓦片更靠上，则让这个瓦片为找到的空白地板位置
			return left_floor_pos
	var right_pos : Vector2 = position_ + Vector2(map.tile_set.tile_size) * Vector2(0.5, 0)
	var right_cell : Vector2i = map.local_to_map(right_pos)
	if is_empty(right_cell + Vector2i.UP) and right_cell != current_cell:
		var right_floor_pos : Vector2 = _floor_empty_pos(right_pos)
		if right_floor_pos.y < floor_pos.y:
			# 如果左侧瓦片更靠上，则让这个瓦片为找到的空白地板位置
			return right_floor_pos
	
	return floor_pos


func _floor_empty_pos(position_: Vector2) -> Vector2:
	var cell : Vector2i = map.local_to_map(position_)
	if map_rect.has_point(cell):
		# 如果当前的就是地板空位置，则直接返回
		if is_empty(cell) and not is_empty(cell + Vector2i.DOWN):
			return cell * map.tile_set.tile_size
		while map_rect.has_point(cell) and is_empty(cell):
			cell += Vector2i.DOWN
		return (cell + Vector2i.UP) * map.tile_set.tile_size
	return position_


## 找到这个位置最近的点
func find_closest_point(position_: Vector2) -> int:
	var start_cell : Vector2i = map.local_to_map(position_)
	if cell_to_graph_id_dict.has(start_cell):
		return cell_to_graph_id_dict[start_cell]
	
	if not is_empty(start_cell):
		start_cell += Vector2i.UP #可能当前位置是个瓦片
		if cell_to_graph_id_dict.has(start_cell):
			return cell_to_graph_id_dict[start_cell]
	
	var visited := { start_cell: null }
	if not map_rect.has_point(start_cell):
		return -1
	
	var last_move_point := [ start_cell ]
	var temp_cell := Vector2i.ZERO
	var found_cell : Variant = null
	while not last_move_point.is_empty():
		var next_move_point = []
		for cell in last_move_point:
			for dir in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, ]:
				temp_cell = cell + dir
				if not visited.has(temp_cell):
					# 贴着地面查找
					if is_empty(temp_cell) and (
						not is_empty(temp_cell + Vector2i(0, 1))
						or not is_empty(temp_cell + Vector2i(0, 2))
					):
						next_move_point.append(temp_cell)
					visited[temp_cell] = null
					if cell_to_graph_id_dict.has(temp_cell):
						found_cell = temp_cell
						break
			if typeof(found_cell) != TYPE_NIL:
				break
		if typeof(found_cell) != TYPE_NIL:
			break
		last_move_point = next_move_point
	_visited_point_path_dict.merge(visited)
	if typeof(found_cell) != TYPE_NIL:
		return cell_to_graph_id_dict[found_cell]
	return -1

## 获取这个位置最近的路径点
func get_closest_position(position_: Vector2) -> Vector2:
	var point_id = find_closest_point(position_)
	return graph.get_point_position(point_id)

## 两个同一水平位置的点是否可连通
func is_connectivity(from_pos: Vector2, to_pos: Vector2) -> bool:
	var from_tile : Vector2i = map.local_to_map(from_pos)
	var to_tile : Vector2i = map.local_to_map(to_pos)
	var dir : int = sign(to_tile.x - from_tile.x)  # 左右方向
	var p : Vector2i = from_tile + Vector2i(dir, 0)
	while is_empty(p) and map.get_used_rect().has_point(p):
		if is_empty(p + Vector2i.DOWN): # 如果同一行两个点之间存在有沟壑，则不算可连通
			return false
		if p == to_tile: #到达目标位置则代表连通了
			return true
		p.x += dir
	return false

## 创建地图连接点
func create_map_points() -> void:
	map_rect = map.get_used_rect()
	
	var cells : Array[Vector2i] = []
	if wall_tile_ids.size() == 1:
		cells = map.get_used_cells_by_id(wall_tile_ids[0])
	elif wall_tile_ids.size() > 1:
		for id in wall_tile_ids:
			cells.append_array(map.get_used_cells_by_id(id))
	else:
		cells = map.get_used_cells()
	
	var time = 0
	
	time = Time.get_ticks_msec()
	# 地图最外部的点，找到最外层的瓦片
	var tmp_map_rect : Rect2i = map_rect.grow(1)
	var last_around_empty_cells: Array = []
	last_around_empty_cells.append(tmp_map_rect.position)
	outside_empty_cells[tmp_map_rect.position] = null
	const FOUR_DIRECTION = [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]
	var next_cell : Vector2i
	while not last_around_empty_cells.is_empty():
		var next_empty_cells : Dictionary = {}
		for cell in last_around_empty_cells:
			# 向四周四个方向移动
			for dir:Vector2i in FOUR_DIRECTION:
				next_cell = cell + dir
				if tmp_map_rect.has_point(next_cell):
					if is_empty(next_cell):
						if not outside_empty_cells.has(next_cell):
							next_empty_cells[next_cell] = null
							outside_empty_cells[cell] = null # 记录这个地图外层点
					else:
						outside_cells[next_cell] = null
		last_around_empty_cells = next_empty_cells.keys()
	print("找到最外层的点耗时：%.3f s" % ((Time.get_ticks_msec() - time) / 1000.0))
	
	# 地面走路地板的点
	time = Time.get_ticks_msec()
	floor_cells = []
	for cell in outside_cells:
		while map_rect.has_point(cell):
			cell += Vector2i.RIGHT
			if not outside_empty_cells.has(cell) and is_empty(cell) and not is_empty(cell + Vector2i.DOWN):
				floor_cells.append(cell)
	# 走路地板上的贴近墙壁的点
	for cell in floor_cells:
		if not is_empty(cell + Vector2i.LEFT) or not is_empty(cell + Vector2i.RIGHT):
			add_point(cell)
	print("走路地板的点耗时：%.3f s" % ((Time.get_ticks_msec() - time) / 1000.0))
	
	# 查找左右的落脚点
	time = Time.get_ticks_msec()
	var up: Vector2i
	for cell_coords in cells:
		up = cell_coords + Vector2i.UP
		if is_empty(up) and map_rect.has_point(up) and (empty_passway_tiles.is_empty() or empty_passway_tiles.has(up)):
			# 左侧都为空，则开始找落脚点
			if is_empty(up + Vector2i.LEFT) and is_custom_edge_tile(cell_coords + Vector2i.LEFT):
				edge_floor_cells[up] = null
				edge_around_cells[up + Vector2i.LEFT] = null
				
				var up_id : int = add_point(up)
				var edge_id : int = add_point(up + Vector2i.LEFT, EDGE_POINT_WEIGHT, Vector2(map.tile_set.tile_size.x * 0.4, 0))
				add_connect_point(up_id, edge_id)
				
				for i in range(0, 4):
					var left := Vector2i(-i, 0)
					var fall_point : Vector2i = find_floor_cell(up + left)
					fall_cells[fall_point] = null
					
					var fid : int = add_point(fall_point, FALL_POINT_WEIGHT)
					var bidirectional = abs(fall_point.y - up.y) <= jump_cell_count
					add_connect_point(edge_id, fid, bidirectional)
			
			# 右侧
			if is_empty(up + Vector2i.RIGHT) and is_custom_edge_tile(cell_coords + Vector2i.RIGHT):
				edge_floor_cells[up] = null
				edge_around_cells[up + Vector2i.RIGHT] = null
				
				var up_id : int = add_point(up)
				var edge_id : int = add_point(up + Vector2i.RIGHT, EDGE_POINT_WEIGHT, Vector2(-map.tile_set.tile_size.x * 0.4, 0))
				add_connect_point(up_id, edge_id)
				
				for i in range(1, 4):
					var right := Vector2i(i, 0)
					var fall_point : Vector2i = find_floor_cell(up + right)
					fall_cells[fall_point] = null
					
					var fid : int = add_point(fall_point, FALL_POINT_WEIGHT)
					var bidirectional = abs(fall_point.y - up.y) <= jump_cell_count
					add_connect_point(edge_id, fid, bidirectional)
					
	print("添加左右落脚的点耗时：%.3f s" % ((Time.get_ticks_msec() - time) / 1000.0))


## 创建连接的点
func create_connects():
	# 同一水平线的瓦片ID分组
	var line_points_dict : Dictionary[Variant, Array] = {}
	for point_id in graph.get_point_ids():
		var pos := Vector2i(graph.get_point_position(point_id))
		line_points_dict.get_or_add(pos.y, []).append({
			"id": point_id,
			"pos": pos,
		})
		
	for y in line_points_dict:
		line_points_dict[y].sort_custom(
			func(a, b):
				return a["pos"].x < b["pos"].x
		)
		for idx in range(1, line_points_dict[y].size()):
			var left = line_points_dict[y][idx - 1]
			var right = line_points_dict[y][idx]
			if is_connectivity( left["pos"], right["pos"] ):
				add_connect_point(left["id"], right["id"])
	
	# 连接周围斜的边缘地面的瓦片坐标
	for cell in edge_around_cells:
		var tile_id = graph.get_closest_point(cell * map.tile_set.tile_size)
		var left_fall_tile = find_floor_cell(cell + Vector2i(-1, 0))
		if edge_floor_cells.has(left_fall_tile):
			var fall_tile_id = graph.get_closest_point(left_fall_tile * map.tile_set.tile_size)
			add_connect_point(tile_id, fall_tile_id, left_fall_tile.y - cell.y <= jump_cell_count)
		
		var right_fall_tile = find_floor_cell(cell + Vector2i(1, 0))
		if edge_floor_cells.has(right_fall_tile):
			var fall_tile_id = graph.get_closest_point(right_fall_tile * map.tile_set.tile_size)
			add_connect_point(tile_id, fall_tile_id, right_fall_tile.y - cell.y <= jump_cell_count)


## 添加寻路的点。返回添加的这个寻路点的 ID 值
##[br]
##[br]- [param cell]  瓦片的坐标
##[br]- [param weight_scale]  这个点的权重
##[br]- [param offset]  实际位置的偏移向量
func add_point(cell: Vector2i, weight_scale: float = 1.0, offset := Vector2(0,0)) -> int:
	var pos : Vector2 = Vector2(cell * map.tile_set.tile_size) + offset
	var id : int = graph.get_closest_point(pos)
	if id > -1 and graph.get_point_position(id) == pos: # 如果找到且位置相同，则不添加
		# 重复则退出
		return id
	id = graph.get_available_point_id()
	graph.add_point(id, pos, weight_scale)
	var p_cell : Vector2i = map.local_to_map(pos)
	cell_to_graph_id_dict[p_cell] = id
	return id


## 连接两个点
func add_connect_point(from_point: int, to_point: int, bidirectional: bool = true):
	graph.connect_points(from_point, to_point, bidirectional)
	connect_point_ids_dict.get_or_add(from_point, []).append(to_point)


## 寻找落脚点
func find_floor_cell(cell: Vector2i) -> Vector2i:
	cell += Vector2i.DOWN
	while is_empty(cell) or is_custom_edge_tile(cell):
		cell += Vector2i.DOWN
		if not map_rect.has_point(cell):
			return cell
	return cell + Vector2i.UP
