# Agent rules

## Task board

All work on Athens Transit (backend `athens-transit-rt`, app `athens-transit-app`, web
`athens-transit-map`) is tracked on one GitHub board:
https://github.com/users/angelospk/projects/3. Issues live in the repo they change. Use
`track` (`~/.local/bin/track` on the mini PC) or `gh` directly. Repo keys: `rt`, `app`, `web`.

1. Before you start, look for existing work: `track list`, `gh issue list` AND `gh pr list`
   in the repo (a PR is a task too; people often open a PR without an issue). Read the latest
   comments of the parent issue. Open a new issue only when neither exists, then `track add`.
   If the item is `In progress` or has an open PR, someone else has it: stop and say so.
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
