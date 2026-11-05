## SafariFrame is test code, like everything in this gates folder: the game
## never runs any of it. SafariFrame paints one Safari frame into a list of
## 0xRRGGBB pixels, in Roc: the sky and the grass (BackdropPixels), the sun
## (SunPixels), then the frame's shapes in paint order (ShapesPixels), all
## turned by the camera's roll (the rider's lean, which tilts the whole picture about the
## centre of the screen). Its pixels are exact and the same on every run.
##
## That is what Safari's gate needs. The gate is a script we run before a
## change lands (run.shale, in this folder), and it builds two programs on SafariFrame
## to check the drawing pixel for pixel. RasterFrame prints a hash of a
## frame's pixels, so we can confirm that a change which shouldn't alter the
## picture leaves the hash the same. ShapesFrame paints a frame with its
## polygons whole, as the browser is given them, paints it again with them cut
## into triangles, as the native runner is given them, and counts the pixels
## that differ; the gate requires none.
##
## The game itself paints differently. In the browser, the Roc program (built
## to wasm) hands each frame to the page as shapes, and shapes_canvas.js paints
## them with the browser's canvas. Wasm reaches a canvas only through JS in
## any case, and a canvas paints paths and gradients natively and
## anti-aliased, far faster than Roc could fill every pixel and copy the
## frame out. This painter has no anti-aliasing.
##
## What is generic lives in modules that know nothing of Safari: ScreenRoll
## turns points by the roll, PixelGrid finds the pixels that a stretch of a
## row or column covers, PixelColor packs and blends pixels, ScanlineFill
## fills polygons and discs, and ShapesPixels, the Roc twin of
## shapes_canvas.js, paints shapes with it.
import game.Angle
import BackdropPixels
import game.Sky
import game.Screen
import PixelGrid
import ScreenRoll
import ShapesPixels
import SunPixels
import lib.Shapes

SafariFrame :: [].{

	## What a frame shows, in SafariRide's terms.
	Scene : {
		shapes : List(Shapes.Shape),
		roll : Angle.Lean,
		sky_top : I64,
		sky_horizon : I64,
		sun : Sky.SunPos,
	}

	## The frame: the sky and the grass, the sun, then every shape.
	paint : SafariFrame.Scene -> List(U32)
	paint = |scene| {
		roll = SafariFrame.screen_roll(scene.roll)
		var $px = BackdropPixels.paint(
			roll,
			{ sky_top: scene.sky_top, sky_horizon: scene.sky_horizon },
		)
		$px = SunPixels.paint($px, { roll, sun: scene.sun })
		ShapesPixels.paint($px, { roll, shapes: scene.shapes })
	}

	## Safari's screen, seen through the camera's roll.
	screen_roll : Angle.Lean -> ScreenRoll
	screen_roll = |roll|
		ScreenRoll.of({
			roll: roll.to_radians(),
			width: screen_width,
			height: screen_height,
		})
}

## Safari's screen, in pixels across and down.
screen_width : PixelGrid.Coordinate
screen_width = PixelGrid.Coordinate.from_i64(Screen.width_px)

screen_height : PixelGrid.Coordinate
screen_height = PixelGrid.Coordinate.from_i64(Screen.height_px)
