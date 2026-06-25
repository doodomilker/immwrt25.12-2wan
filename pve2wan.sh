#!/usr/bin/env bash
set -euo pipefail

color() {
  case "$1" in
    cr) echo -e "\e[1;31m${2}\e[0m" ;;
    cg) echo -e "\e[1;32m${2}\e[0m" ;;
    cy) echo -e "\e[1;33m${2}\e[0m" ;;
    cb) echo -e "\e[1;34m${2}\e[0m" ;;
    cp) echo -e "\e[1;35m${2}\e[0m" ;;
    cc) echo -e "\e[1;36m${2}\e[0m" ;;
    cw) echo -e "\e[1;37m${2}\e[0m" ;;
  esac
}

status_info() {
  local task_name="$1" begin_time exit_code time_info had_errexit=0
  begin_time=$(date +%s)
  shift

  [[ $- == *e* ]] && had_errexit=1
  set +e
  "$@"
  exit_code=$?
  [[ "$had_errexit" -eq 1 ]] && set -e

  [[ "$exit_code" -eq 99 ]] && return 0

  time_info="==> 用时 $(($(date +%s) - begin_time)) 秒"
  if [[ "$exit_code" -eq 0 ]]; then
    printf "%s %-52s %s %s\n" "$(color cy "⏳ $task_name")" "" "[ $(color cg ✔) ]" "$(color cw "$time_info")"
  else
    printf "%s %-52s %s %s\n" "$(color cy "⏳ $task_name")" "" "[ $(color cr ✖) ]" "$(color cw "$time_info")"
  fi

  return "$exit_code"
}

find_dir() {
  find $1 -maxdepth 4 -type d -name "$2" -print -quit 2>/dev/null || true
}

print_info() {
  printf "%s %-40s %s\n" "$1" "$2" "$3"
}

git_clone() {
  local repo_url branch target_dir current_dir
  branch=""
  if [[ "$1" == */* ]]; then
    repo_url="$1"
    shift
  else
    branch="-b $1 --single-branch"
    repo_url="$2"
    shift 2
  fi
  target_dir="${1:-${repo_url##*/}}"
  target_dir="${target_dir%.git}"
  rm -rf "$target_dir"
  git clone -q $branch --depth=1 "$repo_url" "$target_dir" 2>/dev/null || {
    print_info "$(color cr 拉取)" "$repo_url" "[ $(color cr ✖) ]"
    return 1
  }
  rm -rf "$target_dir"/{.git*,README*.md,LICENSE} 2>/dev/null || true
  current_dir=$(find_dir "package/ feeds/ target/" "$target_dir")
  if [[ -n "$current_dir" && -d "$current_dir" ]]; then
    rm -rf "$current_dir"
    mv -f "$target_dir" "${current_dir%/*}"
    print_info "$(color cg 替换)" "$target_dir" "[ $(color cg ✔) ]"
  else
    rm -rf "$destination_dir/$target_dir"
    mv -f "$target_dir" "$destination_dir"
    print_info "$(color cb 添加)" "$target_dir" "[ $(color cb ✔) ]"
  fi
}

clone_dir() {
  local repo_url branch temp_dir target_dir source_dir current_dir
  branch=""
  temp_dir=$(mktemp -d)
  if [[ "$1" == */* ]]; then
    repo_url="$1"
    shift
  else
    branch="-b $1 --single-branch"
    repo_url="$2"
    shift 2
  fi
  git clone -q $branch --depth=1 "$repo_url" "$temp_dir" 2>/dev/null || {
    print_info "$(color cr 拉取)" "$repo_url" "[ $(color cr ✖) ]"
    rm -rf "$temp_dir"
    return 1
  }
  for target_dir in "$@"; do
    source_dir=$(find_dir "$temp_dir" "$target_dir")
    if [[ -z "$source_dir" || ! -d "$source_dir" ]]; then
      print_info "$(color cr 查找)" "$target_dir" "[ $(color cr ✖) ]"
      continue
    fi
    current_dir=$(find_dir "package/ feeds/ target/" "$target_dir")
    if [[ -n "$current_dir" && -d "$current_dir" ]]; then
      rm -rf "$current_dir"
      mv -f "$source_dir" "${current_dir%/*}"
      print_info "$(color cg 替换)" "$target_dir" "[ $(color cg ✔) ]"
    else
      rm -rf "$destination_dir/$target_dir"
      mv -f "$source_dir" "$destination_dir"
      print_info "$(color cb 添加)" "$target_dir" "[ $(color cb ✔) ]"
    fi
  done
  rm -rf "$temp_dir"
}

clone_all() {
  local repo_url branch temp_dir base_dir source_dir target_dir current_dir
  branch=""
  temp_dir=$(mktemp -d)
  if [[ "$1" == */* ]]; then
    repo_url="$1"
    shift
  else
    branch="-b $1 --single-branch"
    repo_url="$2"
    shift 2
  fi
  git clone -q $branch --depth=1 "$repo_url" "$temp_dir" 2>/dev/null || {
    print_info "$(color cr 拉取)" "$repo_url" "[ $(color cr ✖) ]"
    rm -rf "$temp_dir"
    return 1
  }
  process_dir() {
    while IFS= read -r -d '' source_dir; do
      target_dir=$(basename "$source_dir")
      current_dir=$(find_dir "package/ feeds/ target/" "$target_dir")
      if [[ -n "$current_dir" && -d "$current_dir" ]]; then
        rm -rf "$current_dir"
        mv -f "$source_dir" "${current_dir%/*}"
        print_info "$(color cg 替换)" "$target_dir" "[ $(color cg ✔) ]"
      else
        rm -rf "$destination_dir/$target_dir"
        mv -f "$source_dir" "$destination_dir"
        print_info "$(color cb 添加)" "$target_dir" "[ $(color cb ✔) ]"
      fi
    done < <(find "$1" -maxdepth 1 -mindepth 1 -type d ! -name '.*' -print0)
  }
  if [[ $# -eq 0 ]]; then
    process_dir "$temp_dir"
  else
    for base_dir in "$@"; do
      [[ -d "$temp_dir/$base_dir" ]] && process_dir "$temp_dir/$base_dir" || print_info "$(color cr 目录)" "$base_dir" "[ $(color cr ✖) ]"
    done
  fi
  rm -rf "$temp_dir"
}

clone_source_code() {
  REPO_URL="${REPO_URL:-https://github.com/immortalwrt/immortalwrt}"
  REPO_BRANCH="${REPO_BRANCH:-v25.12.0}"
  export REPO_URL REPO_BRANCH
  echo "REPO_URL=$REPO_URL" >> "$GITHUB_ENV"
  echo "REPO_BRANCH=$REPO_BRANCH" >> "$GITHUB_ENV"
  cd /workdir
  rm -rf openwrt
  git clone -q -b "$REPO_BRANCH" --single-branch "$REPO_URL" openwrt
  ln -sf /workdir/openwrt "$GITHUB_WORKSPACE/openwrt"
  cd openwrt
  echo "src-git linkease https://github.com/linkease/istore.git;main" >> feeds.conf.default
  export OPENWRT_PATH="$PWD"
  echo "OPENWRT_PATH=$OPENWRT_PATH" >> "$GITHUB_ENV"
}

set_variable_values() {
  cd "$OPENWRT_PATH"
  export SOURCE_REPO=$(basename "$REPO_URL")
  echo "SOURCE_REPO=$SOURCE_REPO" >> "$GITHUB_ENV"
  echo "LITE_BRANCH=${REPO_BRANCH#*-}" >> "$GITHUB_ENV"
  TARGET_NAME=$(grep -oP '^CONFIG_TARGET_\K[a-z0-9]+(?==y)' "$GITHUB_WORKSPACE/$CONFIG_FILE" | head -1)
  SUBTARGET_NAME=$(grep -oP "^CONFIG_TARGET_${TARGET_NAME}_\K[a-z0-9]+(?==y)" "$GITHUB_WORKSPACE/$CONFIG_FILE" | head -1)
  export DEVICE_TARGET="$TARGET_NAME-$SUBTARGET_NAME"
  echo "DEVICE_TARGET=$DEVICE_TARGET" >> "$GITHUB_ENV"
  KERNEL=$(grep -oP 'KERNEL_PATCHVER:=\K[\d\.]+' "target/linux/$TARGET_NAME/Makefile" | head -1 || true)
  if [[ -n "${KERNEL:-}" ]]; then
    KERNEL_FILE="include/kernel-$KERNEL"
    [[ -e "$KERNEL_FILE" ]] || KERNEL_FILE="target/linux/generic/kernel-$KERNEL"
    KERNEL_VERSION=$(grep -oP 'LINUX_KERNEL_HASH-\K[\d\.]+' "$KERNEL_FILE" | head -1 || true)
    export KERNEL_VERSION="${KERNEL_VERSION:-unknown}"
    echo "KERNEL_VERSION=$KERNEL_VERSION" >> "$GITHUB_ENV"
  fi
}

update_install_feeds() {
  cd "$OPENWRT_PATH"
  ./scripts/feeds update -a
  ./scripts/feeds install -a
}

add_custom_packages() {
  cd "$OPENWRT_PATH"
  destination_dir="package/A"
  mkdir -p "$destination_dir"

  echo " 添加额外插件：pve2wan 精简路线..."
  clone_dir https://github.com/sirpdboy/luci-app-ddns-go ddns-go luci-app-ddns-go
  clone_all https://github.com/Openwrt-Passwall/openwrt-passwall-packages
  clone_all https://github.com/Openwrt-Passwall/openwrt-passwall
  clone_all https://github.com/Openwrt-Passwall/openwrt-passwall2

  # pve2wan 不再保留无关历史包，避免把与当前配置无关的组件拉入构建链。
  rm -rf "$destination_dir/shadowsocksr-libev" 2>/dev/null || true

  # Themes actually enabled by x86-64-pve2wan.config
  git_clone https://github.com/jerrykuku/luci-theme-argon
  clone_all https://github.com/0x676e67/luci-theme-design

  # 修复 Makefile 路径
  find "$destination_dir" -type f -name "Makefile" -print0 | xargs -0 -r sed -i \
    -e 's?\.\./\.\./\(lang\|devel\)?$(TOPDIR)/feeds/packages/\1?' \
    -e 's?\.\./\.\./luci.mk?$(TOPDIR)/feeds/luci/luci.mk?'

  # 转换插件语言翻译 zh-cn / zh_Hans
  while IFS= read -r -d '' po_dir; do
    if [[ -d "$po_dir/zh-cn" && ! -e "$po_dir/zh_Hans" ]]; then
      ln -s zh-cn "$po_dir/zh_Hans" 2>/dev/null || true
    elif [[ -d "$po_dir/zh_Hans" && ! -e "$po_dir/zh-cn" ]]; then
      ln -s zh_Hans "$po_dir/zh-cn" 2>/dev/null || true
    fi
  done < <(find "$destination_dir" feeds/luci/applications -type d -name po -print0 2>/dev/null || true)
}

apply_custom_settings() {
  cd "$OPENWRT_PATH"
  [[ -e "$GITHUB_WORKSPACE/files" ]] && mv "$GITHUB_WORKSPACE/files" files

  # 设置固件 rootfs 大小。
  if [[ -n "${PART_SIZE:-}" ]]; then
    sed -i '/ROOTFS_PARTSIZE/d' "$GITHUB_WORKSPACE/$CONFIG_FILE"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=$PART_SIZE" >> "$GITHUB_WORKSPACE/$CONFIG_FILE"
  fi

  # 修改默认 IP 地址
  if [[ -n "${IP_ADDRESS:-}" ]]; then
    sed -i '/lan) ipad/s/".*"/"'"$IP_ADDRESS"'"/' package/base-files/files/bin/config_generate
  fi

  # ttyd 免登录
  if [[ -f feeds/packages/utils/ttyd/files/ttyd.config ]]; then
    sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config
  fi

  # 设置 root 密码为 password
  if [[ -f package/base-files/files/etc/shadow ]]; then
    sed -i 's#root:::0:99999:7:::#root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::#g' package/base-files/files/etc/shadow
  fi

  # 更改 argon 主题背景，文件存在才执行
  if [[ -f "$GITHUB_WORKSPACE/images/bg1.jpg" && -d feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img ]]; then
    cp -f "$GITHUB_WORKSPACE/images/bg1.jpg" feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
  fi
}

update_config_file() {
  cd "$OPENWRT_PATH"
  cp -f "$GITHUB_WORKSPACE/$CONFIG_FILE" .config
  make defconfig
}

show_build_info() {
  echo -e "$(color cy " 当前编译信息")"
  echo "========================================"
  echo " 固件源码: $(color cc "${SOURCE_REPO:-immortalwrt}")"
  echo " 源码分支: $(color cc "${REPO_BRANCH:-v25.12.0}")"
  echo " 目标设备: $(color cc "${DEVICE_TARGET:-x86-64}")"
  echo " 内核版本: $(color cc "${KERNEL_VERSION:-unknown}")"
  echo "========================================"
  echo " 关键插件检查:"
  grep -E 'CONFIG_PACKAGE_(luci-app-(keepalived|passwall|passwall2|smartdns|ddns-go)|keepalived|keepalived-sync|jq|bash|bind-dig|coreutils-timeout)=y|CONFIG_PACKAGE_luci-i18n-(passwall|passwall2|smartdns|ddns-go)-zh-cn=y' .config || true
}

main() {
  echo "$(color cp " 开始运行自定义脚本：pve2wan 精简路线 + PassWall/PassWall2/SmartDNS/keepalived/中文包")"
  echo "========================================"
  status_info "拉取编译源码" clone_source_code
  status_info "设置环境变量" set_variable_values
  status_info "更新&安装插件" update_install_feeds
  status_info "添加额外插件" add_custom_packages
  status_info "加载个人设置" apply_custom_settings
  status_info "更新配置文件" update_config_file
  show_build_info
  echo "$(color cp "✅ 自定义脚本运行完成")"
  echo "========================================"
}

main "$@"
