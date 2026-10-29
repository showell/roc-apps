# Roc, as Steve writes it

This style guide is as much about design as about style. Roc gives you
excellent tools for making code correct by construction: tag unions,
records, opaque types, `Try`. Using them is a discipline, though, and the
language won't apply it for you; this guide is that discipline, written down.

These are Steve's preferences for Roc in this repository and its siblings
(roc-webbox's chat, dog-park's physics), and most carry over from his Zig.
Each one replaces a construct that can be wrong and still compile with one
that can't. Examples are drawn mostly from roc-webbox's chat (`chat/`), but
the rules are for any Roc. The guide is written for Claude, which writes
this code, so a rule is added where our own code taught it. How the
compiler itself behaves is in
[roc-notes.md](roc-notes.md).

**Roc's own conventions** are in its language reference, the *langref*:
<https://roc-lang.org/docs/main/langref/> (source: `docs/langref/` in
roc-lang/roc; our pinned copy is `~/tools/roc-258ab27/docs/langref/`). It
covers the new compiler's syntax and is marked work in progress. Roc has no
style guide for code (roc-lang/roc's `docs/langref-style-guide.md` is about
writing the langref's prose, not Roc), and `roc fmt` settles layout with no
options. Its conventions sit in the langref's pages, chiefly
[naming](https://roc-lang.org/docs/main/langref/naming/),
[errors](https://roc-lang.org/docs/main/langref/errors/),
[types](https://roc-lang.org/docs/main/langref/types/) and
[static dispatch](https://roc-lang.org/docs/main/langref/static-dispatch/).
This guide follows the langref; where it goes further, it is deliberate.

**How to read it:** each rule is a bold line, then why, then an example where
one helps.

**Three tools hold these rules, in order:** Roc's type checker (the rules
written as types), `roc fmt` (layout), and
[Shale](https://github.com/showell/shale), a small sandboxed scripting
language we use for code tooling. Every rule here that neither of the first
two can see, such as names, Bools that should be tags, stacking, magic
numbers, or a file read that bypasses its module, is a Shale hunt. See
[enforcement](#testing-and-enforcement).

## Contents

1. [Principles](#principles)
2. [Naming](#naming)
3. [Types and data](#types-and-data): tags, records, nominal and opaque types,
   decoding at the door
4. [Text and bytes](#text-and-bytes)
5. [Errors and failure](#errors-and-failure)
6. [Effects and purity](#effects-and-purity)
7. [Modules and visibility](#modules-and-visibility)
8. [The host boundary](#the-host-boundary)
9. [Layout and formatting](#layout-and-formatting)
10. [Testing and enforcement](#testing-and-enforcement)
11. [Tools and builds](#tools-and-builds)

## Principles

- **Prefer a construct that can't be wrong to one that can be wrong and still
  compile.** Every rule below is an instance of this.
- **One home for a rule.** A fact the program depends on (a limit, a check,
  how a cache is read) lives in one place, and every user asks that place. A
  second copy that must remember to agree is the bug waiting; where a copy
  has to exist on the far side of a seam, a test holds the two equal.
- **A little speed traded for robustness is fine,** especially off hot loops.

## Naming

Roc's own rules are in the langref's
[naming](https://roc-lang.org/docs/main/langref/naming/) page.

- **A function that returns a Bool is a question: `is_*` or `has_*`.**
  A bare noun or adjective (`all_digits`) doesn't say which way `True` points.
  Examples: `is_valid_emoji`, `has_prefix`, `is_all_digits`, the langref's
  `is_empty`.
- **A function is named for what it does,** so a reader can predict it
  without opening it; what the caller wants it for stays in the caller.
  Search's `conv_at(scope, at)` answers the conversation at a place, and
  crashes past the end; as `in_scope` it read as a question.
- **Prefer a plain word to an abbreviation.** `topic`, not `sid`.
- **A type is named for what it holds, not where it sits.** `Entry`, `Item`,
  `Node`, `Data` and `Info` say only that a value is in a list or a tree;
  the domain usually has the word. One DM's row in the conversations JSON is
  a `DmSummary`, not an `Entry`. Where the container word *is* the domain's
  (a folder listing's entry), it stays.
- **An effect is named for its act, never as a state or a noun.** `page!`, `appended!` or `member!` read as a value or a question,
  not a command. A route handler is `serve_*!` for what it serves
  (`serve_topic_page!`); a lookup that can fail the request is `load_*!`
  (`load_viewer!`); anything else is a verb (`append_message!`, `fan_out!`,
  `check_member!`). A port is where bad names come from: it keeps the old
  function's noun or past tense, so rename on the way in.
- **A command is not named as a question.** An effect that
  does something and reports how it went is named for the act, not for the
  state it checks: `serve_file!` answering `[Serving, NotServing]`, not
  `held_raw!`.
- **When a Bool becomes a tag, rename the field to the question.** See
  [tags](#a-closed-set-is-a-tag-union).
- **Name a tag for what it is: a command, an event, or a state.** A tag that
  tells someone what to do is an imperative verb; a tag that reports what
  happened is past tense; a tag that says what is (a state, an answer) is a
  noun or an adjective. The reader can then tell an instruction from a fact
  at a glance, and a tag passed *in* as an instruction doesn't read like
  something that has already happened.

  ```roc
  # A command, passed in:
  Edit : [Pin, Unpin]

  # An event, stored and replayed:
  Change : [Added, Removed]

  # A state:
  Presence : [Online, Offline]
  ```

  A domain's own words for a state stay as they are, even in a command's
  union: an HTTP answer's `NotFound` beside `Redirect` is the protocol's
  name, not a slip.

## Types and data

### A closed set is a tag union

- **Use a tag union, not a Bool, a magic number, or a `"1"`/`"0"` string, for
  any closed set; match on it exhaustively.** A tag says which case it is; a
  Bool or a number has to be remembered
  ([tag unions](https://roc-lang.org/docs/main/langref/tag-unions/)).
- **Naming the tags forces you to name the question.** A Bool usually states
  one case of it, so rename the field when the tag reads wrong with it:
  `on : Bool` becomes `change : [Added, Removed]`; `online : Bool` becomes
  `presence : [Online, Offline]`.
- **An ordering answers `[Before, Same, After]`**, fed straight to
  `List.sort_with`, not a signed number to compare against zero.
- **Use `match` where a chain tests one value** against constants, tags or
  ranges. It reads as the set of cases it is, and the compiler checks it's
  complete ([pattern matching](https://roc-lang.org/docs/main/langref/pattern-matching/)).
- **Leave an `if` chain alone when its branches test different things in
  turn.** A sequence of effects isn't a set of cases, and a `match` would hide
  that.
- **Match the shape you need instead of indexing and defaulting.** A list
  pattern (`[first, second, ..]`) leaves no impossible case to crash on. See
  also [crash on the impossible](#errors-and-failure).

### Name what travels together

- **A function with three or more arguments takes a record.** This is
  **Steve's preference**, and `roc fmt` is why. A signature can't be stacked:
  `roc fmt` refuses a trailing comma in a type annotation, so
  `serve_topic! : Chat.Request, Route.R, Paths.TopicAt, Chat.Conv, Who => Chat.Answer`
  stays one long line however it's written. A record stacks (it's a value),
  names every argument where it's passed, and can't be called with two
  swapped. So two arguments stay as they are; three or more become one record
  argument, or two arguments where one is a record of the rest.

  ```roc
  serve_topic! : {
  	req : Chat.Request,
  	route : Route.R,
  	at : Paths.TopicAt,
  	conv : Chat.Conv,
  	who : Who,
  } => Chat.Answer
  ```

  The chat takes the second form: the subject first, the rest a record,
  so a call reads as an act on its subject with its options named:
  `Bytes.count_while(line, { keep: Ascii.is_digit, at: 0 })`. A loop's
  index and accumulator are fields too (`{ at: i, out }`), a one-letter
  parameter given a field's name and keeping its own in the body. A
  hosted effect's record is a seam record: its mirror on the host's side
  is laid out as Roc lays it out (numbers by name, then lists by name,
  then the small fields), asserted, and driven field by field.

  The stack hunt flags a signature with three or more arguments
  ([enforcement](#testing-and-enforcement)).
- **A parameter every caller passes the same value is no parameter.** A
  recursion's start (`at: 0`, `kept: 0`) belongs to an entry function that
  takes only what varies, and the `_from` worker it calls is the one place
  the index is passed: `Bytes.find(s, { needle })` calls
  `find_from(s, { needle, at: 0 })`, as `quotes` calls `quotes_from`.
- **Neighbouring arguments of one type get a record**, even when there are
  only two of them: they can be swapped and still type-check, and a record
  names the fields, so order can't go wrong: `appended!(conv, who, draft)`,
  not four `Str`s in a row
  ([records](https://roc-lang.org/docs/main/langref/records/)).
- **A fundamental pair is one record, with a concise comment on each field.**
  A topic's address is `TopicAt : { key, topic }`, and its comments say what a
  key and a topic look like, in URLs and on disk.
- **No list read by position.** A list of lists whose parts are known only by
  their index becomes a list of records.

### Make wrong values impossible to build

- **Use a nominal type (`:=`) where values of the same shape mean different
  things.** A name passed where an id belongs is then a type error
  ([types](https://roc-lang.org/docs/main/langref/types/)).
- **Use an opaque type (`::`) for anything validated.** Only its own module
  can build one, so the validator is the only way in. In the chat: `Uid`
  (made only by `Uid.from_str`), `ChatPath` (only `Paths` makes a path),
  `ChannelName` (only `channel_name`), `PairKey` (only `pair_key`).

  ```roc
  Uid :: Str.{
  	from_str : Str -> Try(Uid, [NotAUid])
  	from_str = |text| if is_all_digits(text) Ok(Uid.(text)) else Err(NotAUid)

  	to_str : Uid -> Str
  	to_str = |Uid.(s)| s

  	is_eq : _
  }
  ```
- **Combine them into the domain's real shape:**
  `ConvKey : [Dm(PairKey), Channel(ChannelName)]`.
- **A state machine is an opaque type whose module owns the transitions.**
  Each state is a value only the module can build, and each transition is a
  function from one state to the next, so a caller can't make a state by
  hand or skip a step. What a state claims (a search found this place) is
  then true by construction, not by each caller's care. A two-state tag used
  inside one function needs none of this; a state that crosses functions or
  modules does. In the chat, a scan remembers where its next `>` is across
  many openers:

  ```roc
  Seen :: [Unknown, At(U64), Never].{

  	## No search made yet: where every scan starts.
  	unknown : Seen
  	unknown = Seen.(Unknown)
  }

  ## The only transition: a search, or the answer an earlier one found.
  find_seen : List(U8), { byte : U8, from : U64, seen : Seen } -> (Try(U64, [NotFound]), Seen)
  ```

  A caller holds a `Seen` and passes it on; it can't write `At(40)` itself.
- **Decode into the type at the door, once.** The function that reads a
  request, a file or a host answer turns it into `Uid`, `ConvKey`, `ChatPath`;
  nothing deeper takes the raw `Str` or bytes and decodes again.
- **A nominal or opaque type derives `is_eq` with `is_eq : _`.** Write one by
  hand only when equality isn't structural; a hand-written structural one is
  more code to read and to get wrong
  ([compiler-derived methods](https://roc-lang.org/docs/main/langref/static-dispatch/#compiler-derived-methods)).
- **A type's accessors are methods in its own block, called as methods:**
  `key.to_str()`, `key.partner(me)`, `path.bytes()`. Keep a module call where
  the function is passed as a value (`map_ok(Uid.to_str)`) and for builders
  that make a value from parts rather than read one
  ([static dispatch](https://roc-lang.org/docs/main/langref/static-dispatch/)).
  Only a nominal or opaque type can carry methods, not an alias.
- **Structured output goes through one opaque builder, never a string spliced
  by hand.** JSON is `JsonOut :: List(U8)`, with `string`, `number`, `bool`,
  `array`, `object`, and `bytes` the only way out, so every field is a whole,
  escaped value. Html is opaque the same way: a page is built only from
  escaped text and literal markup.

  ```roc
  JsonOut.object([("conv", JsonOut.string(conv)), ("id", JsonOut.number(id))])
  ```

### Syntax at the pinned nightly

- declare: `X := T.{ ... }` (nominal) or `X :: T.{ ... }` (opaque);
- wrap: `X.(v)`. Plain `X(v)` parses as a tag;
- unwrap: the pattern `|X.(v)| v`;
- compare: `==` needs an `is_eq` on the type; `is_eq : _` derives it.

## Text and bytes

- **Text is a `Str`; bytes exist only at the door.** Decode to UTF-8 once,
  where text enters (a request, a file, a host answer). Past that point, work
  in `Str` with its helpers (`split_on`, `join_with`, interpolation);
  `List(U8)` is for parsing at the door, and for bytes that aren't text
  ([strings](https://roc-lang.org/docs/main/langref/strings/)).

  ```roc
  ChatPath.("${conv_dir(at.key)}/sessions/${at.topic}.reactions.jsonl")
  ```
- **Build text by interpolation:** `"${base}/${topic}"`, not a chain of
  `Str.concat` calls or a byte list joined by hand. The template reads as the
  result. Only a `Str` goes in a slot, so convert at the slot:
  `"${count.to_str()} messages"`. A long template is a multiline string (see
  below). Joining a list of pieces is `Str.join_with(pieces, sep)`, a
  function, not a method on the list at the pin. `Str.concat` is for a fold
  that builds text piece by piece.
- **An element with attributes is built by `Html.tag`; a value never
  reaches an attribute through a template.** `Html.tag({ name, attrs,
  inner })` puts every attribute value through `escape`, so no caller can
  forget it, and its names are code (lowercase letters, digits, `-`; else a
  crash). A trusted literal that leaves a quote open for a value to follow
  (`Html.trusted("<a href=\"")`) is a hunt finding. A template's slots
  (`Html.fill`) hold text between elements, never inside a tag.

  ```roc
  Html.tag({ name: "a", attrs: [Attr("href", href)], inner: Html.text(label) })
  ```
- **Join bytes only where bytes are the point:** inside an opaque builder
  (`Html`, `JsonOut`) or a decoder at the door, with `List.join`. Text past
  the door stays `Str`.
- **Refuse what isn't UTF-8.** A single read of text that isn't UTF-8 fails
  (`Try(Str, [Missing, Failed, NotUtf8])`). Inside a collection, the
  [damaged-entry rule](#errors-and-failure) applies instead:
  the entry is skipped and counted.
- **Character literals (`'_'`, `c - 'A' + 'a'`) are for the byte-level
  parsing at the door.** A number left in the code should be an honest number
  (a minute, a length limit), not a byte in disguise.
- **A length limit counts bytes (`Str.count_utf8_bytes`), never graphemes.**
  Limits exist to protect the disk; how long text should look is a social
  convention, not a technical one.
- **Markup and CSS are multiline `\\` strings, one `\\` per line.** They need
  no `\"` escaping and keep `${…}` interpolation, so the literal reads as the
  page it makes. Leave a short single-line literal as it is
  ([multiline strings](https://roc-lang.org/docs/main/langref/strings/#multiline-strings)).

  ```roc
  css =
  	\\.links a { color: ${link}; }
  	\\.links li { margin: 0 0 4px; }
  ```

### `Str` and the builtins at the pin

- **Read the pin's `Builtin.roc` before writing a helper.** A helper the
  builtins already have is a second copy to keep right. The chat had
  written, by hand: `List.split_on` and `split_on_list` (std.mem's
  splits), `List.split_first` and `split_last` (they answer
  `{ before, after }`), `List.starts_with` and `ends_with`, `List.map_try`
  (all or none), `List.append_if_ok`, `List.join_map`, `List.chunks_of`
  (fixed-size records), `I64.div_floor_by` and `I64.mod_by` (Zig's
  `@divFloor` and `@mod`), `U64.min`, `max` and `minus_saturated`,
  `Str.with_ascii_lowercased` and `Str.replace_each`. A fold can be one
  too: a fold whose accumulator only says whether it has found something
  yet is `List.find_first` or `find_last`, one that keeps the larger is
  `List.max`, and one that stops early is `List.fold_until`. `Json.to_str` of a
  `Str` is Zig's `std.json` string byte for byte; of a record it sorts the
  fields, so an ordered object is built, not encoded.
- **`Str.len` is no number.** It answers `LearnAboutStringsInRoc(...)`.
  Count bytes with `Str.count_utf8_bytes`; test for none with
  `Str.is_empty`.
- **`Str.trim` is Unicode's.** It takes a no-break space and an em space
  off too (`"\u(a0)x".trim() == "x"`). Where the format's spaces are ASCII
  (the Zig's `std.mem.trim(u8, s, " \t\r\n")`), trim the bytes in that set,
  and say why beside the helper.
- **`U64.from_str` is lenient:** it reads `+1`, `1_000`, `0x10` and `1e3`.
  A number at the door is strict: all digits, then `U64.from_int_digits`
  of the digits' values.
- **`Str.from_utf8_lossy` gives one U+FFFD per bad run of bytes.** A writer
  that must match another byte for byte (one per byte) keeps its own, and
  says so.
- **A byte's class has one home** (the chat's `Ascii`: `is_digit`,
  `is_alphabetic`, `is_whitespace`, `to_lower` and the rest), asked one
  byte at a time of UTF-8 bytes, which never splits a character. A format
  with its own set (markdown's five spaces, JSON's four) names it beside
  its parser, saying how it differs, rather than borrowing a near one.

## Errors and failure

The langref's [errors](https://roc-lang.org/docs/main/langref/errors/) page
is the base; these rules sharpen it.

- **A function that can fail returns a `Try`, never a Bool.** A Bool
  ("false when it failed") lets a caller drop the failure, and `?` can't pass
  it on. An effect that can only succeed or fail answers `Try({}, [Failed])`.

  ```roc
  write! : ChatPath, List(U8) => Try({}, [Failed])
  ```
- **Its error tags say what went wrong.** The langref's `[ListWasEmpty]` says
  why; an `Err(None)` says nothing, and two such errors look alike after a `?`
  joins them.
- **No optionals: a value that may be absent is tagged by what it is, and
  its absence by why.** `[Some(x), None]`, `Nothing`, and `Try(x, [None])`
  make every caller remember what "none" meant. A topic's last message is
  `[Latest(Message), NoMessage]`; the editor's open doc is
  `[NoneChosen, Doc(...)]`. The same holds for a fold's "nothing found yet"
  (`[Newest(...), NoDocs]`).
- **A `Try`'s error lists the tags that function can return, in place; no
  shared error alias.** `Accounts.name` fails only with
  `[NameUnreadable(Uid)]` and `admits` only with `[KindUnreadable(Uid)]`;
  one alias of both made every caller of each handle a tag that can't
  happen. An output union is open to its callers, so the narrow list still
  meets a handler that takes the wide one (`Members.fail_unreadable!`), and
  the checker holds the body to the list. An alias is for a handler's
  input. Leaving the error to inference (`_`) is fine too.
- **Keep distinct failures apart in the tags.** A read answers
  `Try(Str, [Missing, Failed])`: missing and failed are different answers,
  and as a `Try` they still work with `?` and `??`.
- **`crash`, with a reason, on the impossible; never a silent `?? default`.**
  A default for a case that can't happen hides the bug that makes it happen.
  The message names the function and why the case can't arise
  ([when to crash](https://roc-lang.org/docs/main/langref/errors/#when-to-crash)).

  ```roc
  Err(_) => crash "Html.fill: a template has more {s} slots than values"
  ```
- **A case that *can* happen keeps its handling: an error tag, not a crash.**
  User data, a file on disk, the end of a walk.
- **A failed read of a cache is a miss; a failed read of the truth fails the
  request.** A cache (a count sidecar, a window into a file) can always be
  rebuilt from the truth, so its read answers `Try(_, [Miss])`, with missing
  and failed as one answer. Give the cache read one home
  (`Files.read_cache!`), not a fallback at each call site. **A failed write
  of a cache is a miss too**: the next read recounts, so the write
  (`Files.write_cache!`) answers nothing and the host logs its failure;
  never fail a request whose truth is already written (a send whose message
  is stored) over its cache.
- **One damaged entry fails only itself.** Where a page or
  feed reads many entries (lines, rows, accounts), an entry that won't decode
  is left out and counted, not a failure of the whole request; a lookup of
  that entry itself still fails. One bad byte on disk must not be a lasting
  500 for everyone.

## Effects and purity

- **Pure decisions live outside effects,** so `expect`s can reach them. An
  effect gathers input, calls a pure function for the decision, and acts on
  its answer. See [testing](#testing-and-enforcement).
- **Effects are named for their act.** See [naming](#naming).
- **Best-effort work runs in an aside, and gives back what it could not
  spend.** Work the request does not stand on (a broadcast, a welcome)
  runs between `Host.aside!(Begin)` and `Host.aside!(End)`: a read that
  fails there fails the aside, never the request. Whatever the work was
  owed is handed back to the host when it did not happen, so it is tried
  again later rather than lost.

  ```roc
  _ = Host.aside!(Begin)
  told = came_online!(who)
  match (Host.aside!(End).status, told) {
  	(Done, Ok({})) => {}
  	_ => Host.presence_unspent!({})
  }
  ```
- **A failure that must not fail the request travels by an aside, not by
  each primitive.** The primitives fail the same way everywhere (the
  request, or the aside around them); `End` answers the aside's `fault`,
  the host's error as a number the Roc carries and never reads, for the
  counter that says it. Asides nest, so a step that must not fail the
  aside around it (one member's feed, inside the welcome's message) gets
  its own. Example: the fan-out's feed entry, each in an aside, its fault
  handed to `report_fanout_failure!`.

  ```roc
  ended = Host.aside!(End)
  match ended.status {
  	Done => Host.publish!(f.key.bytes(), f.event)
  	Failed => Host.report_fanout_failure!(f.surface, { member: f.member, key, sid, fault: ended.fault })
  }
  ```

## Modules and visibility

- **Private helpers live outside the `X :: [].{ }` block**. Only what sits
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
- **A resource is reached through one module.** In the chat, `Files.roc` is
  the only caller of the host's file functions, and it keeps missing and
  failed apart as a `Try`'s two error tags. Every other module asks it; a
  [hunt](#testing-and-enforcement) flags any call that bypasses it.
- **A flow is read in one module, not five** (Steve: "We don't want to
  force folks to read 5 different modules to understand a code flow").
  A module whose every caller is one other module belongs with that
  caller, unless the reason it stands alone is written down: a route
  whole (the upload's POST and GET, the docs, the admin retire), with main
  only dispatching to it; a rule to audit alone (which `<img>` a page may
  hold); an effect kept apart from the pure rules the twin tests. Helpers
  another module shares go where its callers meet (byte searches in Bytes,
  a markdown fence in its own module), not in whichever module wrote them
  first. What a route needs from the request (who is asking, the accounts)
  is a module of its own too, so the route can leave main.
- **A function earns its boundary.** It names a domain concept, hides a
  platform's fiddliness, removes real repetition, or is a pure decision an
  `expect` reaches. A wrapper of a line or two with one caller, or a second
  name for one function, is read better inline: the chat's `docs!` only
  split `/post` from the rest for its one caller, a match whose other arms
  make the same split in place. A rule of thumb, not a gate: a one-caller
  function that is a rule's one home, or the public name of a function the
  twins hold to its Zig, stays.

## The host boundary

- **A hosted effect answers a tag or a `Try`, not a Bool:**
  `[Serving, NotServing]`, `[Member, Outsider]`, and `Try({}, [Failed])` for
  one that can only succeed or fail. A Bool across the seam is as easy to
  misread there as anywhere.
- **A record that crosses into the host is checked against `roc glue`,
  field by field.** The host mirrors each record by hand, in Roc's field
  order (by sort key, then by name; a U64 comes before a List). A size
  assertion catches a missing or extra field but not two same-sized fields
  swapped, and a swap isn't an error: the host reads the wrong field, and
  memory is misread or corrupted. So the seam holds every record of every
  hosted function to what `roc glue` generates, at compile time, by name and
  offset, and every tag union tag by tag, by number (the chat's
  `src/chat_glue_test.zig`). With that check a record can be as large as
  the data is: there is no limit on its size, and a list of small records
  is a choice made for the data, not for the mirror.
- **A hosted function answers a fact, never a verdict.** When the Roc can
  decide from what the host can tell it, the host gives the fact and the Roc
  gives the verdict: `identify!` says who is asking, and `Members.admit!`
  decides whether they may use the chat. The host keeps only what needs its
  secrets or its state (an HMAC check, a key compare). A fact a request needs
  everywhere is read once, at the door, and passed to every route as a
  value, never as a lazy `[Known, Unasked]` cache.
- **A host answer of zero or one value becomes a named tag at the door.**
  `read_header!` and `read_query!` answer a `List(List(U8))`; before any pure
  module takes it, it becomes a tag union that says what it means
  (`Backlog.Given : [Sent(List(U8)), Unsent]`). Pure code never takes the
  host's list, or a `List.first` result with its `ListWasEmpty`.
- **The host is a type, not a struct of function pointers.** A host
  implements the seam as a type with one `pub fn` per hosted function, named
  as the Roc's platform names it. The whole-host constructor fails the build
  on a function that's missing or mistyped; only a test host may be partial,
  and its gap is a named panic, never a jump to address 0. A rule every host
  function follows (the answer when nothing can be done, the data root's
  join) lives once in the seam, not once per function.
- **The Roc decides; the host holds what lasts.** A long-lived or byte-heavy
  answer (a live stream, a file served as stored) is a decision the Roc
  makes and a primitive the host carries out: the Roc says which bus key, or
  which file, after it has checked whose it is, and the host only holds the
  connection or copies the bytes. The host never works out the key or the
  path again, so the check and the thing checked can't drift apart. Example:
  a topic's stream is the Roc's `Chat.topic_stream(BusKey.topic(at).bytes(),
  Paths.transcript_path(at).bytes(), topic)`, which the host replays and then
  holds.
- **A primitive takes the bytes exactly; the rule around them is the
  Roc's.** The host appends what it is handed (`append!(path, bytes)`,
  answering the size after); whether a torn line needs a newline first, or
  a feed a separator, the Roc decides from `stat!` and a one-byte
  `read_at!`, in a pure function its `expect`s reach
  (`Files.line_bytes`, `Files.entry_bytes`). One primitive with no rule in
  it replaces one per rule, and the rule is tested where it lives.
- **A bad name at the seam crashes (a 500) rather than returning `[]`.** An
  empty answer looks like a real one.
- **Decode the host's answer into types at the door.** See
  [decode once](#make-wrong-values-impossible-to-build).
- **A list the host would mirror goes a call at a time.** Rather than a
  list of records crossing the seam (one more mirror for the host to keep,
  and a list it must own and free), the Roc
  hands the host one item per call to an effect that keeps what it is
  building, then a last call to finish it. A topic's bundle is
  `Files.bundle_add!(name, path)` for each file, then
  `Host.serve_bundle!(name)`: two lists of bytes per call, no record.
- **An answer about what the Roc handed names it by its place.** When the
  Roc hands the host a list a call at a time, the host's answer names an
  item by its position in that list (`conv : U64`), never by a copy of the
  Roc's own key or URL. The Roc looks the item up, and a position past the
  list is a crash. The meaning stays in one home, and the seam record
  shrinks to numbers. Search hands the conversations it may look in, one
  `search_scope_add!` at a time, and each hit names its conversation by
  place.
- **Words the operator reads are the Roc's.** A host counter takes a tag
  for the kind and the Roc's bytes for the text, and keeps them; it never
  builds a sentence from facts the Roc already has (`count!(kind, text)`).
  An error crosses the seam as a number; when the Roc needs its name, it
  asks for it (`name_fault!`).
- **An effect that answers the request is for bytes only the host should
  touch.** Where the answer is a file's bytes (an upload, whole or a
  range, or a bundle), the Roc decides everything (whose it is, its type,
  the range, the 404 and the 416) and passes it in one record; the host
  answers, and the Roc returns `Chat.answered`. Everything decidable stays
  the Roc's: the host never parses the `Range` header again.

  ```roc
  Host.serve_upload!({ first, last, size, content_type, path, part: Range })
  ```
- **A rule the whole site keeps stays the host's primitive.** What is the
  chat's is the Roc's: a static script is `Route.asset` naming it, then
  `Host.serve_script!(name)` answering `[Missing, Served]`, the Roc saying
  the 404. How an embedded file is cached (its hash as its ETag, immutable
  when asked for by it, a 304) is webbox's `serveEmbedded`, which every
  embedded file on the site goes through, the games' too: a Roc copy of it
  would be a second home for one rule.
- **Markup the host made comes in at one door.** `Html.trusted` takes a
  string literal only; markup the host built (a script's hashed src, the
  server's own rendered markdown) becomes `Html` in Chrome.roc alone
  (`Chrome.src_in`, `Chrome.rendered`), so every place the page trusts bytes
  it did not write is in one file. The hunt flags `Html.host_markup`
  anywhere else.

  ```roc
  Doc({ slug, markdown, rendered: Chrome.rendered(rendered.html) })
  ```
- **What destroys is planned as data, then handed over a step at a time.**
  The Roc reads, decides, and builds the whole plan as a list of steps (a
  tag union: say it, remove this, write that) before anything changes;
  then it hands each step to an effect, in order, stopping at the first
  that fails. The host decides only whether to act (a dry run says, a
  confirm does), and what must go last goes last on the host's side (the
  accounts, after every step). The dry run and the confirm are then one
  plan, so what the preview lists is exactly what the confirm removes.

  ```roc
  Step : [Note(Kind, Str), Remove(Paths.ChatPath, [File, Tree]), Replace(Paths.ChatPath, List(U8)), RetireUser(Uid)]
  ```

## Layout and formatting

- **`roc fmt` decides layout.** Ask for a vertical stack with a trailing
  comma: it keeps it, as `zig fmt` does.
- **Stack anything with three or more parts, one per line, with a trailing
  comma**: a list, a record, a tuple, a call's arguments, a tag's payload.
  Three things on one line are hard to scan. A line over about 100 columns
  gets stacked too. A type annotation's arguments can't be stacked (`roc fmt`
  refuses the trailing comma there), so a signature with three or more
  arguments [takes a record](#name-what-travels-together) instead.

  ```roc
  JsonOut.object([
  	("conv", JsonOut.string(conv)),
  	("session", JsonOut.string(topic)),
  	("id", JsonOut.number(id)),
  ])
  ```

  That's `roc fmt`'s own shape: a call whose one argument is a stacked list
  keeps the bracket on the call's line.
- **A call nested three deep is read inside out; write it left to right.**
  A method chain first, where the values carry methods (the builtins' do:
  `s.split_on("\n").map(ZigText.trim_str).drop_if(|l| l.is_empty())`); a
  pipe where the steps are module functions; else a named middle step
  (`now = Time.rfc3339(Host.read_time!({}))`). A chain of edits reads as
  the order they run in:

  ```roc
  edited = text.to_utf8()
  	|> quotes
  	|> html_images
  	|> md_images
  	|> collapse_ws
  	|> cap(350)
  ```

  not `cap(collapse_ws(md_images(html_images(quotes(md)))), 350)`.

## Testing and enforcement

- **Test each pure mapping, and the exact bytes each builder makes,** with
  `expect`s beside the code. `roc test <app>.roc` runs every imported
  module's `expect`s (`roc test chat/main.roc` for the chat).
- **A rule a type can't express gets a Shale hunt with plants.**
  [Shale](https://github.com/showell/shale) is how we enforce this guide's
  more advanced preferences: what the type checker and `roc fmt` can't see. A
  hunt reads the code as Roc's own parser does (through `roc-ast`, so a
  comment or a string never counts), names each finding `path:line: check:
  why`, and is a question for a reader, not a verdict. Its plants are cases
  it must find and cases it must not, so the hunt itself is tested
  (`self_test=1`). The ones we run:
  - `tools/roc_hunt/hunt.shale` in roc-webbox: `bool_returns` (a Bool that
    should be a tag, or a question without its name), `fs_bypass` (a file
    call outside `Files.roc`), `html_trusted_nonliteral`, magic numbers,
    runs of same-typed arguments, positional lists, long `if` chains, and
    `single_caller` (a module every production reference to which comes
    from one other module, `twin` counting, unless its allowlist names it
    with its reason);
  - Shale's `cookbook/roc/name_hunt.shale`: an effect named as a state or a
    noun, a question with no Bool, vague names, a name its type contradicts,
    negative flags, `command_tense` (an effect told what to do in past
    tense: a tag union with no payloads whose tags all read as done,
    `[Pinned, Unpinned]`), and `preposition_split` (one noun given
    different trailing prepositions in one file, `blocks_of` beside
    `blocks_in`; a matched opposite pair and the `_from` recursion worker
    are fine). An effect that starts with a preposition (`of!`) is a
    `noun_effect`. The words are shared files in Shale's `cookbook/words/`,
    and `words=1` lists every first word an effect starts with, for a
    reader to scan. Beside the names, `mixed_tense` (an effect handed a
    union of commands and events at once, `[Pin, Unpinned]`; a `List(T)`
    argument is judged as `T`, for this and `command_tense`) and
    `container` (a type or record field named only by container words,
    `Entry`, `items`, unless its doc says whose: `## A folder's entry`);
  - Shale's `cookbook/roc/boundaries.shale`: `fixed`, a parameter every
    production call fills with the same literal (a recursion's `at: 0`;
    context passed down, `me` or `accounts`, is no constant), and `single`,
    a one-caller wrapper of a line or two that no `expect`, twin or `##`
    doc keeps (the rule of thumb in [modules](#modules-and-visibility),
    never a gate);
  - Shale's `cookbook/roc/errors.shale`: `error_alias` (a result's `Try`
    whose error is a shared alias, not its tags in place) and
    `optional_tag` (a tag named as an optional, `None` or `Some`);
  - Shale's `cookbook/roc/nest_depth.shale`: a call nested three deep or
    more, read inside out ([layout](#layout-and-formatting));
  - Shale's `cookbook/roc/stack.shale`: three or more parts on one line,
    or a line over 100 columns.

  The hunt runs these cookbook checks over the chat too, as findings:
  `stack.shale`, `name_hunt.shale`'s `command_tense`, `mixed_tense` and
  `container`, `boundaries.shale`'s `fixed`, `errors.shale`'s
  `error_alias` and `optional_tag`, and `nest_depth.shale` at four deep
  (main holds none; three deep still stands in some 46 places, builders
  and `expect`s among them, which the rule above asks to be rewritten as
  they are touched).

  A rule added here that a script can check gets a check, and a gate runs
  it (`bool_returns` must stay 0). A finding fixed by hand and left
  unchecked comes back.

## Tools and builds

- **Run `roc fmt`; its layout wins.** See
  [layout](#layout-and-formatting).
- **Build tests with `--opt=dev`.** `roc build` defaults to `--opt=speed`
  (LLVM): the chat took 5 min 21 s that way, 0.9 s on the dev backend.

---

All of these suggestions solely reflect Steve Howell's preferences, but he thanks the Roc community (notramo in particular) for several useful suggestions.
