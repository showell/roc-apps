## Where a cat crosses the road: how far along its segment, and its place across
## the road at the start and at the end. A cat crosses by a roadside tree on the
## right of the road. Wherever that tree stands, the cat starts behind it and
## just past it, freezes with its head over the middle of the road, and ends on
## the far verge.
import Across
import Along
import Distance
import Geom
import PosedCat

CatCrossing :: { along : Along, start_across : Across }.{

	## How far along its segment the cat crosses.
	along : CatCrossing -> Along
	along = |CatCrossing.(crossing)| crossing.along

	## Where across the road the cat starts, behind its tree.
	start_across : CatCrossing -> Across
	start_across = |CatCrossing.(crossing)| crossing.start_across

	## Where across the road every cat ends: on the far verge, its hips on the
	## grass.
	end_across : Across
	end_across =
		Across.left_of_middle(Geom.road_half_width.plus(grass_toehold))
			.minus(PosedCat.collapsed_hip_reach)

	## Where every cat freezes across the road: with its head over the middle.
	mid_across : Across
	mid_across = Across.right_of_middle(PosedCat.frozen_head_reach)

	## How far behind its tree, away from the road, the cat starts.
	cat_behind_tree : Distance
	cat_behind_tree = Distance.metres(1.5)

	## How far past its tree, along the road, the cat crosses.
	cat_beyond_tree : Distance
	cat_beyond_tree = Distance.metres(2.0)

	## The crossing of a cat by `tree`, on the right of the road.
	by_tree : { tree : { along : Along, across : Across, .. } } -> CatCrossing
	by_tree = |{ tree }|
		CatCrossing.(
			{
				along: tree.along.plus(CatCrossing.cat_beyond_tree),
				start_across: tree.across.plus(CatCrossing.cat_behind_tree),
			},
		)
}

## How far onto the far verge's grass the collapsed cat's hips lie.
grass_toehold : Distance
grass_toehold = Distance.metres(0.3)

the_cat : CatCrossing
the_cat = CatCrossing.by_tree({ tree: { along: Along.metres(100.0), across: Across.metres(3.0) } })

## The same cat by a tree farther from the road.
the_cat_by_a_far_tree : CatCrossing
the_cat_by_a_far_tree = CatCrossing.by_tree({
	tree: { along: Along.metres(100.0), across: Across.metres(8.0) },
})

expect the_cat.along().to_metres() == 102.0
expect the_cat.start_across().to_metres() == 4.5
expect the_cat_by_a_far_tree.start_across().to_metres() == 9.5
expect
	[
		(CatCrossing.end_across.to_metres(), -3.49),
		(CatCrossing.mid_across.distance_from(CatCrossing.end_across).to_metres(), 3.915),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)
