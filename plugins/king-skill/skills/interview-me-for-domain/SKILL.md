---
description: 当需要在穷追式盘问的同时、把谈定的统一语言(术语表)和难反悔的架构决策(ADR)当场写成活文档时使用——在 interview-me 盘问之上叠加领域建模,边问边产出 CONTEXT.md 与 docs/adr/。
allowed-tools: Read, Grep, Glob, Write, Edit
disable-model-invocation: true
---

## 目的
在 interview-me 的穷追式盘问之上叠加领域建模:边盘问边把「统一语言」(CONTEXT.md 术语表)和「难反悔的结构性决定」(docs/adr/ ADR)当场写成活文档。

## 步骤
1. 盘问基底:完全遵循 interview-me 的盘问纪律(一次一问、每题给推荐、按依赖逐层、能查码先查、穷追到共识、不设退出口)。基底以 interview-me 技能为准,本技能不重写。
2. 叠加领域建模五条纪律:① 拿术语表对质冲突 ② 逼精模糊/超载措辞、给规范术语 ③ 造边界场景压测概念边界 ④ 和代码对账 ⑤ 术语一谈定就当场写进 CONTEXT.md。详见 [references/method.md](references/method.md)。
3. 文档落在「被设计项目」根目录:`CONTEXT.md`(术语表)、`docs/adr/0001-slug.md`(ADR)。懒创建——有内容要写才建文件,首次落盘前先确认一次。单上下文默认,出现多个限界上下文才升级 `CONTEXT-MAP.md` + 各上下文子目录。
4. 当场随谈随写:术语/决策一结晶就立刻写进对应文件;ADR 仅在「难反悔 + 没上下文会让人意外 + 真权衡」三闸全过时才写。格式见 [references/context-format.md](references/context-format.md)、[references/adr-format.md](references/adr-format.md)。
5. 收尾:除 interview-me 的共识小结外,再给出本次产出/更新的文档清单(路径)。

## 注意
- 盘问纪律不重写,一切以 interview-me 为准;本技能只加「领域建模 + 活文档」层。
- `CONTEXT.md` 是纯术语表,零实现细节;实现性取舍归 ADR。
- 懒创建、按需写,别无脑刷文件。
- ADR 三闸缺一不写。
