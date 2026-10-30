# 学院路 GameJam · 弹射清版

一个「幽灵态贴到敌人身上 → 实体化把它弹飞 → 连锁碰撞」的 2D 弹射清版原型。
当前是**可玩 MVP**：一张场地、5 个敌人、1 面墙，没有 UI、没有胜负判定、没有美术。

## 在线试玩（网页，随时最新）

https://jinsaoqu.cc.cd/



**首次打开要下约 10MB 的引擎本体**（wasm 原始 39.5MB，Pages 用 gzip 压到 10.2MB），所以要等十几秒；
之后走 Service Worker 缓存，刷新基本秒开。卡在 Godot 启动图超过半分钟，就 Ctrl+F5 强刷一次。

## 操作

| 操作 | 按键 |
| --- | --- |
| 移动 | 方向键 |
| 实体化 / 虚化 | 鼠标左键 |

开局是**幽灵态**：半透明、没有碰撞体，能穿墙、也能直接穿过敌人，跑得快（700），但打不到人。

幽灵态下**一直有一根青色箭头**，指着离你最近的敌人——这就是「射击方向预览」：贴上人时箭头会变亮变粗、一直穿到敌人身后，
告诉你「现在按左键，它就会沿这条线飞出去」。

贴着敌人（两个圆有重叠）按左键 → **实体化**：重叠的敌人沿「两球圆心连线」以 2600 的速度被弹飞，
同时再闪一道青色箭头标出弹飞方向。没贴到人就只是安静地变回实体，什么也不会发生。

实体态：不透明、会被敌人追、会被子弹打中，速度慢（500），冷却 5 秒，0.15 秒无敌帧。
再按左键 → 变回幽灵态。节奏是「幽灵态穿进人堆 → 实体化炸开 → 幽灵态溜走」。

> 为什么是「实体化」而不是鼠标瞄准：幽灵态能穿模，所以**唯一的攻击手段就是走到敌人身上再变实**。

## 伤害规则

| 事件 | 伤害 |
| --- | --- |
| 被实体化冲击弹飞 | 50（`launch_damage` 20 + `overlap_impact_damage` 30） |
| 被飞行中的敌人撞到 | 法向相对速度 × 0.06（擦边几乎不掉血） |
| 自己撞墙 | 自己速度 × 0.2，并反弹 |
| 被尸体滑行砸到 | 法向相对速度 × 0.12 |

敌人 100 血。撞人按**真实球体碰撞**算：正碰几乎把速度全传过去、自己停下；斜碰只传法向分量，
自己顺着切线滑走（恢复系数 0.85，正碰每跳约 ×0.925）。同一次攻击的子弹互不伤害，避免自打自穿。

## 目录

    项目根目录
    ├─ project.godot        项目设置（渲染器 = gl_compatibility，网页版必需）
    ├─ export_presets.cfg   Web + Windows 两个导出预设（CI 靠它出包）
    ├─ icon.svg             目前所有角色共用的占位图
    ├─ scenes/
    │   ├─ levels/level_01.tscn  主场景：玩家 + 5 个敌人 + 1 面墙
    │   ├─ player.tscn      玩家：幽灵/实体状态机 + 实体化冲击
    │   ├─ enemy.tscn       敌人：NORMAL/AIMING/STUNNED/BULLET/DEAD、连锁碰撞、尸体滑行
    │   ├─ enemy_bullet.tscn    敌人子弹（Area2D）
    │   └─ wall.tscn        墙（RectangleShape2D 200×10）
    ├─ script/              player.gd / enemy.gd / enemy_bullet.gd / GameManager.gd / launch_arrow.gd
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

- 实体化前没有「是否贴到人」的提示，贴没贴上全靠肉眼，可以考虑加一圈判定范围高亮。
- 没有 UI：血条、得分、关卡进度、胜负都没有。
- 敌人只会直线追玩家，不会绕墙。
- 没有边界墙，玩家能走出画面。
