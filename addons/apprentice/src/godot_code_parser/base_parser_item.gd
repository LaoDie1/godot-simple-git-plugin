#============================================================
#    Base Parser Item
#============================================================
# - author: zhangxuetu
# - datetime: 2024-12-16 16:17:35
# - version: 4.3.0.stable
#============================================================
class_name BaseParserItem


const KEY_SYSTEM_TAB = 9   # \t
const KEY_NEW_LINE = 10    # \n
const KEY_LINE_FEED = 13   # \r


var code : PackedByteArray = PackedByteArray()
var point : int = 0


func _init(point: int, code: PackedByteArray) -> void:
	self.point = point
	self.code = code


## 是换行符
static func is_line_break(key: int) -> bool:
	return key == KEY_NEW_LINE or key == KEY_LINE_FEED

## 是空白字符
static func is_blank(key: int) -> bool:
	return key == KEY_SPACE or key == KEY_SYSTEM_TAB

## 是字母
static func is_letter(key: int) -> bool:
	return (key >= KEY_A and key <= KEY_Z) or (key >= 97 and key <= 122) or key == KEY_UNDERSCORE

## 是数字
static func is_number(key: int) -> bool:
	return key >= KEY_0 and key <= KEY_9

## 单词
static func is_word(key: int) -> bool:
	return is_letter(key) or is_number(key)


func get_slice(begin, end) -> PackedByteArray:
	return code.slice(begin, end)

func get_string(begin, end) -> String:
	return code.slice(begin, end).get_string_from_utf8()

## 移动到整个单词的结束位置
func next_word() -> String:
	assert(is_letter(code[point]), "开始的字符必须是单词字符")
	var last = point
	while point < code.size() and (is_letter(code[point]) or is_number(code[point])):
		point += 1
	return code.slice(last, point).get_string_from_utf8()

## 移动到整个数字的结束位置
func next_number() -> String:
	assert(is_number(code[point]) or code[point] == KEY_MINUS, "开始的字符必须是数字或者减号")
	var last = point
	if code[point] == KEY_MINUS:
		point += 1
	while point < code.size() and (is_number(code[point]) or code[point] == KEY_PERIOD):
		point += 1
	return code.slice(last, point).get_string_from_utf8()

## 移动到下一个缩进字符串
func next_indent() -> String:
	assert(point > 0 or is_line_break(code[point - 1]), "上一个字符必须是换行符")
	var last : int = point
	while point < code.size() and is_blank(code[point]):
		point += 1
	return code.slice(last, point).get_string_from_utf8()

## 移动到这个字符的位置
func next_char(char_v: int) -> String:
	var begin = point
	while point < code.size() and code[point] != char_v and not is_line_break(code[point]):
		point += 1
	return code.slice(begin, point).get_string_from_utf8()

## 空白符。返回其中的字符个数
func next_blank() -> int:
	var line_count: int = 0
	while point < code.size() and is_blank(code[point]):
		point += 1
	return line_count

## 移动到末尾，返回是否移动到了末尾状态
func next_line_break() -> bool:
	if point < code.size():
		while point < code.size() and is_blank(code[point]):
			point += 1
		return is_line_break(code[point])
	return true

func next_value() -> String:
	var begin : int = point
	if is_number(code[point]):
		# 数字值
		return next_number()
		
	elif code[point] == KEY_QUOTEDBL or code[point] == KEY_APOSTROPHE:
		# 字符串
		var quote_char = code[point]
		if point+2 < code.size() and code[point+1]==quote_char and code[point+2]==quote_char:
			# 多行字符串
			point += 3
			while point < code.size() and not (
				code[point] == quote_char 
				and code[point+1]==quote_char 
				and code[point+2]==quote_char
			):
				point += 1
			point += 3
			
		else:
			#单行字符串
			point += 1
			while point < code.size() and code[point] != quote_char and not is_line_break(code[point]):
				point += 1
			point += 1
		return code.slice(begin, point).get_string_from_utf8()
	
	elif is_letter(code[point]):
		# 单词
		return next_word()
	
	elif code[point] == KEY_NUMBERSIGN:
		# 注释
		var last : int = point
		while point < code.size() and not is_line_break(code[point]):
			point += 1
		return code.slice(last, point).get_string_from_utf8()
	
	# 其他
	var last : int = point
	while (point < code.size() 
		and not is_blank(code[point]) 
		and not is_line_break(code[point]) 
		and not code[point] in [KEY_PERIOD, KEY_QUOTEDBL, KEY_APOSTROPHE, KEY_PARENLEFT, KEY_PARENRIGHT, KEY_BRACKETLEFT, KEY_BRACKETRIGHT, KEY_BRACELEFT, KEY_BRACERIGHT]
	):
		point += 1
	if last == point:
		point += 1
	return code.slice(last, point).get_string_from_utf8()
