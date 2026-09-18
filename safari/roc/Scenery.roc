# Scenery -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).

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

	eq_Scheme : Scenery.Scheme, Scenery.Scheme -> Bool
	eq_Scheme = |ex, ey| (match ex {
		AllGreen => (match ey {
			AllGreen => True
			_ => False
		})
		YellowGreen => (match ey {
			YellowGreen => True
			_ => False
		})
		RedGreen => (match ey {
			RedGreen => True
			_ => False
		})
	})

	eq_Creature : Scenery.Creature, Scenery.Creature -> Bool
	eq_Creature = |ex, ey| (match ex {
		NoCreature => (match ey {
			NoCreature => True
			_ => False
		})
		Elephant => (match ey {
			Elephant => True
			_ => False
		})
		Giraffe => (match ey {
			Giraffe => True
			_ => False
		})
		Zebra => (match ey {
			Zebra => True
			_ => False
		})
		Rhino => (match ey {
			Rhino => True
			_ => False
		})
		DuckPond => (match ey {
			DuckPond => True
			_ => False
		})
	})
}
