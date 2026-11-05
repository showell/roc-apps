# Safari Ride: a tour of a real Roc program

*[The live ride goes here, running as you read.]*

This is Safari Ride. A rider cycles down a long road through open country, past trees, cows and pigs, with a truck somewhere ahead. Radio masts blink in the distance. A bird takes off as the rider comes near. A cat walks into the lane, freezes, and leaps for the far verge. The sun goes down behind the mountains, and the truck turns on its headlights.

Safari Ride has the important parts of a game's world: terrain, physics, a camera, things that react to the player, and a day that ends. It doesn't have game mechanics yet. Nothing keeps score.

This tour reads the program from the bottom up. It's about seventy modules of Roc, which is enough to show how Roc holds up in a program with a lot going on. It assumes you can already read Roc. Each chapter points out a few Roc ideas as they come up, and the useful ones come up more than once.

Here's the whole system, simplified. An arrow points from a module to one it imports. The dashed boxes each stand for a family of modules. Roc doesn't allow import cycles, so every diagram in this tour reads downward.

```dot
digraph system {
  node [shape=box, fontname="Helvetica"];
  web [label="web.roc"];
  plans [label="the plans\nCatPlan, BirdPlan, TreePlan, TruckPlan, ...", style=dashed];
  drawing [label="the drawing\nCatDraw, RocBird, Tree, Tower, TruckDraw, ...", style=dashed];
  shapes [label="lib.Shapes"];
  web -> SafariApp;
  SafariApp -> SafariRide;
  SafariApp -> SafariShapes;
  SafariRide -> Safari;
  Safari -> Rider;
  Safari -> Truck;
  Safari -> Sky;
  Safari -> Mountains;
  Safari -> Render;
  Safari -> ItemDraw;
  ItemDraw -> Render;
  Render -> plans;
  ItemDraw -> drawing;
  SafariShapes -> Sky;
  Mountains -> Sky;
  Rider -> World;
  Truck -> World;
  plans -> World;
  World -> Cat;
  World -> BirdFlight;
  plans -> Cat;
  plans -> BirdFlight;
  Cat -> Animation;
  BirdFlight -> Animation;
  drawing -> shapes;
  SafariShapes -> shapes;
}
```

`Safari` holds the ride and steps it. `Render` asks the plans what's in view, and `ItemDraw` paints it. `World` holds the route. The browser only sees `SafariApp`, which hands it a list of shapes each frame.

## All that's stored

A record alias is the plainest way to name a shape in Roc, and it's all this needs. `Safari` itself is a module written as a type: `Safari :: [].{ ... }` holds the definitions other modules can reach.

{{code Safari.Ride}}

Those three fields are the whole of what Safari Ride keeps from one step to the next. The cat has no state, and neither does the bird, the sun or the beacons. Each frame works them all out again from the rider, the truck and the clock.

That gives three kinds of moving thing, and the tour is organized around them:

| Kind | Things | How it works |
|---|---|---|
| Stepped | The rider, the truck | Stored in `Ride`, and moved once a step from where it was |
| Rider-driven | The cat, the bird | Worked out from how the rider is approaching, with nothing stored |
| Clock-driven | The sun, the sky, the beacons, the headlights | Worked out from the clock, with nothing stored |

Trees and cows are a fourth kind, the easiest of all: they never change.

Purity makes some things free. Safari Ride can pause and step backward, because a step back only needs an older `Ride`. The cat follows along, since it was never anywhere but where the rider's position puts it, and the sun rises again.

## The sky

The sky is the simplest thing that moves, because it depends on one number.

```dot
digraph sky {
  node [shape=box, fontname="Helvetica"];
  Sky [style=bold];
  Safari -> Sky;
  SafariRide -> Sky;
  SafariShapes -> Sky;
  Mountains -> Sky;
  Sky -> Angle;
  Sky -> Lens;
  Sky -> Screen;
  Lens -> Angle;
  Lens -> Screen;
}
```

`Sky` sits near the bottom of the system. Leaving out small maths helpers, it imports only the angle type and the lens and screen geometry, and it knows nothing of the rider, the road or the drawing. Those above it each ask for a colour or a sun at a given clock.

*[The sky widget goes here: drag the clock and watch the sun set.]*

### A function of the clock

Every function in this chapter has a `->` arrow, not `=>`. In Roc that's a promise the compiler holds: no effects, so the same clock always gives the same sky.

{{code Sky.sun_height_px}}

The sun's height is a straight line. It starts at 244 pixels, reaches the horizon around step 3,980, and has fully set around step 4,730.

Dusk is a curve and then a line, which means two cases. `Sky` keeps the two halves below its block. Anything outside `Sky :: [].{ ... }` is private to the module, so a helper stays a helper without any keyword.

{{code Sky.dusk_at}}

{{code Sky.dusk_while_up}}

{{code Sky.dusk_after_set}}

The horizon's warmth is a third shape, a tent centred on the moment the sun touches the horizon. Three curves come off one number, and they're plain functions rather than anything more general. Nothing else in the game needs them.

{{code Sky.sunset_warmth}}

### Angles that can't be mixed up

The sun is the one thing here that also depends on where the rider is looking. Two tags say the two answers, so there's no `null` and no off-screen sentinel value. A caller has to handle `OutOfView`, because `match` must cover every tag.

{{code Sky.SunPos}}

Opaque types do the most work in this next function. `Angle.Bearing` is a direction in the world and `Angle.Turn` is a change of direction. Both are floats underneath, but they're opaque types (`::`), so only the `Angle` module can build or open one, and a `Turn` can't be passed where a `Bearing` is wanted. `sun_bearing.turn_from(heading)` is static dispatch: the method comes from the type of `sun_bearing`, with no import needed at the call. The function also takes one record argument, destructured in its parameter list, so callers name every field.

{{code Sky.sun_pos}}

`turn_from_view.abs() >= visible_turn_limit` compares two `Turn`s. The code never touches radians until `sun_place` has to do trigonometry.

## The cat

The cat is the best scene in Safari Ride. It walks out, freezes in the lane as the rider bears down on it, and leaps clear at the last moment.

```dot
digraph cat {
  node [shape=box, fontname="Helvetica"];
  Cat [style=bold];
  World -> Cat;
  CrossingReaction -> Cat;
  CrossingReaction -> World;
  CatPlan -> Cat;
  CatDraw -> Cat;
  CatDraw -> CatStills;
  CatStills -> Cat;
  Cat -> Animation;
  Cat -> Easing;
  Animation -> Easing;
  Animation -> Speed;
}
```

`Cat` says what a cat does, and `Animation` holds what a cat shares with a bird. Everything that uses a cat imports it, and `Cat` imports none of them: it doesn't know it's drawn, placed or reacted to.

*[The cat widget goes here: drag the rider's gap and watch the crossing play.]*

The slider isn't scrubbing a video. Every position of it is a call to this function. The arrow is `->` again, so the type already says there's no hidden cat being updated somewhere. Method syntax chains the two halves of the job: `.moment(...)` is defined on the `Timeline` that `crossing_timeline` returns.

{{code Cat.moment_at}}

A crossing and an approach go in, and a moment comes out. The same crossing at the same approach gives the same cat, a thousand frames apart. `crossing_stage` decides how far along things are, and `crossing_timeline` decides what that looks like. They know nothing of each other.

### When it plays

`Approach` is a plain record alias. Its `speed` field isn't a plain number, though. Like `Angle`, `Speed` is an opaque type.

{{code Animation.Approach}}

`Speed` wraps an `F64`, and its methods live in a block after the type. `Speed.(s)` in a parameter list is how the module opens one. Outside this module, nothing can, so a distance can't be passed as a speed.

{{code Speed.distance_in}}

`Speed` also defines `is_lte`, which is what lets `speed <= standstill` work in the next snippet with an ordinary operator.

The stage is a tag union where two of the tags carry a payload. `Waiting` and `Past` aren't progress of 0 and 1, because a critter can rest somewhere no part of its animation reaches.

{{code Animation.Stage}}

{{code Cat.crossing_stage}}

The rule lives in `Animation`. Its first argument is destructured in place, and so is the `Approach` after it, so the body reads in plain names.

{{code Animation.over_steps}}

The cat plays over steps rather than over a stretch of road because it has to finish before the rider reaches it, however fast the rider comes. A faster rider makes it start earlier. The bird uses `over_gap`, because a bird simply reacts to how close the rider is. Each critter picks the rule that suits it.

### What it looks like

A timeline is data, so the cat's whole performance reads in one place, like a score. Tags with payloads do almost everything here: `Through` and `Before` say where a stretch ends, `Holds` and `Alternates` say how the cat looks, and `Line`, `StaysAt` and `Arc` say where it goes. `Animation.Timeline.( ... )` wraps a record in the nominal type `Timeline`. Nominal (`:=`) is the middle ground: unlike an alias it can carry methods, and unlike an opaque type anyone can build one, which is right for data that needs no guarding.

{{code Cat.crossing_timeline}}

There are two tracks because a cat's looks and its movement change at different moments. Its body moves just ahead of its path, so the `looks` track cuts at 0.8, 2.8 and 3.8 steps into the escape while the `path` track cuts at 1 and 3. One list of phases tying them together wouldn't fit the cat or the bird.

`Timeline(pose)` takes a type parameter, which is how a cat and a bird share it. A cat's pose is a closed tag union, and nothing outside `Cat` needs to know its tags. Because it's closed, a `match` on it that misses a pose won't compile.

{{code Cat.Pose}}

A cut has to say which side of it its own step falls on, and two tags say that better than a boolean would. `crossing_timeline`'s comment says why it matters: those leap steps sum to a float just under the step they stand for.

{{code Animation.Cut}}

Finding the stretch that's playing shows one more Roc idea. `var $from` is a local variable that a `for` loop reassigns, inside a pure function. Roc allows that because nothing outside can see it: `playing_at` still has a `->` arrow, and the `$` marks what changes. An early `return` ends the loop.

{{code Animation.playing_at}}

### What it does to the rider

So far the cat hasn't touched the rider. That's a separate question, answered in one place.

```dot
digraph reaction {
  node [shape=box, fontname="Helvetica"];
  CrossingReaction [style=bold];
  Throttle -> CrossingReaction;
  RideFocal -> CrossingReaction;
  CrossingReaction -> Cat;
  CrossingReaction -> World;
  World -> Cat;
}
```

`Throttle` and `RideFocal` know nothing of cats. They ask `CrossingReaction`, which is the only part of the rider's code that does.

`..others` in the argument's type makes it an open record: this function needs `along` and `speed`, and accepts any record that has them, so it doesn't depend on `Pose.RiderState`. `speed` here is the opaque `Speed` again, and `match` on `segment.crossing` has to name every tag.

{{code CrossingReaction.reaction_to}}

A cat in the lane stops the rider opening the throttle, without braking, and widens the view as it pulls the rider's eye. Two tags, `MayAccelerate` and `NoAcceleration`, stand where a boolean might have gone, so the call site reads as a sentence.

This is the only loop in the design. The rider's speed decides where the cat has got to, and the cat holds the rider's speed down. It settles, and it's also why `over_steps` has to stay the cat's rule. A bird asks nothing of the rider, so it falls through to the same answer as an empty road.

Each stretch of road has exactly one `crossing`: `CatCrosses`, `BirdFlies` or `QuietRoad`. A cat and a bird in the same place can't be written down.

### Getting it on screen

The last step is finding the cat in the rider's view.

```dot
digraph screen {
  node [shape=box, fontname="Helvetica"];
  CatPlan [style=bold];
  CatDraw [style=bold];
  ItemDraw -> Render;
  ItemDraw -> CatDraw;
  ItemDraw -> CatPlan;
  Render -> CatPlan;
  CatPlan -> Cat;
  CatPlan -> Frame;
  CatPlan -> DepthSort;
  CatDraw -> Cat;
  CatDraw -> CatStills;
  CatStills -> Cat;
}
```

`CatPlan` and `CatDraw` never import each other. `ItemDraw` is what carries a plan's answer to the drawing.

`CatPlan` asks for the moment, places it, and decides whether it's big enough to draw. An empty list or a list of one is how it says "maybe", because the caller flattens them with `join_map`.

{{code CatPlan.cat_in_view}}

A plan decides how a thing looks, and drawing only paints it. That rule runs through all of Safari Ride.

Notice what isn't in this chapter: a cat in `Ride`, an update loop, or a flag saying the cat has already crossed. Roc doesn't force that, but pure functions make the stateless version the easy one to write, and every `->` shows it stayed that way.

## Credits

Safari Ride was designed by Steve Howell. Claude wrote most of the code and this tutorial under his direction.
