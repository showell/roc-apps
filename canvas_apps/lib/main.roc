# The vocabulary every canvas app shares, as a package.
#
# An app's two roots, main.roc and web.roc, sit in the app's own directory and
# reach this as `lib: "../lib/main.roc"`; every module of the app then says
# `import lib.Shapes`. It declares no platform, because both platforms use it.
package [ArgbColor, Brush, BrushGlsl, Camera, CanvasApp, Color, Font, Input, Keys, Math, Mouse, Random, RgbColor, Shapes, Trig, View, WasmApp] {}
