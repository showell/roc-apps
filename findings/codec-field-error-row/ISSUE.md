# A custom `parser_for` that is generic over the format fails to type-check as a record field

The `Token` example from the langref ([static-dispatch.md, "Parsing and
Encoding"](https://github.com/roc-lang/roc/blob/main/docs/langref/static-dispatch.md#parsing-and-encoding))
parses fine on its own. As a field of a record, the same `Json.parse` is a
type error:

```roc
Token := { raw : Str }.{
	parser_for : encoding -> (state -> Try({ value : Token, rest : state }, err))
		where [
			encoding.parse_str : encoding, state -> Try({ value : Str, rest : state }, err),
		]
	parser_for = |encoding| {
		Encoding : encoding

		|state| {
			parsed = Encoding.parse_str(encoding, state)?
			Ok({ value: Token.{ raw: parsed.value }, rest: parsed.rest })
		}
	}
}

main! = |args| {
	json = args.first().ok_or("{\"t\": \"hi\"}")

	# Fine on its own.
	alone : Try(Token, _)
	alone = Json.parse("\"hi\"")

	# Type error as a record field.
	in_record : Try({ t : Token }, _)
	in_record = Json.parse(json)

	echo!("alone: ${Str.inspect(alone.map_ok(|tok| tok.raw))}\n")
	echo!("in record: ${Str.inspect(in_record.map_ok(|r| r.t.raw))}\n")
	Ok({})
}
```

```
── ✗ type mismatch ───────────────────────────────────────────── fails.roc:27:14

The parse_str method on JsonEncoding has an incompatible type.

in_record = Json.parse(json)
            ^^^^^^^^^^

The method parse_str has the type:

    JsonEncoding, JsonState -> Try({ rest: JsonState, value: Str },
    [InvalidJson(Str)])

But I need it to have the type:

    JsonEncoding, JsonState -> Try({ rest: JsonState, value: Str }, [])
```

Writing the error as a concrete type instead of `err` makes it compile and
run (`alone: Ok("hi")`, `in record: Ok("hi")`):

```roc
	parser_for : encoding -> (state -> Try({ value : Token, rest : state }, [InvalidJson(Str)]))
		where [
			encoding.parse_str : encoding, state -> Try({ value : Str, rest : state }, [InvalidJson(Str)]),
		]
```

That works around it, but it ties the type to one format's error, which is
what the generic version exists to avoid.

**A guess at the cause**, from reading `src/check/Check.zig` on `main`
(`d6267b4ef`): when a derived record parser includes a field parser's error
row, `constrainDerivedParserFormatError` sends an unconstrained flex error
variable to `constrainDerivedParserErrorRowIncludes`, which closes it to
`[]`. In the generic `Token`, the field's error variable is still flex at
that point, because it is only fixed once `encoding.parse_str` is resolved
against the format. It becomes `[]`, and then `JsonEncoding.parse_str`'s real
`[InvalidJson(Str)]` no longer fits.

**Versions.** `nightly-2026-09-22-e494788` and `nightly-2026-09-25-1ab6804`,
the release tarballs from roc-lang/nightlies, x86-64 Linux.

**Where we hit it.** A CBOR format, where an `ImageBlob` type asks the
format for `parse_bytes` so that it's encoded as a byte string rather than an
array of `U8` (Zulip, #ideas > CBOR serialization).
