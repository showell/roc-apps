# BrushGlsl -- Brush.shade on a GPU, and the numbers that say which shading.
#
# Hand-written, beside Brush because it belongs to Brush: the six fills a
# command can name, shaded on the scene position, for a platform whose fragment
# shader can do the arithmetic itself. **Nothing here belongs to any one
# app**: native/CanvasAppRunner.roc compiles it once and shades every app's
# gradients with it.
#
# `Brush.shade` is the same arithmetic on the CPU, case for case; the names
# below are its cases, so the two can be read side by side. A player sets
# `mode` to `mode_of` its fill, fills the colour and geometry uniforms the way
# `Brush` lays them out, and draws the shape in white.
import Brush

BrushGlsl :: [].{
	# Which shading, as `mode`. The player sends these; the shader switches on
	# them. **The contract is here so it is in ONE file**: it used to be bare
	# numbers at both ends, agreeing by hand.
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

	# The scene position, through to the fragment shader. The camera is in the
	# matrix, not in the vertices, so what arrives is the frame's own
	# coordinates -- which is what every brush's geometry is in.
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
			"vec4 spanColor() {",
			"    float t = clamp((scenePos.x - geom_a.x) / (geom_a.y - geom_a.x), 0.0, 1.0);",
			"    return t <= 0.5 ? mix(color_a, color_b, t * 2.0) : mix(color_b, color_a, (t - 0.5) * 2.0);",
			"}",
			"",
			"vec4 radialColor() {",
			"    return mix(color_a, color_b, ringT());",
			"}",
			"",
			"vec4 linearColor() {",
			"    float t = clamp(dot(scenePos - geom_b.xy, geom_b.zw) / dot(geom_b.zw, geom_b.zw), 0.0, 1.0);",
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
