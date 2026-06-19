#============================================================
#    Virtual Joystick
#============================================================
# - author: zhangxuetu
# - datetime: 2023-05-31 11:04:36
# - version: 4.0
# - see: https://github.com/mcunha-br/virtual_joystick_godot4
#============================================================
## 虚拟摇杆
@tool
@icon("sprites/icon.png")
class_name VirtualJoystickA
extends Control

##  摇杆线程。[code]direction[/code] 方向，[code]strength[/code] 力度
signal analogic_process(direction: Vector2, strength: float)
## 摇杆状态发生了变化
signal analogic_changed(direction: Vector2, strength: float)
## 按下了摇杆
signal analogic_pressed()
## 松开摇杆
signal analogic_released()

const JOYSTICK = preload("sprites/joystick.png")


## 摇杆背景图
@export var border: Texture2D = preload("sprites/joystick.png"):
	set(value):
		border = value
		_draw()
## 摇杆贴图
@export var stick: Texture2D = preload("sprites/stick.png"):
	set(value):
		stick = value
		_draw()
@export var stick_scale: Vector2 = Vector2(0.6, 0.6):
	set(value):
		stick_scale = value
		_draw()
## 显示到的平台。如果游戏运行在这个类型的操作系统时则显示
@export_flags("Mobile", "Computy", "Web") 
var display_platform : int = 0:
	set(v):
		display_platform = v
		if Engine.is_editor_hint(): #编辑器中的时候不更新
			return
		match OS.get_name():
			"Android", "iOS":
				visible = (display_platform & 1 == 1)
			"Windows", "UWP", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
				visible = (display_platform & 2 == 2)
			"Web":
				visible = (display_platform & 3 == 3)



var stick_background := TextureRect.new() # 摇杆背景
var stick_touch_button := TouchScreenButton.new() # 控制按钮

var _touch_pos : Vector2:
	set(v):
		_touch_pos = v
		_touch_max_radius = _touch_pos.length()
var _touch_max_radius : float
var _on_going_drag : bool = false
var _direction : Vector2 = Vector2(0, 0) # 上次拖拽的方向
var _strength : float = 0.0 # 力度，离中心点和最大距离之间的比值


## 获取上次拖拽的摇杆的方向
func get_last_normalize() -> Vector2:
	return _direction

## 获取摇杆拖拽的力度
func get_last_strength() -> float:
	return _strength


func _enter_tree():
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
	
	self.display_platform = display_platform


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
	else:
		stick_touch_button.released.connect(func(): 
			_direction = Vector2(0, 0)
			self.analogic_released.emit()
		)
	queue_redraw()
	self.display_platform = display_platform
	_init_child_node()


func _draw():
	stick_background.texture = border \
		if is_instance_valid(border) \
		else preload("sprites/joystick.png")
	stick_touch_button.texture_normal = stick \
		if is_instance_valid(stick) \
		else preload("sprites/stick.png")
	
	# 更新大小
	stick_background.size = self.size
	if stick_touch_button.texture_normal:
		stick_touch_button.scale = self.size / Vector2(stick_touch_button.texture_normal.get_size()) * stick_scale
	
	_reset_position()


func _physics_process(delta):
	self.analogic_process.emit(_direction, _strength)


func _gui_input(event):
	# 按下时
	if event is InputEventScreenTouch:
		if _on_going_drag != event.is_pressed():
			_on_going_drag = event.is_pressed()
			if not _on_going_drag:
				self.analogic_released.emit()
				_direction = Vector2.ZERO
				_strength = 0.0
				_reset_position()
			else:
				#self.analogic_changed.emit(_direction, _strength)
				self.analogic_pressed.emit()
	# 拖拽时
	elif event is InputEventScreenDrag:
		var diff : Vector2 = Vector2(event.position - size/2).limit_length(_touch_max_radius)
		var length : float = diff.length()
		_strength = length / _touch_max_radius
		_direction = diff.normalized()
		stick_touch_button.position = _touch_pos + diff
		self.analogic_changed.emit(_direction, _strength)


func _init_child_node():
	if not stick_background.is_inside_tree():
		add_child(stick_background)
		move_child(stick_background, 0)
		stick_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stick_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stick_background.set_anchors_preset(Control.PRESET_FULL_RECT)

	if not stick_touch_button.is_inside_tree():
		stick_touch_button.modulate.a = 0.8
		stick_background.add_child(stick_touch_button)


func _reset_position():
	if stick_touch_button.texture_normal:
		_touch_pos = (self.size - stick_touch_button.scale * Vector2(stick_touch_button.texture_normal.get_image().get_size())) / 2
		if not is_inside_tree():
			await ready
		create_tween().tween_property(stick_touch_button, "position", _touch_pos, 0.08)
	
