#============================================================
#    Platform Move Component
#============================================================
# - author: zhangxuetu
# - datetime: 2025-05-15 21:34:08
# - version: 4.4.1
#============================================================
## 角色移动控制的方式
class_name PlatformMoveComponent
extends Node2D

signal direction_changed(direction: Vector2)
signal move_state_changed
signal jumped
signal fell
signal on_floor_state_changed

@export var role: CharacterBody2D
@export var enabled: bool = true:
	set(v):
		enabled = v
		set_physics_process(enabled)

@export var on_ceil_fall : bool = true ##碰到天花板时立马开始下坠

@export_group("Move", "move")
@export var move_enabled: bool = true
@export var move_speed: float = 0.0
@export_range(0, 1) var move_rate: float = 1.0
@export_range(0, 1) var move_friction: float = 1.0

@export_group("Jump")
@export var jump_enabled: bool = true
@export var jump_heigth: float = 0.0
@export var jump_buffer_time = 0.1 ##跳跃缓冲时间。如果在落下之前的短时间内按下过跳跃，则在进入地面之后自动进行跳跃
@export var coyote_time = 0.1 ##土狼时间，在这个时间内离开地面仍可以跳跃 
@export var on_floor_jump_time: float = 0.0 ##落在地面上时跳跃缓冲时间

@export_group("Gravity")
@export var gravity_enabled: bool = true
@export var gravity_max: float = 0.0
@export_range(0, 1) var gravity_rate: float = 0.02

var velocity: Vector2 #当前控制的移动向量，他是自动计算的，一般情况下不要修改
var _temp_on_floor : bool = false

var _last_direction: Vector2 = Vector2.ZERO
var _move_direction: Vector2 = Vector2.ZERO
var _last_move_direction: Vector2 = Vector2.ZERO
var _last_velocity: Vector2 = Vector2.ZERO
var _moving: bool = false:
	set(v):
		if _moving != v:
			_moving = v
			move_state_changed.emit()
var _jump_count: int = 0  #没有落地前调用 [method jump] 方法的次数
var _jump_last_time: float = 0.0  #已经在空中跳跃的时间
var _coyote_time: float = 0.0  # 土狼时间。如果在这个时间内进行了跳跃，则无论是否在地面上，都可以进行跳跃
var _jump_buffer_time: float = 0.0 #跳跃缓冲时间。如果在落下之前的短时间内按下过跳跃
var _on_floor_state : bool = false:
	set(v):
		if _on_floor_state != v:
			_on_floor_state = v
			if _on_floor_state:
				_last_on_floor_frame = Engine.get_physics_frames()
			on_floor_state_changed.emit()
var _last_on_floor_frame: int = -9999
var _last_on_ceil_frame: int = -9999

## 这个值默认为 [code]Vector2(0, 0)[/code]，需要手动调用 [method update_direction] 进行更新
func get_last_direction() -> Vector2:
	return _last_direction

func is_moving() -> bool:
	return _moving

func get_jump_count() -> int:
	return _jump_count

func get_jump_last_time() -> float:
	return _jump_last_time

func is_on_floor() -> bool:
	return _on_floor_state

func get_last_move_direction() -> Vector2:
	return _last_move_direction


func _ready():
	set_physics_process(enabled)

func _physics_process(delta):
	if enabled:
		_temp_on_floor = role.is_on_floor()
		
		# 移动
		var direction : Vector2 = _move_direction
		if move_enabled:
			direction.x = sign(direction.x)
			if direction.x != 0:
				if _temp_on_floor or role.is_on_wall():
					# 在地面时的移动
					velocity.x = lerpf(velocity.x, direction.x * move_speed, move_rate)
				else:
					# 不在地面时的移动
					velocity.x += lerpf(velocity.x, direction.x * move_speed, move_rate * 8 ) * delta
					velocity.x = clampf(velocity.x, -move_speed, move_speed)
				
				update_direction(direction)
		
		# 跳跃
		if _temp_on_floor:
			_jump_last_time = 0.0
			_jump_count = 0
			_coyote_time = 0.0
		_jump_last_time += delta
		_coyote_time += delta
		_jump_buffer_time -= delta #开始倒计时跳跃缓冲
		if direction.y < 0:
			_jump_buffer_time = jump_buffer_time
		if _jump_buffer_time > 0:
			if _temp_on_floor or _coyote_time < coyote_time:
				var last_jump_time := float(Engine.get_physics_frames() - _last_on_floor_frame) / Engine.physics_ticks_per_second
				if _jump_count == 0 and last_jump_time >= on_floor_jump_time:
					jump(jump_heigth)
		
		# 重力
		if gravity_enabled:
			velocity.y = lerpf(velocity.y, gravity_max, gravity_rate) 
			if _last_velocity.y < 0 and velocity.y > 0:
				fell.emit()
		 
		# 实际移动
		role.velocity = velocity
		role.move_and_slide()
		
		# 更新状态和数据
		_temp_on_floor = role.is_on_floor()
		if _temp_on_floor:
			velocity.y = 0
		if role.is_on_ceiling():
			if on_ceil_fall:
				var time := float(Engine.get_physics_frames() - _last_on_ceil_frame) / Engine.physics_ticks_per_second
				if time > 0.1:
					velocity.y = 0
		else:
			_last_on_ceil_frame = Engine.get_physics_frames()
		
		_moving = (direction.x != 0)
		_last_move_direction = _move_direction
		_last_velocity = velocity
		_on_floor_state = _temp_on_floor
		
		# 摩擦力
		if direction.x == 0:
			if _temp_on_floor:
				# 在地面上时的摩擦力
				velocity.x = lerpf(velocity.x, 0, move_friction) 
			else:
				velocity.x = lerpf(velocity.x, 0, delta)
		
		_move_direction = Vector2.ZERO
	else:
		set_physics_process(enabled)


func clear_jump_buffer() -> void:
	_jump_buffer_time = 0

func clear_jump_count() -> void:
	_jump_count = 0

func move(vector: Vector2) -> void:
	update_direction(vector)
	_move_direction = vector.normalized()

func move_and_jump(direction: Vector2) -> void:
	update_direction(direction)
	_move_direction = direction
	_move_direction.x = sign(_move_direction.x)

func update_direction(direction: Vector2) -> void:
	if direction.x != 0 and _last_direction.x != sign(direction.x):
		_move_direction.x = 0
		_last_direction.x = sign(direction.x)
		direction_changed.emit(_last_direction)

## 让角色进行跳跃起来。这个高度是正数，会自动转为负数进行跳跃。
func jump(height: float = 0) -> void:
	if jump_enabled:
		if is_zero_approx(height):
			height = jump_heigth
		velocity.y = -height
		_jump_last_time = 0.0
		_jump_count += 1
		jumped.emit()

func stop():
	_move_direction = Vector2()
	_jump_buffer_time = 0


## 计算跳跃到这个高度需要多长时间
func calculate_jump_height_max_time(height: float) -> float:
	var vel : Vector2 = Vector2(0, -height)
	var count : int = 0
	while true:
		vel.y = lerpf(vel.y, gravity_max, gravity_rate) 
		if vel.y >= 0:
			break
		count += 1
	return count * get_physics_process_delta_time()

## 计算用这个跳跃的力能跳达最高的高度
func calculate_jump_height_max_height(height: float) -> float:
	var vel : Vector2 = Vector2(0, -height)
	var total_height : float = 0.0
	var delta : float = get_physics_process_delta_time()
	while true:
		vel.y = lerpf(vel.y, gravity_max, gravity_rate) 
		if vel.y >= 0:
			break
		total_height += vel.y * delta
	return -total_height

## 计算达到目标高度所需的最小初始跳跃速度
func calculate_jump_height_by_distance(target_height: float) -> float:
	if target_height <= 0:
		return 0.0  # 不需要跳跃
	
	var epsilon: float = target_height * -0.5       # 允许的高度误差
	const STEP: float = 1.0          # 速度递增步长（可调整精度）
	var v0: float = 0.0  # 初始速度从0开始
	while true:
		# 计算当前速度v0能达到的最大高度
		var current_height = calculate_jump_height_max_height(v0)
		# 若达到或超过目标高度，返回当前速度
		if current_height >= target_height - epsilon:
			return v0
		# 否则增加速度，继续尝试
		v0 += STEP
	return 0.0
