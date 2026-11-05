# Scenery -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Across
import Along
import Distance

Scenery :: [].{
	Scheme : [AllGreen, YellowGreen, RedGreen]
	Creature : [NoCreature, Elephant, Giraffe, Zebra, Rhino, DuckPond]
	Tree : {
		along : Along,
		across : Across,
		color : I64,
		height : Distance,
	}
	Critter : {
		along : Along,
		across : Across,
		codepoint : I64,
		height : Distance,
		face_right : Bool,
	}

	lane_width : Distance
	lane_width = Distance.metres(4.0)

	lane_half_width : Distance
	lane_half_width = lane_width.divided_by(2.0)

	left_edge : Across
	left_edge = Across.left_of_middle(lane_half_width)

	right_edge : Across
	right_edge = Across.right_of_middle(lane_half_width)

	herd_road_offset : Distance
	herd_road_offset = Distance.metres(10.0)

	is_pond : Scenery.Creature -> Bool
	is_pond = |c| (
		match c {
			DuckPond => True
			NoCreature => False
			Elephant => False
			Giraffe => False
			Zebra => False
			Rhino => False
		}
	)

	eq_Scheme : Scenery.Scheme, Scenery.Scheme -> Bool
	eq_Scheme = |ex, ey| (
		match ex {
			AllGreen => (
				match ey {
					AllGreen => True
					_ => False
				}
			)
			YellowGreen => (
				match ey {
					YellowGreen => True
					_ => False
				}
			)
			RedGreen => (
				match ey {
					RedGreen => True
					_ => False
				}
			)
		}
	)

	eq_Creature : Scenery.Creature, Scenery.Creature -> Bool
	eq_Creature = |ex, ey| (
		match ex {
			NoCreature => (
				match ey {
					NoCreature => True
					_ => False
				}
			)
			Elephant => (
				match ey {
					Elephant => True
					_ => False
				}
			)
			Giraffe => (
				match ey {
					Giraffe => True
					_ => False
				}
			)
			Zebra => (
				match ey {
					Zebra => True
					_ => False
				}
			)
			Rhino => (
				match ey {
					Rhino => True
					_ => False
				}
			)
			DuckPond => (
				match ey {
					DuckPond => True
					_ => False
				}
			)
		}
	)
}
