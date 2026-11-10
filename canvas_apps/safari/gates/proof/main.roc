# The proof tools' modules that hold expects of their own, so the gate's
# `roc test gates/proof/main.roc` reaches them: the proof tools are apps, and
# no other root imports them. A module left off this list runs none of its
# expects, and the gate fails on each expect that never passed.
package [PixelColor, ShapesPixels] { game: "../../game.roc", lib: "../../../lib/main.roc" }
