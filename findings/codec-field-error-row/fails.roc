# The langref's Token example (static-dispatch.md, "Parsing and Encoding"):
# a custom parser_for, generic over the format, passing the format's error through.
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
