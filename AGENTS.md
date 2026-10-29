# Agent rules

## Task board

All work on Athens Transit (backend `athens-transit-rt`, app `athens-transit-app`, web
`athens-transit-map`) is tracked on one GitHub board:
https://github.com/users/angelospk/projects/3. Issues live in the repo they change. Use
`track` (`~/.local/bin/track` on the mini PC) or `gh` directly. Repo keys: `rt`, `app`, `web`.

1. Before you start, find the issue (`track list`, `gh issue list`). If there is none, open
   one and `track add`. If the issue is `In progress`, someone else has it: stop and say so.
2. Claim it: `track claim <repo> <num> "<agent> in <thread link>"`. This sets `In progress`,
   assigns it and comments.
3. A new problem found during the work gets its own issue (`gh issue create` + `track add`),
   not a fix folded into the current task.
4. Commits and PRs say `Refs #N` or `Fixes #N`.
5. When you finish: `track done <repo> <num> "<SHA or PR, tests, review>"`. A PR waiting for
   review: `track move <repo> <num> Review`. Blocked: `track block <repo> <num> <by-repo>
   <by-num>`, or `track move ... Blocked` plus a comment that names the person.
6. Work for a person (deploy, test on a phone, a decision) gets the `human` label and an
   assignee: `angelospk` (Harold), `abinop` (Alexandros, backend and hosting),
   `imertz` (Yiannis, contributor).
7. Scheduled jobs and new threads put the issue number in their brief.
