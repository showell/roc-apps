## Where a Roc bird is and how it looks. A bird sits on the fifth tree on the
## left of a segment until the rider comes near, then flies diagonally ahead,
## across the road, to the next tree on the far side, and perches there. Where
## it is depends only on how far the rider is from the tree it left, as the
## cat's crossing does, so stepping back through a ride shows the same bird.
## A bird's spots are places on its segment, as its trees' are, because its
## flight is its own and no other bird shares it.
import Across
import Along
import Animation
import Beat
import Beats
import Conifer
import Distance
import Fraction
import Trees

BirdFlight :: [].{

	## The tree a bird leaves, and the one it flies to.
	Flight : { from : Trees.Tree, to : Trees.Tree }

	## What a segment's bird does: flies from one tree to another, or sits,
	## when there's no tree to fly to.
	Habit : [Flies(BirdFlight.Flight), Sits(Trees.Tree)]

	## Where the wings are in a beat.
	WingBeat : [WingsUp, WingsDown]

	## How the bird looks: sitting; side on as it takes off; seen from behind
	## as it flies off; and dropping onto its tree.
	Pose : [
		Perched,
		Side(BirdFlight.WingBeat),
		Away(BirdFlight.WingBeat),
		Diving,
	]

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

	## How many times the wings flap in a flight.
	wing_flaps : U32
	wing_flaps = 9

	## The share of a flight spent side on, taking off.
	takeoff_share : Fraction
	takeoff_share = Fraction.of(0.12)

	## The share of a flight spent dropping to land.
	landing_share : Fraction
	landing_share = Fraction.of(0.12)

	## How far through the flight its landing starts.
	landing_start : Fraction
	landing_start = landing_share.complement()

	## The tree a bird starts on, the fifth with a negative `across`. Those are
	## on the left, and an unflipped still's beak points toward +x, so from
	## there the bird faces the road.
	fifth_left_tree : List(Trees.Tree) -> [Found(Trees.Tree), NoTree]
	fifth_left_tree = |trees|
		match trees.keep_if(|tree| tree.across < Across.middle).drop_first(4).first() {
			Ok(tree) => Found(tree)
			Err(ListWasEmpty) => NoTree
		}

	## The habit of a bird on the tree at `from`: to the first tree on the
	## other side of the road far enough along, or none, and it sits.
	habit_from : List(Trees.Tree), Trees.Tree -> BirdFlight.Habit
	habit_from = |trees, from| {
		is_far_enough = |tree| tree.along >= from.along.plus(shortest_hop)
		far_side = trees.keep_if(|tree| tree.across > Across.middle and is_far_enough(tree))
		match far_side.first() {
			Ok(to) => Flies({ from, to })
			Err(ListWasEmpty) => Sits(from)
		}
	}

	## The bird of a segment with `trees`, if one has a tree to start on.
	crossing_among : List(Trees.Tree) -> [BirdHere(BirdFlight.Habit), QuietRoad]
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
	flight_stage : Distance -> Animation.Stage
	flight_stage = |gap| Animation.over_gap({ starts_at: takeoff_gap, ends_at: landing_gap }, gap)

	## The bird with `habit`, with the rider `gap` from the tree it starts on.
	habit_instant_at : BirdFlight.Habit, Distance -> Animation.Instant(BirdFlight.Pose, Distance)
	habit_instant_at = |habit, gap|
		match habit {
			Flies(flight) => instant_at(flight, gap)
			Sits(tree) => sitting_on(tree)
		}

	## The bird with the rider `gap` from the tree it left.
	instant_at : BirdFlight.Flight, Distance -> Animation.Instant(BirdFlight.Pose, Distance)
	instant_at = |flight, gap| flight_timeline(flight).instant(flight_stage(gap))

	## The bird as it sits on top of `tree`.
	sitting_on : Trees.Tree -> Animation.Instant(BirdFlight.Pose, Distance)
	sitting_on = |tree| { pose: Perched, spot: tree_top(tree) }

	## A flight's timeline is one beat long, so a cut on it is a share of the
	## flight.
	flight_beats : Beats
	flight_beats = Beats.of(1.0)

	## The whole of a flight: side on as it takes off, then seen from behind,
	## beating its wings all the way until it dives, on one smooth path that
	## rises in the middle.
	flight_timeline : BirdFlight.Flight -> Animation.Timeline(BirdFlight.Pose, Distance)
	flight_timeline = |{ from, to }|
		Animation.Timeline.(
			{
				length: flight_beats,
				before: sitting_on(from),
				after: sitting_on(to),
				looks: {
					stretches: [
						{
							until: Before(Beat.at(flight_beats.portion(takeoff_share))),
							plays: wings_beating({ up: Side(WingsUp), down: Side(WingsDown) }),
						},
						{
							until: Through(Beat.at(flight_beats.portion(landing_start))),
							plays: wings_beating({ up: Away(WingsUp), down: Away(WingsDown) }),
						},
					],
					finally: Holds(Diving),
				},
				path: {
					stretches: [],
					finally: Arc({
						line: {
							from: tree_top(from),
							to: tree_top(to),
							ease: Smooth,
						},
						rise: flight_arc,
					}),
				},
			},
		)
}

## The spot on top of `tree`.
tree_top : Trees.Tree -> Animation.Spot(Distance)
tree_top = |tree| {
	along: tree.along,
	across: tree.across,
	lift: tree.conifer.height(),
}

## A bird that shows `up` and `down` in turn, as its wings beat through the
## flight.
wings_beating : { up : BirdFlight.Pose, down : BirdFlight.Pose } -> Animation.Looks(BirdFlight.Pose)
wings_beating = |{ up, down }|
	Alternates({
		up,
		down,
		count: BirdFlight.wing_flaps,
		over: BirdFlight.flight_beats,
	})

tree_at : F64, F64 -> Trees.Tree
tree_at = |along, across| {
	along: Along.metres(along),
	across: Across.metres(across),
	conifer: Conifer.Red,
}

left_tree : Trees.Tree
left_tree = tree_at(100.0, -6.0)

## A tree on the far side too near to fly to, and two far enough.
sample_trees : List(Trees.Tree)
sample_trees = [
	left_tree,
	tree_at(100.0, 6.0),
	tree_at(140.0, -6.0),
	tree_at(140.0, 6.0),
	tree_at(180.0, 6.0),
]

sample_flight : BirdFlight.Flight
sample_flight = { from: left_tree, to: { ..tree_at(140.0, 6.0), conifer: Conifer.Gold } }

## How high a bird perches on a red tree, and on a gold one.
red_top : F64
red_top = Conifer.Red.height().to_metres()

gold_top : F64
gold_top = Conifer.Gold.height().to_metres()

## A left and a right tree at each of `alongs`.
pairs_at : List(F64) -> List(Trees.Tree)
pairs_at = |alongs| alongs.join_map(|along| [tree_at(along, -6.0), tree_at(along, 6.0)])

## How far along the fifth left tree of `choices` is: one number, or none.
fifth_along : List(Trees.Tree) -> List(F64)
fifth_along = |choices|
	match BirdFlight.fifth_left_tree(choices) {
		Found(tree) => [tree.along.to_metres()]
		NoTree => []
	}

expect fifth_along([]) == []
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0])) == []
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0, 50.0])) == [50.0]
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0, 50.0, 60.0])) == [50.0]
expect fifth_along([50.0, 60.0, 70.0, 80.0, 90.0].map(|along| tree_at(along, 6.0))) == []

chosen_along : List(Trees.Tree) -> List(F64)
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
	match BirdFlight.flight_stage(gap) {
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
	spot = BirdFlight.instant_at(sample_flight, Distance.metres(100.0)).spot
	spot.along.to_metres() == 100.0
		and spot.across.to_metres() == -6.0
		and spot.lift.to_metres() == red_top
}

expect {
	spot = BirdFlight.instant_at(sample_flight, Distance.zero).spot
	spot.along.to_metres() == 140.0
		and spot.across.to_metres() == 6.0
		and spot.lift.to_metres() == gold_top
}

expect {
	spot = BirdFlight.instant_at(sample_flight, halfway_gap).spot
	[
		(spot.along.to_metres(), 120.0),
		(spot.across.to_metres(), 0.0),
		(spot.lift.to_metres(), (red_top + gold_top) / 2.0 + BirdFlight.flight_arc.to_metres()),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)
}

expect BirdFlight.instant_at(sample_flight, Distance.metres(100.0)).pose == Perched
expect BirdFlight.instant_at(sample_flight, Distance.zero).pose == Perched

expect
	[
		(0.01, Side(WingsUp)),
		(0.08, Side(WingsDown)),
		(0.1199, Side(WingsUp)),
		(0.12, Away(WingsUp)),
		(0.5 - 1.0 / 36.0, Away(WingsUp)),
		(0.5 + 1.0 / 36.0, Away(WingsDown)),
		(0.87, Away(WingsDown)),
		(0.89, Diving),
		(0.95, Diving),
	].all(
		|(progress, pose)|
			BirdFlight.flight_timeline(sample_flight).at_beat(Beat.of(progress)).pose == pose,
	)
