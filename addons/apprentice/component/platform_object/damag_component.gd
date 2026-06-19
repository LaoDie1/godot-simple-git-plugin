#============================================================
#    Damag Component
#============================================================
# - author: zhangxuetu
# - datetime: 2025-09-08 10:06:01
# - version: 4.4.1.stable
#============================================================
## 伤害组件。一个场景只存放一个即可
class_name DamageComponent
extends MyNode


signal ready_damage(data: Dictionary)  ##准备对目标造成伤害
signal damaged(data: Dictionary)  ##已目标造成伤害
signal ready_take_damage(data: Dictionary)  ##准备受到伤害
signal execute_damage(data: Dictionary) ##执行伤害功能
signal took_damage(data: Dictionary) ##已进行了伤害

const ONLY_ONE_META_KEY = &"_damage_component"


func _enter_tree():
	if owner.has_meta(ONLY_ONE_META_KEY):
		printerr("已存在有 DamageComponent 节点")
	else:
		owner.set_meta(ONLY_ONE_META_KEY, self)


## 对目标造成伤害。这个数据需要有一个 target 键
func damage_to(data: Dictionary):
	assert(data.has("target"), "必须要有 target 数据")
	var target = data["target"] as Node
	if is_instance_valid(target):
		if target.has_meta(ONLY_ONE_META_KEY):
			var target_component = target.get_meta(ONLY_ONE_META_KEY) as DamageComponent
			if target_component:
				data["_source_owner"] = self.owner
				ready_damage.emit(data)
				# 对目标施加伤害
				target_component.take_damage(data)
				damaged.emit(data)


## 造成伤害
func take_damage(data: Dictionary):
	ready_take_damage.emit(data)
	execute_damage.emit(data)
	took_damage.emit(data)
