# CLAUDE.md

本仓库是 king 的自用 Claude Code 技能集合:单一 plugin `king-skill`,经 marketplace `king` 分发。

在本仓库里干活时遵守以下规矩。完整说明见 [docs/authoring-guide.md](docs/authoring-guide.md)。

## 开发语言
- **一律使用简体中文开发**:技能 `description`、正文,以及仓库内文档(README、authoring-guide、提交信息说明等)都用**简体中文**书写。
- 不要使用繁体中文、英文或其他语言来写这些内容(代码、标识符、文件名等技术标识除外——它们一律英文)。

## 分支策略(每个 feature 一条分支)
新增/修改技能、改动框架,都在独立 feature 分支上完成,**别直接在 `main` 上动**。

**一定开新分支(直接开,不必问):**
- 新增技能(`plugins/king-skill/skills/` 下新建)。
- 修改已有技能内容(`SKILL.md` 及其 `references/`、`scripts/`、`assets/`)。
- 改动框架(`templates/`、根 `scripts/`、`docs/`、`plugin.json`、`marketplace.json`)。

**不开新分支:** 纯错别字/格式小修;或用户明确说「就在当前分支改」。
**模糊地带:** 动手前先问一句「是否开新分支」。

**分支命名:**
- 新增技能:`feat/skill-<标识符>`(如 `feat/skill-interview-design`)。
- 改技能:`fix/skill-<标识符>-<简述>`。
- 框架改动:`chore/<简述>` 或 `docs/<简述>`。

**完成后:** `bash scripts/validate.sh` 通过 → 提交 → 合回 `main`(个人仓库,默认不强制 PR,需要时再开)。

**硬兜底:** `.claude/settings.json` 的 PreToolUse 守卫钩子(`scripts/guard-branch.sh`)会在 `main` 分支上拦截对 `plugins/king-skill/skills/**` 的写入,提醒先开分支。框架文件不在钩子拦截范围,靠本约定自觉。

## 加一个技能(操作清单)
0. **先开 feature 分支**(新增技能属于「一定开新分支」,见上节)。
1. 照 `templates/SKILL.template.md` 在 `plugins/king-skill/skills/<kebab-标识符>/SKILL.md` 新建。
2. description 用句式「当<场景>时使用——<做什么>」,场景在前,全简体中文。
3. 正文全简体中文且精简;长内容放技能目录内的 `references/`,脚本放 `scripts/`,数据放 `assets/`(均相对该技能目录,勿与仓库根的 `scripts/` 混淆)。
4. 运行 `bash scripts/validate.sh` 校验,必须通过。
5. `plugins/king-skill/.claude-plugin/plugin.json` 的 `version` 做 patch +1。
6. 单 plugin 场景下 `.claude-plugin/marketplace.json` 无需改动。

## 硬约束
- 技能标识符:英文 kebab-case(`^[a-z0-9]+(-[a-z0-9]+)*$`)。
- 所有文件名一律英文 kebab-case(含技能目录内 `references/`/`scripts/`/`assets/` 的文件);不要用中文文件名,文件内容可用简体中文。
- 不要把非技能文件放进 `plugins/king-skill/skills/`。
- 不新增 plugin 时不要改 marketplace 名(`king`)与 plugin 名(`king-skill`)。
