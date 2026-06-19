#============================================================
#    Smoothed Random
#============================================================
# - author: zhangxuetu
# - datetime: 2025-07-22 06:12:53
# - version: 4.4.1.stable
#============================================================
## 随机分布平滑，避免密集出现
class_name SmoothedRandomGenerator
extends RefCounted

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var recent_hits: Array[bool] = [] # 历史记录，跟踪最近几次是否触发暴击
var max_history: int = 3  # 记录最近3次结果


func get_next(chance_: float) -> bool:
	# 计算调整后的概率
	var adjusted_chance : float = calculate_adjusted_chance(chance_)
	
	# 单次随机判断
	var r : float = rng.randf()
	var status : bool = r < adjusted_chance
	
	# 更新历史记录
	update_history(status)
	
	return status


# 根据历史调整概率，减少连续出现
func calculate_adjusted_chance(chance_: float = 0.0) -> float:
	# 计算最近连续触发的次数
	var consecutive_hits : int = 0
	for hit in recent_hits:
		if hit:
			consecutive_hits += 1
		else:
			break  # 遇到非暴击则停止计数
	
	# 连续触发次数越多，概率降低越多（但不低于基础概率的30%）
	var penalty : float = 1.0 - (consecutive_hits * 0.2)
	penalty = clampf(penalty, 0.3, 1.0)
	
	return chance_ * penalty

# 更新历史记录
func update_history(status: bool):
	recent_hits.append(status)
	if recent_hits.size() > max_history:
		recent_hits.pop_front()

# 重置状态
func reset():
	recent_hits.clear()
	rng.randomize()
