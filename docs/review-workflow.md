# The review workflow

This workflow is specific to Steve's setup. It needs Shale (the `type_walk` recipe and the Shale-only shell) and the essay surface (`essay-repl-server`, with its comments). Another agent can run it once those are in place. The agents' own brief is `docs/type-review.md`, and this file is the orchestrator's side.

The process makes code right one module at a time, types first. Cold agents review and clean up in parallel. One orchestrator decides, merges and gates. Steve stays single-threaded, making only the calls that are his. It ran first on Safari, and it should carry over to roc-chat.

## The roles

**Review agent.** It reads the guides (`CLAUDE.md`, `docs/roc-style.md`, `docs/smells.md`), walks a module with `cookbook:roc/type_walk.shale` and reports findings. It changes nothing. Each finding gives what the smell is, the fix, its reach, whether pixels move, and whether the call is clear or needs Steve. The report ends with how the walk felt, noisy or incomplete, which is how the tool gets tuned.

**Cleanup agent.** It makes only the fixes the orchestrator decided, in a worktree of its own, and runs only the quick checks. It reports the new types, what it did and didn't do, the checks, whether pixels moved, and any book sentence it made plainly false.

**Orchestrator.**
- Keeps up to four agents busy on mostly disjoint code.
- Decides most findings itself.
- Writes the rest up for Steve.
- Merges lanes, batches the full gate, and updates the smells guide as trends appear.

**Steve.** Makes the calls that are a matter of design or taste, and eye-tests every change that moves pixels.

## The loop

1. **Review.** Pick modules whose reach doesn't overlap a running lane. Kinds and leaves go first, the shared substrate later. A review is read-only, so it can run beside anything.
2. **Decide.** For each finding, choose one of four:
   - **Clear:** goes in a cleanup lane.
   - **Needs Steve:** goes on the essay surface.
   - **Moves pixels:** waits for the eye-test note.
   - **Rejected:** dropped.

   Make the executive calls; the doctrines and the smells guide usually settle them.
3. **Clean up.** One lane per review, briefed with the decided fixes, the shared modules it may touch, and what to leave alone.
4. **Merge.** As lanes return, merge them, resolve conflicts, and run the full gate, batching two lanes when they return close together. Push only on green.
5. **Learn.** Add each new trend to `docs/smells.md` with a real case, and add each repeated miss to the brief's checks.

## Lanes and shared modules

- **Worktrees:** each lane is a worktree under `~/showell_repos/lanes/<lane>`, on its own branch. A lane goes when it merges. Each checkout's gate caches (a GB or so) sit under `~/build/roc-apps/safari-checkout-caches/`, and the next merge gate run in any checkout removes a removed worktree's.
- **Shared modules, one lane at a time:**
  - The shared modules are Geom, Pipeline, Picture, RoadAhead, World, Segment, Route, Scene, lib and the unit types.
  - The orchestrator gives each lane its shared modules by name, and only one lane at a time may touch a given one.
  - A fix that needs another lane's shared module waits.
- **Conflicts:** most are in `gates/CrossModuleExpects.roc` (imports and tests from two lanes) and in widgets two lanes touched. Keep both sides.
- **Shale lanes need their own mounts file:** copy `~/.config/shale/mounts` with `cookbook` pointed at the lane, and run through `SHALE_MOUNTS`. Without it, `cookbook:` resolves to master's plants. Don't print that file: it names the secrets folder. Delete it when the lane goes.

## Checks

Cleanup agents run the quick tier, about a minute in all:
- `gates/fast.shale` (`roc check`, the format check, the expects, the lints on changed files, one held frame)
- `gates/lints.shale` (the whole-tree lints, which fast.shale skips)
- `run.shale part=proof` (every held frame)
- `part=tutorial` and `part=book_names`
- `roc check` in every widget the change reaches
- for apps other than Safari, `roc check` only: that's Steve's bar for them

The orchestrator runs the full gate (`gates/run.shale`, about two minutes) before every push.

Things the quick tier has missed, which the brief now covers:
- **Whole-tree lints:** a new parameter that's always the same value, or a field name clashing with a unit type elsewhere.
- **Import cycles:** a type the kinds can see can't name anything that depends on World.

`part=page`'s `drawn` hash covers every canvas call and its arguments, not pixels. When it moves, build master's page into a scratch `OUT=` and compare `shot.png` byte for byte. Never build into the dev channel.

## Decisions for Steve

- **On the essay surface, never the console.** With four agents reporting, the console is too noisy. Each decision or group of decisions is a `notes/<slug>.md`, with the facts, the options and a recommendation on each item.
- **Repeat the link.** Repeat its URL at the end of every reply until Steve says he's reading it.
- **Replies are comments.** They live in `essay-repl-server/data/comments/notes/<slug>.md.comments.json`, one per paragraph, not in the note or in git.
- **Record his answers.** Add them to the note under "Steve's answer" and carry them into the lanes.
- **One at a time.** Hold agent reports until he's ready, and hand him one note at a time.
- **Pixel changes wait for one eye-test note,** with before and after renders. Steve tests carefully, so batch them rather than asking piecemeal.

## The book while it's parked

The tutorial is rewritten later, so lanes never rewrite prose.
- **Includes:** a lane points a broken include at the new name.
- **Stale names:** while the book is parked, no count is held. The gate prints the stale names and the unnamed modules as SKIPPED, because a held count only tracked how broken the parked prose was (Steve: "a skip is actually more honest than churning counts").
- **The log:** the orchestrator logs the sentences each lane made false in `essay-repl-server/notes/book-parked-sentences.md`.

## The type walk

`cookbook:roc/type_walk.shale` grows as reviewers ask; "a bit of feature-itis" is fine. Run it with `module=<Name>` from the app's folder. It prints:
- the type closure, with less detail at depth;
- a stop list for hub types;
- per-member use counts, with receivers typed where the code says, and operators counted;
- a "Public, but used only in this file" line;
- "named by", the signatures elsewhere that mention the module's types, marked test or private;
- the imports used only in bodies.

A package such as lib is walked with its apps as clients, from `canvas_apps`: `root=lib module=Brush clients=*`. Without clients, a package's members look unused.

The recipe's header lists every setting.
