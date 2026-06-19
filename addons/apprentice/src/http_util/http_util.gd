#============================================================
#    Http Util
#============================================================
# - author: zhangxuetu
# - datetime: 2024-11-26 19:02:06
# - version: 4.3.0.stable
#============================================================
class_name HTTPUtil


static var _http_request_map : Dictionary = {}


## 获取新的 [HTTPRequest] 请求。
static func get_http_request(id = "") -> HTTPRequest:
	if not _http_request_map.has(id):
		var http_request = HTTPRequest.new()
		http_request.name = "http_util"
		Engine.get_main_loop().current_scene.add_child(http_request)
		_http_request_map[id] = http_request
	return _http_request_map[id]


## 发送 http 请求，[code]method[/code] 方法需要有一个 [HTTPResponse] 类型
##的参数接收响应的数据
static func request(url: String, method: Callable):
	var hr : HTTPRequest = get_http_request(url)
	hr.request_completed.connect(
		func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
			var response := HTTPResponse.new()
			response.result = result
			response.code = response_code
			response.headers = headers
			response.body = body
			method.call(response)
	, Object.CONNECT_ONE_SHOT)
	var error : int = hr.request(url)
	if error != OK:
		push_error(error, " ", error_string(error))


static var _url_to_icon_cache : Dictionary = {}
## 找到这个网址的图标数据。method 需要有一个 [PackedByteArray] 类型的参数接收图片数据。
##[br]
##[br] - 可以使用 [method FileUtil.load_image_by_buffer] 获取到这个数据的 [Image]
##[br] - 如果数据为空，则代表没有获取到
static func find_icon_url(url: String, method: Callable) -> void:
	if not _url_to_icon_cache.has(url):
		request(url, func(response: HTTPResponse):
			var html : String = response.body.get_string_from_ascii()
			var icon_url : String = find_icon_url_by_html(html)
			if not icon_url.is_empty():
				_url_to_icon_cache[url] = icon_url
				request(icon_url, func(response: HTTPResponse):
					method.call(response.body)
				)
			else:
				method.call(PackedByteArray())
		)
	else:
		request(_url_to_icon_cache[url], func(response: HTTPResponse):
			method.call(response.body)
		)


## 找到 html 中的图标网址
static func find_icon_url_by_html(html_content: String) -> String:
	var start_index : int = html_content.find("<link rel=\"icon")
	if start_index == -1:
		start_index = html_content.find("<link rel=\"shortcut icon")
	if start_index != -1:
		var end_index : int = html_content.find(">", start_index)
		var link_tag : String = html_content.substr(start_index, end_index - start_index + 1)
		var href_index : int = link_tag.find("href=\"")
		if href_index != -1:
			var icon_link = link_tag.substr(href_index + 6, link_tag.length())
			end_index = icon_link.find("\"")
			return icon_link.substr(0, end_index)
	return ""
