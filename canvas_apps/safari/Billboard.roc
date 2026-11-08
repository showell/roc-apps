## A billboard is an animal that stands in one place and always faces the
## camera: an emoji's still, at a height, facing left or right.
import Distance
import EmojiStills
import Picture
import StillShapes

Billboard :: {
	emoji : EmojiStills.EmojiStill,
	height : Distance,
	facing : Billboard.Facing,
}.{

	## Which way a billboard faces on screen.
	Facing : [FacesLeft, FacesRight]

	## A kind of animal: its emoji, and how tall a grown one stands.
	Species : { emoji : EmojiStills.EmojiStill, adult_height : Distance }

	## A grown animal of `species`.
	adult_billboard : Billboard.Species, Billboard.Facing -> Billboard
	adult_billboard = |species, facing|
		Billboard.({ emoji: species.emoji, height: species.adult_height, facing })

	## A young animal of `species`, which stands half as tall as a grown one.
	young_billboard : Billboard.Species, Billboard.Facing -> Billboard
	young_billboard = |species, facing|
		Billboard.(
			{
				emoji: species.emoji,
				height: species.adult_height.divided_by(2.0),
				facing,
			},
		)

	## Which way the billboard faces.
	facing : Billboard -> Billboard.Facing
	facing = |Billboard.(billboard)| billboard.facing

	scenery_height : Billboard -> Distance
	scenery_height = |Billboard.(billboard)| billboard.height

	## How far a billboard reaches to each side of its middle. An emoji's still
	## is square, so this is half its height.
	half_width : Billboard -> Distance
	half_width = |Billboard.(billboard)| billboard.height.divided_by(2.0)

	## How a billboard looks. An emoji faces left, so a billboard facing right
	## is its still mirrored.
	scenery_picture : Billboard, Picture.Setting({}) -> Picture
	scenery_picture = |Billboard.(billboard), setting| {
		flip =
			match billboard.facing {
				FacesLeft => AsDrawn
				FacesRight => Mirrored
			}
		anchor = StillShapes.standing_anchor(setting, { height: billboard.height, flip })
		Picture.from_shapes(StillShapes.still_shapes(anchor, billboard.emoji.still()))
	}

	is_eq : _
}
