## story_data.gd
## 剧情数据 — 定义所有剧情帧序列
## 每帧结构:
##   { "type": "title",     "text": "..." }            标题(居中大字)
##   { "type": "narration", "text": "..." }            旁白(左对齐)
##   { "type": "dialogue",  "speaker": "Kane", "text": "..." }  对话(带角色名)
##
## 新增剧情: 在 get_story 的 match 里加新分支 + 对应 _xxx() 函数

class_name StoryData
extends RefCounted

const PROLOGUE := "prologue"              # 开篇世界观(splash 后首次进入)
const TUTORIAL_INTRO := "tutorial_intro"  # 教程关前置剧情


static func get_story(story_id: String) -> Array:
	match story_id:
		PROLOGUE:
			return _prologue()
		TUTORIAL_INTRO:
			return _tutorial_intro()
		_:
			push_warning("[StoryData] 未知剧情 id: %s" % story_id)
			return []


# ============ 序章:通用前置世界观(游戏开篇图鉴短篇) ============
static func _prologue() -> Array:
	return [
		{ "type": "title", "text": "环界大陆" },
		{ "type": "narration", "text": "虚空存在「归零」将其锁入无限昼夜轮回。" },
		{ "type": "narration", "text": "时序,是牢笼的运行规则。" },
		{ "type": "narration", "text": "世界不断重复——" },
		{ "type": "narration", "text": "边境防线溃败,腹地漠视,魔物吞噬一切,世界重启。" },
		{ "type": "narration", "text": "少年 Kane,擅长沙盘推演。推演循环模型时,被时空裂隙拉入大陆。" },
		{ "type": "narration", "text": "他体内寄宿主神时间残魂——唯一不受轮回束缚之人。" },
		{ "type": "narration", "text": "边境少女丽塔,见证无数次轮回苦难,收留了坠落的 Kane。" },
		{ "type": "narration", "text": "虚空侵蚀从裂隙涌出混沌魔物。钟摆核心是小镇屏障根基——一旦破碎,本轮轮回直接重置。" },
		{ "type": "title", "text": "钟摆未眠,黎明将至" },
	]


# ============ 第一幕:教程关・初次守候(新手教学 3 天循环前置) ============
# 注:"复活"遵循方案 A —— 轮回重启时复活,单局黎明仅清屏+回血(与策划书不冲突)
static func _tutorial_intro() -> Array:
	return [
		{ "type": "narration", "text": "深夜,Kane 对着沙盘演算轮回公式。屏幕白光炸裂,空间撕裂将他吞噬。" },
		{ "type": "narration", "text": "荒野界碑旁,Kane 摔落。破碎记忆闪过毁灭画面,头痛欲裂。" },
		{ "type": "dialogue", "speaker": "Kane", "text": "沙盘的闭环……怎么变成真的了?" },
		{ "type": "narration", "text": "残破边境小镇,魔物爪痕遍布墙体。丽塔背着魔力露珠路过,扶起倒地的 Kane。" },
		{ "type": "dialogue", "speaker": "丽塔", "text": "你是外来流民?这片土地被轮回困住,昼夜规则千万不要忘记。" },
		{ "type": "dialogue", "speaker": "Kane", "text": "轮回?我能看见不断重复毁灭的碎片。" },
		{ "type": "dialogue", "speaker": "丽塔", "text": "白昼无魔物,我们开采金矿积攒魔力、布置防御。黄昏屏障削弱,魔物先锋会出现。黑夜魔潮大举进攻,守护中央钟摆核心就是活下去唯一办法。等到黎明圣光降临,所有魔物会被直接净化——这是轮回给我们唯一喘息的机会。" },
		{ "type": "dialogue", "speaker": "Kane", "text": "(望向中央发光的钟摆核心)那就是屏障根基?" },
		{ "type": "dialogue", "speaker": "丽塔", "text": "每一轮黑夜,无数人死在魔物手下。唯有轮回重启,他们才会原样复活——苦难无限循环。" },
		{ "type": "dialogue", "speaker": "Kane", "text": "我精通推演循环。这次,我不会让防线再崩塌。" },
	]
