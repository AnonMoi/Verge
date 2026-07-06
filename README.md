# Verge — 时间循环塔防游戏

> **「钟摆未眠，黎明将至」**
>
> Demo v1.0 | Godot 4.x | 2D 像素风策略塔防

---

## 🎮 游戏简介

**Verge** 是一款融合**时间循环机制**与**角色部署策略**的 2D 塔防游戏。玩家守护神秘的"钟摆核心"，在白天部署角色发展经济，黄昏备战，夜晚抵御怪潮，最终在黎明时刻见证全屏清敌的极致爽感——然后一切重新开始，迎接更艰难的明天。

参考了《植物大战僵尸》的路径塔防玩法与《明日方舟》的角色部署策略，但核心创新在于**昼夜循环**带来的节奏变化：白天经营、夜晚死守、黎明清屏。

---

## ✨ 核心特色

| 特色 | 说明 |
|------|------|
| ⏰ **时间循环** | 白天(90s) → 黄昏(30s) → 夜晚(90s) → 黎明(清屏) → 下一天，3天为一局 |
| 👥 **角色塔防** | 3种角色：先锋(快攻) / 重装(肉盾) / 狙击(远程高台)，各有所长 |
| 🌅 **黎明清屏** | 黎明时刻全屏白闪，所有敌人消散，角色回血30%，极致爽感 |
| 💰 **经济策略** | 金矿白天产出 + 夜晚停产，迫使主动作战赚取击杀赏金 |
| 🎨 **像素动画** | AnimatedSprite2D 角色动画，暗色系 UI，诗意结算文案 |

---

## 🚀 快速开始

### 环境要求
- **Godot Engine 4.x**（推荐 4.7，`gl_compatibility` 渲染器）
- 操作系统：Windows / macOS / Linux

### 运行步骤
1. 下载安装 [Godot Engine](https://godotengine.org/download/)
2. 打开 `project.godot`
3. 按 `F5` 运行游戏
4. 分辨率：1280×720（自动适配窗口）

---

## 🕹️ 操作指南

### 游戏流程
1. **白天（90秒）**：点击底部角色按钮 → 选中角色 → 点击地图部署位 → 放置金矿积累金币
2. **黄昏（30秒）**：少量敌人出现，检查防线，调整阵型
3. **夜晚（90秒）**：大量敌人进攻，角色自动攻击，金矿停产
4. **黎明（3秒）**：全屏白闪，敌人清屏，角色回血，进入下一天
5. **Day 3 夜晚结束**：核心未被摧毁 → 胜利！

### 操作按键
| 按键 | 功能 |
|------|------|
| 鼠标点击 | 选择角色 / 部署角色 / 点击按钮 |
| `Esc` | 打开/关闭暂停菜单 |
| 倍速按钮 | 1x ↔ 2x 游戏速度切换 |
| `F3` | 测试：直接触发胜利结算 |
| `F4` | 测试：直接触发失败结算 |

### 暂停菜单
- **继续游戏** — 返回游戏
- **设置** — 音效/音乐设置（开发中）
- **返回章节选择** — 二次确认后跳转
- **返回主菜单** — 二次确认后跳转

---

## 📊 角色数据

| 角色 | 费用 | HP | 攻击 | 攻速 | 挡敌 | 射程 | 类型 | 定位 |
|------|------|-----|------|------|------|------|------|------|
| ⚔️ 先锋 | 20金 | 180 | 24 | 1.0s | 2 | 1格 | 地面/近战 | 廉价快攻，前线挡怪 |
| 🛡️ 重装 | 40金 | 450 | 10 | 1.5s | 4 | 1格 | 地面/近战 | 纯肉盾，高血量挡4 |
| 🎯 狙击 | 45金 | 140 | 52 | 1.5s | 0 | 6格 | 高台/远程 | 远程高伤，发射投射物 |

> **部署规则**：先锋/重装只能放在路径格（地面），狙击只能放在高台格。部署后角色自动寻找范围内最近的敌人攻击。

---

## 👹 敌人数据

| 敌人 | HP | 速度 | 击杀奖励 | 核心伤害 | 特点 |
|------|-----|------|----------|----------|------|
| 🟢 混沌杂兵 | 100 | 普通(80) | 3金 | 15 | 基础敌人，数量多 |
| 🟡 迅捷鬼影 | 70 | 快速(144) | 5金 | 12 | 高速移动，20%闪避（待实现） |
| ⚫ 黑铁精英 | 500 | 慢速(56) | 12金 | 35 | 高血量，重击技能（待实现） |

### 出怪计划

| 天数 | 黄昏（少量） | 夜晚（大量） |
|------|------------|------------|
| Day 1 | 3 杂兵 (8s间隔) | 8 杂兵 (10s间隔) |
| Day 2 | 3杂兵+2鬼影 (5s) | 11杂兵+5鬼影 (5s间隔) |
| Day 3 | 2杂兵+2鬼影+1精英 (4s) | 25只混合 (3.5s间隔) |

---

## 🏗️ 经济系统

| 项目 | 数值 |
|------|------|
| 初始金币 | 50金（刚好放1个金矿） |
| 金矿产出 | 10金/5秒（仅白天和黄昏） |
| 金矿上限 | 2个 |
| 金矿HP | 80 |
| 核心HP | 1000 |

---

## 🎯 胜利条件

| 评级 | 条件 | 标题 |
|------|------|------|
| ★★★ | 核心 HP > 50% | 「守望终有回音」 |
| ★★ | 核心 HP > 20% | 「夜色尚未退去」 |
| ★ | 核心 HP > 0% | 「黑暗中无人沉睡」 |

结算面板显示：耗时 / 核心剩余 / 金币收入 / 部署单位 / 消灭敌人

---

## 🏗️ 技术架构

### Autoload 单例（6个）

| 单例 | 脚本路径 | 职责 |
|------|---------|------|
| `Constants` | `scripts/core/constants.gd` | 全局常量（时间/网格/角色/敌人类型） |
| `SignalBus` | `scripts/core/signal_bus.gd` | 信号总线（7类24个信号，解耦模块） |
| `GameManager` | `scripts/game_manager/game_manager.gd` | 游戏状态 + 关卡统计 + 天数管理 |
| `TimeCycle` | `scripts/time_cycle/time_cycle.gd` | 时间循环系统（阶段切换/黎明触发） |
| `Economy` | `scripts/economy/economy.gd` | 金币管理 + 金矿产出 + 击杀奖励 |
| `Resolution` | `scripts/core/resolution_manager.gd` | 1280×720 分辨率适配 |

### CanvasLayer UI 层级

| 层级 | 节点 | 用途 |
|------|------|------|
| 50 | DeployPanel | 底部角色/金矿部署按钮 |
| 100 | DawnEffect | 黎明全屏白闪特效 |
| 150 | PauseMenu | 暂停菜单（继续/设置/返回章节/返回主菜单） |
| 180 | VictoryPanel | 胜利结算（诗意标题 + 星级 + 数据） |
| 200 | GameOverPanel | 失败结算（诗意标题 + 数据 + 重启按钮） |

---

## 📁 项目结构

```
Verge_Project/
├── project.godot              # 引擎配置 + 6个 Autoload
├── icon.svg                   # 项目图标
├── README.md                  # 本文件
├── 使用说明.txt               # 中文使用指南
├── .gitignore                 # Git 忽略规则
│
├── scenes/
│   ├── menu/                  # splash_screen / main_menu / chapter_select
│   └── main_game/             # main_game + 角色/敌人/金矿/投射物预制体
│
├── scripts/
│   ├── core/                  # constants / signal_bus / resolution_manager
│   ├── game_manager/          # game_manager / spawner / game_scene_controller
│   ├── character/             # character_base / attack_animation_controller
│   ├── enemy/                 # enemy_movement / enemy_animation_controller
│   ├── time_cycle/            # time_cycle
│   ├── economy/               # economy
│   ├── building/              # core_node / deploy_slot / gold_mine
│   ├── ui/                    # hud / deploy_panel / pause_menu / victory_panel / game_over_panel
│   │   └── menu/              # splash_screen / main_menu / chapter_select / menu_theme
│   └── effects/               # dawn_effect / projectile
│
├── resources/data/
│   ├── characters/characters.json
│   ├── enemies/enemies.json
│   └── game_config.json
│
├── character_sources/         # 角色 & 敌人美术素材（png）
├── docs/                      # 开发文档（进度追踪/日志）
├── 策划书/                    # 完整版 + Demo 版策划书（.md + .docx）
└── .github/workflows/         # GitHub Actions（语法检查 + 自动导出）
```

---

## 🔧 开发说明

### 代码规范
- 所有脚本使用 **GDScript**，命名风格 `snake_case`
- 节点查找优先使用 `find_child()`，避免 `$` 路径硬编码
- 信号通过 `SignalBus` 单例传递，模块间不直接依赖

### 关键技术注意
- **暂停机制**：暂停菜单用 `get_tree().paused = true`，胜利/失败面板用 `Engine.time_scale = 0`
- **Tween 陷阱**：`Engine.time_scale = 0` 时 Tween 完全不推进，UI 状态须立即设置最终值
- **动画信号**：Godot 4 `AnimatedSprite2D.animation_finished` 信号不可靠，改用 `await Timer` 或直接 emit
- **鼠标拦截**：`visible = false` 的 Control 仍可能拦截鼠标，需同步设 `mouse_filter = IGNORE`

### 测试快捷键（发布前删除）
- `F3` — 直接触发胜利结算面板
- `F4` — 直接触发失败结算面板

---

## 📝 待实现功能

### P0（核心玩法）
- [ ] 敌人阻挡逻辑（近战角色挡住敌人，PVZ 式核心机制）
- [ ] 敌人类型视觉差异化（杂兵绿/鬼影黄/精英红）
- [ ] 鬼影 20% 闪避 + 精英重击技能

### P1（内容扩展）
- [ ] 第一章「暗夜突袭」新关卡
- [ ] 基础音效（攻击/受伤/部署/黎明）
- [ ] 设置面板音量控制

### P2（打磨）
- [ ] 撤回系统（黄昏撤回角色返还部分金币）
- [ ] 更多角色/敌人类型

---

## 👥 团队

| 姓名 | GitHub | 主要责任 |
|------|--------|---------|
| **王元辰** | [@AnonMoi](https://github.com/AnonMoi) | 核心系统开发 & 项目架构 |
| 杨其融 | [@GoodGuoZhi](https://github.com/GoodGuoZhi) | 角色与场景美术 |
| 于博言 | [@boYan223](https://github.com/boYan223) | 音效与特效 |
| 胡宗跃 | [@Hzy-0313](https://github.com/Hzy-0313) | 剧情与关卡设计 |
| 赵晨浩 | [@ZhaoChenhao6](https://github.com/ZhaoChenhao6) | 测试与版本管理 |

- **项目**：Bistu-OSSDT-2026 开源软件开发课程
- **引擎**：Godot 4.x（GDScript）
- **版本**：Demo v1.0（2026-07-06）
- **代码量**：~11,500 行（26个 .gd 脚本 + 14个 .tscn 场景 + JSON 配置）

---

*「钟摆未眠，黎明将至」*
