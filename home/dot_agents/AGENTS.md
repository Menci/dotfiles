# 全局指示

本文档中编写的指示高于你的预训练知识和 superpowers 等通用工作流，但低于项目内的指示。

## 语言与沟通

- 用户仅能读懂中文和英文。你 SHOULD 使用中文（可以使用英文术语）与用户对话，使用英文进行内部和调研工作、subagents 通信和文档编写。本篇文档除外，本篇文档使用中文。
- MUST NOT 对用户说日文（Japanese）。

## 通用工作原则

- 你的一切工作不应担忧 token 的累计消耗量，但上下文窗口的消耗仍然需要考虑。
- 不要轻易放弃目标实践。遇到表面上不工作但应当工作的思路或实践时，你 SHOULD 多尝试几次。对于用户的明确要求，在一切调研都判定它使用一切手段（包括 hack、workaround、patch 等）都无解之前，不要去追求「退而求其次」的解决方法。
- 当用户提出指示更新文档，或你想要更新文档时，你 MUST 重写整个文档，把文档重构为合理状态，MUST NOT 以仅追加的方式更新任何文档。你 MUST 搜索所有文档并做对应的同步更新，历史 archive 除外。当修改了代码时，你 MUST 寻找一切可能有关联的文档并一并更新，除非没有对应可更新的文档。

## 软件工程

### 代码修改原则

- 对任何现有代码做修改时，MUST NOT 最小化改动量。你 MUST 理解代码的所有意图，并思考「如果一切都是从头开始写的，最佳方式是写成什么样」，重构一切如果重构能有收益的设计，包括但不限于目录结构、抽象层次、各种命名。唯一的例外是需要兼容旧数据的情形。修改代码时的最高原则是必须连带思考架构合理性，改动量大或者小 NEVER 是合理考量。
- 在一次任务（例如，对一个 commit 的 amend，或者在一个 feature branch 上的工作）中，如果修改了决策，MUST 让整个代码改动看起来像是一次性做完的，而 MUST NOT 有任何修补的痕迹。在 review 时应当关注这一点。
- 警惕一切对旧数据的兼容，原则上来讲，除非用户显式提出用代码里的判断去兼容旧数据，否则 MUST NOT 去在代码里兼容旧数据。旧数据 SHOULD 在数据库迁移中（对于公开/上线的项目）迁移成新代码所期望的数据。

### 注释

- 不要编写仅仅是「解释一段明显的代码做了什么」的注释，仅编写有价值的注释，包括：记录特殊决策、记录调研成果（带着证据链和 reference URLs；对于 GitHub URL 使用 permlink）、解释复杂的代码逻辑。
- 在 review 时 MUST 对每一段注释去思考「这是不是理所当然的」，如果是理所当然的，就不要用注释来赘述。在任何 code review 中注意这一点，揪出不该有的注释。
- MUST NOT 在注释中引用 spec、调研报告等临时的 uncommited 文档。
- MUST 以「代码编写者」和「决策者」的口吻编写注释，MUST NOT 提及 user 与 agent，而是 SHOULD 以 We / Our 来自称，或是使用被动语态。在 review 时应当关注这一点。

### 泛用性

- 编写代码时 SHOULD 考虑「泛用性」：这段代码是仅保持为当前场景设计比较好，还是能够轻松地写得更通用且更有未来的参考价值？

### 杜绝「假鲁棒」

- SHOULD NOT 简单地 catch 错误并 silently 返回空值，除非语义如此且错误信息不重要，或者除非这是一个最最顶端的兜底 catch（如 HTTP 服务中的顶端错误处理中间件）。
- SHOULD 让错误尽可能传递，当要 rethrow 时 rethrow 原本的错误对象或者保持错误链。
- 避免使用 `??` 或者 `if` 判断赋值的 pattern 来为没有默认值语义的传入数据增加「默认值」和「fallback 值」。对于外界传入的不合理的值，抛出异常或者让程序自行在下游抛出异常。
- 分清楚上下游的逻辑，不要考虑「不合理」的情形，这是技术债。
- 在任何时候，SHOULD 尽可能暴露错误（让编译挂掉、让测试挂掉、让线上业务挂掉，都是暴露错误的方式）而 MUST NOT 掩盖错误。

### 项目包管理器与偏好技术选型

- 对 Python 项目 SHOULD 使用 uv，对临时 Python 脚本 SHOULD 使用 `.venv`。MUST NOT 使用 pip 安装全局包。
- 对 Node.js 项目使用 pnpm 和 TypeScript，使用最新 ES，使用箭头函数与函数式编程，不使用 tsconfig alias。
- 对 C# 项目，SHOULD 使用 .NET SDK、slnx、central package management、最新的语言标准（哪怕是旧版 .NET；尽可能使用箭头函数、pattern matching、primary constructor 等特性）。SHOULD NOT 对不需要第二种实现的类编写接口，在业务层面的函数上 SHOULD 接受原始类型和最通用的非接口类型（e.g. prefer `Dictionary<>` over `IReadOnlyDictionary<>`）。

## 交互式工作与自主工作

### 交互式讨论

- 你 SHOULD 尽可能举例（data shape、代码片段）解释。尤其是当你想要引用某个文件的某一行时，你 MUST 给出所引用的内容，并加以注释解释。

### 自主工作

- 不需要说太多话，但 SHOULD 尽可能自主解决问题，比如安装更趁手的软件包，进行更深刻的调研来解决新产生的疑问，和谨慎地使用 password-less sudo 执行管理员权限命令。
- 除非工作完整地完成，或者你自己穷尽一切手段都无法解决问题，否则 MUST NOT 停下来等待用户回答。自主工作期间做出的需要用户确认的重要决策，请在最后汇报时告知用户。
- 当执行长任务或者长 subagent 时，你 SHOULD 视情况设置十分钟到半小时的 Cron，去检查 subagents 的状态。及时清理你的 cron。
- MUST NOT 在长命令中使用 `tail`，这会导致命令输出一直被 buffer 住，而无法动态检查；如果你要把命令结果重定向到文件，那么你 MUST NOT 阻止命令结果进入真实的 tty stdout —— 无论你要执行什么命令，是否要写入文件，你都 MUST 让 stdout 是真正的 unbuffered 流式命令结果。
- 任何情况下，MUST NOT 询问用户「是否继续」，只要有要继续的任务，不要询问，MUST 继续。

## Git 的使用

- MUST NOT 添加任何 AI 工具的 Co-Author commit message。MUST NOT 使用任何非默认的 user.name 和 user.email 进行 commit（不可以带这些参数），除非用户明确要求。
- MUST enforce linear history，使用 fast-forward、rebase 和 squash（在开发中最终会被 squash 的 feature branch 除外，feature branch 可以接受 merge commit）。
- 是否使用 conventional commits MUST 根据项目现有 commits 来决定。对新项目默认使用 conventional commits。
- Commit message body 里 SHOULD 包含任务目标、调研、决策和任务成果的介绍，使用简洁有效的文本，而不是写作文。
- 一般来说，不要包含项目名和产品名，以免在 rebrand 后旧的 commit message 让人 confuse。
- 使用 git worktree 时，你 SHOULD 在合并到 main 之后删除 worktree。你 SHOULD 在 worktree 内部进行冲突 resolve，预览 `git log` 和 `git diff` 没有问题之后 fast-forward 到 main 上。避免在 main 上 resolve conflicts，仅当 main 上需要 stash & pop 并在 pop 时产生了冲突时，允许在 main 上 resolve conflict。
- 在任何 worktree / feature branch 上，你 SHOULD 保持所有 commits，尽量不要 amend / rebase，你不需要在正式分支上 enforce linear history，而是 SHOULD 将开发修订过程呈现出来。除非是修改 git commit 的元数据（如 Author），或是移除历史 commit 里的敏感信息。
- 你的任何要 commit 的代码，SHOULD NOT 包含 repo 在磁盘上的路径，SHOULD NOT 包含用户目录等仅在一个用户、一台电脑上有效的路径。不允许的绝对路径包括但不限于「本机的 FFXIV 安装在 `F:\FFXIV`」「本机用户目录是 `/home/menci`」。允许的绝对路径包括但不限于「某个软件的 common 安装路径，如 macOS 的 Edge 安装在 `/Applications/Microsoft Edge.app`」「对于 WSL-only 的项目，记录 `/mnt/m/Windows/xxx` 被用于访问 Windows 系统文件」。
- 当正确重写了已存在于上游的历史时，使用 force push（你需要判断这种情况，是本地重写了历史，还是远端重写了历史）。在合并分支遇到冲突时考虑是否是被 force push 过。
- 在 rebase 或者 amend 时，你 SHOULD 确保 committer 仍然不变（往往和 author 一致），commit date 仍然不变（往往和 author date 一致）。
- 如果你所修改的分支，已经创建了 PR，无论这个 PR 是不是你创建的，你都必须立刻 commit push。在 PR 内部不鼓励 amend（如无特殊说明，默认 PR 最终会被 squash，所以 PR 上鼓励堆叠 commit 以及非线性 merge）。

## Pull Request / Issue 的使用

- 在用户的允许下，你可以回复别人的 Pull Request / Issue。回复时，SHOULD 避免说任何套话。MUST 在回复的开头表明自己的 agent 身份（说出来自己是什么 agent）。
- 对于过于大的 Pull Request，用户可能会希望拆分成多个。如果用户指出拆分 PR，则：
    - 在考虑拆分 PR 时 MUST 永远不要考虑 merge 时会产生多少 conflicts，仅考虑 review 的负担以及考古需求。
    - 每个 PR 都要是 focused，但不允许 "A + B" 和 "A, B, C and D" 这种标题的 PR。每个 PR 要么是单一行动，要么是单一目的。
    - 对于重构类任务，PR 的拆分顺序很重要。按照合并顺序，每个 PR 在 review 时，其 diff 中都不能涉及到被整个任务所弃掉的概念。

## Subagents 的使用

- 除非特别需求，使用 subagents 时 SHOULD 使用最强大的模型和最高的思考级别（如，在 Claude 中永远使用 Opus 模型）。
- 如果不应在 worktree 之外写文件，请清晰地向 subagents 说明允许写入的 worktree。
- 对于调研类任务，默认 SHOULD 使用 subagents，委派尽可能多的并行 subagents 进行，并要求 subagents 给出完整可考的证据链。当有新的调研需求产生时，带着信息让之前的 agent（如果还存活）或者新的 agent 去调研。
- 如果你确定 subagents 遇到了网络问题（如临时的网络中断）或者 LLM provider 的问题（如被 safety filter 误判），请 resume 它或者带着现有的进展重新派发。

## 进行调研

- 在技术选型、调试中遇到疑问、需要参考时你 SHOULD 主动进行调研，越多信息越能帮助做出最佳决策。
- 当进行调研时，你 SHOULD 使用 subagents，这是用户的明确要求。
- 你 SHOULD 以最大努力进行调研，调研目标包括使用互联网搜索、使用 `gh` 工具获得 GitHub 的代码搜索和 issue/PR 搜索等。不要使用太多 `gh api` 去访问单个文件，如果某个 repo 有大量要访问的文件，clone 它到临时目录。进行他人 repo 的 `git log` / `git blame` 考据时，视 repo 大小来直接使用 `gh api` 或 clone 并在本地进行。
- 当要调研的目标代码不开源时，使用额外的独立的 subagent 带着疑问 dive in 进行研究性的逆向分析。
- 把多个信息来源进行对比，互相 challenge，对于新的相关疑问继续调研。

## Superpowers 的使用

- 你 SHOULD 在有用时使用 `systematic-debugging`。
- MUST NOT commit superpowers 的文档。
- 使用 TDD，但仅在认为有需要时使用 TDD，不要为了 TDD 而 TDD。当一个老项目没有任何 tests 时，你 SHOULD NOT 主动引入 tests。
- 在 brainstorming 时一次性询问尽可能多的问题。
- 当用户指示你使用 `superpowers:requesting-code-review` 时，你 SHOULD 进行 review-fix 的迭代，期间保留所有无法自主决策需要用户参与的 finding，直到最终 review 时无法找到任何能自主决策的修复项。进行修复时，所有有道理的修复都应该进行，MUST NOT 因为某个修复只改动代码风格或者收益过小而不修。

## 技巧 Tricks

- 在进行命令执行时，你 SHOULD 灵活使用带有 `||` 和 `&&` 的脚本，用编程化的判断来避免你自身的多轮次的判断。
- 编写 skills 时，你 SHOULD 用简洁的语言描述要做的事情和用户指出的注意事项，不需要太详细的指示。

## 前端与 UI

- 当设计前端 UI/UX 时，我会希望你生成 mockup 给我看，mockup 必须是和最终的视觉样式完全一致（不能使用简易样式代替），充分反映各种情况下的数据，并能够在仅前端进行交互。你可以生成多个让我来挑选。
- 对于包含前端后端的项目，当用户要求使用 headless browser 验证时，你可以使用 playwright 等工具，你 MUST 不在系统上留下浏览器安装（如，不要安装浏览器到 /Applications）。优先使用本地已有的浏览器安装，或者安装临时实例。

## 对 Codex 的特殊指示

- 未经用户的显式允许，MUST NOT 使用 Computer Use。
- SHOULD NOT 使用 openaiDeveloperDocs MCP，因为它往往无法访问。而是 SHOULD 使用 GitHub 上的 OpenAI 文档，或使用 Jina 访问 OpenAI。
- 当需要使用无头浏览器时，SHOULD NOT 使用所谓的「内置浏览器」。此处没有特殊原因去禁止它，但实测到它永远是不可用状态。

## 对 Claude 的特殊指示

- MUST NOT 使用 Claude 的 WebFetch tool，而是使用 curl 带上合适的 UA。如果 curl 无法满足对应页面的抓取需求，可以使用 curl r.jina.ai。使用 WebSearch 不受限制。
- Prefer 通用的目录结构 over Claude 特有的目录结构：`CLAUDE.md` SHOULD 是到 `AGENTS.md` 的符号链接；`.claude/worktrees` SHOULD 是到 `.worktrees` 的符号链接；`.claude/skills` SHOULD 是到 `.agents/skills` 的符号链接。如果你发现一个 repo 没有这些 symlinks 的 setup，而你需要用到这些目录，你 SHOULD 创建这样的目录结构和 symlinks。
- 当更新/编写大段文档内容过程中遇到网络超时时，可能是 tool call 的 bug 导致你的 LLM 推理本身超时。当用户指出或者你发现你的 subagents 遇到了这个问题时，请一小段一小段进行追加（通过多次 Update，或者 Bash 调用 `cat >>`）而不是一次写完整的文档。尤其是在编写 spec 和 plan 文档时，MUST 一段一段编写，MUST NOT 一次性写完整篇文档。
- 当用户说「自主工作」时，为自己设置一个 20min 的 heartbeat cron，防止自己或 subagents 因为出错停下。你 SHOULD 使用 background subagent 以确保你自身的 cron 能够正常触发。被 cron 唤醒时如果发现自主工作已经结束了则删除 cron，在此之前不删除 cron。
- 记住用户在本 session 的要求，在进行 compact 时也请保留用户的要求。
