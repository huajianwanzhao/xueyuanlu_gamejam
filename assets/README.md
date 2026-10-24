# 素材目录

- `sprites/` 美术图（PNG，带透明通道）
- `audio/sfx/` 音效（wav），文件名 = 代码里的名字
- `audio/music/` 音乐（ogg 循环）
- `fonts/` 中文字体（导出 Web 时必须用，见 docs/05）

**玩家素材怎么接**（三级自动降级，代码都不用改）：

1. **只交一张静态图** → 存成 `sprites/player/player_idle.png`，游戏自动用它，并按 56px 高自动缩放。
2. **交逐帧动画** → 框选 `idle_01.png / run_01.png / jump_01.png` → 右键「新建 SpriteFrames」→ 动画名改成 `idle` `run` `jump`（可加 `die`）→ 存成 `sprites/player/player_frames.tres`，优先级高于静态图。
3. **都没交** → 继续用纯色块，不会报错。

导入时记得给每张图勾 **Mipmaps** + **Fix Alpha Border**（多选一次改完），否则缩小时边缘发闪、透明边有黑边。

规格见 `docs/03_美术素材规格.md`。
