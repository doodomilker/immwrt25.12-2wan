# dockerrootfs

这是 `immwrt25.12-2wan` 的 Docker 容器 rootfs 分支。

它不是宿主机固件，也不是 PVE 虚拟机镜像，而是给 `docker import` 用的最小化旁路由容器基线。

## 1. 这条线做什么

`dockerrootfs` 适合下面这种场景：

- 主路由本机已经是 OpenWrt / ImmortalWrt
- 旁路由能力放进 Docker 容器里
- 容器拿独立 LAN IP
- 容器流量按宿主机策略走 `wan2`
- 容器只保留 PassWall / PassWall2 / LuCI / argon / 中文包

这条线不负责：

- Docker 宿主机能力
- Wi-Fi
- Netdata / Dockerman / Diskman
- PVE 双 OP HA

## 2. 编译输入

本分支默认使用：

- `source = dockerrootfs`
- `repo_branch = v25.12.0`
- workflow 选 `branch dockerrootfs`

GitHub Actions 里只要按这三个选就行：

1. workflow from: `branch dockerrootfs`
2. source: `dockerrootfs`
3. repo_branch: `v25.12.0`

## 3. 核心保留项

这条线重点保留：

- LuCI 完整基础页
- `luci-theme-argon`
- `PassWall`
- `PassWall2`
- `firewall4`
- `nftables`
- `iptables-nft`
- `tproxy`
- `ipset`
- `ip-full`
- `dnsmasq-full`
- `dropbear`
- 中文包

这条线重点删除：

- Docker / Dockerd / Containerd / Runc
- Wi-Fi / `wpad` / `iw`
- SmartDNS
- OpenClash / HomeProxy / Nikki
- Netdata / TTYD / Diskman / Nlbwmon
- 文件共享 / NAS 类工具
- 宿主机内核模块大包

## 4. 已保留的修复项

这条线已经把之前踩过的坑一并保留下来了：

- 删除 `shadowsocksr-libev`，避开 SSR 哈希漂移老坑
- 保留外部包 `Makefile` 路径修复
- 保留 `zh-cn / zh_Hans` 翻译目录软链修复
- 明确关闭 `PassWall2 Haproxy`，避开上游回退后的编译问题
- 默认锁定 `v25.12.0`
- 使用统一的 ccache 配置
- 使用统一的新 release/tag 逻辑

## 5. 产物说明

主要产物是：

- `immortalwrt-x86-64-generic-rootfs.tar.gz`
- `immortalwrt-x86-64-generic-rootfs-ready-v4.tar.gz`

其中：

- `rootfs.tar.gz` 是原始编译产物
- `rootfs-ready-v4.tar.gz` 是当前这条线对外使用的正式命名

## 6. 目录结构

```text
.
├── README.md
├── configs/
│   └── x86-64-dockerrootfs.config
├── scripts/
│   └── init-settings.sh
├── .github/
│   └── workflows/
│       └── build-x86-64-openwrt.yml
├── images/
│   └── bg1.jpg
└── dockerrootfs.sh
```

## 7. 使用原则

1. 这条线只做容器 rootfs
2. 不把宿主机功能混进来
3. 不把 PVE 双 OP 思路混进来
4. 改完本地先核对，再决定 push
