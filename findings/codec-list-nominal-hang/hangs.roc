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
