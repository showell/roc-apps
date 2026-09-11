# SafariCritter -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Scenery

SafariCritter :: [].{
	Species : { present : Bool, cp : I64, adult_h : F64 }

	no_species : SafariCritter.Species
	no_species = { present: False, cp: 0, adult_h: 0.0 }

	adult_rail_buffer : F64
	adult_rail_buffer = 1.5

	baby_ratio : F64
	baby_ratio = 0.5

	baby_beyond : F64
	baby_beyond = 14.0

	species_of : Scenery.Creature -> SafariCritter.Species
	species_of = |c| (match c {
		Elephant => { present: True, cp: 128024, adult_h: 2.8 }
		Giraffe => { present: True, cp: 129426, adult_h: 4.5 }
		Zebra => { present: True, cp: 129427, adult_h: 1.6 }
		Rhino => { present: True, cp: 129423, adult_h: 2.2 }
		DuckPond => no_species
		NoCreature => no_species
	})

	corner_critters : Scenery.Creature, F64, Bool, F64 -> List(Scenery.Critter)
	corner_critters = |c, along, turn_right, hw| ({
		sp = species_of(c)
		turn_sign = (if turn_right { 1.0 } else { (0.0 - 1.0) })
		adult_h = sp.adult_h
		(if sp.present { [{ along: along, across: ((0.0 - turn_sign) * ((hw + adult_rail_buffer) + (adult_h / 2.0))), codepoint: sp.cp, height: adult_h, face_right: turn_right }, { along: (along + baby_beyond), across: 0.0, codepoint: sp.cp, height: (adult_h * baby_ratio), face_right: turn_right }] } else { [] })
	})
}
