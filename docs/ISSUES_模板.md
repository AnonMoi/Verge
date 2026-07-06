# GitHub Issues 创建清单

> 在 GitHub 仓库 Issues 标签中逐条创建以下 Issue。
> 创建后在右侧 Assignees 中选择对应负责人，Labels 中勾选对应标签。

---

## 👥 成员分工总览

| 姓名 | GitHub | 主要责任 | 负责内容 |
|------|--------|---------|---------|
| **王元辰** | @AnonMoi | **核心系统开发 & 项目架构** | 全部游戏系统（时间循环/角色/敌人/UI/经济/Autoload）、底层架构、数值平衡、工程搭建（Git/GitHub Actions）、全部文档 |
| 杨其融 | @GoodGuoZhi | **角色与场景美术** | 角色精灵图、敌人精灵图、地图背景素材、UI 视觉美化 |
| 于博言 | @boYan223 | **音效与特效** | 游戏音效、背景音乐、攻击/死亡/黎明等视觉特效 |
| 胡宗跃 | @Hzy-0313 | **剧情与关卡设计** | 世界观设定、剧情文本、关卡策划、Boss 设计 |
| 赵晨浩 | @ZhaoChenhao6 | **测试与版本管理** | 完整功能测试、Bug 记录与追踪、文件统筹、版本发布、答辩演示 |

## Issue 1: 项目工程 — 完善项目基础配置 ✅

**标题**: 完善项目工程配置（LICENSE + CONTRIBUTING + CI/CD）

**内容**:
```
## 已完成
- [x] 添加 MIT LICENSE 文件
- [x] 添加 CONTRIBUTING.md 贡献指南
- [x] 配置 GitHub Actions（GDScript 语法检查 + Godot 导出）
```

**标签**: `documentation`
**负责人**: @AnonMoi
**状态**: ✅ 已完成，无需创建

---

## Issue 2: 核心玩法 — 实现敌人阻挡逻辑

**标题**: [P0] 实现敌人阻挡逻辑（近战角色挡住敌人）

**内容**:
```
## 问题描述
character_base.gd 中有 block_count 属性（先锋2/重装4），但 enemy_movement.gd
未实现阻挡检测。敌人经过角色所在格子时不会停下来，直接穿过防线攻击核心。
这是 PVZ 式塔防的核心机制，当前缺失。

## 期望行为
- 近战角色（先锋/重装）部署在路径格上时，经过该格的敌人被阻挡
- 阻挡数用完后，多余的敌人可以穿过
- 被阻挡的敌人与角色互相攻击

## 涉及文件
- scripts/character/character_base.gd
- scripts/enemy/enemy_movement.gd
```

**标签**: `bug`, `P0`
**负责人**: @AnonMoi

---

## Issue 3: 敌人系统 — 敌人精灵图配置 ✅

**标题**: [P0] 三种敌人精灵图配置（已完成，待优化）

**内容**:
```
## 已完成
三种敌人已各自使用独立的精灵图资源，包含完整的 idle/attack/hit/death 动画：
- 混沌杂兵（chaos_grunt）→ Blue_Slime 素材（7帧 attack / 3帧 death / 6帧 hit / 8帧 idle）
- 迅捷鬼影（swift_ghost）→ Minotaur_1 素材（5帧 attack / 5帧 death / 3帧 hit / 12帧 idle），半透明黄色调
- 黑铁精英（iron_elite）→ Blue_Slime 素材（复用），紫色调 + 放大 1.3x/1.4x

## 待优化
- [ ] enemy_elite 是否需要独立素材（当前复用 Blue_Slime，仅 modulate 调色+scale 放大）
- [ ] 未使用的精灵帧是否需要清理（Blue_Slime: Jump/Run/Run+Attack 等未被引用）
- [ ] 确认各动画帧数与游戏实际表现匹配

## 涉及文件
- scenes/main_game/enemy.tscn
- scenes/main_game/enemy_ghost.tscn
- scenes/main_game/enemy_elite.tscn
- scenes/main_game/enemy_grunt.tscn
- character_sources/Blue_Slime/
- character_sources/Gorgon_1/
- character_sources/Minotaur_1/
```

**标签**: `enhancement`, `P0`
**负责人**: @AnonMoi

---

## Issue 4: 音效系统 — 添加游戏音效和背景音乐

**标题**: 添加游戏音效系统（攻击/受伤/部署/黎明/背景音乐）

**内容**:
```
## 任务描述
当前游戏完全静音，需要添加基础音效和背景音乐。

## 待完成
- [ ] 创建 AudioManager 单例管理音频
- [ ] 添加攻击音效（近战挥砍 / 远程射击）
- [ ] 添加受击音效（角色受伤 / 敌人受伤）
- [ ] 添加部署音效（角色部署 / 金矿放置）
- [ ] 添加黎明清屏音效（钟声）
- [ ] 添加白天/黄昏/夜晚三阶段背景音乐
- [ ] 添加胜利/失败音效
- [ ] 设置面板音量滑块控制音效/音乐音量

## 涉及文件
- 新建 scripts/core/audio_manager.gd（Autoload 单例）
- scripts/ui/pause_menu.gd（设置面板音量控制）
- resources/audio/（音频资源目录）
```

**标签**: `enhancement`, `feature`
**负责人**: @boYan223

---

## Issue 5: 视觉特效 — 添加游戏特效

**标题**: 添加游戏视觉特效（攻击特效/死亡特效/黎明增强/伤害数字）

**内容**:
```
## 任务描述
当前游戏缺少视觉特效反馈，战斗体验平淡。

## 待完成
- [ ] 攻击命中特效（近战刀光 / 远程子弹命中闪光）
- [ ] 敌人死亡特效（碎裂/消散动画）
- [ ] 伤害数字飘字（从受击单位上浮，红色数字）
- [ ] 金矿产出金币飘字（+10 金）
- [ ] 黎明特效增强（当前已有基础白闪，可添加粒子/光柱）
- [ ] 部署特效（角色出现时的落地效果）

## 涉及文件
- scenes/effects/（新建特效场景）
- scripts/effects/（新建特效脚本）
```

**标签**: `enhancement`, `feature`
**负责人**: @boYan223, @Hzy-0313

---

## Issue 6: 角色美术 — 完善精灵动画帧 ✅

**标题**: 完善角色 AnimatedSprite2D 动画帧配置（已有基础，待优化）

**内容**:
```
## 已完成
三个角色已使用独立的精灵图资源，含 attack + default 动画：
- 先锋 Pioneer → rika_9721bbe0.png（attack 16帧 + default 1帧）
- 重装 Defender → rika_8ad2355f.png（attack 16帧 + default 1帧）
- 狙击 Sniper → rika_3f8e6078 (1).png（attack 24帧 + default 1帧）

## 待优化
- [ ] 添加 hit（受击）动画帧
- [ ] 添加 death（死亡）动画帧
- [ ] 调整角色 scale 使三个角色尺寸统一协调
- [ ] 确认 attack 动画帧数与攻击冷却时间匹配

## 涉及文件
- character_sources/（美术源文件）
- scenes/main_game/character_pioneer.tscn
- scenes/main_game/character_defender.tscn
- scenes/main_game/character_sniper.tscn
```

**标签**: `enhancement`, `art`
**负责人**: @GoodGuoZhi

---

## Issue 7: 场景美术 — 地图背景分层与 UI 美化 ✅

**标题**: 使用分层素材替换单一背景图 + UI 面板美化（已有基础，待完善）

**内容**:
```
## 已完成
- 教学关背景已使用 Battleground1.png（1920x1080）
- 核心（Core）已使用独立精灵图：5abb8617a1f192f3f6334b8a8ff6d1d7-no-bg (2).png
- character_sources/PNG/ 下有 4 套完整的分层战场素材（Battleground1~4，各含 sky/hills/ruins/statue 等图层）
- PathVisual 仍为纯灰 ColorRect，无纹理

## 待完成
- [ ] 用分层素材（sky + hills + ruins + ground 等）替换单一背景图
- [ ] 根据时间阶段切换背景色调（白天亮色 / 夜晚暗色）
- [ ] 路径格纹理化（替换纯灰 ColorRect 为石板/草地纹理）
- [ ] HUD 顶部栏美化（金币/核心HP 图标替换 emoji）
- [ ] 部署按钮美化（角色头像图标 + 费用，替代纯文字按钮）
- [ ] 高台位视觉标识美化（当前仅蓝色半透明高亮）

## 可用素材
character_sources/PNG/ 下 4 套战场背景，每套含 Bright/Pale 两种色调变体

## 涉及文件
- scenes/main_game/main_game.tscn（Background + PathVisual 节点）
- scripts/ui/deploy_panel.gd（部署按钮样式）
- scripts/ui/hud.gd（HUD 图标）
```

**标签**: `enhancement`, `art`
**负责人**: @GoodGuoZhi

---

## Issue 8: 剧情系统 — 添加世界观与剧情文本

**标题**: 添加游戏世界观设定与剧情文本

**内容**:
```
## 任务描述
游戏需要世界观设定和剧情文本，增强沉浸感。

## 待完成
- [ ] 编写世界观背景设定（钟摆核心的来历、时间循环的成因）
- [ ] 编写角色背景故事（先锋/重装/狙击 各 100-200 字）
- [ ] 编写敌人背景描述（混沌杂兵/迅捷鬼影/黑铁精英 对应 Blue_Slime/Gorgon/Minotaur 的设定）
- [ ] 编写教学关剧情文本（白天开始/夜晚开始/黎明/胜利/失败 的旁白或对话）
- [ ] 设计后续章节剧情大纲（第一章「暗夜突袭」等）

## 涉及文件
- 新建 docs/世界观设定.md
- 新建 docs/剧情设计.md
```

**标签**: `documentation`, `design`
**负责人**: @Hzy-0313

---

## Issue 9: 关卡设计 — 第一章「暗夜突袭」策划

**标题**: 设计第一章「暗夜突袭」关卡配置

**内容**:
```
## 任务描述
当前仅有教学关，需要策划第一章正式关卡。

## 待完成
- [ ] 编写第一章剧情大纲（故事背景、出场角色、Boss 设定）
- [ ] 设计关卡地图布局（路径走向、部署位数量、高台位分布）
- [ ] 设计敌人波次配置（Day 1~4 每天黄昏+夜晚的出怪计划）
- [ ] 设计 Boss 机制（如有）
- [ ] 编写关卡对话/旁白文本

## 可用素材
character_sources/PNG/ 下 Battleground2~4 可作为新关卡背景素材

## 涉及文件
- 新建 docs/关卡设计_第一章.md
```

**标签**: `design`, `documentation`
**负责人**: @Hzy-0313

---

## Issue 10: 项目测试 — 完整功能测试与 Bug 记录

**标题**: 教学关完整运行测试与 Bug 记录修复

**内容**:
```
## 任务描述
按照测试清单完整运行教学关，记录发现的所有问题，并协助修复验证。

## 测试清单
- [ ] F5 启动 → splash_screen → 主菜单 → 章节选择 → 教学关
- [ ] 部署先锋/重装/狙击/金矿，确认金币扣减 + 角色正常出现
- [ ] Day 1~3 完整流程（白天/黄昏/夜晚/黎明）
- [ ] 胜利结算面板（星级 + 数据 + 按钮正常点击）
- [ ] 失败结算面板（核心被摧毁后的显示 + 按钮）
- [ ] 暂停菜单全部功能（继续/设置/返回章节/返回主菜单）
- [ ] 倍速 1x ↔ 2x 切换
- [ ] 从胜利/失败面板返回章节选择/主菜单
- [ ] 窗口缩放时 UI 是否正常
- [ ] 三种敌人精灵图是否正确显示

## 发现的问题
（测试后在此 Issue 下用评论逐条记录，创建子 Issue 跟踪修复）
```

**标签**: `testing`
**负责人**: @ZhaoChenhao6

---

## Issue 11: 项目集成 — 文件统筹与版本发布

**标题**: 项目文件统筹、版本管理与最终集成

**内容**:
```
## 任务描述
统筹管理所有成员提交的文件，确保项目可正常运行，准备最终发布。

## 待完成
- [ ] 汇总各成员提交的代码/资源/文档，检查集成后能否正常运行
- [ ] 清理未使用的素材文件（character_sources/ 下未被引用的 png/gif）
- [ ] 检查 .gitignore 是否正确（排除 .godot/ .uid/ .import）
- [ ] 整理 project.godot 的 Autoload 配置（如新增 AudioManager 后需注册）
- [ ] 最终版本验证（完整运行教学关，确认所有功能正常）
- [ ] 删除测试快捷键（F3/F4）
- [ ] 创建 v1.1.0 版本 Tag
- [ ] 创建 GitHub Release 并编写 Release Notes
- [ ] 准备答辩演示流程和演示要点

## 涉及范围
全项目文件
```

**标签**: `release`, `integration`
**负责人**: @ZhaoChenhao6
