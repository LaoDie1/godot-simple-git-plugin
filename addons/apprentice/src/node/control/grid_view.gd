#============================================================
#    Grid View
#============================================================
# - author: zhangxuetu
# - datetime: 2024-12-05 17:10:33
# - version: 4.3.0.stable
#============================================================
@tool
class_name GridView
extends Control


signal ready_draw
signal button_clicked(cell: Vector2, button_index: int)
signal button_hovered(cell: Vector2, button_index: int)
signal button_release(cell: Vector2, button_index: int)
signal offset_changed()


@export var offset := Vector2(): # 中心点位置偏移的值
	set(v):
		offset = v
		queue_redraw()
		offset_changed.emit()
@export var enabled_draw_cell_line : bool = true:
	set(v):
		enabled_draw_cell_line = v
		queue_redraw()
@export var tile_line_color: Color = Color(1,1,1,0.3):
	set(v):
		tile_line_color = v
		queue_redraw()
@export var tile_size: int = 16:
	set(v):
		tile_size = v
		queue_redraw()
@export var unit_size: Vector2 = Vector2(16, 16):
	set(v):
		unit_size = v
		queue_redraw()
@export var unit_line_color: Color = Color.WHITE:
	set(v):
		unit_line_color = v
		queue_redraw()
@export var unit_line_width: float = -1:
	set(v):
		unit_line_width = v
		queue_redraw()
@export var select_color: Color = Color.WHITE:
	set(v):
		select_color = v
		queue_redraw()
@export var select_width: float = 3:
	set(v):
		select_width = v
		queue_redraw()

var tile_line_width: float = -1.0
var select_rect: Rect2i = Rect2i():
	set(v):
		select_rect = v
		queue_redraw()

var _middle_press_status := false
var _middle_press_pos := Vector2()
var _middle_press_offset := Vector2()
var _click_button_status := false
var _last_clicked_button_index := MOUSE_BUTTON_NONE
var _last_click_cell: Vector2i


func _init() -> void:
	clip_contents = true


func _draw() -> void:
	ready_draw.emit()
	if enabled_draw_cell_line:
		draw_grid(Vector2(tile_size, tile_size), tile_line_color, tile_line_width)
		draw_grid(Vector2(tile_size, tile_size) * unit_size, unit_line_color, unit_line_width)
		if select_rect != Rect2i():
			var r = select_rect
			r.position *= tile_size
			r.position += Vector2i(offset)
			r.size *= tile_size
			draw_rect(r, select_color, false, select_width)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if event.pressed:
					var cell : Vector2i = local_to_cell(get_local_mouse_position())
					_last_click_cell = cell
					_last_clicked_button_index = event.button_index
					button_clicked.emit(cell, event.button_index)
				else:
					var cell : Vector2i = local_to_cell(get_local_mouse_position())
					button_release.emit(cell, event.button_index)
				_click_button_status = event.pressed
			MOUSE_BUTTON_MIDDLE:
				_middle_press_status = event.pressed
				_middle_press_pos = get_local_mouse_position()
				_middle_press_offset = offset
			
	elif event is InputEventMouseMotion:
		if _middle_press_status:
			offset = (_middle_press_offset + get_local_mouse_position() - _middle_press_pos)
		elif _click_button_status:
			var cell = local_to_cell(get_local_mouse_position())
			if _last_click_cell != cell:
				_last_click_cell = cell
				button_hovered.emit(cell, _last_clicked_button_index)

func draw_grid(cell_size: Vector2, color: Color, width: float = -1.0):
	var start := Vector2()
	start.x = int(offset.x) % int(cell_size.x) - cell_size.x
	start.y = int(offset.y) % int(cell_size.y) - cell_size.y
	var end := size + start + cell_size * 2.0
	var point := start
	while point.x < end.x:
		draw_line(Vector2(point.x, start.y), Vector2(point.x, end.y), color, width)
		point.x += cell_size.x
	while point.y < end.y:
		draw_line(Vector2(start.x, point.y), Vector2(end.x, point.y), color, width)
		point.y += cell_size.y

## 获取整个视野范围内的矩形大小的所有单元格
func get_view_rect_cells() -> Array[Vector2i]:
	var list : Array[Vector2i] = []
	var columns_rows := Vector2i((size - offset) / tile_size) + Vector2i.ONE
	for y in range(int(-offset.y/tile_size), columns_rows.y):
		for x in range(int(-offset.x/tile_size), columns_rows.x):
			list.push_back(Vector2i(x, y))
	return list

func get_offset_cell() -> Vector2i:
	return Vector2i(offset / tile_size)

# 全局位置转为本地 cell 位置
func local_to_cell(local_position: Vector2) -> Vector2i:
	return Vector2i(((local_position - offset) / tile_size).floor())

func update_select_rect(from_cell: Vector2i, to_cell: Vector2i):
	var tmp
	if from_cell.x > to_cell.x:
		tmp = from_cell.x
		from_cell.x = to_cell.x
		to_cell.x = tmp
	if from_cell.y > to_cell.y:
		tmp = from_cell.y
		from_cell.y = to_cell.y
		to_cell.y = tmp
	select_rect = Rect2i(from_cell, to_cell - from_cell + Vector2i.ONE)
	queue_redraw()

func clear_select_rect():
	select_rect = Rect2i()
	queue_redraw()

func get_selected_cells() -> Array[Vector2i]:
	var list : Array[Vector2i] = []
	for y in range(select_rect.position.y, select_rect.end.y):
		for x in range(select_rect.position.x, select_rect.end.x):
			list.push_back(Vector2i(x,y))
	return list
