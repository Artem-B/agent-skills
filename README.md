# agent-skills

Skills and scripts for coding agents (Claude Code, Codex, Gemini via Antigravity) that run under [T3 Code](https://github.com/pingdotgg/t3code).

## Skills

### offload-watch

Hands mechanical, token-heavy work to a cheap model in its own T3 thread: running and waiting on CI, builds and test suites, and digesting large logs or transcripts. The caller gets back a short report instead of the raw output.

- [`SKILL.md`](skills/offload-watch/SKILL.md): when to offload, which model to use, and how to wait without polling.
- [`worker-prompt.md`](skills/offload-watch/worker-prompt.md): the worker prompt template.
- [`scripts/offload`](skills/offload-watch/scripts/offload): a fallback for when T3 is unavailable. It runs the command, then has `claude -p` or `codex exec` write the report.

Findings from benchmark runs (mock CI and build logs, 120 runs, list prices):

- **Quality:** Haiku 5.5 and GPT-6-Luna matched Opus 5.5 and GPT-6.1-Sol on CI and build watching (quality 0.97–1.0). Luna was weaker on build-error cascades and session summaries.
- **The heavy model's fixed cost per delegation dominates:**
  - Opus about $0.25 for a fresh Claude Code session (cache-writing ~25k tokens of start-up prompt).
  - Sol about $0.04 when it blocks.
- **Waiting matters more than the model:** Sol polling `task_status` took 16 requests and ~500k tokens per job; blocking in one `delegate_task` call (`mode: "wait"`) took 2–3. Claude Code callers end their turn and are woken by T3.
- **Cost of doing it yourself in a big session:** a 4-call watch job costs about calls × context × cache-read price. At 520k context that's $0.48 per job with Opus, against $0.11 at 53k.

## Install

```sh
./install.sh
```

This links each skill into `~/.agents/skills/` and `~/.claude/skills/`. Then add [`snippets/global-instructions.md`](snippets/global-instructions.md) to your global agent instructions (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`). That line is what makes agents reach for the skill reliably, and it tells Codex not to poll.

## License

Apache 2.0
