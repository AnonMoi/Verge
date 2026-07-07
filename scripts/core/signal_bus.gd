## signal_bus.gd
## 全局信号总线 — 各模块之间通信用的单例
## 在 project.godot 中设为 Autoload: SignalBus

extends Node

# ---------- 时间循环 ----------
@warning_ignore("unused_signal")
signal day_started(day_index: int)
@warning_ignore("unused_signal")
signal dusk_started(day_index: int)
@warning_ignore("unused_signal")
signal night_started(day_index: int)
@warning_ignore("unused_signal")
signal dawn_triggered(day_index: int)
@warning_ignore("unused_signal")
signal cycle_phase_changed(phase_name: String)

# ---------- 经济 ----------
@warning_ignore("unused_signal")
signal gold_changed(current_gold: int)
@warning_ignore("unused_signal")
signal gold_changed_display(amount: int)  # + / - 动画用
@warning_ignore("unused_signal")
signal mine_built(position: Vector2i)

# ---------- 角色 ----------
@warning_ignore("unused_signal")
signal character_deployed(char_id: String, position: Vector2i)
@warning_ignore("unused_signal")
signal character_recalled(char_id: String)
@warning_ignore("unused_signal")
signal character_died(char_id: String)
@warning_ignore("unused_signal")
signal character_killed_enemy(attacker_id: String, enemy_type: String)

# ---------- 敌人 ----------
@warning_ignore("unused_signal")
signal enemy_spawned(enemy_type: String, spawn_point: String)
@warning_ignore("unused_signal")
signal enemy_reached_core(enemy_type: String)
@warning_ignore("unused_signal")
signal enemy_died(enemy_type: String, gold_reward: int)
@warning_ignore("unused_signal")
signal boss_spawned(boss_type: String)
@warning_ignore("unused_signal")
signal boss_defeated()

# ---------- 核心 ----------
@warning_ignore("unused_signal")
signal core_damaged(amount: float, remaining_hp: float)
@warning_ignore("unused_signal")
signal core_hp_changed(remaining_hp: float)
@warning_ignore("unused_signal")
signal core_destroyed()

# ---------- 游戏状态 ----------
@warning_ignore("unused_signal")
signal game_won()
@warning_ignore("unused_signal")
signal game_over()
@warning_ignore("unused_signal")
signal wave_started(wave_index: int)
@warning_ignore("unused_signal")
signal wave_cleared(wave_index: int)
@warning_ignore("unused_signal")
signal day_completed(day_index: int)

# ---------- UI ----------
@warning_ignore("unused_signal")
signal show_notification(text: String, duration: float)
@warning_ignore("unused_signal")
signal show_damage_number(value: int, is_heal: bool)

# ---------- 剧情 ----------
@warning_ignore("unused_signal")
signal show_dialogue(dialogue_list: Array)
@warning_ignore("unused_signal")
signal dialogue_finished()
@warning_ignore("unused_signal")
signal chapter_opening_started(chapter_id: String)
@warning_ignore("unused_signal")
signal chapter_ending_started(chapter_id: String)
@warning_ignore("unused_signal")
signal lord_encountered(lord_id: String)
@warning_ignore("unused_signal")
signal branch_choice(choices: Array)

# ---------- 教学 ----------
@warning_ignore("unused_signal")
signal show_tutorial(text: String, position: Vector2)
@warning_ignore("unused_signal")
signal mine_placed()
@warning_ignore("unused_signal")
signal character_deployed(char_id: String)
@warning_ignore("unused_signal")
signal game_started()
