# immwrt25.12-2wan

面向 `N100 / x86-64` 平台的 ImmortalWrt 固件编译仓库。

每条分支是一条独立的编译线，对应不同的使用场景。

---

## 四条编译线

| 分支 | 定位 | 编译入口 | 配置 |
|---|---|---|---|
| `main` | 主路由全家桶 | `immwrt.sh` | `configs/x86-64-immwrt.config` |
| `pve2wan` | PVE 双 OP 精简版 | `pve2wan.sh` | `configs/x86-64-pve2wan.config` |
| `opdocker2wan` | Docker 旁路由 + wan2 | `immwrt.sh` | `configs/x86-64-immwrt.config` |
| `dockerrootfs` | Docker rootfs 最小基线 | `dockerrootfs.sh` | `configs/x86-64-dockerrootfs.config` |

### main
主路由完整全家桶：Wi‑Fi、Docker、PassWall/PassWall2/OpenClash、Samba/Alist、监控面板。适合物理机做主路由。

### pve2wan
PVE 双 OP 精简版：keepalived / VRRP 双 VIP、PassWall/PassWall2、SmartDNS。去掉 Docker、Wi‑Fi、文件共享。适合 PVE 里跑双 OpenWrt VM 做高可用。

### opdocker2wan
主路由 + Docker 旁路由：Docker 容器走 `wan2`，保留 Wi‑Fi 和 PassWall/PassWall2。适合一台设备同时做主路由和旁路由。

### dockerrootfs
最小化旁路由容器 rootfs，给 `docker import` 用。不是宿主机固件，不包含 LuCI。

---

## 编译

所有分支默认锁定 `v25.12.0`。

GitHub Actions 入口：`.github/workflows/build-x86-64-openwrt.yml`

1. push 到 GitHub
2. 进仓库 Actions，选对应分支的 workflow
3. 选 `source` 和 `repo_branch`
4. 等编译完成，下载 release

---

## 仓库结构

```
.
├── .github/workflows/    # Actions 编译流程
├── configs/              # 各分支 .config
├── scripts/              # 首启预设脚本
├── images/               # 背景图
├── immwrt.sh             # main / opdocker2wan 编译入口
├── pve2wan.sh            # pve2wan 编译入口
└── dockerrootfs.sh       # dockerrootfs 编译入口
```

---

## 边界

- 仓库只管编译和默认行为，不放线上部署、节点、IP、快照
- 运维资料在外部（`star/docs/servers/`），不进这个 repo
- 每条分支的详细说明看各自分支的 README
