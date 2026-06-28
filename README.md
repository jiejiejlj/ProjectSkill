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
2. 按 [docs/authoring-guide.md](docs/authoring-guide.md) 填 description(句式「当<场景>时使用——<做什么>」)与正文(中文)。
3. `bash scripts/validate.sh` 通过。
4. plugin 版本 patch +1。

## 仓库结构
- `.claude-plugin/marketplace.json` — 市场清单(名 `king`)
- `plugins/king-skill/` — 单一 plugin(技能在 `skills/` 下)
- `templates/` — 新技能模板
- `docs/authoring-guide.md` — 作者完整指南
- `scripts/validate.sh` — 分层校验脚本
- `.github/workflows/validate.yml` — CI 校验
