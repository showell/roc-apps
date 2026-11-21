## ChairGame draws the musical chairs as MusicalChairs places them: the
## chairs dropping in and standing in their row, the robots going round,
## diving and sat, and the boombox thumping with notes popping out of it.
## Each chair, robot and the boombox is a layer with the spot on the lawn it
## stands on, so the yard paints it among the tables and the army, farthest
## from the eye first. The notes float over everything. The drum major is
## the army's, so Army draws it.
import lib.Brush
import lib.RgbColor
import lib.Shapes
import Figure
import MusicalChairs
import Robot
import Table
import View

ChairGame :: [].{

	## The chairs, the robots and the boombox at `tick`, each on its spot.
	game_layers : View, I64 -> List({ spot : { right : F64, forward : F64 }, shapes : List(Shapes.Shape) })
	game_layers = |view, tick| {
		chairs = MusicalChairs.chairs_at(tick).map(
			|{ chair, drop }| {
				spot: { right: chair.right, forward: chair.forward },
				shapes: Table.chair_shapes(view.raised_view(drop), { chair, pulled: 0.0 }),
			},
		)
		# A robot is a little nearer the eye than the chair it sits on, from
		# the aisle and from down the yard alike, so it is painted over it.
		players = MusicalChairs.players_at(tick).map(
			|player| {
				spot: { right: player.feet.right + 0.02, forward: player.feet.forward - 0.02 },
				shapes: player_shapes(view, player),
			},
		)
		boombox =
			match MusicalChairs.boombox_at(tick) {
				In(box) => [{ spot: { right: box.at.right, forward: box.at.forward }, shapes: boombox_shapes(view, box) }]
				Out => []
			}
		[chairs, players, boombox].join()
	}

	## The notes in the air at `tick`, over everything else in the yard.
	note_shapes : View, I64 -> List(Shapes.Shape)
	note_shapes = |view, tick|
		MusicalChairs.notes_at(tick)
			.map(
				|note|
					match view.sighting(note.at) {
						Ok({ point, pixels_per_metre }) =>
							one_note_shapes(
								{ x: point.x.to_f64(), y: point.y.to_f64(), scale: pixels_per_metre },
								note,
							)
						Err(BehindEye) => []
					},
			)
			.join()
}

player_shapes : View, MusicalChairs.Player -> List(Shapes.Shape)
player_shapes = |view, { build, feet, pose, hips_up }|
	match view.sighting(feet) {
		Ok({ point, pixels_per_metre }) =>
			Robot.perched_figure_shapes({ build, pose, feet: point, pixels_per_metre, hips_up })
		Err(BehindEye) => []
	}

# A boombox face on: a dark case with a handle, a tape window, and two
# speakers whose cones jump out on the beat.
boombox_shapes : View, MusicalChairs.Boombox -> List(Shapes.Shape)
boombox_shapes = |view, { at, thump }|
	match view.sighting(at) {
		Ok({ point, pixels_per_metre }) => {
			place = { x: point.x.to_f64(), y: point.y.to_f64(), scale: pixels_per_metre }
			handle = [
				Figure.bar(
					place,
					{
						from: { across: -0.24, up: 0.44 },
						to: { across: -0.2, up: 0.58 },
						width: 0.035,
						fill: chrome,
					},
				),
				Figure.bar(
					place,
					{
						from: { across: 0.24, up: 0.44 },
						to: { across: 0.2, up: 0.58 },
						width: 0.035,
						fill: chrome,
					},
				),
				Figure.bar(
					place,
					{
						from: { across: -0.2, up: 0.58 },
						to: { across: 0.2, up: 0.58 },
						width: 0.035,
						fill: chrome,
					},
				),
			]
			case = [
				Figure.box(
					place,
					{
						left: -0.42,
						bottom: 0.0,
						width: 0.84,
						height: 0.46,
						corner: 0.06,
						fill: case_paint,
					},
				),
				Figure.box(
					place,
					{
						left: -0.07,
						bottom: 0.24,
						width: 0.14,
						height: 0.12,
						corner: 0.02,
						fill: tape,
					},
				),
			]
			speakers =
				[-0.25, 0.25]
					.map(
						|across| [
							Figure.dot(place, { at: { across, up: 0.2 }, radius: 0.15, fill: chrome }),
							Figure.dot(
								place,
								{ at: { across, up: 0.2 }, radius: 0.09 + 0.04 * thump, fill: cone },
							),
							Figure.dot(place, { at: { across, up: 0.2 }, radius: 0.03, fill: chrome }),
						],
					)
					.join()
			[handle, case, speakers].join()
		}
		Err(BehindEye) => []
	}

# A quaver: a round head, a stem and a flag, fading out as it goes.
one_note_shapes : Figure.Place, MusicalChairs.Note -> List(Shapes.Shape)
one_note_shapes = |place, { color, fade, .. }| {
	ink = note_colors.get(color) ?? crash "ChairGame.one_note_shapes: three note colors"
	fill = Flat({ ..ink, a: 1.0 - fade })
	[
		Figure.dot(place, { at: { across: 0.0, up: 0.0 }, radius: 0.08, fill }),
		Figure.bar(
			place,
			{
				from: { across: 0.065, up: 0.0 },
				to: { across: 0.065, up: 0.32 },
				width: 0.03,
				fill,
			},
		),
		Figure.bar(
			place,
			{
				from: { across: 0.065, up: 0.32 },
				to: { across: 0.18, up: 0.2 },
				width: 0.04,
				fill,
			},
		),
	]
}

note_colors : List(Brush.Rgba)
note_colors = [0xFFD45A, 0xFF7FB0, 0x7FE8FF].map(|hex| Brush.opaque_rgba(RgbColor.of(hex)))

case_paint : Brush.Fill
case_paint = Brush.flat(RgbColor.of(0x2E2A3D))

chrome : Brush.Fill
chrome = Brush.flat(RgbColor.of(0xC4C8D4))

cone : Brush.Fill
cone = Brush.flat(RgbColor.of(0x15121D))

tape : Brush.Fill
tape = Brush.flat(RgbColor.of(0xE8A33D))
