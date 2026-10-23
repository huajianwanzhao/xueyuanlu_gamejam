# 学院路 Game Jam · 程序岗起步模板

一个**能直接跑**的 Godot 4.7 最小可玩项目：主菜单 → 两关平台跳跃（移动/跳跃/吃金币/掉坑重开/过关）→ 暂停 → 通关结算。
代码是给你当骨架用的：把玩法换掉，但结构别推翻。

## 30 秒跑起来

1. 双击 `D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe` 打开 Godot。
2. 导入 → 选这个文件夹 `D:\学院路gamejam` → 打开。
3. 按 **F5**（运行项目）。**F6** 只运行当前打开的场景。

操作：`A/D` 或 `←/→` 移动，`空格` 跳跃，`Esc` 暂停，`R` 重开本关。

**调试小技巧**：在主菜单按数字键 `1` `2` … 可以直接从第 N 关开始，不用每次从头玩。

## 目录结构

| 路径 | 作用 | 谁改 |
|---|---|---|
| `scenes/main_menu.tscn` | 主菜单 | 程序 |
| `scenes/game.tscn` | 关卡容器（HUD + 暂停 + 关卡挂载点） | 程序 |
| `scenes/win_screen.tscn` | 通关结算 | 程序/策划 |
| `scenes/player/player.tscn` | 玩家 | 程序 |
| `scenes/objects/` | 平台 / 金币 / 终点 | 程序（只加新物件） |
| `scenes/ui/` | HUD / 暂停菜单 | 程序 |
| `levels/level_01.tscn, level_02.tscn` | **关卡内容** | **策划（重点）** |
| `scripts/autoload/` | GameManager（全局状态）、AudioManager（音频） | 程序 |
| `ui/theme.tres` | 全局字体（中文） | 程序 |
| `export_presets.cfg` | Web 导出预设 | 程序 |
| `docs/` | 策划/美术/流程文档 | 全队 |

## 三个核心概念（看懂这三句就能改）

1. **Autoload = 全局单例**。`GameManager` 和 `AudioManager` 在任何脚本里直接写名字就能用，不用传引用。
2. **关卡是纯内容**。`levels/*.tscn` 里只有平台、金币、玩家出生点、终点；逻辑全在 `scripts/`。所以策划改关卡不会改坏代码。
3. **信号解耦**。金币加分 → `GameManager.add_score()` → `score_changed` 信号 → HUD 自己更新。谁都不用去找谁。

## 加一关 / 改关卡顺序

1. 在 `levels/` 里复制 `level_01.tscn`，改名叫 `level_03.tscn`。
2. 打开 `scripts/autoload/game_manager.gd`，在 `LEVELS` 数组里加一行 `"res://levels/level_03.tscn"`。
3. 顺序就是数组顺序。

## 加音效 / 音乐（不用改代码）

把文件丢进目录即可，名字对上就会播：

- `assets/audio/sfx/coin.wav`、`jump.wav`、`die.wav`、`win.wav`
- `assets/audio/music/bgm.ogg`

代码里调用 `AudioManager.play_sfx("coin")`，没文件就静默，不会报错。

## 每天的工作流（照做就不会翻车）

1. 早上 `git pull` → 开工。
2. 每完成一小块就 commit 一次（别攒到最后）。
3. **每天结束前必须做一次 Web 导出**并自己玩一遍（见 `docs/05_导出与提交清单.md`）。
4. 晚上 `git push`，然后才睡觉。

## 这个模板**没有**的东西（自己按需加，别提前加）

存档、设置菜单（音量/分辨率）、手柄支持、多语言、粒子特效、可交互 NPC。
比赛期间除非玩法必须，否则一个都别加。

## 已知注意点

- 模板用**纯色矩形**当美术占位。美术出图后，把 `ColorRect` 换成 `Sprite2D` 即可，代码不用动。
- 中文字体用的是系统字体（`SystemFont`），**桌面端正常，WebGL 导出会缺字**。修复方法见 `docs/05_导出与提交清单.md`。
- 视口是 640×360（像素风友好）。想改成 1280×720：项目设置 → 显示 → 窗口 → 视口宽高。
- 渲染用 GL Compatibility，为了 WebGL 导出能跑；别切到 Forward+，网页端会挂。
