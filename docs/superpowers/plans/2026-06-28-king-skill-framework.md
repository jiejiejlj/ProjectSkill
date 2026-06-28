# king-skill 技能集合框架 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `ProjectSkill` 仓库中搭好一个以 marketplace 方式分发的单一 Claude Code plugin(`king-skill`)框架,含模板、分层校验脚本、CI 与三份文档,但不放任何真实技能。

**Architecture:** 仓库根 `.claude-plugin/marketplace.json` 作市场(名 `king`),`plugins/king-skill/` 作单一 plugin;技能以后放进 `plugins/king-skill/skills/<kebab>/SKILL.md`。校验脚本分两层:无依赖的结构检查必跑,`claude plugin validate` 在有 CLI 时尽力跑;CI 在 GitHub Actions 跑同一脚本。

**Tech Stack:** Claude Code plugin/marketplace 规范、JSON、bash、`jq`、GitHub Actions、Markdown(简体中文文档)。

## Global Constraints

- 技能标识符(目录名 = slash 名):英文 kebab-case,正则 `^[a-z0-9]+(-[a-z0-9]+)*$`。
- 技能 `description` 与正文:全简体中文;description 句式「当<场景>时使用——<做什么>」,场景在前。
- plugin 名固定 `king-skill`;marketplace 名固定 `king`;`metadata.pluginRoot = "./plugins"`,source 写 `./king-skill`(必须以 `./` 开头,经 `claude plugin validate` 实测;裸名会报 `Invalid input`)。
- 版本 semver,起始 `0.1.0`;加/改技能时 patch +1。
- author 只放 `name: "king"` + 仓库链接,不放邮箱;LICENSE 沿用 MIT。
- 模板 `allowed-tools` 预填只读工具 `Read, Grep, Glob`。
- 不做专属脚手架技能、不加 git 钩子、不写 CHANGELOG(YAGNI)。
- 校验脚本第一层只依赖 `jq` 与 shell;第二层 `claude plugin validate` 仅在 `claude` CLI 存在时运行。
- 提交信息结尾附:`Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- 工作分支:`king-skill-framework`(spec 已在此分支)。

---

### Task 1: 脚手架结构与两个清单文件

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `plugins/king-skill/.claude-plugin/plugin.json`
- Create: `plugins/king-skill/skills/.gitkeep`
- Create: `.gitignore`

**Interfaces:**
- Produces: 市场名 `king`、plugin 名 `king-skill`、`pluginRoot=./plugins`、source=`./king-skill`;skills 目录路径 `plugins/king-skill/skills/`。后续 Task 2 的校验脚本依赖这两个 JSON 路径与 skills 目录路径。

- [ ] **Step 1: 创建目录与 plugin.json**

写 `plugins/king-skill/.claude-plugin/plugin.json`:

```json
{
  "name": "king-skill",
  "description": "king 的自用技能集合",
  "version": "0.1.0",
  "author": { "name": "king" },
  "homepage": "https://github.com/jiejiejlj/ProjectSkill",
  "repository": "https://github.com/jiejiejlj/ProjectSkill",
  "license": "MIT",
  "keywords": ["skills", "personal", "toolkit"]
}
```

- [ ] **Step 2: 创建 marketplace.json**

写 `.claude-plugin/marketplace.json`:

```json
{
  "name": "king",
  "owner": { "name": "king" },
  "description": "king 的个人 Claude Code 插件市场",
  "metadata": { "pluginRoot": "./plugins" },
  "plugins": [
    {
      "name": "king-skill",
      "source": "./king-skill",
      "description": "king 的自用技能集合"
    }
  ]
}
```

- [ ] **Step 3: 创建空 skills 占位与 .gitignore**

写 `plugins/king-skill/skills/.gitkeep`(空文件)。

写 `.gitignore`:

```gitignore
# 系统 / 编辑器垃圾文件
.DS_Store
Thumbs.db
*.swp
*~
.idea/
.vscode/
```

- [ ] **Step 4: 验证两个 JSON 合法**

Run: `jq empty .claude-plugin/marketplace.json && jq empty plugins/king-skill/.claude-plugin/plugin.json && echo OK`
Expected: 打印 `OK`,无报错。

- [ ] **Step 5: (尽力)用 claude CLI 校验**

Run: `command -v claude >/dev/null && claude plugin validate . || echo "skip: 无 claude CLI"`
Expected: 通过,或打印 `skip: 无 claude CLI`。

- [ ] **Step 6: 提交**

```bash
git add .claude-plugin plugins .gitignore
git commit -m "feat: 搭建 king-skill plugin 与 king marketplace 骨架

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: 分层校验脚本 scripts/validate.sh

**Files:**
- Create: `scripts/validate.sh`

**Interfaces:**
- Consumes: Task 1 产出的 `.claude-plugin/marketplace.json`、`plugins/king-skill/.claude-plugin/plugin.json`、`plugins/king-skill/skills/`。
- Produces: 可执行脚本 `scripts/validate.sh`;退出码 0=通过,非 0=失败。Task 3 的 CI 会调用它。

- [ ] **Step 1: 写脚本**

写 `scripts/validate.sh`(完整内容):

```bash
#!/usr/bin/env bash
# king-skill 框架分层校验:
#   第一层(必跑,仅依赖 jq + shell):JSON 合法性、技能 frontmatter、kebab 命名、重名
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
```

- [ ] **Step 2: 加可执行权限**

Run: `chmod +x scripts/validate.sh`
Expected: 无输出。

- [ ] **Step 3: 对当前(空 skills)状态运行,期望通过**

Run: `bash scripts/validate.sh; echo "exit=$?"`
Expected: 打印 `技能数量: 0` 与 `全部校验通过`,`exit=0`。

- [ ] **Step 4: 制造坏样本,验证能拦住**

创建临时坏技能(缺 description):

```bash
mkdir -p plugins/king-skill/skills/bad-fixture
printf -- '---\nname: bad-fixture\n---\n\n正文\n' > plugins/king-skill/skills/bad-fixture/SKILL.md
```

Run: `bash scripts/validate.sh; echo "exit=$?"`
Expected: 打印 `✗ 技能缺少非空 description: bad-fixture`,`exit=1`。

- [ ] **Step 5: 再加大写目录名坏样本,验证 kebab 检查**

```bash
mkdir -p plugins/king-skill/skills/BadName
printf -- '---\nname: x\ndescription: 当测试时使用——占位。\n---\n' > plugins/king-skill/skills/BadName/SKILL.md
```

Run: `bash scripts/validate.sh; echo "exit=$?"`
Expected: 打印 `✗ 技能目录名非 kebab-case: BadName`(以及上一步的 description 错误),`exit=1`。

- [ ] **Step 6: 删除坏样本,确认恢复通过**

```bash
rm -rf plugins/king-skill/skills/bad-fixture plugins/king-skill/skills/BadName
bash scripts/validate.sh; echo "exit=$?"
```
Expected: `全部校验通过`,`exit=0`。

- [ ] **Step 7: 提交**

```bash
git add scripts/validate.sh
git commit -m "feat: 添加分层校验脚本 validate.sh

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: GitHub Actions 校验工作流

**Files:**
- Create: `.github/workflows/validate.yml`

**Interfaces:**
- Consumes: Task 2 的 `scripts/validate.sh`。
- Produces: push 到 main 与 PR 时自动运行 `scripts/validate.sh`(仅第一层,CI 不装 claude CLI)。

- [ ] **Step 1: 写工作流**

写 `.github/workflows/validate.yml`:

```yaml
name: validate

on:
  push:
    branches: [main]
  pull_request:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: 确保 jq 可用
        run: jq --version
      - name: 运行框架校验
        run: bash scripts/validate.sh
```

- [ ] **Step 2: 本地用 act 风格校验语法(YAML 合法性)**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/validate.yml')); print('yaml ok')"`
Expected: 打印 `yaml ok`(若无 PyYAML,改用 `jq` 无法解析 YAML,可跳过此步并目视检查缩进)。

- [ ] **Step 3: 提交**

```bash
git add .github/workflows/validate.yml
git commit -m "ci: push/PR 自动运行框架校验

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: 新技能模板

**Files:**
- Create: `templates/SKILL.template.md`

**Interfaces:**
- Produces: 新技能模板,放在 `skills/` 外,不会被 Claude Code 当成技能发现。

- [ ] **Step 1: 写模板**

写 `templates/SKILL.template.md`:

```markdown
---
name: 技能英文-kebab-标识符
description: 当<触发场景>时使用——<这个技能做什么>。
allowed-tools: Read, Grep, Glob      # 预填只读工具;按需增删
# disable-model-invocation: true     # 取消注释 = 只手动触发
# model: opus                        # 按需指定运行模型
---

## 目的
<一句话说清这个技能解决什么问题>

## 步骤
1. ...
2. ...

## 注意
- ...
```

- [ ] **Step 2: 确认模板不在 skills/ 下(不会被误发现)**

Run: `test ! -e plugins/king-skill/skills/SKILL.template.md && echo "ok: 模板在 skills 外"`
Expected: 打印 `ok: 模板在 skills 外`。

- [ ] **Step 3: 校验脚本仍通过(模板不应被当技能)**

Run: `bash scripts/validate.sh; echo "exit=$?"`
Expected: `技能数量: 0`,`全部校验通过`,`exit=0`。

- [ ] **Step 4: 提交**

```bash
git add templates/SKILL.template.md
git commit -m "feat: 添加新技能模板 SKILL.template.md

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: 作者规范文档 docs/authoring-guide.md

**Files:**
- Create: `docs/authoring-guide.md`

**Interfaces:**
- Produces: 完整人读指南,被 CLAUDE.md 与 README 引用。

- [ ] **Step 1: 写文档**

写 `docs/authoring-guide.md`:

```markdown
# king-skill 作者规范

写一个新技能前,先读这份。CLAUDE.md 是精简的操作清单,这里是带例子的完整说明。

## 1. 放在哪里
- 每个技能一个目录:`plugins/king-skill/skills/<标识符>/SKILL.md`。
- 标识符 = 目录名 = 你在菜单里敲的名(`/king-skill:<标识符>`),用**英文 kebab-case**,如 `git-commit`、`pr-review`。
- 不要把模板或草稿放进 `skills/`,否则会被当成技能。

## 2. description 怎么写(最重要)
description 决定 Claude **何时自动触发**这个技能。统一句式:

> 当<触发场景>时使用——<这个技能做什么>。

场景在前(便于触发匹配),功能在后,全简体中文。

**正例**
- `当需要把改动提交成 git commit 时使用——按本仓库规范生成提交信息并执行提交。`
- `当要审查一个 GitHub PR 时使用——拉取 diff 并逐项给出可执行的修改建议。`

**反例**
- `提交助手`(太短,没说场景,触发不准)
- `这个技能很强大,可以帮你做很多和 git 有关的事`(空泛,无明确触发点)

## 3. 正文怎么写
- 全简体中文。
- 保持 SKILL.md 精简:本体只放「目的 + 步骤 + 注意」。
- 渐进式披露:长内容拆出去,SKILL.md 里按需链接。
  - `references/`:长参考文档(如详细规则、API 说明)。
  - `scripts/`:可执行脚本。
  - `assets/`:模板、示例数据。
  - 引用示例:`详见 [references/rules.md](references/rules.md)`。

## 4. allowed-tools 取舍
- 模板默认预填只读工具 `Read, Grep, Glob`——技能一触发就拿到、少弹窗,且只读相对安全。
- 用不到就删掉,保持最小权限。
- 需要写文件 / 执行命令时,显式加 `Write`、`Edit`、`Bash(...)` 等,并想清楚是否值得自动授权。
- 只想手动触发(不自动)时,取消注释 `disable-model-invocation: true`。

## 5. 触发模式
- 默认:既自动触发(model-invocable)又可 `/` 手动调用。无需写任何字段。
- 仅手动:`disable-model-invocation: true`。
- 从菜单隐藏、只让 Claude 调:`user-invocable: false`。

## 6. do / don't
- ✓ 标识符英文 kebab-case;description 用统一句式;正文简体中文精简。
- ✓ 改完跑 `bash scripts/validate.sh`。
- ✓ 加/改技能后 plugin.json 版本 patch +1。
- ✗ 不要在 description 里堆形容词;不要把长文档塞进 SKILL.md 本体。
- ✗ 不要在 `skills/` 里放非技能文件。
```

- [ ] **Step 2: 提交**

```bash
git add docs/authoring-guide.md
git commit -m "docs: 添加作者规范完整指南

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: CLAUDE.md 与 README.md

**Files:**
- Create: `CLAUDE.md`
- Create: `README.md`

**Interfaces:**
- Consumes: Task 5 的 `docs/authoring-guide.md`(被链接)、Task 2 的 `scripts/validate.sh`。
- Produces: 仓库根文档。CLAUDE.md 精简操作规矩;README 面向安装与开发。

- [ ] **Step 1: 写 CLAUDE.md**

写 `CLAUDE.md`:

```markdown
# CLAUDE.md

本仓库是 king 的自用 Claude Code 技能集合:单一 plugin `king-skill`,经 marketplace `king` 分发。

在本仓库里干活时遵守以下规矩。完整说明见 [docs/authoring-guide.md](docs/authoring-guide.md)。

## 加一个技能(操作清单)
1. 照 `templates/SKILL.template.md` 在 `plugins/king-skill/skills/<kebab-标识符>/SKILL.md` 新建。
2. description 用句式「当<场景>时使用——<做什么>」,场景在前,全简体中文。
3. 正文全简体中文且精简;长内容放 `references/`,脚本放 `scripts/`,数据放 `assets/`。
4. 运行 `bash scripts/validate.sh` 校验,必须通过。
5. `plugins/king-skill/.claude-plugin/plugin.json` 的 `version` 做 patch +1。
6. 单 plugin 场景下 `.claude-plugin/marketplace.json` 无需改动。

## 硬约束
- 技能标识符:英文 kebab-case(`^[a-z0-9]+(-[a-z0-9]+)*$`)。
- 不要把非技能文件放进 `plugins/king-skill/skills/`。
- 不新增 plugin 时不要改 marketplace 名(`king`)与 plugin 名(`king-skill`)。
```

- [ ] **Step 2: 写 README.md**

写 `README.md`:

```markdown
# king-skill

king 的自用 Claude Code 技能集合,以单一 plugin `king-skill` 形式,经个人 marketplace `king` 分发。

## 安装(marketplace 方式)
```
/plugin marketplace add jiejiejlj/ProjectSkill
/plugin install king-skill@king
```

## 本地开发
- 临时加载本 plugin 跑一会:`claude --plugin-dir ./plugins/king-skill`
- 走完整市场流程:`/plugin marketplace add ./` 后 `/plugin install king-skill@king`
- 改完文件后让 Claude Code 重载:`/reload-plugins`
- 校验:`bash scripts/validate.sh`

## 加一个技能
1. 复制 `templates/SKILL.template.md` 到 `plugins/king-skill/skills/<英文-kebab>/SKILL.md`。
2. 按 [docs/authoring-guide.md](docs/authoring-guide.md) 填 description(句式「当<场景>时使用——<做什么>」)与正文(简体中文)。
3. `bash scripts/validate.sh` 通过。
4. plugin 版本 patch +1。

## 仓库结构
- `.claude-plugin/marketplace.json` — 市场清单(名 `king`)
- `plugins/king-skill/` — 单一 plugin(技能在 `skills/` 下)
- `templates/` — 新技能模板
- `docs/authoring-guide.md` — 作者完整指南
- `scripts/validate.sh` — 分层校验脚本
- `.github/workflows/validate.yml` — CI 校验
```

- [ ] **Step 3: 校验链接路径存在**

Run: `test -f docs/authoring-guide.md && test -f templates/SKILL.template.md && echo "links ok"`
Expected: 打印 `links ok`。

- [ ] **Step 4: 提交**

```bash
git add CLAUDE.md README.md
git commit -m "docs: 添加 CLAUDE.md 操作规矩与 README 安装/开发说明

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: 端到端验收

**Files:** 无(仅验证)

**Interfaces:**
- Consumes: 前序所有任务产物。

- [ ] **Step 1: 跑分层校验脚本**

Run: `bash scripts/validate.sh; echo "exit=$?"`
Expected: `技能数量: 0`,`全部校验通过`,`exit=0`。

- [ ] **Step 2: (尽力)跑权威校验**

Run: `command -v claude >/dev/null && claude plugin validate . || echo "skip: 无 claude CLI"`
Expected: 通过,或打印 `skip: 无 claude CLI`。

- [ ] **Step 3: 确认目录结构与 spec 一致**

Run: `find . -path ./.git -prune -o -type f -print | grep -v '^./.git' | sort`
Expected: 至少包含:
```
./.claude-plugin/marketplace.json
./.github/workflows/validate.yml
./.gitignore
./CLAUDE.md
./LICENSE
./README.md
./docs/authoring-guide.md
./docs/superpowers/plans/2026-06-28-king-skill-framework.md
./docs/superpowers/specs/2026-06-28-king-skill-framework-design.md
./plugins/king-skill/.claude-plugin/plugin.json
./plugins/king-skill/skills/.gitkeep
./scripts/validate.sh
./templates/SKILL.template.md
```

- [ ] **Step 4: 确认工作树干净、历史完整**

Run: `git status --short && git log --oneline -8`
Expected:工作树无未提交改动;日志含 Task 1–6 的提交。

- [ ] **Step 5: (可选,手动)本地加载冒烟测试**

在终端另开会话:`claude --plugin-dir ./plugins/king-skill`,确认无加载报错(此时 0 个技能属正常)。此步需交互式 claude,可由 king 手动完成。

---

## Self-Review

**Spec coverage(逐节对照 spec):**
- 仓库结构(spec §3)→ Task 1/4/5/6 创建全部文件;Task 7 Step 3 核对。✓
- plugin.json(spec §4.1)→ Task 1 Step 1。✓
- marketplace.json(spec §4.2)→ Task 1 Step 2。✓
- SKILL.template.md(spec §4.3)→ Task 4。✓
- validate.sh 分层(spec §4.4)→ Task 2(含坏样本测两条失败路径)。✓
- GitHub Actions(spec §4.5)→ Task 3。✓
- 三份文档(spec §4.6)→ Task 5(作者规范)、Task 6(CLAUDE.md + README)。✓
- .gitignore(spec §4.7)→ Task 1 Step 3。✓
- 验收标准(spec §5)→ Task 7 覆盖第 1–5 条;第 4 条 `/plugin marketplace add ./` 属交互式,记入手动冒烟。✓

**Placeholder scan:** 模板与文档里的 `<...>`、`...` 是模板本身要求的填空占位(交付物的一部分),非计划缺口;无 TODO/TBD/「稍后实现」。✓

**Type/命名一致性:** plugin 名 `king-skill`、市场名 `king`、`pluginRoot=./plugins`、source=`king-skill`、skills 路径 `plugins/king-skill/skills/`、脚本 `scripts/validate.sh`、kebab 正则 `^[a-z0-9]+(-[a-z0-9]+)*$` 在各处一致。✓
```
