# BrushGlsl -- Brush.shade on a GPU, and the numbers that say which shading.
#
# Hand-written, beside Brush because it belongs to Brush: the six fills a
# command can name, shaded on the scene position, for a platform whose fragment
# shader can do the arithmetic itself. **Nothing here belongs to any one
# movie** -- it used to live in ray/apps/safari/main.roc, where a player that
# knows nothing else about a movie carried sixty lines of its paint.
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
			Skip => 0.0
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
			# Where the shape may paint: x, y, width, height. A width of zero
			# is "anywhere", which is what most shapes are.
			"uniform vec4 clip;",
			"uniform vec4 colorA;",
			"uniform vec4 colorB;",
			"uniform vec4 colorC;",
			"uniform vec4 geomA;",
			"uniform vec4 geomB;",
			"uniform vec4 geomC;",
			"out vec4 finalColor;",
			"",
			"bool outsideClip() {",
			"    if (clip.z <= 0.0) return false;",
			"    return scenePos.x < clip.x || scenePos.x >= clip.x + clip.z",
			"        || scenePos.y < clip.y || scenePos.y >= clip.y + clip.w;",
			"}",
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
			"    float d = distance(scenePos, geomA.xy);",
			"    return geomA.w > geomA.z ? clamp((d - geomA.z) / (geomA.w - geomA.z), 0.0, 1.0) : 1.0;",
			"}",
			"",
			"vec4 spanColor() {",
			"    float t = clamp((scenePos.x - geomA.x) / (geomA.y - geomA.x), 0.0, 1.0);",
			"    return t <= 0.5 ? mix(colorA, colorB, t * 2.0) : mix(colorB, colorA, (t - 0.5) * 2.0);",
			"}",
			"",
			"vec4 radialColor() {",
			"    return mix(colorA, colorB, ringT());",
			"}",
			"",
			"vec4 linearColor() {",
			"    float t = clamp(dot(scenePos - geomB.xy, geomB.zw) / dot(geomB.zw, geomB.zw), 0.0, 1.0);",
			"    return twoStop(colorA, geomA.x, colorB, geomA.y, t);",
			"}",
			"",
			"vec4 ellipseColor() {",
			"    vec2 q = scenePos - geomB.xy;",
			"    vec2 u = vec2(geomC.x * q.x + geomC.y * q.y, geomC.z * q.x + geomC.w * q.y);",
			"    return twoStop(colorA, geomA.x, colorB, geomA.y, clamp(length(u), 0.0, 1.0));",
			"}",
			"",
			"vec4 glowColor() {",
			"    float t = ringT();",
			"    return t <= 0.4 ? mix(colorA, colorB, t / 0.4) : mix(colorB, colorC, (t - 0.4) / 0.6);",
			"}",
			"",
			"void main() {",
			"    if (outsideClip()) discard;",
			"    vec4 c = colorA;",
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
