#!/bin/bash
set -euo pipefail
trap 'echo "❌ start.sh 失败 (行号: $LINENO)" >&2' ERR

log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# 进入脚本目录（防止面板工作目录不确定）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# 可选：加载环境变量（如你有 .env）
if [[ -f ".env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source ".env"
  set +a
fi

BRANCH="${DEPLOY_BRANCH:-main}"
REMOTE="${DEPLOY_REMOTE:-origin}"

# 禁止 git 弹交互提示（否则会卡启动）
export GIT_TERMINAL_PROMPT=0

log "📌 PWD=$(pwd)"
log "📌 目标分支: ${REMOTE}/${BRANCH}"

# 记录旧版本（用于兜底信息）
OLD_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")"
log "🔎 当前版本: ${OLD_SHA}"

update_ok=0
if command -v git >/dev/null 2>&1; then
  # 尽量用“确定性更新”，不要用 pull（pull = fetch + merge/rebase，容易出幺蛾子）
  if git fetch --prune "${REMOTE}" "${BRANCH}" >/dev/null 2>&1; then
    # 确保在正确分支
    if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
      git checkout -q "${BRANCH}" || true
    else
      # 首次没有本地分支
      git checkout -q -B "${BRANCH}" "${REMOTE}/${BRANCH}"
    fi

    # 强制对齐远端（避免 merge 产生、避免冲突卡住）
    if git reset --hard "${REMOTE}/${BRANCH}" >/dev/null 2>&1; then
      update_ok=1
    fi
  fi
fi

if [[ "${update_ok}" -eq 1 ]]; then
  NEW_SHA="$(git rev-parse --short HEAD)"
  log "✅ 更新完成: ${OLD_SHA} -> ${NEW_SHA}"
else
  log "⚠️ 更新失败，将尝试使用当前工作区版本启动（避免服务起不来）"
fi

# 可选：依赖安装（谨慎！0.5G/1G 很容易把你搞爆）
# 如果你已经把 dist 产物提交到仓库，且运行不依赖 node_modules，建议不要 install
if [[ "${RUN_BUN_INSTALL:-0}" -eq 1 ]]; then
  if [[ -f "bun.lock" ]]; then
    log "📦 bun install（建议仅在必要时开启 RUN_BUN_INSTALL=1）"
    bun install --frozen-lockfile
  fi
fi

# 确保产物存在
if [[ ! -f "dist/index.js" ]]; then
  log "❌ dist/index.js 不存在。你要么把 dist 提交到仓库，要么在启动时执行 build（不推荐在小机上 build）"
  exit 1
fi

log "🚀 启动应用: bun dist/index.js"
# 用 exec 交出 PID，面板更好管理（信号/退出码）
exec bun dist/index.js