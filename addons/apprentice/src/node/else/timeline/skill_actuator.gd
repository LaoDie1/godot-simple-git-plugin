#============================================================
#    Skill Actuator
#============================================================
# - datetime: 2022-11-26 00:29:06
#============================================================
##技能执行器
##
##以控制 [TimeLine] 作为基础进行技能功能的实现。先调用 [method set_stages] 方法设置执行阶段，
##再调用 [method add_skill] 进行添加技能。
##[br]
##[br]示例：
##[codeblock]
##var skill_management = SkillActuator.new()
##add_child(skill_management)
### 设置技能执行阶段
##skill_management.set_stages(["ready", "before", "executing", "after", "cooldown", "refresh"])
###添加技能，及对应阶段的时间的数据
##skill_management.add_skill("skill_id", {
##    "name": "skill_id",
##    "ready": 1,
##    "before": 0.2,
##    "executing": 1.0,
##    "after": 0.1,
##    "cooldown": 2.0,
##})
##[/codeblock]
##实现技能的功能效果
##[codeblock]
##var skill = skill_management.get_skill("skill_id")
##skill.executed_stage.connect(
##    func(stage, skill_data: Dictionary):
##        if stage == "execute":
##            # 实现执行时的功能
##            pass
##)
##[/codeblock]
##[br]使用技能时，直接调用 [method execute] 方法
##[codeblock]
##skill_management.execute("skill_id", {})
##[/codeblock]
##
class_name SkillActuator
extends MyNode


## 新增技能
signal newly_added_skill(skill_id)
## 移除技能
signal removed_skill(skill_id)
## 准备执行技能。[b]注意：这个时候技能还未被调用。[/b]
signal ready_execute(skill_id)
## 开始执行技能。[b]注意：这个时候技能执行方法已经被调用，只是还未到正式执行阶段。[/b]
signal started(skill_id)
## 技能执行结束。打断、停止、执行完成 都会发出这个信号。
signal ended(skill_id, end_state: EndState)
## 打断技能
signal interruptted(skill_id)
## 已强行停止技能
signal stopped(skill_id)
## 执行完成
signal finished(skill_id)
## 技能数据发生改变
signal skill_data_changed(skill_id)
signal executed_stage(skill_id, stage, skill_data)


enum {
	UNEXECUTED = -1, ## 未执行
	NON_EXISTENT = -2, ## 技能不存在
}

## 信号结束状态
enum EndState {
	FINISHED,  ## 所有阶段执行完成
	INTERRUPTTED,  ##执行被打断
	STOPPED,  ##停止执行
}


## 技能执行阶段。调用 [method add_skill] 时，传入的 [Dictionary] 数据中的 key 如果有这个阶段的值，
##则获取这个数据的值为播放时间数据，否则播放时间按照 0 的时长的阶段来执行。
@export var stages : Array : set=set_stages
##忽略缺省的数据中的 key。如果这个属性为 [code]true[/code]，
##则在添加技能数据时不再强制要求必须要有这个 key，缺省的值默认为 [code]-1[/code]
@export var ignore_default_key : bool = true
##添加的技能节点的名字变为可读形式
@export var force_readable_name: bool = false
##这个技能在这个阶段的时候可以调用 [method execute] 方法
@export var can_execute_stages : Array = []
##这个技能在这个阶段的时候调用 [method execute] 方法不会成功
@export var can_not_execute_stages : Array = []


# 技能名称对应的技能节点
var _name_to_skill_dict : Dictionary = {}
# 技能名称对应的技能数据
var _name_to_data_dict : Dictionary = {}
# 当前正在执行的技能ID
var _current_execute_skill_ids : Dictionary = {}


#============================================================
#  SetGet
#============================================================
## 获取技能
func get_skill(skill_id) -> TimeLine:
	var skill = _name_to_skill_dict.get(skill_id)
	if skill:
		return skill
	else:
		printerr("没有这个技能：", skill_id)
		return null

## 获取技能名称列表
func get_skill_name_list() -> Array:
	return _name_to_skill_dict.keys()

##设置技能执行几个阶段的值（按顺序），如果不设置则在 [method add_skill] 的时候添加的数据的时
##候没有执行时间
func set_stages(v: Array) -> void:
	stages = v
	var tmp := {}
	for stage in stages:
		assert(not tmp.has(stage), "不能设置有重复的值！")
		tmp[stage] = null


## 获取这个 [code]stage[/code] 索引的阶段的名称
func get_stage_name(stage_idx: int) -> String:
	if stage_idx >= 0 and stage_idx < stages.size():
		return stages[stage_idx]
	return ""

## 获取正在执行的技能ID列表
func get_executing_skills() -> Array:
	return _current_execute_skill_ids.keys()

## 存在有正在执行的技能
func has_executing_skill() -> bool:
	return not _current_execute_skill_ids.is_empty()

## 是否正在执行
##[br]
##[br][code]skill_id[/code]  技能名称
##[br][code]return[/code]  返回这个技能是否正在执行
func is_executing(skill_id) -> bool:
	return _current_execute_skill_ids.has(skill_id)

## 技能能否执行
func is_can_execute(skill_id) -> bool:
	if has_skill(skill_id):
		var stage = get_skill(skill_id).get_current_stage()
		return not is_executing(skill_id) \
			and (can_execute_stages.is_empty() or stage in can_execute_stages) \
			and (can_not_execute_stages.is_empty() or not stage in can_not_execute_stages)
	return false


## 添加技能。技能中需要有 [member stages] 中的 key，比如 [member stages] 属性的值为 [code]
##["ready", "before", "execute", "after"][/code]，则 [code]data[/code] 参数中至少要有
##包含以下的 key 的数据：
##[codeblock]
##{
##  "ready": 0.1,
##  "before": 0,
##  "execute": 1.0,
##  "after": 0,
##}
##[/codeblock]
##[br]用以在执行时判断这些数据的执行阶段和时间，如果设置 [member ignore_default_key] 为 
##[code]true[/code] 则可以忽略
func add_skill(skill_id, data: Dictionary = {}) -> TimeLine:
	if not ignore_default_key:
		assert(data.has_all(stages), "stages 属性中的某些阶段值，数据中不存在这个名称的 key！")
	
	_name_to_data_dict[skill_id] = data
	
	var skill := TimeLine.new()
	skill.process_execute_mode = TimeLine.ProcessExecuteMode.PHYSICS
	skill.stages = stages
	_name_to_skill_dict[skill_id] = skill
	
	if force_readable_name:
		skill.name = str(skill_id)
	self.add_child.call_deferred(skill, force_readable_name)
	
	# 执行时
	skill.ready_execute.connect(
		func(): 
			self._current_execute_skill_ids[skill_id] = null
			self.started.emit(skill_id)
	)
	skill.resumed.connect(func():
		self._current_execute_skill_ids[skill_id] = null
	)
	skill.altered_stage_data.connect(
		func(stage, time):
			skill_data_changed.emit(skill_id)
	)
	skill.executed_stage.connect(_skill_executed_stage.bind(skill_id))
	
	# 执行结束
	var skill_end : Callable = func(signal_name: StringName, end_state):
		self._current_execute_skill_ids.erase(skill_id)
		self.emit_signal(signal_name, skill_id)
		self.ended.emit(skill_id, end_state)
	skill.finished.connect( skill_end.bind("finished", EndState.FINISHED) )
	skill.paused.connect( skill_end.bind("interruptted", EndState.INTERRUPTTED) )
	skill.stopped.connect( skill_end.bind("stopped", EndState.STOPPED) )
	
	# 新增技能
	self.newly_added_skill.emit(skill_id)
	return skill


## 移除技能
func remove_skill(skill_id) -> void:
	_name_to_skill_dict.erase(skill_id)
	self.removed_skill.emit(skill_id)


## 是否有这个技能
func has_skill(skill_id) -> bool:
	return _name_to_skill_dict.has(skill_id)


## 获取技能执行到的阶段。如果没有在执行，则返回 [code]-1[/code]，如果没有这个技能，则返回
##[code]-2[/code]
func get_skill_stage(skill_id) -> int:
	var skill = get_skill(skill_id)
	if skill:
		return skill.get_current_key_index()
	return NON_EXISTENT


## 获取这个技能的数据。可以通过修改这个数据永久改变每次执行的技能的数据，这会对执行 [method execute] 方法时
##默认的技能数据产生影响。如果临时修改，则需要通过 [method TimeLine.update_skill_data] 方法进行修改或通过
## [method get_skill] 方法获取到目标技能对象之后调用 [method TimeLine.get_last_data] 进行获取这个技能的数据。
func get_skill_data(skill_id) -> Dictionary:
	if has_skill(skill_id):
		return _name_to_data_dict[skill_id]
	return {}


## 获取这个技能执行状态的名称
func get_skill_stage_name(skill_id) -> String:
	if has_skill(skill_id):
		var stage = get_skill_stage(skill_id)
		return get_stage_name(stage)
	return ""


## 这个技能当前是否正在这个阶段中运行
func is_in_stage(skill_id, stage_idx: int) -> bool:
	var skill = get_skill(skill_id)
	if skill:
		return skill.get_current_key_index() == stage_idx
	return false


## 执行技能
##[br]
##[br][param skill_id]  技能名称
##[br][param additional]  附加数据。如果技能数据中包含有这个数据，则会被覆盖，相当于修改技能的数据
##[br][param temp_add]  临时添加数据。执行完这个数据不会合并到当前技能数据中
func execute(skill_id, additional: Dictionary = {}, force_merge: bool = true, temp_add: bool = false) -> bool:
	assert(not stages.is_empty(), "没有设置执行阶段的值！")
	var skill := get_skill(skill_id)
	if skill:
		# 从头开始播放 
		if can_execute_stages.is_empty() or skill.get_current_stage() in can_execute_stages:
			var data : Dictionary = get_skill_data(skill_id)
			if temp_add:
				data = data.duplicate()
			if not additional.is_empty():
				data.merge(additional, force_merge)
			ready_execute.emit(skill_id)
			return skill.execute(data)
	return false


## 继续执行技能
func continue_execute(skill_id) -> void:
	var skill = get_skill(skill_id)
	if skill and is_executing(skill_id):
		skill.resume()


## 打断技能，中止技能的执行，可以继续执行
func interrupt(skill_id) -> void:
	var skill = get_skill(skill_id)
	if skill:
		skill.pause()


## 停止技能
func stop(skill_id) -> void:
	var skill = get_skill(skill_id)
	if skill:
		skill.stop()


## 停止执行所有技能
func stop_all() -> void:
	for s in _current_execute_skill_ids:
		stop(s)


## 跳到某个阶段执行
func goto_stage(skill_id, stage) -> void:
	var skill = get_skill(skill_id)
	if skill and skill.is_executing():
		skill.goto(stage)

##  修改技能的数据
##[br]
##[br][param skill_id]  技能的ID
##[br][param skill_data]  技能数据
##[br][param overwrite]  覆盖掉旧的键名数据
func update_skill_data(skill_id, skill_data: Dictionary, overwrite: bool = false):
	var data : Dictionary = _name_to_data_dict.get(skill_id, {})
	var last_hash : int = data.hash()
	data.merge(skill_data, overwrite)
	if data.hash() != last_hash:
		skill_data_changed.emit(skill_id)

func _skill_executed_stage(stage, skill_data, skill_id):
	executed_stage.emit(skill_id, stage, skill_data)
