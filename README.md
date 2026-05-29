# immwrt25.12-2wan

ImmortalWrt 25.12 + Docker 旁路由 PassWall（wan2 出口）双 WAN 自定义编译。

**基线**：haiibo `openwrt-github-upload-immwrt-25.12.0-haiibo-base-plus` Plus 版
**目标设备**：N100 主路由（x86-64）
**架构**：主路由跑 Docker，macvlan 容器 `192.168.50.2` 内独立 PassWall，dnsmasq tag 自动给 ACL 设备下发 `gateway/DNS = 50.2`，主路由 `ip rule from 50.2 lookup wan2_table` 让容器流量出 wan2

## 目录结构

```
.
├── README.md                                ← 本文件
├── README_上传说明.md                       ← haiibo 原版上传/触发说明（保留）
├── CHECKLIST_改动说明.md                    ← haiibo 原版改动清单（保留）
├── immwrt.sh                                ← 编译脚本（已改）
├── configs/x86-64-immwrt.config             ← 编译 config（已改）
├── .github/workflows/build-x86-64-openwrt.yml  ← Actions workflow（已改）
├── scripts/                                 ← 首启脚本（未改）
└── images/bg1.jpg                           ← LuCI 主题背景（未改）
```

## 本地相对 haiibo 原版的改动

参见 git log，按 commit 拆分：

| Commit | 文件 | 变更 |
|---|---|---|
| feat: workflow default branch → openwrt-25.12 | `.github/workflows/build-x86-64-openwrt.yml` | `repo_branch` 默认值由 `v25.12.0` 改为 `openwrt-25.12` 维护分支 |
| feat: immwrt.sh adguardhome 改源 | `immwrt.sh` | adguardhome 由 lean 23.05 切到 sbwml 25.12 兼容版 |
| feat: immwrt.sh 注释 golang 工具链 | `immwrt.sh` | `sbwml/packages_lang_golang` 首编先注释，验证后再开 |
| feat: immwrt.sh 补 luci-theme-design clone | `immwrt.sh` | immortalwrt feed 25.12 不带，从 0x676e67 单独拉 |
| feat: immwrt.sh 默认分支同步 | `immwrt.sh` | 内嵌默认值 `v25.12.0` → `openwrt-25.12` |
| feat: config 删 filetransfer | `configs/x86-64-immwrt.config` | feed 已 remove，编不进 |
| feat: config 删 passwall2 haproxy | `configs/x86-64-immwrt.config` | 上游 2026-05-18 已 Revert |
| feat: config 加 ShadowsocksR Libev Client | `configs/x86-64-immwrt.config` | PassWall1 SSR 客户端补全 |
| feat: config 加 docker 旁路由内核包 | `configs/x86-64-immwrt.config` | macvlan/ipvlan/tun + tproxy + ipset 全套 |

## 部署方案文档

详见：`star/docs/servers/openwrt-192.168.50.1/openwrt-docker-bypass-passwall-wan2-ipv4-plan-2026-05-30.md`

包括：
- 架构总览
- 主路由 dnsmasq tag 配置
- ip rule + table 200 配置
- Docker macvlan 网络 + PassWall 容器启动命令
- 容器内 PassWall DNS / ChinaDNS-NG 配法
- 4 个关键坑（macvlan 主机隔离、容器 DNS 解析地区、DoH 绕行、IPv6 不在范围）
- 实施步骤 + 回滚策略

## 上传 GitHub fork 流程

1. 本仓库还没绑定 GitHub remote。可选方案：
   - **覆盖 fork**：把本目录所有文件覆盖到 `doodomilker/build-openwrt` 默认分支（保留 fork 的 git 历史）
   - **新仓**：在 GitHub 网页新建空仓 → 本地 `git remote add origin ...` → push
2. 不主动 push，等用户决定推哪里再操作

## 验证状态

- 已确认：25.12 dnsmasq 2.90+ 支持 tag dhcp_option（自动按 MAC 下发 gateway/DNS）
- 已确认：`kmod-macvlan` / `kmod-tun` / `iptables-mod-tproxy` 在 immwrt 25.12 feed 中
- 已确认：`0x676e67/luci-theme-design` 仓库存活（gngpp 已重定向至此）
- 已确认：sbwml/luci-app-adguardhome 主分支跟 25.12
- 已确认：PassWall1/PassWall2 在 25.12 上 0 个 OPEN issue（PW2 haproxy 唯一缺角已删）

## 首编可能的常见 fail mode

| 现象 | 处理 |
|---|---|
| `Package istore-ui not found` | immwrt.sh 注释掉 istore 两行 |
| `xt_TPROXY` 模块 build error | 取消 `luci-app-openclash` |
| `chinadns-ng` 多版本冲突 | 让 PassWall1 主导，PW2 让步 |
| 磁盘满 | workflow 已带 LVM+btrfs 扩容，理论不会发生 |

---

更新时间：2026-05-30
