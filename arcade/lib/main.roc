# The arcade's vocabulary, as a package.
#
# A package rather than a directory of loose modules because a game's two app
# files live in the game's own directory, and a relative import may not climb
# above an app -- a package reference may. So `snake_web.roc` says
# `lib: "lib/main.roc"` and every module of the game says `import lib.Shapes`.
package [Game, GameApp, Color, Input, Keys, Mouse, Math, Random, Shapes, Brush, Font, Trig, DeviceMath, ShapeWire, BrushGlsl] {}
