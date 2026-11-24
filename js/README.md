# JavaScript, in Roc

A subset of JavaScript run by a tree-walking interpreter written in Roc, a
bytecode VM growing beside it, a web playground where a program draws on a
canvas as it runs, and a corpus that holds the language to node.

The code here was written by AI coding agents (Claude), with human
supervision.

**Status (2026-11-24): the language gaps closed.** 50 of 50
corpus programs print what node 22 prints, byte for byte, timers and
uncaught throws included, and 44 of 44 programs outside the subset are
refused with the message they must give. Eight canvas samples are held to
their logs of effects, one of them driven by scripted clicks alone and one
by timers, restarted by a scripted click. The page builds into the dev
channel; the unlisted copy at roc.lynrummy.com/js/ predates the gaps.

**The bytecode VM's first round (2026-11-24):** `js-vm` runs 37 of the 50
corpus programs as node does and refuses the other 13, each for something
the round leaves out, with no wrong answer; 39 of the 44 programs outside
the subset get the message they must, and the other 5 meet a refusal of
the VM's first ("The bytecode VM", below).

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
  js-run prints `Uncaught <the first line node prints of what was thrown>
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
  (`js/tests/36-timeouts.js` to `38-nested-timeouts.js`). js-run runs
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

**One queue, one clock.** A timer's callback, a click and the next
`frame(t)` are each an event on the interpreter's queue (`Interp.Events`),
due at a time on its virtual clock. The page ticks the clock a frame at a
time (`Interp.tick!`), to the frame's own time, and each tick runs what is
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
  Roc call runs. At full speed `js_page.js` paints each line as it arrives;
  in slow motion it holds a call's lines in order and shows them one or ten
  marks at a time, since a wasm call can't give the browser a turn halfway.
  The next frame is called only once they are all shown.
- **The recording host,** `js-canvas` (`JsCanvas.roc`): every effect and
  every read a line, with a line `frame <n> <t>` before each tick. The
  pointer rests at the middle; an argument says which keys are down in
  each frame, and another where the canvas is clicked before which frame,
  each click a line `click <x> <y>`.
- **js-run's and js-count's,** on the core library: a log is printed as it
  is made, and nothing else can happen.

**A canvas builtin isn't node's, so the samples have an oracle of their
own:** `js/canvas.shale` holds each sample in `js/canvas/` to its golden log
(`<name>.log`) for the frames, keys and clicks `js/canvas/goldens.txt`
names, and `page_check.mjs` holds the wasm to the same logs. A log moves only by
`freeze=<name>`, with every moved line explained in the commit.

**The rails.** The program before its first frame may run 3,000,000
statements and make 20,000 effects, and each frame 300,000 and 20,000
(`Canvas.run_limits`, `Canvas.frame_limits`); past either, the run stops with
a message that names the budget. A frame's budget covers all its tick runs:
its clicks, its timers and its `frame(t)`. The program's own scope outlives its last
statement (`Interp.start!`), as a page keeps a script's, so each frame sees
the variables it declared.

## Laying it out

The interpreter is `js/roc/`: `Lexer.roc` makes tokens with their lines and
columns, `Parser.roc` reads them into `Ast.roc`'s tree by recursive descent,
laying out each scope's names, `Resolve.roc` places every name read or
written in those layouts before the run, `Interp.roc` walks it, `Heap.roc` holds what JavaScript shares by
reference, `Inspect.roc` is console.log's formatting (node's `util.inspect`,
function for function), and `NumberText.roc` writes a number as `String(n)`
does. The VM takes the same resolved tree: `Compile.roc` makes each
function a list of `Bytecode.roc`'s instructions, `Vm.roc` runs them, and
`JsVm.roc` is `js-vm`, js-run's command on the VM. `Canvas.roc` is the canvas library: its effects, their written form,
the turtle and the host's type. `JsRun.roc` is `js-run`, the command;
`JsCount.roc` is `js-count`, the same run followed by its counts;
`JsCanvas.roc` is `js-canvas`, the recording host. `JsApp.roc` is the page's
wasm module, on the platform and host in `js/wasm/`; `js/web/` is the page.

## The bytecode VM

The tree walker keeps half-made values on Roc's own stack and grows with
the language in a few huge functions, so it can't be collected and builds
slowly. The VM puts every value a program holds into its machine, and each
instruction's handler is a small function of its own. It runs beside the
walker, held by the same oracle, until it runs everything; it never falls
back on the walker.

- **The pipeline:** the lexer, the parser and `Resolve` as they are, then
  `Compile`, which lays out each function's frame and makes its code, then
  `Vm`, a stack machine whose loop only fetches and dispatches.
- **Frames are slots on the operand stack,** a call's parameters, its
  blocks' and loops' variables, and the boxes it captures, each named by its
  place from the frame's base; callers wait in `frames`. A variable of a
  scope with a function literal inside (`Ast.Capture`) lives in a box, a
  heap cell (`Heap.Cell`'s `Variable`) its frame and its closures share; a
  closure's `Fun` cell names an `Environment` cell, its code and the boxes
  it captures. A `for` loop whose body makes closures gives each pass a
  fresh box. So the roots a collector needs are the live stack, the frames
  and the cells, all data.
- **Control flow is jumps,** relative to the instruction after them; a loop
  makes its own `break`s and `continue`s jumps once it knows its end.
- **A read before a declaration is decided when compiling** wherever it can
  be: in the declaring function, a read written before the declaration
  always runs before it (a block's scope starts afresh each time), so it
  compiles to its ReferenceError, and only a read through a box checks at
  run time.
- **The value rules are the walker's.** A property read, an operator on
  mixed values, a string method, a builtin that calls nothing back, and the
  messages they make live once, in `Interp`; the VM's fast paths settle the
  common cases (numbers, an object's own property, an array's item) and hand
  the rest to `Interp`'s rule inside a walker machine holding only the
  cells (`Vm.shell`). None of those rules walks the tree.
- **A builtin that calls back runs the loop again** (`forEach`, `map`,
  `sort` and their kin, `Array.from` with a mapper): it pushes the function
  and its arguments, runs until that frame returns, and takes the answer off
  the stack, the receiver and the array being built waiting on the stack.
- **The round leaves out** `try` and `catch` (a throw ends the run, as an
  uncaught one), `switch`, labels, destructuring and patterned parameters,
  optional chains, Map and Set methods, `for ... of` over anything but an
  array or a string, timers and the canvas. Each stops the run with `js:
  unsupported (vm): <what>`, when compiling where the tree shows it.
- **Steps** count calls and loop passes, not statements; js-vm's budget is
  js-run's, 200,000,000.

**What the dev controls show (2026-11-24, `js/controls.shale opt=dev
engine=vm`, a report):** every control flat, and none above the walker's
dev count: 0, 1, 1, 0, 1, 2 and 2 allocations a pass for 00 to 06 (the
walker's 1, 1, 3, 0, 1, 3 and 5); 07-map-set is refused. The one a call
makes is a list the dev build copies when a frame is entered, by
roc-alloc-trace's `where`, which names `frames_with` (the lines it gives
aren't Vm.roc's); rewriting the write three ways didn't move it. On the dev backend fib(22)
takes about 660 ms of CPU against the walker's 600, and the loops 2.4 s
against 2.8 s; the release build isn't measured yet.

## Why the heap is one value

JavaScript shares arrays, objects and closures by reference: two variables
that hold one array see each other's writes. Roc has only values. So the
interpreter keeps everything JavaScript shares in one Roc value, the heap, a
list of cells (an object, an array, a closure, a builtin, an error, a Map, a
Set, an iterator) named by index,
and a JavaScript reference is that index. Scopes are a second list, because
a closure holds on to the scope it was made in and must see later writes to
it. The machine (`Interp.Machine`: the heap, the scopes, the output, the step
count) is threaded through the walk the way BASIC threads its machine: each
evaluation takes it and answers it back beside its value.

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
- **Every result is taken apart where it is answered,** `{ machine: after,
  value } = Interp.evaluate(machine, expression)`. A result kept whole for its value keeps its
  machine too, and each write made while it lives copies. Before this rule,
  a store into an array copied the array, and a closure's `++c` copied
  every scope.
- **A writer asks what a cell is (`Interp.kind_of`), and never matches the
  cell out of the heap:** the matched cell is a second reference to its
  items for as long as the arm runs.
- **The write inside a taken-out cell or scope is a function of its own**
  (`Heap.items_with`, `Interp.scope_with_variable`). Written inline in the match
  arm, beside a binding, a store into an array of N items copied the N
  items.
- **The scope list is a stack whose dropped slots are reused,** and it
  never shrinks: in the dev build, `List.drop_last` answers a sublist and
  the next append to it copies the whole list, so a closure's call, beside
  N scopes other closures keep alive, cost N. The release build appends in
  place there; the dev build's controls catch the copy (02-closure-call
  goes from 3 allocations a pass to 4).
- **`s += e` on a string, with an `e` that can't change `s`, grows the
  string where the variable holds it** (`Interp.appended_name`), so a
  string built one piece at a time is not copied per piece.
- **A Map's or a Set's table sits in a list of one in its cell,** so every
  cell stays an object's size while `List.update` still writes the table
  in place (`Heap.with_entry`).
- **A helper that may write hands the machine back whatever it finds**
  (`Interp.iterated`, `walked_of`): a caller that kept its own machine for
  the case of a value that isn't iterable held a second reference while the
  helper wrote, and the write copied the heap.
- **No closure captures the machine;** a loop over it is a `var $st` loop.
- **The host is an argument of its own, never a field of the machine.**
  Following BASIC's workhorse pattern, the walk's functions take several
  arguments (`host`, then the machine, then the rest) where one record
  would do: a record holding the machine is a second reference to the heap
  for as long as it lives. The host refers to nothing of the machine, so
  carrying it costs nothing.

**A variable is read by its place, never by its name.** Each scope (a
block that declares, a C-form `for`, a `for ... of` pass, a call) is made
with the variables its layout names, unready until their declarations run,
and `Resolve` gives every name a slot: how many scopes out, and where
there. Reading `fib` inside `fib` is two hops and a list index, where it was
a comparison with every name in every scope on the way.

A block or function whose text holds no function literal can't have its
scope captured, so its scope is dropped when it ends: a loop or a recursion
without closures leaves the scope list as it found it.

**Cells are never freed, and a collector isn't worth it yet**
(`js/heaps.shale`, 2026-11-23, the release build). No corpus program holds
more than 226 cells or peaks past 9 MB. A program that makes an object a
pass holds them all: 400,000 objects peak at 146 MB, about 370 bytes each,
the cell list and its growth about half of it and the objects' properties
the rest. A closure's definition is boxed in the tree, so a closure's cell
is no bigger than an object's; unboxed, every cell was the size of the
biggest, and the same program peaked at 239 MB.

The simple collector, a mark from the live scopes and a sweep onto a free
list, is safe only where no JavaScript value lives on Roc's own stack: at a
statement outside every call, with any `for ... of` array pinned. Inside a
call, the caller's half-made values (the left side of a `+`, the arguments
made so far, the object a method is called on) live only on Roc's stack,
and a collection there would free them. So it would free what a top-level
loop drops (`heaps/1-object-a-pass.js`) and nothing a call drops
(`heaps/2-object-a-pass-in-a-call.js`, the same garbage inside `main()`,
146 MB too), which is where most programs make theirs. Freeing inside calls
takes a root stack that each of those places pushes to, a full collector's
cost and risk. The page's budget of 3,000,000 steps caps a run near a
million objects, about 370 MB.

**What the controls count (2026-11-23).** `js/controls.shale` runs each
control in `js/controls/` (an empty loop, then the probes' six writes, one
each, and a Map's write) at 1,000 and 10,000 passes on `tools/alloc_ladder.shale`, which counts
`roc_alloc`'s calls exactly, and holds what one pass allocates to
`js/controls/expected.txt` (release) and `expected-dev.txt` (dev). In the
release build every control allocates nothing a pass but a push, which
makes its argument list, and the Map's write, which makes its argument list
and its key's identity text. A copy is an allocation a pass, so a write that
stops being made in place turns a control red by name.

**What the probes say (2026-11-23, the dev backend; the box was quiet when
the run began, and the BASIC lane's controls had started by its end).**
Each write's cost, at three sizes, in CPU time, so rough:

| probe | µs a write | at N = | shape |
|---|---|---|---|
| a property write beside N objects | 14, 14, 12 | 2,000, 4,000, 8,000 | flat |
| N pushes onto one array | 12, 13, 14 | 20,000, 80,000, 160,000 | flat |
| a store into an array of N items | 17, 15, 17 | 2,000, 4,000, 8,000 | flat |
| a string built by N appends | 11, 11, 11 | 20,000, 80,000, 160,000 | flat |
| a closure's variable, N closures beside it | 18, 17, 18 | 2,000, 4,000, 8,000 | flat |
| a push and a pop on an array of N items | 20, 20, 19 | 2,000, 4,000, 8,000 | flat |

Before the shapes above, the array store, the closure and the string were
linear: 59, 88 and 184 µs a store; 28, 35 and 86 µs a call; 22, 35 and
49 µs an append.

## Running it and the tests

    shale js/oracle.shale      # js-run, then every program through node and js-run
    shale js/oracle.shale engine=vm   # the same with js-vm, the bytecode VM
    shale js/probes.shale      # js-count, then the copying probes at three sizes
    shale js/controls.shale    # js-run --opt=speed, then count each control's allocations
    shale js/controls.shale opt=dev engine=vm   # js-vm's, as a report
    shale check.shale js=1     # the controls in both builds, held to their expected counts
    shale js/bench.shale       # both builds, then time js/bench/'s programs
    shale js/heaps.shale       # js-count --opt=speed, then each program's cells, scopes and peak memory
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

`js/oracle.shale` is a tier of `check.shale`. It builds `js-run` on the dev
backend and runs each program in `js/tests/` through node and through
`js-run`; the two transcripts, exit codes included, must match. Each
program in `js/tests/refused/` names in its first line (`// refused:
<text>`) what `js-run`'s last line must say. Nothing is skipped: the run
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
waited for), to the golden logs on every canvas sample, and runs every sample on the page, the
turtle in slow motion too. Unlike BASIC's host, this one needs no checkout
of the Roc compiler's source: the Roc hands it its buffers, takes back each
line it emitted (`drop_bytes`) and keeps the run in one box, so the host
never lays out a Roc list itself.

`js/probes.shale` is a first look at what a write copies: each probe in
`js/probes/` is timed at three sizes, and a write's cost that stays flat
across them is a write in place.

## Pitfalls

- **`js-run` takes the program as an argument,** so a program is held to
  the kernel's limit on one argument (128 KiB).
- **The page runs a program on the browser's main thread,** held to the
  rails above so a loop that never ends stops with a message rather than
  freezing the tab. js-canvas on the dev backend takes about 0.6 s of CPU
  to run a frame out of its 300,000 steps, and 3.7 s for a program out of
  its 3,000,000 (2026-11-23), so a frame near its budget slows the loop
  well below 30 a second before it stops it.
- **A turtle's trigonometry is exact only on the square headings,** so a
  turtle that walks a square ends where it began; at any other heading its
  positions carry a float's rounding, and the logs show it.
- **A JavaScript call is several Roc calls deep,** so the interpreter
  reports a stack overflow at 400 nested calls, as node would much deeper,
  rather than overflow Roc's own stack.
- **Built on the dev backend,** `fib(22)` takes about 0.4 s of CPU, and
  about 0.15 s in the release build (`js/bench.shale`, 2026-11-24).
- **The release build takes 11 to 17 minutes** on a 2-core box
  (2026-11-24), about 70% of it RC1's SpecConstr pass and the rest LLVM
  (`roc build --timings`; the tag `rc1-slow-release-build` reproduces it).
  So a round takes its release numbers once, never per step. The dev backend shows the
  code's shape, which is what the probes look at; a release build is for
  measuring speed.
- **A Map or a Set keeps a place for every key it ever held.** A deleted
  entry stays, `Gone`, so a walk under way still meets the rest in order,
  and is never reused: a table many keys pass through grows with them.
- **The host costs the dev build about a sixth.** With the walk carrying the
  host and effectful, `fib(22)` on the dev backend took 471 ms of CPU
  against 400 ms before (best of five each, 2026-11-23, with another lane
  running); the release build wasn't measured.
