#============================================================
#    Auto Wired
#============================================================
# - author: zhangxuetu
# - datetime: 2025-05-19 15:19:11
# - version: 4.2.1
#============================================================
# - datetime: 2026-05-15 21:29:40
# - version: 4.7.0.beta1
#============================================================
## 继承这个节点。开启 Apprentice 插件，在项目启动后会自动注入属性到这个脚本里的静态变量里
class_name Autowired
extends Object


static func _static_init() -> void:
	# 设置所有继承 Autowired 类的脚本，初始化静态属性变量
	var dict = ScriptUtil.get_child_script_class_dict()
	for child_class in dict.get("Autowired", []):
		var script := ScriptUtil.get_script_class(child_class) as Script
		ScriptUtil.init_static_var(script, script._get_value)


## 在自动注入时，对变量进行赋值的值。可重写更改赋值的内容
##[br]
##[br]- [param script]  注入的脚本对象
##[br]- [param path]  注入的类的路径。在这个脚本中的内部类的层级
##[br]- [param property_name]  要注入静态属性名
##[br]- [param return]  返回要注入的值
static func _get_value(script: Script, path: String, property_name: String) -> Variant:
	return StringName(property_name.to_lower())
