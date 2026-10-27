# Roc, as Steve writes it

How Roc is written in this repository and its siblings (roc-webbox's chat,
dog-park's physics). These are Steve's preferences, and most carry over from
his Zig. Each one replaces a construct that can be wrong and still compile with
one that can't. The examples come from roc-webbox's chat (`chat/`), cleaned up
this way on branch `box/roc-cleanup`. How the compiler itself behaves is in
[roc-notes.md](roc-notes.md).

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
- **Character literals for bytes:** `'_'`, `'\n'`, `c - 'A' + 'a'`. They're
  `U8`, in patterns too. A number left in the code should be an honest number
  (a minute, a length limit), not a byte in disguise.

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
  - compare: `==` needs an `is_eq` defined on the type.

## One workhorse at the edge

- **The disk is reached through one module.** `Files.roc` is the only caller of
  the host's file functions, and it keeps `[Found, Missing, Failed]` apart:
  missing and failed are never one answer.
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
