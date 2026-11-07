## A billboard is a critter that stands in one place and always faces the
## camera: an emoji's still, at a height, facing left or right.
import Across
import Along
import Camera
import Distance
import EmojiStills
import Geom
import Picture
import Pixels
import SegmentPlace
import Spot
import StillShapes

Billboard := {
	still : EmojiStills.EmojiStill,
	height : Distance,
	facing : Billboard.Facing,
}.{

	## Which way a billboard faces on screen.
	Facing : [FacesLeft, FacesRight]

	## A kind of animal: its emoji, and how tall a grown one stands.
	Species : { still : EmojiStills.EmojiStill, adult_height : Distance }

	## A grown animal of `species`.
	adult_billboard : Billboard.Species, Billboard.Facing -> Billboard
	adult_billboard = |species, facing| {
		still: species.still,
		height: species.adult_height,
		facing,
	}

	## A young animal of `species`, which stands half as tall as a grown one.
	young_billboard : Billboard.Species, Billboard.Facing -> Billboard
	young_billboard = |species, facing| {
		still: species.still,
		height: species.adult_height.divided_by(2.0),
		facing,
	}

	scenery_height : Billboard -> Distance
	scenery_height = |billboard| billboard.height

	## How a billboard looks. An emoji faces left, so a billboard facing right
	## is its still mirrored. One less than a pixel tall isn't drawn.
	scenery_picture : Billboard, Picture.Setting({}) -> Picture
	scenery_picture = |billboard, { spot, cam_focal, .. }| {
		projected = |height| Camera.project(spot.foot().at_height(height), cam_focal)
		feet = projected(spot.lift())
		height_px = feet.y.minus(projected(spot.lift().plus(billboard.height)).y)
		if height_px < Pixels.of(1.0) {
			Picture.from_shapes([])
		} else {
			flip =
				match billboard.facing {
					FacesLeft => AsDrawn
					FacesRight => Mirrored
				}
			Picture.from_shapes(
				StillShapes.still_shapes({ feet, flip, height_px }, billboard.still.polygons()),
			)
		}
	}

	is_eq : _
}

# How many shapes draw a billboard of `height` metres, `forward` metres ahead.
shape_count : {
	forward : Distance,
	height : Distance,
	still : EmojiStills.EmojiStill,
} -> U64
shape_count = |{ forward, height, still }| {
	billboard : Billboard
	billboard = { still, height, facing: FacesLeft }
	foot = Geom.ahead_on_level({
		right: Distance.zero,
		forward,
	}) ?? crash "a test's billboard is past the near plane"
	spot = Spot.at({
		place: Ahead(SegmentPlace.Position.first),
		road_point: { along: Along.metres(forward.to_metres()), across: Across.middle },
		lift: Distance.zero,
		foot,
	})
	billboard.scenery_picture({ spot, cam_focal: Pixels.of(500.0), context: {} }).to_shapes().len()
}

# A billboard is drawn while it stands a pixel tall.
expect
	shape_count({
		forward: Distance.metres(1000.0),
		height: Distance.metres(2.0),
		still: EmojiStills.elephant,
	})
		== 6
expect
	shape_count({
		forward: Distance.metres(2000.0),
		height: Distance.metres(2.0),
		still: EmojiStills.elephant,
	})
		== 0
expect
	shape_count({
		forward: Distance.metres(1000.0),
		height: Distance.metres(1.9),
		still: EmojiStills.elephant,
	})
		== 0
expect
	shape_count({
		forward: Distance.metres(100.0),
		height: Distance.metres(2.0),
		still: EmojiStills.elephant,
	})
		== 6

expect EmojiStills.elephant.polygons().len() == 6
