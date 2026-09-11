# EmojiStills -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import EmojiStillsData
import Stills

EmojiStills :: [].{

	# baked: duck_polys : List(Stills.StillPoly) -- EmojiStills 523 literals
	duck_polys : List(Stills.StillPoly)
	duck_polys = EmojiStillsData.duck_polys

	# baked: elephant_polys : List(Stills.StillPoly) -- EmojiStills 701 literals
	elephant_polys : List(Stills.StillPoly)
	elephant_polys = EmojiStillsData.elephant_polys

	# baked: giraffe_polys : List(Stills.StillPoly) -- EmojiStills 2208 literals
	giraffe_polys : List(Stills.StillPoly)
	giraffe_polys = EmojiStillsData.giraffe_polys

	# baked: zebra_polys : List(Stills.StillPoly) -- EmojiStills 1884 literals
	zebra_polys : List(Stills.StillPoly)
	zebra_polys = EmojiStillsData.zebra_polys

	# baked: rhino_polys : List(Stills.StillPoly) -- EmojiStills 632 literals
	rhino_polys : List(Stills.StillPoly)
	rhino_polys = EmojiStillsData.rhino_polys

	# baked: bull_polys : List(Stills.StillPoly) -- EmojiStills 6802 literals
	bull_polys : List(Stills.StillPoly)
	bull_polys = EmojiStillsData.bull_polys

	# baked: cow_polys : List(Stills.StillPoly) -- EmojiStills 1228 literals
	cow_polys : List(Stills.StillPoly)
	cow_polys = EmojiStillsData.cow_polys

	# baked: pig_polys : List(Stills.StillPoly) -- EmojiStills 631 literals
	pig_polys : List(Stills.StillPoly)
	pig_polys = EmojiStillsData.pig_polys

	emoji_polys_for : I64 -> List(Stills.StillPoly)
	emoji_polys_for = |cp| (if (cp == 129414) { duck_polys } else { (if (cp == 128024) { elephant_polys } else { (if (cp == 129426) { giraffe_polys } else { (if (cp == 129427) { zebra_polys } else { (if (cp == 129423) { rhino_polys } else { (if (cp == 128002) { bull_polys } else { (if (cp == 128004) { cow_polys } else { (if (cp == 128022) { pig_polys } else { [] }) }) }) }) }) }) }) })
}
