# syntax_color

A Roc package that colors source code for web pages: code text in, HTML out,
with a `<span class="syn-...">` around each run a language's lexer gives a
class. It colors Roc and Shale the same way the Safari book's
`canvas_apps/safari/tutorial/color_roc.shale` and the Shale cookbook's
`color_shale.shale` do, byte for byte, and JavaScript with the same classes. The class names are book.css's:
`syn-comment`, `syn-string`, `syn-number`, `syn-keyword`, `syn-name` and
`syn-type`.

The folder stands alone, so it can move to a repository of its own: nothing in
it imports from the rest of roc-apps. Only its gate takes roc-apps' pinned Roc,
through the repository's prelude.

## The interface

`package/SyntaxColor.roc` is the interface:

- `SyntaxColor.html(language, text)` is the whole text, colored.
- `SyntaxColor.spans(language, text)` is the lexer's answer: a list of `Span`s,
  `{ class, start, end }` over the text's bytes, covering every byte once, in
  order. `class` is `Plain`, `Comment`, `String`, `Number`, `Keyword`, `Name` or
  `Type` (`package/Span.roc`).
- `SyntaxColor.range_html(text, { spans, start, end })` is a byte range of the
  text, colored by the spans of the whole. A page that shows part of a file
  colors the file once and takes the ranges it shows, so a block cut from a
  function's body is colored as it reads there.
- `SyntaxColor.escaped_text(text)` is the text with `&`, `<`, `>`, `"` and `'`
  escaped, as both the spans and the text between them are.

A language is a `SyntaxColor.Language`, `{ name, spans }`, whose `spans` is its
lexer. `SyntaxColor.roc`, `SyntaxColor.shale` and `SyntaxColor.js` are the three
there are, each lexer a module of its own (`RocSyntax.roc`, `ShaleSyntax.roc`,
`JsSyntax.roc`), and `Bytes.roc` holds the byte reads they share. Another
language is one more module with a
`spans : Str -> List(Span)` and one more value beside those.

No text makes a lexer fail: an unterminated string, a stray byte or half a
program still comes out with every byte covered, and the expects hold both
lexers to that over 1378 hostile texts.

## Lexical, with brackets

The lexers read bytes, not a tree. JavaScript's keeps a stack of braces, for
a template's `${...}`, and the token before, to tell a regular expression's
`/` from division's. Shale's follows Shale's own lexer
(`src/script/lex.zig` in the shale repository). Roc's has no lexer of record to
follow, since color_roc reads roc-ast's tree, so RocSyntax keeps the little it
needs to agree with the tree: which brackets are open and what the token
before was. That tells a top-level definition's name from a local's, and a
function's body from a record. `RocSyntax.roc`'s header says the rules.

## The gate and the oracle

    cd <roc-apps checkout> && shale syntax_color/tools/verify.shale

It runs `roc fmt --check`, `roc check` and `roc test` (its count held exact),
builds `harness/main.roc` on Roc's echo platform, and holds the harness's
answer for every sample in `oracle/` to what today's scripts made of it, byte
for byte. A sample known to differ is named in `oracle/known_mismatches.txt`
with its reason, and the list is held exact both ways.

`tools/record_oracle.shale` records `oracle/` again, from a roc-apps checkout
with the books book's checkout and the Shale cookbook beside it. Its header
says what each file holds. Re-record only when today's scripts change, and
read the diff.

## Status (2026-11-16)

- Every Safari Roc block (223) and every file they quote (76) matches
  color_roc, but for web.roc, which color_roc leaves plain because roc-ast's
  spans for its app header overlap. Colored alone, without their files, 218 of
  the 223 blocks match. The other five are cut from a function's body, whose
  `name = ...` lines read as top-level definitions alone.
- 107 of 109 Shale samples match color_shale; the two others are fragments
  color_shale refuses because they fail `shale --check` alone.
- JavaScript had no colorer before, so its 13 fixtures (`oracle/js_files.jsonl`,
  from `tools/record_js_fixtures.shale`) are the package's own answers, read
  by eye.
- The gate takes about 3 seconds on a warm Roc cache.
- The book builder does not use the package yet.

## Pitfalls

- A record literal opened right after `=` reads as a body, so a `name : value`
  field in it, spaced as an annotation is, would count as a definition.
  `roc fmt` writes fields as `name: value`, which never does.
- A qualified type in a lambda's unwrap pattern, `|Route.Index.(n)|`, is plain,
  where an unqualified one, `|Route.(n)|`, is a type. That is color_roc's
  answer, kept so the book doesn't change.
