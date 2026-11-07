## A conifer's kind, which sets its height, from the ground to the tip of its
## crown, where a bird perches, and its color. `TreeShapes` draws a tree of that
## height and color, and where it stands beside a road comes from `Trees`.
import Distance
import Picture
import TreeShapes
import lib.RgbColor

Conifer := [BigGreen, SmallGreen, Red, Gold].{

	## A small green tree's height.
	small_height : Distance
	small_height = Distance.metres(4.896)

	## A big green tree's height.
	big_height : Distance
	big_height = small_height.times(1.3)

	scenery_height : Conifer -> Distance
	scenery_height = |conifer|
		match conifer {
			BigGreen => big_height
			SmallGreen => small_height
			Red => small_height.times(2.0)
			Gold => small_height.times(3.0)
		}

	## How a conifer looks. How much detail it gets depends on how many trees
	## are nearer than it, which it can't know alone, so that is its context.
	scenery_picture : Conifer, Picture.Setting({ nearer_tree_count : U16 }) -> Picture
	scenery_picture = |conifer, { foot, cam_focal, context }|
		TreeShapes.tree_picture(
			{
				tree: {
					foot,
					height: conifer.scenery_height(),
					foliage_color: foliage_color(conifer),
				},
				nearer_tree_count: context.nearer_tree_count,
			},
			cam_focal,
		)

	is_eq : _
}

green_color : RgbColor
green_color = RgbColor.of(0x1C5A22)

gold_color : RgbColor
gold_color = RgbColor.of(0xCF9A18)

red_color : RgbColor
red_color = RgbColor.of(0xB23A2A)

## A conifer's foliage color.
foliage_color : Conifer -> RgbColor
foliage_color = |conifer|
	match conifer {
		BigGreen | SmallGreen => green_color
		Gold => gold_color
		Red => red_color
	}

expect
	[
		(Conifer.BigGreen, 6.3648),
		(Conifer.SmallGreen, 4.896),
		(Conifer.Red, 9.792),
		(Conifer.Gold, 14.688),
	].all(|(conifer, want)| (conifer.scenery_height().to_metres() - want).abs() <= 0.000000001)

expect foliage_color(Conifer.BigGreen) == RgbColor.of(0x1C5A22)
expect foliage_color(Conifer.SmallGreen) == RgbColor.of(0x1C5A22)
expect foliage_color(Conifer.Gold) == RgbColor.of(0xCF9A18)
expect foliage_color(Conifer.Red) == RgbColor.of(0xB23A2A)
