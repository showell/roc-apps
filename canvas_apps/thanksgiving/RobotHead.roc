## RobotHead draws a dinner guest's head from its proportions: the antenna on
## top, the neck, the head, and the face, whose eyes light up like the string
## lights and slide to look across the table.
import lib.Brush
import lib.Pixels
import lib.RgbColor
import lib.Shapes
import Figure
import RobotBody

RobotHead :: [].{

	## The antenna on top of the head, its tip lit with the eyes.
	antenna_shapes : Figure.Place,
	{
		body : RobotBody.Proportions,
		head_top : F64,
		glow : F64,
	} -> List(Shapes.Shape)
	antenna_shapes = |place, { body, head_top, glow }|
		if body.antenna > 0.0 {
			[
				Figure.bar(
					place,
					{
						from: { across: 0.0, up: head_top },
						to: { across: 0.0, up: head_top + body.antenna },
						width: 0.018,
						fill: Flat(body.trim),
					},
				),
				Figure.dot(
					place,
					{
						at: { across: 0.0, up: head_top + body.antenna },
						radius: 0.03,
						fill: Flat(antenna_tip(glow)),
					},
				),
			]
		} else {
			[]
		}

	## The neck and the head, then its two eyes and mouth. Lit eyes add a
	## glow around them, the color of the string lights; `look` slides them
	## toward the screen's right.
	head_shapes : Figure.Place,
	{
		body : RobotBody.Proportions,
		top : F64,
		glow : F64,
		look : F64,
	} -> List(Shapes.Shape)
	head_shapes = |place, { body, top, glow, look }| {
		head_bottom = top + body.neck
		neck_and_head = [
			Figure.bar(
				place,
				{
					from: { across: 0.0, up: top - 0.01 },
					to: { across: 0.0, up: head_bottom + 0.01 },
					width: body.head_width * 0.3,
					fill: Flat(body.trim),
				},
			),
			Figure.box(
				place,
				{
					left: 0.0 - body.head_width / 2.0,
					bottom: head_bottom,
					width: body.head_width,
					height: body.head_height,
					corner: body.head_height * 0.3,
					fill: Flat(body.paint),
				},
			),
		]
		List.concat(neck_and_head, face_shapes(place, { body, head_bottom, glow, look }))
	}

	## The color of a lit eye, the string lights' warm white.
	lit_eye : Brush.Rgba
	lit_eye = Brush.opaque_rgba(RgbColor.of(0xFFD98A))

}

face_shapes : Figure.Place,
{
	body : RobotBody.Proportions,
	head_bottom : F64,
	glow : F64,
	look : F64,
} -> List(Shapes.Shape)
face_shapes = |place, { body, head_bottom, glow, look }| {
	slide = look * body.head_width * 0.14
	eye_up = head_bottom + body.head_height * 0.58
	eye_apart = body.head_width * 0.24
	eye_radius = body.head_height * 0.14
	eye_fill = Flat(
		Brush.mix({
			from: dark_eye,
			to: RobotHead.lit_eye,
			fraction: glow,
		}),
	)
	eyes = [-1.0, 1.0].map(
		|side| Figure.dot(
			place,
			{
				at: { across: slide + side * eye_apart, up: eye_up },
				radius: eye_radius,
				fill: eye_fill,
			},
		),
	)
	mouth = Figure.bar(
		place,
		{
			from: {
				across: 0.0 - body.head_width * 0.18,
				up: head_bottom + body.head_height * 0.24,
			},
			to: { across: body.head_width * 0.18, up: head_bottom + body.head_height * 0.24 },
			width: body.head_height * 0.07,
			fill: Flat(body.trim),
		},
	)
	halos =
		if glow > 0.0 {
			Shapes.added_light_shapes(
				[-1.0, 1.0].map(
					|side|
						Shapes.halo(
							{
								center: Figure.screen_point(
									place,
									{ across: slide + side * eye_apart, up: eye_up },
								),
								radius: Pixels.of(eye_radius * 2.6 * place.scale),
							},
							{ ..RobotHead.lit_eye, a: 0.55 * glow },
						),
				),
			)
		} else {
			[]
		}
	List.concat(eyes.append(mouth), halos)
}

antenna_tip : F64 -> Brush.Rgba
antenna_tip = |glow| Brush.mix({
	from: Brush.opaque_rgba(RgbColor.of(0xC0504A)),
	to: RobotHead.lit_eye,
	fraction: glow,
})

dark_eye : Brush.Rgba
dark_eye = Brush.opaque_rgba(RgbColor.of(0x1F2830))
