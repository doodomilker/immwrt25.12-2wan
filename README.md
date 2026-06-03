# immwrt25.12-2wan

这是一个面向 `N100 / x86-64` 的 ImmortalWrt 三线编译仓库。

仓库只负责“怎么稳定编出来”，不保存线上部署、快照和排障细节。
部署资料统一放在：

```text
star/docs/servers/openwrt-192.168.50.1/
```

---

## 1. 三条发布线

本仓库维护三条明确分工的发布线：

| 分支 | 定位 | 典型场景 |
|---|---|---|
| `main` | 主路由完整全家桶 | 功能尽量全、管理页尽量齐、长期物理机主路由 |
| `opdocker2wan` | Docker 旁路由 + `wan2` | 主路由上保留 Docker，容器走 `wan2`，同时保留 Wi‑Fi 和双 PassWall |
| `pve2wan` | PVE 双 OP 精简版 | PVE 里跑双 OpenWrt VM，做 keepalived / VRRP / fallback |

---

## 2. 分支口径

### `main`
- 主路由完整全家桶
- 保留 Docker / Dockerman
- 保留 Wi‑Fi
- 保留 `PassWall` / `PassWall2` / `OpenClash`
- 保留 `SmartDNS`
- 保留 `Samba4` / `Alist`
- 保留 `Netdata` / `Nlbwmon` / `TTYD`
- `rootfs` 保持较大，适合功能全的主路由

### `opdocker2wan`
- 主路由 + Docker 旁路由
- Docker 容器出口走 `wan2`
- 保留 Wi‑Fi
- 保留 `PassWall` / `PassWall2`
- 保留健康检查工具
- 保留 Docker / 磁盘 / 监控核心管理页
- 代理面板收口，避免过度堆叠

### `pve2wan`
- PVE 虚拟机专用
- 双 OP / 双 VIP / keepalived
- 保留 `PassWall` / `PassWall2`
- 保留 `SmartDNS`
- 保留 `keepalived`
- 保留健康检查基础工具
- 尽量精简，减少虚拟机负担

---

## 3. 编译输入

三条线默认都锁到稳定版本 `v25.12.0`。
常用输入口径如下：

| 分支 | workflow from | source | repo_branch |
|---|---|---|---|
| `main` | `branch main` | `immwrt` | `v25.12.0` |
| `opdocker2wan` | `branch opdocker2wan` | `immwrt` | `v25.12.0` |
| `pve2wan` | `branch pve2wan` | `pve2wan` | `v25.12.0` |

GitHub Actions 主入口：

- [`.github/workflows/build-x86-64-openwrt.yml`](./.github/workflows/build-x86-64-openwrt.yml)

典型流程：

1. push 到 GitHub
2. 进入仓库 `Actions`
3. 选择对应分支的 workflow
4. 选择 `source`
5. 选择 `repo_branch`
6. 等待编译完成并下载 artifacts / release 产物

---

## 4. 仓库边界

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

---

## 5. 目录结构

```text
.
├── README.md
├── configs/
├── scripts/
├── .github/
├── images/
└── 编译脚本
```

不同分支会有不同的编译脚本与配置文件：

- `main` / `opdocker2wan`
  - `immwrt.sh`
  - `configs/x86-64-immwrt.config`
- `pve2wan`
  - `pve2wan.sh`
  - `configs/x86-64-pve2wan.config`

---

## 6. Release 约定

- 每次编译都会生成独立 release
- 不覆盖旧版本
- tag 和名称会带上分支名、版本线和时间戳，方便回滚和对比
- release 会自动附上“本次更新”内容

---

## 7. 当前关键改动

| 类别 | 作用 |
|---|---|
| ccache 修复 | 修正 cache path/key，让 GitHub Actions 的 ccache 真正能复用 |
| release 统一 | 每次生成独立 release，并自动带“本次更新” |
| netdata 兜底 | 给 25.12 的 netdata 补 fallback 配置，减少首启后不可用概率 |
| 分支收口 | 各分支只保留自己负责的编译入口和 README 口径 |

---

## 8. 常见编译风险

| 现象 | 白话解释 | 处理方向 |
|---|---|---|
| 包不存在 / feed 404 | 上游包改名、删库或失效了 | 删掉失效包，换活着的源 |
| PassWall 依赖冲突 | 同类代理组件在 25.12 上版本不一致 | 精简包选择，避免重复 / 冲突组合 |
| `fuse-overlayfs` 相关失败 | 只选了上层包，底层依赖没一起带上 | 同时补 `kmod-fuse` + `libfuse3-3` |
| WiFi 驱动缺失 | 固件能刷，但 AX101 可能起不来 | 把对应驱动编进固件，不要只靠事后装包 |
| ccache 看起来没生效 | 首次 run 本来就可能 miss | 连续看第 2 次、第 3 次 run 才有意义 |

---

## 9. 使用原则

1. 先保证能稳定编出来，再谈功能继续加料
2. 编译 repo 和运维档案分离
3. 敏感信息不进 git
4. 改完本地先核对，再决定 push
5. README 只讲编译 repo 本身，不承担运维手册职责
