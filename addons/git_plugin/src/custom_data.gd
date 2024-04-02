#============================================================
#    Const
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 21:09:14
# - version: 4.2.1.stable
#============================================================
class_name GitPluginCustomData


#============================================================
#  Enum
#============================================================
static var UpdateCommit : Action



#============================================================
#  Else
#============================================================
class Action:
	func equals(data) -> bool:
		return typeof(data) == TYPE_OBJECT and data == self


static func init():
	# 初始化静态变量
	init_static_var(GitPluginCustomData)


static func init_static_var(script: GDScript, is_path_name: bool = true):
	var var_regex = RegEx.new()
	var_regex.compile("^static\\s+var\\s+(?<var_name>\\w+).*")
	
	# 分析
	var obj = script.new()
	var lines = script.source_code.split("\n")
	var result : RegExMatch
	for line in lines:
		# 变量名
		result = var_regex.search(line)
		if result:
			var var_name = result.get_string("var_name")
			obj[var_name] = GitPluginCustomData.Action.new() # 设置为 Action


