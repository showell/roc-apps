# JavaScript, in Roc

A subset of JavaScript run by a bytecode VM written in Roc, a web
playground where a program draws on a canvas as it runs, and a corpus that
holds the language to node.

The code here was written by AI coding agents (Claude), with human
supervision.

**Status (2026-11-24):** 54 of 54 corpus programs print what node 22
prints, byte for byte, timers and uncaught throws included, and 44 of 44
programs outside the subset are refused with the message they must give,
on the VM's usual collection schedule and collecting at every allocation.
Eight canvas samples are held to their logs of effects, one of them driven
by scripted clicks alone and one by timers, restarted by a scripted click.
The VM collects its garbage, so js/heaps/'s programs, which make an object
a pass, hold about 1,024 cells and peak near 4 MB on the dev build. In the
release build it runs fib(22) in 106 ms, and its release build takes
110 s. The page builds into the dev channel; the unlisted copy at
roc.lynrummy.com/js/ predates the gaps.

## The subset

Every program in the subset is real JavaScript, so `node` is a free oracle:
what node prints for it is what the interpreter must print.

- **Values:** numbers (F64), strings, booleans, `null`, `undefined`, arrays,
  plain objects, functions, errors, and Maps and Sets.
- **Statements:** `let` and `const` with block scope (a `for` loop's `let`
  is a new variable each pass, as closures see it), `if`, `while`,
  `do ... while`, the C-form `for`, `for ... of` over arrays, strings, Maps,
  Sets and their iterators, `switch` (cases compared by `===`, falling
  through, `default` anywhere), `return`, `break` and `continue`, labelled
  too (`break outer`), `throw` of any value, `try` with `catch (e)`, a
  `catch` pattern or a `catch` with no binding, and `finally`, and function
  declarations, hoisted.
- **Destructuring,** in declarations, assignments, parameters, `catch` and
  `for ... of`: array patterns with holes and rest (`[a, , ...rest]`),
  object patterns with renames, defaults and rest (`{ x, y: why = 2,
  ...others }`), nested; and default and rest parameters (`function f(a,
  b = a + 1, ...more)`).
- **Expressions:** arithmetic and `**`; `<`, `>`, `<=`, `>=` on numbers or on
  strings; `===` and `!==`; `&&`, `||`, `??`, `!`, `?:` and `typeof`;
  assignment, the compound assignments, the logical ones (`??=`, `||=`,
  `&&=`) and `++` and `--`; property and index access, and optional
  chains (`a?.b`, `a?.[k]`, `f?.()`); calls; `new` of the builtin
  constructors below; arrow functions and function expressions, closures
  included; array and object literals (with shorthand properties, methods
  and spread, `{ ...o }`); template strings; and spread (`...`) of anything
  iterable into an array literal or a call's arguments. `+` joins when
  either side is a string, an array or an object, as in JavaScript.
- **Errors:** the interpreter's own errors are JavaScript's, caught by
  `catch` with node's `name` and `message` (`TypeError: Cannot read
  properties of null (reading 'x')`, `o.f is not a function`,
  `ReferenceError: x is not defined`, `RangeError: Maximum call stack size
  exceeded`). `new Error(message)`, and `TypeError`, `RangeError`,
  `ReferenceError` and `SyntaxError` the same way, make one. A throw nothing
  catches ends the run as node ends it, a timer's and a click's included:
  js-vm prints `Uncaught <the first line node prints of what was thrown>
  (line <n>)` and exits 1 (js/oracle.shale writes node's own report, its
  stack and all, as that line).
- **Builtins:** `console.log`, formatted as node formats the subset's
  values (line breaks past 80 columns, grouped columns for long arrays,
  depth 2, the quoting rules, `Map(2) { 'a' => 1 }` and `Set(1) { 1 }`);
  `Math`'s `floor`, `ceil`, `round`, `trunc`, `abs`, `sign`, `sqrt`, `pow`,
  `min`, `max`, `sin`, `cos`, `tan`, `atan`, `PI` and `E`; arrays'
  `length`, `push`, `pop`, `shift`, `unshift`, `splice`, `join`, `indexOf`,
  `lastIndexOf`, `includes`, `at`, `slice`, `concat`, `reverse`, `sort`,
  `fill`, `flat`, `flatMap`, `forEach`, `map`, `filter`, `some`, `every`,
  `find`, `findIndex`, `findLast`, `findLastIndex`, `reduce`,
  `reduceRight`, `keys`, `values` and `entries`; strings' `length`,
  indexing, `charAt`, `charCodeAt`, `at`, `indexOf`, `lastIndexOf`,
  `includes`, `startsWith`, `endsWith`, `slice`, `substring`,
  `toUpperCase`, `toLowerCase`, `trim`, `trimStart`, `trimEnd`, `split`
  (with a limit), `replace` and `replaceAll` (a string by a string),
  `repeat`, `padStart`, `padEnd` and `concat`; `new Map(entries)` and `new
  Set(values)`, with `get`, `set`, `add`, `has`, `delete`, `clear`,
  `size`, `forEach`, `keys`, `values` and `entries`, keys compared as
  SameValueZero and kept in the order first set; `Object.keys`, `values`
  and `entries`; `String(x)` and `String.fromCharCode`; `Array.isArray`,
  `Array.from` (an iterable, or an object with a `length`, with a mapper)
  and `Array.of`; `Number.isInteger`; and the timers, `setTimeout(f, ms)`,
  `setInterval(f, ms)`, `clearTimeout(timer)` and `clearInterval(timer)`,
  on a virtual clock (below).
- **Timers run after the program, in the order node runs them.** Each is
  due `ms` after the moment it was set (a delay below 1, or left out, is
  1 ms, as node makes it), and they run earliest first, two at one time in
  the order they were set. The clock is virtual: it reads 0 while the
  program runs and moves to each callback's time as it runs, so a
  program's output is the same on every run, and the same as node's
  (`js/tests/36-timeouts.js` to `38-nested-timeouts.js`). js-vm runs
  callbacks until none is left; an interval never cleared, which node runs
  for good, stops at 100,000 callbacks with a message saying so.
- **Out of it:** `this`, `new` on a function of the program, prototypes and
  classes (below), getters and setters, `==` and the other coercions (`"3"
  * 2`, `true + 1`), `var`, `eval`, regular expressions, `in` and
  `instanceof`, computed property names, async and modules; printing an
  error (node prints its stack) or an iterator, an iterator's `next`, a
  Map's or a Set's method read outside a call; `startsWith` and `endsWith`
  from a position, a replacement with `$` patterns or a function,
  `localeCompare`, and the number methods (`toFixed`); a timer's arguments
  after its delay, and printing or reading a timer (node's is an object it
  prints; ours is a handle `clearTimeout` takes, and nothing else); two
  parameters of one name, and a function declared as the lone body of an
  `if`, a `while` or a `for`. A name declared twice in one scope, a `let` or
  `const` as such a lone body, a `break` or a `continue` with nothing to
  leave, and a destructuring with no value are refused as node refuses
  them, with its SyntaxError.
- **Why `this`, `new` and classes stay out:** `this` is bound by how a
  function is called (a method call, a plain call, which in node's sloppy
  mode binds the global object the subset has no value for, a callback a
  builtin makes, a timer's), and taken from around it by an arrow, so every
  call path would carry a receiver; `new` with `prototype` methods needs an
  object to link to its prototype, every property read to walk that link
  and every listing (`Object.keys`, spread, console.log's `Point { x: 1 }`)
  to tell its own properties from inherited ones, and functions to carry
  properties; and classes are mostly used with `extends` and `super`, on
  top of all that. None of it is a small step.

**A program outside the subset gets an error that names what it used,
never a wrong answer.** The parser refuses the forms it can see (`js:
unsupported: classes (line 1, column 1)`), and the interpreter stops at the
ones only a run shows (`js: unsupported: an operator on a string and a
number (a coercion) (line 2)`). A position-counting string method on
non-ASCII text is one of these: JavaScript counts UTF-16 units, and the
interpreter's strings are UTF-8.

## The canvas playground

The page's programs have a few builtins of our own beside JavaScript's: the
canvas library (`Ast.Library`'s `Canvas`). They take p5.js's names, but they
are a small set of our own with no promise of p5.js's behaviour, and the
page lists them:

- **Shapes:** `background(color)`, `fill(color)`, `noFill()`,
  `stroke(color, width)`, `noStroke()`, `line(x1, y1, x2, y2)`,
  `rect(x, y, w, h)`, `circle(x, y, r)`, `ellipse(x, y, rx, ry)`,
  `polygon([[x, y], ...])` and `text(words, x, y, size)`, on a 400 by 400
  canvas with its origin at the top left. Colors are CSS color strings.
- **A turtle:** `forward(n)`, `back(n)`, `turn(degrees)` (clockwise),
  `penUp()`, `penDown()` and `goto(x, y)`. It starts in the middle, facing
  up; each move with the pen down is one `line`.
- **Input:** `mouseX()`, `mouseY()` and `keyIsDown(key)`, read when called,
  and `onClick((x, y) => { ... })`, a handler called with each click on the
  canvas, in canvas units, in the next frame. A second `onClick` replaces
  the first.
- **A frame loop:** a program that declares `function frame(t)` has it
  called 30 times a second, `t` being the frame's number over 30.

**The second sample, "all features,"** is the corpus program
`js/tests/54-big-daddy.js`, which js/build.shale writes into the page's list,
so node holds it: a day in a little city that uses every feature of the
subset, in stages (a census parsed from text, a clerk's lookups that fail, a
merge sort, Dijkstra's shortest walks, a prime sieve, a word count and an
evening on the timers), each printing a checksum. Its `SIZE` scales the work;
at its default, 5, node takes about 55 ms of CPU, 40 of them node's own start.

**One queue, one clock.** A timer's callback, a click and the next
`frame(t)` are each an event on the interpreter's queue (`Events.Queue`),
due at a time on its virtual clock. The page ticks the clock a frame at a
time (`Vm.tick!`), to the frame's own time, and each tick runs what is
due by then: the clicks queued since the last tick, then the timers and the
frame in the order of their times. So `frame(t)` is a convenience on the
same queue, and on the page a timer runs in the frame of its time, 30 to a
second. A program runs on for as long as something waits (an event queued,
or a click handler), and the page stops calling it when nothing does.

**Drawing is an effect, made when the program calls for it.** The
interpreter hands each effect to its host (`Canvas.Host`, a record of three
effectful functions: `emit!`, `pointer!` and `key!`) at the moment the
program makes it, in program order, `console.log` included. So a draw, a
log and another draw reach the host in that order, and a program that
stops halfway has drawn what it drew before the stop. A read is asked of
the host when the program asks for it.

Each effect has one written form, a line (`Canvas.line_of`), and there are
three hosts:

- **The page's** (js/wasm, `JsApp.roc`): the platform's hosted functions
  (`js/wasm/platform/Host.roc`) call into the page's JavaScript while the
  Roc call runs, and `js_page.js` paints each line as it arrives; the
  browser shows the canvas when the call returns.
- **The recording host,** `js-canvas` (`JsCanvas.roc`): every effect and
  every read a line, with a line `frame <n> <t>` before each tick. The
  pointer rests at the middle; an argument says which keys are down in
  each frame, and another where the canvas is clicked before which frame,
  each click a line `click <x> <y>`.
- **js-vm's,** on the core library: a log is printed as it is made, and
  nothing else can happen.

**A canvas builtin isn't node's, so the samples have an oracle of their
own:** `js/canvas.shale` holds each sample in `js/canvas/` to its golden log
(`<name>.log`) for the frames, keys and clicks `js/canvas/goldens.txt`
names, and `page_check.mjs` holds the wasm to the same logs. A log moves only by
`freeze=<name>`, with every moved line explained in the commit.

**The rails.** The program before its first frame may run 3,000,000
steps and make 20,000 effects, and each frame 300,000 and 20,000
(`Canvas.run_limits`, `Canvas.frame_limits`); past either, the run stops with
a message that names the budget. A frame's budget covers all its tick runs:
its clicks, its timers and its `frame(t)`. The program's own scope outlives its last
statement (`Vm.start!`), as a page keeps a script's, so each frame sees
the variables it declared.

## Laying it out

The interpreter is `js/roc/`: `Lexer.roc` makes tokens with their lines and
columns, `Parser.roc` reads them into `Ast.roc`'s tree by recursive descent,
laying out each scope's names, and `Resolve.roc` places every name read or
written in those layouts before the run. `Compile.roc` makes each function
a list of `Bytecode.roc`'s instructions, `Vm.roc` runs them, and
`Collector.roc` frees the cells its roots don't reach. `ValueRules.roc`
holds the rules JavaScript's values follow, `Events.roc` the queue of
callbacks and its virtual clock, `Heap.roc` what JavaScript shares by
reference, `Inspect.roc` console.log's formatting (node's `util.inspect`,
function for function), and `NumberText.roc` writes a number as `String(n)`
does. `Canvas.roc` is the canvas library: its effects, their written form,
the turtle and the host's type. `JsVm.roc` is `js-vm`, the command;
`JsCanvas.roc` is `js-canvas`, the recording host. `JsApp.roc` is the page's
wasm module, on the platform and host in `js/wasm/`; `js/web/` is the page.

## The bytecode VM

The VM puts every value a program holds into its machine, so a collector
can find them all, and each instruction's handler is a small function of
its own, so no one function grows with the language.

- **The pipeline:** the lexer, the parser and `Resolve`, then `Compile`,
  which lays out each function's frame and makes its code, then `Vm`, a
  stack machine whose loop only fetches and dispatches.
- **Frames are slots on the operand stack,** a call's parameters, its
  blocks' and loops' variables, and the boxes it captures, each named by its
  place from the frame's base; callers wait in `frames`. A variable of a
  scope with a function literal inside (`Ast.Capture`) lives in a box, a
  heap cell (`Heap.Cell`'s `Variable`) its frame and its closures share; a
  closure's `Fun` cell names an `Environment` cell, its code and the boxes
  it captures. A `for` loop whose body makes closures gives each pass a
  fresh box. So the roots a collector needs are the live stack, the frames
  and the cells, all data.
- **The collector marks from the machine and sweeps onto a free list**
  (`Collector.roc`, `Vm.roots`). Its roots are the stack up to its top
  (each frame's slots, its boxes and the function it runs, a caller's
  half-made values, a `finally`'s held throw), the builtins, a throw on its
  way to a handler and the event queue's callbacks. It runs before an
  instruction, once no cell is free and the heap holds twice what the last
  collection kept (never under 1,024 cells), so a cell costs amortized
  O(1). Between instructions no value lives in Roc's own locals, but for a
  builtin that runs a callback: what it keeps across the callback (the
  item `filter` keeps, the items `sort` orders) waits on the stack. A freed
  cell stays in its place as a link of the free list, so a reference never
  moves; the value rules allocate from the same list (`Heap.allocated`).
  `js-vm --collect-at-every-allocation` collects after every instruction
  that allocates, and `js/tests/51` to `53` hold values through each kind
  of root while collections run, so a missed root shows as a wrong answer
  or as the collector's own stop (a live value naming a freed cell).
- **Control flow is jumps,** relative to the instruction after them; a loop
  makes its own `break`s and `continue`s jumps once it knows its end.
- **A read before a declaration is decided when compiling** wherever it can
  be: in the declaring function, a read written before the declaration
  always runs before it (a block's scope starts afresh each time), so it
  compiles to its ReferenceError, and only a read through a box checks at
  run time.
- **The value rules live in a module of their own.** A property read, an
  operator on mixed values, a string method, a builtin that calls nothing
  back, and the messages they make live once, in `ValueRules`; the VM's
  fast paths settle the common cases (numbers, an object's own property,
  an array's item) and hand the rest to the rule. A rule takes a machine of
  the cells and a status (`ValueRules.Machine`), and the VM lends it its
  cells and puts back what it gives (`Vm.lent`, `Vm.shell`), so the cells
  have one owner while the rule writes them. A rule generic over the VM's
  whole machine (an open record) would need no lending, but the dev build
  copies the cells a rule writes through one, so the controls would see a
  copy a write.
- **A builtin that calls back runs the loop again** (`forEach`, `map`,
  `sort` and their kin, `Array.from` with a mapper): it pushes the function
  and its arguments, runs until that frame returns, and takes the answer off
  the stack, the receiver and the array being built waiting on the stack.
- **A `try` pushes a handler, which is data:** its frame, where its
  `catch` or `finally` starts and how high the stack stood. A throw lands at
  the innermost one, the frames and the stack above it given up. A
  `break`, a `continue` or a `return` that leaves a `try` runs its
  `finally` on the way, compiled where it stands.
- **The callbacks go through one queue** (`Events.roc`): the VM queues a
  timer, a click and the canvas's `frame(t)` by its rules and, once the
  program finishes, its own frame kept at the bottom of the stack
  (`Vm.start!`), runs each in turn on the same virtual clock: all of them,
  as js-vm does, or those due by a frame's time (`Vm.tick!`), as the page
  does.
- **Steps** count calls and loop passes, not statements; js-vm's budget is
  200,000,000.

**What the dev controls show (2026-11-24, `js/controls.shale opt=dev`,
held to `js/controls/expected-dev.txt`):** every control flat: 0, 1, 1, 0,
1, 2, 2, 4.08 and 3.04 allocations a pass for 00 to 08. 08-garbage-in-a-call
makes an object a pass inside a call; its 0.04 is the collector's own
lists, made once a collection. The one a call makes is a list of 112 bytes,
the same at every size, which roc-alloc-trace's `where` puts down to
`Vm.pushed`; rewriting the write three ways didn't move it. On the dev
backend fib(22) takes about 860 ms of CPU (best of three, with the
collector's check before every instruction).

**What the release build shows (2026-11-24, `js/bench`'s programs, the
fastest of five, a quiet box):** fib(22) takes 106 ms, and the loops
497 ms. The release controls (`js/controls.shale`, held to
`expected.txt`) allocate nothing a pass but a call's argument list, a Map
key's identity and a new object's property list. js-vm's release build
takes 110 s. `memcpy` is 11% of fib's time; the next inline field of the
machine to box is still to find (the collector's schedule, boxed, changed
nothing).

**The machine keeps its event queue in a box.** Every instruction hands
the machine back, so whatever the machine holds inline is copied on each
one; only a timer's or a click's instruction touches the queue. Inline, the
queue made fib(22) take 123 ms, a sixth of it in `memcpy`.

## Why the heap is one value

JavaScript shares arrays, objects and closures by reference: two variables
that hold one array see each other's writes. Roc has only values. So the
interpreter keeps everything JavaScript shares in one Roc value, the heap, a
list of cells (an object, an array, a closure, a builtin, an error, a Map, a
Set, an iterator, a captured variable's box, a closure's environment) named
by index, and a JavaScript reference is that index. The machine
(`Vm.Machine`: the heap, the operand stack, the frames, the handlers, the
step count) is handed to each instruction's handler, which answers it back.

**Roc writes a list in place only while nothing else refers to it, so one
stray reference to the heap makes every write copy the whole heap.** The
shapes that keep it unique, each with a comment where it is used:

- **A cell is written by `List.update`** (`Heap.with_property` and its
  siblings), which hands its function the cell with nothing else referring
  to it, so the props or items are written in place. The dev build boxes
  the function's capture, one small allocation a write (not a copy), which
  the dev controls name; the release build makes none.
- **A writer is handed the list straight from the record it updates,**
  `{ ..machine, cells: Heap.with_property(machine.cells, ...) }`.
- **Every result is taken apart where it is answered,** `{ machine: ruled,
  value } = got`. A result kept whole for its value keeps its machine too,
  and each write made while it lives copies.
- **A writer asks what a cell is (`ValueRules.kind_of`), and never matches the
  cell out of the heap:** the matched cell is a second reference to its
  items for as long as the arm runs.
- **The write inside a taken-out cell is a function of its own**
  (`Heap.items_with`). Written inline in the match arm, beside a binding, a
  store into an array of N items copies the N items.
- **A place the stack gives up is cleared.** The stack never shrinks: a
  pop lowers `top` and writes `Null` where the value was, so no value left
  above `top` is a second reference to a string or a list.
- **`s += e` on a string grows the string where the slot holds it**
  (`Vm.local_appended`), so a string built one piece at a time is not
  copied per piece.
- **A Map's or a Set's table sits in a list of one in its cell,** so every
  cell stays an object's size while `List.update` still writes the table
  in place (`Heap.with_entry`).
- **A helper that may write hands the machine back whatever it finds**
  (`ValueRules.iterated`): a caller that kept its own machine for the case
  of a value that isn't iterable held a second reference while the helper
  wrote, and the write copied the heap.
- **No closure captures the machine;** a loop over it is a `var $st` loop.
- **The host is an argument of its own, never a field of the machine.**
  Following BASIC's workhorse pattern, the handlers take several arguments
  (`host`, then the program, then the machine, then the rest) where one
  record would do: a record holding the machine is a second reference to
  the heap for as long as it lives. The host refers to nothing of the
  machine, so carrying it costs nothing.

**A variable is read by its place, never by its name.** `Resolve` gives
every name a slot (how many scopes out, and where there), and `Compile`
turns each into a slot of the frame or a box the frame holds. Reading a
local is an index into the stack from the frame's base.

**The VM collects** (`js/heaps.shale`): on its dev build (`js/heaps.shale
opt=dev`, 2026-11-24) each js/heaps/ program,
`heaps/2-object-a-pass-in-a-call.js` included, holds 1,024 cells and peaks
at about 4 MB. A caller's half-made values (the left side of a `+`, the
arguments made so far, the object a method is called on) wait on the
operand stack, where the collector sees them, so it collects anywhere
between two instructions ("The bytecode VM", above).

**What the controls count.** `js/controls.shale` runs each control in
`js/controls/` (an empty loop, then the probes' six writes, one each, a
Map's write and garbage made in a call) at 1,000 and 10,000 passes on
`tools/alloc_ladder.shale`, which counts `roc_alloc`'s calls exactly, and
holds what one pass allocates to `js/controls/expected.txt` (release) and
`expected-dev.txt` (dev). A copy is an allocation a pass, so a write that
stops being made in place turns a control red by name.

**What the probes say (2026-11-24, the dev backend, nothing else heavy
running).** Each write's cost, at three sizes, in CPU time, so rough:

| probe | µs a write | at N = | shape |
|---|---|---|---|
| a property write beside N objects | 14, 12, 12 | 2,000, 4,000, 8,000 | flat |
| N pushes onto one array | 16, 16, 14 | 20,000, 80,000, 160,000 | flat |
| a store into an array of N items | 18, 16, 16 | 2,000, 4,000, 8,000 | flat |
| a string built by N appends | 11, 11, 12 | 20,000, 80,000, 160,000 | flat |
| a closure's variable, N closures beside it | 18, 25, 17 | 2,000, 4,000, 8,000 | flat |
| a push and a pop on an array of N items | 22, 28, 19 | 2,000, 4,000, 8,000 | flat |

## Running it and the tests

    shale js/oracle.shale      # js-vm, then every program through node and js-vm
    shale js/oracle.shale collect=every   # js-vm collecting at every allocation
    shale js/probes.shale      # js-vm, then the copying probes at three sizes
    shale js/controls.shale    # js-vm --opt=speed, then count each control's allocations
    shale js/controls.shale opt=dev   # the same on the dev build, held to expected-dev.txt
    shale check.shale js=1     # the controls in both builds, held to their expected counts
    shale js/bench.shale       # both builds, then time js/bench/'s programs
    shale js/heaps.shale       # js-vm --opt=speed, then each program's cells, live cells, collections and peak memory
    shale js/canvas.shale      # js-canvas, then hold every canvas sample to its log
    shale js/build.shale       # build the page into the dev channel, :9210/js/

Each script but the last takes its commands from tools/roc_build.shale
(`js/js_builds.shale`'s `js_build`), which builds one only when its cache
holds no build of the same inputs: a second run of unchanged code compiles
nothing, and its line says `reused`. js/build.shale builds the page's wasm
itself.

and, with the page built, to see it draw in headless Chromium:

    node js/page_shots.mjs http://localhost:9210/js/ <dir> "turtle spiral" 1
    node js/page_shots.mjs http://localhost:9210/js/ <dir> "Click to place" 0 click:100:120,300:90
    node js/page_shots.mjs http://localhost:9210/js/ <dir> "Click to place" 0 click:100:120 width:390

Each run shoots the sample first as picked, before Run (`before.png`),
where the page shows only a line saying the program hasn't run: no canvas
and no console until Run, and again after a pick or an edit. Stop leaves
what was drawn in view.

`js/oracle.shale` is a tier of `check.shale`. It builds `js-vm` on the dev
backend and runs each program in `js/tests/` through node and through
`js-vm`; the two transcripts, exit codes included, must match. Each
program in `js/tests/refused/` names in its first line (`// refused:
<text>`) what `js-vm`'s last line must say. Nothing is skipped: the run
fails unless every program passes.

`js/canvas.shale` is a tier of `check.shale` too.

`js/build.shale` builds `JsApp.roc` into a wasm32 archive, links it with
Zig 0.16 and `js/wasm/host.zig` into `js.wasm`, writes `js_samples.js` from
`js/canvas/`, and replaces the page only after `js/page_check.mjs` passes.
Every file but `index.html` is named by its bytes (`js_page.<hash>.js`,
`js.<hash>.wasm`, the first 16 hex digits of its sha256), each file's
references to the others rewritten first, so a deploy can't leave a browser
running a stale script beside a new page; the check finds the files from
`index.html` as a browser does, and fails on a name that leads nowhere or a
file nothing names. The check drives the page's own `js_runner.js` and `js_page.js` under node:
it holds the wasm to node on every corpus program and refusal (ticking each
program's clock as the page does, so its timers run, and node's timers
waited for), to the golden logs on every canvas sample, and runs every sample on the page, each
shown from its top. Unlike BASIC's host, this one needs no checkout
of the Roc compiler's source: the Roc hands it its buffers, takes back each
line it emitted (`drop_bytes`) and keeps the run in one box, so the host
never lays out a Roc list itself.

`js/probes.shale` is a first look at what a write copies: each probe in
`js/probes/` is timed at three sizes, and a write's cost that stays flat
across them is a write in place.

## Pitfalls

- **`js-vm` takes the program as an argument,** so a program is held to
  the kernel's limit on one argument (128 KiB).
- **The page runs a program on the browser's main thread,** held to the
  rails above so a loop that never ends stops with a message rather than
  freezing the tab. js-canvas on the dev backend takes about 2.0 s of CPU
  to run a frame out of its 300,000 steps, and 8.8 s for a program out of
  its 3,000,000 (`js/canvas/rails/`, 2026-11-24), so a frame near its
  budget slows the loop well below 30 a second before it stops it.
- **A turtle's trigonometry is exact only on the square headings,** so a
  turtle that walks a square ends where it began; at any other heading its
  positions carry a float's rounding, and the logs show it.
- **The VM throws a RangeError at 400 nested calls**
  (`ValueRules.max_depth`), where node goes much deeper.
- **Built on the dev backend,** js-vm runs `fib(22)` in about 0.86 s of
  CPU, and in about 0.11 s in the release build (2026-11-24). Its release
  build takes about two minutes on a 2-core box, so a round takes its
  release numbers once, never per step. The dev backend shows the code's
  shape, which is what the probes look at; a release build is for
  measuring speed.
- **A Map or a Set keeps a place for every key it ever held.** A deleted
  entry stays, `Gone`, so a walk under way still meets the rest in order,
  and is never reused: a table many keys pass through grows with them.
