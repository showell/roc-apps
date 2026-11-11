## BrushGlsl is Brush.shade on a GPU, with the numbers that say which shading.
## It shades the six fills a shape can carry on the scene position, for a
## platform whose fragment shader can do the arithmetic itself. It sits beside
## Brush because it belongs to Brush. No app owns any of it:
## native/CanvasAppRunner.roc compiles it once and shades every app's gradients
## with it.
##
## `Brush.shade` is the same arithmetic on the CPU, case for case, and the names
## below are its cases, so the two can be read side by side. A player sends
## `uniforms` of a shape's fill, each number converted to its own vector type,
## and draws the shape in white. Which numbers go in which uniform is decided
## here, beside the shader that reads them, so both ends of the contract are in
## this one file.
import Brush
import Pixels
import Point

BrushGlsl :: [].{

	## One vec4 uniform's four numbers.
	Quad : {
		x : F64,
		y : F64,
		z : F64,
		w : F64,
	}

	## The values the fragment shader reads, by its uniforms' names: which
	## shading, and the colours and geometry that shading wants. Every field is
	## sent with every shape, so a slot the shading doesn't read is zero. A
	## colour's red, green and blue go from 0..255 to the 0..1 a shader mixes.
	Uniforms : {
		mode : F64,
		color_a : BrushGlsl.Quad,
		color_b : BrushGlsl.Quad,
		color_c : BrushGlsl.Quad,
		geom_a : BrushGlsl.Quad,
		geom_b : BrushGlsl.Quad,
		geom_c : BrushGlsl.Quad,
	}

	## The fill as the uniforms the fragment shader reads.
	uniforms : Brush.Fill -> BrushGlsl.Uniforms
	uniforms = |fill| {
		blank = { ..blank_uniforms, mode: mode_of(fill) }
		match fill {
			Flat(c) => { ..blank, color_a: color_quad(c) }
			Span(p) => {
				..blank,
				color_a: color_quad(p.edge_color),
				color_b: color_quad(p.middle_color),
				geom_a: {
					x: p.left_x.to_f64(),
					y: p.right_x.to_f64(),
					z: 0.0,
					w: 0.0,
				},
			}
			Radial(p) => {
				..blank,
				color_a: color_quad(p.inner_color),
				color_b: color_quad(p.outer_color),
				geom_a: ring_quad(p),
			}
			Linear(p) => {
				..blank,
				color_a: color_quad(p.stops.start_color),
				color_b: color_quad(p.stops.end_color),
				geom_a: {
					x: p.stops.start_offset,
					y: p.stops.end_offset,
					z: 0.0,
					w: 0.0,
				},
				geom_b: {
					x: p.start_point.x.to_f64(),
					y: p.start_point.y.to_f64(),
					z: p.end_point.x.to_f64() - p.start_point.x.to_f64(),
					w: p.end_point.y.to_f64() - p.start_point.y.to_f64(),
				},
			}
			Ellipse(p) => {
				inverse = Brush.ellipse_inverse({ axis_u: p.axis_u, axis_v: p.axis_v })
				{
					..blank,
					color_a: color_quad(p.stops.start_color),
					color_b: color_quad(p.stops.end_color),
					geom_a: {
						x: p.stops.start_offset,
						y: p.stops.end_offset,
						z: 0.0,
						w: 0.0,
					},
					geom_b: {
						x: p.center.x.to_f64(),
						y: p.center.y.to_f64(),
						z: 0.0,
						w: 0.0,
					},
					geom_c: {
						x: inverse.top_row.x,
						y: inverse.top_row.y,
						z: inverse.bottom_row.x,
						w: inverse.bottom_row.y,
					},
				}
			}
			Glow(p) => {
				..blank,
				color_a: color_quad(p.inner_color),
				color_b: color_quad(p.middle_color),
				color_c: color_quad(p.outer_color),
				geom_a: ring_quad(p),
				geom_b: {
					x: p.middle_offset,
					y: 0.0,
					z: 0.0,
					w: 0.0,
				},
			}
		}
	}

	## The scene position, through to the fragment shader. The camera is in the
	## matrix, not in the vertices, so what arrives is the frame's own
	## coordinates -- which is what every brush's geometry is in.
	vertex : Str
	vertex = Str.join_with(
		[
			"#version 330",
			"in vec3 vertexPosition;",
			"uniform mat4 mvp;",
			"out vec2 scenePos;",
			"void main() {",
			"    scenePos = vertexPosition.xy;",
			"    gl_Position = mvp * vec4(vertexPosition, 1.0);",
			"}",
		],
		"\n",
	)

	fragment : Str
	fragment = Str.join_with(
		[
			"#version 330",
			"in vec2 scenePos;",
			"uniform float mode;",
			"uniform vec4 color_a;",
			"uniform vec4 color_b;",
			"uniform vec4 color_c;",
			"uniform vec4 geom_a;",
			"uniform vec4 geom_b;",
			"uniform vec4 geom_c;",
			"out vec4 finalColor;",
			"",
			"vec4 twoStop(vec4 c0, float o0, vec4 c1, float o1, float t) {",
			"    if (t <= o0) return c0;",
			"    if (t >= o1) return c1;",
			"    return mix(c0, c1, (t - o0) / (o1 - o0));",
			"}",
			"",
			# The distance from a centre as a fraction of the way from the
			# inner radius to the outer, which Radial and Glow both want.
			"float ringT() {",
			"    float d = distance(scenePos, geom_a.xy);",
			"    return geom_a.w > geom_a.z ? clamp((d - geom_a.z) / (geom_a.w - geom_a.z), 0.0, 1.0) : 1.0;",
			"}",
			"",
			# A span whose edges meet, and a line from a point to itself in
			# linearColor, are at their far end everywhere, as in Brush.shade.
			"vec4 spanColor() {",
			"    float t = geom_a.y != geom_a.x ? clamp((scenePos.x - geom_a.x) / (geom_a.y - geom_a.x), 0.0, 1.0) : 1.0;",
			"    return t <= 0.5 ? mix(color_a, color_b, t * 2.0) : mix(color_b, color_a, (t - 0.5) * 2.0);",
			"}",
			"",
			"vec4 radialColor() {",
			"    return mix(color_a, color_b, ringT());",
			"}",
			"",
			"vec4 linearColor() {",
			"    float length_squared = dot(geom_b.zw, geom_b.zw);",
			"    float t = length_squared > 0.0 ? clamp(dot(scenePos - geom_b.xy, geom_b.zw) / length_squared, 0.0, 1.0) : 1.0;",
			"    return twoStop(color_a, geom_a.x, color_b, geom_a.y, t);",
			"}",
			"",
			"vec4 ellipseColor() {",
			"    vec2 q = scenePos - geom_b.xy;",
			"    vec2 u = vec2(geom_c.x * q.x + geom_c.y * q.y, geom_c.z * q.x + geom_c.w * q.y);",
			"    return twoStop(color_a, geom_a.x, color_b, geom_a.y, clamp(length(u), 0.0, 1.0));",
			"}",
			"",
			"vec4 glowColor() {",
			"    float t = ringT();",
			"    float m = geom_b.x;",
			"    return t <= m ? mix(color_a, color_b, t / m) : mix(color_b, color_c, (t - m) / (1.0 - m));",
			"}",
			"",
			"void main() {",
			"    vec4 c = color_a;",
			"    switch (int(mode + 0.5)) {",
			"        case 1: c = spanColor(); break;",
			"        case 2: c = radialColor(); break;",
			"        case 3: c = linearColor(); break;",
			"        case 4: c = ellipseColor(); break;",
			"        case 5: c = glowColor(); break;",
			"        default: break;",
			"    }",
			"    finalColor = c;",
			"}",
		],
		"\n",
	)
}

## Which shading, as `mode`. The shader's switch names the same numbers.
mode_of : Brush.Fill -> F64
mode_of = |fill|
	match fill {
		Flat(_) => 0.0
		Span(_) => 1.0
		Radial(_) => 2.0
		Linear(_) => 3.0
		Ellipse(_) => 4.0
		Glow(_) => 5.0
	}

zero_quad : BrushGlsl.Quad
zero_quad = {
	x: 0.0,
	y: 0.0,
	z: 0.0,
	w: 0.0,
}

blank_uniforms : BrushGlsl.Uniforms
blank_uniforms = {
	mode: 0.0,
	color_a: zero_quad,
	color_b: zero_quad,
	color_c: zero_quad,
	geom_a: zero_quad,
	geom_b: zero_quad,
	geom_c: zero_quad,
}

color_quad : Brush.Rgba -> BrushGlsl.Quad
color_quad = |c| {
	x: c.r / 255.0,
	y: c.g / 255.0,
	z: c.b / 255.0,
	w: c.a,
}

## A radial gradient's center and its two radii, as `ringT` reads them.
ring_quad : {
	center : Point,
	inner_radius : Pixels,
	outer_radius : Pixels,
	..,
} -> BrushGlsl.Quad
ring_quad = |ring| {
	x: ring.center.x.to_f64(),
	y: ring.center.y.to_f64(),
	z: ring.inner_radius.to_f64(),
	w: ring.outer_radius.to_f64(),
}

# A glow fills all three colours and its middle offset, with each colour's red,
# green and blue as a share of 255 and its alpha as it is.
expect {
	look = {
		inner_color: {
			r: 255.0,
			g: 0.0,
			b: 0.0,
			a: 1.0,
		},
		middle_color: {
			r: 0.0,
			g: 51.0,
			b: 0.0,
			a: 0.5,
		},
		outer_color: {
			r: 0.0,
			g: 0.0,
			b: 255.0,
			a: 0.0,
		},
		middle_offset: 0.25,
		center: Point.at(3.0, 4.0),
		inner_radius: Pixels.of(1.0),
		outer_radius: Pixels.of(9.0),
	}
	BrushGlsl.uniforms(Glow(look))
		== {
			mode: 5.0,
			color_a: {
				x: 1.0,
				y: 0.0,
				z: 0.0,
				w: 1.0,
			},
			color_b: {
				x: 0.0,
				y: 0.2,
				z: 0.0,
				w: 0.5,
			},
			color_c: {
				x: 0.0,
				y: 0.0,
				z: 1.0,
				w: 0.0,
			},
			geom_a: {
				x: 3.0,
				y: 4.0,
				z: 1.0,
				w: 9.0,
			},
			geom_b: {
				x: 0.25,
				y: 0.0,
				z: 0.0,
				w: 0.0,
			},
			geom_c: zero_quad,
		}
}

# A line sends its start and the step to its end, and an ellipse its center and
# the inverse of its axes, in the order the shader reads them.
expect {
	stops = {
		start_color: {
			r: 0.0,
			g: 0.0,
			b: 0.0,
			a: 1.0,
		},
		end_color: {
			r: 255.0,
			g: 255.0,
			b: 255.0,
			a: 1.0,
		},
		start_offset: 0.1,
		end_offset: 0.9,
	}
	line = BrushGlsl.uniforms(
		Linear({
			stops,
			start_point: Point.at(1.0, 2.0),
			end_point: Point.at(4.0, 6.0),
		}),
	)
	ellipse = BrushGlsl.uniforms(
		Ellipse({
			stops,
			center: Point.at(7.0, 8.0),
			axis_u: Point.at(3.0, 4.0),
			axis_v: Point.at(5.0, 6.0),
		}),
	)
	line.mode == 3.0
		and line.geom_b == {
			x: 1.0,
			y: 2.0,
			z: 3.0,
			w: 4.0,
		}
		and ellipse.mode == 4.0
		and ellipse.geom_b == {
			x: 7.0,
			y: 8.0,
			z: 0.0,
			w: 0.0,
		}
		and ellipse.geom_c == {
			x: -3.0,
			y: 2.5,
			z: 2.0,
			w: -1.5,
		}
}
