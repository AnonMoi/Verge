# Verge 项目进度交接文档

> **最后更新**：2026-07-08 16:20

> **项目**：Verge — Godot 4.x 塔防游戏（时间循环主题）
> **路径**：`D:\CodeBuddy\Verge_Project\`
> **策划书**：`D:\CodeBuddy\Verge\策划书\`（Demo 版 + 完整版 + Python 生成器）
> **目的**：供下一个 AI 模型/新设备接续开发，了解项目历史、当前状态、技术陷阱

---

## 一、项目概述

- **引擎**：Godot 4.7（`gl_compatibility` 渲染器，保证跨平台兼容）
- **分辨率**：1280×720（viewport 模式，stretch=expand）
- **主场景**：`res://scenes/menu/splash_screen.tscn`（启动画面 → 主菜单 → 章节选择 → 游戏）
- **设计风格**：植物大战僵尸式路径塔防 + 时间循环机制（白天/黄昏/夜晚/黎明）
- **美术策略**：Demo 阶段全部用几何体/色块占位，不投入美术资源
- **副标题**：「钟摆未眠，黎明将至」

---

## 二、当前进度总览

**核心 Demo（教学关）已全部完成并可运行**：从启动画面 → 主菜单 → 章节选择 → 进入教学关 → 3 天时间循环（白天部署/黄昏过渡/夜晚战斗/黎明清屏）→ 胜利结算 / 失败结算 → 返回菜单。

**2026-07-08 追加说明**：
- 敌人死亡表现已优化为：普通战斗先播 `death` 动画，再停留后消失；黎明清屏仍保持快速消散。
- 狙击部署限制已修正：`high` 角色只能部署在高台位，避免误放到地面。
- 高台提示已补强：高台格在狙击选中时有更明显的蓝色高亮，误放时会弹出更游戏化的错误提示。
- 背景过渡做了轻度提亮/压暗微调，保留原素材但让昼夜切换不那么突兀。


**已验证通过的功能链**：
- ✅ 启动画面 + 主菜单 + 章节选择（教学关已解锁，其他章节显示"开发中"）
- ✅ 教学关完整 3 天流程（部署 → 战斗 → 黎明清屏 → 胜利）
- ✅ 暂停系统（暂停菜单 + 设置子面板 + 确认弹窗 + 场景切换）
- ✅ 胜利结算面板（星级评定 + 诗意标题 + 结算数据 + 动画时序）
- ✅ 失败结算面板（"钟摆已停摆" + 重启/退出）
- ✅ 倍速系统（1x ↔ 2x）
- ✅ 经济系统（初始 50 金 + 击杀奖励 + 金矿产出）
- ✅ 部署系统（3 角色 + 金矿 + 高台/地面区分 + 按钮状态实时刷新）

---

## 三、已完成功能清单（按模块）

### 3.1 菜单系统

| 场景 | 脚本 | 功能 |
|------|------|------|
| `scenes/menu/splash_screen.tscn` | `splash_screen.gd` | 启动画面：Verge 标题淡入 + 副标题「钟摆未眠，黎明将至」+ 2.5s 自动跳转/按键跳过 |
| `scenes/menu/main_menu.tscn` | `main_menu.gd` | 主菜单：标题 + 副标题 + 4 个按钮（开始游戏/章节选择/设置/退出），按钮左对齐排列 |
| `scenes/menu/chapter_select.tscn` | `chapter_select.gd` | 章节选择：可滚动卡片列表，教学关已解锁（绿色），其他章节灰显"开发中"，左上角返回按钮 |

### 3.2 游戏场景（教学关）

**主场景**：`scenes/main_game/main_game.tscn`

**节点结构**：
```
MainGame (Node2D, game_scene_controller.gd)
├── Background (ColorRect, 深色 0.05,0.05,0.08)
├── PathVisual (Node2D, 17 个灰色路径格)
├── Obstructions (Node2D, 空节点保留结构)
├── DeploySlots (Node2D, 19 个部署位)
├── Core (Node2D, 红色 60×60, 位置 800,320)
├── EnemySpawner (Node, spawner.gd)
├── Enemies / Characters / Buildings (Node, 容器)
├── HUD (Control, 顶部信息栏 + 倍速/暂停按钮)
├── DeployPanel (CanvasLayer layer=50, 底部部署栏)
├── DawnEffect (CanvasLayer layer=100, 黎明特效)
├── PauseMenu (CanvasLayer layer=150, 暂停菜单)
├── VictoryPanel (CanvasLayer layer=180, 胜利结算)
└── GameOverPanel (CanvasLayer layer=200, 失败结算)
```

### 3.3 路径系统

- **网格**：64×64 标准网格，每格视觉 60×60（2px 内缩形成 4px 深色缝隙作为网格线）
- **路径走向**（拐角已对齐到 64px 网格格心）：
  ```
  起点 (32,320) → H1 段 6 格 → 拐角1 (416,320) → V1 段 (416,384) → 拐角2 (416,448)
  → H2 段 5 格 → 拐角3 (800,448) → V2 段 (800,384) → 核心 (800,320)
  ```
- **格心序列**（x 坐标）：32, 96, 160, 224, 288, 352, 416, 480, 544, 608, 672, 736, 800
- **关键修复**：拐角从 x=384 右移 32px 到 416（原来不在 64px 网格上）

### 3.4 部署系统

- **19 个部署位**：16 地面（ground，在路径格上）+ 3 高台（high，路径外侧）
- **高台格**：仅狙击手选中时显示蓝色半透明高亮 `Color(0.4, 0.5, 0.7, 0.35)`，并同步显示更醒目的错误提示风格
- **4 个部署按钮**：先锋(20金) / 重装(40金) / 狙击(45金) / 金矿(50金)
- **金矿上限**：MAX_MINES = 2
- **按钮状态**：每帧 `_check_buttons_state()` 检查金币/选中状态/金矿数变化，钱不够时按钮变灰不可点
- **黄昏半价**：已移除（原策划书的黄昏半价机制已删除）


### 3.5 角色系统

| 角色 | 费用 | HP | 攻击 | CD | 挡敌数 | 类型 | 视觉 |
|------|------|-----|------|-----|--------|------|------|
| 先锋 Pioneer | 20 | 180 | 24 | 1.0s | 2 | 近战/ground | AnimatedSprite2D（rika_9721bbe0.png） |
| 重装 Defender | 40 | 450 | 10 | 1.5s | 4 | 近战/ground | AnimatedSprite2D（rika_8ad2355f.png） |
| 狙击 Sniper | 45 | 140 | 52 | 1.5s | 0 | 远程6格/high | AnimatedSprite2D（rika_3f8e6078.png） |

- 角色基类 `character_base.gd`：HP 条 + 受伤闪白 + 死亡动画 + 攻击冷却 + 范围指示器 + 黎明恢复
- 攻击动画控制器 `attack_animation_controller.gd`：播放 attack 动画后立即触发伤害/子弹（不依赖 animation_finished 信号）
- 投射物系统 `projectile.gd/.tscn`：远程攻击飞行 + 碰撞检测
- **美术素材已接入**：3 个角色 + 敌人均有 AnimatedSprite2D（待机/攻击动画），来自 `character_sources/` 目录

### 3.6 敌人系统

| 敌人 | HP | 速度 | 击杀奖励 | 特殊 |
|------|-----|------|----------|------|
| 混沌兵 chaos_grunt | 100 | 普通 | 3金 | 无 |
| 鬼影 swift_ghost | 70 | 快速 | 5金 | 20% 闪避（JSON 已定义，后续待补） |
| 铁甲精英 iron_elite | 500 | 慢速 | 12金 | 每3秒35额外伤害（JSON 已定义，后续待补） |

- **敌人死亡表现**：普通战斗中的敌人会先播放死亡动画，再短暂停留后消失；黎明清屏则会快速消散，保持节奏爽快。


**出怪计划**（spawner.gd）：
- **黄昏**（少量出怪）：Day1 3普通(8s间隔) / Day2 3普通+2快速(5s) / Day3 2普通+2快速+1精英(4s)
- **夜晚**（大量出怪）：Day1 8只(10s) / Day2 16只(5s) / Day3 25只(3.5s)

### 3.7 时间循环系统

- **阶段**：白天 90s → 黄昏 30s → 夜晚 90s → 黎明 3s 过渡 → 下一天
- **3 天胜利条件**：Day 3 夜晚结束 + 核心未被摧毁
- **完美通关**：核心 HP > 70% → 奖励 50 金 + 星级 ★★★
- **黎明特效**：全屏白闪 + "黎明"大字 + 敌人消散 + 角色 30% HP 恢复 + 飘字

### 3.8 经济系统

- **初始资金**：50 金（PVZ 式开局，刚好够放 1 个金矿）
- **击杀奖励**：3/5/12 金（普通/快速/精英）
- **金矿**：10金/5秒产出，夜晚停产，HP 80，上限 2 个
- **统计字段**（GameManager）：`level_start_time` / `total_gold_earned` / `total_deployed` / `total_kills`

### 3.9 UI 系统

**HUD（顶部栏）**：
- 阶段图标 + 倒计时 + Day X/3 + 金币 + 核心 HP%
- 核心 HP 颜色动态变化（绿→黄→红）
- 倍速按钮 `▶ 1x` ↔ `▶▶ 2x`
- 暂停按钮 `⏸ 暂停`（深蓝灰圆角，悬停高亮）

**暂停菜单**（`pause_menu.gd`，2026-07-06 重写）：
- 全屏半透明遮罩 + 居中面板（绝对定位，340×400）
- 三个互斥页面（主菜单/设置/确认弹窗），通过 `visible` + `mouse_filter` 切换
- 4 个按钮：继续游戏 / 设置 / 返回章节选择 / 返回主菜单
- 设置子面板：音效/音乐（开发中）+ ← 返回
- 确认弹窗：确认/取消（用于返回章节/主菜单的二次确认）
- **暂停机制**：`get_tree().paused = true`（非 Engine.time_scale）
- **Esc 键切换**
- ⚠️ 隐藏的页面必须设 `mouse_filter = MOUSE_FILTER_IGNORE`（见陷阱 4.9）

**胜利结算面板**（`victory_panel.gd`，2026-07-06 重写）：
- 全屏遮罩 + 居中面板（绝对定位，440×560）
- 诗意标题（根据星级）：
  - ★★★ "守望终有回音"（核心 > 50%）
  - ★★ "夜色尚未退去"（核心 > 20%）
  - ★ "黑暗中无人沉睡"（核心 > 0%）
- 星级显示（金色/灰色）+ 结算数据（耗时/核心剩余/金币收入/部署单位/击杀数）
- 按钮：返回章节列表 / 下一关（disabled）
- **暂停机制**：`Engine.time_scale = 0.0`（不能用 get_tree().paused，见陷阱 4.10）
- 不用 Tween，所有状态立即设置

**失败结算面板**（`game_over_panel.gd`，2026-07-06 重写）：
- 全屏暗红色遮罩 + 居中面板（绝对定位，440×520，红色调）
- 诗意失败标题（根据坚持天数）：第1天「第一夜便已失守」/ 第2天「守候止于次夜」/ 第3天「黎明前最后的溃败」
- 副标题 + 结算数据（坚持天数/坚持时长/消灭敌人/部署单位/核心剩余）
- 按钮：重新开始 / 返回章节列表
- R 重新开始 / Esc 返回章节列表

### 3.10 数据配置

- `resources/data/characters/characters.json` — 3 角色完整数据
- `resources/data/enemies/enemies.json` — 3 敌人完整数据
- `resources/data/game_config.json` — 全局配置

### 3.11 Autoload 单例

| 名称 | 路径 | 职责 |
|------|------|------|
| Constants | `scripts/core/constants.gd` | 全局常量（时间/网格/类型） |
| SignalBus | `scripts/core/signal_bus.gd` | 信号总线（7 大类 24 个信号） |
| GameManager | `scripts/game_manager/game_manager.gd` | 游戏状态 + 关卡统计 |
| TimeCycle | `scripts/time_cycle/time_cycle.gd` | 时间循环 + 阶段切换 |
| Economy | `scripts/economy/economy.gd` | 金币 + 金矿 + 击杀奖励 |
| Resolution | `scripts/core/resolution_manager.gd` | 分辨率适配 |

---

## 四、关键技术陷阱（⚠️ 下一个模型必读）

### 4.1 Engine.time_scale = 0 的副作用（最重要）

**问题**：暂停时 `Engine.time_scale = 0` 会让所有 `_process(delta)` 的 delta 乘 0，**Tween 完全不推进**。

**已踩的坑**：
1. 暂停菜单最初用 tween 做淡入动画 → 永远卡在第 0 帧，UI 完全透明看不见
2. 按钮 hover 缩放用 tween → 暂停时悬停无反馈

**解决方案**：
- 暂停菜单所有 UI 状态切换改为**立即设置最终值**（不用 tween）
- 暂停菜单 CanvasLayer 设 `process_mode = Node.PROCESS_MODE_ALWAYS`，确保暂停时按钮仍能响应
- 关闭暂停菜单时**先恢复 time_scale 再启动 tween**（关闭动画可以正常播放）

### 4.2 change_scene_to_file 在暂停状态下的坑

**问题**：`get_tree().change_scene_to_file()` 是 deferred 的（下一帧执行）。如果在 `time_scale=0` 的同一帧里调用，可能出现状态竞争。

**解决方案**（见 `pause_menu.gd` 的 `_do_return_chapters`）：
```gdscript
func _do_return_chapters() -> void:
    _reset_global_state()  # 先恢复 time_scale + 重置状态
    _do_change_scene.call_deferred(CHAPTER_SELECT_SCENE)  # 延后一帧切场景

func _do_change_scene(path: String) -> void:
    Engine.time_scale = 1.0  # 切换前再次强制恢复
    GameManager.is_paused = false
    get_tree().change_scene_to_file(path)
```

### 4.3 RefCounted 静态方法中不能用 get_tree()

**问题**：`menu_theme.gd` 是 RefCounted（不是 Node），它的静态方法里调用 `get_tree()` 会报错。

**解决方案**：改用 `Engine.get_main_loop() as SceneTree`

### 4.4 CPUParticles2D 枚举名

- ❌ `EMISSION_SHAPE_BOX` 不存在
- ✅ `EMISSION_SHAPE_RECTANGLE`
- 属性 `emission_rect_extents`（Vector2，不是 Vector3 的 box_extents）

### 4.5 Variant 类型推断警告

**问题**：`var x := dict.get(key, default)` 会触发 "type being inferred from Variant" 警告。

**解决方案**：显式声明类型
```gdscript
var title_text: String = TITLES.get(star_count, TITLES[1])
```

### 4.6 网格对齐

64px 网格的格心序列必须是：32, 96, 160, 224, 288, 352, 416, 480, 544, 608, 672, 736, 800
**不能出现 384**（这是格子边界，不是格心）。如果路径拐角在 384，要右移到 416。

### 4.7 按钮状态刷新

**问题**：部署栏按钮的金币状态依赖 `gold_changed` 信号，但某些代码路径不发信号 → 按钮状态不刷新。

**解决方案**：在 `deploy_panel.gd` 的 `_process()` 里每帧调用 `_check_buttons_state()`，检查金币/选中/金矿数是否有变化，有变化才刷新（避免每帧重建 StyleBox）。

### 4.8 GDScript 三元表达式

**问题**：`var x := func_call() if cond else null` 这种写法在某些 GDScript 版本里会被 parser 静默拒绝（函数体不执行，不报错）。

**解决方案**：拆成 if 语句
```gdscript
var x := null
if cond:
    x = func_call()
```

### 4.9 visible=false 的 Control 仍拦截鼠标（重要）

**问题**：Godot 4.x 中，`Control.visible = false` 的节点**默认仍然拦截鼠标事件**（`mouse_filter = MOUSE_FILTER_STOP` 时）。会导致隐藏的 UI 层挡住下层按钮，表现为"按钮有时能点有时不能点"。

**踩坑场景**：
1. 暂停菜单的设置/确认子面板用 `PRESET_FULL_RECT` 撑满父面板，`visible=false` 后仍挡住主菜单按钮
2. 暂停菜单的三个页面（主菜单/设置/确认）同时存在，隐藏的页面挡住可见页面的按钮

**解决方案**：
```gdscript
# 隐藏时必须同时关闭鼠标拦截
func _hide_panel(p: Control) -> void:
    p.visible = false
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE

# 显示时恢复
func _show_panel(p: Control) -> void:
    p.visible = true
    p.mouse_filter = Control.MOUSE_FILTER_STOP
```

### 4.10 get_tree().paused vs Engine.time_scale = 0（重要）

**问题**：两种暂停机制不兼容，混用会导致按钮点击失效。

| 机制 | 效果 | 适用场景 |
|------|------|----------|
| `Engine.time_scale = 0` | `_process` 仍调用但 delta=0，Tween 不推进 | 胜利/失败面板 |
| `get_tree().paused = true` | 完全停止 PAUSABLE 节点的 `_process`/`_physics_process` | 暂停菜单 |

**踩坑场景**：
1. 胜利面板用 `get_tree().paused = true` → 按钮 `pressed` 信号不触发（即使 `process_mode = ALWAYS`，`_gui_input` 在某些 Godot 4 版本中仍受影响）
2. 暂停菜单用 `Engine.time_scale = 0` → 按钮点击时灵时不灵

**解决方案**：
- **暂停菜单**用 `get_tree().paused = true`（`process_mode = ALWAYS` 的按钮完全不受影响）
- **胜利/失败面板**用 `Engine.time_scale = 0.0`（按钮正常工作，不能用 Tween）
- 两者不要混用

### 4.11 AnimatedSprite2D.animation_finished 信号不触发（重要）

**问题**：Godot 4 中 `AnimatedSprite2D.animation_finished` 信号在以下情况不触发：
1. `play("attack")` 时当前已经在播放 `"attack"`（同名动画不重置进度）
2. `stop()` + `frame = 0` + `play()` 后引擎内部状态异常
3. 动画已经播完停在最后一帧时，再次 `play()` 不会重新播放

**踩坑场景**：
1. 角色攻击动画播放后 `animation_finished` 不触发 → 子弹永远不发射、伤害不造成
2. 敌人死亡动画播放后 `death_animation_finished` 不触发 → 尸体不消失
3. 敌人受击动画播放后不回到 idle 动画

**解决方案**：
- **角色攻击**：动画和伤害逻辑解耦——`play_attack_animation()` 播放动画后**立即** emit 信号，不等动画播完
- **敌人死亡/受击**：用 `await get_tree().create_timer(anim_duration)` 代替信号，计算动画时长（帧数/speed）
- **敌人死亡兜底**：`_die()` 中用 Timer 2 秒后强制 `queue_free()`，防止动画控制器信号不触发导致尸体残留

### 4.12 AnimatedSprite2D 默认 animation 属性

**问题**：角色场景的 `AnimatedSprite2D` 节点 `animation` 属性如果默认设成 `"attack"`，角色一加载就开始播放攻击动画（非循环），播完停在最后一帧。之后调用 `play("attack")` 不会重新播放。

**解决方案**：`AnimatedSprite2D` 的默认 `animation` 必须设成 `"default"`（待机动画），不能设成 `"attack"`。

### 4.13 角色攻击已死亡敌人（鞭尸）

**问题**：敌人死后 `is_dead = true` 但还没 `queue_free`（死亡动画播放中），角色的 `_find_target()` 仍然把它当作有效目标。

**解决方案**：`_find_target()` 中检查 `is_dead`：
```gdscript
if "is_dead" in enemy and enemy.get("is_dead") == true:
    continue
```

---

## 五、CanvasLayer 层级规范

| 层级 | 用途 | 节点 |
|------|------|------|
| 50 | 底部部署栏 | DeployPanel |
| 100 | 黎明特效 | DawnEffect |
| 150 | 暂停菜单 | PauseMenu |
| 180 | 胜利结算 | VictoryPanel |
| 200 | 失败结算 | GameOverPanel |

**规则**：结算面板（胜利/失败）必须在暂停菜单之上，因为游戏结束时不应能暂停。

---

## 六、文件结构概览

```
D:\CodeBuddy\Verge_Project\
├── project.godot              # 引擎配置 + 6 个 autoload
├── icon.svg
├── README.md
├── 使用说明.txt
├── character_sources/         # 角色美术素材（png + gif + import）
├── docs/
│   ├── progress.md            # ← 本文档
│   └── 开发日志.md             # 早期开发日志（路径/部署系统细节）
├── 策划书/
│   ├── Verge_Demo版策划书.md
│   ├── Verge_完整版策划书.md
│   ├── Verge_Demo版策划书.docx
│   ├── Verge_完整版策划书.docx
│   └── generate_verge_proposals.py  # Python 脚本：从 .md 生成 .docx
├── scenes/
│   ├── menu/                  # splash_screen / main_menu / chapter_select
│   ├── main_game/             # main_game.tscn + 3 个角色场景 + enemy/projectile/gold_mine
│   └── ...
├── scripts/
│   ├── core/                  # constants / signal_bus / resolution_manager
│   ├── building/              # core_node / deploy_slot / gold_mine
│   ├── character/             # character_base / attack_animation_controller
│   ├── enemy/                 # enemy_movement / enemy_animation_controller
│   ├── effects/               # dawn_effect / projectile
│   ├── economy/               # economy
│   ├── time_cycle/            # time_cycle
│   ├── game_manager/          # game_manager / spawner / game_scene_controller
│   └── ui/
│       ├── hud.gd             # 顶部信息栏 + 倍速/暂停按钮
│       ├── deploy_panel.gd    # 底部部署栏
│       ├── pause_menu.gd      # 暂停菜单（2026-07-06 重写）
│       ├── victory_panel.gd   # 胜利结算面板（2026-07-06 重写）
│       ├── game_over_panel.gd # 失败结算面板（2026-07-06 重写）
│       └── menu/              # splash_screen / main_menu / chapter_select / menu_theme
└── resources/
    └── data/
        ├── characters/characters.json
        ├── enemies/enemies.json
        └── game_config.json
```

---

## 七、已知问题 / 待实现

### 7.1 代码级待实现
- [ ] **敌人阻挡逻辑** — `character_base.gd` 有 `block_count`，但 `enemy_movement.gd` 未实现阻挡检测（敌人经过角色格子时不会停下来）
- [ ] **敌人类型视觉差异化** — `enemy.tscn` 颜色统一绿色，三种敌人视觉无区别
- [ ] **鬼影闪避** — `enemies.json` 定义了 20% 闪避率，后续待补
- [ ] **精英重击** — `enemies.json` 定义了每 3 秒 35 额外伤害，后续待补
- [ ] **战士撤回 UI** — `deploy_slot.gd` 有 `recall_character()` 方法，但 `deploy_panel.gd` 还没有正式整理成完整入口
- [ ] **设置面板的音效/音乐** — 目前显示"开发中"
- [ ] **测试快捷键需删除** — `game_manager.gd` 中 F3(触发胜利)/F4(触发失败) 测试代码，发布前必须删除
- [ ] **game_over_panel 重复监听** — 同时监听 `core_destroyed` + `game_over` 信号，`_show_game_over` 被调用两次（有 `_is_open` 保护，不崩溃但冗余）


### 7.2 数值/配置不一致
- `game_config.json` 中 `starting_gold = 150`，但 `economy.gd` 硬编码 `gold = 50`（以代码为准）
- `game_config.json` 中金矿 `gold_per_tick: 15, tick_interval: 3.0`，但 `gold_mine.gd` 硬编码 `10金/5秒`（以代码为准）

### 7.3 待优化
- [ ] 暂停菜单的 print 诊断日志可以清理（保留关键的）
- [ ] 倍速 2x 时 `await get_tree().create_timer()` 受 time_scale 影响，黎明 3s 过渡会变 1.5s
- [ ] Day 2/3 的 Spawner 计划切换逻辑需确认（`_load_plan_for_day` 在 `day_completed` 回调中预加载）
- [ ] 后续如继续优化提示/UI，建议统一按“更像游戏内反馈”的风格处理


---

## 八、下一步开发建议

按优先级排序：

### P0（核心玩法完善）
1. **敌人阻挡逻辑** — 让近战角色真正"挡住"敌人（PVZ 式核心机制）
2. **敌人视觉差异化** — 至少改颜色：普通绿/快速黄/精英红
3. **鬼影闪避 + 精英重击** — 让精英敌人有威胁感

### P1（内容扩展）
4. **第一章「暗夜突袭」** — 章节选择里已占位，需要新地图/新波次
5. **音效系统** — 攻击/受伤/部署/黎明等基础音效
6. **设置面板实现** — 音量滑条 + 静音

### P2（打磨）
7. **美术资源替换** — 替换色块占位（Godot 资源商店或自制）
8. **撤回系统** — 黄昏撤回角色返还部分金币
9. **更多角色/敌人** — 按完整版策划书扩展

---

## 九、测试验证清单

接手后建议先跑一遍完整流程确认：

- [ ] F5 启动 → splash_screen → 主菜单 → 章节选择 → 教学关
- [ ] 教学关 Day 1 白天：部署先锋/重装/狙击/金矿，确认金币扣减 + 角色出现
- [ ] Day 1 黄昏：少量敌人出现，角色自动攻击
- [ ] Day 1 夜晚：大量敌人，战斗激烈
- [ ] Day 1 黎明：全屏白闪 + "黎明"大字 + 敌人消散 + 角色回血
- [ ] Day 2 / Day 3 流程正常
- [ ] Day 3 夜晚结束 → 胜利结算面板（星级 + 数据 + 按钮）
- [ ] 暂停按钮 → 暂停菜单 → 4 个按钮全部测试（继续/设置/返回章节/返回主菜单）
- [ ] 倍速 1x ↔ 2x 切换
- [ ] 核心被摧毁 → 失败结算面板 → R 重启

---

## 十、决策记录

- **2026-07-01**：先锋回费机制删除（与金矿功能冲突）
- **2026-07-01**：Guard 更名为 Defender（重装），纯肉盾定位
- **2026-07-01**：部署位视觉去除（仅保留高台格蓝色高亮）
- **2026-07-01**：路径拐角从 x=384 右移到 416（网格对齐）
- **2026-07-02**：黄昏半价机制移除（简化经济）
- **2026-07-02**：数值调整 — 先锋 20/180/24、重装 40/450/10、狙击 45/140/52
- **2026-07-02**：敌人血量大幅提升 — chaos_grunt 65→180, swift_ghost 40→120, iron_elite 520→1200
- **2026-07-02**：出怪数量大幅增加（夜晚 Day1 8只 / Day2 16只 / Day3 25只）
- **2026-07-02**：副标题从"时间循环·塔防"改为"钟摆未眠，黎明将至"
- **2026-07-02**：教学关从第一章中独立（章节列表调整）
- **2026-07-02**：暂停系统重写（修复 tween 卡死 + process_mode + 场景切换 deferred）
- **2026-07-02**：胜利结算面板完成（星级 + 诗意标题 + 动画时序）
- **2026-07-06**：敌人血量削弱 — chaos_grunt 180→100, swift_ghost 120→70, iron_elite 1200→500（解决"怪太肉"问题）
- **2026-07-06**：角色美术素材接入 — 3 个角色 + 敌人替换为 AnimatedSprite2D（来自 character_sources/）
- **2026-07-06**：胜利结算面板重写 — 去掉 Tween（time_scale=0 不推进），改用立即设置 + 绝对定位布局
- **2026-07-06**：失败结算面板重写 — 从简陋全屏文字改为与胜利面板同构的结算卡片（诗意标题 + 数据 + 按钮）
- **2026-07-06**：暂停菜单重写 — 三个互斥页面（主菜单/设置/确认），用 get_tree().paused 替代 Engine.time_scale
- **2026-07-06**：修复角色攻击动画不触发伤害 — AnimatedSprite2D.animation_finished 信号不可靠，改为动画和伤害解耦
- **2026-07-06**：修复敌人尸体不消失 — 同上，death 动画信号不触发，改用 await Timer + 兜底强制销毁
- **2026-07-06**：修复狙击鞭尸 — _find_target() 跳过 is_dead=true 的敌人
- **2026-07-06**：HUD 暂停/倍速按钮间距加大（10px → 20px）
- **2026-07-06**：测试快捷键 F3(胜利)/F4(失败) — 发布前需删除
- **2026-07-08**：敌人死亡表现优化 — 普通战斗中的敌人先播 `death` 动画再延迟消失，黎明清屏保持快速消散
- **2026-07-08**：狙击部署限制修正 — `high` 角色只能部署在高台位，避免误放到地面
- **2026-07-08**：高台错误提示补强 — 误放时显示更游戏化的高台提示，并加入高亮/动效
- **2026-07-08**：背景与高台提示视觉微调 — 保留原背景素材，但轻调昼夜过渡和高台高亮观感
- **2026-07-08**：文档同步 — README / 开发日志 / 进度文档统一记录本轮更新


---

*本文档由 CodeBuddy 于 2026-07-06 19:22 更新，覆盖到此时刻的所有开发进度。*
