
#============================================================
#	Node Util
#============================================================
# @datetime: 2022-7-31 18:31:44
#============================================================
class_name NodeUtil
extends ObjectUtil


static func get_physics_process_delta_time():
	return Engine.get_main_loop().current_scene.get_physics_process_delta_time()

static func get_process_delta_time():
	return Engine.get_main_loop().current_scene.get_process_delta_time()


##  扫描所有子节点
##[br]
##[br][code]parent_node[/code]  开始的父节点
##[br][code]filter[/code]  过滤方法。这个方法有一个参数用于接收传入的节点，如果返回 [code]true[/code]，则添加，否则不添加
##[br][code]return[/code]  返回扫描到的所有节点
static func get_all_child( parent_node: Node, filter := Callable() ) -> Array[Node]:
	var list : Array[Node] = []
	var _scan_all_node = func(_parent: Node, self_callable: Callable):
		if filter.is_valid():
			for child in _parent.get_children():
				if filter.call(child):
					list.append(child)
		else:
			for child in _parent.get_children():
				list.append(child)
		for child in _parent.get_children():
			self_callable.call(child, self_callable)
	_scan_all_node.call(parent_node, _scan_all_node)
	return list


##  创建一个计时器
##[br]
##[br][code]time[/code]  倒计时时间
##[br][code]to[/code]  添加到的节点
##[br][code]callable[/code]  回调方法
##[br][code]autostart[/code]  创建并添加到场景后自动执行
##[br][code]one_shot[/code]  只执行一次
##[br][code]return[/code]  返回创建的 [Timer] 计时器
static func create_timer(
	time: float, 
	to: Node = null, 
	callable: Callable = Callable(), 
	autostart : bool = true,
	one_shot : bool = false
) -> Timer:
	var timer := Timer.new()
	timer.wait_time = time
	if not callable.is_null():
		timer.timeout.connect(callable)
	if autostart:
		timer.autostart = true
	timer.one_shot = one_shot
	if to:
		if to.is_inside_tree():
			to.add_child(timer)
		else:
			to.add_child.call_deferred(timer)
	return timer


##  创建一个一次性计时器
##[br]
##[br][code]time[/code]  时间
##[br][code]callable[/code]  回调方法
##[br][code]to[/code]  添加到这个节点上，如果为 null，则自动添加到当前场景
##[br][code]return[/code]  返回创建的 [Timer]
static func create_once_timer(
	time: float = 1.0, 
	callable: Callable = Callable(), 
	to: Node = null
) -> Timer:
	if to == null:
		if callable.is_valid():
			var object = callable.get_object() as Object
			if object is Node and is_instance_valid(object):
				to = object
	if to == null:
		to = Engine.get_main_loop().current_scene
	
	var timer := create_timer(time, to, callable, true)
	timer.one_shot = true
	timer.timeout.connect(timer.queue_free, Object.CONNECT_DEFERRED)
	return timer


##  获取场景树
##[br]
##[br][code]return[/code]  返回场景树
static func get_tree() -> SceneTree:
	return Engine.get_main_loop()

## 获取根节点
static func get_root() -> Window:
	return Engine.get_main_loop().root

##  获取当前场景
##[br]
##[br][code]return[/code]  返回当前场景节点
static func get_current_scene() -> Node:
	return Engine.get_main_loop().current_scene

static func get_current_scene_2d() -> Node2D:
	return Engine.get_main_loop().current_scene as Node2D

static func get_current_scene_3d() -> Node3D:
	return Engine.get_main_loop().current_scene as Node3D

static func get_current_scene_control() -> Control:
	return Engine.get_main_loop().current_scene as Control

##  创建 Tween
static func create_tween() -> Tween:
	return Engine.get_main_loop().current_scene.create_tween()

##  根据 Class 获取父节点
##[br]
##[br][code]node[/code]  开始节点
##[br][code]_class[/code]  祖父节点的类
##[br][code]return[/code]  返回符合的类的祖父节点
static func find_parent_by_class(node: Node, _class):
	if not is_instance_valid(node):
		return null
	var p = node.get_parent()
	while p and not is_instance_of(p, _class):
		p = p.get_parent()
	return p


static func find_parent_by_method(node: Node, method: String):
	var p = node.get_parent()
	while p and not p.has_method(method):
		p = p.get_parent()
	return p


##  添加节点到目标
##[br]
##[br][code]node[/code]  节点目标
##[br][code]to[/code]  添加到的节点上。默认添加到当前游戏场景节点
##[br][code]callable[/code]  这个节点添加到场景上之后的回调，这个回调要有一个 [Node] 类型的
##参数用于接收这个添加的节点
static func add_node(
	node: Node, 
	to: Node = Engine.get_main_loop().current_scene, 
	callable: Callable = Callable(),
	is_call_deferred_add: bool = false
) -> Node:
	if callable.is_valid():
		node.tree_entered.connect(func(): 
			callable.call(node)
		, Object.CONNECT_ONE_SHOT)
	if is_instance_valid(to):
		if is_call_deferred_add:
			to.add_child.call_deferred(node)
		else:
			to.add_child(node)
	return node


##  添加节点列表到节点中
##[br]
##[br][code]to[/code]  要添加到的节点
##[br][code]node_list_callback[/code]  返回节点列表的没有参数的回调法
##[br][code]force_readable_name[/code]  强制设置可读性强的名称
##[br][code]internal[/code]  添加的节点的内部方式，详见 [Node] 节点中的 [enum Node.InternalMode] 枚举 
static func add_node_by_list(
	to: Node, 
	node_list_callback: Callable, 
	force_readable_name: bool = false, 
	internal: int = Node.INTERNAL_MODE_DISABLED
) -> Array:
	var node_list : Array = node_list_callback.call()
	for node in node_list:
		to.add_child(node, force_readable_name, internal)
	return node_list


##  延迟移除
##[br]
##[br][code]node[/code]  移除节点
##[br][code]time[/code]  延迟时间
static func delay_free(node: Node, time: float):
	Engine.get_main_loop().create_timer(time).timeout.connect(node.queue_free)

##  添加节点到目标或添加到当前场景中
##[br]
##[br][code]node[/code]  添加的节点
##[br][code]to[/code]  添加到的目标，如果这个值不传入或为 [code]null[/code]，则默认添加到当前场景中
##[br][code]force_readable_name[/code]  添加的节点名称是否为可读的
##[br][code]internal[/code]  添加的节点的内部方式，详见 [Node] 节点中的 [enum Node.InternalMode] 枚举 
static func add_node_to_or_current_scene(
	node: Node, 
	to: Node = null, 
	force_readable_name: bool = false, 
	internal: int = 0
) -> void:
	if to:
		to.add_child(node, force_readable_name, internal)
	else:
		Engine.get_main_loop().current_scene.add_child(node, force_readable_name, internal)


##  节点是否在场景树中
##[br]
##[br][code]node[/code]  节点对象
static func is_inside_tree(node: Node) -> bool:
	return node is Node and node != null and node.is_inside_tree()


## 获取这个类型的子节点
static func find_child_by_class(parent: Node, type) -> Array[Node]:
	var list : Array[Node] = []
	if not is_instance_valid(parent):
		return list
	for child in parent.get_children():
		if is_instance_of(child, type):
			list.append(child)
	return list


## 获取这个类型的子节点
static func find_child_by_name(parent: Node, name) -> Array[Node]:
	return parent.find_children(name)


## 获取这个类型的第一个子节点
static func find_first_child_by_class(parent: Node, type) -> Node:
	if is_instance_valid(parent):
		for child in parent.get_children():
			if is_instance_of(child, type):
				return child
	return null

## 获取这个类型的第一个子节点
static func find_first_child_by_name(parent: Node, name) -> Node:
	return parent.find_child(name)


##  查找匹配这个名称的所有子节点
static func find_all_children_by_name(root: Node, pattern: String) -> Array[Node]:
	var regex : RegEx = RegEx.new()
	regex.compile(pattern)
	return get_all_child(root, func(node: Node):
		return regex.search(node.name) != null
	)


##  查找匹配这个类型的所有子节点
##[br]
##[br][code]root[/code]  根节点
##[br][code]_class[/code]  类
static func find_all_children_by_class(root: Node, _class) -> Array[Node]:
	return get_all_child(root, func(node: Node): return is_instance_of(node, _class) )


## 从父节点中移除这个节点
static func remove_node(node: Node) -> bool:
	if node.is_inside_tree():
		node.get_parent().remove_child(node)
		return true
	return false


## 删除所有子节点
static func queue_free_children(parent: Node):
	for child in parent.get_children():
		child.queue_free()


## 移除所有子节点
static func remove_all_child(parent: Node):
	for child in parent.get_children():
		parent.remove_child(child)


## 获取帧信号
static func get_main_loop_frame_signal(process_type: Timer.TimerProcessCallback) -> Signal:
	if process_type == Timer.TIMER_PROCESS_IDLE:
		return Engine.get_main_loop().process_frame
	else:
		return Engine.get_main_loop().physics_frame

## 节点是否可见
static func is_visible(node: CanvasItem) -> bool:
	return is_instance_valid(node) \
		and "visible" in node \
		and node.visible


## 创建节点到鼠标位置
static func create_node_to_mouse_position(_class, add_to: Node = null) -> Node:
	if add_to == null:
		add_to = Engine.get_main_loop().current_scene
	var node = _class.new()
	add_to.add_child(node)
	if node is CanvasItem:
		var pos = node.get_global_mouse_position()
		node.global_position = pos
	return node


## 设置相同的位置
static func set_same_position(node: Node2D, from: Node2D):
	node.global_position = from.global_position


## 创建一个 TextureRect 节点
static func create_texture_rect(texture: Texture2D) -> TextureRect:
	var texture_rect = TextureRect.new()
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return texture_rect

## 将节点移动到另一个节点上
static func move_to(target_node: Node, add_to_node: Node) -> void:
	if target_node.is_inside_tree():
		if target_node.get_parent() == add_to_node:
			return
		target_node.get_parent().remove_child(target_node)
	add_to_node.add_child(target_node)

## 将节点绑定节点到目标节点上。一个节点只能绑定一个这种类型的节点。
static func bind_singleton_node(type_node: Node, to_node: Node, auto_unbind: bool = true) -> void:
	var type : Script = type_node.get_script()
	assert(type != null, "type_node 节点必须挂载有脚本！")
	var id : StringName = "BINDED_SINGLETON_NODE_%s" % type.resource_path.hash()
	to_node.set_meta(id, type_node)
	if auto_unbind:
		# 自动取消绑定
		to_node.tree_exiting.connect(
			func(): 
				if to_node.has_meta(id):
					to_node.remove_meta(id)
		, Object.CONNECT_ONE_SHOT)

## 获取节点上绑定的类型的节点
static func get_binded_singleton_node(from_node: Node, type_class: Script) -> Object:
	var id : StringName = &"BINDED_SINGLETON_NODE_%s" % type_class.resource_path.hash()
	if from_node.has_meta(id):
		return from_node.get_meta(id)
	return null

## 创建漂浮文字
static func create_rich_label(text, ...label_callbacks: Array) -> RichTextLabel:
	var label : RichTextLabel = RichTextLabel.new()
	label.visible = true
	label.fit_content = true
	label.clip_contents = false
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = str(text)
	label.add_theme_font_size_override("normal_font_size", 16)
	label.pivot_offset_ratio = Vector2(0.5, 0.5)
	
	# 等待 text 设置后的大小更新
	get_tree().process_frame.connect(
		func():
			for callback: Callable in label_callbacks:
				callback.call_deferred(label)
			if not label.is_inside_tree():
				get_tree().current_scene.add_child(label)
	, Object.CONNECT_ONE_SHOT)
	return label


static func center(node: CanvasItem, pos: Vector2):
	get_tree().process_frame.connect(
		func():
			node.position = pos - node.size / 2
	, Object.CONNECT_ONE_SHOT)


## 节点转向目标位置
static func look_at(node: CanvasItem, target_position: Vector2, offset_rotation: float = 0.0) -> void:
	var r : float = node.get_angle_to(target_position) + offset_rotation
	node.rotation += r
