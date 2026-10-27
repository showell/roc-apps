# Roc, as Steve writes it

This style guide is as much about design as about style. Roc gives you
excellent tools for making code correct by construction: tag unions,
records, opaque types, `Try`. Using them is a discipline, though, and the
language won't apply it for you; this guide is that discipline, written down.

How Roc is written in this repository and its siblings (roc-webbox's chat,
dog-park's physics). These are Steve's preferences, and most carry over from
his Zig. Each one replaces a construct that can be wrong and still compile with
one that can't. The examples come from roc-webbox's chat (`chat/`), cleaned up
this way on branch `box/roc-cleanup`. How the compiler itself behaves is in
[roc-notes.md](roc-notes.md).

**Roc's own conventions** are in its language reference, the *langref*:
<https://roc-lang.org/docs/main/langref/> (source: `docs/langref/` in
roc-lang/roc; our pinned copy is `~/tools/roc-258ab27/docs/langref/`). It
covers the new compiler's syntax and is marked work in progress. It has no
separate style guide; its conventions sit in the pages, chiefly
[naming](https://roc-lang.org/docs/main/langref/naming/),
[errors](https://roc-lang.org/docs/main/langref/errors/),
[types](https://roc-lang.org/docs/main/langref/types/) and
[static dispatch](https://roc-lang.org/docs/main/langref/static-dispatch/).
Where this guide and the langref disagree, this guide is deliberate. The
chat was written against both of the rules below, and is being brought round
(Steve, 2026-10-27: "I agree with the official stance").

## Text is `Str` inside; bytes only at the door

- **Text is a `Str`.** Decode it to UTF-8 once, where it enters (a request, a
  file, a host answer), and refuse what isn't UTF-8. Past that point, work in
  `Str` with its helpers (`split_on`, `join_with`, ...); `List(U8)` is for
  parsing at the door, and for bytes that aren't text
  ([strings](https://roc-lang.org/docs/main/langref/strings/)).
- **The chat broke this everywhere:** URLs, titles and paths are glued from
  bytes (`List.concat(Str.to_utf8("/chat/c/"), key)`). Every stored chat file
  in production is UTF-8 (the v40 scan), so moving to `Str` needs no data
  migration.
- **Character literals** (`'_'`, `c - 'A' + 'a'`) are for the byte-level
  parsing at the door. A number left in the code should be an honest number (a
  minute, a length limit), not a byte in disguise.

## Failure is a `Try`

- **A function that can fail returns a `Try`, whose error tags say what went
  wrong.** That includes a three-way read: `Try(List(U8), [Missing, Failed])`
  keeps missing and failed apart, as the chat's `[Found, Missing, Failed]`
  did, and lets `?` and `??` work.

## Roc's conventions we have already broken

The langref says these too. They're repeated here because the chat breaks them.

- **A function that can fail returns a `Try`, not a Bool.** `Files.write!`,
  `remove!` and `append_line!` return `Bool`, "false when it failed": a caller
  can drop the failure and `?` can't pass it on.
  Use `Try({}, [WriteFailed])` and the like
  ([errors](https://roc-lang.org/docs/main/langref/errors/)).
- **An error tag names what went wrong.** The langref's `[ListWasEmpty]` says
  why. The chat's `Err(None)` (`Conversation.dm_other`, `Paths.cut_first`) says
  nothing, and two such errors look alike after a `?` joins them.
- **A nominal type derives `is_eq` with `is_eq : _`.** Write one by hand only
  when equality isn't structural. `Uid` hand-writes the structural one,
  `|Uid.(a), Uid.(b)| a == b`, which is more code to read and to get wrong
  ([compiler-derived methods](https://roc-lang.org/docs/main/langref/static-dispatch/#compiler-derived-methods)).

## Say which, with a tag

- **A tag union, not a Bool, a magic number, or a `"1"`/`"0"` string**, for any
  closed set. Pattern-match on it exhaustively.
- Naming the tags forces you to name the question. A Bool usually states one
  case of it, so rename the field when the tag reads wrong with it: `on : Bool`
  became `change : [Added, Removed]`, and `online : Bool` became
  `presence : [Online, Offline]`.
- **Use `match` where a chain tests one value** against constants, tags or
  ranges (`Html.escape`, the header names).
- **Leave an `if` chain alone when its branches test different things in
  turn.** A sequence of effects isn't a set of cases, and a `match` would hide
  that.

## Name what travels together

- **Neighbouring arguments of one type can be swapped and still type-check.**
  Pass a record, so the fields are named and order can't go wrong:
  `appended!(conv, who, draft)`, not four `List(U8)`s in a row.
- **A fundamental pair gets one record with concise comments on what each field
  is.** A topic's address is `TopicAt : { key, topic }`, and its comments say
  what a key and a topic look like, in URLs and on disk. Prefer a plain word
  (`topic`) over an abbreviation (`sid`).
- **No list read by position.** A `List(List(U8))` whose parts are known only by
  their index becomes a list of records.

## Make wrong values impossible to build

- **A nominal type where values of the same shape mean different things**:
  `Uid := List(U8)`. A name or a path passed where a uid belongs is then a type
  error.
- **An opaque type (`::`) for anything validated.** Only its own module can
  build one, so the validator is the only way in:
  - `ChatPath :: List(U8)`: only `Paths` makes a path;
  - `ChannelName`, made only by `channel_name`;
  - `PairKey`, made only by `pair_key`/`pair_key_of`.
- **Combine them into the domain's real shape:**
  `ConvKey : [Dm(PairKey), Channel(ChannelName)]`. Build it once, where bytes
  enter; past that point nothing takes raw bytes.
- **Syntax at the pinned nightly:**
  - declare: `X := T.{ ... }` (nominal) or `X :: T` (opaque);
  - wrap: `X.(v)`. Plain `X(v)` parses as a tag.
  - unwrap: the pattern `|X.(v)| v`;
  - compare: `==` needs an `is_eq` on the type; `is_eq : _` derives it.

## One workhorse at the edge

- **The disk is reached through one module.** `Files.roc` is the only caller of
  the host's file functions, and it keeps missing and failed apart: never one
  answer (as a `Try`'s two error tags).
- **A shale hunt** (`tools/roc_hunt/hunt.shale`, `fs_bypass`) flags any call
  that bypasses it. A rule a type can't express gets a hunt with plants (cases
  it must find and cases it must not).
- **Keep records small where they cross into the host.** Nothing checks a Roc
  record's layout against the host's extern struct, so a large one can drift
  and corrupt memory instead of failing. Use a list of small records, and make
  a bad name crash (a 500) rather than return `[]`.

## Speed, layout, tests

- **A little speed traded for robustness is fine,** especially off hot loops.
- **`roc fmt` decides layout.** Ask for a vertical stack with a trailing comma:
  it keeps it, as `zig fmt` does.
- **Pure decisions live outside effects**, so `expect`s can reach them
  (`roc test chat/main.roc` runs every imported module's). Test each pure
  mapping, and the exact bytes each builder makes.
- **Build tests with `--opt=dev`.** `roc build` defaults to `--opt=speed`
  (LLVM): the chat took 5 min 21 s that way, 0.9 s on the dev backend.
