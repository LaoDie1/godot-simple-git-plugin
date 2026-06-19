#============================================================
#    Stable Xor Shift
#============================================================
# - author: zhangxuetu
# - datetime: 2025-06-27 16:00:35
# - version: 4.4.1.stable
#============================================================
class_name StableXorshift

var state: int

func _init(initial_seed: int = 1):
	state = initial_seed
	if state == 0:
		state = 1  # 不能为0

func rand_int() -> int:
	state += 7
	state ^= state << 13
	state ^= state >> 17
	state ^= state << 5
	return state & 0x7fffffff  # 保持为正数

func rand_float() -> float:
	return float(rand_int()) / float(0x7fffffff)
