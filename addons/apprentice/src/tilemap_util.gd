#============================================================
#    Tilemap Util
#============================================================
# - datetime: 2023-02-14 19:48:46
#============================================================
## TileMapLayer 工具类
##
##一些处理 TileMapLayer 数据的功能
class_name TileMapUtil

# tile 和 cell 的区别
# - tile（瓦片）：方法名或变量名带有 “tile” 的可以认为是瓦片的 ID 的值的数据
# - cell（单元格）：获取瓦片的所在行和列的坐标位置。是 Vector2i 类型的数据


##  单元格是连通的。中间过程没有存在其他的单元格
##[br]
##[br][code]tilemap[/code]  TileMapLayer 对象
##[br][code]from[/code]  开始的坐标
##[br][code]to[/code]  到达的坐标
##[br][code][/code]  所在的层
static func cell_is_connected(tilemap: TileMapLayer, from: Vector2, to: Vector2) -> bool:
	if from == to:
		return true
	
	var start = Vector2(from)
	var end = Vector2(to)
	var direction = start.direction_to(end)
	for step in floor(start.distance_to(end) - 1.0):
		start += direction
		var id = tilemap.get_cell_source_id(Vector2i(start))
		if id != -1:
			return false
	return true


##  获取这组点列表可以互相连接的点，两个点之间没有其他瓦片
##[br]
##[br][code]tilemap[/code]  tilemap对象
##[br][code]points[/code]  点列表
##[br][code][/code]  所在的层
##[br]
##[br]返回以下结构的数据列表
##[codeblock]
##{
##    "from": Vector2, 
##    "to": Vector2,
##}
##[/codeblock] 
static func get_connected_cell(tilemap: TileMapLayer, points: Array) -> Array[Dictionary]:
	if points.size() < 2:
		return []
	var list : Array[Dictionary]= []
	for i in points.size() - 1:
		for j in range(i + 1, points.size()):
			if cell_is_connected(tilemap, points[i], points[j]):
				list.append({
					"from": points[i],
					"to": points[j],
				})
	
	for idx in range(list.size() - 1, -1, -1):
		var data := Dictionary(list[idx])
		if (data['from'] == data['to']):
			list.remove_at(idx)
	
	return list


## 获取两边没有瓦片的单元格
static func get_between_no_tile_cell(tilemap: TileMapLayer, coordinate: Vector2i, max_height: int = 1, max_width: int = 1) -> Array[Vector2i]:
	var id = tilemap.get_cell_source_id(coordinate)
	var no_tiles : Array[Vector2i] = []
	if id != -1:
		for width in max_width:
			var left : Vector2i = coordinate + Vector2i(-width, 0)
			var right : Vector2i = coordinate + Vector2i(width, 0)
			for i in (max_height + 1):
				left -= Vector2i(0, i)
				if tilemap.get_cell_source_id(left) > -1:
					no_tiles.append(left)
				right -= Vector2i(0, i)
				if tilemap.get_cell_source_id(right) > -1:
					no_tiles.append(right)
	return no_tiles


## 获取这个坐标点两边的立足点。会返回两个项的数组，第一个为左边的点，第二个为右边的点，若为 null，则代表没有
static func get_foothold_cell(tilemap: TileMapLayer, coordinate: Vector2i) -> Array:
	var used_rect = tilemap.get_used_rect()
	var left : Vector2i
	var right : Vector2i
	var coord : Array = [null, null]
	
	# 左。中上不能有其他瓦片
	if (tilemap.get_cell_source_id(coordinate + Vector2i(-1, -1)) == -1
		and tilemap.get_cell_source_id(coordinate + Vector2i(-1, 0)) == -1
	):
		for i in (used_rect.end.y - coordinate.y):
			left = coordinate + Vector2i(-1, i)
			if tilemap.get_cell_source_id(left) != -1:
				coord[0] = left
				break
		
	# 右。中上不能有其他瓦片
	if (tilemap.get_cell_source_id(coordinate + Vector2i(1, -1)) == -1
		and tilemap.get_cell_source_id(coordinate + Vector2i(1, 0)) == -1
	):
		for i in (used_rect.end.y - coordinate.y):
			right = coordinate + Vector2i(1, i)
			if tilemap.get_cell_source_id(right) != -1:
				coord[1] = right
				break
	
	return coord


## 获取可接触到的单元格点
static func get_touchable_coordinates(tilemap: TileMapLayer, coordinate: Vector2i, touchable_height: int, touchable_width: int) -> Array:
	var list : Array = [null, null]
	
	# 头顶不能有碰撞的单元格
	for i in range(1, touchable_height + 1):
		if tilemap.get_cell_source_id(coordinate + Vector2i(0, -i)) != -1:
			return list
		
	# 从中心向两边扩散，那一边的某列有，那这边是这个单元格可接触
	var left : Vector2i
	var right : Vector2i
	for y in range(1, touchable_height + 1):
		for x in range(1, touchable_width + 1):
			if list[0] == null:
				left = coordinate + Vector2i(-x, -y)
				if (tilemap.get_cell_source_id(left) > -1
					and tilemap.get_cell_source_id(left + Vector2i.UP) == -1
				):
					list[0] = left
			
			if list[1] == null:
				right = coordinate + Vector2i(x, -y)
				if (tilemap.get_cell_source_id(right) > -1
					and tilemap.get_cell_source_id(right + Vector2i.UP) == -1
				):
					list[1] = right
			
			if list[0] != null and list[1] != null:
				break
		
		if list[0] != null and list[1] != null:
			break
	
	return list


## 瓦片替换为节点
static func replace_tile_as_node_by_scene(tilemap: TileMapLayer,  coordinate: Vector2i, scene: PackedScene) -> Node:
	tilemap.set_cell(coordinate, -1, Vector2(0, 0))
	
	# 替换场景节点
	var node = scene.instantiate()
#	node.z_index = -10
	tilemap.add_child(node)
	node.global_position = tilemap.global_position + Vector2(tilemap.tile_set.tile_size * coordinate) 
	return node


## 获取是个地板的单元格
##[br]
##[br][code]tilemap[/code]  数据来源 TileMapLayer
##[br][code][/code]  所在层
##[br][code]ids[/code]  这个单元格的 ID
##[br][code]atlas_coords[/code]  这个单元格图片的坐标
##[br][code]return[/code]  返回符合条件的单元格
static func get_ground_cells(
	tilemap: TileMapLayer, 
	ids: Array[int] = [], 
	atlas_coords: Array[Vector2i] = []
) -> Array[Vector2i]:
	var list : Array[Vector2i] = []
	if ids.is_empty() and atlas_coords.is_empty():
		return tilemap.get_used_cells()
	
	for coordinate in tilemap.get_used_cells():
		if ((ids.is_empty() or tilemap.get_cell_source_id(coordinate) in ids)
			and (atlas_coords.is_empty() or tilemap.get_cell_atlas_coords(coordinate) in atlas_coords)
		):
			if tilemap.get_cell_source_id(coordinate + Vector2i.UP) == -1:
				list.append(coordinate)
	return list


## 获取 TileMapLayer 的中心位置
static func get_global_center(tilemap: TileMapLayer) -> Vector2:
	return tilemap.global_position + Vector2(tilemap.get_used_rect().size / 2 * tilemap.tile_set.tile_size)


## 是否存在这个 ID
static func is_exists_id(tilemap: TileMapLayer, idx: int) -> bool:
	return tilemap.tile_set != null and tilemap.tile_set.get_source(idx) != null


## 添加贴图
##[br]
##[br][code]tilemap[/code]  添加到的 [TileMapLayer]
##[br][code]texture[/code]  添加的图片
##[br][code]atlas_source_id_override[/code]  要覆盖掉的之前的ID。如果为 [code]-1[/code]，则为新增
static func add_texture(
	tilemap: TileMapLayer, 
	texture: Texture2D, 
	atlas_source_id_override: int = -1
) -> void:
	var tile_set : TileSet
	if tilemap.tile_set == null:
		tilemap.tile_set = TileSet.new()
	tile_set = tilemap.tile_set
	
	# 添加 Texture
	var source : TileSetAtlasSource
	if tile_set.has_source(atlas_source_id_override):
		source = tile_set.get_source(atlas_source_id_override)
		source.texture = texture
	else:
		source = TileSetAtlasSource.new()
		source.texture = texture
		source.create_tile(Vector2i())
		tile_set.add_source(source, atlas_source_id_override)

## 这块区域是否有瓦片
static func has_cell_data_by_rect(tilemap: TileMapLayer, rect: Rect2i) -> bool:
	for y in range(rect.position.y, rect.end.y + 1):
		for x in range(rect.position.x, rect.end.x + 1):
			if tilemap.get_cell_source_id(Vector2i(x, y)) != -1:
				return true
	return false


##  获取这片区域的瓦片数据列表
##[br]
##[br][code]tilemap[/code]  地图
##[br][code]rect[/code]  获取区域的区域
##[br][code][/code]  所在层
##[br][code]use_proxies[/code]  如果 [code]use_proxies[/code] 为 [code]false[/code]，
##则忽略 [TileSet]的 tile 代理。请参见 [method TileSet.map_tile_proxy]
##[br][code]return[/code] 返回的数据结构类似如下结构：
##[codeblock]
##{
##    "coord": Vector2i(),
##    "source_id": 0,
##    "alternative_tile": -1,
##    "atlas_coords": Vector2i(),
##}
##[/codeblock]
static func get_cell_data_by_rect(
	tilemap: TileMapLayer, 
	rect: Rect2i, 
) -> Array[CellItemData]:
	var list : Array[CellItemData] = []
	FuncUtil.for_rect(rect, func(coordinate: Vector2i):
		if tilemap.get_cell_source_id(coordinate) != -1:
			list.append_array(get_cell_data(tilemap, coordinate))
	)
	return list


## 这个单元格的数据
class CellItemData:
	var coord : Vector2i
	var source_id : int
	var atlas_coords : Vector2i
	var alternative_tile : int
	
	func _init(data: Dictionary = {}):
		if not data.is_empty():
			JsonUtil.set_property_by_dict(data, self)
	
	func _to_string():
		return JsonUtil.object_to_json(self, "    ")


##  获取这个坐标的单元格的所有数据
##[br]
##[br][code]tilemap[/code]  获取的 tilemap
##[br][code]coordinate[/code]  所在单元格的坐标
##[br][code]use_proxies[/code]  获取代理的数据
static func get_cell_data(
	tilemap: TileMapLayer, 
	coordinate: Vector2i, 
) -> Array[CellItemData]:
	var list : Array[CellItemData] = []
	var item : CellItemData = CellItemData.new()
	item.coord = coordinate
	item.source_id = tilemap.get_cell_source_id(coordinate)
	item.atlas_coords = tilemap.get_cell_atlas_coords(coordinate)
	item.alternative_tile = tilemap.get_cell_alternative_tile(coordinate)
	list.append(item)
	return list


## 设置单元格的数据
##[br]
##[br][code]tilemap[/code]  要设置的 [TileMapLayer]
##[br][code]data[/code]  设置的数据。所需的数据结构为 [method set_cell_data] 方法中的结构
static func set_cell_data(tilemap: TileMapLayer, data: Dictionary) -> void:
	set_cell(
		tilemap, 
		data.get("coord", Vector2i.ZERO),
		data.get("source_id", 0),
		data.get("atlas_coords", Vector2i.ZERO),
	)

## 设置这个单元格位置的数据
static func set_cell(
	tilemap: TileMapLayer,
	coord: Vector2i, 
	source_id: int = 0, 
	atlas_coords: Vector2i = Vector2i.ZERO, 
	alternative_tile: int = 0,
) -> void:
	tilemap.set_cell(coord, source_id, atlas_coords, alternative_tile)

static func set_cell_by_points(
	tilemap: TileMapLayer,
	coords_list, 
	source_id: int = 0, 
	atlas_coords: Vector2i = Vector2i.ZERO, 
	alternative_tile: int = 0,
) -> void:
	for coord in coords_list:
		tilemap.set_cell(coord, source_id, atlas_coords, alternative_tile)


## 擦除这个单元格
static func clear_cell(tilemap: TileMapLayer, coord: Vector2i) -> void:
	tilemap.set_cell(coord, -1, Vector2i(-1, -1))

## 擦除这个单元格
static func clear_cell_by_points(tilemap: TileMapLayer, coords_list) -> void:
	for point in coords_list:
		tilemap.set_cell(Vector2i(point), -1, Vector2i(-1, -1))


##  复制 cell 数据到 TileMapLayer 上
##[br]
##[br][code]from_tilemap[/code]  从这个 [TileMapLayer] 中获取数据
##[br][code]from_rect[/code]  获取这个区域的范围的数据
##[br][code]to_tilemap[/code]  复制到这个 [TileMapLayer] 上
##[br][code]to_rect[/code]  复制到这个区域范围内。如果为 Rect2i(0,0,0,0) 则为 from_rect 参数的值
##[br][code]cell_filter[/code]  过滤数据方法。这个参数需要有一个 [Dictionary] 
##类型的参数接受这个单元格上数据，并返回一个 [bool] 类型的值返回是否需要这个数据，如果返回 
##[code]true[/code] 则添加，否则不添加
static func copy_cell_to(
	from_tilemap: TileMapLayer, 
	from_rect: Rect2i, 
	to_tilemap: TileMapLayer, 
	to_rect: Rect2i = Rect2i(), 
	cell_filter: Callable = Callable()
) -> void:
	assert(from_rect.size != Vector2i.ZERO, "from_rect 参数值的大小必须要超过 0！")
	if to_rect == Rect2i():
		to_rect = from_rect
	
	# 获取数据
	var dict : Dictionary = {}
	if cell_filter.is_valid():
		FuncUtil.for_rect(from_rect, func(from_coords: Vector2i):
			var list : Array[CellItemData] = []
			for data in get_cell_data(from_tilemap, from_coords):
				if cell_filter.call(data):
					list.append(data)
			if not list.is_empty():
				dict[from_coords] = list
		)
	else:
		FuncUtil.for_rect(from_rect, func(from_coords: Vector2i):
			dict[from_coords] = get_cell_data(from_tilemap, from_coords)
		)
	
	# 复制到另一个 TileMapLayer 上
	var offset : Vector2i = from_rect.position - to_rect.position
	FuncUtil.for_rect(to_rect, func(to_coords: Vector2i):
		var from_coords : Vector2i = to_coords + offset
		if dict.has(from_coords):
			var list : Array[CellItemData] = dict[from_coords]
			for data in list:
				var cell_coord : Vector2i = data.coord - offset
				to_tilemap.set_cell(cell_coord, data.source_id, data.atlas_coords)
		else:
			printerr("没有这个位置：", from_coords)
	)


##  复制所有 Cell 到另一个 [TileMapLayer] 上
##[br]
##[br][code]from[/code]  从这个 [TileMapLayer] 上复制数据
##[br][code]to[/code]  设置到这个 [TileMapLayer] 上
##[br][code]offset_coord[/code]  偏移的坐标位置
static func copy_all_cell_to(from: TileMapLayer, to: TileMapLayer, offset_coord: Vector2i = Vector2i.ZERO):
	for coord in from.get_used_cells():
		to.set_cell(coord + offset_coord, 
			from.get_cell_source_id(coord), 
			from.get_cell_atlas_coords(coord), 
			from.get_cell_alternative_tile(coord), 
		)


static func has_cell_data(tilemap: TileMapLayer, coord) -> bool:
	return tilemap.get_cell_source_id(coord) != -1


## 获取两点之间的连接线
static func get_connect_line_points(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	#var points = Geometry2D.bresenham_line(start, end) #效果不如下面的好
	#return Array(points, TYPE_VECTOR2I, "", null)
	var tiles : Array[Vector2i] = []
	
	var x0 = start.x
	var y0 = start.y
	var x1 = end.x
	var y1 = end.y

	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy

	while true:
		# 添加当前瓦片坐标
		tiles.append(Vector2i(x0, y0))
		
		# 到达终点就退出
		if x0 == x1 && y0 == y1:
			break
			
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return tiles

# 预简化：剔除同一直线上的连续冗余瓦片
static func pre_simplify_tile_path(tiles: Array) -> Array[Vector2i]:
	if tiles.size() <= 2:
		return tiles.duplicate()
	var simplified : Array[Vector2i] = [tiles[0]]
	for i in range(1, tiles.size()-1):
		var dir_prev = tiles[i] - tiles[i-1]
		var dir_next = tiles[i+1] - tiles[i]
		if dir_prev != dir_next:  # 方向变了，保留拐点
			simplified.append(tiles[i])
	simplified.append(tiles[-1])
	return simplified


## 路径平滑。- [param tolerance] 平滑度，值越大平滑度越高
static func simplify_path(path: Array, tolerance: float) -> Array:
	if path.size() <= 2: return path
	var max_dist = 0.0
	var max_idx = 0
	var start = path[0]
	var end = path[path.size()-1]
	for i in range(1, path.size()-1):
		var dist = _point_to_line_distance(path[i], start, end)
		if dist > max_dist:
			max_dist = dist
			max_idx = i
	if max_dist > tolerance:
		var left = simplify_path(path.slice(0, max_idx+1), tolerance)
		var right = simplify_path(path.slice(max_idx, path.size()), tolerance)
		return left.slice(0, left.size()-1) + right
	else:
		return [start, end]

static func _point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	if line_vec.length_squared() == 0:
		return point.distance_to(line_start)
	var t = clamp(point_vec.dot(line_vec) / line_vec.length_squared(), 0.0, 1.0)
	var proj = line_start + line_vec * t
	return point.distance_to(proj)


## 检测是否有单元格
##[br]
##[br]这个深度的方向一行货列中没有其他瓦片数据时返回 [code]true[/code]，否则返回 [code]false[/code]
##[br]
##[br][code]tilemap[/code]  判断的 [TileMapLayer]
##[br][code]coord[/code]  从这个坐标开始
##[br][code]direction[/code]  这个方向为出口方向
##[br][code]depth[/code]  判断深度
static func ray_has_colliding_i(
	tilemap: TileMapLayer, 
	coord: Vector2i, 
	direction: Vector2i, 
	depth : int,
) -> bool:
	assert(depth > 0, "深度必须要超过0")
	var move_direction : Vector2i = direction * -1
	for i in depth:
		coord += move_direction
		if tilemap.get_cell_source_id(Vector2i(coord)) != -1:
			return false
	return true


## 如果其中没有存在障碍物则返回 -1
static func ray_has_colliding(
	tilemap: TileMapLayer, 
	from_coord: Vector2i, 
	direction: Vector2, 
	max_length: int,
) -> int:
	var length : int = 0
	var tmp_from : Vector2 = Vector2(from_coord) + direction.sign()
	var result : int = -1
	while (length < max_length - 1):
		result &= ( tilemap.get_cell_source_id(Vector2i(tmp_from)) | tilemap.get_cell_source_id(Vector2i(tmp_from.ceil())) )
		if result != -1:
			break
		tmp_from += direction
		# 存在有障碍物
		length += 1
	return result


## 射线射向目标位置
##[br]
##[br][code]coord[/code]  所在位置
##[br][code]direction[/code]  检测方向
##[br][code]length[/code]  长度
##[br][code]return[/code]  返回检测到的瓦片的坐标位置，如果没有检测到瓦片，则返回 [constant MathUtil.VECTOR2I_MAX]
static func ray_to(
	tilemap: TileMapLayer,
	from_coord: Vector2i,
	direction: Vector2,
	length: float = INF,
) -> Array[Vector2i]:
	var rect : Rect2i = tilemap.get_used_rect()
	var tmp_coord := Vector2(from_coord)
	var tmp_coord_i_floor := Vector2i(from_coord)
	var tmp_coord_i_ceil := Vector2i(from_coord)
	var list : Array[Vector2i] = [from_coord]
	var step = Vector2()
	while step.length() < length:
		tmp_coord += direction
		step += direction
		tmp_coord_i_floor = Vector2i(tmp_coord.floor())
		list.append(tmp_coord_i_floor)
		tmp_coord_i_ceil = Vector2i(tmp_coord.ceil())
		if tmp_coord_i_floor != tmp_coord_i_ceil:
			list.append(tmp_coord_i_ceil)
		if has_cell_data(tilemap, tmp_coord_i_floor) and has_cell_data(tilemap, tmp_coord_i_ceil):
			break
	return list


## 返回给定参数的所有元格的位置
static func get_used_cells(
	tilemap: TileMapLayer, 
	source_ids: Array[int], 
	atlas_coords_list: Array[Vector2i],
) -> Array[Vector2i]:
	var data = {}
	for source_id in source_ids: 
		for atlas_coords in atlas_coords_list:
			for cell in tilemap.get_used_cells_by_id(source_id, atlas_coords):
				data[cell] = []
	return Array(data.keys(), TYPE_VECTOR2I, "", null)


## 获取整个地图实际矩形像素大小
static func get_rect(tilemap: TileMapLayer) -> Rect2:
	var rect = tilemap.get_used_rect()
	rect.position *= tilemap.tile_set.tile_size
	rect.size *= tilemap.tile_set.tile_size
	rect.position += Vector2i(tilemap.global_position)
	return rect


## 获取全部外侧瓦片坐标列表
static func get_all_edge_coords_list(tile_map: TileMapLayer) -> Array[Vector2i]:
	var coords_list : Array[Vector2i] = []
	var visited : Dictionary = {}
	var rect = tile_map.get_used_rect().grow(1)
	var tmp_coord
	var last_coords_list = [rect.position] # 从左上角第一个位置开始
	while not last_coords_list.is_empty():
		var next_coords_list = []
		for coord in last_coords_list:
			for direction in MathUtil.get_four_directions_i():
				tmp_coord = coord + direction # 移动到的位置
				if not visited.has(tmp_coord) and rect.has_point(tmp_coord):
					# 判断移动到的位置(tmp_coord)是否是墙
					if tile_map.get_cell_source_id(tmp_coord) == -1:
						next_coords_list.append(tmp_coord)
					else:
						coords_list.append(tmp_coord)
					visited[tmp_coord] = null
		last_coords_list = next_coords_list
		next_coords_list = []
	return coords_list


## 获取全部外侧空白瓦片坐标列表
static func get_all_edge_empty_coords_list(
	tile_map: TileMapLayer, 
	grow: int = 1, # 向外扩展大小
) -> Array:
	var coords_list = []
	var visited = {}
	var rect = tile_map.get_used_rect().grow(grow)
	var tmp_coord
	var last_coords_list = [rect.position] # 从左上角第一个位置开始
	while not last_coords_list.is_empty():
		var next_coords_list = []
		for coord in last_coords_list:
			for direction in MathUtil.get_four_directions_i():
				tmp_coord = coord + direction # 移动到的位置
				if not visited.has(tmp_coord) and rect.has_point(tmp_coord):
					# 判断移动到的位置(tmp_coord)是否是墙
					if tile_map.get_cell_source_id(tmp_coord) == -1:
						next_coords_list.append(tmp_coord)
						coords_list.append(tmp_coord)
					visited[tmp_coord] = null
		last_coords_list = next_coords_list
		next_coords_list = []
	return coords_list


## 获取边界的瓦片坐标列表。
static func get_border_coords_list(
	points: Array, 
	directions: Array = MathUtil.get_eight_directions_i(),
) -> Array:
	# 不存在的点的位置
	var p_set : HashSet = HashSet.new(points)
	var start_p = p_set.pick_random()
	if start_p is Vector2:
		if not directions[0] is Vector2:
			directions = directions.map(func(v): return Vector2(v))
	else:
		if not directions[0] is Vector2i:
			directions = directions.map(func(v): return Vector2i(v))
	while true:
		start_p += directions[0]
		if not p_set.has(start_p):
			start_p -= directions[0]
			break
	
	var ps : Array = []
	FuncUtil.path_move(
		start_p, directions,
		func(point) -> bool:
			if p_set.has(point):
				for dir in directions:
					if not p_set.has(point + dir):
						# 周围有的地方不存在瓦片，则这个瓦片视为边缘瓦片
						ps.append(point)
						return true
			return false
	)
	return ps


static func tiles_to_outline_polygon(tiles: Array, distance_epsilon: float = 0.0) -> PackedVector2Array:
	# O(1) 查表
	var set = {}
	for t in tiles:
		set[Vector2i(t)] = true
	
	# 收集暴露的边，用字典存邻接关系
	# key: 顶点坐标 Vector2, value: 邻居顶点 Array[Vector2]
	var adj = {}
	
	for t in tiles:
		var x = t.x
		var y = t.y
		
		# 左边暴露
		if not set.has(Vector2i(x - 1, y)):
			_add_edge(adj, Vector2(x, y), Vector2(x, y + 1))
		# 右边暴露
		if not set.has(Vector2i(x + 1, y)):
			_add_edge(adj, Vector2(x + 1, y), Vector2(x + 1, y + 1))
		# 下边暴露
		if not set.has(Vector2i(x, y - 1)):
			_add_edge(adj, Vector2(x, y), Vector2(x + 1, y))
		# 上边暴露
		if not set.has(Vector2i(x, y + 1)):
			_add_edge(adj, Vector2(x, y + 1), Vector2(x + 1, y + 1))
	
	if adj.is_empty():
		return PackedVector2Array()
	
	# 找起点：最左下的顶点
	var start = adj.keys()[0]
	for p in adj:
		if p.x < start.x or (p.x == start.x and p.y < start.y):
			start = p
	
	# 沿着边走路，拼出多边形
	# 有 L 形拐角（>2条边相交）时，按角度选最右边那条，保证走外圈
	var result = PackedVector2Array()
	var cur = start
	var prev = start  # 上一步的顶点
	
	while true:
		result.append(cur)
		
		var neighbors = adj[cur]
		if neighbors.is_empty():
			break
		
		# 选下一个顶点：排除"回头"，如果有歧义选最"右转"的方向
		var best = null
		var best_dot = -999.0  # 角度比较
		
		for n in neighbors:
			if n == prev and neighbors.size() > 1:
				continue  # 不回头，除非只剩这一条路
			
			if prev == cur:
				# 第一步：随便选第一个
				best = n
				break
			
			# 计算方向，选最右转的
			var dir_in = (cur - prev).normalized()
			var dir_out = (n - cur).normalized()
			var cross_val = dir_in.x * dir_out.y - dir_in.y * dir_out.x
			var dot_val = dir_in.dot(dir_out)
			
			if cross_val > 0:
				dot_val += 2.0  # 左转加分
			elif cross_val < 0:
				dot_val -= 2.0  # 右转减分（更优）
			
			if best == null or dot_val < best_dot:
				best = n
				best_dot = dot_val
		
		if best == null:
			break
		
		prev = cur
		cur = best
		
		if cur == start:
			break  # 走回起点，闭合
	
	if distance_epsilon == 0.0:
		return result
	return NavigationServer2D.simplify_path(result, distance_epsilon)


static func _add_edge(adj: Dictionary, a: Vector2, b: Vector2):
	if not adj.has(a):
		adj[a] = []
	if not adj.has(b):
		adj[b] = []
	adj[a].append(b)
	adj[b].append(a)


## 获取内部的坐标列表
static func get_inside_coords_list(
	border_coords_dict: Dictionary,  # 边缘坐标点，根据 [method get_border_coords_list] 进行获取
	directions: PackedVector2Array = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN],
	condition: Callable = Callable(), #是否符合继续向下走的条件。这个方法需要有一个 [Vector2] 参数
) -> Array:
	var min_v : Vector2 = border_coords_dict.keys()[0]
	var start : Vector2 = min_v + Vector2(1, 1)
	var result = {start: null}
	if condition.is_valid():
		FuncUtil.path_move(
			start, directions,
			func(v): return not border_coords_dict.has(v) and condition.call(v),
			func(points): DataUtil.merge(result, points)
		)
	else:
		FuncUtil.path_move(
			start, directions,
			func(v): return not border_coords_dict.has(v),
			func(points): DataUtil.merge(result, points)
		)
	
	return result.keys()


## 地图边缘转为多边形点，这个点都是单元格坐标点
static func tile_map_to_polygon(tilemap: TileMapLayer) -> Array[Vector2i]:
	# 获取边缘点
	var points : Array = get_all_edge_coords_list(tilemap)
	# 点排序
	return __tile_map_to_polygon_sort_points(points)

static func __tile_map_to_polygon_sort_points(list: Array) -> Array[Vector2i]:
	var curr : Vector2i = Vector2i(list[0])
	var visited = {}
	visited[curr] = null
	var cells : Array[Vector2i] = [curr]
	var tmp
	var moved = false
	while true:
		moved = false
		for dir in [
			Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN,
			Vector2i(-1, -1), Vector2i(-1, 1),
			Vector2i(1, 1), Vector2i(1, -1),
		]:
			tmp = curr + dir
			if not visited.has(tmp) and list.has(tmp):
				cells.append(tmp)
				curr = tmp
				visited[tmp] = null
				moved = true
				break
		if not moved:
			break
	return cells

 
## 对 [Ti了MapLayer] 进行划分区块，互相连接的单元格划分为一组点
static func adjacent_groups(
	tilemap_layer:TileMapLayer, 
	directions: PackedVector2Array = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN],
) -> Array[Array]:
	var map_rect : Rect2i = tilemap_layer.get_used_rect().grow(1)
	
	# 所有空白位置
	var empty_visited : Dictionary = {}
	FuncUtil.path_move(
		map_rect.position, 
		directions,
		func(next_point): 
			return (map_rect.has_point(Vector2i(next_point)) 
			and tilemap_layer.get_cell_source_id(next_point) == -1
		),
		func(next_points):
			DataUtil.merge(empty_visited, next_points)
	)
	
	# 所有区分出来的整块区域
	var groups : Array[Array] = []
	FuncUtil.for_rect(
		map_rect.grow(-1),
		func(v):
			if not empty_visited.has(v):
				var list : Array = []
				list.append(v)
				empty_visited[v] = null
				FuncUtil.path_move(
					v, 
					directions,
					func(next): 
						return not empty_visited.has(next) and map_rect.has_point(next),
					func(next_points):
						list.append_array(next_points)
						DataUtil.merge(empty_visited, next_points)
				)
				groups.append(list)
	)
	return groups


## 是否为拐角点
static func is_cornet_coords(point: Vector2, map_coords_dict:Dictionary) -> bool:
	return (
		not (map_coords_dict.has(point + Vector2.UP) and map_coords_dict.has(point + Vector2.DOWN) ) 
		and not (map_coords_dict.has(point + Vector2.LEFT) and map_coords_dict.has(point + Vector2.RIGHT) ) 
	)


## 获取拐角坐标点
static func get_corner_coords_list(point_dict: Dictionary) -> Array:
	var map = {}
	for point in point_dict:
		if is_cornet_coords(point, point_dict):
			map[point] = null
	return map.keys()


## 获取区域路径内所有空白的点
static func get_all_empty_cells(
	tilemap_layer:TileMapLayer, 
	start_point: Vector2i,
	directions: PackedVector2Array = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN],
	map_rect: Rect2i = Rect2i()
) -> Array:
	var dict = {}
	if map_rect == Rect2i():
		map_rect = tilemap_layer.get_used_rect().grow(1)
	var random_cell = start_point
	FuncUtil.path_move(random_cell, MathUtil.get_four_directions(), 
		func(next_point):
			return (tilemap_layer.get_cell_source_id(next_point) == -1
				or tilemap_layer.get_cell_atlas_coords(next_point) != Vector2i(0,0)
			) and map_rect.has_point(Vector2i(next_point))
			,
		func(next_points):
			for point in next_points:
				dict[Vector2i(point)] = null
	)
	# 去掉最外层的一圈
	FuncUtil.for_rect_around(map_rect, dict.erase)
	return dict.keys()


## 点排序
static func sort_border_points(border_points: Array, dirs: Array = [], start_point = null, depth_search: bool = true) -> Array:
	if border_points.is_empty():
		return []
	if dirs.is_empty():
		dirs = [
			Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, 
			Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1),  
		]
	if border_points[0] is Vector2:
		dirs = dirs.map(func(v): return Vector2(v))
	else:
		dirs = dirs.map(func(v): return Vector2i(v))
	
	var origin_point_set := HashSet.new(border_points)
	if start_point == null:
		var around_point_count : int = 0 
		for point in border_points:
			around_point_count = 0
			for dir in dirs:
				if origin_point_set.has(point + dir):
					around_point_count += 1
			if around_point_count == 1:
				start_point = point
				break
		start_point = border_points[0]
	
	# 找到路径上的点
	var visited := HashSet.new()
	var current_point = start_point
	var points_stack : Array = [current_point]
	var has_point: bool = false
	var all_point_set := HashSet.new()
	all_point_set.append(current_point)
	var last_points : Array 
	var tmp_point
	for __ in 2:
		last_points = []
		while true:
			has_point = false
			visited.append(current_point)
			for dir in dirs:
				tmp_point = current_point + dir
				if not visited.has(tmp_point):
					if origin_point_set.has(tmp_point):
						current_point = tmp_point
						points_stack.append(current_point)
						has_point = true
						break # 结束当前位置点的判断
			if not has_point:
				# 当前这个点到末尾了时
				if last_points.size() < points_stack.size():
					last_points = points_stack.duplicate()
					all_point_set.append_array(points_stack)
				if points_stack.size() > 0:
					current_point = points_stack.pop_back()
				else:
					break
		points_stack = []
		if last_points:
			current_point = last_points[-1]
	
	if depth_search:
		var around_point_count : int = 0 
		for point in all_point_set.get_data():
			around_point_count = 0
			for dir in dirs:
				if origin_point_set.has(point + dir):
					around_point_count += 1
			if around_point_count == 1:
				start_point = point
				break
		return sort_border_points(border_points, dirs, start_point, false)
	else:
		return all_point_set.to_array()


## 选取位置中间的瓦片（最快，99% 概率不会选到区域外的点）
static func get_fast_center_point(tile_coords: Array) -> Vector2i:
	if tile_coords.is_empty(): return Vector2i.ZERO
	
	# 提取所有X和Y并排序
	var x_coords := tile_coords.map(func(c): return c.x)
	x_coords.sort()
	var y_coords := tile_coords.map(func(c): return c.y)
	y_coords.sort()
	
	# 取中位数
	var mid := tile_coords.size() / 2
	return Vector2i(x_coords[mid], y_coords[mid])


## 选取离中间位置最近的瓦片（最稳）
static func get_center_point(tile_coords: Array) -> Vector2i:
	if tile_coords.is_empty(): 
		return Vector2i.ZERO
	var best_coord = tile_coords[0]
	var min_total_dist := INF
	for coord in tile_coords:
		var total_dist := 0.0
		# 用平方距离（避免开根号，更快）
		for other in tile_coords: 
			total_dist += coord.distance_squared_to(other)
		if total_dist < min_total_dist:
			min_total_dist = total_dist
			best_coord = coord
	return best_coord

## 几何质心。凹凸多边形都准
static func get_centroid_point(points: PackedVector2Array) -> Vector2:
	var centroid = Vector2.ZERO
	var area = 0.0
	var n = points.size()
	for i in range(n):
		var p1 = points[i]
		var p2 = points[(i + 1) % n]
		var cross = p1.cross(p2)
		area += cross
		centroid += (p1 + p2) * cross
	area *= 0.5
	return centroid / (6.0 * area) if area != 0.0 else Vector2.ZERO


## 膨胀/收缩轮廓点。传入的需要是这一整组所有内部的点，而不是只有轮廓。如果传入的是一组边缘的点，则使用 [method Geometry2D.offset_polygon] 方法
##[br]
##[br]- [param input_points]: 单个颜色区域的所有通行瓦片坐标
##[br]- [param operation_level]: 收缩/膨胀幅度。超过 0 则为膨胀，小于 0 则为收缩
##[br]- [param connect_type]: 连通类型 4=4方向 8=8方向（默认8）
##[br]返回值：[code]Array[Array][/code]，每个元素是一个独立巡逻块的闭合路线
static func offset_contour(
	input_points: Array,
	operation_level: int = 1, 
	connect_type: int = 8,
	solid: bool = false
) -> Array[Array]:
	if input_points.is_empty():
		return []
	
	if operation_level == 0:
		return [
			get_border_coords_list(input_points, [
				Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
				Vector2i.LEFT + Vector2i.UP, Vector2i.RIGHT + Vector2i.UP,
				Vector2i.LEFT + Vector2i.DOWN, Vector2i.RIGHT + Vector2i.DOWN
			])
		]
	
	# 步骤1：对整个区域统一收缩（核心！） 
	# 先把整个大区域收缩，狭窄通道会被直接缩没，原本连通的区域会分裂成多个独立块
	var point_set : Dictionary = {}
	for p:Vector2i in input_points:
		point_set[p] = null
	
	var result : Dictionary
	if operation_level < 0:
		result = shrink_contour(point_set, abs(operation_level), [], solid)
	elif operation_level > 0:
		result = expand_contour(point_set, operation_level, [], solid)
	
	if result.is_empty():
		return []
	
	# 把收缩后的字典转成坐标数组
	var points = result.keys()

	# 步骤2：分割收缩后的多个独立连通块 
	# 收缩后分裂的多个块，在这里被拆分出来，每个块都是一个独立的巡逻区
	var patrol_blocks = split_connected_blocks(points, connect_type)
	if not solid:
		if operation_level < 0:
			var all_routes : Array[Array] = []

			# 步骤3：每个独立块单独生成闭合巡逻路线 
			for block in patrol_blocks:
				# 过滤掉太小的块（小于4个点无法生成有效闭合路线，避免无效绘制）
				if block.size() < 4:
					continue
				# 给当前块生成边缘闭合路线（不再重复收缩）
				var route = get_edge_loop_route_for_single_block(block)
				if route.size() >= 3: # 只有路线长度足够，才加入结果
					all_routes.append(route)
			
			return all_routes
	
	return patrol_blocks


# 收缩轮廓函数，对这些点向内收缩
static func _shrink_contour(point_set: Dictionary, dirs: Array = [
		Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
		Vector2i.LEFT + Vector2i.UP, Vector2i.RIGHT + Vector2i.UP,
		Vector2i.LEFT + Vector2i.DOWN, Vector2i.RIGHT + Vector2i.DOWN
	]
) -> Dictionary:
	var new_set = {}
	
	for p in point_set:
		var is_inner = true
		for dir in dirs:
			if not point_set.has(p + dir):
				is_inner = false
				break
		if is_inner:
			new_set[p] = null
			
	return new_set


# 膨胀轮廓函数，对点集向外膨胀一圈
static func _expand_contour(point_set: Dictionary, exclude_point_set: Dictionary) -> Dictionary:
	var new_set = {}
	# 8个方向（和收缩函数完全一致，保证膨胀/收缩对称）
	var dirs = [
		Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
		Vector2i.LEFT + Vector2i.UP, Vector2i.RIGHT + Vector2i.UP,
		Vector2i.LEFT + Vector2i.DOWN, Vector2i.RIGHT + Vector2i.DOWN
	]
	
	# 遍历原始点集中的每一个点
	for p in point_set:
		# 遍历8个方向，把所有邻点都加入新集合
		for dir in dirs:
			var expanded_point = p + dir
			if not exclude_point_set.has(expanded_point):
				new_set[expanded_point] = true  # 字典自动去重，重复添加不影响
			
	return new_set

## 对一组不连续的点进行切分，将连续的点分组，点之间相连的分为一个组。[param connect_type] 为对一个点周围判定的方向数量
static func split_connected_blocks(input_points: Array, connect_type: int = 8, condition: Callable = Callable()) -> Array[Array]:
	var point_set := {}
	for p:Vector2i in input_points:
		point_set[p] = true
	
	var visited := {}
	var blocks : Array[Array] = []
	var dirs := _get_dirs(connect_type)

	# BFS遍历所有点，分割连通块
	for p:Vector2i in input_points:
		if not visited.has(p) and (not condition.is_valid() or condition.call(p)):
			var current_block := []
			var queue := [p]
			visited[p] = null
			
			while not queue.is_empty():
				var current:Vector2i = queue.pop_front()
				current_block.append(current)
				
				for dir:Vector2i in dirs:
					var next_p:Vector2i = current + dir
					if point_set.has(next_p) and not visited.has(next_p) and (not condition.is_valid() or condition.call(next_p)):
						visited[next_p] = true
						queue.append(next_p)
			blocks.append(current_block)
	
	return blocks


## 扩展点的范围，传入的点需要是填充的点
static func shrink_contour(point_set: Dictionary, length: int, dirs : Array = [], include_middle_points: bool = false) -> Dictionary:
	if dirs.is_empty():
		dirs = [
			Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
			Vector2i.LEFT + Vector2i.UP, Vector2i.RIGHT + Vector2i.UP,
			Vector2i.LEFT + Vector2i.DOWN, Vector2i.RIGHT + Vector2i.DOWN
		]
	
	var inner_points : Array = find_inner_points(point_set.keys())
	var inner_point_set : Dictionary = {}
	for p in inner_points:
		inner_point_set[p] = null
	
	# 找到边缘的点
	var border_point_set : Dictionary = {}
	for point in point_set:
		for dir in dirs:
			if not point_set.has(point + dir):
				border_point_set[point] = null
	
	if length <= 0:
		if include_middle_points:
			return point_set
		else:
			return border_point_set
	
	# 扩展边缘的点
	var last_point_set: Dictionary = border_point_set
	var visited_set : Dictionary = border_point_set.duplicate()
	for __ in length-1:
		var tmp_point
		var current_points: Dictionary = {}
		for point in last_point_set:
			# 找到这个点的周围所有的内部点
			for dir in dirs:
				tmp_point = point + dir
				if inner_point_set.has(tmp_point) and not visited_set.has(tmp_point):
					visited_set[tmp_point] = null
					current_points[tmp_point] = null
		last_point_set = current_points
		if current_points.is_empty():
			break
	
	if include_middle_points:
		var new_set : Dictionary = {}
		for point in point_set:
			if not visited_set.has(point):
				new_set[point] = null
		return new_set
	else:
		return last_point_set



## 扩展点的范围，传入的点需要是填充的点
static func expand_contour(point_set: Dictionary, length: int, dirs : Array = [], include_middle_points: bool = true) -> Dictionary:
	if dirs.is_empty():
		dirs = [
			Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
			Vector2i.LEFT + Vector2i.UP, Vector2i.RIGHT + Vector2i.UP,
			Vector2i.LEFT + Vector2i.DOWN, Vector2i.RIGHT + Vector2i.DOWN
		]
	
	var inner_points = find_inner_points(point_set.keys())
	var inner_point_set: Dictionary = {}
	for p in inner_points:
		inner_point_set[p] = null
	
	# 找到边缘的点
	var border_point_set : Dictionary = {}
	for point in point_set:
		for dir in dirs:
			if not point_set.has(point + dir):
				border_point_set[point] = null
	
	# 扩展边缘的点
	var last_point_set: Dictionary = border_point_set
	var new_set : Dictionary = point_set.duplicate()
	for __ in length:
		var tmp_point
		var current_points: Dictionary = {}
		for point in last_point_set:
			for dir in dirs:
				tmp_point = point + dir
				if not point_set.has(tmp_point) and not inner_point_set.has(tmp_point) and not new_set.has(tmp_point):
					new_set[tmp_point] = null
					current_points[tmp_point] = null
		last_point_set = current_points
	
	if include_middle_points:
		return new_set
	else:
		return last_point_set


# ==============================================
# 获取方向数组
# ==============================================
static func _get_dirs(connect_type: int) -> Array:
	var dirs_4 = [
		Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i.UP, Vector2i.DOWN
	]
	var dirs_8 = dirs_4 + [
		Vector2i.LEFT + Vector2i.UP,
		Vector2i.RIGHT + Vector2i.UP,
		Vector2i.LEFT + Vector2i.DOWN,
		Vector2i.RIGHT + Vector2i.DOWN
	]
	return dirs_8 if connect_type == 8 else dirs_4


# ==============================================
# 单块路线生成：仅给单个独立的、已收缩的块生成闭合边缘路线
# 移除了内部收缩逻辑，避免重复收缩；优化了寻路逻辑，确保闭合
# ==============================================
## 对点进行闭合路线
static func get_edge_loop_route_for_single_block(block_points: Array) -> Array:
	if block_points.size() < 3:
		return Array()

	# 构建当前块的点集
	var block_set = {}
	for p:Vector2i in block_points:
		block_set[p] = true

	# 提取当前块的所有边缘点
	var edge_points = {}
	for p:Vector2i in block_set:
		if _is_edge_point(p, block_set):
			edge_points[p] = true
	
	if edge_points.is_empty():
		return Array()

	# 找到起点（最左上的边缘点）
	var start_pos:Vector2i = _find_top_left_edge(edge_points)
	if start_pos == Vector2i(-1, -1):
		return Array()

	# 优化寻路：用BFS替代DFS，避免路线断裂，确保完整遍历边缘
	var route = Array()
	var visited = {}
	var queue = [start_pos]
	
	# 8方向遍历，优先相邻方向，保证路线连续
	var dirs = [
		Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP,
		Vector2i.RIGHT + Vector2i.DOWN, Vector2i.LEFT + Vector2i.DOWN,
		Vector2i.LEFT + Vector2i.UP, Vector2i.RIGHT + Vector2i.UP
	]

	while not queue.is_empty():
		var current:Vector2i = queue.pop_front()
		
		if visited.has(current):
			continue
		if not edge_points.has(current):
			continue
			
		visited[current] = true
		route.append(current)

		# 逆序遍历，保证路线顺时针连续
		for i in range(dirs.size() - 1, -1, -1):
			var dir:Vector2i = dirs[i]
			var next_p:Vector2i = current + dir
			if edge_points.has(next_p) and not visited.has(next_p):
				queue.append(next_p)

	# 强制闭合路线：如果终点和起点不重合，把起点加到末尾
	if route.size() > 0 and route[0] != route[route.size()-1]:
		route.append(route[0])

	return route

# ==============================================
# 边缘点判断函数
# ==============================================
static func _is_edge_point(p: Vector2i, point_set: Dictionary) -> bool:
	var dirs = [
		Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
		Vector2i.LEFT + Vector2i.UP, Vector2i.RIGHT + Vector2i.UP,
		Vector2i.LEFT + Vector2i.DOWN, Vector2i.RIGHT + Vector2i.DOWN
	]
	for dir in dirs:
		if not point_set.has(p + dir):
			return true
	return false


# ==============================================
# 找最左上起点函数
# ==============================================
static func _find_top_left_edge(edge_points: Dictionary) -> Vector2i:
	var min_x = INF
	var min_y = INF
	var start = Vector2i(-1, -1)
	for p:Vector2i in edge_points:
		if p.y < min_y or (p.y == min_y and p.x < min_x):
			min_y = p.y
			min_x = p.x
			start = p
	return start


## 均匀点采样（固定步长点采样）。采样完后的点是排好序的。
static func uniform_point_sampling(points: Array, max_length) -> Array:
	if points.is_empty():
		return []
	
	assert( max_length is int or max_length is float, "max_length 参数的值需要是数字类型" )
	
	# 点对齐
	var point_table : Dictionary[Variant, Array] = {}  #对齐的点对应的点数组
	var align_point
	max_length = int(max_length)
	for point in points:
		align_point = point / max_length  #将点对齐，这个记录这个网格范围的存在的点，按照 max_length 进行划分网格
		point_table.get_or_add(align_point, []).append(point)
	
	# 对齐的点进行深度搜索排序
	var dirs : Array
	if points[0] is Vector2:
		dirs = MathUtil.get_eight_directions()
	elif points[0] is Vector2i:
		dirs = MathUtil.get_eight_directions_i()
	var current_align_point = points[0] / max_length
	var align_point_stack : Array = [current_align_point]
	var max_size_points: Array = []
	var visited: Dictionary = {}
	var find_status: bool = false
	var tmp_align_point
	var not_dir = Vector2.ZERO if points[0] is Vector2 else Vector2i.ZERO
	while true:
		visited[current_align_point] = null
		find_status = false
		for dir in dirs:
			if dir != not_dir:
				tmp_align_point = current_align_point + dir
				if not visited.has(tmp_align_point) and point_table.has(tmp_align_point):
					find_status = true
					current_align_point = tmp_align_point
					align_point_stack.append(current_align_point)
					if max_size_points.size() < align_point_stack.size():
						max_size_points = align_point_stack.duplicate()
					break
		
		# 如果没有找到，则弹出最后一个重新找
		if not find_status:
			current_align_point = align_point_stack.pop_back()
			if align_point_stack.is_empty():
				break
		if align_point_stack.size() > 1:
			not_dir = Vector2(align_point_stack[-1] - align_point_stack[-2]).normalized()
			if points[0] is Vector2i:
				not_dir = Vector2i(not_dir)
	
	var list : Array = [points[0]]
	for point_key in max_size_points:
		list.append(point_table[point_key].pick_random())
	return list


## 查找这组点的内部点。这些点必须是闭合的，否则查找不到。
static func find_inner_points(points: Array) -> Array:
	if points.is_empty():
		return []
	
	var min_point = points[0]
	var max_point = points[0]
	for point in points:
		min_point.x = min(min_point.x, point.x)
		min_point.y = min(min_point.y, point.y)
		max_point.x = max(max_point.x, point.x)
		max_point.y = max(max_point.y, point.y)
	
	var point_set: Dictionary = {}
	for point in points:
		point_set[point] = null
	
	# 查找边缘的点
	var point_rect := Rect2i()
	point_rect.position = Vector2i(min_point)
	point_rect.end = Vector2i(max_point)
	point_rect = point_rect.grow(2)
	var start_cell : Vector2i = point_rect.position
	var around_points : Dictionary = {}
	FuncUtil.path_move(start_cell, [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN], 
		func(next_pos: Vector2i):
			return not point_set.has(next_pos) and point_rect.has_point(next_pos),
		func(next_points):
			for p in next_points:
				around_points[p] = null
	)
	
	var inner_points: Array = []
	for y in range(point_rect.position.y, point_rect.end.y):
		for x in range(point_rect.position.x, point_rect.end.x):
			if not around_points.has(Vector2i(x,y)):
				inner_points.append(Vector2i(x,y))
	
	return inner_points


# 旋转一组 Tile 网格坐标的核心函数
static func rotate_tile_positions(
	tile_map_layer: TileMapLayer, 
	angle_rad: float, #弧度
	pivot_point: Vector2i,
	positions: PackedVector2Array,
) -> PackedVector2Array:
	# 1. 把角度转为弧度（Godot 数学函数用弧度）
	var rotated_positions = PackedVector2Array()
	
	# 2. 遍历所有需要旋转的网格点
	for tile_pos in positions:
		# 步骤A：网格坐标 → 世界坐标
		var world_pos = tile_map_layer.map_to_local(tile_pos)
		var pivot_world = tile_map_layer.map_to_local(pivot_point)
		
		# 步骤B：以中心点为轴，旋转世界坐标
		var rotated_world = rotate_point_around_pivot(world_pos, pivot_world, angle_rad)
		
		# 步骤C：旋转后的世界坐标 → 转回网格坐标
		var new_tile_pos = tile_map_layer.local_to_map(rotated_world)
		
		rotated_positions.append(new_tile_pos)
	
	return rotated_positions


# 辅助函数：点绕中心点旋转
static func rotate_point_around_pivot(point: Vector2, pivot: Vector2, angle: float) -> Vector2:
	# 1. 平移：让中心点变成原点
	var translated = point - pivot
	# 2. 旋转数学公式
	var rotated = Vector2(
		translated.x * cos(angle) - translated.y * sin(angle),
		translated.x * sin(angle) + translated.y * cos(angle)
	)
	# 3. 平移回去
	return rotated + pivot


## 转为简化后的多边形的点。
static func to_polygon_points(border_points: Array, distance_epsilon: float = 1.0) -> PackedVector2Array:
	var _sort_border_points = sort_border_points(border_points)
	# 提取关键坐标点 #膨胀一点点是为了去除交叉的不规则形状
	var results := Geometry2D.offset_polygon(_sort_border_points, 0.001) 
	if results:
		var sort_results := Array(results)
		sort_results.sort_custom(func(a, b): return a.size() > b.size())
		var points := Array(sort_results[0])
		points.map(func(p: Vector2): return p.floor())
		return NavigationServer2D.simplify_path(points, distance_epsilon)
	return PackedVector2Array()


## 获取这些点的整个 Rect2i 大小
static func get_rect_by_cells(cell_list: Array) -> Rect2i:
	var rect = MathUtil.get_rect_by_max_min_vector2(cell_list)
	return Rect2i(rect)


class MergePolygon:
	func connect_polygon(A, B) -> PackedVector2Array:
		# 步骤1：找到两条公切线
		var upper = find_upper_common_tangent(A, B)
		var a_upper = upper[0]
		var b_upper = upper[1]
		var lower = find_lower_common_tangent(A, B)
		var a_lower = lower[0]
		var b_lower = lower[1]
		
		# 步骤2：拼接轮廓
		var merged = PackedVector2Array()
		
		# 从a_lower逆时针走到a_upper
		var idx = find_closest(A, a_lower)
		for __ in range(A.size()):
			merged.append(A[idx])
			if A[idx] == a_upper:
				break
			idx = (idx + 1) % A.size()
		
		# 连接到b_upper
		merged.append(b_upper)
		
		# 从b_upper顺时针走到b_lower
		idx = find_closest(B, b_upper)
		for __ in range(B.size()):
			merged.append(B[idx])
			if B[idx] == b_lower:
				break
			idx = (idx - 1 + B.size()) % B.size()
		
		# 连接回a_lower，闭合
		merged.append(a_lower)
		
		return merged

	# 找到上公切线（所有点都在直线下方）
	func find_upper_common_tangent(A: PackedVector2Array, B: PackedVector2Array) -> Array:
		for a in A:
			for b in B:
				var all_below = true
				
				# 检查A的所有点是否都在直线ab下方
				for p in A:
					if cross(b - a, p - a) > 0.01:
						all_below = false
						break
				if not all_below: continue
				
				# 检查B的所有点是否都在直线ab下方
				for p in B:
					if cross(b - a, p - a) > 0.01:
						all_below = false
						break
				if all_below:
					return [a, b]
		
		return [A[0], B[0]]

	# 找到下公切线（所有点都在直线上方）
	func find_lower_common_tangent(A: PackedVector2Array, B: PackedVector2Array) -> Array:
		for a in A:
			for b in B:
				var all_above = true
				
				# 检查A的所有点是否都在直线ab上方
				for p in A:
					if cross(b - a, p - a) < -0.01:
						all_above = false
						break
				if not all_above: continue
				
				# 检查B的所有点是否都在直线ab上方
				for p in B:
					if cross(b - a, p - a) < -0.01:
						all_above = false
						break
				if all_above:
					return [a, b]
		
		return [A[0], B[0]]

	# 叉积计算（判断点在直线的哪一侧）
	func cross(a: Vector2, b: Vector2) -> float:
		return a.x * b.y - a.y * b.x

	# 找到最近点索引
	func find_closest(arr: PackedVector2Array, point: Vector2) -> int:
		var min_dist = INF
		var idx = 0
		for i in arr.size():
			var dist = arr[i].distance_squared_to(point)
			if dist < min_dist:
				min_dist = dist
				idx = i
		return idx


## 合并离散的多边形
static func merge_discrete_polygons(A: PackedVector2Array, B: PackedVector2Array) -> PackedVector2Array:
	return MergePolygon.new().connect_polygon(A, B)
