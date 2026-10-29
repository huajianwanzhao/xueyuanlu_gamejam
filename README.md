# 学院路 GameJam · 弹射清版

一个「幽灵状态瞄准 → 出杆瞬移 → 弹飞敌人 → 连锁碰撞得分」的 2D 弹射清版原型。
当前是**可玩 MVP**：一张场地、4 个敌人、1 面墙，没有 UI、没有胜负判定、没有美术。

## 在线试玩（网页，随时最新）

https://huajianwanzhao.github.io/xueyuanlu_gamejam/

每次 push 到 main，GitHub Actions 大约 2 分钟重新导出网页版并部署，刷新页面即最新构建。

**首次打开要下约 10MB 的引擎本体**（wasm 原始 39.5MB，Pages 用 gzip 压到 10.2MB），所以要等十几秒；
之后走 Service Worker 缓存，刷新基本秒开。卡在 Godot 启动图超过半分钟，就 Ctrl+F5 强刷一次。

## 操作

| 操作 | 按键 |
| --- | --- |
| 移动 | 方向键 |
| 出杆 / 状态切换 | 鼠标左键（朝鼠标方向） |

开局是**幽灵态**：半透明、能穿墙、跑得快（700），但打不到人。
左键朝鼠标方向「出杆」→ 瞬间移动到落点，落点附近（400px 内、离鼠标最近）的敌人会被弹飞；
落点后变成**实体态**：不透明、会被敌人追、速度慢（500），冷却 1 秒，0.15 秒无敌帧。
实体态再按左键 → 变回幽灵态。节奏是「幽灵态找角度 → 出杆 → 实体态躲 1 秒 → 再出杆」。

## 伤害规则

| 事件 | 伤害 |
| --- | --- |
| 被出杆直接弹飞 | 固定 50 |
| 被飞行中的敌人撞到 | 撞击者速度 × 0.2 |
| 自己撞墙 | 自己速度 × 0.2，并反弹 |
| 被尸体滑行砸到 | 尸体速度 × 0.15（需 > 10） |

敌人 100 血。子弹撞到别的敌人时把 85% 速度传给它（连锁），自己减速到 60% 但**不反弹**，
所以一次出杆能像打台球一样串起一串敌人。同一次攻击的子弹互不伤害，避免自打自穿。

## 目录

    项目根目录
    ├─ project.godot        项目设置（渲染器 = gl_compatibility，网页版必需）
    ├─ export_presets.cfg   Web + Windows 两个导出预设（CI 靠它出包）
    ├─ world.tscn           主场景：玩家 + 4 个敌人 + 1 面墙
    ├─ player.tscn/.gd      玩家：幽灵/实体状态机、出杆、路径扫掠、弹射
    ├─ enemy.tscn/.gd       敌人：NORMAL/STUNNED/BULLET/DEAD 四态、连锁碰撞、尸体滑行
    ├─ wall.tscn            墙（RectangleShape2D 200×10）
    ├─ 游戏结构.md          实现细节文档，看代码前先看它
    └─ .github/workflows/   推 main 出网页、发 tag 出 exe

## 三个人各自改哪里

- **策划**：改 `world.tscn`（敌人摆位、加墙、加敌人，复制节点即可）、`player.tscn` 里的 `ghost_speed`/`real_speed`、`enemy.tscn` 里的 `max_health`/`speed`。都是检查器里能拖的数值，不用碰代码。
- **美术**：把 `player.tscn` / `enemy.tscn` 里 Sprite2D 的 `icon.svg` 换成贴图；贴图放 `art/`（自己建目录）。
- **程序**：`player.gd`、`enemy.gd`。

## 协作规矩

- 动手前先 `git pull --rebase`。
- 提交前缀：`feat:` `fix:` `level:` `art:` `docs:`。
- 只改 .tscn 里的数值基本不会冲突；**同时改 project.godot / export_presets.cfg / 同一个 .tscn 容易打架**，要改先说一声。
- `.godot/`、`build/` 已经在 .gitignore 里，别提交；`*.import` 和 `*.gd.uid` **必须**提交，少了会丢贴图引用。
- 文档、策划案、数值表放腾讯文档；能进游戏包的东西才进 Git。

## 本地跑

双击 `project.godot` 用 Godot 4.7 打开，F5 运行。

## 自动出包

- push 到 `main` → 网页版自动部署（Pages）。
- 打 tag → 自动出 Windows exe 并挂到 Release：先 `git tag v0.2.0` 再 `git push origin v0.2.0`。

## 已知待办

- 玩家没有任何出杆提示（瞄准线、落点、扫掠范围都看不见），手感靠猜。
- 没有 UI：血条、得分、关卡进度、胜负都没有。
- 敌人只会直线追玩家，不会绕墙。
- 没有边界墙，玩家能走出画面。
