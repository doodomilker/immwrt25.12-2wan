# immwrt25.12-2wan

`pve2wan` 分支现在只保留 **PVE 双 OP 精简编译线**，不再混入 `immwrt` 兼容入口。

> 这个仓库只放编译相关内容：workflow、configs、编译脚本、首启脚本。<br>
> 部署方案 / PVE 规划 / 运行时快照 / 排障记录统一放到 `star/docs/servers/openwrt-192.168.50.1/`。

## 项目定位

当前这个分支只负责产出 PVE 双 OP 需要的固件，不再承载通用 `immwrt` 路线。

当前目标场景：
- 设备：`N100 x86-64`
- 系统：`ImmortalWrt 25.12`
- 重点能力：
  - PassWall / PassWall2
  - SmartDNS
  - keepalived
  - Docker 旁路由相关基础能力

## 仓库边界

保留在本 repo 的内容：
- GitHub Actions 编译流程
- `pve2wan.sh` 编译脚本
- `configs/x86-64-pve2wan.config` 固件配置
- `scripts/` 首启默认设置脚本
- 与“能否成功编译/开箱默认行为”直接相关的改动

不放进本 repo 的内容：
- N100 线上部署步骤
- Docker 容器启动/重建实录
- PassWall 节点、订阅、UUID
- VPS IP、域名、设备 MAC
- 路由器运行时快照、nft dump、dhcp dump
- PVE 双 OP HA 规划

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

## 当前关键改动

最近已经沉淀并 push 的关键改动：

| 类别 | 文件 | 作用 |
|---|---|---|
| ccache 修复 | `.github/workflows/build-x86-64-openwrt.yml` | 修正 cache path/key，让 GitHub Actions 的 ccache 真正能复用 |
| netdata 兜底 | `scripts/init-settings.sh` | 给 25.12 的 netdata 补 fallback 配置，减少首启后不可用概率 |
| 最小化 `.gitignore` | `.gitignore` | 只保留 macOS / OpenWrt 编译产物相关忽略规则，避免 repo 再混入运维快照 |

## 编译入口

主入口：
- `.github/workflows/build-x86-64-openwrt.yml`

典型流程：
1. push 到 GitHub
2. 进入仓库 `Actions`
3. 查看 `build x86/64 openwrt`
4. 选择 `source = pve2wan`
5. 选择 `repo_branch = v25.12.0`
6. 等待编译完成并下载 artifacts / release 产物

## 关键输入

- `source = pve2wan`
- `target = x86-64`
- `repo_branch = v25.12.0`

## 常见编译风险

| 现象 | 白话解释 | 处理方向 |
|---|---|---|
| 包不存在 / feed 404 | 上游包改名、删库或失效了 | 删掉失效包，换活着的源 |
| PassWall 依赖冲突 | 同类代理组件在 25.12 上版本不一致 | 精简包选择，避免重复/冲突组合 |
| ccache 看起来没生效 | 首次 run 本来就可能 miss | 连续看第 2 次、第 3 次 run 才有意义 |

## 使用原则

1. 先保证能稳定编出来，再谈功能继续加料
2. 编译 repo 和运维档案分离
3. 敏感信息不进 git
4. 改完本地先核对，再决定 push
