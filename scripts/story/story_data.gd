## story_data.gd
## 剧情数据 — 定义所有剧情帧序列
## 每帧结构:
##   { "type": "title",      "text": "..." }          旧标题帧（当前按旁白显示）
##   { "type": "narration",  "text": "..." }          旁白
##   { "type": "dialogue",   "speaker": "Kane", "text": "..." }  对话
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
		{ "type": "narration", "text": "Kane是一名擅长推理游戏的少年，他和所有人一样过着安逸的生活。" },
		{ "type": "narration", "text": "一次偶然的穿越打乱了他的生活。" },
		{ "type": "narration", "text": "这是哪里？" },
		{ "type": "narration", "text": "这片大陆叫做环界大陆，大陆的中心是一个名为奥斯特兰的王国，周围被火山、冰川等复杂地形包裹。" },
		{ "type": "narration", "text": "王国中的人民安居乐业。" },
		{ "type": "narration", "text": "殊不知，虚空力量正企图入侵这片土地。" },
		{ "type": "narration", "text": "王室贵族和边疆首领正被虚空力量暗中操控，战争不断。" },
		{ "type": "narration", "text": "平凡的边境少女丽塔，见证了无数战乱。一次偶然的相遇，她结识了刚穿越来的Kane。" },
		{ "type": "narration", "text": "他们会做出怎样的行动，王国的未来何去何从，Kane又该如何回到现实世界？" },
		{ "type": "narration", "text": "钟摆未眠，黎明将至。" },
	]


# ============ 第一幕:教程关・初次守候(新手教学 3 天循环前置) ============
# 注:"复活"遵循方案 A —— 轮回重启时复活,单局黎明仅清屏+回血(与策划书不冲突)
static func _tutorial_intro() -> Array:
	return [
		{ "type": "narration", "text": "深夜,Kane 对着沙盘演算轮回公式。屏幕白光炸裂,空间撕裂将他吞噬。" },
		{ "type": "narration", "text": "荒野界碑旁,Kane 摔落。破碎记忆闪过毁灭画面,头痛欲裂。" },
		{ "type": "dialogue", "speaker": "Kane", "text": "沙盘的闭环……怎么变成真的了?" },
		{ "type": "narration", "text": "残破边境小镇,魔物爪痕遍布墙体。丽塔背着魔法果实路过,扶起倒地的 Kane。" },
		{ "type": "dialogue", "speaker": "丽塔", "text": "你是外来流民?这片土地被虚空怪物占领,已经很久没人来这里了" },
		{ "type": "dialogue", "speaker": "Kane", "text": "怪物?我为什么会在这里？我要回去！" },
		{ "type": "dialogue", "speaker": "丽塔", "text": "你不是这个世界的人？......哎呀总之快离开这里，怪物马上就来了！" },
		{ "type": "dialogue", "speaker": "Kane", "text": "(望着丽塔的眼睛，正准备说什么)快跑！你身后！" },
		{ "type": "dialogue", "speaker": "丽塔", "text": "它们来了！快去中央的钟摆！那里有守护阵！用守护阵抵挡他们！" },
		{ "type": "dialogue", "speaker": "Kane", "text": "搞什么啊......" },
	]
