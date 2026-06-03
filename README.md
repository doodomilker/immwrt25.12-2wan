# immwrt25.12-2wan

这是一个面向 `N100 / x86-64` 的 ImmortalWrt 自定义编译项目，目标不是做单一固件，而是维护三条明确分工的发布线：

- `main`：主路由完整全家桶
- `opdocker2wan`：Docker 旁路由 + `wan2`
- `pve2wan`：PVE 双 OP 精简版

这个仓库只负责“怎么稳定编出来”，不负责“线上怎么部署”。部署、运行、排障和快照都统一放到外部文档里，不混进 git。

> 仓库里只放编译相关内容：workflow、configs、编译脚本、首启脚本。<br>
> 部署方案 / PVE 规划 / 运行时快照 / 排障记录统一放到 `star/docs/servers/openwrt-192.168.50.1/`。

## 项目目标

这个项目的核心诉求很简单：

1. 让三条线各自有清楚的职责
2. 让每条线都能锁定稳定源码版本编译
3. 让 release 一眼能看出是哪条线、改了什么、适合什么场景
4. 让编译产物尽量“开箱即用”，少靠手工补救

## 三条发布线

| 分支 | 定位 | 适合场景 |
|---|---|---|
| `main` | 主路由完整全家桶 | 功能尽量全、管理页尽量齐、长期物理机主路由 |
| `opdocker2wan` | Docker 旁路由 + `wan2` | 主路由上保留 Docker，容器走 `wan2`，同时保留 Wi‑Fi 和双 PassWall |
| `pve2wan` | PVE 双 OP 精简版 | PVE 里跑双 OpenWrt VM，做 keepalived / VRRP / fallback |

## 每条线的侧重点

### `main`
- 主路由完整全家桶
- 保留 Docker / Dockerman
- 保留 Wi‑Fi
- 保留 `PassWall` / `PassWall2` / `OpenClash`
- 保留 `SmartDNS`
- 保留 `Samba4` / `Alist`
- 保留 `Netdata` / `Nlbwmon` / `TTYD`

### `opdocker2wan`
- 主路由 + Docker 旁路由
- Docker 容器出口走 `wan2`
- 保留 Wi‑Fi
- 保留 `PassWall` / `PassWall2`
- 增加健康检查工具
- 保留 Docker / 磁盘 / 监控核心管理页

### `pve2wan`
- PVE 虚拟机专用
- 双 OP / 双 VIP / keepalived
- 保留 `PassWall` / `PassWall2`
- 保留 `SmartDNS`
- 保留 `keepalived`
- 保留健康检查基础工具
- 尽量精简，减少虚拟机负担

## 仓库边界

### 保留在本 repo 的内容
- GitHub Actions 编译流程
- 各分支对应的编译脚本
- 各分支对应的固件配置
- `scripts/` 首启默认设置脚本
- 与“能否成功编译 / 开箱默认行为”直接相关的改动

### 不放进本 repo 的内容
- N100 线上部署步骤
- Docker 容器启动 / 重建实录
- PassWall 节点、订阅、UUID
- VPS IP、域名、设备 MAC
- 路由器运行时快照、`nft` dump、`dhcp` dump
- PVE 双 OP HA 规划

这条边界是硬规则：即使仓库是 private，也不把敏感运维内容放进来。

## 目录结构

```text
.
├── README.md
├── configs/
│   └── x86-64-pve2wan.config
├── scripts/
│   ├── init-settings.sh
│   ├── preset-adguard-core.sh
│   ├── preset-clash-core.sh
│   └── preset-terminal-tools.sh
├── .github/
│   └── workflows/
│       └── build-x86-64-openwrt.yml
├── images/
│   └── bg1.jpg
└── pve2wan.sh
```

## 编译方式

主入口：
- [`.github/workflows/build-x86-64-openwrt.yml`](/Users/ruanzhenwu/.hermes/workspace/projects/immwrt25.12-2wan/.github/workflows/build-x86-64-openwrt.yml)

典型流程：
1. push 到 GitHub
2. 进入仓库 `Actions`
3. 选择 `build x86/64 openwrt`
4. 选择 `source`
5. 选择 `repo_branch`
6. 等待编译完成并下载 artifacts / release 产物

## 常用输入

### `main`
- `source = immwrt`
- `repo_branch = v25.12.0`

### `opdocker2wan`
- `source = immwrt`
- `repo_branch = v25.12.0`

### `pve2wan`
- `source = pve2wan`
- `repo_branch = v25.12.0`

## Release 约定

每次编译都会生成独立 release，不覆盖旧版本。
release 名和 tag 会带上分支名、版本线和时间戳，方便回滚和对比。

## 当前关键改动

| 类别 | 文件 | 作用 |
|---|---|---|
| ccache 修复 | [`.github/workflows/build-x86-64-openwrt.yml`](/Users/ruanzhenwu/.hermes/workspace/projects/immwrt25.12-2wan/.github/workflows/build-x86-64-openwrt.yml) | 修正 cache path/key，让 GitHub Actions 的 ccache 真正能复用 |
| release 统一 | [`.github/workflows/build-x86-64-openwrt.yml`](/Users/ruanzhenwu/.hermes/workspace/projects/immwrt25.12-2wan/.github/workflows/build-x86-64-openwrt.yml) | 每次生成独立 release，并自动带“本次更新” |
| netdata 兜底 | [`scripts/init-settings.sh`](/Users/ruanzhenwu/.hermes/workspace/projects/immwrt25.12-2wan/scripts/init-settings.sh) | 给 25.12 的 netdata 补 fallback 配置，减少首启后不可用概率 |
| pve2wan 收口 | [`pve2wan.sh`](/Users/ruanzhenwu/.hermes/workspace/projects/immwrt25.12-2wan/pve2wan.sh) | `pve2wan` 只保留自己的编译入口，不再跳去旧的通用入口 |

## 常见编译风险

| 现象 | 白话解释 | 处理方向 |
|---|---|---|
| 包不存在 / feed 404 | 上游包改名、删库或失效了 | 删掉失效包，换活着的源 |
| PassWall 依赖冲突 | 同类代理组件在 25.12 上版本不一致 | 精简包选择，避免重复 / 冲突组合 |
| `fuse-overlayfs` 相关失败 | 只选了上层包，底层依赖没一起带上 | 同时补 `kmod-fuse` + `libfuse3-3` |
| ccache 看起来没生效 | 首次 run 本来就可能 miss | 连续看第 2 次、第 3 次 run 才有意义 |

## 使用原则

1. 先保证能稳定编出来，再谈功能继续加料
2. 编译 repo 和运维档案分离
3. 敏感信息不进 git
4. 改完本地先核对，再决定 push
