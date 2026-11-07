# Smells

These are Steve's code and design smells, each with a real case from Safari. A
lint catches what can be parsed, and `docs/roc-style.md` gives the rules. This
list carries what takes judgment. Paste it into every review brief, and add to
it whenever Steve names a new smell.

A smell is a reason to look, not a verdict. When one fires, say where and why,
and say what the code would look like without it.

## Names

**The name is cute.** A name should say what the thing is, not be clever about
it. `Through` and `Before` were "overly cute" names for parts of an animation.
`planted_trees` was cute, and so is `herd` for a list of cows: call it
`herd_cows`.

**The verb is a pretend effect.** A pure function doesn't do anything to the
world, so `draw`, `paint` and `plant` mislead. Our Roc app doesn't truly draw
anything: it answers with shapes, and a platform draws them. `draw_tree` became
`tree_shapes`, and the `Paint` module became `Polygon`.

**One word carries two meanings.** The rider's look and the rider's gawking were
both "look" until the code told them apart. Find the two meanings, and give each
its own word.

**The word has outlived its thing.** A word stays after the thing has changed,
and it now describes something else. `cutout` went when `Billboard` came, and
`TreeLook` was only the inputs to a tier, so it became `TierInputs`.

**A plain English word became a type.** "Critter" is English. It holds cats,
birds, bulls, giraffes and elephants, and it doesn't manifest as a type, so
`Scenery.Critter` became `Billboard`. Ask whether the code really has one
concept here, or only the language does.

**The top comment has to translate the name.** Read a module's first
sentence aloud with its name in it. If the sentence has to say what the name
means before it can say what the module does, the name is a metaphor the reader
must learn. `Chain` has to begin "Chain finds where the road lies from where the
rider is", and a chain is also a bike's. The structure is fine; the name should
say what the comment says.

## Types

**The return type is wider than the truth.** A function that gives one thing or
none answers a `Try`, not a list, so that the types enforce it. `cat_in_view`
gives one cat, and a polygon maker gives one `Shape`, and `polygon_shapes` was
the wrong shape for both. Add the list when a second cat really exists.

**A bare type hides a concept.** If `List(Shape)` travels everywhere and means
one thing, that thing wants a name. It is `Picture`, and `Rendered` is a
`Picture` plus a depth.

**A parallel hierarchy.** One enum that lists every kind, beside a set of modules
that each handle a kind, has to change in two places forever. `DepthSort.Subject`
was that enum. The fix was generic forms, `Placed(kind)` and `Sighted(kind)`,
with `where` methods on each kind.

**A kind says where the object is.** A kind holds how the object looks right now,
a pose or a beacon's brightness, because it is what the picture needs beyond where
the object is. `Tower` and `TruckAhead` held `along` and `across`, so location had
two homes. Location lives in `Geom.Placed` and `Pipeline.Sighted`, around the kind.

**A wrong state can be written down.** If a value can hold something the program
must never see, the type is too loose. Prefer a type where that state has nowhere
to live over a check that catches it.

## Behavior

**A heuristic coincidence that just kinda works.** "I hate heuristic coincidences
that just kinda work." Tuned fractions that land on the right frame are the
archetype: `Cut`, `Stretch`, `Track` and `Alternates` went, and an animation is
now a list of frames on successive steps. If a constant is right only because it
was nudged until the eye agreed, ask what it stands for.

**More than we need today.** A cap chosen to be big enough is a decision nobody
owns, and it fails quietly on the day it's reached. Polygons were silently cut to
8 corners by a buffer on the Zig side, and there were similar caps of 512 points
and on the guard rail. Either the limit is a rule of the world and is named as
one, or it goes.

**A silent fallback.** A default that hides a missing case turns a bug into a
wrong picture. The emoji default was one. Answer an error, or crash if it can't
happen.

## Structure

**The same step is written once per kind.** When two modules have the same five
lines with different nouns, the steps belong in one place, and each kind supplies
only what is its own. `Pipeline` is that place for sighting and rendering.

**Knowledge is in the wrong module.** A kind should own what is true of it.
`Conifer` owns its picture and `Pipeline` knows nothing of trees. If a general
module imports a particular one, ask which way the arrow should point.

**The explanation needs an apology.** If you can't say what a piece of code does
in plain words to a newcomer, the code is usually wrong and the prose is fine.
"It's kind of amazing how shining a light on the code reveals so much to the
author of the code."
