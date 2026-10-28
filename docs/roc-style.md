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
- **A length limit counts bytes** (`Str.count_utf8_bytes`), never graphemes.
  Limits exist to protect the disk; a convention about how long text should
  look is social, not technical.
- **Markup and CSS are multiline `\\` strings**, one `\\` per line. They need
  no `\"` escaping and keep `${…}` interpolation, so the literal reads as the
  page it makes. Leave a short single-line literal as it is
  ([strings](https://roc-lang.org/docs/main/langref/strings/#multiline-strings)).

  ```roc
  css =
      \\.links a { color: ${link}; }
      \\.links li { margin: 0 0 4px; }
  ```

## Failure is a `Try`

- **A function that can fail returns a `Try`, whose error tags say what went
  wrong.** That includes a three-way read: `Try(List(U8), [Missing, Failed])`
  keeps missing and failed apart, as the chat's `[Found, Missing, Failed]`
  did, and lets `?` and `??` work.
- **`crash`, with a reason, on the impossible; never a silent `?? default`.**
  A default for a case that can't happen hides the bug that makes it happen.
  The message names the function and why the case can't arise
  ([errors](https://roc-lang.org/docs/main/langref/errors/#when-to-crash)):

  ```roc
  Err(_) => crash "Html.fill: a template has more {s} slots than values"
  ```

  A case that *can* happen (user data, a file on disk, the end of a walk)
  keeps its handling: an error tag, not a crash.
- **Better still, let the pattern say it.** Match the shape you need
  (`[first, second, ..]`, a fixed-length list pattern) instead of indexing and
  defaulting; then there's no impossible case left to crash on.
- **A failed read of a cache is a miss; a failed read of the truth fails the
  request.** A cache (a count sidecar, a window into a file) can always be
  rebuilt from the truth, so its read answers `Try(_, [Miss])` and missing and
  failed are one answer. Give the cache read one home (`Files.read_cache!`),
  not a fallback at each call site.

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
- **Tags at the host boundary too.** A hosted effect answers a tag, not a
  Bool: `[Serving, NotServing]`, `[Member, Outsider]`, and `Try({}, [Failed])`
  for one that can only succeed or fail. A Bool across the seam is as easy to
  misread there as anywhere.
- **An ordering answers `[Before, Same, After]`**, fed straight to
  `List.sort_with`, not a signed number to compare against zero.
- **A function that does return a Bool is a question: `is_*` or `has_*`**
  (`is_valid_emoji`, `has_prefix`, `is_all_digits`), as the langref's
  `is_empty` is. A bare noun or adjective (`all_digits`) doesn't say which way
  `True` points.
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
- **Decode into the type at the door, once.** The function that reads a
  request, a file or a host answer turns it into `Uid`, `ConvKey`, `ChatPath`;
  nothing deeper takes the raw `Str` or bytes and decodes again.
- **A type's accessors are methods in its own block**, called as methods:
  `key.to_str()`, `key.partner(me)`, `page.bytes()`. A module call stays where
  the function is passed as a value (`map_ok(Uid.to_str)`) and for builders
  that make a value from parts rather than read one
  ([static dispatch](https://roc-lang.org/docs/main/langref/static-dispatch/)).
  A type made nominal (`:=`) rather than an alias can carry them.
- **JSON goes through one opaque builder** (`JsonOut :: List(U8)`, with
  `string`, `number`, `bool`, `array`, `object`, and `bytes` the only way
  out), never a string spliced by hand. Every field is then a whole, escaped
  value. Html is opaque the same way: a page is built only from escaped text
  and literal markup.

  ```roc
  JsonOut.object([("conv", JsonOut.string(conv)), ("id", JsonOut.number(id))])
  ```

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
- **One home for a rule.** A fact the program depends on (a limit, a check,
  how a cache is read) lives in one place, and every user asks that place. A
  second copy that must remember to agree is the bug waiting; where a copy
  has to exist on the far side of a seam, a test holds the two equal.

## Speed, layout, tests

- **A little speed traded for robustness is fine,** especially off hot loops.
- **`roc fmt` decides layout.** Ask for a vertical stack with a trailing comma:
  it keeps it, as `zig fmt` does.
- **Stack anything with three or more parts, one per line, with a trailing
  comma**: a list, a record, a tuple, a call's arguments, a tag's payload.
  Three things on one line are hard to scan, and `roc fmt` keeps the stack.
  A line over about 100 columns gets stacked too.

  ```roc
  JsonOut.object([
      ("conv", JsonOut.string(conv)),
      ("session", JsonOut.string(topic)),
      ("id", JsonOut.number(id)),
  ])
  ```

  That's `roc fmt`'s own shape: a call whose one argument is a stacked list
  keeps the bracket on the call's line.
- **Pure decisions live outside effects**, so `expect`s can reach them
  (`roc test chat/main.roc` runs every imported module's). Test each pure
  mapping, and the exact bytes each builder makes.
- **Build tests with `--opt=dev`.** `roc build` defaults to `--opt=speed`
  (LLVM): the chat took 5 min 21 s that way, 0.9 s on the dev backend.

## Recent, not yet settled

- **An effect is named for its act, never as a state or a noun.** A route
  handler is `serve_*!` for what it serves (`serve_topic_page!`); a lookup
  that can fail the request is `load_*!` (`load_viewer!`); anything else is a
  verb (`append_message!`, `fan_out!`, `check_member!`). `page!`,
  `appended!` or `member!` read as a value or a question, not a command. A
  port is where such names come from: it keeps the old function's noun or
  past tense, so rename on the way in.
- **A command is not named as a question.** An effect that does something
  and reports how it went (`serve_file!` answering `[Serving, NotServing]`)
  is named for the act, not for the state it checks (`held_raw!`).
- **Private helpers live outside the `X :: [].{ }` block.** Only what sits
  inside the block is exposed
  ([modules](https://roc-lang.org/docs/main/langref/modules/)), so the block
  is the module's public surface at a glance. A helper outside names a block
  member qualified (`Feeds.sep`); the module's own `expect`s call helpers
  bare.

  ```roc
  Util :: [].{
      public_fn : Str -> Str
      public_fn = |s| helper(s)
  }

  helper : Str -> Str
  ```
- **One damaged entry fails only itself.** Where a page or feed reads many
  entries (lines, rows, accounts), an entry that won't decode is left out and
  counted, not a failure of the whole request; a lookup of that entry itself
  still fails. One bad byte on disk must not be a lasting 500 for everyone.
