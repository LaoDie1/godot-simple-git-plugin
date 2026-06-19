#============================================================
#    Text Edit Submit Wrapper
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-14 14:47:26
# - version: 4.4.0.dev
#============================================================
## 当用按下 Enter 键时，会发处提交信号，并且不会产生回车的输入
class_name TextEditSubmitWrapper
extends Object


signal text_submitted(new_text: String)

var text_edit: TextEdit


func _init(text_edit: TextEdit = null):
	self.text_edit = text_edit
	self.text_edit.gui_input.connect(self._gui_input)


static func create(text_edit: TextEdit) -> TextEditSubmitWrapper:
	return TextEditSubmitWrapper.new(text_edit)


func _gui_input(event) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER and not (
			event.alt_pressed or event.ctrl_pressed or event.shift_pressed
		):
			text_submitted.emit(text_edit.text)
			text_edit.get_tree().root.set_input_as_handled()
