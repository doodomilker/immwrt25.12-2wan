#!/usr/bin/env bash
set -euo pipefail

# pve2wan uses the same build pipeline as immwrt.sh;
# workflow source=pve2wan expects a matching DIY script name.
exec "$(dirname "$0")/immwrt.sh"
