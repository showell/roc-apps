# The vocabulary every canvas app shares, as a package.
#
# An app's root, web.roc, sits in the app's own directory and reaches this as
# `lib: "../lib/main.roc"`; every module of the app then says
# `import lib.Shapes`. It declares no platform, so the rules stay platform-free.
package
	[
		ArgbColor,
		Brush,
		BrushShade,
		Camera,
		CanvasApp,
		ColorShade,
		ConvexCut,
		CurvedShapes,
		Eye,
		Font,
		Fraction,
		Input,
		Keys,
		Math,
		Mouse,
		Pixels,
		Point,
		Random,
		RgbColor,
		Shapes,
		Squash,
		Trigonometry,
		WasmApp,
		WidthShading,
	]
	{}
