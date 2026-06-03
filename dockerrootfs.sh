#!/usr/bin/env bash
set -euo pipefail

color() {
  case "$1" in
    cr) echo -e "\e[1;31m${2}\e[0m" ;;
    cg) echo -e "\e[1;32m${2}\e[0m" ;;
    cy) echo -e "\e[1;33m${2}\e[0m" ;;
    cc) echo -e "\e[1;36m${2}\e[0m" ;;
    cp) echo -e "\e[1;35m${2}\e[0m" ;;
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

  time_info="==> 用时 $(($(date +%s) - begin_time)) 秒"
  if [[ "$exit_code" -eq 0 ]]; then
    printf "%s %-52s %s %s\n" "$(color cy "⏳ $task_name")" "" "[ $(color cg ✔) ]" "$(color cc "$time_info")"
  else
    printf "%s %-52s %s %s\n" "$(color cy "⏳ $task_name")" "" "[ $(color cr ✖) ]" "$(color cc "$time_info")"
  fi

  return "$exit_code"
}

find_dir() {
  find "$1" -maxdepth 4 -type d -name "$2" -print -quit 2>/dev/null || true
}

print_info() {
  printf "%s %-40s %s\n" "$1" "$2" "$3"
}

clone_all() {
  local repo_url="$1" temp_dir current_dir target_dir source_dir
  temp_dir=$(mktemp -d)
  git clone -q --depth=1 "$repo_url" "$temp_dir" 2>/dev/null || {
    rm -rf "$temp_dir"
    print_info "$(color cr 拉取)" "$repo_url" "[ $(color cr ✖) ]"
    return 1
  }
  rm -rf "$temp_dir"/{.git*,README*.md,LICENSE*}
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
      print_info "$(color cc 添加)" "$target_dir" "[ $(color cc ✔) ]"
    fi
  done < <(find "$temp_dir" -maxdepth 1 -mindepth 1 -type d ! -name '.*' -print0)
  rm -rf "$temp_dir"
}

git_clone() {
  local repo_url="$1" target_dir current_dir
  target_dir="${repo_url##*/}"
  target_dir="${target_dir%.git}"
  current_dir=$(find_dir "package/ feeds/ target/" "$target_dir")
  if [[ -n "$current_dir" && -d "$current_dir" ]]; then
    rm -rf "$current_dir"
    git clone -q --depth=1 "$repo_url" "${current_dir%/*}/$target_dir" 2>/dev/null || {
      print_info "$(color cr 拉取)" "$repo_url" "[ $(color cr ✖) ]"
      return 1
    }
    rm -rf "${current_dir%/*}/$target_dir"/{.git*,README*.md,LICENSE*}
    print_info "$(color cg 替换)" "$target_dir" "[ $(color cg ✔) ]"
  else
    rm -rf "$destination_dir/$target_dir"
    git clone -q --depth=1 "$repo_url" "$destination_dir/$target_dir" 2>/dev/null || {
      print_info "$(color cr 拉取)" "$repo_url" "[ $(color cr ✖) ]"
      return 1
    }
    rm -rf "$destination_dir/$target_dir"/{.git*,README*.md,LICENSE*}
    print_info "$(color cc 添加)" "$target_dir" "[ $(color cc ✔) ]"
  fi
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
  export OPENWRT_PATH="$PWD"
  echo "OPENWRT_PATH=$OPENWRT_PATH" >> "$GITHUB_ENV"
}

set_variable_values() {
  cd "$OPENWRT_PATH"
  export SOURCE_REPO
  SOURCE_REPO=$(basename "$REPO_URL")
  echo "SOURCE_REPO=$SOURCE_REPO" >> "$GITHUB_ENV"
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

  echo " 仅添加 PassWall + PassWall2 + argon 主题（与主路由 UI 一致的同源版本）"
  clone_all https://github.com/Openwrt-Passwall/openwrt-passwall-packages
  clone_all https://github.com/Openwrt-Passwall/openwrt-passwall
  clone_all https://github.com/Openwrt-Passwall/openwrt-passwall2

  # SSR 老坑：上游哈希漂移且协议已过时，直接删掉最稳。
  rm -rf "$destination_dir/shadowsocksr-libev" 2>/dev/null || true

  git_clone https://github.com/jerrykuku/luci-theme-argon
  git_clone https://github.com/jerrykuku/luci-app-argon-config

  find "$destination_dir" -type f -name "Makefile" -print0 | xargs -0 -r sed -i \
    -e 's?\.\./\.\./\(lang\|devel\)?$(TOPDIR)/feeds/packages/\1?' \
    -e 's?\.\./\.\./luci.mk?$(TOPDIR)/feeds/luci/luci.mk?'

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

  if [[ -n "${PART_SIZE:-}" ]]; then
    sed -i '/ROOTFS_PARTSIZE/d' "$GITHUB_WORKSPACE/$CONFIG_FILE"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=$PART_SIZE" >> "$GITHUB_WORKSPACE/$CONFIG_FILE"
  fi

  if [[ -f package/base-files/files/etc/shadow ]]; then
    sed -i 's#root:::0:99999:7:::#root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::#g' \
      package/base-files/files/etc/shadow
  fi
}

update_config_file() {
  cd "$OPENWRT_PATH"
  cp -f "$GITHUB_WORKSPACE/$CONFIG_FILE" .config
  make defconfig
}

show_build_info() {
  cd "$OPENWRT_PATH"
  echo -e "$(color cy " 当前编译信息")"
  echo "========================================"
  echo " 固件源码: $(color cc "${REPO_URL}")"
  echo " 源码分支: $(color cc "${REPO_BRANCH}")"
  echo " 目标产物: $(color cc "rootfs-generic.tar.gz (Docker import)")"
  echo "========================================"
  echo " 关键插件检查:"
  grep -E 'CONFIG_PACKAGE_(luci-app-passwall|luci-app-passwall2|luci-theme-argon|luci-i18n-passwall|luci-i18n-passwall2)=y' .config || true
}

main() {
  echo "$(color cp " ImmortalWrt 25.12 Docker rootfs：PassWall + PassWall2 + argon")"
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
