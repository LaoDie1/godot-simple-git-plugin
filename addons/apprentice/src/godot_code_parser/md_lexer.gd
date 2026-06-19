# 2024-12-24 15:38:41
@tool
extends EditorScript
class_name MdLexer


func _run() -> void:
	var code = """参考自：

- 参考配置：[FunASR/runtime/docs/SDK_advanced_guide_offline_zh.md at main · alibaba-damo-academy/FunASR (github.com)](https://github.com/alibaba-damo-academy/FunASR/blob/main/runtime/docs/SDK_advanced_guide_offline_zh.md#如何定制服务部署)
- 参考配置：[FunASR/runtime/quick_start_zh.md at 861147c7308b91068ffa02724fdf74ee623a909e · alibaba-damo-academy/FunASR (github.com)](https://github.com/alibaba-damo-academy/FunASR/blob/861147c7308b91068ffa02724fdf74ee623a909e/runtime/quick_start_zh.md)
- 参考运行命令：[FunASR/runtime/python/websocket/README.md at 861147c7308b91068ffa02724fdf74ee623a909e · alibaba-damo-academy/FunASR (github.com)](https://github.com/alibaba-damo-academy/FunASR/blob/861147c7308b91068ffa02724fdf74ee623a909e/runtime/python/websocket/README.md)
- 便捷部署教程：[FunASR/blob/main/runtime/docs/SDK_tutorial_en_zh.md](https://github.com/modelscope/FunASR/blob/main/runtime/docs/SDK_tutorial_en_zh.md)

> 阿里达摩院

## 服务端

1. item xxxxxxxxx
2. item xxxxxxxxx
3. item xxxxxxxxx

""".to_utf8_buffer()
	
	var lexer = Lexer.new(0, code)
	lexer.parse()
	JsonUtil.print_stringify(lexer.tokens)


static func execute(text: String) -> Lexer:
	var lexer = Lexer.new(0, text.to_utf8_buffer())
	lexer.parse()
	return lexer


class Keys:
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
	
	#行开头
	const LINE_HEAD = [
		KEY_NUMBERSIGN,   #"#" 
		KEY_GREATER,      #">" 
		
		# 无序列表
		KEY_ASTERISK,     #"*"
		KEY_PLUS,         #"+"
		KEY_MINUS,        #"-" 
	] 
	


class Lexer:
	extends BaseParserItem
	
	var tokens: Array = []
	
	func parse():
		var indent: int = 0
		var begin: int = point
		while point < code.size():
			indent = next_blank()
			add_token("INDENT", indent)
			
			# 分析头
			begin = point 
			if Keys.LINE_HEAD.has(code[point]):
				# 行首
				var t_char : int = code[point]
				var type: String = "" #空白默认为 TEXT 类型
				match t_char:
					KEY_NUMBERSIGN:
						type = "TITLE"
					KEY_GREATER:
						type = "QUOTE"
					KEY_ASTERISK, KEY_PLUS, KEY_MINUS:
						type = "UL"
					_:
						breakpoint
				if t_char in Keys.LINE_HEAD:
					while point < code.size() and code[point] == t_char:
						point += 1
				add_token(type, {
					"level": point - begin,
					"text": get_string(begin, point),
				})
			else:
				var type = ""
				if is_number(code[point]):
					begin = point
					while point < code.size() and is_number(code[point]):
						point += 1
					if code[point] == KEY_PERIOD:
						var number : String = get_string(begin, point)
						add_token("OL", number)
			
			# 分析块内容
			next_blank()
			while point < code.size() and not is_line_break(code[point]):
				begin = point 
				if code[point] == KEY_ASTERISK or code[point] == KEY_UNDERSCORE:
					var t_char : int = code[point]
					while point < code.size() and code[point] == t_char:
						point += 1
					var count : int = point - begin
					if count == 1:
						add_token("ITALIC", get_string(begin, point))
					elif count == 2:
						add_token("BOLD", get_string(begin, point))
					elif count == 3:
						add_token("I/B", get_string(begin, point))
					
				elif Keys.BLOCK.has(code[point]):
					var type = "TEXT"
					if code[point] == KEY_EXCLAM and point+1<code.size() and code[point+1] == KEY_BRACKETLEFT:
						# 图片
						point += 1
						var description : String = next_char(KEY_BRACKETRIGHT)
						if not is_line_break(code[point]):
							point += 1
							if point < code.size() and code[point] == KEY_PARENLEFT:
								point += 1
								var link : String = next_char(KEY_PARENRIGHT)
								if code[point] == KEY_PARENRIGHT:
									type = "IMAGE"
									add_token(type, {
										"link": link,
										"description": description,
									})
									point += 1
						
					elif code[point] == KEY_BRACKETLEFT:
						# 链接
						point += 1
						var description : String = next_char(KEY_BRACKETRIGHT)
						if not is_line_break(code[point]):
							point += 1
							if point < code.size() and code[point] == KEY_PARENLEFT:
								point += 1
								var link : String = next_char(KEY_PARENRIGHT)
								if code[point] == KEY_PARENRIGHT:
									type = "LINK"
									add_token(type, {
										"link": link,
										"description": description,
									})
									point += 1
					
					elif code[point] == KEY_QUOTELEFT:
						# 代码块
						if point + 2 < code.size() and code[point+1] == KEY_QUOTELEFT and code[point+2] == KEY_QUOTELEFT:
							point += 3
							var lang = ""
							next_blank()
							if not next_line_break():
								begin = point
								while point < code.size() and not is_line_break(code[point]):
									point += 1
								lang = get_string(begin, point)
							begin = point + 1
							while (point < code.size() 
								and not (
									point + 2 < code.size() 
									and code[point] == KEY_QUOTELEFT 
									and code[point+1] == KEY_QUOTELEFT 
									and code[point+2] == KEY_QUOTELEFT
								)
							):
								point += 1
							if (
								point + 2 < code.size() 
								and code[point] == KEY_QUOTELEFT 
								and code[point+1] == KEY_QUOTELEFT 
								and code[point+2] == KEY_QUOTELEFT
							):
								type = "CODE_BLOCK"
								add_token(type, {
									"lang": lang,
									"code": get_string(begin, point).strip_edges(),
								})
							point += 3
							
						else:
							# 代码
							point += 1
							var code_str = next_char(KEY_QUOTELEFT)
							if code[point] == KEY_QUOTELEFT:
								type = "CODE"
								add_token(type, code_str)
								point += 1
					
					if type == "TEXT":
						if begin != point:
							add_token(type, get_string(begin, point))
						else:
							point += 1
					
				else:
					while point < code.size() and not Keys.BLOCK.has(code[point]) and not is_line_break(code[point]):
						point += 1
					add_token("TEXT", get_string(begin, point))
			
			# 换行
			next_line_break()
			add_token("NEW_LINE", null)
			point += 1
	
	func add_token(type, text):
		tokens.push_back([type, text])
		
