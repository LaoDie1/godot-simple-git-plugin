#============================================================
#    State Node
#============================================================
# - author: zhangxuetu
# - datetime: 2022-12-01 12:48:31
# - version: 4.0
#============================================================
## 状态节点
##
##如果父节点不是状态节点，则默认当前状态为根状态节点
##[br]
##[br]通过 [method add_state] 进行添加子状态，返回添加的状态节点可以继续进行添加下一层级的状态。如果有父节点，则通过 [method trans_to_child]
##或 [method trans_to_self] 方法进行切换状态。
##[br]
##[br]场景有个 [kbd]state_root[/kbd] 名称的 [StateNode] 根节点，并向其添加如下几个状态：
##[codeblock]
##enum States {
##    IDLE,
##    MOVE,
##    JUMP,
##}
##
##@onready var idle_state : StateNode = state_root.add_state(States.IDLE)
##@onready var move_state : StateNode = state_root.add_state(States.MOVE)
##@onready var jump_state : StateNode = state_root.add_state(States.JUMP)
### 或者
##@onready var state_list = state_root.add_multi_states(States.values())
##[/codeblock]
##
##[br]启动或切换状态
##[codeblock]
### 启动 idle 状态
##state_root.enter_child_state(States.IDLE)
##
### === 切换到 Move 状态的几种方式 ===
### Idle 状态切换到 Move 状态
##idle_state.trans_to(States.MOVE)
### 或者 state_root 对子状态进行切换，切换到 Move 状态
##state_root.trans_to_child(State.Move)
### 或者使用 trans_to_self 方法从其他状态切换到 Move 状态
##move_state.trans_to_self()
##[/codeblock]
class_name StateNode
extends MyNode


## 进入当前状态
signal entered_state()
## 执行线程，这个是物理线程 _physics_process
signal state_processed()
## 退出当前状态
signal exited_state
## 子节点进入状态
signal child_state_entered(state_name)
## 子节点退出状态
signal child_state_exited(state_name)
## 状态发生切换。[param previous_state_name] 上个状态名称，[param current_state_name] 当前状态名
signal child_state_changed(previous_state_name, current_state_name)

## 新增状态
signal newly_added_state(state_name)
## 移除状态
signal removed_state(state_name)

## 自动扫描子节点。如果子节点是 [StateNode] 类型的节点，则会自动注册为子状态节点
@export var auto_scan_children: bool = true

var _root_state : StateNode: # 根节点状态
	set(v):
		if _root_state:
			_root_state.set_physics_process(false)
		_root_state = v
		_root_state.set_physics_process(true)
var _state_name # 当前状态名称
var _parent_state : StateNode # 父状态节点
var _name_to_state_node : Dictionary = {} # 名称对应的状态节点

var _last_enter_data : Dictionary = {} # 最后一次进入状态时的数据
var _current_child_state : Variant = null # 当前执行的子状态名
var _entered_physics_frames: int = 0 # 登录时的物理帧数（计算时间）


## 获取状态。通过枚举添加时使用这个进行获取会很方便。
func get_state_node(state_name) -> StateNode:
	return _name_to_state_node.get(state_name)

## 是否存在有这个子状态
func has_state(state_name) -> bool:
	return _name_to_state_node.has(state_name)

## 获取子状态名列表
func get_state_name_list() -> Array:
	return _name_to_state_node.keys()

## 获取当前执行的子级状态名称
func get_current_child_state():
	return _current_child_state

## 是否和当前状态相同
func equals_current_child_state(state_name) -> bool:
	return str(_current_child_state) == str(state_name)

## 获取当前运行的状态子节点
func get_current_child_state_node() -> StateNode:
	return get_state_node(_current_child_state) \
		if _current_child_state != null \
		else null

## 获取进入这个状态时的数据。如果是根状态节点，可以当做一个全局的数据
func get_last_data() -> Dictionary:
	return _last_enter_data

## 获取父状态
func get_parent_state() -> StateNode:
	return _parent_state

## 当前状态是否正在运行中
func is_running() -> bool:
	return (_root_state == self 
		or (_parent_state.is_running() and _parent_state.equals_current_child_state(self._state_name))
	)

## 获取根节点状态
func get_root_state_node() -> StateNode:
	return _root_state

## 获取自身状态名称
func get_self_state_name():
	return _state_name

## 查找子状态节点
##[br]
##[br][code]state_name[/code]  状态名，注意大小写和注册时的状态名保持一致
##[br][code]from_parent[/code]  从这个状态开始。不传入默认为当前根节点
##[br][code]return[/code]  返回找到的状态节点
func find_state_node(state_name) -> StateNode:
	return _find_state_node(state_name, _root_state)

func _find_state_node(state_name, from_parent: StateNode) -> StateNode:
	assert(from_parent != null, "父状态节点不能为空")
	if from_parent.has_state(state_name):
		return from_parent.get_state_node(state_name)
	var state_node : StateNode
	for child_state_name in from_parent.get_state_name_list():
		state_node = _find_state_node(state_name, from_parent.get_state_node(child_state_name))
		if state_node != null:
			return state_node
	return null


## 获取所有父节点的名称
func get_all_parent_state_name() -> Array:
	if self == _root_state:
		return []
	var list : Array = []
	var p = self
	while p != _root_state:
		list.append(p.get_parent_state().get_child_state_name(p))
		p = p.get_parent_state()
	list.reverse()
	return list


## 获取所有父级祖父级节点
##[br]
##[br][b]注意：[/b] 不包含根节点
func get_all_parent_state_node() -> Array[StateNode]:
	if self == _root_state:
		return []
	var list : Array = []
	var p = self
	while p != null:
		list.append(p.get_parent_state())
		p = p.get_parent_state()
	list.reverse()
	return list

## 获取登录这个状态时的物理时间
func get_entered_time() -> float:
	return float(_entered_physics_frames) / Engine.physics_ticks_per_second

## 获取登录这个状态时已经过的物理时间
func get_entered_pass_time() -> float:
	return float(Engine.get_physics_frames() - _entered_physics_frames) / Engine.physics_ticks_per_second

## 获取登录时的经过的物理帧数（可计算出对应时间）
func get_entered_frames() -> int:
	return _entered_physics_frames


#============================================================
#  内置
#============================================================
func state_process(delta):
	_state_process(delta)
	if _current_child_state:
		get_current_child_state_node().state_process(delta)
	self.state_processed.emit()


func _notification(what):
	match what:
		NOTIFICATION_PHYSICS_PROCESS:
			if self == _root_state:
				state_process(get_physics_process_delta_time())
		
		NOTIFICATION_READY:
			set_physics_process.call_deferred(_root_state == self)
			set_process.call_deferred(_root_state == self)
			# 是根节点时自动进入这个状态
			if _root_state == self:
				enter_state({})
		
		NOTIFICATION_ENTER_TREE:
			# 自动判断是否是状态根节点
			var p = self
			while p is StateNode:
				_root_state = p
				p = p.get_parent()
			if auto_scan_children:
				for child in get_children():
					if child is StateNode:
						register_state(child.name, child)


#============================================================
#  自定义
#============================================================
## 注册状态
func register_state(state_name, state_node: StateNode) -> bool:
	if not _name_to_state_node.has(state_name):
		# 连接信号
		state_node.entered_state.connect( self.child_state_entered.emit.bind( state_name ) )
		state_node.exited_state.connect( self.child_state_exited.emit.bind( state_name ) )
		
		# 存储数据
		_name_to_state_node[state_name] = state_node
		state_node._parent_state = self
		state_node._state_name = state_name
		
		self.newly_added_state.emit(state_name)
		return true
	else:
		printerr("已经添加过 " + str(state_name) + " 状态，添加失败")
		return false


## 添加状态
##[br]
##[br]- [param state_name]  状态名。可以是任意类型
##[br]- [param state_node]  指定的状态节点
##[br]- [param auto_add_node]  如果这个状态还没有添加到场景树中，则自动添加
##[br]
##[br][code]return[/code]  返回添加的状态节点
func add_state(state_name, state_node: StateNode = null, auto_add_node: bool = true) -> StateNode:
	if not has_state(state_name):
		if state_node == null:
			state_node = StateNode.new()
			state_node.name = str(state_name)
		if auto_add_node and not state_node.is_inside_tree():
			add_child(state_node, true)
		register_state(state_name, state_node)
	return get_state_node(state_name)

func get_state_or_add(state_name, state_node: StateNode = null, auto_add_node: bool = true) -> StateNode:
	if has_state(state_name):
		return get_state_node(state_name)
	return add_state(state_name)

## 添加状态数据
##[br]
##[br][param name_to_node]  状态名对应的状态节点
func add_state_data(name_to_node: Dictionary):
	for state_name in name_to_node:
		add_state(state_name, name_to_node[state_name])


## 添加多个状态节点
##[br]
##[br][param list]  状态名列表
##[br]
##[br][code]return[/code]  返回对应状态节点列表
func add_multi_states(list: Array) -> Array[StateNode]:
	var nodes : Array[StateNode] = []
	for state in list:
		if not _name_to_state_node.has(state):
			nodes.append(add_state(state))
	return nodes


## 移除状态
func remove_state(state_name) -> bool:
	if has_state(state_name):
		assert(_current_child_state != state_name, "当前状态正在运行！")
		self.removed_state.emit(state_name)
		_name_to_state_node.erase(state_name)
		return true
	return false


## 进入子状态
func enter_child_state(state_name, data: Dictionary = {}) -> void:
	assert(is_inside_tree(), "此节点还未添加到场景中")
	if typeof(state_name) == typeof(_current_child_state) and state_name == _current_child_state:
		push_error("已经在这个状态中，不能重复切换. state name: %s" % [state_name] )
		return 
	
	assert(_name_to_state_node.has(state_name), "没有这个状态")
	assert(is_running(), "当前状态(%s)还未启动！" % [ get_self_state_name() ])
	
	if _current_child_state:
		trans_to_child(state_name, data)
	
	else:
		_current_child_state = state_name
		get_current_child_state_node().enter_state(data)

## 退出子状态
func exit_child_state() -> void:
	if _current_child_state:
		get_current_child_state_node().exit_state()
		_current_child_state = null

## 执行的状态转换到自己这个状态
func trans_to_self(data: Dictionary = {}, parent_auto_enter: bool = false):
	var parent_state = get_parent_state()
	if parent_state:
		if parent_auto_enter:
			parent_state.trans_to_self({}, true)
		else:
			assert(parent_state.is_running(), "父节点的状态没有启动")
		parent_state.trans_to_child(_state_name, data)
	else:
		self.enter_state(data)

## 当前子状态切换到另一种状态
func trans_to_child(
	state_name, 
	data: Dictionary = {}, 
	ignore_running : bool = true ## 忽略是否已在这个状态中
) -> void:
	#assert(self.is_inside_tree(), "此状态还未添加到树中")
	assert(is_running(), "当前状态还未启动")
#	assert(_current_child_state != null, "子状态机还未启动，请使用 enter_child_state 先启动子节点")
	assert(_name_to_state_node.has(state_name), "没有这个状态(%s)" % [ state_name ])
	if not ignore_running:
		assert(typeof(state_name) != typeof(_current_child_state) or state_name != _current_child_state, "已经在这个状态中，不能重复切换")
	else:
		if typeof(state_name) == typeof(_current_child_state) and state_name == _current_child_state:
			return 
	
	# 退出上次状态
	var previous_state = _current_child_state
	if typeof(_current_child_state) != TYPE_NIL:
		get_current_child_state_node().exit_state()
	# 进入当前状态
	_current_child_state = state_name
	get_current_child_state_node().enter_state(data)
	
	self.child_state_changed.emit( previous_state, state_name )


## 将当前状态切换到同级的其他状态中
func trans_to(state, data: Dictionary = {}) -> void:
	assert(_root_state != self, "当前是根状态，不能切换到其他状态")
	assert(get_parent_state().get_current_child_state_node() == self, "当前状态没有运行，不能切换这个状态")
	assert(is_running(), "当前状态还未启动")
	
	get_parent_state().trans_to_child(state, data)


## 全局切换状态
func global_trans_to(state_name, data: Dictionary) -> void:
	var state_node = find_state_node(state_name)
	assert(state_node, "没有这个状态")
	
	var list = state_node.get_all_parent_state_node()
	list.reverse()
	# 逐个进入
	var curr_state_name = state_name
	for parent_state_node in list:
		parent_state_node.enter_child_state(curr_state_name)
		curr_state_name = parent_state_node.get_self_state_name()


## 进入当前状态。调用这个方法时不会影响到父状态的功能，如果是从父状态切换到这个状态中，
##请使用父状态的 [method trans_to_child] 方法或 [method trans_to_self] 方法切换到
##当前这个状态。
##[br]
##[br][param data]  进入时的数据。可使用 [method get_last_data] 获取这个数据
func enter_state(data: Dictionary) -> void:
	#assert(self.is_inside_tree(), "状态还未添加到节点树中")
	
	_last_enter_data = data
	_entered_physics_frames = Engine.get_physics_frames()
	
	set_physics_process(true)
	set_process(true)
	_enter_state()
	self.entered_state.emit()

## 退出当前状态
func exit_state() -> void:
	#assert(self.is_inside_tree(), "状态还未添加到节点树中")
	assert(_root_state != self, "根状态节点不能退出")
	assert(is_running(), "退出前状态必须是启动的")
	
	exit_child_state()
	
	set_physics_process(false)
	set_process(false)
	
	_exit_state()
	self.exited_state.emit()


## 虚方法，专门用于重写
func _enter_state():
	pass

## 虚方法，专门用于重写
func _state_process(delta):
	pass

## 虚方法，用于重写
func _exit_state():
	pass
