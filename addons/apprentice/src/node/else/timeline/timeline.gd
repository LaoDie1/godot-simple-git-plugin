#============================================================
#    Timeline
#============================================================
# - author: zhangxuetu
# - datetime: 2023-09-24 23:10:53
# - version: 4.1
#============================================================
## 执行功能时间线
##
##执行不同时间段的阶段的事务。通过设置 [member stages] 属性，设置数据执行的阶段顺序，
##在调用 [method execute] 方法执行的时候，会根据 [member stages] 顺序执行给予数据的
##消耗的时间，并发出 [signal executed_stage] 信号来响应执行的每个阶段。
class_name TimeLine
extends MyNode


## 准备执行。注意，这个时候还未进入到执行发出 [signal executed_stage] 信号的阶段
signal ready_execute
## 执行完这个阶段时发出这个信号，[kbd]data[/kbd] 数据为调用 [method execute] 方法时的数据
signal executed_stage(stage, data: Dictionary)
## 手动停止执行
signal stopped
## 暂停执行
signal paused
## 继续执行
signal resumed
## 所有阶段执行完成
signal finished
##修改了阶段的时间数据
signal altered_stage_data(stage, time: float)


## process 执行方式
enum ProcessExecuteMode {
	PROCESS, ## _process 执行
	PHYSICS, ## _physics_process 执行
}

enum {
	UNEXECUTED, ## 未执行
	EXECUTING, ## 执行中
	PAUSED, ## 暂停中
}


## 执行时处理的阶段列表，根据 [member stages] 中的阶段名获取执行数据中对应的键名的数据 。这关系到 [method execute] 方法中的数据获取的时间数据
@export var stages : Array = []
## process 执行方式。如果设置为 [enum ProcessExecuteMode.PROCESS] 或 [enum ProcessExecuteMode.PHYSICS] 以外的值，
## 则当前节点的线程将不会执行
@export var process_execute_mode : ProcessExecuteMode = ProcessExecuteMode.PHYSICS

# 当前阶段的剩余时间。修改这个时间会改变剩余时间
var _stage_time_left : float = 0.0
# 上次执行后的数据
var _last_data : Dictionary = {}
# 所在阶段的指针
var _stage_point : int = -1:
	set(v):
		if _stage_point != v:
			_stage_point = v
			if _stage_point >= 0 and _stage_point < stages.size():
				self.executed_stage.emit(stages[_stage_point], _last_data)
var _execute_state : int = UNEXECUTED:  # 当前执行到的阶段
	set(v):
		if _execute_state == v:
			return
		_execute_state = v
		match _execute_state:
			UNEXECUTED, PAUSED:
				set_process(false)
				set_physics_process(false)
			EXECUTING:
				if process_execute_mode == ProcessExecuteMode.PROCESS:
					set_process(true)
				elif process_execute_mode == ProcessExecuteMode.PHYSICS:
					set_physics_process(true)


func _ready():
	self.process_execute_mode = process_execute_mode
	if not is_executing():
		set_process(false)
		set_physics_process(false)

func _process(delta):
	_exec(delta)

func _physics_process(delta):
	_exec(delta)

func _exec(delta):
	_stage_time_left -= delta
	_next()

func _next():
	# 当前阶段执行完时，开始不断向后执行到 时间>0 的阶段
	while _stage_time_left <= 0 and _execute_state == EXECUTING:
		_stage_point = _stage_point +  1
		if _stage_point < stages.size():
			_stage_time_left += _last_data[stages[_stage_point]]
		else:  
			# 所有阶段执行完毕
			_stage_time_left = 0.0
			_stage_point = -1
			_execute_state = UNEXECUTED
			self.finished.emit()
			break


## 获取当前阶段剩余执行时间
func get_time_left() -> float:
	return _stage_time_left

## 获取上次调用 [method execute] 时的数据
func get_last_data() -> Dictionary:
	return _last_data

## 获取当前执行到的阶段
func get_current_stage() -> Variant:
	return stages[_stage_point]

## 修改这个阶段耗费的时间
##[br]
##[br]- [code]stage[/code]  要修改的阶段
##[br]- [code]time[/code]  修改到的时间
##[br]- [code]sync_current_time[/code]  如果修改的阶段当前正在执行，同步修改当前已消耗的时间。多了则同步追加，少了则同步减去
func alter_stage_time(stage, time: float, sync_current_time: bool = false) -> void:
	if (sync_current_time 
		and _stage_point != -1 
		and get_current_stage() == stage
	):
		# 同步修改到当前时间
		_stage_time_left += (time - _last_data[stage])
	if _last_data.get(stage, 0.0) != time:
		_last_data[stage] = time
		altered_stage_data.emit(stage, time)

##执行功能。这个数据里需要有 [member stages] 中的 [code]key[/code] 的数据，且需要是 [int] 或 [float]
##类型作为判断执行的时间。否则默认时间为 0。在 [signal executed_stage] 和 [method get_last_data] 
##中的数据都不是传入前的数据，而是复制后的数据
func execute(data: Dictionary) -> bool:
	assert(is_node_ready(), "节点还未准备好")
	#if not is_node_ready():
		## 必须等待节点 ready 完成之后执行。
		## 如果以 tree_entered 信号，则会出现第一次执行的时间不正确的问题，因为这时候物理线程还未正常调用
		#await ready 
	if data.is_empty():
		push_warning("时间线的执行数据为空")
	_last_data = data
	_stage_point = -1
	_stage_time_left = 0.0
	if not stages.is_empty():
		_execute_state = EXECUTING
		for stage in stages:
			_last_data[stage] = float(data.get(stage, 0))
		self.ready_execute.emit()
		_next.call_deferred() 
		return true
	else:
		printerr("没有设置 stages，必须要设置每个执行的阶段的 key 值！")
	return false

## 获取执行状态
func get_execute_state() -> int:
	return _execute_state

## 是否正在执行
func is_executing() -> bool:
	return _execute_state == EXECUTING

## 停止执行
func stop() -> void:
	if _execute_state == EXECUTING:
		_execute_state = UNEXECUTED
		_stage_time_left = 0.0
		_stage_point = -1
		self.stopped.emit()

## 暂停执行
func pause() -> void:
	if _execute_state == EXECUTING:
		_execute_state = PAUSED
		self.paused.emit()

## 恢复执行
func resume() -> void:
	if _execute_state == PAUSED:
		_execute_state = EXECUTING
		self.resumed.emit()

## 跳跃到这个阶段
func goto(stage, emit_signal_: bool = true) -> void:
	if _execute_state == EXECUTING:
		if stages.has(stage):
			_stage_point = stages.find(stage)
			_stage_time_left = _last_data[stages[_stage_point]]
			if emit_signal_:
				executed_stage.emit(stages[_stage_point], _last_data)
		else:
			push_error("stages 中没有 ", stage, ". 所有 stage: ", stages)
