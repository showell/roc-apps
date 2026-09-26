# Compiler hangs building a derived parser or encoder whose field is a custom-coded nominal type backed by a `List`

`roc check` passes on this program in tens of milliseconds. `roc` and `roc build`
never finish: one core at 100%, resident memory flat at 67 MB, no output,
killed after five minutes.

```roc
# A nominal type backed directly by List(U8), with its own parser_for.
Blob := List(U8).{
	parser_for = |format| |state| {
		parsed = Json.parse_str(format, state)?
		Ok({ value: Blob.(parsed.value.to_utf8()), rest: parsed.rest })
	}
}

main! = |args| {
	json = args.first().ok_or("{\"b\": \"hi\"}")

	# Works: Blob on its own.
	alone : Try(Blob, _)
	alone = Json.parse("\"hi\"")
	echo!("alone: ${Str.inspect(alone.is_ok())}\n")

	# Hangs the compiler: Blob as a field of a derived record.
	in_record : Try({ b : Blob }, _)
	in_record = Json.parse(json)
	echo!("in record: ${Str.inspect(in_record.is_ok())}\n")

	Ok({})
}
```

Changing only the backing to a record, `Blob := { bytes : List(U8) }`
(constructing it as `Blob.{ bytes: ... }`), builds and prints `alone: True`,
`in record: True`.

Variations, each a one-line change to the program above ("hangs" means
not finished after 30 seconds):

| change | result |
|---|---|
| as above (`List(U8)` backing, field of a record) | hangs |
| remove the `in_record` lines (`Blob` parsed on its own) | builds and runs |
| backing `{ bytes : List(U8) }` | builds and runs |
| backing `Str` | builds and runs |
| backing `List(Str)` | hangs |
| `Try(List(Blob), _)` instead of a record | hangs |
| `Try((Blob, Str), _)` instead of a record | hangs |

So it looks like any derived container (record, list or tuple) whose element
is a custom-coded nominal type with a `List` backing. Encoding hangs the same
way: a `Blob` with its own `encoder_for`, encoded as a record field with a
custom format, doesn't finish either, while `Blob` encoded alone does.

**Versions.** `nightly-2026-09-22-e494788` and `nightly-2026-09-25-1ab6804`,
the release tarballs from roc-lang/nightlies, x86-64 Linux. We haven't tried
`main` since (`21a5ddbfe`, "Lay out padded nominal backings and recursion
boxes independently of order", might be related).

**Where we hit it.** A CBOR format, where `ImageBlob := List(U8)` has its
own `parser_for`/`encoder_for` so that it's encoded as a byte string rather
than an array of `U8` (Zulip, #ideas > CBOR serialization). There, `roc test`
spun the same way.
