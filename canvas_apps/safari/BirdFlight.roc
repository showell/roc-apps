## Where a Roc bird is and how it looks. A bird sits on the fifth tree on the
## left of a segment until its flight starts, then flies diagonally ahead,
## across the road, to the next tree on the far side, and perches there. Its
## flight plays a frame a step at its own pace, and the ride plans its start so
## that it lands as the rider comes within `landing_gap` of the tree it left.
import Across
import Along
import Animation
import Conifer
import Distance
import Easing
import Fraction
import PosedBird
import Steps
import Trees

BirdFlight :: [].{

	## The tree a bird leaves, and the one it flies to.
	Flight : { from : Trees.RoadsideTree, to : Trees.RoadsideTree }

	## A bird at one instant: how it looks, and where it is.
	BirdInstant : Animation.Instant(PosedBird.BirdPose)

	## How far above a straight line the top of its path is.
	flight_arc : Distance
	flight_arc = Distance.metres(5.0)

	## How the bird looks through a flight, a frame a step: a flap side on as
	## it takes off, seven flaps seen from behind, and a flap's length of diving.
	flight_poses : List(PosedBird.BirdPose)
	flight_poses = [
		flap_poses(Side(WingsUp), Side(WingsDown)),
		List.repeat(flap_poses(Away(WingsUp), Away(WingsDown)), 7).join(),
		List.repeat(Diving, frames_a_flap),
	].join()

	## What the ride plans a flight by: its length, and the gap from the rider
	## to the tree it left at which it has landed.
	flight_span : Animation.StepSpan
	flight_span = {
		length: Steps.of(flight_poses.len().to_u32_wrap()),
		ends_at: Distance.metres(15.0),
	}

	## The flight of a bird perched on the tree at `perch`, among a segment's
	## `trees`: to the first tree on the other side of the road far enough along.
	flight_from : List(Trees.RoadsideTree),
	Trees.RoadsideTree -> Try(
		BirdFlight.Flight,
		[NoTreeToFlyTo],
	)
	flight_from = |trees, perch| {
		is_far_enough = |tree| tree.road_point.along >= perch.road_point.along.plus(shortest_hop)
		is_far_side = |tree| tree.road_point.across > Across.middle
		match trees.find_first(|tree| is_far_side(tree) and is_far_enough(tree)) {
			Ok(to) => Ok({ from: perch, to })
			Err(NotFound) => Err(NoTreeToFlyTo)
		}
	}

	## Where the flight has got to at `timing`.
	flight_stage : Animation.Timing -> Animation.Stage
	flight_stage = |timing| Animation.stage_at(timing, flight_span.length)

	## The bird at `stage` of its flight.
	instant_at : BirdFlight.Flight, Animation.Stage -> BirdFlight.BirdInstant
	instant_at = |flight, stage| flight_timeline(flight).instant(stage)
}

## The bird flies to a tree at least this far along from the one it left,
## so that its path runs ahead of the rider as well as across the road.
shortest_hop : Distance
shortest_hop = Distance.metres(25.0)

## How many steps one flap of the wings takes, half of them up and half down.
## At the rider's cruising 1.25 m a step a flap spans 5 m of road, as it did
## when a flight played by the road, eight frames a metre, 40 to a flap.
frames_a_flap : U64
frames_a_flap = 4

## The bird as it sits on top of `tree`.
sitting_on : Trees.RoadsideTree -> BirdFlight.BirdInstant
sitting_on = |tree| { pose: Perched, location: tree_top(tree) }

## The whole of a flight: `flight_poses`, on one smooth path that rises in
## the middle, from the tip of the tree it leaves to the tip of the one it
## lands on.
flight_timeline : BirdFlight.Flight -> Animation.Timeline(PosedBird.BirdPose)
flight_timeline = |{ from, to }| {
	ends = { from: tree_top(from), to: tree_top(to) }
	last_frame = (BirdFlight.flight_poses.len() - 1).to_f64()
	frames = BirdFlight.flight_poses.map_with_index(
		|pose, frame| {
			through = Fraction.of(frame.to_f64() / last_frame)
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

chosen_along : List(Trees.RoadsideTree) -> List(F64)
chosen_along = |choices|
	match BirdFlight.flight_from(choices, left_tree) {
		Ok({ to, .. }) => [to.road_point.along.to_metres(), to.road_point.across.to_metres()]
		Err(NoTreeToFlyTo) => []
	}

expect chosen_along(sample_trees) == [140.0, 6.0]
expect chosen_along([left_tree, tree_at(124.0, 6.0)]) == []
expect chosen_along([left_tree, tree_at(125.0, 6.0)]) == [125.0, 6.0]
expect chosen_along([left_tree, tree_at(140.0, -6.0)]) == []
expect BirdFlight.flight_from(sample_trees, left_tree).map_ok(|flight| flight.from) == Ok(left_tree)

## The bird `steps_in` steps into its flight.
frame_of : U32 -> BirdFlight.BirdInstant
frame_of = |steps_in| BirdFlight.instant_at(sample_flight, Playing(Steps.of(steps_in)))

expect {
	location = BirdFlight.instant_at(sample_flight, Waiting).location
	location.along.to_metres() == 100.0
		and location.across.to_metres() == -6.0
		and location.lift.to_metres() == red_top
}

expect {
	location = BirdFlight.instant_at(sample_flight, Past(Steps.zero)).location
	location.along.to_metres() == 140.0
		and location.across.to_metres() == 6.0
		and location.lift.to_metres() == gold_top
}

expect BirdFlight.instant_at(sample_flight, Waiting).pose == Perched
expect BirdFlight.instant_at(sample_flight, Past(Steps.zero)).pose == Perched

# A flap side on, seven from behind, and one of diving, four steps to a flap.
expect
	[
		(0, Side(WingsUp)),
		(1, Side(WingsUp)),
		(2, Side(WingsDown)),
		(3, Side(WingsDown)),
		(4, Away(WingsUp)),
		(6, Away(WingsDown)),
		(29, Away(WingsUp)),
		(31, Away(WingsDown)),
		(32, Diving),
		(35, Diving),
	].all(|(steps_in, pose)| frame_of(steps_in).pose == pose)

# The flight starts on the first tree's tip and ends on the second's, and its
# path rises over the straight line between them.
expect frame_of(0).location == BirdFlight.instant_at(sample_flight, Waiting).location
expect {
	last = frame_of(35).location
	[
		(last.along.to_metres(), 140.0),
		(last.across.to_metres(), 6.0),
		(last.lift.to_metres(), gold_top),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)
}
expect frame_of(18).location.lift.to_metres() > (red_top + gold_top) / 2.0 + 4.0
