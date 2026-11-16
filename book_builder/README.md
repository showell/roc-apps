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

This is step 1 of five, the skeleton. It builds and runs one example,
`examples/one_page/`, which reads `book.md` and prints each paragraph as
escaped plain text in a `<p>`. Deliberately missing, each a later step:

2. Markdown rendered through roc-markdown.
3. A book's contents and index, across many pages.
4. Code coloring.
5. The Safari tutorial (`canvas_apps/safari/tutorial/`) rebuilt on this
   platform, replacing `make_book.roc` on the echo platform and the Shale
   scripts that read its files.

## Building and checking

You need Zig 0.17.0 (the box's patched build) and roc-apps' pinned Roc, the
nightly named in `../roc-version`, at `~/tools/roc-<pin>/roc` (or name it
with `-Droc=<path>`). `zig build` refuses any other Roc. From this folder:

    zig build                          # zig-out/bin/book, with the one-page example linked
    zig-out/bin/book examples/one_page # the page, on stdout
    zig build test                     # the seam against roc glue, and the folder's reads on a real folder
    zig build -Dapp=<dir>/main.roc     # another book app

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
- `examples/one_page/`: the smallest book, with `expected.html`, the page
  the gate holds its output to byte for byte.
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
- **A FIFO in the book blocks the read.** The host opens a file before it
  can tell what it is, and opening a named pipe waits for a writer.
