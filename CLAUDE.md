# CLAUDE.md

本仓库是 king 的自用 Claude Code 技能集合:单一 plugin `king-skill`,经 marketplace `king` 分发。

在本仓库里干活时遵守以下规矩。完整说明见 [docs/authoring-guide.md](docs/authoring-guide.md)。

## 加一个技能(操作清单)
1. 照 `templates/SKILL.template.md` 在 `plugins/king-skill/skills/<kebab-标识符>/SKILL.md` 新建。
2. description 用句式「当<场景>时使用——<做什么>」,场景在前,全中文。
3. 正文全中文且精简;长内容放技能目录内的 `references/`,脚本放 `scripts/`,数据放 `assets/`(均相对该技能目录,勿与仓库根的 `scripts/` 混淆)。
4. 运行 `bash scripts/validate.sh` 校验,必须通过。
5. `plugins/king-skill/.claude-plugin/plugin.json` 的 `version` 做 patch +1。
6. 单 plugin 场景下 `.claude-plugin/marketplace.json` 无需改动。

## 硬约束
- 技能标识符:英文 kebab-case(`^[a-z0-9]+(-[a-z0-9]+)*$`)。
- 所有文件名一律英文 kebab-case(含技能目录内 `references/`/`scripts/`/`assets/` 的文件);不要用中文文件名,文件内容可中文。
- 不要把非技能文件放进 `plugins/king-skill/skills/`。
- 不新增 plugin 时不要改 marketplace 名(`king`)与 plugin 名(`king-skill`)。
