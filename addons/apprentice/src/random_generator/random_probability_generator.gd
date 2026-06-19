#============================================================
#    Random Probability Generator
#============================================================
# - author: zhangxuetu
# - datetime: 2023-06-26 01:32:33
# - version: 4.0
#============================================================
## 随机概率值生成器
##
##示例：
##[codeblock]
##var generator = RandomProbabilityGenerator.new({
##    a: 3, # 生成 a 的概率为：3/abc的总和
##    b: 5, # 生成 b 的概率为：5/abc的总和
##    c: 9, # 生成 c 的概率为：9/abc的总和
##})
##[/codeblock]
class_name RandomProbabilityGenerator


var value_list : Array
var probability_list: Array
var sum_value : float = 0.0
var probaility_list : Array[float] = []	# 概率列表
var rng: RandomNumberGenerator


func _init(data: Dictionary, random_number_generator: RandomNumberGenerator = null) -> void:
	set_probability(data)
	if random_number_generator:
		rng = random_number_generator
	else:
		rng = RandomNumberGenerator.new()


## 设置概率数据
func set_probability(data: Dictionary) -> void:
	value_list = data.keys()
	probability_list = data.values()
	
	# 累加概率值，计算概率总和。每次累加存到列表中作为概率区间
	for item in probability_list:
		sum_value += item
		probaility_list.push_back(sum_value)


## 获取随机值
func get_rand_value() -> Variant:
	var random_value : float = rng.randf() * sum_value
	for idx in probaility_list.size():
		# 当前概率超过或等于随机的概率，则返回
		if probaility_list[idx] >= random_value:
			return value_list[idx]
	return null
