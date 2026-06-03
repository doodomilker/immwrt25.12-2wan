# opdocker2wan

这是 `immwrt25.12-2wan` 的 **Docker 旁路由 + `wan2`** 分支。

这条线的目标很明确：

- 主路由能力保留
- Wi‑Fi 保留
- Docker 保留
- Docker 容器主要走 `wan2`
- PassWall / PassWall2 保留
- 常用管理页和健康检查工具保留

---

## 1. 这条线做什么

`opdocker2wan` 适合下面这种场景：

- OpenWrt 既是主路由，也是 Docker 宿主
- Docker 容器要有自己的出口逻辑
- `wan2` 专门给容器侧或旁路由侧使用
- 路由器本机也要能继续正常管理和代理

这条线不是 PVE 双 OP，也不是纯主路由全家桶，而是介于两者之间的 Docker 专线版本。

---

## 2. 编译输入

本分支默认使用：

- `source = immwrt`
- `repo_branch = v25.12.0`
- workflow 选 `branch opdocker2wan`

GitHub Actions 里只要按这三个选就行：

1. workflow from: `branch opdocker2wan`
2. source: `immwrt`
3. repo_branch: `v25.12.0`

---

## 3. 核心保留项

这条线重点保留：

- Docker / Dockerd / Containerd / Runc
- `luci-app-dockerman`
- `luci-lib-docker`
- `kmod-macvlan`
- `kmod-ipvlan`
- `kmod-tun`
- `iptables-nft`
- `iptables-mod-tproxy`
- `kmod-ipt-tproxy`
- `ipset`
- `ip-full`
- `fuse-overlayfs`
- `kmod-fuse`
- `libfuse3-3`
- `PassWall`
- `PassWall2`
- `SmartDNS`
- Wi‑Fi 全套
- `jq`
- `bash`
- `bind-dig`
- `coreutils-timeout`
- `tcping`
- `curl`
- `ca-bundle`
- `Dockerman / Diskman / Netdata / Nlbwmon / TTYD`

这条线的重点不是“最多”，而是“够用、稳定、好排障”。

---

## 4. 当前配置方向

这条线现在的口径是：

- 主路由全功能保留
- Docker 是重点
- `wan2` 是 Docker 容器出口的关键
- 代理面板收口到 `PassWall + PassWall2`
- 主题保留
- `rootfs` 保持 `4096`

如果你后续要看编译风险，优先盯这几类：

- Docker 网络相关包是否齐
- `fuse-overlayfs` 相关依赖是否齐
- 健康检查脚本工具是否齐
- `PassWall / PassWall2` 是否和其他代理面板冲突

---

## 5. 目录结构

```text
.
├── README.md
├── immwrt.sh
├── configs/
│   └── x86-64-immwrt.config
├── scripts/
│   ├── init-settings.sh
│   ├── preset-adguard-core.sh
│   ├── preset-clash-core.sh
│   └── preset-terminal-tools.sh
├── .github/
│   └── workflows/
│       └── build-x86-64-openwrt.yml
└── images/
    └── bg1.jpg
```

---

## 6. release 约定

- 每次编译生成独立 release
- 不覆盖旧版本
- tag 和名称带时间戳，方便回滚和对比
- release 自动带“本次更新”内容

---

## 7. 常见编译风险

| 现象 | 白话解释 | 处理方向 |
|---|---|---|
| Docker 依赖冲突 | 容器相关包没配全或版本不一致 | 同时补齐 Docker 核心和网络依赖 |
| `fuse-overlayfs` 失败 | 底层依赖没一起带上 | 同时补 `kmod-fuse` + `libfuse3-3` |
| 代理面板冲突 | 重叠代理路线太多 | 收口到 `PassWall + PassWall2` |
| 健康检查脚本不稳 | 探活工具缺失 | 补齐 `jq / bash / dig / timeout / tcping` |
| ccache 看起来没生效 | 首次 run 本来就可能 miss | 连续看第 2 次、第 3 次 run 才有意义 |

---

## 8. 使用原则

1. 主路由和 Docker 这两件事都要稳
2. 不把 PVE 双 OP 的思路混进来
3. 敏感信息不进 git
4. 改完本地先核对，再决定 push
