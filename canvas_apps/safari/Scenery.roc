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

expect Scenery.lane_width.to_metres() == 4.0
expect Scenery.lane_half_width.to_metres() == 2.0
expect Scenery.herd_road_offset.to_metres() == 10.0
expect Scenery.left_edge.to_metres() == -2.0
expect Scenery.right_edge.to_metres() == 2.0
expect Across.middle.distance_from(Scenery.left_edge).to_metres() == 2.0
expect Across.metres(-2.0).distance_from(Scenery.left_edge).to_metres() == 0.0
expect Across.metres(2.0).distance_from(Scenery.left_edge).to_metres() == 4.0
expect Scenery.is_pond(DuckPond)
expect !(Scenery.is_pond(NoCreature))
expect !(Scenery.is_pond(Elephant))
expect !(Scenery.is_pond(Giraffe))
expect !(Scenery.is_pond(Zebra))
expect !(Scenery.is_pond(Rhino))
scheme_code : Scenery.Scheme -> I64
scheme_code = |s| (
	match s {
		AllGreen => 0
		YellowGreen => 1
		RedGreen => 2
	}
)

creature_code : Scenery.Creature -> I64
creature_code = |c| (
	match c {
		NoCreature => 0
		Elephant => 1
		Giraffe => 2
		Zebra => 3
		Rhino => 4
		DuckPond => 5
	}
)

expect scheme_code(AllGreen) == 0
expect scheme_code(YellowGreen) == 1
expect scheme_code(RedGreen) == 2
expect creature_code(NoCreature) == 0
expect creature_code(Elephant) == 1
expect creature_code(Giraffe) == 2
expect creature_code(Zebra) == 3
expect creature_code(Rhino) == 4
expect creature_code(DuckPond) == 5
a_tree : Scenery.Tree
a_tree = {
	along: Along.metres(120.5),
	across: Across.metres(3.25),
	color: 9066271,
	height: Distance.metres(7.75),
}

a_critter : Scenery.Critter
a_critter = {
	along: Along.metres(250.5),
	across: Across.metres(-6.5),
	codepoint: 128004,
	height: Distance.metres(1.375),
	face_right: True,
}

expect a_tree.along.to_metres() == 120.5
expect a_tree.across.to_metres() == 3.25
expect a_tree.height.to_metres() == 7.75
expect a_critter.along.to_metres() == 250.5
expect a_critter.across.to_metres() == -6.5
expect a_critter.height.to_metres() == 1.375
expect a_tree.color == 9066271
expect a_critter.codepoint == 128004
expect a_critter.face_right
