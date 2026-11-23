# JavaScript, in Roc

A subset of JavaScript run by a tree-walking interpreter written in Roc, a
web page that runs it, and a corpus that holds it to node.

The code here was written by AI coding agents (Claude), with human
supervision.

**Status (2026-11-23): a first version.** 33 of 33 corpus programs print
what node 22 prints, byte for byte, and 25 of 25 programs outside the subset
are refused with the message they must give. The page builds into the dev
channel; it is not published.

## The subset

Every program in the subset is real JavaScript, so `node` is a free oracle:
what node prints for it is what the interpreter must print.

- **Values:** numbers (F64), strings, booleans, `null`, `undefined`, arrays,
  plain objects and functions.
- **Statements:** `let` and `const` with block scope (a `for` loop's `let`
  is a new variable each pass, as closures see it), `if`, `while`, the
  C-form `for`, `for ... of` over arrays and strings, `return`, `break`,
  `continue`, and function declarations, hoisted.
- **Expressions:** arithmetic and `**`; `<`, `>`, `<=`, `>=` on numbers or on
  strings; `===` and `!==`; `&&`, `||`, `??`, `!`, `?:` and `typeof`;
  assignment, the compound assignments and `++` and `--`; property and
  index access; calls; arrow functions and function expressions, closures
  included; array and object literals (with shorthand properties and
  methods); and template strings. `+` joins when either side is a string,
  an array or an object, as in JavaScript.
- **Builtins:** `console.log`, formatted as node formats the subset's
  values (line breaks past 80 columns, grouped columns for long arrays,
  depth 2, the quoting rules); `Math`'s `floor`, `ceil`, `round`, `trunc`,
  `abs`, `sign`, `sqrt`, `pow`, `min`, `max`, `sin`, `cos`, `tan`, `atan`,
  `PI` and `E`; arrays' `length`, `push`, `pop`, `join`, `indexOf`,
  `includes`, `slice`, `concat`, `reverse`, `sort`, `forEach`, `map`,
  `filter`, `some`, `every`, `find`, `findIndex` and `reduce`; strings'
  `length`, indexing, `charAt`, `charCodeAt`, `indexOf`, `includes`,
  `startsWith`, `endsWith`, `slice`, `substring`, `toUpperCase`,
  `toLowerCase`, `trim`, `split`, `repeat`, `padStart`, `padEnd` and
  `concat`; `Object.keys`, `values` and `entries`; `String(x)` and
  `String.fromCharCode`; `Array.isArray`; `Number.isInteger`.
- **Out of it:** `this`, `new`, prototypes and classes, getters and setters,
  `==` and the other coercions (`"3" * 2`, `true + 1`), `var`, exceptions,
  `eval`, regular expressions, destructuring, spread, async and modules.

**A program outside the subset gets an error that names what it used,
never a wrong answer.** The parser refuses the forms it can see (`js:
unsupported: classes (line 1, column 1)`), and the interpreter stops at the
ones only a run shows (`js: unsupported: an operator on a string and a
number (a coercion) (line 2)`). A position-counting string method on
non-ASCII text is one of these: JavaScript counts UTF-16 units, and the
interpreter's strings are UTF-8.

## Laying it out

The interpreter is `js/roc/`: `Lexer.roc` makes tokens with their lines and
columns, `Parser.roc` reads them into `Ast.roc`'s tree by recursive descent,
`Interp.roc` walks it, `Heap.roc` holds what JavaScript shares by
reference, `Inspect.roc` is console.log's formatting (node's `util.inspect`,
function for function), and `NumberText.roc` writes a number as `String(n)`
does. `JsRun.roc` is `js-run`, the command; `JsCount.roc` is `js-count`, the
same run followed by its counts. `JsApp.roc` is the page's wasm module, on
the platform and host in `js/wasm/`; `js/web/` is the page.

## Why the heap is one value

JavaScript shares arrays, objects and closures by reference: two variables
that hold one array see each other's writes. Roc has only values. So the
interpreter keeps everything JavaScript shares in one Roc value, the heap, a
list of cells (an object, an array, a closure, a builtin) named by index,
and a JavaScript reference is that index. Scopes are a second list, because
a closure holds on to the scope it was made in and must see later writes to
it. The machine (`Interp.St`: the heap, the scopes, the output, the step
count) is threaded through the walk the way BASIC threads its machine: each
evaluation takes it and answers it back beside its value.

**Roc writes a list in place only while nothing else refers to it, so one
stray reference to the heap makes every write copy the whole heap.** The
shapes that keep it unique, each with a comment where it is used:

- **A cell is taken out, written and put back** (`Heap.with_prop` and its
  siblings): `List.replace` leaves `Taken` in its place, so the props or
  items are written while nothing else refers to them.
- **A writer is handed the list straight from the record it updates,**
  `{ ..st, cells: Heap.with_prop(st.cells, ...) }`.
- **Every result is taken apart where it is answered,** `{ st: after, val
  } = Interp.eval(st, e)`. A result kept whole for its value keeps its
  machine too, and each write made while it lives copies. Before this rule,
  a store into an array copied the array, and a closure's `++c` copied
  every scope.
- **A writer asks what a cell is (`Interp.kind_of`), and never matches the
  cell out of the heap:** the matched cell is a second reference to its
  items for as long as the arm runs.
- **The write inside a taken-out cell or scope is a function of its own**
  (`Heap.items_with`, `Interp.scope_with_var`). Written inline in the match
  arm, beside a binding, a store into an array of N items copied the N
  items.
- **The scope list is a stack whose dropped slots are reused,** and it
  never shrinks: `List.drop_last` answers a sublist, and the next append
  to it copied the whole list, so a closure's call, beside N scopes other
  closures keep alive, cost N.
- **`s += e` on a string, with an `e` that can't change `s`, grows the
  string where the variable holds it** (`Interp.appended_name`), so a
  string built one piece at a time is not copied per piece.
- **No closure captures the machine;** a loop over it is a `var $st` loop.

A block or function whose text holds no function literal can't have its
scope captured, so its scope is dropped when it ends: a loop or a recursion
without closures leaves the scope list as it found it. Cells are never
freed: a run's heap holds every object it made.

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

    shale js/oracle.shale      # build js-run, then every program through node and js-run
    shale js/probes.shale      # build js-count, then the copying probes at three sizes
    shale js/build.shale       # build the page into the dev channel, :9210/js/

`js/oracle.shale` is a tier of `check.shale`. It builds `js-run` on the dev
backend and runs each program in `js/tests/` through node and through
`js-run`; the two transcripts, exit codes included, must match. Each
program in `js/tests/refused/` names in its first line (`// refused:
<text>`) what `js-run`'s last line must say. Nothing is skipped: the run
fails unless every program passes.

`js/build.shale` builds `JsApp.roc` into a wasm32 archive, links it with
Zig 0.16 and `js/wasm/host.zig` into `js.wasm`, and replaces the page only
after `js/page_check.mjs` passes. The check drives the page's own
`js_runner.js` and `js_page.js` under node, and holds the wasm to node on
every corpus program and refusal and on the page's samples. Unlike BASIC's
host, this one needs no checkout of the Roc compiler's source: the Roc
hands it its buffers and drops its transcripts, so the host never lays out
a Roc list itself.

`js/probes.shale` is a first look at what a write copies: each probe in
`js/probes/` is timed at three sizes, and a write's cost that stays flat
across them is a write in place.

## Pitfalls

- **`js-run` takes the program as an argument,** so a program is held to
  the kernel's limit on one argument (128 KiB).
- **The page runs a program on the browser's main thread,** held to a
  budget of 3,000,000 steps so a loop that never ends stops with a message
  rather than freezing the tab.
- **A JavaScript call is several Roc calls deep,** so the interpreter
  reports a stack overflow at 400 nested calls, as node would much deeper,
  rather than overflow Roc's own stack.
- **Built on the dev backend,** a statement costs about 10 µs: `fib(22)`
  takes 1.8 s. The dev backend shows the code's shape, which is what the
  probes look at; a release build is for measuring speed.
