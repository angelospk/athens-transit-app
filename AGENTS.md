# Agent rules

## Task board

All work on Athens Transit (backend `athens-transit-rt`, app `athens-transit-app`, web
`athens-transit-map`) is tracked on one GitHub board:
https://github.com/users/angelospk/projects/3. Issues live in the repo they change. Use
`track` (`~/.local/bin/track` on the mini PC) or `gh` directly. Repo keys: `rt`, `app`, `web`.

### When work needs an issue or a PR

Backend (`athens-transit-rt`): every change goes through an issue, a PR and a review. It is
the data source for the app and the web, and a merge to `main` deploys it (about 10 minutes,
with a restart). Ask Harold before a merge. Raise the load on OASA in small steps only.

App and web (`athens-transit-app`, `athens-transit-map`): the UI still changes often, so
commit straight to `main` after the tests, the typecheck and the build pass. In the web, a
push to `main` deploys bus.haroldpoi.dev. Open an issue only when:

- the work will not be finished in this session (a bug or an idea to keep);
- a person must act (a deploy, a test on a phone, a decision);
- it depends on, or blocks, work in another repo;
- it is large enough that two agents could collide on it (several sessions).

Open a PR only when someone else must review it before it goes live, or for a risky change
(data migration, auth, push notifications, a release build). Small fixes, UI tweaks and
iterations need no issue, no PR and no board item; the commit message says what changed and
why.

### Tracked work

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
