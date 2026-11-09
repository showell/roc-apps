## The colors the Safari tutorial's widgets share, each named for what it is
## for. A widget's page, its buttons and the pictures that look down on the road
## all draw in these, so one change here moves every widget alike. A color only
## one widget uses, for something only that widget draws, stays in the widget.
import lib.RgbColor

WidgetPalette :: [].{

	## The words and the lines on the panel, and a label in the picture.
	ink_color : RgbColor
	ink_color = RgbColor.of(0x202020)

	## The panel under the picture, which the text and the buttons sit on.
	panel_color : RgbColor
	panel_color = RgbColor.of(0xDCECF5)

	## A button that isn't running the widget's number, and a mark already passed.
	unlit_button_color : RgbColor
	unlit_button_color = RgbColor.of(0x303030)

	## The play, step and stop signs on a button.
	button_icon_color : RgbColor
	button_icon_color = RgbColor.of(0xf7f5f0)

	## A second thing to pick out, such as the truck, the cat or the current
	## mark. A lit video recorder button is this color too.
	accent_color : RgbColor
	accent_color = RgbColor.of(0xd0603a)

	## The grass either side of the road, seen from above.
	plan_ground_color : RgbColor
	plan_ground_color = RgbColor.of(0x6f9a55)

	## The road's surface, seen from above.
	plan_road_color : RgbColor
	plan_road_color = RgbColor.of(0x4a4a46)

	## What a picture from above is about and stands out on the road: the rider,
	## the arc kept, the stretch read out.
	highlight_color : RgbColor
	highlight_color = RgbColor.of(0xf2efe4)

	## Where the rider aims or looks, in a picture from above: a bend's apex, the
	## line of sight, the line a rehearsal aims for.
	aim_color : RgbColor
	aim_color = RgbColor.of(0xf6d743)

	## Behind a picture that has no ground or sky of its own, such as the two
	## shapes and the stills.
	picture_background_color : RgbColor
	picture_background_color = RgbColor.of(0xf7f5f0)
}
