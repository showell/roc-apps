## A pig is the pig emoji, a little over a metre tall. Every pig in Safari Ride
## looks the same, so one value says how.
import Billboard
import Distance
import EmojiStills

Pig :: [].{

	## How every pig looks.
	pig : Billboard.Species
	pig = { emoji: EmojiStills.pig, adult_height: Distance.metres(1.1) }
}
