#============================================================
#    Stable Random Generator
#============================================================
# - author: zhangxuetu
# - datetime: 2025-07-02 19:44:16
# - version: 4.4.1.stable
#============================================================
## 稳定的随机数生成器。内置的 [RandomNumberGenerator] 类生成的数字有时候会因为脚本发生改变，
##造成生成的结果不稳定。
class_name StableRandomGenerator

var seed: int = 0:
	set(v):
		seed = v
		_current = seed
var _current: int


# 线性同余生成器
func randi() -> int:
	_current ^= _current << 13
	_current ^= _current >> 17
	_current ^= _current << 5
	return _current & 0x7fffffff  # 保持为正数

func randf() -> float:
	return float(self.randi()) / float(0x7fffffff)

func randf_range(from: float, to: float) -> float:
	return from + self.randf() * (to - from)

func randi_range(from: int, to: int) -> int:
	return from + (float(self.randi()) / 0x7fffffff) * (to - from)

func pick_random(list: Array) -> Variant:
	if list.is_empty():
		return null
	return list[ self.randi_range(0, list.size()-1) ]

func rand_weighted(weights: PackedFloat32Array) -> int:
	if weights.is_empty():
		return -1
	var list := PackedFloat32Array()
	var v : float = 0.0
	for weight in weights:
		v += weight
		list.append(v)
	var rn = randf_range(0, list[list.size() - 1])
	for i in list.size():
		if rn < list[i]:
			return i
	return -1
