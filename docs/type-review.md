# Type review

Safari's code is being made right one module at a time, types first, because
good types are the most fundamental part of the system: a well-written type is
clear with almost no context. The work comes in two kinds of job, each done by
a cold agent with this file as its brief. A review agent reads a module's types
and recommends fixes. A cleanup agent makes the fixes the orchestrator decided
on, in a worktree of its own. The orchestrator merges, gates and decides.

## Shell rules for every agent

Bash runs only Shale, in exactly this form:

```
cd DIR && shale [FILE] [NAME=VALUE ...] <<'TAG'
...shale code...
TAG
```

Shale is a small Lua-like language:

- **Running a program:** `local r = run({"git", "status"}, {timeout_ms = 60000, whole = 20000, want = "any"})`, then `print(r.code)` and `print(r.out)`. A text tool such as grep needs a reason, as in `want = "any: callers"`.
- **Files:** read with the Read tool, and edit with Edit and Write.
- **Not in the language:** `table.*`, `local function`, and `type()`.
  - Declare a function with `function name()` at the top level.
  - Walk a map with `for k in keys(m) do`.
  - Join a list with `join(l, sep)`.
- **Paths:** they're relative to the folder you `cd` to. A `repos:` path names a repo under ~/showell_repos.

Never push, never merge, and never touch a checkout that isn't yours.

## Read first, every time

1. `CLAUDE.md` at the roc-apps root and `docs/roc-style.md`: the rules.
2. `docs/smells.md`: Steve's smells, each with a real case. Read it right
   before you review or design, so the smells are fresh.
3. This file.

## The review job

You review one module, or a small family of them, named in your prompt. You change nothing.

### 1. Walk the types

From `canvas_apps/safari` in the main checkout (`/home/steve/showell_repos/roc-apps`):

```
cd /home/steve/showell_repos/roc-apps/canvas_apps/safari && shale cookbook:roc/type_walk.shale module=Tower packages=lib=repos:roc-apps/canvas_apps/lib <<'TAG'
TAG
```

The walk prints the module's types and every type they depend on to depth 3,
the most primitive first, with no function bodies. Read it the way a newcomer
would, from the top. Types past depth 3 are named in one line and not
followed. Read their source only if a finding needs it.

### 2. Read the code behind what smells

The walk shows the surface. Open the source where a type, a name or a
signature smells, and check:

- **Who calls what.** grep the callers. A member of a type's `.{ }` block that
  nothing outside the file uses is a private helper wearing a public name.
- **What the function really returns.** A list that holds one thing or none,
  a crash that a better type would make impossible, or a record that repeats
  another type's fields.

### 3. What to look for

Use every smell in `docs/smells.md`, and don't stop there. These turned up in
the reviews so far:

- **The module is a kitchen sink.** An empty `[].{ }` used as a namespace, or a
  type's block full of helpers. Pigs became `Pig`, `PigHerd` and the route's
  choices in World. Tower's block has 31 members, and 3 are used outside the
  file.
- **One input is packed several ways.** Tower takes `Picture.Setting`, then a
  record of its own, then `TowerInView`, with `center` as `foot` under a second
  name.
- **The type is wider than the truth.** A list for one or none, a signed number
  for a count, or a crash for a state the type allows.
- **A route choice lives in a kind's module.** "Seven rows of seven" is the
  world's choice. How a herd is laid out is the herd's.
- **One thing has two homes.** `World.Segment` holds both a `pigs` list and the
  `pig_herd` it's computed from.
- **Names.** Abbreviations (`rod_w`), a type repeated in the name (`width_px :
  Pixels`), a word with two meanings, or a name that needs its comment.
- **Tuned constants.** Ask what each one stands for.

### 4. Report

Your final message is the report, and the orchestrator reads all of it. Keep
it plain, and don't write long prose. For each finding, worst first, give:

- **What:** the smell, where it is (`file:line`), and in one or two sentences
  why it matters.
- **Fix:** the change you recommend, as concrete as a signature. Show a short
  before and after for the worst one or two findings.
- **Reach:** the files the fix touches. Mark any shared module (Geom, Camera,
  Picture, Pipeline, RoadAhead, World, Scenery, SceneShapes, anything in `lib`,
  `Distance`, `Along`, `Across`, `Fraction`, `Pixels`, `Angle`), and any widget
  that imports the module.
- **Pixels:** whether the fix should leave every pixel as it is, or would move
  some. Say which and why.
- **Call:** "clear" if the fix is plainly right, or "needs Steve" if it's a
  design question with real weight on both sides. Say what the two sides are.

End with the findings you considered and rejected, one line each, so they
aren't raised again.

Then say, in a line or two, how depth 3 felt for this module:
- **Noisy:** were types near the bottom of the walk ones you never needed?
- **Incomplete:** did a finding need a type past the cut, which you had to read
  in its source?

Name the types either way. The depth is a setting, and these answers are how
it gets tuned.

## The cleanup job

You make the fixes listed in your prompt, which the orchestrator has decided.
Make those fixes and nothing else. If you see something more, put it in your
report.

### Where you work

Your worktree is named in your prompt, under `/home/steve/showell_repos/lanes/`,
on its own branch. Work and commit only there. Commit as you go, and end each
message with:

```
Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

### Shared modules

Your prompt says which shared modules (the list under the review job's
"Reach") you may change. Change no other shared module. If a fix needs one,
stop that fix and say so in your report. Another lane may be changing it.

### Checks

Run only the fast tier, from your worktree's root:

```
cd /home/steve/showell_repos/lanes/<lane> && nice -n 19 shale canvas_apps/safari/gates/fast.shale <<'TAG'
TAG
```

It runs `roc check`, the format check, the expects, the lints on changed
files, and one frame held to `gates/proof.expected`.

- **Speed:** about 10 seconds when warm. The first run in a new worktree builds
  its cache, which takes longer.
- **Widgets:** if you change something a widget imports, also run `roc check web.roc` in that widget's folder (`canvas_apps/<name>_widget`), with the
  pinned Roc: `/home/steve/tools/roc-nightly-2026-11-03-34bd006/roc`.
- **The full gate is the orchestrator's.** Don't run `gates/run.shale`.
- **A lint you trip:** fix the code. Never loosen a lint or raise a held
  count, except for the book's stale-name counts in `gates/run.shale`, as
  noted below.

### Pixels

A fix decided as "pixels hold" must keep the frame. If fast.shale's frame
moves, find out why. Don't update `proof.expected`.

A fix decided as "pixels move" will fail fast.shale's frame on purpose. In
that case, check everything else is green, leave `proof.expected` alone, and
say in your report which frame moved and what should look different. The
orchestrator renders it for Steve's eye test.

### The book

The tutorial (canvas_apps/safari/tutorial/) is parked, and it will be
rewritten later.

- **Prose:** don't rewrite any.
- **A broken include:** if an include such as `{{code Module.name}}` names
  something you moved, point it at the new name.
- **Stale names:** if a name in the prose goes stale, raise
  `BOOK_STALE_NAMES_HELD` (or `BOOK_STALE_DIAGRAM_NAMES_HELD`) in
  `gates/run.shale` to match, and list each newly stale name, with its line,
  in your report.

### Report

Keep it short:
- the new or changed types, as annotations
- each fix, done or not, with the reason if not
- the fast.shale result
- whether pixels moved
- book names that went stale
- anything you saw and left alone
