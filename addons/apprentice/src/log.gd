#============================================================
#    Log
#============================================================
# - author: zhangxuetu
# - datetime: 2023-10-04 00:25:06
# - version: 4.1.1.stable
#============================================================
class_name Log

const LOG_DISPLAY_PATH = "log/display"
const LOG_PRINT_PATH = "log/print_path"

## 日志类型
enum Level { 
	INFO = 0b1,  ##普通信息
	DEBUG = 0b10,   ##测试
	WARNNING = 0b100,  ##警告
	ERROR = 0b1000,  ##错误
	PROMPT = 0b10000, ##提示
	DEVELOPMENT = 0b100000, ##开发阶段
}

const DefaultValue = {
	DISPLAY = Level.INFO | Level.DEBUG | Level.WARNNING | Level.ERROR | Level.PROMPT,
	PRINT_PATH = Level.DEBUG | Level.ERROR,
}

##显示输出内容的日志级别
static var display: int = DefaultValue.DISPLAY
##输出路径的日志级别
static var print_path: int = DefaultValue.PRINT_PATH
## 格式化输出方法。可以修改这个值，以改变输出结果，这个方法需要有一个 params: Array 参数接收数据参数列表
static var format_method : Callable = func(head, params: Array):
	if head is Object:
		head = ScriptUtil.get_info(head)
	head = str(head)
	if params:
		var format_str : String = "%s ".repeat(params.size())
		var head_info : String = ""
		if head:
			head_info = "[ %s ]" % head
		return " - ".join([
			head_info, 
			" ".join(params),
		])
	else:
		return  " %s " % head


static func info(head, ...params : Array) -> void:
	if display & Level.INFO == Level.INFO or Engine.is_editor_hint():
		print_rich("● [b]INFO:[/b] %s" % format_method.call(head, params))
		if print_path & Level.INFO == Level.INFO:
			print("  | <{function}>: {line} : {source}".format( get_stack()[1] ))

static func debug(head, ...params: Array) -> void:
	if display & Level.DEBUG == Level.DEBUG or Engine.is_editor_hint():
		print_rich("● [b]DEBUG:[/b] %s" % format_method.call(head, params))
		if print_path & Level.DEBUG == Level.DEBUG:
			print("  | <{function}>: {line} : {source}".format( get_stack()[1] ))

static func prompt(head, ...params: Array) -> void:
	if display & Level.PROMPT == Level.PROMPT:
		print_rich("[color=7FFF7F]● [b]PROMPT:[/b] %s[/color]" % format_method.call(head, params))
		if print_path & Level.PROMPT == Level.PROMPT:
			print("  | <{function}>: {line} : {source}".format( get_stack()[1] ))

static func warn(head, ...params: Array) -> void:
	if display & Level.WARNNING == Level.WARNNING:
		var v = format_method.call(head, params)
		push_warning(v)
		print_rich("[color=FFDE66]● [b]WARNNING:[/b] %s[/color]" % v)
		if print_path & Level.WARNNING == Level.WARNNING:
			print("  | <{function}> : {line} : {source}".format( get_stack()[1] ))

static func error(head, ...params: Array) -> void:
	if display & Level.ERROR == Level.ERROR:
		var v = format_method.call(head, params)
		push_error(v)
		printerr(v)
		if print_path & Level.ERROR == Level.ERROR:
			print("  | <{function}>: {line} : {source}".format( get_stack()[1] ))

static func dev(head, ...params: Array) -> void:
	if Engine.is_editor_hint():
		print("● DEVELOPMENT: %s - [ %s ] - %s" % [Time.get_datetime_string_from_system(false, true), head, " ".join(params)])
	elif display & Level.DEVELOPMENT == Level.DEVELOPMENT:
		print_rich("[color=C891FFFF]● [b]DEVELOPMENT:[/b] %s[/color]" % format_method.call(head, params))
		if print_path & Level.DEVELOPMENT == Level.DEVELOPMENT:
			print("  | <{function}>: {line} : {source}".format( get_stack()[1] ))


## 格式化输出内容。例：
##[codeblock]
##Log.format(["%-10s"], ["hello world", 1, 2, 3, ])
##[/codeblock]
static func format(format_str: Array, ...params: Array) -> void:
	if format_str.size() <= params.size():
		var item = format_str.back()
		for i in params.size() - format_str.size():
			format_str.push_back(item)
	print("".join(format_str) % params)


## JSON 格式输出
##[br]
##[br]- [param params]  
##[br]- [param indent]  
static func print_json(params, indent: String = "\t") -> void:
	print(JSON.stringify(params, indent))

## 打印时间
static func print_time() -> void:
	print( Time.get_datetime_string_from_system(false, true))

## 输出信息
static func print_dev(object: Node, ...info) -> void:
	var head : String = ScriptUtil.get_info(object)
	dev( head, " ".join( info ))
