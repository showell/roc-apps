## Conifer is a kind of tree. It sets the tree's height, from the ground to the
## tip where a bird perches, and its color. TreeShapes draws it, and Trees places
## it beside the road.
import Distance
import Picture
import TreeShapes
import lib.RgbColor

Conifer := [Green, SmallGreen, Red, Gold].{

	## A red tree is twice a small one's height and a gold one three times,
	## sizes chosen by eye.
	scenery_height : Conifer -> Distance
	scenery_height = |conifer|
		match conifer {
			Green => green_height
			SmallGreen => small_height
			Red => small_height.times(2.0)
			Gold => small_height.times(3.0)
		}

	## How a conifer looks. How much detail it gets depends on how many trees
	## are nearer than it, which it can't know alone, so that is its context.
	scenery_picture : Conifer, Picture.Setting(TreeShapes.Detail) -> Picture
	scenery_picture = |conifer, setting|
		TreeShapes.tree_picture(
			setting,
			{ height: conifer.scenery_height(), foliage_color: foliage_color(conifer) },
		)

	is_eq : _
}

## A small green tree's height, chosen by eye.
small_height : Distance
small_height = Distance.metres(4.896)

## A green tree's height, 1.3 times a small one's, a size chosen by eye.
green_height : Distance
green_height = small_height.times(1.3)

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
		Green | SmallGreen => green_color
		Gold => gold_color
		Red => red_color
	}
