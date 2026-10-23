# 学院路 Game Jam · 协作仓库

> 一个**能直接跑**的 Godot 4.7 平台跳跃骨架：主菜单 → 两关 → 暂停 → 通关结算，全流程可玩、可导出。
> 骨架先跑着，玩法边做边换。

**当前状态**：模板骨架已提交，美术/音效素材待接入，玩法方向待定。

**在线试玩**：<https://huajianwanzhao.github.io/xueyuanlu_gamejam/>

每次 push 到 `main`，GitHub Actions 会自动把最新版本导出成 Web 版发布到上面这个地址（约 2 分钟出包）。电脑浏览器打开即玩；手机上暂时没有触屏操作，先别指望。

---

## 一、一分钟上手

| 步骤 | 做什么 |
|---|---|
| 1 | 装 **Godot 4.7.2**（版本必须一致，4.6 打不开、4.8 可能改格式） |
| 2 | `git clone https://github.com/huajianwanzhao/xueyuanlu_gamejam.git` |
| 3 | 打开 Godot → **导入** → 选 clone 下来的那个文件夹 → 打开 |
| 4 | 按 **F5** 跑起来 |

操作：`A/D` 或 `←/→` 移动，`空格` 跳跃，`Esc` 暂停，`R` 重开本关。

> **不要点 GitHub 上的 "Download ZIP"。** ZIP 里没有 git，你改的东西传不回来，最后只能靠群里发文件，等着互相覆盖。
>
> 调试技巧：主菜单按数字键 `1` `2` 直接进对应关卡，不用每次从头玩。

---

## 二、谁负责什么

| 路径 | 内容 | 主要负责 | 其他人 |
|---|---|---|---|
| `levels/level_*.tscn` | **关卡内容**（平台、金币、终点、出生点） | 策划 | 只读 |
| `assets/sprites/`、`assets/audio/` | 图片、音效、音乐、字体 | 美术 | 只读 |
| `scenes/`、`scripts/` | 场景结构与游戏逻辑 | 程序 | 只读 |
| `project.godot`、`export_presets.cfg` | 项目设置、导出配置 | 程序 | **别碰** |
| `docs/` | 策划/美术/流程文档 | 全队 | 可改 |

**边界就是省时间**：策划只改 `levels/`，美术只往 `assets/` 放文件，两个人永远不会冲突；程序改代码时也不会被关卡改动干扰。

---

## 三、协作规则（这部分最重要）

### 1. 动手前先拉

```powershell
git pull --rebase
```

用 `--rebase` 而不是默认 merge，历史才不会变成一堆 "Merge branch"。

### 2. 小改动直接推 main，大改动开分支

团队只有 4 个人，正常情况直接 `git push` 到 `main` 就行。**只有要动下面「高危文件」时**才开分支：

```powershell
git switch -c feat/double-jump
# 改完
git push -u origin feat/double-jump
```

**`main` 必须随时是可运行的**——任何时候 pull 下来按 F5 都得能玩，因为出包、给评审看都从这里来。

### 3. 提交信息写前缀

```text
feat: 加二段跳
fix: 掉坑重开没重置金币
level: 第三关（加了尖刺段）
art: 玩家跑步 4 帧
docs: 更新美术规格
```

一眼能看出谁动了什么，出事了好 revert。

### 4. 高危文件：改之前群里喊一声

| 文件 | 为什么会撞 |
|---|---|
| `scenes/game.tscn` | 所有人都要往里挂节点 |
| `project.godot` | 输入映射、窗口尺寸、自动加载 |
| `ui/theme.tres` | 全局字体 |
| `scripts/autoload/game_manager.gd` | 全局状态，加关卡要改 `LEVELS` |
| `export_presets.cfg` | 导出配置 |

规则：**改完立刻 push，别攒着**。攒三小时再推 = 三个人同时改同一行。

### 5. 不要在 Godot 里「另存为覆盖」

两个人同时开着编辑器改同一个 `.tscn`，后保存的会把先保存的整个覆盖掉，**没有提示**。改之前先 pull，改完立刻推。

### 6. 绝对不要提交

- `.godot/` —— 引擎缓存，每台机器都不一样（已在 `.gitignore`，不要 `git add -f` 强塞）
- `build/`、`export/` —— 导出产物
- `.psd` / `.ai` / `.aseprite` / `.flp` 等**源工程文件** → 放网盘，只提交导出的 png / wav / ogg
- 任何没授权的素材（网上扒的音效、商用字体）

### 7. 冲突了别硬刚

`.tscn` 是文本格式，冲突时差异长得像乱码，**手改基本必翻车**。正确做法：

```powershell
git checkout --ours   levels/level_03.tscn   # 保我这版
git checkout --theirs levels/level_03.tscn   # 保对方那版
```

保一边，另一边让对方花 30 秒重做。别在编辑器里对着 `<<<<<<<` 挣扎。

---

## 四、策划：只碰 `levels/`

完整图文步骤见 [`docs/04_策划摆关卡指南.md`](docs/04_策划摆关卡指南.md)，核心三条：

1. 从 `scenes/objects/` 把 `platform.tscn`、`coin.tscn`、`goal.tscn` **拖进画布**就是关卡内容。
2. 选中后在右侧检查器改 `Position` 和 `size`，碰撞体自动跟着变。
3. 改完按 **F5 自己玩一遍**再提交——摆歪的平台在编辑器里看不出来。

**加新关卡**：复制 `level_01.tscn` → 改名 `level_03.tscn` → 找程序在 `scripts/autoload/game_manager.gd` 的 `LEVELS` 数组里加一行（这行归程序改，别自己动）。

---

## 五、美术：只往 `assets/` 放文件

**规格、尺寸、命名**全在 [`docs/03_美术素材规格.md`](docs/03_美术素材规格.md)，开工前先看那张表。

```text
assets/sprites/player/idle_01.png
assets/sprites/objects/coin.png
assets/sprites/tiles/ground.png
assets/audio/sfx/coin.wav
assets/audio/music/bgm.ogg
assets/fonts/NotoSansSC-Regular.ttf
```

- 全小写、下划线、不要中文名、不要空格——**代码里就是按文件名找的**。
- 交付节奏：占位图（D3 前）→ 首版正式图（D6 前）→ 全部替换（D10 前）→ 只修瑕疵（D13 前）。
- 提交时只提交**成品图 / 音频**。源文件（psd、aseprite）别进仓库，仓库会被撑爆，clone 一次要等十分钟。

---

## 六、程序

- `scenes/` 存结构，`scripts/` 存逻辑，一一对应。
- 金币加分走 `GameManager.add_score()` → `score_changed` 信号 → HUD 自己刷新，**别直接抓 HUD 节点**。
- 加音效不用写代码：文件丢进 `assets/audio/sfx/`，名字对上 `AudioManager.play_sfx("coin")` 就会响；没文件静默，不报错。
- 中文字体现在是系统字体，**WebGL 导出会变方块**，修法见 [`docs/05_导出与提交清单.md`](docs/05_导出与提交清单.md) 第三节。
- 渲染保持 **GL Compatibility**，切到 Forward+ 网页端直接挂。

---

## 七、每天的节奏

| 时间 | 做什么 |
|---|---|
| 早上开工 | `git pull --rebase`，把别人的改动吃掉，跑一遍 F5 确认没坏 |
| 干活中 | 完成一小块就 commit，别攒到晚上 |
| 收工前 | `git push`；程序负责出一次 Web 包自己玩一遍 |
| 出事时 | 群里发一句「我改了 XXX，可能冲突」，比事后回滚便宜得多 |

**每天必须 push。** 谁电脑挂了，全队不能跟着归零。

---

## 八、出问题了

| 现象 | 原因 | 解法 |
|---|---|---|
| 场景里贴图变红 / 丢失 | 素材没提交，或 `.import` 被误忽略 | 确认 `*.png` 和同名 `.import` 都在仓库里 |
| 一堆 "UID changed" 警告 | `.gd.uid` 文件丢失 | 别忽略 `*.gd.uid`，`git status` 看有没有被删 |
| 我的关卡被别人覆盖了 | 两个人同时开编辑器改同一个 `.tscn` | 只能重做；以后改前先 pull、改完立刻推 |
| Web 版中文全是方块 | 用了系统字体 | 按 docs/05 换成品字体 |
| `.godot/` 下面冒出一堆改动 | 缓存不该进库 | `git rm -r --cached .godot`，确认 `.gitignore` 生效 |
| pull 完 Godot 里看不到新文件 | 编辑器没刷新 | 切回 Godot 窗口会自动重扫；还不行就 **项目 → 重新加载当前项目** |

---

## 九、这些**暂时不要**做

存档、设置菜单（音量 / 分辨率）、手柄支持、多语言、粒子特效、可交互 NPC。

14 天只够做「一个机制 + 3~5 关 + 菜单 + 打磨」。多一个系统就烂尾。详见 [`docs/01_14天作战计划.md`](docs/01_14天作战计划.md)。
