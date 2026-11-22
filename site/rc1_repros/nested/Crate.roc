Crate := { width : U64 }.{
	width : Crate -> U64
	width = |Crate.(crate)| crate.width

	Lid := { width : U64 }.{
		width : Crate.Lid -> U64
		width = |Crate.Lid.(lid)| lid.width
	}
}
