# pve2wan

这是 `immwrt25.12-2wan` 的 **PVE 双 OP 精简版** 分支。

它的目标不是把功能堆满，而是让 PVE 里的两台 OpenWrt VM 更容易稳定运行，重点围绕：

- keepalived / VRRP / 双 VIP
- PassWall / PassWall2
- SmartDNS
- 健康检查基础工具
- 尽量轻量，减少虚拟机负担

---

## 1. 这个分支做什么

`pve2wan` 专门服务于 PVE 双 OP 场景：

- 一台 VM 挂了，VIP 继续漂
- 代理和普通出口可以按既定规则切换
- 主要保留路由与 HA 必需组件
- 不把 Docker、文件共享、监控大包再塞回去

这条线适合：

- PVE 里跑两台 OpenWrt VM
- 做主备、fallback、VIP 漂移
- 追求稳定和清晰，而不是功能最多

---

## 2. 编译输入

本分支默认使用：

- `source = pve2wan`
- `repo_branch = v25.12.0`
- workflow 选 `branch pve2wan`

如果你在 GitHub Actions 里要跑这条线，记住只选这一套：

1. workflow from: `branch pve2wan`
2. source: `pve2wan`
3. repo_branch: `v25.12.0`

---

## 3. 核心保留项

这条线保留的重点是：

- `keepalived`
- `keepalived-sync`
- `luci-app-keepalived`
- `PassWall`
- `PassWall2`
- `SmartDNS`
- `jq`
- `bash`
- `bind-dig`
- `coreutils-timeout`
- `curl`
- `ca-bundle`
- `ip-full`
- `tcping`

这些东西的目标很明确：

- 能做 VIP 漂移
- 能检查 WAN / DNS / 代理连通性
- 能尽量减少“进程还在但业务已经挂了”的假健康

---

## 4. 目录结构

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

其中：

- `pve2wan.sh` 是这条线自己的编译入口
- `configs/x86-64-pve2wan.config` 是这条线自己的配置

---

## 5. release 约定

这条线的 release 约定和其他分支一致：

- 每次编译生成独立 release
- 不覆盖旧版本
- tag 和名称都带时间戳，方便回滚和对比

---

## 6. 与其他分支的关系

`pve2wan` 只负责 PVE 双 OP 这条线，不承担其他分支的说明职责。

如果你要看：

- `main` 的主路由全家桶总览
- `opdocker2wan` 的 Docker 旁路由 + `wan2`

请切到对应分支看各自 README。

---

## 7. 常见编译风险

| 现象 | 白话解释 | 处理方向 |
|---|---|---|
| 包不存在 / feed 404 | 上游包改名、删库或失效了 | 删掉失效包，换活着的源 |
| keepalived 相关包冲突 | 25.12 上某些依赖版本不一致 | 只保留真正需要的 HA 组件 |
| 健康检查脚本不稳定 | timeout / dig / curl 没配齐 | 把基础探活工具补齐 |
| ccache 看起来没生效 | 首次 run 本来就可能 miss | 连续看第 2 次、第 3 次 run 才有意义 |

---

## 8. 使用原则

1. 先保证能稳定编出来，再谈功能继续加料
2. 这条线只保留 PVE 双 OP 必需内容
3. 敏感信息不进 git
4. 改完本地先核对，再决定 push
