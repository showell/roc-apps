# CLAUDE.md: working on Roc projects, the opinionated way

These are instructions for a coding agent working on Steve Howell's Roc
projects. They're written so other people can crib them for their own.

**The disclaimer, and we mean it.** Everything below is one person's set of
choices for his own codebases, made with an agent doing most of the typing.
Some of it is plain good practice that hardly anyone would argue with. A
fair amount is strong opinion, and a few parts only make sense with our
tools (Shale, our build box, a cloud agent working through a queue). None
of it is the Roc project's official advice, and Roc's own docs win
wherever they disagree with us. Take what fits, drop what doesn't, and
keep your own fork. Our scope is narrow on purpose: a rule goes in only
after our own code has broken it. And this file should evolve as quickly
as Roc itself does: when the compiler or our practice moves, the file
moves in the same change.

**What we assume you already know.** You've seen plenty of Roc in training,
but probably not the version we build with. Roc changes fast: syntax, the
builtins and the compiler's rules all move from one nightly to the next.
So don't teach yourself Roc from memory. Trust the compiler you're given,
read the code that's here, and when your memory and the pinned compiler
disagree, the compiler is right.

**How this file is laid out.** Each section names a problem you'll hit
working in Roc today, then gives our answer to it. The sections run
roughly from least to most opinionated, so the early ones should fit
almost any Roc project, and the later ones are where you're most likely to
fork. The style guide, [docs/roc-style.md](docs/roc-style.md), is the
companion to this file: this file says how we work, and the guide says how
the code should read.

**Contents:**

1. Your Roc knowledge is out of date
2. Roc is bleeding-edge: pin it, and doubt every nightly
3. Reading the compiler's verdict
4. Builds are slow by default
5. Formatting: `roc fmt` decides
6. Testing: frozen answers, planted faults, floors that only rise
7. Performance: know what copies
8. Docs and comments
9. Security habits for Roc services
10. The standard library is still growing: pragmatism and patience
11. Roc doesn't excel at every niche: hybrid architectures
12. Many ways to write the same thing: the style guide
13. Rules the type checker can't see: hunts and mechanical rewrites
14. Agents: the long builds are the orchestrator's

**The habits under all of it:**

- **Make a failure loud.** A check that can't run fails; it doesn't skip.
  A fallback nobody chose is a bug.
- **Prove the check can see.** A test, a lint or a judge counts only once
  a planted fault has turned it red.
- **Read the record, not your memory.** Check what the compiler, the test
  output or the git log actually says before you claim anything.
- **Keep history out of the code.** Comments say what holds and why, in
  the present tense. How it got that way goes in the commit message.

## 1. Your Roc knowledge is out of date

**The problem.** Most of the Roc you saw in training is the old compiler,
or an early version of the new one. The syntax, the builtins and the
compiler's rules have moved since, and they move again with most nightlies.
So you will write old forms with confidence: `\x ->` lambdas, `!` without
`=>`, `X(v)` to wrap a nominal or opaque value where the pin wants `X.(v)`
(a plain `X(v)` is a tag), a `module [...]` header where the
compiler now prefers a type module. Some of these fail to compile. Others
compile and mean something else.

**Our answer.** The pinned compiler and Roc's own docs are the authority,
and your memory isn't. Look a construct up, or ask the compiler, before you
write it. When your memory and the pin disagree, the pin is right.

- **Cite the langref; don't recall it.** Roc's conventions are in the
  language reference at roc-lang.org/docs/main/langref/, and a roc-lang/roc
  checkout carries it as `docs/langref/` (`functions.md`, `if-else.md`,
  `errors.md` and the rest), next to `docs/langref-style-guide.md`. Read
  the checkout at the pin's commit, not an older one you happen to have.
- **Read the pin's `Builtin.roc` before writing a helper.** It is
  `src/build/roc/Builtin.roc` in roc-lang/roc at the pin's commit (the hash
  at the end of the repo's `roc-version`). The toolchain release carries
  no source, so fetch just that commit: `git init roc-src && cd roc-src &&
  git fetch --depth 1 https://github.com/roc-lang/roc <hash> && git
  checkout FETCH_HEAD`. `docs/roc-style.md`, "`Str` and the builtins at
  the pin", lists helpers we wrote by hand that the builtins already had.
- **Know the forms training gets wrong, and where they're written down.**
  Effects (`=>` and a `!` name), record update (`{ ..r, f: v }`), `var $x`
  and `while`, no shadowing and list patterns are in `docs/roc-notes.md`,
  "The language". Declaring, wrapping and unwrapping nominal and opaque
  types is in `docs/roc-style.md`, "Syntax at the pinned nightly". Read
  them; this file doesn't repeat them.
- **Get the new compiler from roc-lang/nightlies.** roc-lang/roc's own
  releases page is the old compiler (`docs/roc-notes.md`, "The compiler").
- **When unsure whether something compiles, ask the compiler.** Write the
  form into a scratch file and run the pinned `roc check` on it. Once
  Roc's cache is warm it takes well under a second (the first check in a
  fresh sandbox takes several), which is cheaper than a guess that costs a
  build.
- **Read the warnings, too.** A deprecation warning is the compiler telling
  you what it prefers now (the pin warns "module header deprecated" and
  points to type modules). Follow the code that's already
  in the repo for which forms we use, and ask before migrating a pattern
  across a repo.

## 2. Roc is bleeding-edge: pin it, and doubt every nightly

**The problem.** Roc ships as nightlies (github.com/roc-lang/nightlies/releases,
or `gh release list --repo roc-lang/nightlies`), and each one can change the
syntax, the builtins, `roc glue`'s output and `roc fmt`'s layout. Some are
simply broken. A project built with whatever `roc` is on the PATH can break
when nothing in it changed, and two projects on one machine may need two
different compilers.

**Our answer.** Pin the compiler per repo, install pins side by side, and
refuse to build with anything else. Stay fairly current with Roc, but move
each pin lazily, as its own commit, and check each new nightly before
trusting it.

- **A repo names its compiler in one file, `roc-version`.** It holds a
  nightly's tag (roc-chat `roc-version`, roc-markdown `roc-version`), and
  every tool reads that file rather than keeping its own copy of the pin.
- **Pins live side by side at `~/tools/roc-<pin>/roc`; the PATH is never
  touched.** roc-chat `tools/get_roc.sh` downloads the pinned nightly there,
  checks that `roc version` names the pin, and does nothing if it's already
  installed.
- **The build refuses a mismatch.** roc-chat `build.zig` `rocCompiler` takes
  `-Droc=<path>`, then `~/tools/roc-<pin>/roc`, then `roc` on the PATH, and
  stops with an error if `roc version` isn't the pin. roc-markdown
  `build.zig` does the same. The scripts read the same file: `roc_at` in
  roc-chat `tools/verify.shale`, `pinned_roc` in roc-markdown
  `tools/verify.shale`, and roc-chat `tools/chat_glue.shale`.
- **A sandbox that can't reach roc-lang's releases uses ours.** The
  roc-apps GitHub release `toolchain-2026-10-30-0602c5f` carries the pinned nightly,
  repacked unmodified, plus `roc-ast`, each with its sha256. Check the hash
  before you untar it into `~/tools/`. That is the home of the user who
  builds: where git runs as root and builds run as another user, untar
  into the build user's `~/tools/`, because that's where `build.zig` looks,
  and point Shale's `tools` mount there.
- **Move pins lazily.** A project that's working keeps its pin until it
  next gets features. Dog Park stays on its older pin
  (`dog-park/roc/roc-version`), and roc-apps itself still uses an older
  scheme and an older nightly (`roc-nightly.txt`, README "The compiler").
- **A pin move is its own commit.** Change `roc-version`, then run the full
  verify and regenerate any ABI snapshot with `roc glue` (roc-chat
  `tools/chat_glue.shale`) to check the seam hasn't moved. If `roc fmt` now
  lays code out differently, the reformat goes with the pin move, never
  mixed with a change in behaviour (§5).
- **Before you debug the compiler, ask "is it already fixed?"** Try the
  nightlies between the pin and the newest. On the 2026-10-09 pin, Roc had
  "receiver extensions": a function in one module whose first parameter
  was another module's type also became a method on that type. So a trial
  rewrite of roc-chat's `ConvAccess` to `viewer.can_post(...)` dispatched
  to the very function being defined, and `roc check` crashed with a
  SIGSEGV. A few
  minutes of trying newer nightlies found the crash fixed on 10-10
  (roc-lang/roc#12194, `df2fd296aa`) and the rule removed on 10-28
  (#12630, `333f582d61`). The nightlies in between checked the code clean,
  which was the wrong answer.
- **A check that uses the compiler as its judge is only as good as the
  compiler's version.** Any rewrite or check that the compiler approved
  under an older pin may need checking again after a move.

## 3. Reading the compiler's verdict

**The problem.** The compiler's exit code doesn't mean what it seems to. A
clean program with one unused variable exits non-zero, and a program with a
type error still builds, then crashes when it reaches the bad line. Some
failures show up as a hang or as the wrong error message. An agent that
reads `$?` alone, or reads an error message's first words at face value,
reports the wrong thing.

**Our answer.** Read the report, not the exit code. Check from a root that
reaches everything you changed, know the few traps below, and when the
compiler itself misbehaves, reduce it to a program others can run. The full
list is `docs/roc-notes.md`, "The compiler".

- **Judge a build by the ✗ mark.** Each diagnostic heads with ✗ (an error)
  or ● (a warning), and the last line counts both ("1 error and 0
  warnings"). A warning alone exits 2. A type error still produces a
  binary, which dies with "runtime error" at the error's site while the
  rest of the program runs. Zero ✗ is the bar, whatever the exit code.
- **Check from a root that reaches your change.** `roc check` on an app or
  test root reports errors in every module it imports. A file nothing
  imports is checked only when you name it. After an edit, check the root
  that imports what you touched, and name any new file directly
  (`--main=<root>` resolves a module's dependencies from the app root).
- **Compile-time evaluation has no step limit** (roc-lang/roc#11334). A
  call whose arguments are all known at compile time runs during
  `roc check`, so a check can hang, or take as long as the program. An
  experiment from a constant seed ties the seed to a run-time value
  (`findings/roc-check-hang/`).
- **Keep scratch directories out of Roc's way.** Older nightlies deleted
  every `roc-*` directory in the system temp root when they ran. The pin
  doesn't (in `roc check`, `roc test` or a build), but don't name a
  scratch directory that way. Roc honours `TMPDIR`; give parallel builds
  their own.
- **"Overflowed its stack memory" means a SIGSEGV, not necessarily a deep
  recursion.** The default runtime prints it for any segfault, a read after
  free included. Look for the real cause before raising a stack size.
- **A compiler bug gets a reduced reproduction.** It goes in roc-apps
  `findings/<name>/`, with the smallest program that shows it and a
  `README.md` saying what it shows (`findings/roc-check-hang/` also keeps
  the upstream `ISSUE.md`). Before reducing, try the newer nightlies: it
  may be fixed already (see §2).

## 4. Builds are slow by default

**The problem.** `roc build` defaults to `--opt=speed`, which runs the code
through LLVM. That is the right choice for a release and the wrong one for
everything else. The chat app took 5 min 21 s to build that way and 0.9 s on
the dev backend. BASIC's LLVM build took 1,420 s where the dev backend
took 6 s. An agent that keeps the default waits minutes per iteration and
usually blames the program, or Roc, rather than the flag.

**Our answer.** Use the dev backend in every inner loop and LLVM only for a
release. Treat a slow loop as a bug to find, not a wait to sit through:
check the defaults first.

- **Build with `--opt=dev` while working.** That covers tests, checks,
  experiments and the fix loop (`docs/roc-style.md`, "Tools and builds").
  `roc check` takes no `--opt`.
- **Tie Roc's mode to the host's in the build script.** roc-chat
  `build.zig` has `rocOpt`, which picks `.dev` for a Debug build (every
  test) and `.speed` for a release, and passes it to each `roc build`
  through `appArchive`. roc-markdown's `build.zig` follows the same shape,
  and builds its playground's wasm with `.dev`.
- **Give compile time and run time as two numbers.** "The test took 90 s"
  hides which half was slow. More than about a second to compile a small
  app is suspicious. Check which backend ran before anything else;
  `roc check --timings` shows how long each compiler phase took.
- **Measure speed on the release build, never in the fix loop.** LLVM's
  code is much faster (2.7 times on BASIC's slowest program), and the dev
  backend's code is mostly stack moves, so a dev-build timing says little
  about the program (`docs/roc-notes.md`, "Speed and copying").
- **Roc's cache grows with every distinct compile.** `~/.cache/roc` is
  only a cache: a long run of trial compiles (a methods rewrite over a
  repo) can leave several gigabytes there and fill a sandbox's disk. Watch
  `df` during a long run and clear the cache after it.
- **A build that's still slow on dev is a finding.** Look for compile-time
  evaluation first (§3), then reduce it into `findings/` (roc-apps
  `findings/roc-compile-time-memory/` is one).

## 5. Formatting: `roc fmt` decides

**The problem.** Hand layout fights the formatter, and the formatter wins
on the next run, so hand-tuned spacing becomes noise in someone else's
diff. The formatter also changes between nightlies. The 2026-10-29 nightly
parenthesizes a one-line `if`'s condition, so `if n == 0 A else B` becomes
`if (n == 0) A else B`. Code formatted cleanly at one pin can fail
`roc fmt --check` at the next.

**Our answer.** `roc fmt` at the pin is the canonical layout. Shape what it
produces with trailing commas, check it in the gate, and expect a pin move
to bring its own format-only changes.

- **Run `roc fmt` and let its layout win.** The gate checks it: roc-chat
  `tools/verify.shale` runs `roc fmt --check app platform`, and
  roc-markdown `tools/verify.shale` runs it over `package`, `judge` and
  `playground`. Run the pinned `roc`, not one from PATH, because another
  nightly may format differently.
- **Use a trailing comma to get a stack.** `roc fmt` keeps a list, record,
  tuple or call's arguments one per line when the last item has a trailing
  comma, as `zig fmt` does. We stack anything with three or more parts, and
  any line over about 100 columns (`docs/roc-style.md`, "Layout and
  formatting").
- **An annotation's arguments can't be stacked.** `roc fmt` refuses the
  trailing comma there, so a signature with three or more arguments takes a
  record instead (`docs/roc-style.md`, "Name what travels together").
- **A pin move can bring a format-only diff. Keep it out of logic
  commits.** roc-chat's move to the 10-29 nightly (commit `b66de68`)
  reformatted 27 files for the `if` change above, and four planted faults'
  targets followed. Run `roc fmt` right after moving the pin, and commit
  the result with the pin move, apart from any change in behaviour.
- **Judge a pure reformat by machine code, not archive bytes.** Roc's
  procedure names hash the source layout, so a reformat changes the
  archive's bytes while the code stays the same. Shale's
  `cookbook/roc/same_code.shale` compares two builds instruction by
  instruction with those names masked.

## 6. Testing: frozen answers, planted faults, floors that only rise

**The problem.** A green run can mean nothing ran. A test can be rewritten
to agree with broken code, and a count can quietly measure something other
than what you think. None of that shows up in the word "passed".

**Our answer.** One command runs every check and prints what it ran. The
judges hold frozen answers, and an answer moves only when someone says so,
case by case. A planted fault proves, once, that a new test can see a
failure. Test counts have floors that only rise. A green is a claim: read
how many ran.

- **`expect`s sit beside the code.** Test each pure mapping and the exact
  bytes each builder makes; `roc test <app>.roc` runs every imported
  module's expects (`docs/roc-style.md`, "Testing and enforcement").
- **One command, one checklist.** roc-chat `tools/verify.shale` prints a
  line per check, `PASS` or `FAIL` with its numbers, and exits 0 only when
  every line passed. roc-markdown has its own `tools/verify.shale`. Run the
  verify, not a hand-picked subset, before you call a change sound.
- **Floors only rise.** verify holds the test counts to floors
  (`roc_floor`, `zig_floor`) and the end to end to an exact step count. A
  count below its floor fails, so a test that silently stopped running
  can't hide. Raise a floor when you add tests; never lower one to get a
  green.
- **`roc test` counts your path dependencies' expects too.** roc-chat's run
  includes roc-markdown's, so the total moves with the sibling checkout.
  verify counts only files under the repo's own root. Recent nightlies name
  a file by its path from where the run starts (`app/X.roc`, the sibling's
  `../roc-markdown/...`), older ones by its whole path, and verify reads
  both.
- **A plant is a one-time proof, not a permanent check.** When you add a
  test or a gate, plant the fault it should catch, see it go red at the
  right place (a red for any other reason is no proof), revert, and say so
  in the commit. Then let the test carry it: assert both sides of the
  condition, the bad case refused and a near-miss good case accepted, so a
  test that stopped seeing would fail on the good side or the bad.
- **A test asserts every side, not one thing.** We don't follow the "one
  assertion per test" habit. As a principle, a test checks both sides of a
  boolean, every tag of a union, and the values at, just under and just
  over a boundary (14, 15 and 16 against a cap of 15). Running
  every plant on every verify costs most of the run's time for a proof that
  only needed making once. A plant must still build: removing a variable's
  only use makes an unused-variable warning, which fails the build before
  the test runs, so keep every name in use. If no single fault turns the
  test red, the property is guarded twice: say so, and plant the guard
  that stands alone.
- **Frozen answers are the judge.** roc-markdown holds every corpus case's
  answers byte for byte (`TESTING.md`). `zig build judge -- --refreeze
  LABEL` rewrites one corpus and names each case that moved; re-freeze only
  for a deliberate change, and explain every moved case in the commit.
- **A private corpus never leaves its machine.** It's passed with `--also`,
  and the judge prints counts and failing case ids, never a case's text
  (roc-markdown `TESTING.md`, "The corpora").
- **Never rewrite a test to match broken code.** When a test and the code
  disagree, find out which one is wrong. Changing the answer is a
  re-freeze, and it needs a reason you can state per case.

## 7. Performance: know what copies

**The problem.** Roc writes into a list in place only when nothing else
refers to it, and nothing reports a copy: not the type checker, not the
compiler, not a warning at run time. A small, innocent-looking change can
turn an O(1) store into an O(n) one, and the program just gets slower.

**Our answer.** Know the shapes that copy, and when in doubt, measure the
shape of the cost, not one number. The list of shapes and the measurements
behind them live in roc-apps `docs/roc-notes.md`, "Speed and copying".
Read it before writing a loop that stores into a list or a record.

- **Six shapes copy; learn them from the notes.** The commonest is
  `List.set(l, i, v) ?? l`: the fallback names `l`, so every store copies.
  Write `?? crash("...")` instead. The others (`List.update` on a nested
  list, a value threaded down a recursion, a field taken out and written
  back in separate statements) are in the notes, with reproductions under
  `findings/` (`threaded-record-copy/`, `helper-arg-copy/`).
- **Append into an accumulator.** Build a list with `List.append` in an
  accumulator loop, not by concatenating onto a recursion or with
  `List.concat(acc, [x])`, which the notes measure at about 50 times
  slower.
- **To tell a copy from a write, hold the writes fixed and vary the
  size.** Flat time means in place; time linear in the size means a copy.
  One number says nothing. `tests/copycheck.sh` does exactly this: each
  probe runs a fixed number of writes into lists of growing size and
  prints `FLAT` or `LINEAR`.
- **When you find a new copying shape, add a probe.** Put it in
  `tests/copycheck.sh` beside the known ones, with its fix as a second
  probe that reads `FLAT`, and add the shape to the notes.
- **A record update copies the record around the field.** Keep a large,
  rarely written part behind a list of one or a `Box`, not inline (the
  notes, same section, say which suits what).

## 8. Docs and comments

**The problem.** Docs go stale the day the code moves, and nothing fails
when they do. Comments that narrate how the code got here ("used to",
"now", "after the fix") read as current facts long after they stop being
true. A comment that only restates the line under it is one more thing to
keep in step.

**Our answer.** Prose says what holds now, in the present tense. A comment
carries a why or it goes, and the history goes in the commit message. Each
kind of knowledge has one home, and a doc that names a path names a real
one.

- **Write in the present tense.** Say what the code does and why. How it
  came to be that way, and what it replaced, belongs in the commit message,
  where it is dated and attached to the change.
- **A comment carries a why, or it goes.** roc-chat `app/Store.roc`'s
  `append_audit!` says its failure is "the host's to log alone", because
  the audit is a record of what happened, not the request's work. That is
  a reason the code can't show; a restatement of the code is not.
- **A file's top comment says what the file is.** It opens with a short
  headline in caps, then what the file does, how to run it, and what it
  promises: roc-chat `tools/get_roc.sh` ("THE PINNED ROC, INSTALLED"),
  `app/Ascii.roc` ("ASCII BYTE CHECKS", and why roc-markdown keeps its own
  copy) and `tools/verify.shale` ("EVERY CHECK OF roc-chat, IN ONE RUN").
- **A README orients.** It says what the thing is, what to do before you
  build, and the pitfalls, with a status that is hedged and dated. See
  roc-chat `README.md`: "Status (2026-10-29)", "Before you build",
  "Pitfalls".
- **Each kind of knowledge has one home.** What the compiler does goes in
  `docs/roc-notes.md`, how the code should read goes in
  `docs/roc-style.md`, and a reduced reproduction goes in
  `findings/<name>/` with the program that shows it (roc-apps
  `findings/roc-check-hang/`). Point to these homes rather than copying
  them.
- **A path you cite must exist.** Check each backticked path before you
  commit a doc. If a doc is stale, fix it, or cut it down to a stub that
  says only what is still true.
- **Code never cites a task tracker's numbers or a review's finding codes.**
  "Fixes Q250" or "per R-7" means nothing to the next reader and rots when
  the tracker moves. State the rule itself, in words.

## 9. Security habits for Roc services

**The problem.** A Roc service sits behind a host that reads untrusted
bytes off the network and holds the secrets. Roc's purity rules out a
whole class of bugs, but not a wrong decision, an unbounded loop over
hostile input, or a secret written to a log. And the Roc can be the bug.

**Our answer.** Secrets stay in the host. Every cost is bounded by the
input, bytes become typed values at the door, and the host trusts the Roc
only as far as a short list allows. Each refusal is proven by a planted
fault, and nothing we write down or print carries a secret or private
text. (§11 covers the seam itself; this section is about what
crosses it.)

- **Secrets never cross the seam.** The Roc asks the host to `sign!` and
  `verify!`, and never holds the signing key. GitHub's client secret and
  token stay on the host side too (roc-chat `README.md`, "The model").
- **Bound the cost before doing the work.** roc-markdown charges every
  render step to a work budget sized by the message's length, and
  `Md.hostility` answers `Renderable` or `TooMuchFormatting` before you
  render, so a POST can refuse a message built to blow up
  (`package/Md.roc`; `README.md`, "A bounded cost").
- **Decode at the door into an opaque type.** Only its own module can
  build one, so the checks are the only way in (`docs/roc-style.md`, "Make
  wrong values impossible to build"). roc-chat `app/Principal.roc`'s ids
  are opaque and refuse 0. An `AuditCodec` entry is made only by its
  constructors or `decode`.
- **The host allowlists what the Roc may set.** roc-chat
  `host/call.zig` `allowed_headers` is `set-cookie`, `cache-control` and
  `location`. Any other name, or a CR, LF or NUL, is a 500, because it is
  the Roc's bug. The host owns `content-length` and `connection`.
- **Each refusal is a planted fault in verify.** A check that refuses
  something counts once a copy of the tree with that refusal removed goes
  red: roc-chat `tools/verify.shale` plants a forged session cookie, a
  revoked key that still works, and a cross-origin POST. roc-markdown's
  verify plants an image from another origin and a `javascript:` src.
- **An audit never holds a secret.** roc-chat `app/AuditCodec.roc` records
  public numbers and words only, never a token, hash, cookie, nonce, OAuth
  code or login.
- **Neither a judge nor an error page prints private text.** roc-markdown's
  judge prints counts and failing case ids, never a case's text, so it can
  judge real messages (`TESTING.md`). roc-chat's 500 after a Roc crash
  carries nothing of the request, and `host/crash_test.zig` sends a
  `secret-header-value` to prove it.

## 10. The standard library is still growing: pragmatism and patience

**The problem.** Roc's standard library is still being built. Some things
you'd expect aren't there yet, some are there under a different name than
you remember, and a few are missing on purpose. There's no package
ecosystem to fill the gaps either, so the urge is to write a helper, or a
shared package, the moment something is missing.

**Our answer.** Pragmatism and patience. Look in the pin's builtins first,
because the thing you want is often there. Where they really fall short,
write a small, documented module of our own, copy it between repos on
purpose rather than invent a shared package too early, and delete it once
the builtins catch up.

- **Read the pin's builtins before writing a helper.** They live in
  `src/build/roc/Builtin.roc` in the compiler's source at the pin. A helper
  the builtins already have is a second copy to keep right.
  `docs/roc-style.md`, "`Str` and the builtins at the pin", lists the ones
  our chat wrote by hand before finding them there.
- **Some gaps are by design.** `Str.len` isn't a number: it answers
  `LearnAboutStringsInRoc(...)`, because a string's length depends on what
  you count. Count bytes with `Str.count_utf8_bytes`, and test for none
  with `Str.is_empty`.
- **Where the builtins fall short, write one small module with one job.**
  `Ascii.roc` answers seven questions about one byte, plus two case maps,
  and is safe on UTF-8 by construction: every byte of a multi-byte
  character is 128 or above, and every check answers `Bool.False` for it.
- **Copy it on purpose, and say so in its header.** `Ascii.roc` lives in
  both roc-markdown (`package/Ascii.roc`) and roc-chat (`app/Ascii.roc`).
  Each header says the other repo keeps its own copy, on purpose, until a
  package both can share exists. Two copies we know about beat a shared
  package designed for one user.
- **Import a sibling package by path.** roc-chat's `app/main.roc` header
  names `md: "../../roc-markdown/package/main.roc"`, and the pinned Roc
  takes that for a local package. It is the simplest thing that works at
  this pin, and roc-chat's README ("Before you build") says so, along with
  what a pinned, fetched dependency would buy instead.
- **Delete our copy when the builtins catch up.** A pin move is the moment
  to check: read the new `Builtin.roc` for each helper we wrote by hand,
  and where one has landed, move the callers to it and delete ours in the
  same change.

## 11. Roc doesn't excel at every niche: hybrid architectures

**The problem.** Roc is a general purpose language, and it compiles to
wasm for the browser too, but it isn't the best tool for every job. Filling
a canvas, driving the DOM, holding sockets open and waiting on the network
are all awkward from Roc today, and forcing them into Roc costs more than
it buys.

**Our answer.** Build hybrids. Roc owns the decisions, and the host owns
the I/O and whatever needs its state or its secrets. In the browser the
host is JS, which draws what Roc answers. On a server it is Zig, which
runs the network under a Roc app. The seam between the two is the risky
part, so a machine checks it, not a reader.

- **In the browser, JS draws and Roc decides.** roc-apps `canvas_apps/`
  runs one set of Roc files two ways: natively on roc-ray
  (`<app>/main.roc`) and as a page (`<app>/web.roc`). The page's
  `web/canvas_app_runner.js` only keeps the input and paces the clock, and
  `web/shapewire.js` paints each frame. roc-apps `fasttrack/` and
  roc-markdown `playground/` (the package on a wasm32-freestanding host,
  `playground/platform/host.zig`) follow the same split.
- **On a server, Zig carries the network.** roc-chat's `host/` is a Zig
  server on `std.http` under a Roc app (`app/`, on `platform/`). One mutex,
  the turn, is held only while a request's Roc call runs. A body is read
  whole before the turn and the answer is written after it, and an SSE
  stream holds its own task outside it (roc-chat README, "The model").
- **A hosted function answers a fact, never a verdict.** The host keeps
  only what needs its secrets or its state: the Roc asks `sign!` and
  `verify!`, and never holds the key. The rules for this seam are in
  `docs/roc-style.md`, "The host boundary". Read that section before
  adding a hosted function.
- **Generate the other side of the seam; don't hand-write it.** Roc lays a
  record out in its own field order, not the source's. `glue/JsGlue.roc`
  is our `roc glue` generator for JavaScript: it writes the page's readers
  from the compiler's type table on every build, and its output is never
  checked in (`glue/README.md`).
- **Where the host mirrors a record by hand, check it against `roc glue`
  field by field.** A size assertion misses two same-sized fields swapped,
  and the host then silently reads the wrong one. roc-chat
  `host/seam/glue_test.zig` holds every record in `chat_abi.zig` to glue's
  snapshot (`host/seam/glue/`) at compile time, by name and offset, and
  every tag union tag by tag.
- **A wasm export must be named in the platform's `exports:`.** Otherwise
  it silently isn't one (`docs/roc-notes.md`, "The language"). See
  `canvas_apps/web/platform/main.roc` for a list that matches its host.
- **A Roc crash is a 500, not a dead server.** roc-chat
  `host/seam/sljmp.zig` jumps back to where the call began, and the
  request's arena goes with it. Planted crashes, one per way the Roc can
  die, prove it (`app/test/crash.roc`, `host/crash_test.zig`).
- **Let the host check the Roc's work.** In Dog Park
  (`dog-park/README.md`, "Changing the game in Roc"), the physics and the
  rules are Roc under a Zig server. `zig build walk-judge` checks every
  step against `src/play/walk_reference.zig`, a plain Zig reference that
  shares none of the Roc's code.

## 12. Many ways to write the same thing: the style guide

**The problem.** Roc is a very flexible language. A call can be a function
or a method, a step can be piped or nested, a choice can be a Bool or a
tag, and a type can be an alias, a nominal type or an opaque one. Each
form compiles, so agents drift between them, and the code reads as if
several people wrote it, because several did.

**Our answer.** One style guide, `docs/roc-style.md`, held in place by
Shale (§13). The guide is as much about design as about style:
each rule replaces a construct that can be wrong and still compile with
one that can't. This section only points into it. Read the guide itself
before writing Roc, and never restate its rules elsewhere. Where a repo
hasn't caught up with a rule, the guide says so beside the rule:
follow the repo's form in a small change, and move the repo onto the
rule as a change of its own.

- **Read its principles first.** Prefer a construct that can't be wrong;
  keep one home for a rule; a little speed traded for robustness is fine
  (`docs/roc-style.md`, "Principles").
- **A closed set is a tag union,** not a Bool, a magic number or a
  `"1"`/`"0"` string ("A closed set is a tag union").
- **A run of same-typed arguments takes a record.** Three or more
  arguments become a record, and so do two neighbours of one type, which
  could be swapped and still type-check ("Name what travels together").
- **Use an opaque type for anything validated,** so its validator is the
  only way in ("Make wrong values impossible to build").
- **Call a value's own functions as methods:** `messages.last()`, not
  `List.last(messages)`. The same section lists the five places a module
  call stays. Agents lean toward the module form, so expect to correct it.
- **A hosted effect answers a tag or a `Try`, never a Bool**
  ("The host boundary").
- **The guide moves with the code.** A style decision lands with its rule
  in `docs/roc-style.md` in the same change. A rule that lands later, or
  only in a commit message, is a rule the next agent never sees.
- **A rule goes in only after our own code broke it.** The guide is
  written from violations we've seen, not from a wish list, and its
  examples come from our code. That scope is narrow on purpose, so if you
  like it, fork it and grow your own from what your code breaks.

## 13. Rules the type checker can't see: hunts and mechanical rewrites

**The problem.** Many of the style guide's rules are invisible to `roc
check` and `roc fmt`: a vague name, a Bool that should be a tag, a call
nested three deep, three arguments on one line, a parameter every caller
fills with the same literal. A reviewer catches some, an agent writes the
rest back in, and a finding fixed by hand and left unchecked comes back.

**Our answer.** This section and the next are the most specific to Steve. We write these
checks in Shale (github.com/showell/shale), his scripting language, as
recipes in its `cookbook/roc/`. You don't need Shale for the idea, which
carries to any tool: read Roc with Roc's own parser, prove each check on
planted cases, and let the compiler judge any rewrite.

- **Read Roc with Roc's own parser, never a regex.** The recipes read the
  tree from `roc-ast`, so a comment or a string never counts and a broken
  annotation reads as Roc reads it (`cookbook/roc/README.md`,
  `name_hunt.shale`). roc-apps's toolchain release carries `roc-ast`.
- **Each check proves itself on plants.** A plant is a case the check must
  find, or must leave alone. `self_test=1` runs a recipe on its own
  (`cookbook/roc/plants/<recipe>/`), so the hunt itself is tested.
- **The compiler judges a rewrite.** A syntax tree can't know a type, so
  `methods.shale`, which turns `List.map(xs, f)` into `xs.map(f)`, keeps a
  file's rewrite only if `roc check` passes and `roc test`'s summary is
  unchanged. Any other error puts the file back. It runs the repo's own
  pin, read from `roc-version`, because method lookup has changed between
  nightlies.
- **The recipes.** `name_hunt` (awkward names, tense, container words),
  `errors` (an error alias, an optional tag), `boundaries` (a one-caller
  wrapper, a fixed parameter), `nest_depth`, `stack` (three or more on a
  line, or past 100 columns), `roc_commas` (trailing commas so `roc fmt`
  stacks long lines), `methods`, `same_code` (two builds the same machine
  code, the judge of a pure reformat) and `tree_patch`. Each is a recipe,
  not a builtin: copy one and change it for the job.
- **A finding is a question for a reader, not a verdict.** Each prints
  `path:line: check: why`. Fix it, or say why it stands. `boundaries`'
  `single` is a rule of thumb and never a gate.
- **A rule a script can check gets a check, and a gate runs it.**
  `docs/roc-style.md`, "Testing and enforcement", lists the hunts and which
  repo's gate runs each. roc-chat's verify holds its hunts at zero, each
  with a plant; where no gate runs one yet (roc-markdown's), run it by hand
  before a review.
- **For agents using Shale instead of the shell,** read Shale's
  `docs/SHALE-AGENTS.md`. That part is Steve's setup only.

## 14. Agents: the long builds are the orchestrator's

**The problem.** Roc's slow paths are slow: an LLVM release build, a full
gate, a cross-compile. A subagent or a cloud agent that waits on one burns
its time and holds up everyone waiting on its report.

**Our answer.** We work on Roc the way we work on any project with several
agents, and that process changes quickly, so this section says only what's
particular to Roc. The orchestrating session runs the long release builds,
cross-compiles and the long gates, detached, where it can. Between edits, a
subagent or cloud agent uses shortcuts that buy about 90% confidence fast:
the dev backend (§4), `roc check` from the right root (§3), the quick
tests, and a single targeted plant. When its task asks for the repo's
verify, it runs that too (on the dev backend it takes minutes, not hours),
and its report says what it ran and which shortcuts it took. Either way,
the orchestrator runs the full verify again before anything merges.
