# book_builder

A Roc platform for building books from markdown manuscripts, with a Zig
host. A book app is one effectful function, `main!`, which gets the book's
folder from the command line and reads the manuscript through the
platform's one effect, `Book.read_file!`. It answers the text to print: `Ok`
goes to stdout, and `Err` goes to stderr with exit 1, as an echo-platform
app prints.

**The platform's one effect reads a file under the book's own folder.** It
can't touch anything else. There are no writes, no network and no other
paths. The host (`host/book_folder.zig`) refuses an absolute path, a `..`
that climbs above the folder, a symbolic link that resolves outside it and
a NUL byte. It checks the real path of the file it has opened, so nothing
can be swapped in between the check and the read. A link that stays inside
the folder is followed. Every refusal is a tag, never a crash:

    Book.read_file! : Str => Try(Str, [NotAFile, NotFound, NotUtf8, OutsideTheBook, ReadFailed])

`NotUtf8` is decided in Roc (`platform/Book.roc`), where the bytes become
text. `ReadFailed` covers everything else: a file nobody may read, or one
past the host's 16 MiB cap.

## Status (2026-11-16)

Steps 1 and 2 of five are here: the platform, and the builder package
(`builder/`), everything about a book that is a function of its manuscript.
Two examples build: `examples/one_page/`, the platform alone, and
`examples/full/`, a book that uses most of the builder. Still to come, each
a later step: code coloring, as a package of its own behind the builder's
coloring hook; and the Safari tutorial (`canvas_apps/safari/tutorial/`)
rebuilt on this platform, with its own fence hooks (widgets, diagrams), in
place of `make_book.roc` on the echo platform and the Shale scripts that
read its files.

## A book

A book is a folder with a `book.md` and an app, `main.roc`, whose `main!`
names the book's settings and calls the builder:

    main! = |_folder| Builder.build!(settings, Book.read_file!)

    settings = {
        ..Builder.default_settings,
        index_terms: IndexTerms("terms.txt"),
        negatives: Lint({ words: "negative_words.txt", table: "negatives.txt" }),
        fence_hooks: [shout],
    }

The manuscript's `#` heading and the text under it are the front page, which
holds the contents. Each `##` heading starts a chapter, numbered unless it is
back matter (by default a title starting `Appendix`, or `Credits`), and its
`###` headings are its sections. The program prints every page after a line
`<!-- book page: FILE -->`, then a report after `<!-- book report -->`. A
problem stops the build, and every problem found is printed, one a line.

What the builder does, and where each rule lives:

- `Manuscript.roc`: which lines are prose and which are fenced, and the
  pages.
- `Includes.roc`: `{{file PATH}}` and `{{lines PATH from "A" to "B"}}`, each
  a fence quoting a file of the book's folder, read through the platform.
- `References.roc`: `{{chapter Title}}` and `{{number N Title}}` in prose,
  linked to the chapter's page.
- `TermIndex.roc` and `TermPattern.roc`: the `{{index}}` line's tables, from
  a terms file whose patterns are a subset of regular expressions.
- `WordCount.roc`: words of prose per page, and the limit (900 by default)
  a numbered chapter is held to.
- `Negatives.roc`: the negatives lint, a words file and a table of the
  negative sentences the book keeps.
- `Fences.roc`: a book's fence hooks, and the coloring hook for code.
- `Pages.roc`: each page's HTML and the book's navigation.
- `Builder.roc`: the settings, and the build, which reads what the
  settings name and hands it to `Builder.built`, which is pure.

The package imports roc-markdown by relative path, from a checkout beside
roc-apps (`../roc-markdown`), as Safari's `make_book.roc` does.

## Building and checking

You need Zig 0.17.0 (the box's patched build) and roc-apps' pinned Roc, the
nightly named in `../roc-version`, at `~/tools/roc-<pin>/roc` (or name it
with `-Droc=<path>`). `zig build` refuses any other Roc. From this folder:

    zig build                          # zig-out/bin/book, with the one-page example linked
    zig-out/bin/book examples/one_page # the page, on stdout
    zig build test                     # the seam against roc glue, and the folder's reads on a real folder
    zig build -Dapp=<dir>/main.roc     # another book app
    zig build -Dapp=examples/full/main.roc -p zig-out/full   # the full example, as the gate builds it

From the roc-apps root:

    shale book_builder/tools/verify.shale   # the gate: every check, a line each, and how many passed
    shale book_builder/tools/glue.shale     # after a change to platform/: roc glue's snapshot again

## Layout

- `platform/`: `main.roc` says what an app provides and what the host
  calls (`roc_main`); `Host.roc` is the hosted effect as bytes, and
  `Book.roc` is what apps call.
- `host/`: `main.zig` is the program; `book_folder.zig` is the one read and
  its confinement; `abi.zig` is the seam, held to `roc glue`'s output
  (`glue/platform_abi.zig`) by `abi_test.zig`, whose checker is
  roc-screensaver's, copied.
- `builder/`: the builder package (above).
- `examples/one_page/`: the smallest book, with `expected.html`, the page
  the gate holds its output to byte for byte.
- `examples/full/`: a book with chapters, includes, references, an index,
  the negatives lint and a fence hook of its own, `shout`, with
  `expected.html`. `examples/broken_includes/` and `examples/broken_gates/`
  are books that fail, each run by the full example's program, with the
  problems it prints in `expected.txt`.
- `tools/`: the gate and the glue regenerator.

## Pitfalls

- **A provided function must have concrete types.** One whose type is still
  polymorphic passes `roc check` and crashes at run time
  (`findings/provides-type-variable/`).
- **A record crosses in Roc's order, not the source's**: by alignment, then
  by name, with a tag union's tag byte after its payload and its tags
  numbered alphabetically. After a change to `platform/`, run the glue
  script; `zig build test` names any field `host/abi.zig` lays out
  differently.
- **`targets` and `where` are Roc's words.** Neither can name a value,
  even in a package.
- **A change in roc-markdown doesn't rebuild a book.** `zig build` watches
  `platform/`, `builder/` and the app's folder only.
- **A FIFO in the book blocks the read.** The host opens a file before it
  can tell what it is, and opening a named pipe waits for a writer.
