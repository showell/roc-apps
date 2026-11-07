## Where a cat crosses the road: how far along its segment, and its place across
## the road at the start and at the end. A cat crosses by a roadside tree on the
## right of the road. Wherever that tree stands, the cat starts behind it and
## just past it, freezes with its head over the middle of the road, and ends on
## the far verge.
import Across
import Along
import Distance
import PosedCat

CatCrossing := {
	along : Along,
	start_across : Across,
	end_across : Across,
}.{

	## Where every cat freezes across the road: with its head over the middle.
	mid_across : Across
	mid_across = Across.right_of_middle(frozen_head_reach)

	## How far behind its tree, away from the road, the cat starts.
	cat_behind_tree : Distance
	cat_behind_tree = Distance.metres(1.5)

	## How far past its tree, along the road, the cat crosses.
	cat_beyond_tree : Distance
	cat_beyond_tree = Distance.metres(2.0)

	## The crossing of a cat by `tree`, on the right of a road `road_half_width`
	## either side of its middle.
	by_tree : {
		road_half_width : Distance,
		tree : { along : Along, across : Across, .. },
	} -> CatCrossing
	by_tree = |{ road_half_width, tree }| {
		far_verge = Across.left_of_middle(road_half_width.plus(grass_toehold))
		{
			along: tree.along.plus(CatCrossing.cat_beyond_tree),
			start_across: tree.across.plus(CatCrossing.cat_behind_tree),
			end_across: far_verge.minus(collapsed_hip_reach),
		}
	}
}

## How far ahead of its feet the frozen cat's head is. Its still's head runs
## from 0.02 to 0.49 of its height ahead of them, so this is the head's
## centre.
frozen_head_reach : Distance
frozen_head_reach = PosedCat.cat_height.times(0.25)

## How far behind its feet the collapsed cat's hips lie: about 0.7 of its
## height in its still, with the hind feet themselves nearer 0.6.
collapsed_hip_reach : Distance
collapsed_hip_reach = PosedCat.cat_height.times(0.7)

## How far onto the far verge's grass the collapsed cat's hips lie.
grass_toehold : Distance
grass_toehold = Distance.metres(0.3)

the_cat : CatCrossing
the_cat = CatCrossing.by_tree({
	road_half_width: Distance.metres(2.0),
	tree: { along: Along.metres(100.0), across: Across.metres(3.0) },
})

## The same cat by a tree farther from the road.
the_cat_by_a_far_tree : CatCrossing
the_cat_by_a_far_tree = CatCrossing.by_tree({
	road_half_width: Distance.metres(2.0),
	tree: { along: Along.metres(100.0), across: Across.metres(8.0) },
})

expect the_cat.along.to_metres() == 102.0
expect the_cat.start_across.to_metres() == 4.5
expect the_cat_by_a_far_tree.start_across.to_metres() == 9.5
expect the_cat_by_a_far_tree.end_across == the_cat.end_across
expect CatCrossing.mid_across.to_metres() == 0.425
expect
	[
		(the_cat.end_across.to_metres(), -3.49),
		(CatCrossing.mid_across.distance_from(the_cat.end_across).to_metres(), 3.915),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)
