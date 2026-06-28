# king-skill 技能集合框架 — 设计文档

- 日期:2026-06-28
- 作者:king
- 状态:已确认,待实现
- 仓库:`jiejiejlj/ProjectSkill`(GitHub,SSH 别名 `github-jiejiejlj`)

## 1. 背景与目标

在空仓库 `ProjectSkill` 中,搭建一套 king 自用的 Claude Code 技能(skill)集合。

本次只做**框架与规范**,不放任何真实技能;真实技能以后照规范逐个加。框架要满足:

- 以 Claude Code **plugin** 形式组织,并通过 **marketplace** 方式安装、跨机同步。
- 所有技能装进**单一 plugin**(`king-skill`)。
- 配套:新技能模板 + 作者规范、分层校验脚本 + CI、三份文档(README / 作者规范 / CLAUDE.md)。
- 技能正文与 `description` 全中文;技能标识符用英文 kebab-case。

非目标(YAGNI):多主题 plugin 拆分、专属脚手架技能、CHANGELOG、git 钩子。这些以后需要再加。

## 2. 关键决策一览

| 维度 | 决策 |
|------|------|
| 仓库结构 | 方案 A 嵌套式:根放 marketplace,plugin 放 `plugins/king-skill/` |
| plugin 名 | `king-skill`(命名空间前缀 `/king-skill:<技能>`) |
| marketplace 名 | `king`(安装读作 `king-skill@king`) |
| 远程仓库 | GitHub `jiejiejlj/ProjectSkill`,marketplace 安装可行,CI 可行 |
| 版本策略 | semver,从 `0.1.0` 起;加/改技能时 patch +1 |
| 作者信息 | `author.name = "king"` + 仓库链接;不放邮箱;LICENSE 沿用 MIT |
| 技能标识符 | 英文 kebab-case(目录名 = slash 名) |
| description | 全中文,句式「当<场景>时使用——<做什么>」,场景在前 |
| 正文语言 | 全中文 |
| 触发模式 | 默认自动触发 + 可手动调用(沿用默认) |
| 辅助文件 | `references/`(长文档)、`scripts/`(脚本)、`assets/`(模板/数据) |
| 加新技能 | 静态模板 + CLAUDE.md 规矩 + 全局 `skill-creator`;不做专属脚手架技能 |
| 校验 | 本地脚本 + GitHub Actions;不加 git 钩子 |
| 校验设计 | 分层:自含检查必跑 + `claude plugin validate` 尽力跑 |
| 文档 | 三份分开:CLAUDE.md(精简操作规矩)/ docs/作者规范.md(完整指南)/ README(安装与开发) |
| 模板 allowed-tools | 预填只读工具 `Read, Grep, Glob`,按需增删 |

## 3. 仓库结构

```
ProjectSkill/
├── .claude-plugin/
│   └── marketplace.json          # 市场清单(名:king)
├── plugins/
│   └── king-skill/               # 单一 plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/               # 真实技能以后逐个加,现在为空
│           └── .gitkeep
├── templates/
│   └── SKILL.template.md         # 新技能模板(在 skills/ 外,不会被误当成技能)
├── docs/
│   ├── 作者规范.md
│   └── superpowers/specs/        # 设计与计划文档(本文件所在处)
├── scripts/
│   └── validate.sh               # 分层校验脚本
├── .github/
│   └── workflows/
│       └── validate.yml          # push/PR 自动校验
├── CLAUDE.md                     # 仓库内干活的操作规矩(精简)
├── README.md                     # 安装 / 本地开发 / 加技能简述
├── .gitignore
└── LICENSE                       # 已存在,MIT,沿用
```

设计原理:marketplace.json 在仓库根 `.claude-plugin/`,plugin 在 `plugins/king-skill/`,二者职责分离。以后若要拆成多个主题 plugin,只需在 `plugins/` 下新增目录并在 marketplace.json 多列一项,零迁移。

模板放在 `templates/`(而非 `skills/`)是为了避免被 Claude Code 当成一个空技能自动发现、误触发。

## 4. 文件内容规格

### 4.1 `plugins/king-skill/.claude-plugin/plugin.json`

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

- `skills` 字段省略,使用默认 `./skills/`。
- 技能命名空间前缀:`/king-skill:<技能>`。

### 4.2 `.claude-plugin/marketplace.json`

```json
{
  "name": "king",
  "owner": { "name": "king" },
  "description": "king 的个人 Claude Code 插件市场",
  "metadata": { "pluginRoot": "./plugins" },
  "plugins": [
    {
      "name": "king-skill",
      "source": "king-skill",
      "description": "king 的自用技能集合"
    }
  ]
}
```

- `metadata.pluginRoot = "./plugins"`,故 `source: "king-skill"` 解析为 `./plugins/king-skill`。

### 4.3 `templates/SKILL.template.md`

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

### 4.4 `scripts/validate.sh`(分层校验)

第一层(必跑,仅依赖 `jq` 与 shell):

1. `jq` 验证 `.claude-plugin/marketplace.json` 与 `plugins/king-skill/.claude-plugin/plugin.json` 是合法 JSON。
2. 遍历 `plugins/king-skill/skills/*/SKILL.md`:每个含非空 `description` frontmatter。
3. 每个技能目录名匹配 kebab-case 正则 `^[a-z0-9]+(-[a-z0-9]+)*$`。
4. 技能名无重复。

第二层(尽力跑):若 `command -v claude` 存在,则执行 `claude plugin validate .`。

任一检查失败 → 脚本以非零状态退出,并打印失败项。skills/ 为空时,第二层之前的技能遍历应安全跳过(0 个技能视为通过)。

### 4.5 `.github/workflows/validate.yml`

- 触发:`push`(分支 main)与 `pull_request`。
- 步骤:`actions/checkout` → 确保 `jq` 可用 → 运行 `bash scripts/validate.sh`。
- CI 不安装 Claude Code CLI,因此 `validate.sh` 第二层自动跳过;第一层始终执行。

### 4.6 三份文档

- **CLAUDE.md**(精简,载入上下文用):「加一个技能」的操作清单——
  1. 照 `templates/SKILL.template.md` 在 `plugins/king-skill/skills/<kebab-标识符>/SKILL.md` 新建。
  2. description 用句式「当<场景>时使用——<做什么>」,场景在前,全中文。
  3. 正文全中文;长内容拆到 `references/`,脚本放 `scripts/`,数据放 `assets/`。
  4. 运行 `bash scripts/validate.sh` 校验。
  5. `plugins/king-skill/.claude-plugin/plugin.json` 版本 patch +1。
  6. 单 plugin 场景下 marketplace.json 无需改动。
  细节指向 `docs/作者规范.md`。
- **docs/作者规范.md**(完整人读指南):description 句式正反例、技能目录布局、渐进式披露原则、`allowed-tools` 取舍、命名约定、do/don't 清单。
- **README.md**(给使用者/安装者):
  - 项目简介。
  - 安装:`/plugin marketplace add jiejiejlj/ProjectSkill` → `/plugin install king-skill@king`。
  - 本地开发:`claude --plugin-dir ./plugins/king-skill`;或 `/plugin marketplace add ./` 后安装;改完用 `/reload-plugins`。
  - 加技能:简述流程并链接到 `docs/作者规范.md`。

### 4.7 `.gitignore`

忽略常见系统/编辑器垃圾文件(如 `.DS_Store`、`*.swp`、`.idea/`、`.vscode/` 视需要)。

## 5. 验收标准

1. `bash scripts/validate.sh` 在空 skills/ 状态下通过(退出码 0)。
2. `claude plugin validate .`(本地有 CLI 时)通过。
3. `claude --plugin-dir ./plugins/king-skill` 能加载 plugin(此时 0 个技能,但加载不报错)。
4. `/plugin marketplace add ./` 能识别市场 `king` 与其中的 `king-skill`。
5. 目录结构、各文件内容与本设计第 3、4 节一致。
6. 三份文档齐备且职责不重叠;CLAUDE.md 保持精简。

## 6. 后续(本框架之外)

框架就位后,按 CLAUDE.md / 作者规范逐个添加真实技能。第一个真实技能将顺带验证「自动触发」是否符合预期(本框架阶段仅验证结构与加载)。
