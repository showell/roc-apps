# book_builder

A Roc platform for building books from markdown manuscripts, with a Zig host.
A book app is one effectful function, `main!`, which gets the book's folder
from the command line and reads the manuscript through the platform's one
effect, `Book.read_file!`. It answers the text to print: `Ok` goes to stdout,
and `Err` goes to stderr with exit 1.

**The one effect reads a file under the book's own folder.** That is all the
platform does: it writes nothing and opens no network. The host
(`host/book_folder.zig`) refuses an absolute path, a `..` that climbs above
the folder, a symbolic link that resolves outside it and a NUL byte. It checks
the real path of the file it has opened, so the file it checked is the file it
reads. A link that stays inside the folder is followed. Every refusal is a
tag:

    Book.read_file! : Str => Try(Str, [NotAFile, NotFound, NotUtf8, OutsideTheBook, ReadFailed])

`NotUtf8` is decided in Roc (`platform/Book.roc`), where the bytes become
text. `ReadFailed` covers the rest: an unreadable file, or one past the host's size cap.

It builds the Safari tutorial (`canvas_apps/safari/tutorial/`), the books
book (`building-books/`) and the JavaScript book, which lives in
[roc-js-interpreter](https://github.com/showell/roc-js-interpreter)'s
`js-book/` and is built from a checkout of it beside this one, through
`build_book.shale`'s `app=`. Each has a `book.shale` whose pre-step does what
needs a program, such as quoting code through Roc's parser and drawing
diagrams, then builds and publishes the book. Code is colored by
[roc-syntax-color](https://github.com/showell/roc-syntax-color), checked out
beside roc-apps, behind the coloring hook.

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
holds the contents. Each `##` heading starts a chapter. Chapters are numbered, except
back matter (by default a title starting `Appendix`, or `Credits`), and its
`###` headings are its sections. The program prints every page after a line
`<!-- book page: FILE -->`, then a report after `<!-- book report -->`. A
problem stops the build, and every problem found is printed, one a line.

The builder handles includes that quote the book's files (`{{file PATH}}`,
`{{lines ...}}`, `{{function PATH NAME}}`), diagrams, chapter references, a
term index, word counts per page, a negatives lint, fence hooks with syntax
coloring, and each page's HTML and navigation. `builder/Builder.roc` holds the
settings and the build; each module's header states its rule. Read
`examples/full/` for a book that uses most of it.

The package imports roc-markdown by relative path, from a checkout beside
roc-apps.

## Building and checking

It needs Zig and roc-apps' pinned Roc (`../roc-version`, at
`~/tools/roc-<pin>/roc`, or `-Droc=<path>`); `zig build` refuses any other
Roc. From this folder:

    zig build                          # zig-out/bin/book, with the one-page example linked
    zig-out/bin/book examples/one_page # the page, on stdout
    zig build test                     # the seam against roc glue, and the folder's reads on a real folder
    zig build -Dapp=<dir>/main.roc     # another book app

From the roc-apps root:

    shale book_builder/tools/verify.shale   # the gate: every check, a line each
    shale book_builder/tools/glue.shale     # after a change to platform/: roc glue's snapshot again

`examples/one_page/` is the platform alone and `examples/full/` the builder;
each holds an `expected.html` the gate compares byte for byte.
`examples/broken_includes/` and `examples/broken_gates/` are books that fail,
with the problems they print in `expected.txt`. `tools/` holds the gate and
the steps every book's `book.shale` shares; each script's header says what it
does.

Every page links `book.css` and `copy.js`, which `tools/build_book.shale`
copies beside the pages. `copy.js` gives each code block a Copy button, the
essay surface's own, and `copy_test.cjs` holds its pure half under node.

## Pitfalls

- **A provided function must have concrete types.** One whose type is still
  polymorphic passes `roc check` and crashes at run time.
- **A record crosses in Roc's order**: by alignment, then by name, with a tag
  union's tag byte after its payload and its tags numbered alphabetically.
  After a change to `platform/`, run the glue script; `zig build test` names
  any field `host/abi.zig` lays out differently.
- **`targets` and `where` are Roc's words**, reserved even in a package.
- **A change in roc-markdown leaves a book stale.** `zig build` watches
  `platform/`, `builder/` and the app's folder.
- **A FIFO in the book blocks the read.** The host opens a file before it
  learns what it is, and opening a named pipe waits for a writer.
