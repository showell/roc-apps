T :: List(U8).{
	from_quote : Str -> Try(T, [BadQuotedBytes(Str)])
	from_quote = |s| Ok(T.(Str.to_utf8(s)))

	from_units : List(U8) -> T
	from_units = |us| T.(us)

	len : T -> U64
	len = |T.(us)| List.len(us)
}
