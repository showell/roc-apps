# Replies to the NBS programs that ask for them

The NBS corpus ships an `.in` beside eleven programs that INPUT, and for
some of them it holds a placeholder -- a single `0` -- rather than what the
program asks for. P203 asks for a zone width of at least 14 and loops
until it gets one, so a `0` stops it at its first prompt.

The files here are the replies, written from each listing's own prompts,
and `gen.py` prefers them to the corpus's. A reply says what this
interpreter IS, not what a test wants to hear:

- **P108** -- the listing names every reply: `PLEASE ENTER: 0` to `10`,
  then `500,6,600,2,200`, the two lines of section 108.3 (the first must
  be refused and re-asked), then `2,3,999`.
- **P107** -- each number to type is `A$`, continued by the next datum
  when the one after it is `X`. The corpus's file stops after 28 of them
  and splits `000001.2300000E-000009`.
- **P109, P110, P112** -- each case's reply is in the listing's DATA, with
  `=` standing for a space and `#` for a quote, and joined as it is
  printed. P112's replies must each be refused and re-asked, so each is
  followed by the zeros that get past it -- except its over-long string,
  which this interpreter accepts (strings have no length limit), so the
  listing asks RE-TRY and the answer is `N`.
- **P111** -- `1E-99999`, as it asks.
- **P203** -- a zone width of 14 (`Basic.zone`), a margin of 80
  (`Basic.margin`), and so 6 zones to a line: they start at columns 0, 14,
  28, 42, 56 and 70, and the last is 10 wide. P203 computes that last width
  as M - Z*(Z9-1) and fills its rightmost position, so 5 would be a wrong
  answer it cannot catch.
