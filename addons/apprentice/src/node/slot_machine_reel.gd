#============================================================
#    Reel Mask
#============================================================
# - author: zhangxuetu
# - datetime: 2025-06-16 17:39:17
# - version: 4.4.1.stable
#============================================================
## 卷筒老虎机
class_name SlotMachineReel
extends Control

signal scrolled_new_item(index)

@export var icon_size: Vector2i = Vector2i(32, 32)
@export var textures : Array[Texture2D] = []:
	set(v):
		if textures != v:
			textures = v
			for child in duplicaties:
				child.queue_free()
			duplicaties.clear()
			_update_container()
@export var scroll: int = 0:
	set(v):
		scroll = v
		# 更新位置
		var height = _group_height
		var pos_y = scroll % _group_height #取余用于还原到重复的位置
		for i in duplicaties.size():
			duplicaties[i].position.y = pos_y + height * (i - 1)
		#当前滚动到的顶部的节点所属索引
		var index = scroll / (icon_size.y + separation)
		if _last_item_index != index:
			_last_item_index = index
			scrolled_new_item.emit(_last_item_index)

var separation: int = 0
var duplicaties : Array[Control] = []
var _last_item_index : int = 0
var _executing : bool = false
var _group_height : int 


func _ready():
	resized.connect(_update_container)
	_update_container()
	_group_height = int(icon_size.y + separation) * textures.size()
	if scroll != 0:
		self.scroll = scroll


# 更新容器
func _update_container():
	if not is_node_ready():
		await ready
	var height = _group_height
	var count = ceili(self.size.y / height) + 1 - duplicaties.size() #需要额外增加的个数
	for i in count:
		# 添加额外的数量。每次添加超出的节点都会判断是否到达边缘
		var pos_y = height * (duplicaties.size() + i - 1)
		var item = _create_new_item_group()
		item.position.y = pos_y
		duplicaties.append(item)
		self.add_child(item)
	for i in duplicaties.size():
		duplicaties[i].position.y = height * (i - 1)

func _create_new_item_group() -> Control:
	var container = VBoxContainer.new()
	for t in textures:
		var texture_rect = TextureRect.new()
		texture_rect.texture = t
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = icon_size
		texture_rect.size = icon_size
		container.add_child(texture_rect)
	container.add_theme_constant_override("separation", separation)
	return container

func is_executing() -> bool:
	return _executing

## 启动
func start(index: int, time : float = 3):
	if is_executing():
		return
	var scroll_value = index * (icon_size.y + separation) #移动到这个索引图标的位置
	_executing = true
	create_tween() \
		.tween_property(self, "scroll", scroll + scroll_value, time) \
		.set_trans(Tween.TRANS_ELASTIC) \
		.set_ease(Tween.EASE_IN_OUT).finished.connect(
			func():
				_executing = false,
		)

## 获取这个图片的索引的节点
func get_item_node_by_index(item_index: int) -> TextureRect:
	var v_i = index_to_view_index(item_index)
	var pos_y = v_i * (icon_size.y + separation) + self.global_position.y
	for g in duplicaties:
		for child in g.get_children():
			if pos_y <= child.global_position.y:
				return child
	return null

## item 的索引在当前看到的视图中所在的索引位置
func index_to_view_index(item_index: int) -> int:
	var page_number = int(self.size.y / (icon_size.y + separation)) #页面节点可容纳的节点数量
	return int(item_index - _last_item_index) % page_number

## 获取这个位置项的索引
func get_index_by_position(global_pos: Vector2):
	var local_pos = global_pos - self.global_position
	var pos_y = scroll + local_pos.y
	return int(pos_y / (icon_size.y + separation))
