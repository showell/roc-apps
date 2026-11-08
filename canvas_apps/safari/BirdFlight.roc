## Where a Roc bird is and how it looks. A bird sits on the fifth tree on the
## left of a segment until its flight starts, then flies diagonally ahead,
## across the road, to the next tree on the far side, and perches there. Its
## flight plays a frame a step at its own pace, and the ride plans its start so
## that it lands as the rider comes within `landing_gap` of the tree it left.
import Across
import Animation
import EncounterPlan
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

	## How the bird looks through a flight, a frame a step: a flap side on as
	## it takes off, seven flaps seen from behind, and a flap's length of diving.
	flight_poses : List(PosedBird.BirdPose)
	flight_poses = [
		flap_poses({ up: Side(WingsUp), down: Side(WingsDown) }),
		List.repeat(flap_poses({ up: Away(WingsUp), down: Away(WingsDown) }), 7).join(),
		List.repeat(Diving, frames_a_flap),
	].join()

	## What the ride plans a flight by: its length, and the gap from the rider
	## to the tree it left at which it has landed.
	flight_span : EncounterPlan.StepSpan
	flight_span = { length: Steps.of(flight_poses.len().to_u32_wrap()), ends_at: landing_gap }

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
	flight_stage : EncounterPlan.Timing -> Animation.Stage
	flight_stage = |timing| EncounterPlan.stage_at(timing, flight_span.length)

	## The bird at `stage` of its flight.
	instant_at : BirdFlight.Flight, Animation.Stage -> BirdFlight.BirdInstant
	instant_at = |flight, stage| flight_timeline(flight).instant(stage)
}

## How far short of the tree it left the rider is when the bird lands.
landing_gap : Distance
landing_gap = Distance.metres(15.0)

## How far above a straight line the top of its path is.
flight_arc : Distance
flight_arc = Distance.metres(5.0)

## The bird flies to a tree at least this far along from the one it left,
## so that its path runs ahead of the rider as well as across the road.
shortest_hop : Distance
shortest_hop = Distance.metres(25.0)

## How many steps one flap of the wings takes, half up and half down.
frames_a_flap : U64
frames_a_flap = 4

## The bird as it sits on top of `tree`.
sitting_on : Trees.RoadsideTree -> BirdFlight.BirdInstant
sitting_on = |tree| { pose: Perched, location: tree_top(tree) }

## The whole of a flight: `flight_poses`, on one smooth path that rises in
## the middle, from the tip of the tree it leaves to the tip of the one it
## lands on.
flight_timeline : BirdFlight.Flight -> Animation.Timeline(PosedBird.BirdPose, PosedBird.BirdPose)
flight_timeline = |{ from, to }| {
	ends = { from: tree_top(from), to: tree_top(to) }
	last_frame = (BirdFlight.flight_poses.len() - 1).to_f64()
	Animation.Timeline.of({
		before: sitting_on(from),
		frames: BirdFlight.flight_poses,
		frame_instant: |pose, frame_number| {
			through = Fraction.of(frame_number.to_f64() / last_frame)
			{ pose, location: flight_location({ from: ends.from, to: ends.to, through }) }
		},
		after: sitting_on(to),
	})
}

## The location on top of `tree`.
tree_top : Trees.RoadsideTree -> Animation.Location
tree_top = |tree| {
	along: tree.road_point.along,
	across: tree.road_point.across,
	lift: tree.kind.scenery_height(),
}

## One flap of the wings: `up` for half its frames and `down` for the rest.
flap_poses : { up : PosedBird.BirdPose, down : PosedBird.BirdPose } -> List(PosedBird.BirdPose)
flap_poses = |{ up, down }| {
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
	above_line = flight_arc.times(4.0 * share * (1.0 - share))
	{ ..on_line, lift: on_line.lift.plus(above_line) }
}
