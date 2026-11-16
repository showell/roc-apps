# The Example Book

This book shows what the book builder does. The contents below list its
chapters and their sections.

## Pages and chapters

Each chapter starts at a heading of its own. The builder numbers the
chapters and links each page to the pages beside it.

### Sections

A section is a heading inside a chapter. The contents page lists it, and so
does the list of chapters beside this page.

See {{chapter Quoting files}} for the includes, and chapter
{{number 3 The index}} for the index.

## Quoting files

An include quotes a file as it stands when the book is built.
A quote holds no fence of its own.

{{file code/greet.roc}}

An excerpt quotes the lines from one anchor to another.

{{lines code/greet.roc from "greet :" to "Hello"}}

A fence of the book's own kind goes through its hook:

```shout A greeting
hello, reader
```

A plain fence is code, escaped as the renderer escapes it:

```text
<b> & "quotes"
```

## The index

The index lists each term of the terms file with the chapter that mentions
it most. A chapter, an include and a hook each have a place in it.

## Appendix: index

{{index}}
