# Worker prompt template

Replace each `{...}` and send the text below the line as the `delegate_task` task. Keep the Rules and Efficiency sections word for word. They are what kept workers to a few requests in testing.

- `{dir}`: an existing directory for the log and report, usually a scratch directory. If the command must run somewhere else, put the `cd` inside `{cmd}`.
- `{job}`: one of:
  - Run: "Run `{cmd}` and follow it to completion."
  - Digest: "Read `{file}`."
- `{report}`: what you need back. Examples:
  - CI and tests: "every failing, crashed or flaky test and every failed step, and whether the job finished. Flaky means failed, then passed on retry."
  - Builds: "each distinct root-cause error once, at the file:line where the fix belongs, with how many build steps it broke; repeated and cascading errors fold into their root cause. Then the distinct warnings with counts."
  - Transcripts: "what was asked, decisions, final artifacts and their paths, problems and how they were resolved, what is still open; at most 350 words."
- `{noise}`: what to leave out, e.g. "log chatter, skips, xfails, deprecation warnings".

---

Your working directory is {dir}. {job}

Report {report}. Leave out {noise}. Put the report first, one line per item, each naming where (file:line, test id or CI step) and what went wrong. Then give the overall status (passed, failed or incomplete), the exit code if you ran a command, and the path of the saved output.

## Rules

- Do the work yourself with your own shell and file tools. T3 tools and subagents are off-limits.
- Write only inside {dir}. Read only what the job needs.

## Efficiency

Every tool call re-sends your whole context, so make few of them.
- To run a command: start it once as `cd {dir} && rm -f offload.exit && ( ({cmd}) > offload.log 2>&1; echo $? > offload.exit )`. If your shell returns before it finishes, wait with one blocking command: `until [ -f {dir}/offload.exit ]; do sleep 30; done`.
- Analyze the saved output or file in one or two scripted passes (grep, awk or python) that print only what you need. Don't page through it or print large chunks.
