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
import Trees

BirdFlight :: [].{

	## The tree a bird leaves, and the one it flies to.
	Flight : { from : Trees.RoadsideTree, to : Trees.RoadsideTree }

	## What a segment's bird does: flies from one tree to another, or sits,
	## when there's no tree to fly to.
	Habit : [Flies(BirdFlight.Flight), Sits(Trees.RoadsideTree)]

	## Where the wings are in a beat.
	WingBeat : [WingsUp, WingsDown]

	## How the bird looks: sitting; side on as it takes off; seen from behind
	## as it flies off; and dropping onto its tree.
	BirdPose : [
		Perched,
		Side(BirdFlight.WingBeat),
		Away(BirdFlight.WingBeat),
		Diving,
	]

	## A bird at one instant.
	Bird : Animation.Instant(BirdFlight.BirdPose)

	## How tall a bird stands.
	bird_height : Distance
	bird_height = Distance.metres(2.2)

	## How far the rider is from the bird's tree when it takes off.
	takeoff_gap : Distance
	takeoff_gap = Distance.metres(60.0)

	## How far the rider is from that tree when the bird has landed.
	landing_gap : Distance
	landing_gap = Distance.metres(15.0)

	## The bird flies to a tree at least this far along from the one it left,
	## so that its path runs ahead of the rider as well as across the road.
	shortest_hop : Distance
	shortest_hop = Distance.metres(25.0)

	## How far above a straight line the top of its path is.
	flight_arc : Distance
	flight_arc = Distance.metres(5.0)

	## How many frames one flap of the wings takes, half of them up and half down.
	frames_a_flap : U64
	frames_a_flap = 40

	## How the bird looks through a flight, a frame at a time: a flap side on as
	## it takes off, seven flaps seen from behind, and a flap's length of diving.
	##
	## A flight follows the gap, so how many steps it lasts depends on the rider,
	## and its frames can't land one a step as a cat's do. So it has more frames
	## than any rider sees: eight for each metre of the gap it plays over, the
	## finest the book's widget steps through it. However a rider comes, a step
	## lands within an eighth of a metre of where the bird should be.
	flight_poses : List(BirdFlight.BirdPose)
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
		match trees.keep_if(|tree| tree.across < Across.middle).drop_first(4).first() {
			Ok(tree) => Found(tree)
			Err(ListWasEmpty) => NoTree
		}

	## The habit of a bird on the tree at `from`: to the first tree on the
	## other side of the road far enough along, or none, and it sits.
	habit_from : List(Trees.RoadsideTree), Trees.RoadsideTree -> BirdFlight.Habit
	habit_from = |trees, from| {
		is_far_enough = |tree| tree.along >= from.along.plus(shortest_hop)
		far_side = trees.keep_if(|tree| tree.across > Across.middle and is_far_enough(tree))
		match far_side.first() {
			Ok(to) => Flies({ from, to })
			Err(ListWasEmpty) => Sits(from)
		}
	}

	## The bird of a segment with `trees`, if one has a tree to start on.
	crossing_among : List(Trees.RoadsideTree) -> [BirdHere(BirdFlight.Habit), QuietRoad]
	crossing_among = |trees|
		match fifth_left_tree(trees) {
			Found(tree) => BirdHere(habit_from(trees, tree))
			NoTree => QuietRoad
		}

	## Where the tree the bird starts from is along its segment.
	start_along : BirdFlight.Habit -> Along
	start_along = |habit|
		match habit {
			Flies(flight) => flight.from.along
			Sits(tree) => tree.along
		}

	## Where the bird's flight has got to, with the rider `gap` from the tree it
	## left.
	flight_stage : { gap : Distance, .. } -> Animation.Stage
	flight_stage = |approach|
		Animation.stage_over_gap({ starts_at: takeoff_gap, ends_at: landing_gap }, approach)

	## The bird with `habit`, with the rider `gap` from the tree it starts on.
	habit_instant_at : BirdFlight.Habit, { gap : Distance, .. } -> BirdFlight.Bird
	habit_instant_at = |habit, approach|
		match habit {
			Flies(flight) => instant_at(flight, approach)
			Sits(tree) => sitting_on(tree)
		}

	## The bird with the rider `gap` from the tree it left.
	instant_at : BirdFlight.Flight, { gap : Distance, .. } -> BirdFlight.Bird
	instant_at = |flight, approach| flight_timeline(flight).instant(flight_stage(approach))

	## The bird as it sits on top of `tree`.
	sitting_on : Trees.RoadsideTree -> BirdFlight.Bird
	sitting_on = |tree| { pose: Perched, spot: tree_top(tree) }

	## The whole of a flight: `flight_poses`, on one smooth path that rises in
	## the middle.
	flight_timeline : BirdFlight.Flight -> Animation.Timeline(BirdFlight.BirdPose)
	flight_timeline = |{ from, to }| {
		ends = { from: tree_top(from), to: tree_top(to) }
		frame_count = flight_poses.len().to_f64()
		frames = flight_poses.map_with_index(
			|pose, frame| {
				through = Fraction.of(frame.to_f64() / frame_count)
				{ pose, spot: flight_spot(ends, through) }
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
}

## The spot on top of `tree`.
tree_top : Trees.RoadsideTree -> Animation.Spot
tree_top = |tree| {
	along: tree.along,
	across: tree.across,
	lift: tree.kind.scenery_height(),
}

## One flap of the wings: `up` for half its frames and `down` for the rest.
flap_poses : BirdFlight.BirdPose, BirdFlight.BirdPose -> List(BirdFlight.BirdPose)
flap_poses = |up, down| {
	half = BirdFlight.frames_a_flap // 2
	List.repeat(up, half).concat(List.repeat(down, half))
}

## The spot `through` a flight between `from` and `to`, easing out and in along
## a straight line, and raised by an arc over it.
flight_spot : { from : Animation.Spot, to : Animation.Spot }, Fraction -> Animation.Spot
flight_spot = |{ from, to }, through| {
	on_line = Animation.spot_between({ from, to, fraction: Easing.smoothstep(through) })
	share = through.to_f64()
	# 4t(1 - t) is 0 at both ends and 1 halfway, so the arc tops out at `flight_arc`.
	above_line = BirdFlight.flight_arc.times(4.0 * share * (1.0 - share))
	{ ..on_line, lift: on_line.lift.plus(above_line) }
}

expect BirdFlight.bird_height.to_metres() == 2.2

tree_at : F64, F64 -> Trees.RoadsideTree
tree_at = |along, across| {
	along: Along.metres(along),
	across: Across.metres(across),
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
		Found(tree) => Ok(tree.along.to_metres())
		NoTree => Err(NoTree)
	}

expect fifth_along([]) == Err(NoTree)
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0])) == Err(NoTree)
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0, 50.0])) == Ok(50.0)
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0, 50.0, 60.0])) == Ok(50.0)
expect fifth_along([50.0, 60.0, 70.0, 80.0, 90.0].map(|along| tree_at(along, 6.0))) == Err(NoTree)

chosen_along : List(Trees.RoadsideTree) -> List(F64)
chosen_along = |choices|
	match BirdFlight.habit_from(choices, left_tree) {
		Flies(found) => [found.to.along.to_metres(), found.to.across.to_metres()]
		Sits(_) => []
	}

expect chosen_along(sample_trees) == [140.0, 6.0]
expect chosen_along([left_tree, tree_at(124.0, 6.0)]) == []
expect chosen_along([left_tree, tree_at(125.0, 6.0)]) == [125.0, 6.0]
expect chosen_along([left_tree, tree_at(140.0, -6.0)]) == []

## How far through its flight a bird with the rider `gap` off is.
progress_at : Distance -> F64
progress_at = |gap|
	match BirdFlight.flight_stage({ gap: gap }) {
		Waiting => 0.0
		Playing(progress) => progress.to_f64()
		Past(_) => 1.0
	}

## The gap halfway through the flight.
halfway_gap : Distance
halfway_gap = BirdFlight.takeoff_gap.plus(BirdFlight.landing_gap).divided_by(2.0)

expect
	[
		(progress_at(BirdFlight.takeoff_gap.plus(Distance.metres(1.0))), 0.0),
		(progress_at(BirdFlight.takeoff_gap), 0.0),
		(progress_at(halfway_gap), 0.5),
		(progress_at(BirdFlight.landing_gap), 1.0),
		(progress_at(BirdFlight.landing_gap.minus(Distance.metres(1.0))), 1.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)

expect {
	spot = BirdFlight.instant_at(sample_flight, { gap: Distance.metres(100.0) }).spot
	spot.along.to_metres() == 100.0
		and spot.across.to_metres() == -6.0
		and spot.lift.to_metres() == red_top
}

expect {
	spot = BirdFlight.instant_at(sample_flight, { gap: Distance.zero }).spot
	spot.along.to_metres() == 140.0
		and spot.across.to_metres() == 6.0
		and spot.lift.to_metres() == gold_top
}

expect {
	spot = BirdFlight.instant_at(sample_flight, { gap: halfway_gap }).spot
	[
		(spot.along.to_metres(), 120.0),
		(spot.across.to_metres(), 0.0),
		(spot.lift.to_metres(), (red_top + gold_top) / 2.0 + BirdFlight.flight_arc.to_metres()),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)
}

expect BirdFlight.instant_at(sample_flight, { gap: Distance.metres(100.0) }).pose == Perched
expect BirdFlight.instant_at(sample_flight, { gap: Distance.zero }).pose == Perched

expect BirdFlight.flight_poses.len() == 360

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
			BirdFlight.flight_timeline(sample_flight).instant(Playing(Fraction.of(progress))).pose
				== pose,
	)

# The flight starts on the first tree's tip and ends so near the second's that the
# drop to it is out of sight.
expect {
	frames_of = BirdFlight.flight_timeline(sample_flight)
	first = frames_of.instant(Playing(Fraction.zero)).spot
	last = frames_of.instant(Playing(Fraction.of(0.9999))).spot
	first == BirdFlight.instant_at(sample_flight, { gap: BirdFlight.takeoff_gap }).spot
		and last.along.distance_from(sample_flight.to.along).to_metres().abs() <= 0.01
		and (last.lift.to_metres() - gold_top).abs() <= 0.1
}
