---
name: offload-watch
description: Offload watching and digesting to a cheap model through T3 delegate_task. Use for long-running commands (CI runs, builds, test suites, deploys), commands with large output, and summarizing large logs, files or transcripts, when you need a short report rather than the raw output.
---

# Offload watch

A quick model in its own T3 thread runs the command, waits for it, reads the output, and hands back a short report. The raw output never enters your context. You pay for a delegate call and the report, not for every wait and every read.

**When it pays:** from a session holding context C, offloading costs you 2–3 requests at C. Doing it yourself costs 4–8 requests at C, plus the output, which then stays in C for the rest of the session. Waiting and reading both add requests, so judge by both: offload a long run, and also a short one whose output (a big test log, a cascade of build errors) takes more than one small scripted pass to digest. Run it yourself only when it finishes in under a minute and its output is a few KB.

## Steps

1. **Write the worker prompt** from [worker-prompt.md](worker-prompt.md). Fill in the directory, the command or file, and what the report must contain. The worker sees only this prompt, so include every path, flag and environment detail it needs. If the task depends on state only your session holds, do it yourself.

2. **Pick the target**:

   | target | when |
   |---|---|
   | `{"providerInstanceId": "claudeAgent", "model": "claude-haiku-5-5", "options": {"effort": "medium"}}` | default: best quality for the price |
   | `{"providerInstanceId": "codex", "model": "gpt-6-luna", "options": {"reasoningEffort": "medium"}}` | bill the Codex account; cheapest, weaker on cascading build errors and summaries |
   | `{"providerInstanceId": "antigravity", "model": "gemini-3.8-flash-medium"}` | spare Claude and Codex quota; uses the most tokens |

   If a target is refused, look up the current ids with `orchestrator_capabilities`.

3. **Delegate and wait.** Call `delegate_task` with the target, the worker prompt as `task`, `runtimeMode: "full-access"`, a short `title`, and a `clientRequestId` you can reuse if you retry. Wait the way your harness supports:
   - **Claude Code:** `mode: "async"`. Carry on with other work, or end your turn. T3 delivers the result when the child finishes, then read it once with `task_status`.
   - **Codex, Gemini and other harnesses:** `mode: "wait"` with `timeoutMs: 1800000`. The call blocks until the child finishes. If it returns `waitTimedOut`, block again with `t3_thread_wait` on its `childThreadId`.

   Each request re-sends your whole context, so waiting is a single blocking call or a notification. Check status between other pieces of work, never in a loop.

4. **Act on the report.** Before you declare something green, or base a fix on the report, check one claimed item against the log path the report gives.

## Without T3

When `delegate_task` is unavailable, run [`scripts/offload`](scripts/offload) (`--help` for options). It runs the command, saves the log, then has a quick model CLI write the report. The child CLI runs inside your sandbox, so it can fail where a T3 child would not, for example with no network or no write access to its config directory. For commands longer than your shell timeout, run it with your harness's background mode.
