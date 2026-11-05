## What a segment's crossing does to the rider. The rider reacts only to the
## crossing on their own segment, though animations play along the chain ahead,
## and this is the one place that knows which crossings ask anything of them.
## A cat in the lane stops the rider opening the throttle, without braking, and
## draws their eye. A bird asks nothing. The pigs' gaze is no crossing, and is
## Gaze's.
import Along
import Attention
import Cat
import Speed
import World

CrossingReaction :: [].{

	## What a crossing does to the rider now: whether they may open the
	## throttle, and how hard it holds their eye.
	Reaction : { throttle : [MayAccelerate, NoAcceleration], eye_pull : Attention }

	## The reaction to `segment`'s crossing of a rider on that segment.
	reaction_to : World.Segment,
	{
		along : Along,
		speed : Speed,
		..others,
	} -> CrossingReaction.Reaction
	reaction_to = |segment, rider|
		match segment.crossing {
			CatCrosses(crossing) => {
				approach = { gap: crossing.along.distance_from(rider.along), speed: rider.speed }
				{
					throttle: if (Cat.is_in_danger(approach)) NoAcceleration else MayAccelerate,
					eye_pull: Cat.focus(approach),
				}
			}
			BirdFlies(_) | QuietRoad => { throttle: MayAccelerate, eye_pull: Attention.none }
		}
}
