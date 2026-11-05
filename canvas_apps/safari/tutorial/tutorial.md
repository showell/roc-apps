# Safari: a tour of a real Roc program

*[The live ride goes here, running as you read.]*

That's Safari. You're riding a bike down a long road through open country, past trees, cows and pigs, with a truck somewhere ahead of you. Radio masts blink in the distance. A bird may take off as you come near. A cat may walk out into the lane, think better of it, and leap for the far verge. Eventually the sun goes down behind the mountains, and the truck turns on its headlights.

I set out to make a game. There's still no game here, and it's my actual screensaver at home.

This is a tour of how it works. It's about seventy modules of Roc, which is enough to find out whether Roc holds up in a program with a lot going on. I think it does, and I'd like to show you why. You'll get the most out of this if you already know Roc, because I won't stop to explain the language.

## All that's stored

Here's the whole of what Safari keeps from one step to the next:

{{code Safari.Ride}}

Everything you just watched comes from those three fields. The cat has no state, and neither does the bird, the sun or the beacons. Each frame, Safari works them all out again from the rider, the truck and the clock.

That gives us three kinds of moving thing, and the rest of this tour is organized around them:

| Kind | Things | How it works |
|---|---|---|
| Stepped | The rider, the truck | Stored in `Ride`, and moved once a step from where it was |
| Rider-driven | The cat, the bird | Worked out from how the rider is approaching, with nothing stored |
| Clock-driven | The sun, the sky, the beacons, the headlights | Worked out from the clock, with nothing stored |

Trees and cows are a fourth kind, the easiest of all: they never change.

Pure functions make some things free. Safari can pause and step backward, because a step back only needs an older `Ride`. The cat follows along by itself, since it was never anywhere but where the rider's position puts it. The sun rises again too.

## The cat

The cat is the best scene in the game, so we'll start there, even though it isn't the simplest thing in it.

It was going to be a kangaroo. I wanted something to hop across the road, and Claude couldn't make a kangaroo hop convincingly, so we ended up with a cat. It walks out, freezes in your lane as you bear down on it, and at the last moment it leaps clear.

*[The cat widget goes here: drag the rider's gap and watch the crossing play.]*

Try dragging that back and forth. You're not scrubbing a video. Every position of the slider is a call to one function:

{{code Cat.moment_at}}

A crossing and an approach go in, and a moment comes out. There's no cat object being updated. If you asked for the same crossing at the same approach a thousand frames apart, you'd get the same cat. That one line also shows the design: `crossing_stage` decides how far along things are, and `crossing_timeline` decides what that looks like. Those two know nothing of each other.

### When it plays

The first half is a question about the rider:

{{code Cat.crossing_stage}}

{{code Animation.Stage}}

Three tags, because those are the three situations. `Waiting` and `Past` aren't just progress of 0 and 1. The bird, for example, is only ever `Perched` outside its flight, and a critter can rest somewhere no part of its animation reaches.

The rule itself lives in `Animation`:

{{code Animation.over_steps}}

The cat plays over steps rather than over a stretch of road because it has to finish before you reach it, however fast you're going. If you come in fast, it starts earlier. The bird has a different rule, `over_gap`, because a bird simply reacts to how close you are. The two rules are about the same size, and each critter picks the one that suits it.

### What it looks like

The second half is a value. A timeline is data, so the cat's whole performance reads in one place, like a score:

{{code Cat.crossing_timeline}}

It has two tracks because a cat's looks and its movement change at different moments. The body starts to move just ahead of the leap itself, so the `looks` track cuts at 0.8, 2.8 and 3.8 steps into the escape while the `path` track cuts at 1 and 3. One list of phases tying them together wouldn't fit the cat or the bird.

`Timeline(pose)` is generic in its pose, which is what lets a cat and a bird share it. A cat's pose is a closed tag union, and nothing outside `Cat` needs to know its tags:

{{code Cat.Pose}}

There's a small floating-point joke hiding in `Through` and `Before`:

{{code Animation.Cut}}

A cut has to say which side of it its own step falls on. Those leap steps sum to a float just under the step they stand for, and `crossing_timeline`'s comment says why that matters. We changed the way all this was written without moving a single pixel, and I'll explain how in the chapter on proving things.

### What it does to you

So far the cat hasn't touched the rider. That's a separate question with a separate answer, and it's in one place:

{{code CrossingReaction.reaction_to}}

Two things stand out here. A cat in the lane stops you opening the throttle, though it doesn't brake you. And it pulls your eye, which is why the view widens as it crosses.

This is the only loop in the design. The rider's speed decides where the cat has got to, and the cat holds the rider's speed down. It settles, and it's also why `over_steps` has to stay the cat's rule. A bird asks nothing of the rider, so it just falls through to the same answer as an empty road.

Each stretch of road has exactly one `crossing`, either `CatCrosses`, `BirdFlies` or `QuietRoad`, so "a cat and a bird in the same place" can't be written down.

### Getting it on screen

The last step is finding the cat in the rider's view. `CatPlan` asks for the moment, places it, and decides whether it's big enough to bother drawing:

{{code CatPlan.cat_in_view}}

Drawing only paints what the plan decided. That's a rule across the whole of Safari: a plan decides how a thing looks, and drawing just paints it.

Notice what isn't anywhere in this chapter: a `Cat` record in `Ride`, an update loop, or a flag saying the cat has already crossed. Roc didn't force that on us, but it made the stateless version the easy one to write, and once it's there, the type signatures show you it stayed that way.
