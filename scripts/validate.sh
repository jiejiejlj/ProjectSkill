#!/usr/bin/env bash
# king-skill 框架分层校验:
#   第一层(必跑,仅依赖 jq + shell):JSON 合法性、技能 frontmatter、kebab 命名、重名、英文文件名
#   第二层(尽力跑):有 claude CLI 时执行 claude plugin validate
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail=0
err() { echo "✗ $1" >&2; fail=1; }
ok()  { echo "✓ $1"; }

MARKETPLACE=".claude-plugin/marketplace.json"
PLUGIN="plugins/king-skill/.claude-plugin/plugin.json"
SKILLS_DIR="plugins/king-skill/skills"

# --- 前置:jq 必须存在 ---
if ! command -v jq >/dev/null 2>&1; then
  echo "✗ 缺少依赖 jq" >&2
  exit 1
fi

# --- 第一层:JSON 合法性 ---
for f in "$MARKETPLACE" "$PLUGIN"; do
  if [[ ! -f "$f" ]]; then
    err "缺少文件: $f"
  elif ! jq empty "$f" >/dev/null 2>&1; then
    err "JSON 非法: $f"
  else
    ok "JSON 合法: $f"
  fi
done

# --- 第一层:逐技能检查 ---
declare -A seen_names
kebab='^[a-z0-9]+(-[a-z0-9]+)*$'
skill_count=0
if [[ -d "$SKILLS_DIR" ]]; then
  for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
    [[ -e "$skill_md" ]] || continue   # skills/ 为空时直接跳过
    skill_count=$((skill_count + 1))
    dir="$(basename "$(dirname "$skill_md")")"

    # 目录名 kebab-case
    if [[ ! "$dir" =~ $kebab ]]; then
      err "技能目录名非 kebab-case: $dir"
    fi

    # 提取 YAML frontmatter 块(首个 --- 到次个 --- 之间)
    frontmatter="$(awk 'NR==1 && $0!="---"{exit} NR==1{next} $0=="---"{exit} {print}' "$skill_md")"

    # description 必须存在且非空
    desc="$(printf '%s\n' "$frontmatter" | grep -E '^description:' | sed -E 's/^description:[[:space:]]*//' || true)"
    if [[ -z "$desc" ]]; then
      err "技能缺少非空 description: $dir"
    fi

    # 重名检查(有 name: 用之,否则用目录名)
    name="$(printf '%s\n' "$frontmatter" | grep -E '^name:' | sed -E 's/^name:[[:space:]]*//' || true)"
    [[ -z "$name" ]] && name="$dir"
    if [[ -n "${seen_names[$name]:-}" ]]; then
      err "技能名重复: $name"
    fi
    seen_names[$name]=1
  done
fi

# --- 第一层:文件名一律英文(技能目录内所有文件/子目录名只允许 ASCII)---
if [[ -d "$SKILLS_DIR" ]]; then
  ascii_name='^[A-Za-z0-9._-]+$'
  while IFS= read -r -d '' path; do
    base="$(basename "$path")"
    if [[ ! "$base" =~ $ascii_name ]]; then
      err "文件名含非英文字符(请用英文 kebab-case): ${path#./}"
    fi
  done < <(find "$SKILLS_DIR" -mindepth 1 -print0)
fi
ok "技能数量: $skill_count"

# --- 第二层:尽力跑权威校验 ---
if command -v claude >/dev/null 2>&1; then
  echo "运行 claude plugin validate ..."
  if claude plugin validate . ; then
    ok "claude plugin validate 通过"
  else
    err "claude plugin validate 失败"
  fi
else
  echo "（跳过 claude plugin validate:未检测到 claude CLI）"
fi

# --- 汇总 ---
if [[ "$fail" -ne 0 ]]; then
  echo "校验失败" >&2
  exit 1
fi
echo "全部校验通过"
