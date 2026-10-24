# 素材目录

- `sprites/` 美术图（PNG，带透明通道）
- `audio/sfx/` 音效（wav），文件名 = 代码里的名字
- `audio/music/` 音乐（ogg 循环）
- `fonts/` 中文字体（导出 Web 时必须用，见 docs/05）

**玩家动画怎么接**：美术把 `idle_01.png / run_01.png / jump_01.png` 放进 `sprites/player/`，
程序在编辑器里框选这些图 → 右键「新建 SpriteFrames」→ 动画名改成 `idle` `run` `jump`（可加 `die`）
→ 存成 `sprites/player/player_frames.tres`。文件一出现，游戏自动从纯色块切成动画，**代码不用改**。

规格见 `docs/03_美术素材规格.md`。
