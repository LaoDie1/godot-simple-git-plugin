#============================================================
#    Markdown Parser
#============================================================
# - author: zhangxuetu
# - datetime: 2024-12-10 00:57:30
# - version: 4.3.0.stable
#============================================================
## Markdown 解析器
class_name MarkdownParser


## 解析 markdown 数据，返回解析后的 [MarkdownParser.Document] 对象
static func parse(text: String) -> Document:
	return Document.new(text.to_utf8_buffer())

static func parse_file(path: String) -> Document:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		return Document.new(FileAccess.get_file_as_bytes(path))
	return null


class Document:
	
	## 行数据列表
	var lines : Array[LineItem] = []
	
	func _init(code: PackedByteArray) -> void:
		var point := 0
		while point < code.size():
			#if lines.size() > 0 and not lines.back().text.is_empty():
				#print(">>> line = ", lines.size())
			var line = LineItem.new(point, code)
			lines.push_back(line)
			point = line.end + 1


class Token:
	#行开头
	const LINE_HEAD = [
		KEY_NUMBERSIGN,   #"#" 
		KEY_GREATER,      #">" 
		
		# 无序列表
		KEY_ASTERISK,     #"*"
		KEY_PLUS,         #"+"
		KEY_MINUS,        #"-" 
	] 
	
	#块内
	const BLOCK = [
		#斜体、加粗
		KEY_ASTERISK,     #"*"
		KEY_UNDERSCORE,   #"_"
		
		KEY_ASCIITILDE,   #"~"  #删除线
		KEY_QUOTELEFT,    #"`"  #代码、代码块
		KEY_EXCLAM,       #"!"  #图片
		KEY_BRACKETLEFT,  #"["  #链接
		KEY_BAR,          #"|"  #单元格
	] 


enum BlockType {
	TEXT = 0,
	ITALIC = 1 << 0,  ##斜体
	BOLD = 1 << 1,  ##加粗
	DELETE_LINE = 1 << 2, ##删除线
	IMAGE = 1 << 3,  ##图片
	CODE = 1 << 4,  ##代码
	CODE_BLOCK = 1 << 5,  ##代码块
	LINK = 1 << 6,  ##链接
	TABLE = 1 << 7,  ##表格
}

enum LineType {
	TEXT,  ##普通文本
	TITLE, ##标题
	QUOTE, ##引用
	ORDER_LIST, ##有序列表
	UNORDER_LIST, ##无序列表
	CODE_BLOCK, ##代码块
}


class Line:
	extends BaseParserItem
	
	var data : Dictionary = {}
	var blocks : Array = [] ##行内文字块列表
	
	#var type: int = LineType.TEXT
	#var tag  ##类型标记
	#var indent: int   ##空白字符缩进量
	#var start : int
	#var end : int
	#var content: String  ##实际的内容
	#var text: String  ##显示的内容
	
	
	func _init(point: int, code: PackedByteArray) -> void:
		data["start"] = point
		next_blank()
		var begin : int = point
		if Token.LINE_HEAD.has(code[point]):
			var token_char : int = code[point]
			while point < code.size() and code[point] == token_char:
				point += 1
			match token_char:
				KEY_NUMBERSIGN: 
					data["type"] = LineType.TITLE
				KEY_ASTERISK, KEY_PLUS, KEY_MINUS: 
					data["type"] = LineType.UNORDER_LIST
				KEY_GREATER:
					data["type"] = LineType.QUOTE
				_:
					push_error("没有判断这种类型: ", get_string(begin, point))
			data["tag"] = get_string(begin, point)
		
		elif is_number(code[point]):
			while is_number(code[point]):
				point += 1
			if code[point] == KEY_PERIOD:
				data["type"] == LineType.ORDER_LIST
				data["tag"] = get_string(begin, point)
		
		# 分析块代码
		next_blank()
		var list = []
		while point < code.size() and not is_line_break(code[point]):
			
			
			point += 1
		
		
		#region
		#var non_blank_point : int = CharUtil.find_non_blank_point(point, code) # 空白字符缩进
		#self.indent = non_blank_point - 1 - point
		## 行类型
		#point = non_blank_point
		#var text_point: int = point  #显示的正文指针
		#if Token.LINE_HEAD.has(code[point]):
			#var token : int = code[point]
			#point = CharUtil.find_discontinuous_char_point(point, code, token)
			#text_point = point
			#var type_code : PackedByteArray = code.slice(non_blank_point, point)
			#match type_code[0]:
				#KEY_NUMBERSIGN: 
					#self.type = LineType.TITLE
					#self.tag = type_code.size()
				#KEY_ASTERISK, KEY_PLUS, KEY_MINUS: 
					#self.type = LineType.UNORDER_LIST
				#KEY_GREATER:
					#self.type = LineType.QUOTE
				#_:
					#push_error("没有判断这种类型: ", type_code.get_string_from_utf8())
			#
		#elif code[point] >= KEY_0 and code[point] <= KEY_9:
			## 有序列表
			#while (
				#point < code.size()
				#and (code[point] >= KEY_0 and code[point] <= KEY_9)
			#):
				#point += 1
			## 数字后跟着 . 代表有序列表
			#if code[point] == KEY_PERIOD:
				#self.type = LineType.ORDER_LIST
				#text_point = point + 1
		#
		## 行结尾
		#while point < code.size() and not CharUtil.is_line_break(point, code):
			#point += 1
		#self.end = point
		#
		## 行内字符块
		#var block_point : int = text_point
		#if CharUtil.is_blank(block_point, code):
			#block_point += 1
		#var current_tags : Array = []
		#while block_point < self.end:
			#var block : BlockItem = BlockItem.new(block_point, code)
			## 合并 text 
			#if block.type == BlockType.TEXT and not blocks.is_empty() and blocks.back().type == BlockType.TEXT:
				#var last = blocks.back() as BlockItem
				#last.end = block.end
				#last.text += block.text
				#block = last
			#else:
				#self.blocks.push_back(block)
			##prints("%-5d %-5d %-12s %s" % [block.start, block.text.length(), block.type, block.text])
			#if block_point != block.end:
				#block_point = block.end
			#else:
				#block_point += 1
		#
		#if blocks.size() == 1 and blocks[0].type == BlockType.CODE_BLOCK:
			#self.type = LineType.CODE_BLOCK
		#
		#self.end = block_point
		#self.text = code.slice(text_point, end).get_string_from_utf8()
		#endregion
	
	func _to_string() -> String:
		return "<LineItem#%d>" % get_instance_id()

class Block:
	extends BaseParserItem
	
	var data : Dictionary = {}
	
	




#region 废弃代码
class CharUtil:
	const KEY_NEW_LINE = 10    # \n
	const KEY_LINE_FEED = 13   # \r
	
	## 是 token
	static func is_token_char(point: int, code: PackedByteArray) -> bool:
		return (
			(Token.BLOCK.has(code[point]) or Token.LINE_HEAD.has(code[point]))
			and point > 1
			and code[point-1] != KEY_BACKSLASH # 特殊字符前一个不是 \ 
		)
	
	## 是换行符
	static func is_line_break(point: int, code: PackedByteArray) -> bool:
		return point == -1 or code[point] == KEY_NEW_LINE or code[point] == KEY_LINE_FEED
	
	## 是空白字符
	static func is_blank(point:int, code: PackedByteArray) -> bool:
		return code[point] == KEY_SPACE or code[point] == KEY_TAB
	
	## 从 point 位置（不包括 point）开始，前面都是空白字符
	static func is_blank_front(point:int, code: PackedByteArray) -> bool:
		point -= 1
		while point > -1:
			if is_blank(point, code):
				point -= 1
			elif is_line_break(point, code):
				return true
			else:
				return false
		if point == -1:
			return true
		return false
	
	## 从 point 位置（包括 point）开始，找到非空白字符的位置（找到的位置为最后一个空白位置+1的值）
	static func find_non_blank_point(point:int, code: PackedByteArray) -> int:
		while point < code.size() and is_blank(point, code):
			point += 1
		return point
	
	## 从 point 位置（包括 point）开始，找到这个字符串的位置，包括 point 这个字符串也作判断。
	##如果 [code]exclude_line_break[/code] 为 [code]true[/code] 则包括换行符
	static func find_next_char_point(point:int, code: PackedByteArray, char: int, exclude_line_break: bool = false) -> int:
		if not exclude_line_break:
			while point < code.size() and code[point] != char and not is_line_break(point, code):
				point += 1
		else:
			while point < code.size() and code[point] != char:
				point += 1
		return point
	
	## 从 point 位置（包括 point）开始，找到不连续字符的位置
	static func find_discontinuous_char_point(point: int, code: PackedByteArray, char: int) -> int:
		while point < code.size() and code[point] == char:
			point += 1
		return point
	
	## 从 point 位置（包括 point）开始，找到换行符的位置（找到的位置为最后一个换行符位置+1的值）
	static func find_next_line_break_point(point:int, code: PackedByteArray) -> int:
		while point < code.size() and not is_line_break(point, code):
			point += 1
		return point + 1
#endregion


class LineItem:
	var type: int = LineType.TEXT
	var tag  ##类型标记
	var indent: int   ##空白字符缩进量
	var start : int
	var end : int
	var content: String  ##实际的内容
	var text: String  ##显示的内容
	
	##行内文字块列表
	var blocks : Array[BlockItem] = []
	
	func _init(point: int, code: PackedByteArray) -> void:
		self.start = point
		# 空白字符缩进
		var non_blank_point : int = CharUtil.find_non_blank_point(point, code)
		self.indent = non_blank_point - 1 - point
		# 行类型
		point = non_blank_point
		var text_point: int = point  #显示的正文指针
		if Token.LINE_HEAD.has(code[point]):
			var token : int = code[point]
			point = CharUtil.find_discontinuous_char_point(point, code, token)
			text_point = point
			var type_code : PackedByteArray = code.slice(non_blank_point, point)
			match type_code[0]:
				KEY_NUMBERSIGN: 
					self.type = LineType.TITLE
					self.tag = type_code.size()
				KEY_ASTERISK, KEY_PLUS, KEY_MINUS: 
					self.type = LineType.UNORDER_LIST
				KEY_GREATER:
					self.type = LineType.QUOTE
				_:
					push_error("没有判断这种类型: ", type_code.get_string_from_utf8())
			
		elif code[point] >= KEY_0 and code[point] <= KEY_9:
			# 有序列表
			while (
				point < code.size()
				and (code[point] >= KEY_0 and code[point] <= KEY_9)
			):
				point += 1
			# 数字后跟着 . 代表有序列表
			if code[point] == KEY_PERIOD:
				self.type = LineType.ORDER_LIST
				text_point = point + 1
		
		# 行结尾
		while point < code.size() and not CharUtil.is_line_break(point, code):
			point += 1
		self.end = point
		
		# 行内字符块
		var block_point : int = text_point
		if CharUtil.is_blank(block_point, code):
			block_point += 1
		var current_tags : Array = []
		while block_point < self.end:
			var block : BlockItem = BlockItem.new(block_point, code)
			# 合并 text 
			if block.type == BlockType.TEXT and not blocks.is_empty() and blocks.back().type == BlockType.TEXT:
				var last = blocks.back() as BlockItem
				last.end = block.end
				last.text += block.text
				block = last
			else:
				self.blocks.push_back(block)
			#prints("%-5d %-5d %-12s %s" % [block.start, block.text.length(), block.type, block.text])
			if block_point != block.end:
				block_point = block.end
			else:
				block_point += 1
		
		if blocks.size() == 1 and blocks[0].type == BlockType.CODE_BLOCK:
			self.type = LineType.CODE_BLOCK
		
		self.end = block_point
		self.text = code.slice(text_point, end).get_string_from_utf8()
	
	func _to_string() -> String:
		return "<LineItem#%d>" % get_instance_id()


class BlockItem:
	var type : int = BlockType.TEXT
	var tag  ##类型标记
	var start : int
	var end : int
	var text: String
	var data : Dictionary = {}
	
	func _init(point: int, code: PackedByteArray) -> void:
		if code.is_empty():
			return
		
		# 判断字符块类型
		self.start = point
		self.type = BlockType.TEXT
		point = CharUtil.find_non_blank_point(point, code) # 到达非字符的位置
		if code[point] in [KEY_ASTERISK, KEY_UNDERSCORE]:
			# 斜体/加粗
			var char = code[point]
			point = CharUtil.find_discontinuous_char_point(point, code, char)
			match (point - self.start):
				1: self.type = BlockType.ITALIC
				2: self.type = BlockType.BOLD
				_: self.type = BlockType.ITALIC | BlockType.BOLD
			if self.type != BlockType.TEXT:
				while (
					point < code.size()
					and code[point] != char
					and not CharUtil.is_line_break(point, code)
				):
					point += 1
				point = CharUtil.find_discontinuous_char_point(point, code, char)
			
		elif code[point] == KEY_QUOTELEFT:
			if (point+2 < code.size() 
				and code[point+1] == KEY_QUOTELEFT 
				and code[point+2] == KEY_QUOTELEFT
			):
				# 代码块 ```
				self.type = BlockType.CODE_BLOCK
				point += 3
				var text_begin = point
				while point < code.size():
					if (point+2 < code.size() 
						and CharUtil.is_line_break(point-1, code)
						and code[point+1] == KEY_QUOTELEFT 
						and code[point+2] == KEY_QUOTELEFT
					):
						self.data["code"] = code.slice(text_begin, point).get_string_from_utf8()
						point += 4
						break
					point += 1
				
			else:
				# 代码 `
				point = CharUtil.find_next_char_point(point+1, code, KEY_QUOTELEFT)
				if code[point] == KEY_QUOTELEFT:
					self.type = BlockType.CODE
		
		elif code[point] == KEY_EXCLAM:
			# ![]() 图片
			point = CharUtil.find_non_blank_point(point + 1, code)
			if code[point] == KEY_BRACKETLEFT:  # [ 位置
				var url_begin : int = point + 1
				point = CharUtil.find_next_char_point(point + 1, code, KEY_BRACKETRIGHT) # 找到]位置
				self.data["url"] = code.slice(url_begin, point).get_string_from_utf8()
				point = CharUtil.find_next_char_point(point, code, KEY_PARENLEFT) # 找到(位置
				var descript_begin : int = point + 1
				point = CharUtil.find_next_char_point(point + 1, code, KEY_PARENRIGHT) # 找到)位置
				self.data["description"] = code.slice(descript_begin, point).get_string_from_utf8()
				if not CharUtil.is_line_break(point, code):
					# 图片 ![]()
					self.type = BlockType.IMAGE
					point += 1
				
		elif code[point] == KEY_BRACKETLEFT:
			self.type = BlockType.LINK
			# 链接 []()
			var url_begin = point
			point = CharUtil.find_next_char_point(point, code, KEY_BRACKETRIGHT)
			self.data["url"] = code.slice(url_begin, point).get_string_from_utf8()
			
			point = CharUtil.find_next_char_point(point, code, KEY_PARENLEFT)
			var descript_begin = point + 1
			point = CharUtil.find_next_char_point(point, code, KEY_PARENRIGHT)
			
			self.data["description"] = code.slice(descript_begin, point-1).get_string_from_utf8()
			print(self.data["description"])
			#if code[point] == KEY_PARENLEFT:
				#self.type = BlockType.LINK
				#while (point < code.size() 
					#and code[point] != KEY_PARENRIGHT
					#and not CharUtil.is_line_break(point, code)
				#):
					#point += 1
				#point += 1
			#else:
				#point = parse_normal_text(point, code)
		
		elif code[point] == KEY_BAR and point > 0 and CharUtil.is_line_break(point-1, code):
			# 表格
			type = BlockType.TABLE
			point = CharUtil.find_next_line_break_point(point, code)
			point = CharUtil.find_non_blank_point(point, code) + 1
			while code[point] == KEY_BAR and point > 0 and CharUtil.is_line_break(point-1, code):
				point = CharUtil.find_next_line_break_point(point, code)
				point = CharUtil.find_non_blank_point(point, code) + 1
			point += 1
		
		else:
			var p = parse_normal_text(point, code)
			if p > point:
				point = p
			else:
				point += 1
		
		self.end = point
		self.text = code.slice(start, end).get_string_from_utf8()
	
	func _to_string() -> String:
		return "<BlockItem#%d>" % get_instance_id()
	
	func parse_normal_text(point: int, code: PackedByteArray) -> int:
		# 普通字符串
		self.type = BlockType.TEXT
		while (point < code.size() 
			and not (Token.BLOCK.has(code[point]) and code[point-1] != KEY_BACKSLASH)
			and not CharUtil.is_line_break(point, code)
		):
			point += 1
		return point
