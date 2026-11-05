## Where a Roc bird is and how it looks. A bird sits on the fifth tree on the
## left of a segment until the rider comes near, then flies diagonally ahead,
## across the road, to the next tree on the far side, and perches there. Where
## it is depends only on how far the rider is from the tree it left, as the
## cat's crossing does, so stepping back through a ride shows the same bird.
import Easing
import lib.Trig
import Scenery

BirdFlight :: [].{

	## The tree a bird leaves, and the one it flies to.
	Flight : { from : Scenery.Tree, to : Scenery.Tree }

	## Where the wings are in a beat.
	WingBeat : [WingsUp, WingsDown]

	## How the bird looks: sitting; side on as it takes off; seen from behind
	## as it flies off; and dropping onto its tree.
	Pose : [Perched, Side(BirdFlight.WingBeat), Away(BirdFlight.WingBeat), Diving]

	## The bird at a moment: how it looks, how far along its segment it is, its
	## place across the road, and how high its feet are.
	BirdState : {
		pose : BirdFlight.Pose,
		along : F64,
		across : F64,
		lift : F64,
	}

	## How far the rider is from the bird's tree when it takes off.
	takeoff_gap : F64
	takeoff_gap = 60.0

	## How far the rider is from that tree when the bird has landed.
	landing_gap : F64
	landing_gap = 15.0

	## The bird flies to a tree at least this far along from the one it left,
	## so that its path runs ahead of the rider as well as across the road.
	shortest_hop : F64
	shortest_hop = 25.0

	## How far above a straight line the top of its path is, in metres.
	flight_arc : F64
	flight_arc = 5.0

	## How many times the wings beat in a flight.
	wing_beats : F64
	wing_beats = 9.0

	## The share of a flight spent side on, taking off.
	takeoff_share : F64
	takeoff_share = 0.12

	## The share of a flight spent dropping to land.
	landing_share : F64
	landing_share = 0.12

	## The tree a bird starts on, the fifth with a negative `across`. Those are
	## on the left, and an unflipped still's beak points toward +x, so from
	## there the bird faces the road.
	fifth_left_tree : List(Scenery.Tree) -> [Found(Scenery.Tree), NoTree]
	fifth_left_tree = |trees|
		match trees.keep_if(|tree| tree.across < 0.0).drop_first(4).first() {
			Ok(tree) => Found(tree)
			Err(ListWasEmpty) => NoTree
		}

	## The flight of a bird on the tree at `from`: to the first tree on the
	## other side of the road far enough along, or none, and it stays put.
	flight_from : List(Scenery.Tree), Scenery.Tree -> [Flies(BirdFlight.Flight), Stays]
	flight_from = |trees, from| {
		is_far_enough = |tree| tree.along >= from.along + shortest_hop
		far_side = trees.keep_if(|tree| tree.across > 0.0 and is_far_enough(tree))
		match far_side.first() {
			Ok(to) => Flies({ from, to })
			Err(ListWasEmpty) => Stays
		}
	}

	## How far through its flight the bird is, from 0 to 1, with the rider
	## `gap` metres from the tree it left.
	flight_progress : F64 -> F64
	flight_progress = |gap| Easing.clamp01((takeoff_gap - gap) / (takeoff_gap - landing_gap))

	## The bird with the rider `gap` metres from the tree it left.
	state : BirdFlight.Flight, F64 -> BirdFlight.BirdState
	state = |flight, gap| {
		progress = flight_progress(gap)
		if progress <= 0.0 {
			sitting_on(flight.from)
		} else if progress >= 1.0 {
			sitting_on(flight.to)
		} else {
			flying(flight, progress)
		}
	}

	## The bird as it sits on top of `tree`.
	sitting_on : Scenery.Tree -> BirdFlight.BirdState
	sitting_on = |tree| {
		pose: Perched,
		along: tree.along,
		across: tree.across,
		lift: tree.height,
	}

	## How the bird looks `progress` of the way through its flight.
	pose_at : F64 -> BirdFlight.Pose
	pose_at = |progress|
		if progress > 1.0 - landing_share {
			Diving
		} else if progress < takeoff_share {
			Side(wing_beat_at(progress))
		} else {
			Away(wing_beat_at(progress))
		}
}

## Where the wings are `progress` of the way through a flight.
wing_beat_at : F64 -> BirdFlight.WingBeat
wing_beat_at = |progress|
	if Trig.r_sin(progress * BirdFlight.wing_beats * Trig.two_pi) > 0.0 {
		WingsUp
	} else {
		WingsDown
	}

## The bird `progress` of the way along a smooth path that rises in the middle.
flying : BirdFlight.Flight, F64 -> BirdFlight.BirdState
flying = |{ from, to }, progress| {
	eased = Easing.smoothstep(progress)
	between = |start, end|
		Easing.lerp({
			from: start,
			to: end,
			fraction: eased,
		})
	arc = BirdFlight.flight_arc * 4.0 * progress * (1.0 - progress)
	{
		pose: BirdFlight.pose_at(progress),
		along: between(from.along, to.along),
		across: between(from.across, to.across),
		lift: between(from.height, to.height) + arc,
	}
}
