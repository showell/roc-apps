# Roc, as Steve writes it

This style guide is as much about design as about style. Roc gives you
excellent tools for making code correct by construction: tag unions,
records, opaque types, `Try`. Using them is a discipline, though, and the
language won't apply it for you; this guide is that discipline, written down.

These are Steve's preferences for Roc in this repository and its siblings
([roc-chat](https://github.com/showell/roc-chat), dog-park's physics), and
most carry over from his Zig. Each one replaces a construct that can be wrong
and still compile with one that can't. Examples are small and constructed (a
cart, an order, a user id) unless real code is the clearest, which is Safari
(`canvas_apps/safari/`) or the chat; a module named as the chat's (`Files`,
`Html`) is in the older chat, roc-webbox's `chat/`. The rules are for any Roc.
The guide is written for Claude, which writes this code, so a rule is added
where our own code taught it. How the compiler itself behaves is in
[roc-notes.md](roc-notes.md), and what takes judgment rather than a rule is in
[smells.md](smells.md).

**Roc's own conventions** are in its language reference, the *langref*:
<https://roc-lang.org/docs/main/langref/> (read it at the pin's commit, fetched
as CLAUDE.md §1 says). Roc has no style guide for code, and `roc fmt` settles
layout with no options. Its conventions sit in the langref's pages, chiefly
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

- **A function that returns a Bool is a question, `is_*`, `has_*`, `can_*` or
  `should_*`, asked the positive way.** A bare noun or adjective (`all_digits`)
  doesn't say which way `True` points, and a negative (`no_*`, `not_*`,
  `is_not_*`) reads twice under a `!`. Examples: `is_finished`, `can_turn_to`,
  `is_too_narrow_to_shade`, the langref's `is_empty`.
- **A function is named for what it does,** so a reader can predict it
  without opening it; what the caller wants it for stays in the caller.
  `item_at(cart, i)` answers the item at an index, and crashes past the
  end; named `in_cart` it reads as a question.
- **A name stands alone from its module: repeat the noun.** A reader of a
  definition often forgets which module it's in, so write
  `TreeSighting.trees_in_view`, never a bare `in_view`, which reads as a yes or
  no and hides what it gives. Two words almost always remove the ambiguity,
  three counting a preposition: `RoadAhead.rider_point_at`. The name hunt's
  `phrase_name` reports a pure function that starts with a preposition and
  gives no Bool. Three kinds pass, because each reads as what it is: a
  constructor that gives its own module's type (`Clock.at_step`), a conversion
  (`Along.to_metres`, `Attention.from_fraction`), and a changed copy that gives its
  first argument's type (`Bike.with_lean`). A `from_*` is a conversion when it
  takes or gives its own module's type, even inside a record, a union or a
  `Try`'s success; in a `[].{}` module, which has no type to take or give, any
  `from_<noun>` is.
- **A verb in a pure function's name says what happens to its argument; a
  pretend effect goes, and the name becomes its answer.** `plus`, `clamp` and
  `project` say what happens to what they are given. `draw`, `fill`, `paint`,
  `plant` and `render` claim to act on something outside, and all the function
  does is give a value, so `draw_tree` is `tree_shapes`. An effect does act, and
  keeps its verb (`draw!`). The clear name goes on the function, not the local
  (Steve: "I like brevity for the var name and clarity for the function call"):
  `rider = rider_state_at_next_step(...)`. The name hunt's `world_verb` holds
  this.
- **A pure function starts with `push`, `set`, `append` or `add` only when it
  gives back what it was handed, and never starts with `get`.** `append_digits`
  takes a `List(U8)` and gives one. Anything else makes a new value, so it is
  named for that value, and a plain name already says what it gets: `speed`, not
  `get_speed`. Shale's `plain_names` holds this as `pure_mutator`.
- **A name holding a list is plural or explicit.** `triangle : List(Shape)`
  would have to be `triangles` or `triangle_list`. The word that counts is the
  noun: the one before a preposition or a word like `ahead`, else the last, so
  `trees_in_view`, `corners_ahead` and `rectangle_corners` all pass. A collective
  noun doesn't count: a herd of cows is `herd_cows`, and a route of segments is
  `route_segments`. The rule covers a function that gives a list or a `Try` of
  one, a field and a parameter, and a verb's object doesn't excuse it unless the
  function gives back the list it took (`push_trail`). Bytes are plumbing, so
  `boundary : List(U8)` says what they mean, but `flat_coordinates` gives a
  `List(F64)` and is plural. A word with no plural passes, and an accumulator may
  keep its short idiom as its whole name, `out`. The name hunt's `singular_list`
  holds this.
- **A pure function is named by a noun for what it gives, or a verb for
  what it does; never by an adjective or a bare past participle.** A lone
  participle (`added`, `joined`, `named`, `escaped`) reads as a Bool:
  `if added(...)` looks like a question. Name the thing it gives
  (`escaped_text`, `user_by_name`) or what it does (`add_user`). A page that
  says why a request was refused is a `refusal`, not `refused(why)`.

  ```roc
  escaped_text : Str -> Str
  refusal : Str -> Html
  user_by_name : Users, Name -> Try(User, [NoSuchUser])
  ```
- **Prefer a plain word to an abbreviation.** `position`, not `pos`;
  `acceleration`, not `accel`. Shale's `plain_names` holds this as
  `abbreviation`, from its list of them.
- **A method a `where` clause names has at least two words.** A `where`
  clause matches a method by name alone, so any type with that method fits,
  whatever it means by it, and the name is the whole contract: a one-word
  `bark` would take a tree's bark for a dog's. `Pipeline.roc` is the worked
  example. It asks a kind of scenery for its `scenery_height` and its
  `scenery_picture`, and `Conifer` gives both without knowing `Pipeline`. The
  methods Roc calls by name, for operators and the like (`is_eq`, `plus`),
  have a fixed meaning and keep their names. The name hunt's `where_name`
  holds this.

  ```roc
  rendering_of : Pipeline.Sighted(kind), { focal_length : Pixels, context : context } -> Rendered
  	where [kind.scenery_picture : kind, Picture.Setting(context) -> Picture]
  ```
- **Prefer a two-part name that says what a thing is to a short one that
  is cute or sounds like something else.** One word saves a few letters
  and costs the reader a guess. An order whose every part is checked,
  waiting only for its number, named `Order.Submission`, reads as an
  event, the act of submitting; `Order.Unnumbered` says what it is, and a
  value of it is `unnumbered_order`.
- **Use the domain's exact word, keep Roc's words for Roc, and name a
  function and its inverse as a mirrored pair.** `record`, `tag` and
  `module` mean Roc's things to a Roc reader: `<p>` is a tag, and what
  `Html.element` builds is an element. A reader that knows `read_message`
  finds `write_message` without looking.

  ```roc
  Html.element({ name: "p", attrs: [], inner: Html.text(body) })
  write_message : Message -> Str  # beside read_message : Str -> Try(Message, _)
  ```

  Shale's `name_hunt` checks part of this as `taken_word`: a top-level
  or member function named only by Roc's word (`record`, `tag`), unless it gives that
  very thing (`record : Key -> ApiKey.Record`), and a value named only by a
  number (`three`).
- **One thing has one word, and a project lists the words it has retired.** A
  search then finds every use, and a word can't outlive its thing. Safari's
  `vocabulary.txt` keeps `lean` over `tilt` and `road` over `lane`, and Shale's
  `vocabulary` reports a retired word in a name or a comment.
- **One relation keeps one preposition in a file.** `blocks_of` beside
  `blocks_in` makes a reader ask how they differ. A pair of opposites is fine,
  like `point_in_segment_before` and `point_in_segment_after`. The name hunt's
  `preposition_split` holds this.
- **A name's last word promises its type.** A `*_count` is an integer
  (`nearer_tree_count : U64`) and a `*_path` is a `Str` or a path type. A project
  adds its own words in a table: safari's `name_types.txt` ties `fraction` to
  `Fraction` and `steps` to `Steps`. Both are checked as `name_type`.
- **Modules that look alike are spelled alike, and one type name means one
  thing.** `TreeSighting`, `RailSighting` and `GroundSighting` answer
  `trees_in_view`, `rail_quads_in_view` and `patches_in_view`, so a reader who knows
  one finds the others. Shale's `families` reports a member that lacks a public
  name most of its family has (`family`; a member that differs says so in its
  `##` doc), and a `Pose` that has two shapes in two modules (`twin_name`).
- **A top-level value or a field is never one letter.** `board_width`, not
  `w`; `row`, not `y`. It is read far from where it is set, so its name is
  all the reader has. Coordinates are the exception: `x` and `y` on a point
  like lib's `Point.Point` are the words for what they hold. A local or a lambda's
  parameter can be short: its definition is in view.
- **A type or a field is named for what it holds, not where it sits.**
  `Entry`, `Item`, `Node`, `Data` and `Info` say only that a value is in a list
  or a tree; the domain usually has the word. One row of a customer's order
  history is an `OrderSummary`, not an `Entry`. Where the container word *is* the
  domain's (a folder listing's entry), it stays, and its `##` doc says whose. A
  function named only by vague words (`handle_data`, `process!`) has the same
  fault. The name hunt's `container` and `vague` hold this.
- **A record that reports an act names its fields for the things;** its
  type, a noun, already names the act. A field `added` says again what
  `Addition` says, and hides that it holds a user.

  ```roc
  Addition : { directory : Directory, user : User }  # not { directory, added : User }
  ```
- **A method on a type that holds more than one kind of thing names its
  object.** `Directory.remove` could remove a member, an invite or a
  topic; `remove_member` says which, beside `add_member`. A type that holds
  one kind keeps the bare verb: a conversation holds only messages.

  ```roc
  Directory.remove_member(directory, user)
  Conversation.append(conversation, message)
  ```
- **An error tag that wraps another module's error names where it came
  from; a leaf error tag names what went wrong.** The wrapper's name is the
  source, its payload the source's own tags, so nothing is renamed on the
  way up; a leaf has no source, so it says the fault.

  ```roc
  Author(id, fault)  # fault is one of Author.from_str's tags
  BadHead(id)        # a leaf: the head itself is wrong
  ```
- **An effect is named for its act, never as a state or a noun.** `page!`, `appended!` or `member!` read as a value or a question,
  not a command. A route handler is `serve_*!` for what it serves
  (`serve_topic_page!`); a lookup that can fail the request is `load_*!`
  (`load_viewer!`); anything else is a verb (`append_message!`, `fan_out!`).
  An effect whose first argument is a surface, a `Frame` or a `Canvas`, is
  named for what it draws there. A port is where bad names come from: it keeps
  the old function's noun or past tense, so rename on the way in.
- **A command is not named as a question.** An effect that
  does something and reports how it went is named for the act, not for the
  state it checks: `serve_file!` answering `[Serving, NotServing]`, not
  `held_raw!`.
- **Name a tag for what it is: a command, an event, or a state.** A tag that
  tells someone what to do is an imperative verb; a tag that reports what
  happened is past tense; a tag that says what is (a state, an answer) is a
  noun or an adjective. The reader can then tell an instruction from a fact
  at a glance, and a tag passed *in* as an instruction doesn't read like
  something that has already happened. The name hunt's `command_tense` and
  `mixed_tense` hold this for what an effect is handed.

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
- **A flag a caller passes is a tag; a port keeps its source's named
  predicates.** The markdown's callers say `Tight` or `Loose`, `HardWrap`
  or `Reflow`, `Linked` or `InLabel`; inside, CommonMark's own `left`,
  `right`, `can_open` and `can_close` stay Bools, as the spec and the
  Zig it is held to name them.
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
  `checkout! : Cart, Str, Str => Try({}, [Declined])`
  stays one line however it's written, and a call can pass the coupon as
  the address. A record stacks (it's a value),
  names every argument where it's passed, and can't be called with two
  swapped. So two arguments stay as they are; three or more become one record
  argument, or two arguments where one is a record of the rest.

  ```roc
  checkout! : {
  	cart : Cart,
  	coupon : Str,
  	address : Str,
  } => Try({}, [Declined])
  ```

  The second form is the usual one: the subject first, the rest a record,
  so a call reads as an act on its subject with its options named:
  `add : Cart, { item : Item, quantity : U64 } -> Cart`, called as
  `cart.add({ item: tea, quantity: 2 })`. A loop's
  index and accumulator are fields too (`{ at: i, out }`), a one-letter
  parameter given a field's name and keeping its own in the body.

  The stack hunt flags a signature with three or more arguments
  ([enforcement](#testing-and-enforcement)).
- **A parameter every caller passes the same value is no parameter.** A
  recursion's start (`at: 0`, `kept: 0`) belongs to an entry function that
  takes only what varies, and the `_from` worker it calls is the one place
  the index is passed: `find(s, { needle })` calls
  `find_from(s, { needle, at: 0 })`.
- **The entry function takes the plain name; the worker is named for what
  it adds.** Callers call `count`, `find`. The worker's suffix is
  a preposition naming its extra parameter, so a call reads as a sentence:
  `_from` for a start point (`count_from(xs, at)`), `_onto` for an output
  being built (`html_onto(out, node)`), `_with` for other carried state
  (`walk_with(tree, seen)`). A suffix that only says "I'm the helper"
  (`_acc`, `_loop`, `_inner`, `_helper`, `_rec`) names nothing; a `_step`,
  `_walk` or `_go` that calls itself is one too. The name hunt's
  `worker_name` flags them. A worker never stacks two prepositions: when
  the entry's name already ends in one (`tail_from`), rename the pair so
  each reads once, the entry for what it gives (`tail`) and the worker for
  what it adds (`tail_onto`), never `tail_from_onto`. The hunt's
  `stacked_preposition` flags them.
- **A loop is a `for`, over a list or a range; a `while` is for a condition.**
  `for pixel in pixels` has no counter, no increment and no `List.get` with
  a placeholder, and `for _ in 0..<n` says "n times". A `while` stays for a
  stop that isn't a count, an early exit, or a step other than one, and a
  stepped float (below) stays a `var` and a `while`. Recursion stays where it
  says more than a loop: walking a list by pattern, or a merge. Recursion
  that only counts or only builds a list is a loop, and needs no worker.
- **A pure function that takes only `{}` is a constant.** `empty_cart : Cart`
  says what it is; `empty_cart : {} -> Cart` makes every caller write
  `empty_cart({})` for a value that never changes. One stays a function: a
  value generic over a type variable can't be a constant. The pin refuses
  one ("value is not polymorphic") and asks for a `{}` function, so
  `empty_cart : {} -> Cart(item)` stays.
- **Neighboring arguments of one type get a record**, even when there are
  only two of them: they can be swapped and still type-check, and a record
  names the fields, so order can't go wrong: `copy!({ from, to })`, not
  `copy!(src, dst)` with two `Str`s in a row
  ([records](https://roc-lang.org/docs/main/langref/records/)).
- **A fundamental pair is one record, with a concise comment on each field.**

  ```roc
  Money := {
  	## Whole cents; negative for a refund.
  	cents : I64,

  	## The ISO 4217 code, such as "USD".
  	currency : Str,
  }.{
  	is_eq : _
  }
  ```
- **No list read by position.** A list of lists whose parts are known only by
  their index becomes a list of records.
- **When one of two neighbors of the same type is a checked value, give it
  its own opaque type.** `part(body : List(U8), boundary : List(U8))` can be
  called with the two swapped, or with a boundary nobody checked. With
  `boundary : Form.Boundary`, made only by the function that checks it, the
  swap doesn't compile and the check can't be skipped.

### Make wrong values impossible to build

- **Use a nominal type (`:=`) where values of the same shape mean different
  things.** A name passed where an id belongs is then a type error
  ([types](https://roc-lang.org/docs/main/langref/types/)).
- **Spell out the arms of a match on a closed set; no wildcard.** With
  `(Stream, Post) => …` and `(Stream, Put) => …`, a new tag is a compile
  error that forces a decision, where `(Stream, _)` takes it silently. When
  the repeated body passes about six lines, extract a helper. Arms that
  share a body can still be one arm by alternation at the top level (`Flat(_) | Span(_) => …`), and one tag that splits on a
  condition takes a guard (`Cones if tall => …`).
- **A float keeps its order of operations when code is rewritten.** A sum
  that was right-nested stays a `fold_rev`, and a value stepped by
  `+ step` stays an accumulation, never `i * step`: each rounds
  differently, and a picture or a hash changes.
- **A negative number is written negative: `-1.0`, `-half_pi`. `0.0 - x`
  stays where `x` is worked out as the program runs and can be zero.** The
  subtraction gives +0.0 there and `-x` gives -0.0, and a later sum can see
  the sign, so a unit's `opposite` is a subtraction with an `expect` that
  says so.
- **A float lives inside a unit type or the trigonometry.** Anywhere else, a
  bare `F64` in a signature or a type is named with its reason in a table,
  safari's `bare_floats.txt`, which `cookbook:roc/bare_floats.shale` holds at
  zero: a real ratio has no unit, so it goes there.
- **A dense formula unwraps once, does its math in plain floats, and wraps
  once.** A unit's methods name one step well, but a chain of them buries a
  sum a reader knows from paper. A chain of one or two steps stays. So does
  a step from one unit to another, where a named middle step reads as well
  as floats would and the types still check the crossing.

  ```roc
  # Not this:
  diagonal = width.squared().plus(height.squared()).square_root()

  # This:
  w = width.to_metres()
  h = height.to_metres()
  Distance.metres((w * w + h * h).sqrt())
  ```
- **A new type is opaque (`::`) by default; nominal (`:=`) needs a reason.**
  An opaque type can change its insides without touching a caller, and
  nobody outside builds one by hand. Say the reason for nominal in the type's
  doc unless it is the one below. A wish to build values in a test or a
  widget is not a reason: give the type a maker instead. Widgets are real
  clients, so a maker only widgets use is fine; one only tests use is not.
- **A closed set that needs no checking is nominal, not opaque.** This is
  the usual reason. Every
  value of `Conifer := [Green, SmallGreen, Red, Gold]` is valid, so there
  is nothing to guard, and callers write `Conifer.Red`. Opaque is for
  values a constructor must check.
- **Use an opaque type (`::`) for anything validated.** Only its own module
  can build one, so the validator is the only way in. A `UserId` is all
  digits, and `from_str` is the only way to get one:

  ```roc
  UserId :: Str.{
  	from_str : Str -> Try(UserId, [NotAUserId])
  	from_str = |text|
  		if is_all_digits(text) {
  			Ok(UserId.(text))
  		} else {
  			Err(NotAUserId)
  		}

  	to_str : UserId -> Str
  	to_str = |UserId.(s)| s

  	is_eq : _
  }
  ```
- **Combine them into the domain's real shape:**
  `Recipient : [User(UserId), Group(GroupName)]`.
- **A state machine is an opaque type whose module owns the transitions.**
  Each state is a value only the module can build, and each transition is a
  function from one state to the next, so a caller can't make a state by
  hand or skip a step. What a state claims (a search found this place) is
  then true by construction, not by each caller's care. A two-state tag used
  inside one function needs none of this; a state that crosses functions or
  modules does. An order is open, then placed, then shipped:

  ```roc
  Order :: [Open, Placed(U64), Shipped(U64)].{

  	## Every order starts here.
  	open : Order
  	open = Order.(Open)

  	place : Order, U64 -> Try(Order, [NotOpen])
  	place = |Order.(state), id|
  		match state {
  			Open => Ok(Order.(Placed(id)))
  			_ => Err(NotOpen)
  		}

  	ship : Order -> Try(Order, [NotPlaced])
  	ship = |Order.(state)|
  		match state {
  			Placed(id) => Ok(Order.(Shipped(id)))
  			_ => Err(NotPlaced)
  		}
  }
  ```

  A caller holds an `Order` and passes it on; it can't write `Shipped(7)`
  itself, or ship an order that was never placed.
- **Decode into the type at the door, once.** The function that reads a
  request, a file or a host answer turns it into `UserId`, `Recipient`, `Money`;
  nothing deeper takes the raw `Str` or bytes and decodes again.
- **A nominal or opaque type derives `is_eq` with `is_eq : _`.** Write one by
  hand only when equality isn't structural; a hand-written structural one is
  more code to read and to get wrong
  ([compiler-derived methods](https://roc-lang.org/docs/main/langref/static-dispatch/#compiler-derived-methods)).
- **Call a value's own functions as methods:** `messages.last()`, not
  `List.last(messages)`; `id.to_str()`, `count.to_str()`.
  The subject comes first, as in a sentence, and a chain reads in the order
  it runs. Agents lean the other way, because most functional training data
  has no methods, so expect to correct them.

  Keep a module call where it's no method call:
  - the function is passed as a value (`xs.map(Str.trim)`, `map_ok(UserId.to_str)`);
  - the first argument isn't the module's type (`Str.from_utf8(bytes)`,
    `Str.join_with(pieces, sep)`);
  - a builder makes a value from parts rather than reading one;
  - a module calls its own functions in its own body;
  - the step is the right side of a `|>`;
  - the value is a bare numeral, or a name that only numerals type:
    `I64.to_str(steps)` over `[10, 1000]` prints `10`, and `steps.to_str()`
    defaults to `Dec` and prints `10.0`.

  Shale's `cookbook/roc/methods.shale` (`glob=app/*.roc root=app/main.roc`)
  finds the rest and rewrites them where `roc check` and `roc test` agree: a
  dry run by default, and `apply=1` writes. Only a nominal or opaque type can carry methods, not an
  alias ([static dispatch](https://roc-lang.org/docs/main/langref/static-dispatch/)).
- **Structured output goes through one opaque builder, never a string spliced
  by hand.** JSON is `JsonOut :: List(U8)`, with `string`, `number`, `bool`,
  `array`, `object`, and `bytes` the only way out, so every field is a whole,
  escaped value. Html is opaque the same way: a page is built only from
  escaped text and literal markup. roc-webbox's chat and roc-chat follow
  this rule (roc-chat's `app/JsonOut.roc` and `app/Html.roc`, the only
  takers of an answer's JSON and a page's HTML).

  ```roc
  # Not this: a quote in `name` breaks the JSON.
  "{\"name\": \"${name}\", \"quantity\": ${quantity.to_str()}}"

  # This: each field is escaped by the builder.
  JsonOut.object([("name", JsonOut.string(name)), ("quantity", JsonOut.number(quantity))])
  ```
- **An opaque type keeps its sources, never a value derived from them
  beside them.** A file name kept as `{ kind, name }` can say `.png` while
  its kind says `Jpeg`; kept as `{ kind, digits }`, the name is built from
  both when asked, and the two can't disagree.

### Syntax at the pinned nightly

- declare: `X := T.{ ... }` (nominal) or `X :: T.{ ... }` (opaque);
- wrap: `X.(v)`. Plain `X(v)` parses as a tag;
- unwrap: the pattern `|X.(v)| v`;
- compare: `==` needs an `is_eq` on the type; `is_eq : _` derives it;
- a one-field record: `{ gap: gap }`. `{ gap }` is a block that gives `gap`.

## Text and bytes

- **Text is a `Str`; bytes exist only at the door.** Decode to UTF-8 once,
  where text enters (a request, a file, a host answer). Past that point, work
  in `Str` with its helpers (`split_on`, `join_with`, interpolation);
  `List(U8)` is for parsing at the door, and for bytes that aren't text
  ([strings](https://roc-lang.org/docs/main/langref/strings/)).

  ```roc
  words : List(U8) -> Try(List(Str), [NotUtf8])
  words = |bytes| {
  	# At the door, once:
  	text = Str.from_utf8(bytes) ? |_| NotUtf8
  	# Past it, Str's own helpers:
  	Ok(text.split_on(" "))
  }
  ```
- **Build text by interpolation:** `"${base}/${topic}"`, not a chain of
  `Str.concat` calls or a byte list joined by hand. The template reads as the
  result. Only a `Str` goes in a slot, so convert at the slot:
  `"${count.to_str()} messages"`. A long template is a multiline string (see
  below). Joining a list of pieces is `Str.join_with(pieces, sep)`, a
  function, not a method on the list at the pin. `Str.concat` is for a fold
  that builds text piece by piece.
- **An element with attributes is built by `Html.element`; a value never
  reaches an attribute through a template.** `Html.element({ name, attrs,
  inner })` puts every attribute value through `escape`, so no caller can
  forget it, and its names are code (lowercase letters, digits, `-`; else a
  crash). A trusted literal that leaves a quote open for a value to follow
  (`Html.trusted("<a href=\"")`) is a hunt finding. A template's slots
  (`Html.fill`) hold text between elements, never inside a tag.

  ```roc
  Html.element({ name: "a", attrs: [Attr("href", href)], inner: Html.text(label) })
  ```
- **The markdown renderer is the one writer of markup by bytes** (Md,
  MdInline, MdMedia in roc-markdown's `package/`). It is parsing at the door,
  held byte for byte to the Zig that defines the dialect, so it writes its
  HTML as bytes, every byte of a member's text through its one escape,
  `MdText.escape_onto`, and every tag it lets through rebuilt by MdMedia's
  allowlist.
- **Join bytes only where bytes are the point:** inside an opaque builder
  (`Html`, `JsonOut`) or a decoder at the door, with `List.join`. Text past
  the door stays `Str`.
- **Refuse what isn't UTF-8.** A single read of text that isn't UTF-8 fails
  (`Try(Str, [Missing, Failed, NotUtf8])`). Inside a collection, the
  [damaged-entry rule](#errors-and-failure) applies instead:
  the entry is skipped and counted.
- **A color is written in hex, in code and in the `expect` that holds it:**
  `0x1C5A22`, not `1858082`. Each channel can be read off the number.
- **A Bool is `True` or `False`, without the module.** The tags are short and
  unambiguous, and `!x` says what `x == False` says. A `crash` takes no
  parentheses: `crash "..."`.
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
  `List.max`, and one that stops early is `List.fold_until`. A fold that
  needs each index is `List.fold_with_index`, and a list of indexes is a
  range, `List.from_iter(U64.until(0, n))`; neither needs
  `List.map_with_index(xs, |_, i| i)`. `Json.to_str` of a
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
  `is_letter`, `is_whitespace`, `to_lowercase` and the rest), asked one
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
  # Not this: a caller can ignore the Bool.
  save! : Str, List(U8) => Bool

  # This:
  save! : Str, List(U8) => Try({}, [Failed])
  ```
- **Its error tags say what went wrong.** The langref's `[ListWasEmpty]` says
  why; an `Err(None)` says nothing, and two such errors look alike after a `?`
  joins them.
- **No optionals: a value that may be absent is tagged by what it is, and
  its absence by why.** `[Some(x), None]`, `Nothing`, and `Try(x, [None])`
  make every caller remember what "none" meant. A topic's last message is
  `Try(Message, [NoMessage])`; the editor's open doc is
  `[NoneChosen, Doc(...)]`. The same holds for a fold's "nothing found yet"
  (`[Newest(...), NoDocs]`).
- **One or none is a `Try`, with a singular name and no `maybe_` prefix.** A
  list of one or none claims more than is true, and the type should say there
  is at most one. `Pipeline.tall_sighting_of` answers
  `Try(Pipeline.Sighted(kind), [BehindCamera, TooSmall])`, so its error also says
  why there is none.
- **A `Try`'s error lists the tags that function can return, in place; no
  shared error alias.** `Cart.add` fails only with `[OutOfStock(Item)]` and
  `Cart.remove` only with `[NotInCart(Item)]`; one alias of both,
  `CartError : [OutOfStock(Item), NotInCart(Item)]`, makes every caller of
  each handle a tag that can't happen. An output union is open to its
  callers, so the narrow list still meets a handler that takes the wide one
  (a `report_cart_error!` that handles both), and
  the checker holds the body to the list. An alias is for a handler's
  input. Leaving the error to inference (`_`) is fine too.
- **When an argument's tag decides which errors can happen, split the
  function by that tag**, so each answers only its own errors. If
  `Accounts.add({ joining: [Person, BotOf(Person)] })` answers
  `[NoSuchOwner, Full]`, a caller that only ever passes `Person` has to
  crash on `NoSuchOwner`, an error a person can't get. As `add_person`
  (`[Full]`) and `add_bot` (`[NoSuchOwner, Full]`), the impossible case
  can't be written.
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
- **A function that makes one thing answers that thing, not a list of it.**
  A list that is empty on bad input turns a bug into nothing drawn, and every
  caller joins it without a look. Safari's `Camera.clipped_polygon` answers one
  shape and crashes on two corners; `Brush.circular_gradient` answers a `Try`,
  because a distant gradient really can shrink out of sight. The caller that has
  nothing to draw says so in its own list.
- **A placeholder is not a value.** `?? "bogus"`, `?? "?"`, or `?? 4` for
  "no winner" makes up an answer the type allows and the program never
  means; it flows on and shows up far away as a wrong answer. A number
  kept to mean "none" (`no_frames = 1e9`) is the same thing. Where the
  index can't be wrong, crash with a reason; where it can, tag the absence
  (no optionals, above). On a list being written the placeholder also
  copies the list (`List.set(l, i, v) ?? l`, CLAUDE.md §10).

  ```roc
  # Not this: seat 4 is no seat.
  winner = seats.find_first(|seat| has_finished(game, seat)) ?? 4

  # This: the absence is a state.
  winner =
  	match seats.find_first(|seat| has_finished(game, seat)) {
  		Ok(seat) => Won(seat)
  		Err(NotFound) => StillPlaying
  	}
  ```
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
- **Best-effort work runs in an aside, and gives back what it could not
  spend.** Work the request does not stand on (a broadcast, a welcome)
  runs between `Host.mark_aside!(Begin)` and `Host.mark_aside!(End)`: a read
  that fails there fails the aside, never the request. Whatever the work was
  owed is handed back to the host when it did not happen, so it is tried
  again later rather than lost.

  ```roc
  _ = Host.mark_aside!(Begin)
  told = came_online!(who)
  match (Host.mark_aside!(End).status, told) {
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
  its own. Example: one member's feed entry, written in its own aside,
  published only if the write held, its fault counted if not.

  ```roc
  ended = Host.mark_aside!(End)
  match ended.status {
  	Done => Host.publish!(key, event)
  	Failed => Host.count!(FanoutFailure, Fanout.failure(surface, details))
  }
  ```

## Modules and visibility

- **A module opens with a `##` doc that says what it does.** A reader starts
  there, so it is present tense, with no history: `Pipeline.roc`'s doc says
  what the module carries and how. Shale's `plain_names` holds this as
  `module_doc`.
- **Private helpers live outside the `X :: [].{ }` block**. Only what sits
  inside the block is exposed
  ([modules](https://roc-lang.org/docs/main/langref/modules/)), so the block
  is the module's public surface at a glance. A helper outside names a block
  member qualified (`Util.public_fn`); the module's own `expect`s call helpers
  bare.

  ```roc
  Util :: [].{
  	public_fn : Str -> Str
  	public_fn = |s| helper(s)
  }

  helper : Str -> Str
  helper = |s| s.trim()
  ```
- **A resource is reached through one module.** In the chat, `Files.roc` is
  the only caller of the host's file functions, and it keeps missing and
  failed apart as a `Try`'s two error tags. Every other module asks it; a
  [hunt](#testing-and-enforcement) flags any call that bypasses it.
- **A flow is read in one module, not five** (Steve: "We don't want to
  force folks to read 5 different modules to understand a code flow").
  A module whose every caller is one other module belongs with that
  caller, unless the reason it stands alone is written down: a route
  whole, with main only dispatching to it; a rule to audit alone (which
  `<img>` a page may hold); an effect kept apart from the pure rules the twin
  tests. Helpers another module shares go where its callers meet (byte
  searches in Bytes), not in whichever module wrote them first.
- **A function earns its boundary.** It names a domain concept, hides a
  platform's fiddliness, removes real repetition, or is a pure decision an
  `expect` reaches. A wrapper of a line or two with one caller, or a second
  name for one function, is read better inline: the chat's `docs!` only
  split `/post` from the rest for its one caller, a match whose other arms
  make the same split in place. A rule of thumb: a one-caller function that
  is a rule's one home, or the public name of a function the twins hold to
  its Zig, stays, and a `##` doc or an `expect` answers the hunt. A function
  nothing reaches goes.
- **A building block never imports a type built from it.** If a narrower
  caller needs the same operation, it uses a builtin or keeps its own call,
  and a test holds the two equal. A letter-folding module that takes
  `[Written, Strict(StrictName)]` only so strict names can reuse its fold has
  its dependency backwards; a strict name lowercases with
  `Str.with_ascii_lowercased`, and a test holds both keys equal.
- **A function that reads part of a higher layer's record takes an open
  record.** It says exactly which fields the function reads, and the caller
  passes its whole record, so the lower module never imports the type above
  it. `roc check` refuses a record that lacks one of the fields. A function
  that gives the record back keeps the fields it doesn't name, so its body
  is an ordinary `{ ..parcel, ... }`. Here an `Order` holds a customer and
  a payment, and `Shipping` sits below it and knows neither. Name the type
  when several functions share it, and spell it out in the signature when
  one function reads it. A signature that never names the rest writes a plain
  `..`: `{ weight_grams : U64, .. } -> U64`.

  ```roc
  Parcel(others) : { weight_grams : U64, postcode : Str, ..others }

  cost_in_cents : Shipping.Parcel(others) -> U64
  with_weight : Shipping.Parcel(others), U64 -> Shipping.Parcel(others)

  Shipping.cost_in_cents(order)  # the caller passes the whole order
  ```

  Don't use one where nothing is gained. A function that reads one field
  takes that field: `is_local(order.postcode)`. A module whose subject is the
  record takes it by name: giving each of an order's rules its own slice
  restates the record a dozen times. And a record from the same layer or a
  lower one is imported and named as usual.

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
  offset, and every tag union tag by tag, by number (roc-chat's
  `host/seam/glue_test.zig`). With that check a record can be as large as
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
  a feed a separator, the Roc decides from `read_stat!` and a one-byte
  `read_at!`, in a pure function its `expect`s reach
  (`Files.line_bytes`, `Files.entry_bytes`). One primitive with no rule in
  it replaces one per rule, and the rule is tested where it lives.
- **A bad name at the seam crashes (a 500) rather than returning `[]`.** An
  empty answer looks like a real one.
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
- **Stack a group of three or more items and six or more tokens, one item
  per line, with a trailing comma**: a list, a record, a tuple, a call's
  arguments, a tag's payload, a lambda's arguments. Every other group sits on
  one line, without the comma. A token is what's left when the punctuation
  goes: a name (a dotted path like `Angle.Bearing` is one), a number, a
  string. So a record of three typed fields stacks, because someone reads
  it to learn the shape, and the arguments that only name those fields sit
  on one line, because nobody needs to read them:

  ```roc
  triangle : I64,
  {
  	first_corner : Point.Point,
  	second_corner : Point.Point,
  	third_corner : Point.Point,
  } -> Shapes.Shape
  triangle = |color, { first_corner, second_corner, third_corner }|
  ```

  Two items stay side by side, whatever they hold: a pair reads as a pair,
  like `{ along: Along.metres(33.0), across: Across.metres(-17.0) }` or a
  table's `(agent_added(full, { name: "Bot", owner: zed }), Err(NoSuchOwner))`.
  A row of literals stays side by side too, like
  `[1.0, 2.0, 3.0, 4.0, 5.0, 6.0]`, and may stand stacked. A group with a
  comment in it stays stacked, because `roc fmt` won't join it.

  A line over about 100 columns gets stacked whatever its tokens, unless a
  string literal is all that makes it long: Roc has no short way to split a
  string, and frozen text reads better whole. A type annotation's arguments
  can't be stacked (`roc fmt` refuses the trailing comma there), so a
  signature with three or more arguments
  [takes a record](#name-what-travels-together) instead.

  ```roc
  JsonOut.object([
  	("name", JsonOut.string(name)),
  	("quantity", JsonOut.number(quantity)),
  	("cents", JsonOut.number(cents)),
  ])
  ```

  That's `roc fmt`'s own shape: a call whose one argument is a stacked list
  keeps the bracket on the call's line.
- **An `if` takes braces, and a body takes no parentheses.** `roc fmt` keeps
  both of an emitter's habits, and adds the parentheses to a braceless `if`
  itself, so `if (x) a else b` is the layout it gives a form we don't write.
  An `if` that is a lambda's whole body starts its own line, never
  `|x| if x > 1 {`.
  Parentheses that group an operand stay: a float's order rests on them.
  Parentheses that group nothing go: `a * b + c * d`, not
  `(a * b) + (c * d)`, and `f(a * b)`, not `f((a * b))`. This is our taste,
  not Roc's. Safari holds it at zero; older trees still carry the braceless
  form.

  ```roc
  # Not this:
  shipping = |order| (if (order.is_rush) 900 else 400)

  # This:
  shipping = |order|
  	if order.is_rush {
  		900
  	} else {
  		400
  	}
  ```
- **A call nested four deep is read inside out; write it left to right.**
  A method chain first, where the values carry methods (the builtins' do:
  `s.split_on("\n").map(Str.trim).drop_if(|l| l.is_empty())`); a
  pipe where the steps are module functions; else a named middle step
  (`now = Time.rfc3339(Host.read_time!({}))`). A chain of edits reads as
  the order they run in:

  ```roc
  cleaned =
  	input
  		|> strip_tabs
  		|> collapse_spaces
  		|> truncate(80)
  ```

  not `truncate(collapse_spaces(strip_tabs(input)), 80)`.
- **A state that changes in steps names each step,** even two deep.
  `save(refill_hand(activate(game, card)))` hides the states between; a
  name for each says what the game is at that point, and the steps read in
  the order they happen:

  ```roc
  activated = game.activate(card)
  refilled = activated.refill_hand()
  save(refilled)
  ```

## Testing and enforcement

- **Test each pure mapping, and the exact bytes each builder makes,** with
  `expect`s beside the code. `roc test <app>.roc` runs every imported
  module's `expect`s (`roc test app/main.roc` for roc-chat).
- **An `expect` sits at the top level of its file, below the block.** Roc
  also runs one inside the block, but a gate counts the lines that start
  `expect`, so the source is the count, and each must pass exactly once
  (safari's `gates/run.shale`, roc-chat's `tools/verify.shale`). Below the
  block it names members as a caller does (`PigHerd.NoPigs.herd_pigs(...)`) and helpers bare.
- **An `expect` that no one module can write goes in a gates-only app.** A
  check may need two modules that don't import each other, and a production
  import added only for a test is the wrong fix. Safari's
  `gates/expects/` holds those; it is the exception, and an
  `expect` that fits beside its code goes there.
- **A float compared with a tolerance states the tolerance once, over a
  table.** `(got - want).abs() <= tolerance` is false for a NaN and an
  infinity, so it needs no finite check. A float with no tolerance is
  compared with `==`.

  ```roc
  expect
  	[
  		(0.5, 0.479425538604203),
  		(1.0, 0.8414709848078965),
  	].all(|(angle, sine)| (angle.sin() - sine).abs() <= 0.0000001)
  ```
- **An `expect` keeps each input beside its expected answer.** A list of
  inputs mapped and compared to a separate list of answers makes the
  reader count positions to pair them:

  ```roc
  expect
  	[{ held: 90, adding: 9 }, { held: 90, adding: 11 }].map(room)
  		== [Fits, Overflows]
  ```

  Write one `expect` per case; where many cases share an answer, check
  the list with `.all`; where many differ, check a list of `(input,
  answer)` pairs:

  ```roc
  expect room({ held: 90, adding: 9 }) == Fits
  expect room({ held: 90, adding: 11 }) == Overflows
  expect ["Steve!", "R2D2"].all(|text| checked_name(text) == Err(ForbiddenCharacter))
  expect
  	[
  		(Class(token("author")), " class=\"author\""),
  		(Required, " required"),
  	].all(|(attr, expected)| attribute(attr) == expected)
  ```

  A tuple or record of results compared to a tuple or record of answers
  has the same fault; write an `and` chain of equalities instead.
- **Tests too large to sit beside the code get their own module,
  `<Module>Spec.roc`:** `CartSpec.roc` tests `Cart.roc`. The hunts read a
  `*Spec.roc` file, or one under `test/`, as tests: its helpers aren't
  judged, and its calls don't count as production's.
- **A rule a type can't express gets a Shale hunt with plants.**
  [Shale](https://github.com/showell/shale) is how we enforce this guide's
  more advanced preferences: what the type checker and `roc fmt` can't see. A
  hunt reads the code as Roc's own parser does (through `roc-ast`, so a
  comment or a string never counts), names each finding `path:line: check:
  why`, and is a question for a reader, not a verdict. Its plants are cases
  it must find and cases it must not, so the hunt itself is tested
  (`self_test=1`). The recipes are in Shale's `cookbook/roc/`, and the ones we
  run are:
  - `name_hunt.shale`, for what [naming](#naming) says: `question`, `negative`,
    `vague`, `name_type`, `short_name`, `bare_participle`, `taken_word`,
    `phrase_name`, `singular_list`, `world_verb`, `where_name`, `container`,
    `preposition_split`, `worker_name` and `stacked_preposition`, and for
    effects `state_effect`, `noun_effect` (an effect that starts with a noun or
    a preposition, `of!`), `command_tense` (a union of tags with no payloads, all
    past tense, `[Pinned, Unpinned]`) and `mixed_tense` (`[Pin, Unpinned]`; a
    `List(T)` argument is judged as `T`). The words are shared files in Shale's
    `cookbook/words/`, and `words=1` lists every first word an effect starts
    with, for a reader to scan;
  - `plain_names.shale`: `pure_mutator`, `abbreviation` and `module_doc`;
  - `vocabulary.shale`, `name_types.shale` and `families.shale`, which take a
    project's own words. `name_types` also holds `no_value` (a constant that
    means "none", `no_frames`) and `bare_beside_unit` (a field that is a bare
    number in one record and a unit in another);
  - `bare_floats.shale`, over the project's table of reasons;
  - `boundaries.shale`: `fixed`, a parameter every production call fills with
    the same literal (context passed down, `me` or `accounts`, is no
    constant); `entry`, the same for a recursion's start; `constant`, a pure
    function of `{}`; `bool_param`, a flag passed as a Bool, which only
    `types=1` can see; `dead`, a function nothing reaches; and `single`, a
    one-caller wrapper of a line or two that no `expect`, twin or `##` doc
    keeps. Safari's gate holds all six, and `unused_api` and `same_branches`
    print as questions;
  - `errors.shale`: `error_alias` (a result's `Try` whose error is a shared
    alias, not its tags in place), `optional_tag` (a tag named as an optional,
    `None` or `Some`), `set_fallback` (`l.set(i, v) ?? l`), `placeholder`
    (`?? "bogus"`) and `number_fallback` (`l.get(i) ?? 0.0`, which no gate
    holds yet);
  - `nest_depth.shale`: a call nested four deep or more, read inside out
    ([layout](#layout-and-formatting)), run with `min=4`;
  - `parens.shale`: `paren_if` (`if (x) a else b`), `wrapped_body`
    (`|x| (...)`), `else_block` (`else { if ... }`) and `lambda_if`
    (`|x| if x > 1 {`), each rewritten by `write=1`
    ([layout](#layout-and-formatting));
  - `stack.shale`: a group on one line that should stack, a stacked group that should sit on one line (`unstack`),
    or a line over 100 columns (`long`; one that only a string literal
    makes long is reported apart as `wide string`, and no gate holds it);
  - `methods.shale`: an old-style `Module.fn(x, ...)` call the compiler accepts as `x.fn(...)`, rewritten by `apply=1`
    ([methods](#make-wrong-values-impossible-to-build)).

  A rule added here that a script can check gets a check, and a gate runs
  it, held at zero findings: a finding fixed by hand and left unchecked
  comes back. How the gates run the hunts, and the rest of the bar every
  change clears, is CLAUDE.md's: §3, "The bar for every change", and §7.
- **A test helper builds its input from the value's own spelling, never
  from a count of steps.** `stem({ name: "Élodie", id: "5" }) == "elodie-5"`
  reads beside its answer; `stem("Élodie", 4)`, meaning the id after four
  `next`s, makes the reader do arithmetic.

## Tools and builds

How we work, as opposed to how the code reads, is in CLAUDE.md: `roc fmt`,
zero warnings and the gate in §3, "The bar for every change", and the dev
backend for every inner loop in §9, "Builds are slow by default".

---

All of these suggestions solely reflect Steve Howell's preferences, but he thanks the Roc community (notramo in particular) for several useful suggestions.
