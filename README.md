# immwrt25.12-2wan

N100 主路由使用的 **ImmortalWrt 25.12 x86-64 自定义编译方案**。

> 这个仓库 **只放编译相关内容**：workflow、configs、编译脚本、首启脚本。  
> **部署方案 / PVE 规划 / 运行时快照 / 排障记录** 不进本 repo，统一放：  
> `star/docs/servers/openwrt-192.168.50.1/`

---

## 1. 项目定位

本仓库的目标不是保存整套运维资料，而是稳定产出这台 N100 主路由要刷的 ImmortalWrt 固件。

当前目标场景：
- 设备：**N100 x86-64 主路由**
- 系统：**ImmortalWrt 25.12**
- 重点能力：
  - Docker / Dockerman
  - PassWall / PassWall2
  - SmartDNS
  - AX101NGW WiFi
  - USB r8152 作为 wan2
  - 与双 WAN / Docker 旁路由架构兼容

说明：
- **这里解决“怎么编出来”**
- **不在这里记录“线上怎么部署/怎么排障”**

---

## 2. 仓库边界

### 保留在本 repo 的内容
- GitHub Actions 编译流程
- `immwrt.sh` 编译脚本
- `configs/x86-64-immwrt.config` 固件配置
- `scripts/` 首启默认设置脚本
- 与“能否成功编译/开箱默认行为”直接相关的改动

### 不放进本 repo 的内容
- N100 线上部署步骤
- Docker 容器启动/重建实录
- PassWall 节点、订阅、UUID
- VPS IP、域名、设备 MAC
- 路由器运行时快照、nft dump、dhcp dump
- PVE 双 OP HA 规划

这条边界是硬规则：**即使 GitHub repo 是 private，也不把敏感运维内容放进来。**

---

## 3. 目录结构

```text
.
├── README.md                                   # 本文件
├── README_上传说明.md                          # 早期上传/触发说明（保留作参考）
├── CHECKLIST_改动说明.md                       # 早期改动核对说明（保留作参考）
├── immwrt.sh                                   # 编译脚本
├── configs/
│   └── x86-64-immwrt.config                    # x86-64 固件配置
├── scripts/
│   ├── init-settings.sh                        # 首启默认设置
│   ├── preset-adguard-core.sh
│   ├── preset-clash-core.sh
│   └── preset-terminal-tools.sh
├── .github/
│   └── workflows/
│       └── build-x86-64-openwrt.yml            # GitHub Actions 编译入口
└── images/
    └── bg1.jpg                                 # LuCI 背景图
```

---

## 4. 当前关键改动

最近已经沉淀并 push 的关键改动：

| 类别 | 文件 | 作用 |
|---|---|---|
| ccache 修复 | `.github/workflows/build-x86-64-openwrt.yml` | 修正 cache path/key，让 GitHub Actions 的 ccache 真正能复用 |
| netdata 兜底 | `scripts/init-settings.sh` | 给 25.12 的 netdata 补 fallback 配置，减少首启后不可用概率 |
| 最小化 `.gitignore` | `.gitignore` | 只保留 macOS / OpenWrt 编译产物相关忽略规则，避免 repo 再混入运维快照 |

更早但仍重要的编译相关变更：

| 类别 | 说明 |
|---|---|
| Docker 相关 | 补全 Docker / Dockerman 及相关依赖 |
| PassWall 相关 | 调整 PassWall / PassWall2 相关包选择，避开已失效或冲突项 |
| WiFi/驱动 | 纳入 AX101NGW 相关支持 |
| fuse | 明确 `fuse-overlayfs` 相关依赖（`kmod-fuse` + `libfuse3-3`） |
| 双 WAN 兼容 | 使编译产物适配 N100 + wan2（USB r8152）场景 |

---

## 5. 编译入口

### GitHub Actions
主入口：
- `.github/workflows/build-x86-64-openwrt.yml`

典型流程：
1. push 到 GitHub
2. 进入仓库 `Actions`
3. 查看 `build x86/64 openwrt`
4. 等待编译完成并下载 artifacts / release 产物

### 关键输入
默认围绕：
- `source = immwrt`
- `target = x86-64`
- `repo_branch = openwrt-25.12`（或 workflow 当前默认值）

如果后面要锁 tag / 切回具体发布版本，以 workflow 实际参数和 `immwrt.sh` 为准。

---

## 6. 与线上运维文档的关系

本 repo 不保存部署细节，相关资料统一放在：

```text
star/docs/servers/openwrt-192.168.50.1/
```

当前最关键的两份：
- `n100-wan2-docker-bypass-proxy-deploy-plan-2026-05-31.md`
- `pve-dual-op-ha-architecture-plan-2026-05-31.md`

如果你要看的是：
- 容器 `op-proxy` 怎么起
- `unless-stopped` 为什么这样配
- DHCP tag 怎么下发 gateway/DNS
- 快照、nft、dhcp、passwall runtime dump
- PVE 双 OP HA 长期方案

请去 `star`，不要往这个编译 repo 里加。

---

## 7. 常见编译风险

| 现象 | 白话解释 | 处理方向 |
|---|---|---|
| 包不存在 / feed 404 | 上游包改名、删库或失效了 | 删掉失效包，换活着的源 |
| `fuse-overlayfs` 相关失败 | 只选了上层包，底层依赖没一起带上 | 同时补 `kmod-fuse` + `libfuse3-3` |
| PassWall 依赖冲突 | 同类代理组件在 25.12 上版本不一致 | 精简包选择，避免重复/冲突组合 |
| WiFi 驱动缺失 | 固件能刷，但 AX101 可能起不来 | 把对应驱动编进固件，不要只靠事后装包 |
| ccache 看起来没生效 | 首次 run 本来就可能 miss | 连续看第 2 次、第 3 次 run 才有意义 |

---

## 8. 使用原则

1. **先保证能稳定编出来，再谈功能继续加料**
2. **编译 repo 和运维档案分离**
3. **敏感信息不进 git**
4. **改完本地先核对，再决定 push**
5. **README 只讲编译 repo 本身，不承担运维手册职责**

---

## 9. 备注

- `README_上传说明.md` 和 `CHECKLIST_改动说明.md` 目前保留，主要作为早期背景参考。
- 后续如果内容继续稳定，可以把这两份再合并/裁剪，最终只保留一份面向当前状态的 README。

---

更新时间：2026-06-01
