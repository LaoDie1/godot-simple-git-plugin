#============================================================
#    Platform Object
#============================================================
# - author: zhangxuetu
# - datetime: 2025-05-11 16:04:24
# - version: 4.2.1
#============================================================
## 平台类型游戏的角色。继承这个脚本和场景。
##
## [br]在这个扩展的脚本中，所有以 [code]p_[/code] 开头的属性，都会自动添加到 [member properties] 属性中
class_name PlatformObject
extends Node2D

## 角色存在的状态类型
const States = {
	NORMAL = "normal", ##正常状态
	SKILL = "skill", ##施放技能状态
	UNCONTROL = "uncontrol",  ##不可控制状态
	DEAD = "dead",  ##死亡状态
}

# < 标准属性 >

@export var body: CharacterBody2D
@export var canvas: Node2D

@export var properties : DynamicProperties  ##当前对象的属性数据
@export var states : StateNode
@export var inventory: DataManagement
@export var move_component: PlatformMoveComponent

var normal_state: StateNode
var skill_state: StateNode
var uncontrol_state: StateNode
var dead_state: StateNode


func _to_string():
	var script : GDScript = get_script() as GDScript 
	var g_name : StringName = script.resource_path.get_basename().get_file().to_pascal_case()
	return "<%s#%d>" % [g_name, get_instance_id()]


func _notification(what):
	if what == NOTIFICATION_ENTER_TREE:
		
		# 添加以 p_ 头的属性为角色的 properties 的属性和默认值
		for p_data in (get_script() as Script).get_script_property_list():
			if (p_data["usage"] & (PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT) == (PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT)
				and p_data["name"].begins_with("p_")
			):
				var p_name : String = str(p_data["name"]).trim_prefix("p_")
				properties.add(StringName(p_name), get(p_data["name"]))
		
		# 添加状态
		normal_state = states.add_state(PlatformObject.States.NORMAL)
		skill_state = states.add_state(PlatformObject.States.SKILL)
		uncontrol_state = states.add_state(PlatformObject.States.UNCONTROL)
		dead_state = states.add_state(PlatformObject.States.DEAD)

## 获取这个节点所属的 [PlatformObject] 对象
static func find_object(node: Node) -> PlatformObject:
	if node:
		if node.owner is PlatformObject:
			return node.owner as PlatformObject
		elif node is PlatformObject:
			return node
		node = node.get_parent()
		while node and node.owner:
			node = node.get_parent()
		return node as PlatformObject
	return null

## 获取面向的方向
##[br]
##[br]- [param offset_distance]  以这个方向进行偏移的值
func get_face_direction(offset_distance: float = 1.0) -> Vector2:
	var direction = move_component.get_last_direction().sign()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	return direction * offset_distance

## 获取面向方向的一段距离的位置
func get_forward_position(distance: float = 0) -> Vector2:
	return (body.global_position + get_face_direction() * distance).round()

## 获取当前位置的偏移之后的位置
func get_body_position(offset: Vector2 = Vector2()) -> Vector2:
	return (body.global_position + offset).round()

func distance_to(target: PlatformObject) -> float:
	return body.global_position.distance_to(target.body.global_position)

func distance_squared_to(target: PlatformObject) -> float:
	return body.global_position.distance_squared_to(target.body.global_position)

func update_direction(direction: Vector2) -> void:
	move_component.update_direction(Vector2(direction.x, 0))

func direction_to(target: PlatformObject) -> Vector2:
	return self.get_body_position().direction_to(target.get_body_position())
