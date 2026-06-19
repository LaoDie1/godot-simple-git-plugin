#============================================================
#    Coordinate Slider
#============================================================
# - author: zhangxuetu
# - datetime: 2024-12-19 18:42:15
# - version: 4.3.0.stable
#============================================================
@tool
class_name CoordinateSlider
extends Control


signal changed()
signal value_changed(value: Vector2)


@export var rect: Rect2 = Rect2(0,0,1,1):
	set(v):
		rect = v
		_size = rect.size - rect.position
		self.ratio = _size / value
		self.changed.emit()
		queue_redraw()
@export var value: Vector2:
	set(v):
		value = v
		self.value_changed.emit(value)
		queue_redraw()
@export var ratio: Vector2:
	set(v):
		var previous = ratio
		ratio.x = clampf(v.x, 0, 1)
		ratio.y = clampf(v.y, 0, 1)
		_last_pos *= (previous / ratio)
		queue_redraw()
@export var point: StyleBox:
	set(v):
		point = v
		queue_redraw()
@export var panel: StyleBox:
	set(v):
		panel = v
		queue_redraw()

const _MARGIN: float = 2

static var _default_panel : StyleBoxFlat
static var _default_point : StyleBoxFlat

var _size: Vector2 = Vector2(1, 1)
var _last_pos: Vector2
var _click_status: bool = false


func _init() -> void:
	if _default_panel == null:
		_default_panel = StyleBoxFlat.new()
		_default_panel.bg_color = Color(0.2, 0.2, 0.2)
		_default_panel.corner_radius_bottom_left = 4
		_default_panel.corner_radius_bottom_right = 4
		_default_panel.corner_radius_top_left = 4
		_default_panel.corner_radius_top_right = 4
		
		_default_point = StyleBoxFlat.new()
		_default_point.bg_color = Color(0.8, 0.8, 0.8)
		_default_point.corner_radius_bottom_left = 4
		_default_point.corner_radius_bottom_right = 4
		_default_point.corner_radius_top_left = 4
		_default_point.corner_radius_top_right = 4


func _draw() -> void:
	if panel:
		draw_style_box(panel, Rect2(Vector2(), size))
	else:
		draw_style_box(_default_panel, Rect2(Vector2(), size))
	
	if point:
		draw_style_box(point, Rect2(_last_pos, Vector2(4,4)))
	else:
		draw_style_box(_default_point, Rect2(_last_pos, Vector2(4,4)))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _click_status and get_rect().has_point(get_global_mouse_position()):
			_update_pos(get_local_mouse_position())
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_click_status = event.pressed


func _update_pos(pos: Vector2):
	self._last_pos = pos
	self.ratio = (pos-Vector2(_MARGIN,_MARGIN)) / (size - Vector2(_MARGIN,_MARGIN)*2)
	self.value = ratio * _size 
	self.value.x = clampf(value.x, rect.position.x, _size.x)
	self.value.y = clampf(value.y, rect.position.y, _size.y)
