# World -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Cat
import lib.DeviceMath
import Herd
import Maybe
import Pigs
import Scenery
import Trees
import lib.Trig

World :: [].{
	Cfg : { length : F64, scheme : Scenery.Scheme, turn_deg : F64, cat : Bool, pigs : Bool, bull : Bool, terminates : Bool, creature : Scenery.Creature }
	Segment : { length : F64, width : F64, trees : List(Scenery.Tree), cows : List(Scenery.Critter), pigs : List(Scenery.Critter), pigs_distract : Bool, exit_angle : F64, exit_right : Bool, exit_to : I64, commit_along : F64, north_heading : F64, has_mid_tower : Bool, has_cat : Bool, cat : Cat.Cat, terminates : Bool, exit_creature : Scenery.Creature }

	mid_tower_min_length : F64
	mid_tower_min_length = 1000.0

	cfg : F64, Scenery.Scheme, F64, Bool, Bool, Bool, Bool, Scenery.Creature -> World.Cfg
	cfg = |len, sch, turn, c, p, b, t, cr| { length: len, scheme: sch, turn_deg: turn, cat: c, pigs: p, bull: b, terminates: t, creature: cr }

	route : List(World.Cfg)
	route = [cfg(500.0, AllGreen, 50.0, False, False, False, False, Elephant), cfg(320.0, AllGreen, (0.0 - 70.0), True, False, False, False, Elephant), cfg(400.0, AllGreen, 20.0, False, True, False, False, Elephant), cfg(300.0, YellowGreen, 20.0, False, False, False, False, Elephant), cfg(300.0, AllGreen, (0.0 - 70.0), False, False, True, False, Giraffe), cfg(300.0, AllGreen, (0.0 - 70.0), False, False, True, False, Elephant), cfg(1200.0, RedGreen, 80.0, False, False, True, False, Rhino), cfg(300.0, AllGreen, 15.0, False, False, True, False, Elephant), cfg(300.0, AllGreen, (0.0 - 70.0), False, False, True, False, Elephant), cfg(800.0, AllGreen, 15.0, False, False, True, False, Elephant), cfg(300.0, AllGreen, 15.0, False, True, True, False, Elephant), cfg(300.0, AllGreen, 15.0, False, True, True, False, Elephant), cfg(300.0, RedGreen, 15.0, True, True, True, False, DuckPond), cfg(400.0, AllGreen, (0.0 - 50.0), False, True, True, False, Elephant), cfg(300.0, AllGreen, 50.0, False, True, True, False, Elephant), cfg(300.0, RedGreen, (0.0 - 50.0), False, False, True, False, Zebra), cfg(300.0, AllGreen, 50.0, False, True, True, False, Elephant), cfg(300.0, AllGreen, (0.0 - 50.0), False, True, True, False, Elephant), cfg(300.0, RedGreen, 0.0, True, True, True, True, NoCreature)]

	tree_improves : Maybe.Maybe(F64), F64 -> Bool
	tree_improves = |best, a| (match best {
		Just(b) => (a < b)
		None => True
	})

	next_tree_loop : List(Scenery.Tree), F64, I64, Maybe.Maybe(F64) -> Maybe.Maybe(F64)
	next_tree_loop = |ts, desired, i, best| (if (i >= U64.to_i64_wrap(List.len(ts))) { best } else { next_tree_step(ts, desired, i, best) })

	next_tree_step : List(Scenery.Tree), F64, I64, Maybe.Maybe(F64) -> Maybe.Maybe(F64)
	next_tree_step = |ts, desired, i, best| ({
		t = (List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		take = (if (t.across > 0.0) { (if (t.along >= desired) { tree_improves(best, t.along) } else { False }) } else { False })
		(if take { next_tree_loop(ts, desired, (i + 1), Just(t.along)) } else { next_tree_loop(ts, desired, (i + 1), best) })
	})

	next_tree_along : List(Scenery.Tree), F64 -> F64
	next_tree_along = |ts, desired| Maybe.from_maybe(next_tree_loop(ts, desired, 0, None), desired)

	heading_step : I64 -> F64
	heading_step = |i| ({
		c = (List.get(route, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		((if (c.turn_deg >= 0.0) { 1.0 } else { (0.0 - 1.0) }) * (DeviceMath.real_abs(c.turn_deg) * Trig.deg))
	})

	heading_at : I64 -> F64
	heading_at = |i| (if (i <= 0) { 0.0 } else { (heading_at((i - 1)) + heading_step((i - 1))) })

	pig_count_to : I64, I64 -> I64
	pig_count_to = |i, acc| (if (i <= 0) { acc } else { pig_count_to((i - 1), (if (List.get(route, I64.to_u64_wrap((i - 1))) ?? crash("list-at out of range")).pigs { (acc + 1) } else { acc })) })

	segment_at : I64 -> World.Segment
	segment_at = |i| ({
		c = (List.get(route, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		angle = (DeviceMath.real_abs(c.turn_deg) * Trig.deg)
		trees = Trees.fill_trees(c.scheme, c.length, Trees.tree_start_inset, 0, 0)
		distract = (if c.pigs { (pig_count_to((i + 1), 0) <= Pigs.pig_novelty_count) } else { False })
		{ length: c.length, width: Scenery.lane_width, trees: trees, cows: Herd.fill_cows(c.bull), pigs: (if c.pigs { (if distract { Pigs.fill_pig_herd(c.length) } else { Pigs.fill_pig_row(c.length) }) } else { [] }), pigs_distract: distract, exit_angle: angle, exit_right: (c.turn_deg >= 0.0), exit_to: (if c.terminates { i } else { (i + 1) }), commit_along: (if c.terminates { c.length } else { (c.length - ((Scenery.lane_width / 2.0) / Trig.r_tan(angle))) }), north_heading: heading_at(i), has_mid_tower: (c.length > mid_tower_min_length), has_cat: c.cat, cat: Cat.cat_make((Scenery.lane_width / 2.0), Trees.tree_road_offset, next_tree_along(trees, Cat.cat_along)), terminates: c.terminates, exit_creature: (if c.terminates { NoCreature } else { c.creature }) }
	})

	# segments_from builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	segments_from : I64 -> List(World.Segment)
	segments_from = |i| segments_from_acc(i, [])

	segments_from_acc : I64, List(World.Segment) -> List(World.Segment)
	segments_from_acc = |i, acc| (if (i >= U64.to_i64_wrap(List.len(route))) { acc } else { segments_from_acc((i + 1), List.append(acc, segment_at(i))) })

	build_world : List(World.Segment)
	build_world = segments_from(0)

	course_length_from : List(World.Segment), I64 -> F64
	course_length_from = |ss, i| (if (i >= U64.to_i64_wrap(List.len(ss))) { 0.0 } else { ((List.get(ss, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).length + course_length_from(ss, (i + 1))) })

	course_length : List(World.Segment) -> F64
	course_length = |ss| course_length_from(ss, 0)

	route_distance_from : List(World.Segment), I64, I64 -> F64
	route_distance_from = |ss, seg, i| (if (i >= seg) { 0.0 } else { ((List.get(ss, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).length + route_distance_from(ss, seg, (i + 1))) })

	route_distance : List(World.Segment), I64, F64 -> F64
	route_distance = |ss, seg, along| (route_distance_from(ss, seg, 0) + along)
}
