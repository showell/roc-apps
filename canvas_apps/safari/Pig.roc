## A pig is a billboard of the pig emoji, a little over a metre tall, facing
## left. Every pig in Safari Ride looks the same, so one value says how.
import Billboard
import Distance

Pig :: [].{

	## How every pig looks.
	pig_billboard : Billboard
	pig_billboard = {
		codepoint: 128022,
		height: Distance.metres(1.1),
		facing: FacesLeft,
	}
}

expect Pig.pig_billboard.codepoint == 128022
expect Pig.pig_billboard.height.to_metres() == 1.1
expect Pig.pig_billboard.facing == FacesLeft
