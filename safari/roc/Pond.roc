# Pond -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).

Pond :: [].{
	PondPt : { cu : F64, cv : F64 }
	Duck : { p : Pond.PondPt, face_right : Bool }

	water_outline : List(Pond.PondPt)
	water_outline = [{ cu: (-2.0), cv: 3.0 }, { cu: (-28.0), cv: 3.0 }, { cu: (-31.0), cv: 14.0 }, { cu: (-26.0), cv: 28.0 }, { cu: (-15.0), cv: 32.0 }, { cu: (-5.0), cv: 29.0 }, { cu: (-1.0), cv: 16.0 }]

	water_color : I64
	water_color = 3112588

	bank : List(Pond.PondPt)
	bank = [{ cu: (-5.0), cv: 29.0 }, { cu: (-15.0), cv: 32.0 }, { cu: (-26.0), cv: 28.0 }, { cu: (-26.0), cv: 29.0 }, { cu: (-15.0), cv: 33.0 }, { cu: (-5.0), cv: 30.0 }]

	bank_color : I64
	bank_color = 12759680

	duck_codepoint : I64
	duck_codepoint = 129414

	duck_height : F64
	duck_height = 0.9

	ducks : List(Pond.Duck)
	ducks = [{ p: { cu: (-8.0), cv: 11.0 }, face_right: True }, { p: { cu: (-16.0), cv: 17.0 }, face_right: False }, { p: { cu: (-9.0), cv: 21.0 }, face_right: True }, { p: { cu: (-4.0), cv: 6.0 }, face_right: True }, { p: { cu: (-12.0), cv: 7.0 }, face_right: False }, { p: { cu: (-20.0), cv: 8.0 }, face_right: True }]
}
