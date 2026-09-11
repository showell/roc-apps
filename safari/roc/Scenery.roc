# Scenery -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Scenery :: [].{
	Scheme : [AllGreen, YellowGreen, RedGreen]
	Creature : [NoCreature, Elephant, Giraffe, Zebra, Rhino, DuckPond]
	Tree : { along : F64, across : F64, color : I64, height : F64 }
	Critter : { along : F64, across : F64, codepoint : I64, height : F64, face_right : Bool }

	lane_width : F64
	lane_width = 4.0

	herd_road_offset : F64
	herd_road_offset = 10.0

	is_pond : Scenery.Creature -> Bool
	is_pond = |c| (match c {
		DuckPond => True
		NoCreature => False
		Elephant => False
		Giraffe => False
		Zebra => False
		Rhino => False
	})
}
