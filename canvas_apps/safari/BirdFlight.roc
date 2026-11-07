## Where a Roc bird is and how it looks. A bird sits on the fifth tree on the
## left of a segment until the rider comes near, then flies diagonally ahead,
## across the road, to the next tree on the far side, and perches there. Where
## it is depends only on how far the rider is from the tree it left, as the
## cat's crossing does, so stepping back through a ride shows the same bird.
import Across
import Along
import Animation
import Conifer
import Distance
import Easing
import Fraction
import PosedBird
import Trees

BirdFlight :: [].{

	## The tree a bird leaves, and the one it flies to.
	Flight : { from : Trees.RoadsideTree, to : Trees.RoadsideTree }

	## What a segment's bird does: it sits on its perch until the rider comes,
	## then flies to another tree, or stays put when there's no tree to fly to.
	Habit : { perch : Trees.RoadsideTree, leaves_for : [FliesTo(Trees.RoadsideTree), StaysPut] }

	## A bird at one instant: how it looks, and where it is.
	BirdInstant : Animation.Instant(PosedBird.BirdPose)

	## The gaps from the rider to the bird's tree that its flight plays between:
	## it takes off with the rider `starts_at` from that tree, and has landed by
	## `ends_at`.
	flight_gaps : Animation.GapSpan
	flight_gaps = { starts_at: Distance.metres(60.0), ends_at: Distance.metres(15.0) }

	## How far above a straight line the top of its path is.
	flight_arc : Distance
	flight_arc = Distance.metres(5.0)

	## How the bird looks through a flight, a frame at a time: a flap side on as
	## it takes off, seven flaps seen from behind, and a flap's length of diving.
	##
	## A flight follows the gap, so how many steps it lasts depends on the rider,
	## and its frames can't land one a step as a cat's do. So it has more frames
	## than any rider sees: eight for each metre of the gap it plays over, the
	## finest the book's widget steps through it. However a rider comes, a step
	## lands within an eighth of a metre of where the bird should be.
	flight_poses : List(PosedBird.BirdPose)
	flight_poses = [
		flap_poses(Side(WingsUp), Side(WingsDown)),
		List.repeat(flap_poses(Away(WingsUp), Away(WingsDown)), 7).join(),
		List.repeat(Diving, frames_a_flap),
	].join()

	## The tree a bird starts on, the fifth with a negative `across`. Those are
	## on the left, and an unflipped still's beak points toward +x, so from
	## there the bird faces the road.
	fifth_left_tree : List(Trees.RoadsideTree) -> [Found(Trees.RoadsideTree), NoTree]
	fifth_left_tree = |trees|
		match trees.keep_if(|tree| tree.road_point.across < Across.middle).drop_first(4).first() {
			Ok(tree) => Found(tree)
			Err(ListWasEmpty) => NoTree
		}

	## The bird of a segment with `trees`, if one has a tree to start on.
	crossing_among : List(Trees.RoadsideTree) -> [BirdHere(BirdFlight.Habit), QuietRoad]
	crossing_among = |trees|
		match fifth_left_tree(trees) {
			Found(tree) => BirdHere(habit_from(trees, tree))
			NoTree => QuietRoad
		}

	## Where the bird's flight has got to, with the rider `gap` from the tree it
	## left.
	flight_stage : { gap : Distance, .. } -> Animation.Stage
	flight_stage = |approach| Animation.stage_over_gap(flight_gaps, approach)

	## The bird with `habit`, with the rider `gap` from its perch.
	habit_instant_at : BirdFlight.Habit, { gap : Distance, .. } -> BirdFlight.BirdInstant
	habit_instant_at = |habit, approach|
		match habit.leaves_for {
			FliesTo(to) => instant_at({ from: habit.perch, to }, approach)
			StaysPut => sitting_on(habit.perch)
		}

	## The bird with the rider `gap` from the tree it left.
	instant_at : BirdFlight.Flight, { gap : Distance, .. } -> BirdFlight.BirdInstant
	instant_at = |flight, approach| flight_timeline(flight).instant(flight_stage(approach))
}

## The bird flies to a tree at least this far along from the one it left,
## so that its path runs ahead of the rider as well as across the road.
shortest_hop : Distance
shortest_hop = Distance.metres(25.0)

## How many frames one flap of the wings takes, half of them up and half down.
frames_a_flap : U64
frames_a_flap = 40

## The habit of a bird perched on the tree at `perch`: to fly to the first tree
## on the other side of the road far enough along, or, with none, to stay put.
habit_from : List(Trees.RoadsideTree), Trees.RoadsideTree -> BirdFlight.Habit
habit_from = |trees, perch| {
	is_far_enough = |tree| tree.road_point.along >= perch.road_point.along.plus(shortest_hop)
	far_side = trees.keep_if(|tree| tree.road_point.across > Across.middle and is_far_enough(tree))
	match far_side.first() {
		Ok(to) => { perch, leaves_for: FliesTo(to) }
		Err(ListWasEmpty) => { perch, leaves_for: StaysPut }
	}
}

## The bird as it sits on top of `tree`.
sitting_on : Trees.RoadsideTree -> BirdFlight.BirdInstant
sitting_on = |tree| { pose: Perched, location: tree_top(tree) }

## The whole of a flight: `flight_poses`, on one smooth path that rises in
## the middle.
flight_timeline : BirdFlight.Flight -> Animation.Timeline(PosedBird.BirdPose)
flight_timeline = |{ from, to }| {
	ends = { from: tree_top(from), to: tree_top(to) }
	frame_count = BirdFlight.flight_poses.len().to_f64()
	frames = BirdFlight.flight_poses.map_with_index(
		|pose, frame| {
			through = Fraction.of(frame.to_f64() / frame_count)
			{ pose, location: flight_location({ from: ends.from, to: ends.to, through }) }
		},
	)
	Animation.Timeline.(
		{
			before: sitting_on(from),
			frames,
			after: sitting_on(to),
		},
	)
}

## The location on top of `tree`.
tree_top : Trees.RoadsideTree -> Animation.Location
tree_top = |tree| {
	along: tree.road_point.along,
	across: tree.road_point.across,
	lift: tree.kind.scenery_height(),
}

## One flap of the wings: `up` for half its frames and `down` for the rest.
flap_poses : PosedBird.BirdPose, PosedBird.BirdPose -> List(PosedBird.BirdPose)
flap_poses = |up, down| {
	half = frames_a_flap // 2
	List.repeat(up, half).concat(List.repeat(down, half))
}

## The location `through` a flight between `from` and `to`, easing out and in along
## a straight line, and raised by an arc over it.
flight_location : {
	from : Animation.Location,
	to : Animation.Location,
	through : Fraction,
} -> Animation.Location
flight_location = |{ from, to, through }| {
	on_line = Animation.location_between({ from, to, fraction: Easing.smoothstep(through) })
	share = through.to_f64()
	# 4t(1 - t) is 0 at both ends and 1 halfway, so the arc tops out at `flight_arc`.
	above_line = BirdFlight.flight_arc.times(4.0 * share * (1.0 - share))
	{ ..on_line, lift: on_line.lift.plus(above_line) }
}

tree_at : F64, F64 -> Trees.RoadsideTree
tree_at = |along, across| {
	road_point: { along: Along.metres(along), across: Across.metres(across) },
	lift: Distance.zero,
	kind: Conifer.Red,
}

left_tree : Trees.RoadsideTree
left_tree = tree_at(100.0, -6.0)

## A tree on the far side too near to fly to, and two far enough.
sample_trees : List(Trees.RoadsideTree)
sample_trees = [
	left_tree,
	tree_at(100.0, 6.0),
	tree_at(140.0, -6.0),
	tree_at(140.0, 6.0),
	tree_at(180.0, 6.0),
]

sample_flight : BirdFlight.Flight
sample_flight = { from: left_tree, to: { ..tree_at(140.0, 6.0), kind: Conifer.Gold } }

## How high a bird perches on a red tree, and on a gold one.
red_top : F64
red_top = Conifer.Red.scenery_height().to_metres()

gold_top : F64
gold_top = Conifer.Gold.scenery_height().to_metres()

## A left and a right tree at each of `alongs`.
pairs_at : List(F64) -> List(Trees.RoadsideTree)
pairs_at = |alongs| alongs.join_map(|along| [tree_at(along, -6.0), tree_at(along, 6.0)])

## How far along the fifth left tree of `choices` is, if there is one.
fifth_along : List(Trees.RoadsideTree) -> Try(F64, [NoTree])
fifth_along = |choices|
	match BirdFlight.fifth_left_tree(choices) {
		Found(tree) => Ok(tree.road_point.along.to_metres())
		NoTree => Err(NoTree)
	}

expect fifth_along([]) == Err(NoTree)
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0])) == Err(NoTree)
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0, 50.0])) == Ok(50.0)
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0, 50.0, 60.0])) == Ok(50.0)
expect fifth_along([50.0, 60.0, 70.0, 80.0, 90.0].map(|along| tree_at(along, 6.0))) == Err(NoTree)

chosen_along : List(Trees.RoadsideTree) -> List(F64)
chosen_along = |choices|
	match habit_from(choices, left_tree).leaves_for {
		FliesTo(to) => [to.road_point.along.to_metres(), to.road_point.across.to_metres()]
		StaysPut => []
	}

expect chosen_along(sample_trees) == [140.0, 6.0]
expect chosen_along([left_tree, tree_at(124.0, 6.0)]) == []
expect chosen_along([left_tree, tree_at(125.0, 6.0)]) == [125.0, 6.0]
expect chosen_along([left_tree, tree_at(140.0, -6.0)]) == []
expect habit_from(sample_trees, left_tree).perch == left_tree

## How far through its flight a bird with the rider `gap` off is.
progress_at : Distance -> F64
progress_at = |gap|
	match BirdFlight.flight_stage({ gap: gap }) {
		Waiting => 0.0
		Playing(progress) => progress.to_f64()
		Past(_) => 1.0
	}

## The gaps at takeoff and landing.
takeoff_gap : Distance
takeoff_gap = BirdFlight.flight_gaps.starts_at

landing_gap : Distance
landing_gap = BirdFlight.flight_gaps.ends_at

## The gap halfway through the flight.
halfway_gap : Distance
halfway_gap = takeoff_gap.plus(landing_gap).divided_by(2.0)

expect
	[
		(progress_at(takeoff_gap.plus(Distance.metres(1.0))), 0.0),
		(progress_at(takeoff_gap), 0.0),
		(progress_at(halfway_gap), 0.5),
		(progress_at(landing_gap), 1.0),
		(progress_at(landing_gap.minus(Distance.metres(1.0))), 1.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)

expect {
	location = BirdFlight.instant_at(sample_flight, { gap: Distance.metres(100.0) }).location
	location.along.to_metres() == 100.0
		and location.across.to_metres() == -6.0
		and location.lift.to_metres() == red_top
}

expect {
	location = BirdFlight.instant_at(sample_flight, { gap: Distance.zero }).location
	location.along.to_metres() == 140.0
		and location.across.to_metres() == 6.0
		and location.lift.to_metres() == gold_top
}

expect {
	location = BirdFlight.instant_at(sample_flight, { gap: halfway_gap }).location
	[
		(location.along.to_metres(), 120.0),
		(location.across.to_metres(), 0.0),
		(location.lift.to_metres(), (red_top + gold_top) / 2.0 + BirdFlight.flight_arc.to_metres()),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)
}

expect BirdFlight.instant_at(sample_flight, { gap: Distance.metres(100.0) }).pose == Perched
expect BirdFlight.instant_at(sample_flight, { gap: Distance.zero }).pose == Perched

expect
	[
		(0.01, Side(WingsUp)),
		(0.08, Side(WingsDown)),
		(0.11, Side(WingsDown)),
		(0.1112, Away(WingsUp)),
		(0.5 - 1.0 / 36.0, Away(WingsUp)),
		(0.5 + 1.0 / 36.0, Away(WingsDown)),
		(0.87, Away(WingsDown)),
		(0.8888, Away(WingsDown)),
		(0.8889, Diving),
		(0.95, Diving),
		(0.9999, Diving),
	].all(
		|(progress, pose)|
			flight_timeline(sample_flight).instant(Playing(Fraction.of(progress))).pose
				== pose,
	)

# The flight starts on the first tree's tip and ends so near the second's that the
# drop to it is out of sight.
expect {
	frames_of = flight_timeline(sample_flight)
	first = frames_of.instant(Playing(Fraction.zero)).location
	last = frames_of.instant(Playing(Fraction.of(0.9999))).location
	first == BirdFlight.instant_at(sample_flight, { gap: takeoff_gap }).location
		and last.along.distance_from(sample_flight.to.road_point.along).to_metres().abs() <= 0.01
		and (last.lift.to_metres() - gold_top).abs() <= 0.1
}
