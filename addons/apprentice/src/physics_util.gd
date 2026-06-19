#============================================================
#    Physics Util
#============================================================
# - author: zhangxuetu
# - datetime: 2026-01-04 09:55:09
# - version: 4.5.1.stable
#============================================================
## 物理工具
class_name PhysicsUtil


## 获取引擎启动后已经过的物理帧时间
static func get_physics_time() -> float:
	return Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)

## 获取每秒物理周期数
static func get_physics_ticks_per_second() -> int:
	return Engine.physics_ticks_per_second

## 获取每秒最大物理周期数
static func get_max_physics_steps_per_frame() -> int:
	return Engine.max_physics_steps_per_frame


## 设置碰撞检测不启用。自动设置其所有相关子形状节点不可用
static func set_disabled(coll_object: CollisionObject2D, disabled: bool) -> void:
	var shape: Node2D
	for owner_id in coll_object.get_shape_owners():
		shape = coll_object.shape_owner_get_owner(owner_id)
		shape.set_deferred("disabled", disabled)

static func get_collision_shapes(coll_object: CollisionObject2D) -> Array[Node2D]:
	var list : Array[Node2D] = []
	var shape: Node2D
	for owner_id in coll_object.get_shape_owners():
		shape = coll_object.shape_owner_get_owner(owner_id)
		list.append(shape)
	return list

## 获取射线位置检测到的节点。数据结果格式详见 [method PhysicsDirectSpaceState2D.intersect_ray]
static func detect_ray(
	from: Vector2, 
	to: Vector2, 
	collide_with_areas: bool = true,
	collide_with_bodies: bool = true,
	collision_mask: int = 0xFFFFFFFF, 
	exclude: Array[RID] = [],
	world: World2D = null
) -> Dictionary:
	var query_params := PhysicsRayQueryParameters2D.create( from, to, collision_mask, exclude )
	query_params.collide_with_areas = collide_with_areas
	query_params.collide_with_bodies = collide_with_bodies
	query_params.hit_from_inside = false
	var space_state: PhysicsDirectSpaceState2D
	if world != null:
		space_state = world.direct_space_state
	else:
		space_state = get_physics_direct_space_state_2d()
	return space_state.intersect_ray(query_params)


## 检测圆形范围内的物理单位。数据结果格式详见 [method PhysicsDirectSpaceState2D.intersect_shape]
static func detect_circle(
	position: Vector2,
	radius : float,
	collide_with_areas: bool = true,
	collide_with_bodies: bool = true,
	collision_mask: int = -1, 
	exclude: Array[RID] = [],
	max_results: int = 32,
) -> Array[Dictionary]:
	if collision_mask == -1:
		collision_mask = 0xFFFFFFFF
	var params := PhysicsShapeQueryParameters2D.new()
	params.collide_with_areas = collide_with_areas
	params.collide_with_bodies = collide_with_bodies
	params.collision_mask = collision_mask
	params.transform = Transform2D(0, position)
	#params.motion = position
	params.exclude = exclude
	
	var circle := CircleShape2D.new()
	circle.radius = radius
	params.shape = circle
	return get_physics_direct_space_state_2d().intersect_shape(params, max_results)


## 检测矩形范围内的物理单位。数据结果格式详见 [method PhysicsDirectSpaceState2D.intersect_shape]
static func detect_rectangle(
	position: Vector2,
	size: Vector2,
	collide_with_areas: bool = true,
	collide_with_bodies: bool = true,
	collision_mask: int = 0xFFFFFFFF, 
	exclude: Array = [],
	max_results: int = 32
) -> Array[Dictionary]:
	var params := PhysicsShapeQueryParameters2D.new()
	params.collide_with_areas = collide_with_areas
	params.collide_with_bodies = collide_with_bodies
	params.collision_mask = collision_mask
	params.transform = Transform2D(0, position)
	params.exclude = Array(exclude, TYPE_RID, "", null)
	
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	params.shape = rectangle
	return get_physics_direct_space_state_2d().intersect_shape(params, max_results)

static func get_world_2d() -> World2D:
	var root : Window = Engine.get_main_loop().root
	return root.find_world_2d()

static func get_world_3d() -> World3D:
	var root : Window = Engine.get_main_loop().root
	return root.find_world_3d()

## 获取当前世界的物理状态
static func get_physics_direct_space_state_2d() -> PhysicsDirectSpaceState2D:
	return get_world_2d().direct_space_state

static func get_physics_direct_space_state_3d() -> PhysicsDirectSpaceState3D:
	return get_world_3d().direct_space_state
