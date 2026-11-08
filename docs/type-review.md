# Type review

Safari's code is being made right one module at a time, types first, because
good types are the most fundamental part of the system: a well-written type is
clear with almost no context. The work comes in two kinds of job, each done by
a cold agent with this file as its brief. A review agent reads a module's types
and recommends fixes. A cleanup agent makes the fixes the orchestrator decided
on, in a worktree of its own. The orchestrator merges, gates and decides. The orchestrator's side of the
process is `docs/review-workflow.md`.

## Shell rules for every agent

Bash runs only Shale, in exactly this form:

```
cd DIR && shale [FILE] [NAME=VALUE ...] <<'TAG'
...shale code...
TAG
```

Shale is a small Lua-like language:

- **Running a program:** `local r = run({"git", "status"}, {timeout_ms = 60000, whole = 20000, want = "any"})`, then `print(r.code)` and `print(r.out)`. Both `timeout_ms` and a keep (`whole`, `head` or `tail`) are required. A text tool such as grep needs a reason, as in `want = "any: callers"`.
- **Never read `~/.config/shale/mounts`, and never run `shale --help`.** Both show the path of the secrets folder. The `scratch:` mount is `/tmp/claude-1000`, so write scratch files there under `/tmp/claude-1000/<lane>/`.
- **A scratch Roc module** must declare a type named after its file.
- **Shale gaps agents keep hitting:**
  - There's no `write` or `write_file`: `replace(path, text)` writes a file.
  - `substitute(text, old, new)` replaces every occurrence in a string, stops on a miss unless given `{missing_ok = true}`, and is **not word-bounded**. `find(text, pattern)` is a plain substring search, not a pattern. There's no `string.*` or `gsub`.
  - **To rename a Roc identifier, use `cookbook:roc/rename.shale`** (word-bounded; `module=` for a qualified name; `skip=`, `fields=1`, `book=`, `dry=1`; it fails when nothing matched), never a hand-rolled `substitute`, which hits `proportion` when you meant `portion`.
  - A long string holding `]]` needs `[=[ ... ]=]`.
  - A function sees only `const`s, not the script's locals.
  - `read` and `replace` paths are relative to the folder you `cd` to, or a mount such as `repos:` or `scratch:`, never absolute.
  - Map keys must be strings.
  - Loop over a list with `for x in list do ... end`, and over a map with `for k in keys(m) do`. `ipairs` and `for i, x in` are refused.
  - A module must be listed in `game.roc` before a module in `gates/expects/` can import it, and a new module in `gates/expects/` must be listed in its `main.roc`, or its expects never run.
- **Files:** read with the Read tool, and edit with Edit and Write.
- **Not in the language:** `table.*`, `local function`, and `type()`.
  - Declare a function with `function name()` at the top level.
  - Walk a map with `for k in keys(m) do`.
  - Join a list with `join(l, sep)`.
- **Paths:** they're relative to the folder you `cd` to. A `repos:` path names a repo under ~/showell_repos.

The gate enforces this for every agent: any other Bash command is refused. For a real need Shale can't meet, the escape is a first line `# want: <tag>: <text>`, which runs the command and logs it so Steve can see what agents reach for. Use it rarely, and say so in your report.

Never push, never merge, and never touch a checkout that isn't yours.

Several agents share one scratch area, so keep your scratch files under Shale's `scratch:` mount (`/tmp/claude-1000`), in a subfolder named for your lane or review, such as `scratch:<lane>/`, or another agent may overwrite them. Never put scratch files in a repo or a worktree.

## Read first, every time

1. `CLAUDE.md` at the roc-apps root and `docs/roc-style.md`: the rules.
2. `docs/smells.md`: Steve's smells, each with a real case. Read it right
   before you review or design, so the smells are fresh.
3. This file.

## The review job

You review one module, or a small family of them, named in your prompt. You change nothing.

### 1. Walk the types

From `canvas_apps` in the main checkout (`/home/steve/showell_repos/roc-apps`), with the widgets as clients so their uses count. The hook refuses a glob on the command line, so launch the walk from a script:

```
cd /home/steve/showell_repos/roc-apps/canvas_apps && shale <<'TAG'
local r = run({"shale", "cookbook:roc/type_walk.shale", "root=safari", "module=Tower",
  "clients=*_widget", "packages=lib=repos:roc-apps/canvas_apps/lib"}, {whole = 4000000, timeout_ms = 300000})
print(r.out)
TAG
```

Without `clients=`, a member only a widget uses looks unused, and making it private breaks the widget.

The walk prints the module's types and every type they depend on to depth 2,
the most primitive first, with no function bodies. Read it the way a newcomer
would, from the top. Types past depth 2 are named in one line and not
followed. Read their source only if a finding needs it. Judge a module's types
by what depth 2 shows: if a type only makes sense once you've read three levels
down, that's a finding, not a reason to go deeper.

The walk has more than the types (the recipe's header lists every setting):
- **Hub types:** `Shapes.Shape`, `Brush.*` and `World.Segment` are named once
  and not expanded. Pass `stop=` to change the list, as when World is the module
  you review.
- **Less detail at depth:** past depth 1, and for unit wrappers such as
  `Distance` at every depth, members show by name only.
- **Who uses each member:** each of the module's own members carries a
  count of the other files that use it, split into production and tests. A
  `# Public, but used only in this file` line names the private helpers
  wearing public names.
- **"Named by":** every signature and type in other modules that mentions the
  module's types, tagged `(test)` or `(private)`. This is where the wrappers and
  makers of a kind show up. `named_by=production` hides the tagged ones.
- **"Imported but not in any printed type":** modules the code uses only in
  function bodies, which the walk can't show. Read them.
- **"Imported for tests only":** imports used only by `expect`s and the
  top-level values only expects reach. Each one breaks Steve's rule and is a
  finding: its tests move to their topic's module in `gates/expects/` and the import goes.

### 2. Read the code behind what smells

The walk shows the surface. Open the source where a type, a name or a
signature smells, and check:

- **Who calls what.** The walk's use counts and "named by" cover most of it.
  grep for what they can't see, such as a caller that takes the type as an open
  record. A member of a type's `.{ }` block that nothing outside the file uses
  is a private helper wearing a public name.
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
- **Reach:** the files the fix touches. Mark any shared module (Geom, RiderView, Camera,
  Picture, Pipeline, RoadAhead, World, Segment, Route, Scene, anything in `lib`,
  `Distance`, `Along`, `Across`, `Fraction`, `Pixels`, `Angle`), and any widget
  that imports the module.
- **Pixels:** whether the fix should leave every pixel as it is, or would move
  some. Say which and why.
- **Call:** "clear" if the fix is plainly right, or "needs Steve" if it's a
  design question with real weight on both sides. Say what the two sides are.

End with the findings you considered and rejected, one line each, so they
aren't raised again.

Then say, in a line or two, how depth 2 felt for this module:
- **Noisy:** were types near the bottom of the walk ones you never needed?
- **Incomplete:** did a finding need a type past the cut, which you had to read
  in its source?

Name the types either way. The depth is a setting, and these answers are how
it gets tuned.

## The cleanup job

You make the fixes listed in your prompt, which the orchestrator has decided.
Make those fixes and nothing else. If you see something more, put it in your
report.

**Tests (Steve's rule):**
- A new test that needs nothing its module doesn't already import sits beside the code.
- A test that needs more goes in its topic's module in `gates/expects/` (RoadExpects, SightingExpects, SceneExpects, EncounterExpects, RideExpects or RiderExpects). A helper two of them need goes in `Fixtures.roc`, and no module there imports another but Fixtures. Never add an import only a test uses.
- Don't write a test that restates a constant or could never fail usefully. Roc's types already catch most of it.

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
cd /home/steve/showell_repos/lanes/<lane> && shale canvas_apps/safari/gates/fast.shale <<'TAG'
TAG
```

It runs `roc check`, the format check, the expects, the lints on changed
files, and one frame held to `gates/proof.expected`.

- **Speed:** about 10 seconds when warm. The first run in a new worktree builds
  its cache, which takes longer.
- **Widgets:** if you change something a widget imports, also run `roc check web.roc` in that widget's folder (`canvas_apps/<name>_widget`), with the
  pinned Roc: `/home/steve/tools/roc-nightly-2026-11-03-34bd006/roc`.
- **A change that moves the ride or any pixel:** run `shale canvas_apps/safari/gates/run.shale part=widgets` (every widget's `roc check`, then one `roc test` over all of them, about 35 seconds on a busy box). Several widgets hold numbers from a paused step of the real ride, such as the frame widget's shape counts at step 1570, so they break even when you didn't touch them.
- **Whole-tree lints:** before you report, also run `shale canvas_apps/safari/gates/lints.shale` from the worktree root (its header says how long it takes). fast.shale skips the lints that read across files (boundaries, families and others), and they catch what a lane's rename or new parameter does elsewhere.
- **The book:** also run `shale canvas_apps/safari/gates/run.shale part=tutorial`, about a second. It fails only if an include breaks. While the book is parked, its stale names and the rule that it names every module are skipped, loudly (they print SKIPPED with their counts).
- **The full gate is the orchestrator's.** Don't run `gates/run.shale`.
- **A lint you trip:** fix the code. Never loosen a lint or raise a held
  count.

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
- **Stale names and new modules:** leave them. No count is held while the
  book is parked (Steve: "a skip is actually more honest than churning
  counts"), and no module list needs a mention added. Name in your report any
  sentence your change makes plainly false, so it's logged for the rewrite.

### Report

Keep it short:
- the new or changed types, as annotations
- each fix, done or not, with the reason if not
- the fast.shale result
- whether pixels moved
- book sentences your change made plainly false
- anything you saw and left alone

## What tripped you up (every report, reviews and cleanups alike)

End every report with a short list of whatever cost you time that wasn't the task itself. The tools get fixed from these. For example:
- a Shale script refused, and what you meant (a missing builtin, a confusing error, a rule this brief didn't mention);
- the hook refusing a command you needed;
- a check that was slow, flaky, or failed for a reason unrelated to your change;
- a recipe that gave a wrong or confusing answer (type_walk, roc_commas, the lints);
- anything in this brief that was wrong, missing or unclear;
- another agent's files getting in your way.

Give each one a line: what you tried, what happened, and what you did instead. If nothing tripped you up, say "nothing".
