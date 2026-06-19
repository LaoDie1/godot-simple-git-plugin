#============================================================
#    Control Util
#============================================================
# - datetime: 2023-02-12 13:31:18
#============================================================
## 操作 Control 的节点
class_name ControlUtil


##  点击 Control 节点
##[br]
##[br][code]control[/code]  
##[br][code]button_index[/code]  
##[br][code]pressed[/code]  
static func click(
	control : Control, 
	button_index: int = MOUSE_BUTTON_LEFT, 
	pressed : bool = true
) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = pressed
	if control.has_method("_gui_input"):
		control._gui_input(event)
	else:
		control.gui_input.emit(event)
	
	if control is BaseButton:
		control.pressed.emit()
	


##  点击 Control 节点时执行方法
##[br]
##[br][code]node[/code]  点击的节点
##[br][code]callable[/code]  回调方法
##[br][code]execute_once[/code]  连接一次
static func bind_click_event(node: Control, callable: Callable, flags: int = 0):
	node.gui_input.connect(
		func(event):
			if event is InputEventMouseButton:
				callable.call(event.button_index, event.pressed)
	, flags)


## 绑定 [TextEdit] 节点的按键输入，如果按下 Enter 键则触发 [param callback] 回调
static func bind_textedit_submit_signal(
	textedit: TextEdit, 
	callback: Callable, 
	mask_key_flag: int = KEY_MASK_CMD_OR_CTRL | KEY_MASK_SHIFT | KEY_MASK_CTRL | KEY_MASK_ALT | KEY_MASK_META
) -> void:
	textedit.gui_input.connect(
		func(event):
			if event is InputEventKey:
				if event.keycode == KEY_ENTER and event.pressed:
					# 只要不按下下面的键，则视作发送
					if not (
						(event.is_command_or_control_pressed() and mask_key_flag & KEY_MASK_CMD_OR_CTRL == KEY_MASK_CMD_OR_CTRL)
						or (event.shift_pressed and mask_key_flag & KEY_MASK_SHIFT == KEY_MASK_SHIFT)
						or (event.ctrl_pressed and mask_key_flag & KEY_MASK_CTRL == KEY_MASK_CTRL)
						or (event.meta_pressed and mask_key_flag & KEY_MASK_META == KEY_MASK_META)
						or (event.alt_pressed and mask_key_flag & KEY_MASK_ALT == KEY_MASK_ALT)
					):
						callback.call()
	)


##  创建一个 [TextureRect] 节点
static func create_texture_rect(texture: Texture, custom_minimum_size: Vector2 = Vector2(0,0)) -> TextureRect:
	var texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = texture
	texture_rect.custom_minimum_size =custom_minimum_size
	return texture_rect


##  设置节点的style值的属性
##[br]
##[br][code]control[/code]  [Control]类节点
##[br][code]property[/code]  style属性名
##[br][code]value[/code]  属性值
static func set_panel_style(control: Control, property: String, value) -> void:
	control.set_indexed("theme_override_styles/panel:" + property, value)


## 获取中心位置
static func get_global_center(control: Control) -> Vector2:
	return control.global_position + control.size / 2


static func has_point_in_control(point: Vector2, control: Control) -> bool:
	var rect = control.get_rect()
	rect.position -= rect.position
	return rect.has_point(point)

static func has_mouse_point_in_control(control: Control) -> bool:
	return has_point_in_control(control.get_local_mouse_position(), control)


## 根据鼠标位置缩放
static func mouse_zoom_scale(canvas: Control, zoom: Vector2) -> void:
	# 缩放前鼠标位置
	var last_pos : Vector2 = canvas.get_local_mouse_position()
	# 缩放
	canvas.scale = zoom
	# 位置偏移。正确偏移到鼠标位置的点
	var current_pos : Vector2 = canvas.get_local_mouse_position()
	var offset : Vector2 = current_pos - last_pos
	if offset > canvas.size:
		offset = canvas.size
	canvas.position += offset * canvas.scale
