# A generic custom `parser_for` fails to type-check as a record field

**Filed as [roc-lang/roc#11728](https://github.com/roc-lang/roc/issues/11728),
2026-09-26.** `ISSUE.md` is the text as posted.

`fails.roc` is the langref's own `Token` example, a `parser_for` generic
over the format that passes the format's error through as `err`. It parses
alone and fails to type-check as a record field (`{ t : Token }`) with
`Json.parse`: the checker wants `parse_str`'s error to be `[]`.
`works.roc` is the same file with the error written as `[InvalidJson(Str)]`,
and it runs.

    roc fails.roc    # type mismatch, exit 1
    roc works.roc    # alone: Ok("hi") / in record: Ok("hi")

Same on `nightly-2026-09-22-e494788` and `nightly-2026-09-25-1ab6804`.

Found 2026-09-26 building `cbor-pets/`, whose `ImageBlob` carries the
workaround: its `parser_for` requires `parse_bytes` to fail with a concrete
`[InvalidBlob(Str)]`.
