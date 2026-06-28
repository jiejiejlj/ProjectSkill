#!/usr/bin/env bash
# PreToolUse 守卫:禁止在 main 分支上直接写技能目录(plugins/king-skill/skills/**)。
# 触发新增/修改技能前,应先开 feature 分支(见 CLAUDE.md「分支策略」)。
#
# 约定:任何无法判定的情况一律放行(exit 0),只在「确实在 main 且确实写 skills/」时拦截(exit 2)。
# 由 .claude/settings.json 的 PreToolUse 钩子调用,工具输入以 JSON 从 stdin 传入。
set -uo pipefail

input="$(cat)"

# 没有 jq 就放行,避免误伤(本仓库 validate.sh 已要求 jq)
command -v jq >/dev/null 2>&1 || exit 0

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[[ -n "$file_path" ]] || exit 0

# 只关心技能目录下的写入
case "$file_path" in
  */plugins/king-skill/skills/*) ;;
  *) exit 0 ;;
esac

# 取当前分支;取不到(detached / 非 git)就放行
repo="${CLAUDE_PROJECT_DIR:-$(pwd)}"
branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"

if [[ "$branch" == "main" ]]; then
  echo "✗ 当前在 main 分支,禁止直接改技能(skills/)。" >&2
  echo "  请先开 feature 分支再动手——参见 CLAUDE.md「分支策略」。" >&2
  echo "  例:git switch -c feat/skill-<标识符>" >&2
  exit 2
fi

exit 0
