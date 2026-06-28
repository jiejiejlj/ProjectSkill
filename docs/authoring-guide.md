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
- **文件名一律英文 kebab-case**(含 `references/`、`scripts/`、`assets/` 里的文件,如 `rules.md`、`build.sh`),不要用中文文件名;文件内容仍用简体中文。

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
- ✗ 不要用中文文件名(文件名一律英文 kebab-case;内容可用简体中文)。
