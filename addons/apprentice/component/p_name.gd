#============================================================
#    P Name
#============================================================
# - author: zhangxuetu
# - datetime: 2025-05-19 15:31:25
# - version: 4.4.1
#============================================================
## 属性名。游戏中字典数据需要用到的键名
class_name PName
extends Autowired

# 属性
static var ID
static var NAME
static var MOVE_SPEED  ##移动速度
static var DAMAGE   ##伤害值
static var HEALTH
static var HEALTH_MAX
static var JUMP_HEIGHT
static var GRAVITY
static var CRIT  ##暴击 完整名: CRITICAL HIT
static var CRIT_MULTIPLIER  ##暴击倍数
static var CRIT_RATE  ##暴击概率
static var DODGE  ##闪避
static var DODGE_RATE  ##闪避概率
static var ACCURATE  ##精准
static var HIT  ##击中/命中
static var HIT_RATE  ##命中的几率
static var UNLOADING_FORCE  ##卸力
static var ATTACK_SPEED  ##攻击速度
static var UNIT_GROUP  ##所属角色组
static var HOSTILE_UNIT_GROUP  ##敌对角色组

static var DISABLED_MOVE
static var DISABLED_JUMP
static var DISABLED_GRAVITY
static var INVINCIBLE  ##无敌的
static var PROP_ID 
static var PROP_NAME  ## 道具名
static var PROP_QUALITY  ##道具品质
static var EXPERIENCE  ##经验值
static var LEVEL  ##等级
static var CRITICAL_HIT_RATE  ##暴击概率
static var CRITICAL_HIT_MULTIPLIER  ##暴击倍数
static var REPEL_RATE  ##击退概率
static var REPEL_DISTANCE  ##击退距离
static var STUN_RATE  ##击晕概率
static var STUN_TIME  ##击晕时间
static var STUN_TYPE  ##硬直类型，播放的动画
static var STUN_VELOCITY  ##硬直类型，播放的动画
static var STAMINA  ##体力
static var STAMINA_MAX  ##最大体力
static var STAMINA_COST  ##消耗的体力
static var STAMINA_RECOVERY_RATE  ##体力恢复速度
static var MONEY  ##财富
static var COIN  ##金币
static var DIAMOND  ##钻石
static var CAMERA_ZOOM  ##镜头缩放
static var KILLED_COUNT  ##击杀数
static var JIN_TRANSFER  ##卸力
static var JIN_TRANSFER_RATE
static var VISION_RADIUS  ##视野范围


# 杂项
static var TYPE
static var TEXTURE ##贴图路径或名称
static var VALUE
static var INSTIGATOR  ##最终来源者（始作俑者，比如施放技能的最终所属玩家）
static var TARGET  ##目标
static var TARGETS  ##多个目标
static var CAUSER  ##引起者（这个伤害的直接来源，比如伤害来自技能、子弹、陷阱等对象）
static var ATTACKER  ##攻击者
static var TARGET_POSITION  ##目标位置
static var DAMAGE_TYPE  ##伤害类型
static var DAMAGE_VALUE  ##准备要造成的伤害
static var DAMAGED_VALUE  ##已造成的伤害
static var DAMAGED_RESULT  ##伤害结果
static var DAMAGED_RESULT_ITEMS  ##伤害结果列表
static var COUNT ##数量
static var DESCRIPTION ##描述
static var METHOD  ##方法
static var CALLBACK  ##回调
static var DISTANCE  ##距离
static var DIRECTION  ##方向
static var WEAPON  ##武器
static var ANIMATION  ##动画名
static var ANIMATION_TIME  ##动画时间。动画会根据技能持续时间，设置动画速度
static var ENABLED_ANIMATION_TIME_SCALE  ##开启动画时间缩放。动画会根据技能持续时间，缩放动画速度
static var ANIMATION_TIME_SCALE  ##开启动画时间缩放。动画会根据技能持续时间，缩放动画速度
static var SKILL_ID  ##技能ID列表，这个是技能唯一的标识
static var SKILL_QUEUE  ##当前执行的技能队列
static var SKILL_TYPE  ##技能类型
static var SKILL_GROUP   ##技能组。这个技能执行时，逐个执行这些技能。
static var IS_SKILL_GROUP
static var MAX_PROP_COUNT  ##最大可装备的道具数量
static var USED_PROP_IDS  ##使用过的道具ID。在执行使用道具的时候记录这个数据
static var PROP_SLOT_IDS  ##角色道具槽里正在使用的道具
static var ATTACK_TYPE  ##攻击类型
static var ATTACK_MODE  ##采用的攻击方式
static var ENABLED_DAMAGE   ##是否允许造成伤害功能
static var INDEX  ##索引
static var ALIAS  ##别名。会优先显示别名
static var EXTRA  ##附加的
static var SHOW 
static var HIDE 
static var RESULT 
static var LENGTH 
static var STATE 
static var ABILITIES  ##道具能力节点复数
static var RATE ##概率
static var MULTIPLIER ##倍数
static var MAX_ATTACK_MODE_COUNT  ##最大攻击招式槽判断数量
static var ABILITY_NODE  ## 道具能力节点
static var ABILITY_TYPE
static var TECHNIQUE_ACTION  ##招动作
static var POSTURE_ACTION  ##式动作名字
static var POSTURE_ACTION_COUNT  ##式动作类型
static var PUNCTURE_COUNT  ##穿刺敌人数量
static var SUMMONER_COUNT ##召唤物额外数量
static var NO_STAMINA  ##无体力消耗
static var ACTIVED_WEAPONS ##已激活的武器
static var ACTIVED_PROPS ##已激活的道具
static var CAUSE  ##原因


# 技能阶段
static var READY  ##准备阶段
static var EXECUTE  ##执行阶段
static var AFTER   ##执行结束阶段
static var COOLDOWN  ##冷却阶段
static var REFRESH  ##冷却完成已刷新阶段
