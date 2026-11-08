# Safari Ride: a tour of a real Roc program

A long walk through one program of about ninety Roc modules: the big picture, the details, and the big picture again.

## Introduction

Safari Ride is a program written in Roc, and it runs in the page below. It takes a moment to load. When it's ready, a ride starts by itself.

```widget ride
The ride, running as you read. Click it to give it the keyboard: Space pauses, and the arrows step.
```

This is Safari Ride. A rider cycles down a long road through open country, past trees, cows and pigs, with a truck somewhere ahead. Radio towers blink in the distance. A bird takes off as the rider comes near. A cat walks into the lane, freezes, and leaps for the far verge. The sun goes down behind the mountains, and the truck turns on its headlights.

Safari Ride has the important parts of a game's world: terrain, physics, a camera, things that react to the player, and a day that ends. It doesn't have game mechanics yet. Nothing keeps score.

A safari is a guided tour, so this is a tour of a tour. We'll start with the big picture, hold one frame still to see what's in it, let it move, and zoom back out at the end. You'll get to see how Roc holds up in a program with a lot going on.

We assume you can already read Roc. If you can't yet, the official tutorial is the place to start. We'll point out a few Roc ideas in each chapter as they come up.


## The problem

Here's the problem Safari Ride has to solve. We design a world once. Then, each time the clock steps, we move what moves, find everything near enough to see, and draw it against the backdrop.

The problem, as a loop
```dot
digraph problem {
  node [shape=box, fontname="Helvetica"];
  world [label="design the world\n(once)"];
  step [label="the clock steps"];
  move [label="move the rider and the truck"];
  look [label="look around:\nwhat's near enough to see?"];
  draw [label="draw it against the backdrop"];
  world -> step [label="  starts the clock"];
  step -> move [label="  each step"];
  move -> look [label="  from the new places"];
  look -> draw [label="  hands what it sees"];
  draw -> step [label="  next step"];
}
```

It works like a flipbook, the little stack of drawings that seems to move when you riffle the pages with your thumb. Each page is drawn whole. Safari Ride draws a page about thirty times a second. The code calls a page a frame, and a turn of the loop a step.

The most interesting box is the middle one: looking around. On a real safari, a guide scans the land and calls out what's there: a cat by the third tree, a bird on the far side. We'll call each of those a sighting. A sighting is only true for the moment it's made, so Safari Ride throws them all away and makes new ones for every page.

Only four things carry over from one step to the next: the rider, the truck, the clock, and the encounter plan, which says when the next cat or bird encounter starts. Everything else is worked out again each frame.

Everything in the picture is one of three kinds, sorted by what it lacks:

| Sort | Examples | Has | Lacks |
|---|---|---|---|
| Solids | the truck, the radio towers, the guard rails, the road and its ponds | every corner has its own place along, across and above the road | nothing |
| Cards | the cat, the bird, the cows, pigs and other animals by the road, the far trees | a foot on the road, and a width and a height on the screen | depth: they're flat, and always face you |
| Far scenery | the sun, the mountains, the rolling land | a direction and a height above the horizon | distance: they never come nearer |

Each kind is drawn its own way, and the rest of the book keeps to these three.

Next, let's look at what one of those boxes looks like in Roc.

## One whole module

A module of Safari Ride is one file of Roc. This chapter shows one from top to bottom, and it starts with a line that doesn't compile. Here we try to add 7 to the ride's clock:

{{fails clock_plus_seven}}

New in this chapter:

- Roc: opaque types, `is_eq : _`, `expect`, static dispatch
- Modules: `Clock`

This is the module that stops that line, all of it.

{{module Clock}}

Most of Safari Ride's small modules look like this: a comment saying what the thing is, some imports, and one type named after the module.

`Clock :: U32.{ ... }` defines an opaque type. Underneath, a `Clock` is a `U32`, and the block after it holds its methods.

`Clock.(n)` wraps a number into a `Clock`. In a parameter list, it does the opposite and unwraps one. Only this module can do either, which means no other module can add 7 to a clock, or pass a count of trees where a clock is expected.

`is_eq : _` asks Roc to derive equality for us. Below the type, each `expect` is a test, and `roc test` runs them all.

The error names `Steps`, a count of steps, because `+` on a clock is its `plus`, and `plus` takes a `Steps`, not a plain number.

Safari Ride calls it once a step, like this:

{{code RideInstant.next from "clock = instant.clock.next()" to "clock = instant.clock.next()"}}

`instant.clock.next()` is static dispatch: `next` is found from the type of `instant.clock`, so the call is written `next()`, not `Clock.next(...)`.

Because a clock is an ordinary value, a test about one fits on a single line. The `expect` above that checks `Clock.at_step(9).plus(Steps.of(3))` uses `Clock.at_step` to start at step 9 directly, so the test doesn't have to run the ride for nine steps first.

That's one module out of about ninety. In the next chapter, we'll see how the rest fit together.

## The modules

This chapter shows how the modules fit together, starting with the whole system, simplified.

Each arrow points from a module to a module it imports. A dashed box stands for a family of modules. Roc doesn't allow import cycles, so no arrow can point back up the diagram.

The whole system, simplified
```dot
digraph system {
  node [shape=box, fontname="Helvetica"];
  fontname="Helvetica";
  web [label="web.roc"];
  SafariApp; Tour; FrameView;
  subgraph cluster_ride {
    label="the ride";
    RideInstant; Rider; TruckJourney; World; Segment;
    critters [label="the critters\nCatCrossing, BirdFlight", style=dashed];
  }
  subgraph cluster_view {
    label="the view";
    sky [label="the backdrop\nSky, Skyline, Sun", style=dashed];
    Scene; RoadAhead;
    sightings [label="the sightings\nEncounterSighting, TreeSighting, ...", style=dashed];
    drawing [label="the drawing\nCat, Bird, TreeShapes, ...", style=dashed];
  }
  web -> SafariApp [label="  runs"];
  SafariApp -> Tour [label="  steps the ride with"];
  SafariApp -> FrameView [label="  draws each frame with"];
  Tour -> RideInstant [label="  steps"];
  Tour -> World [label="  starts on"];
  RideInstant -> Rider [label="  moves"];
  RideInstant -> TruckJourney [label="  moves"];
  World -> Segment [label="  builds"];
  Segment -> critters [label="  holds"];
  FrameView -> RideInstant [label="  reads"];
  FrameView -> sky [label="  paints"];
  FrameView -> Scene [label="  gathers sightings with"];
  Scene -> sightings [label="  asks"];
  sightings -> RoadAhead [label="  finds segments with"];
  RoadAhead -> Segment [label="  reads"];
  sightings -> drawing [label="  draws with"];
  drawing -> critters [label="  takes pose names from", style=dotted];
}
```

New in this chapter:

- Roc: imports that can't form a cycle
- Modules: `SafariApp`, `FrameView`, `Scene`, `EncounterSighting`

There are two halves. The ride is `RideInstant`, `Rider`, `TruckJourney` and `World`. `RideInstant` holds one instant of the ride and steps to the next. `World` puts the route together from segments, and the segments hold the critters.

The view is everything that turns the ride into a picture. `Scene` gathers the sightings, which work out what's visible, and the drawing code makes its shapes. Every arrow between the halves points one way, from the view to the ride. The view reads the ride, and the dotted arrow is the drawing taking its pose names, and the cat's height, from the critters. The ride never imports the view.

`FrameView` joins the two halves. It reads one instant of the ride and draws it. `Tour` steps the ride. The browser only ever sees `SafariApp`, which gives it a list of shapes each frame.

### The part that isn't Roc

One tick across the line between JavaScript and Roc
```dot
digraph tick {
  node [shape=box, fontname="Helvetica"];
  fontname="Helvetica";
  subgraph cluster_js {
    label="JavaScript";
    runner [label="keeps the clock,\ngathers the keys"];
    paint [label="paints the canvas"];
  }
  subgraph cluster_roc {
    label="Roc, compiled to wasm";
    advance [label="the next step"];
    frame [label="this frame's shapes"];
  }
  runner -> advance [label="  calls"];
  advance -> frame [label="  makes"];
  frame -> paint [label="  a list of shapes"];
}
```

Safari Ride runs in a browser, and that takes a thin layer of JavaScript. The Roc compiles to wasm. Each step, the JS keeps the clock, gathers the keys, and calls into Roc. Roc answers with a list of shapes, and the JS paints them on a canvas. The JS knows nothing of cats, and the Roc knows nothing of canvases. The whole game is on the Roc side of that line, and the same app also runs natively. `canvas_apps/ARCHITECTURE.md` has the details, and the platform chapter comes back to it.

### What's a sighting?

At step 1,570 of the ride, a cat is frozen in the lane. This is what `EncounterSighting` answers about it on that frame:

| Field | Value |
|---|---|
| `right` | 0.32 metres |
| `forward` | 30.42 metres |
| `pose` | `Frozen` |
| `lift` | 0 |

That's a sighting: where the rider sees something, and how it should look.

Most things in the view come in pairs, and the names say which half is which: `EncounterSighting` and `Cat` or `Bird`, `TreeSighting` and `TreeShapes`, `TowerSighting` and `Tower`, `TruckSighting` and `Truck`.

A sighting answers one question each frame: which of these can the rider see right now, and how should each one look? `EncounterSighting` goes through the stretches of road ahead, which Safari Ride calls segments, asks `EncounterPoses.cat_poses` where each cat is and how it stands, works out where that lands in the rider's view, and drops any cat behind the camera or too small to matter. What it hands back is a plain record with no drawing in it:

{{code Pipeline.Sighted}}

`Scene.scene_in_view` gathers every sighting's answer and renders each one through `Pipeline.rendering_of`, which asks the kind's own module for a picture and attaches the depth, making a `Rendered`. Trees go through `TreeSighting.tree_renderings`, which does the same after counting the nearer trees. Then `Scene.scene_renderings` puts the renderings in order, far to near. Because a sighting's answer is plain data, it can be checked with numbers, without drawing anything. So a sighting decides what's visible, and the drawing code only paints what it's told.

Cows, pigs and the other animals by the road are all sighted the same way, by `BillboardSighting`, which decides which of them get drawn. The thresholds behind that kind of decision sit with the code that uses them. `Pipeline.smallest_height_on_screen`, 2 pixels, is how short something may look and still be drawn. `TreeShapes.cone_reach` and `TreeShapes.round_trunk_limit` decide how near a tree shows its full detail.

Everything in this chapter happens within a single frame, and none of it survives to the next one. Only the four things from The problem carry over from step to step: the rider, the truck, the clock and the encounter plan. First, let's hold one frame still and see what's in it.

## The world

Some of Safari Ride never changes. Trees, cows, the pond and the road are built once and only read after that, which makes them the easiest part of the program to read, so the tour starts there.

```widget route
The whole route in one picture. The white stretch is segment 7, and the lines under the map read out its record.
```

Each stretch of this map is one record of a list called `World.segment_plans`, and the lines under the map read out the one in white. The marks on the map are the seven segments with a cat or a bird. We drew the map for this page: the ride itself never has one.

New in this chapter:

- Roc: void modules, record update, small tag unions in place of booleans, `match` that has to cover every tag, `var`, `crash`, tuples
- Modules: `World`, `Pond`, `Trees`, `Segment`, `Route`

The modules around `World`
```dot
digraph world {
  node [shape=box, fontname="Helvetica"];
  World [style=bold];
  World -> Route [label="  puts together"];
  World -> Segment [label="  builds"];
  World -> Trees [label="  picks a tree scheme from"];
  World -> CowHerd [label="  plans the cows with"];
  World -> PigHerd [label="  plans the pigs with"];
  World -> CatCrossing [label="  plans the cats' crossings"];
  World -> BirdFlight [label="  plans the birds' flights"];
  Route -> Segment [label="  holds"];
  Segment -> Pond [label="  places the ducks of"];
}
```

A piece of the world can be just a value. Here's the second whole module. `Pond` is a void module: a type with no values, whose block holds definitions. This one has three record aliases and six ducks.

{{module Pond}}

Its block holds two functions: the pond's outlines, and its ducks placed at a bend. `bank_inner_points` uses a record update. `{ ..point, past_end: ... }` is a copy of `point` with a new `past_end`, and `point` itself doesn't change. The ducks are read in `Segment.BendLife`, whose `DuckPond` case calls `Pond.placed_ducks`.

`World` turns a route, a plain list of records, into segments of road. A plan for a segment shows how much a small tag union can do. `CowHerd.Bull` is just `[WithBull, NoBull]`, and it says more than a boolean would at every place a segment is written down.

{{code World.SegmentPlan}}

A `match` on a closed union has to cover it: leaving out a tag is a compile-time error.

{{code Trees.accent_conifer}}

Here's where it's called. Trees stand in pairs, and after a green pair this `match` picks the kind of the next pair: `Gold`, `Red` or `SmallGreen`. `$conifer` is a `var`, a name the loop around it gives a new value each time, and the `$` marks it.

{{code Trees.roadside_trees from "match $conifer {" to "Green => accent_conifer(scheme)"}}

`Route.SegmentIndex` is another small opaque type, a `U32` for a segment's place in the route. A place in the route can't be confused with a count of trees, because nothing outside can do arithmetic on it. `crash` appears here too. It isn't for error handling: an index that isn't in the world is a bug in Safari Ride, not a case to handle.

{{code Route.segment_at}}

A value that never changes can be checked once, whole. Below its block, `Pond` keeps a function that's there for its tests, `is_inside_water`, in the module above. An `expect` under it runs that over all six ducks. One line covers the whole pond. Another `expect` under `is_inside_water` checks a list of pairs. Each pair in parentheses is a tuple, a fixed group of values whose types needn't match, and `all` checks every one.

Nothing in this chapter moves, and that's true of the next few chapters too, as we go through what's on one page of the flipbook. First, a word about what a page is made of.

## Shapes

Before we draw a tree, we need to know what drawing means here, because our Roc app doesn't draw anything. For each frame, Roc answers with a list of shapes, and a painter puts them on a canvas. The painter on this page is JavaScript. It could as well be a wasm host, written in Odin or Zig, say, and the Roc wouldn't change. A painter is a bit like a printer: it does what the list says, and nothing more.

New in this chapter:

- Roc: a record taken apart in a parameter list, `Try`
- Modules: `TwoShapes`, `Shapes`, `Polygon`, `Screen`, `Pixels`, `Picture`, `GroundPatch`

### Get the types right

Three types carry everything a frame paints:

| Type | What it is |
|---|---|
| `Screen.Point` | A place on the canvas, as an `x` and a `y` in `Pixels` from its top left |
| `Shapes.Shape` | One item in a frame's list, such as a polygon |
| `Picture` | The shapes that paint one object, in the order they're painted |

Safari Ride's frames are for a canvas 960 pixels wide and 600 pixels tall, and `y` grows downward. `Pixels` is a length on the screen. It's opaque like `Clock`, and it's an `F64` underneath, because a corner can fall between two pixels. A `Screen.Point` is a record of two of them:

{{code Screen.Point}}

`Screen.point(x, y)` makes one from two plain numbers.

A frame is a list of `Shapes.Shape`:

{{code Shapes.Shape}}

Each tag here carries a value in parentheses, called its payload. A `Poly` carries a record of its coordinates and its fill, and a `Disc` carries its center, as an `x` and a `y`, its radius and its fill. A conifer comes back to payloads. A fill is a `Brush.Fill`, another tag union: `Flat` with one color, or one of several kinds of shading and gradient.

That type serves every app under `canvas_apps`. Two of its tags, `Blend` and `View`, aren't shapes at all. They're marks that change how the shapes after them are painted. A frame of Safari Ride often holds more than 2,000 shapes, and nearly all of them are `Poly`.

Here's a frame with a triangle and a rectangle in it:

```widget shapes
The list `TwoShapes.shapes`, painted over a plain background, on a smaller canvas than the ride's.
```

It's made like this:

The two shapes, from the top
```dot
digraph shapes {
  node [shape=box, fontname="Helvetica"];
  "TwoShapes.shapes" -> "triangle" [label="  lists"];
  "TwoShapes.shapes" -> "rectangle" [label="  lists"];
  "triangle" -> "Polygon.triangle" [label="  calls"];
  "rectangle" -> "Polygon.rectangle" [label="  calls"];
  "Polygon.rectangle" -> "rectangle_corners" [label="  calls"];
  "Polygon.triangle" -> "Polygon.flat_polygon" [label="  calls"];
  "Polygon.rectangle" -> "Polygon.flat_polygon" [label="  calls"];
  "Polygon.flat_polygon" [style=bold];
}
```

A box is a definition, and an arrow points to a definition it uses. The top three are values, made once. The rest are functions in `Polygon`. The widget adds one more shape of its own, the plain background, at the front of the list.

### The functions

Here's the whole of `TwoShapes`:

{{module TwoShapes}}

A color is a whole number in hex, with the six digits a web page writes after its `#`. `0x2e8b57` is a green, and `0xe8a33d` is an amber.

`Polygon.triangle` doesn't put a triangle on the canvas. It makes a value that describes one. Every maker in `Polygon` works this way, and each gives back one shape. The triangle hands its three corners to `flat_polygon`:

{{code Polygon.triangle}}

The triangle takes two arguments: a record of three corners, and a color. Between the bars, `{ first_corner, second_corner, third_corner }` takes that record apart into three names. A caller gives all three by name, in any order, and can't leave one out.

`Polygon.rectangle` takes two opposite corners, and `rectangle_corners` works out all four, clockwise from the top left. Either way, `flat_polygon` makes a `Poly` of one color from a list of corners:

{{code Polygon.flat_polygon}}

`Brush.flat` turns a hex color into the color a painter wants, with no transparency, and wraps it in `Flat`, a fill of one color.

So our rectangle is a `Poly`, not a `Rect`. A rectangle is just a polygon with four corners, so it goes through the same `flat_polygon` as a triangle or a tier, and every polygon reaches the painter the same way.

A polygon needs at least three corners, and `polygon_coordinates` checks:

{{code Polygon.polygon_coordinates}}

Fewer than three would be a bug in Safari Ride, and a bug shouldn't quietly paint nothing, so it crashes. `maker` names the function that asked, so the crash says where the bug is.

Some things can rightly have nothing to show. A `GroundPatch` is a patch of ground, a list of corners on the ground and a color, and one wholly behind the camera has nothing to show. So `GroundPatch.patch_shape` answers a `Try`:

{{signatures GroundPatch.patch_shape}}

Its second argument is the lens's focal length, in pixels, which turns corners on the ground into places on the screen. A simple tree says more about the lens. A `Try` is either `Ok` holding a shape, or `Err` holding a reason, here `BehindCamera` or `PastHorizon`. Both answers are in the type, so whoever calls `patch_shape` can't forget the ground behind the camera.

### Pictures

Something made of several shapes is a list of them. A tree is nine: a trunk and eight tiers of foliage. The shapes that paint one object, in order, make a `Picture`:

{{signatures Picture.from_shapes Picture.to_shapes}}

`Picture` is opaque, and a `List(Shapes.Shape)` underneath. Outside its module, a picture is one thing, handed along whole until something paints it.

The order of a list is the order of painting, so in our frame the rectangle covers part of the triangle. A frame paints the backdrop, the mountains and the ground first, then a series of pictures, far to near.

For the next few chapters, the work is choosing corners and choosing their order. Before the first tree, though, we need the few types that every object along the road goes through.

## Nature types

The ride has six kinds of object: trees, towers, billboards such as the cows, the cat, the bird and the truck. Each kind is drawn its own way, and each kind's sighting module finds its own objects on the road. After that, every object takes the same steps: it's seen from the camera, drawn, and paired with a depth, so that it can be painted in order with all the others, far to near. Written once for each kind, those steps would be the same code six times over. Safari Ride writes them once, in `Pipeline`, and each kind says only how tall it is and how it looks.

New in this chapter:

- Roc: defining a type with a type variable, `where`
- Modules: `Geom`, `Along`, `Across`

`Pipeline` and `Rendered` came up in The modules, and here we look at them properly.

### Three forms and a kind

An object takes three forms on its way to the screen:

1. Placed: it stands at a spot on the road, measured along and across a segment.
2. Sighted: the camera sees it some distance to the right and forward.
3. Rendered: it's a picture, with a depth that says how far ahead of the camera it stands.

A sighting and a rendering last one frame. How long a placing lasts depends on the object. A tree or a cow is placed on the road once, when the world is built, and stays there for the whole ride. A cat moves, so it's placed anew for each frame.

The first two forms hold the object's kind. A kind, such as `Conifer` or `Billboard`, holds how the object looks right now, and never where it is. The forms around it hold where. A kind is asked for its height, to see whether the object stands tall enough on the screen to draw, and for its picture, which goes into the rendering. A rendering keeps the picture and not the kind.

`Conifer` is one of four tags, `Green`, `SmallGreen`, `Red` or `Gold`, and the tag alone settles a tree's height and color. `Billboard` is a record of an emoji's still, the emoji drawn as polygons, a height and which way it faces, and a cow, a pig or one of the ducks on the pond is one. Neither has a field for a place.

### Get the types right

| Type | What it is |
|---|---|
| `Geom.Placed(kind)` | An object on the road: its `road_point` on its segment, its `lift` off the ground, and its `kind` |
| `Spot` | Where an object stands in one frame: its segment's `place` from the rider, its `road_point`, its `lift`, and its `foot` in the rider's view |
| `Pipeline.Sighted(kind)` | An object in view: its `spot` and its `kind` |
| `Picture.Setting(context)` | What a kind draws from: its `spot`, the lens's `focal_length`, and a `context` for whatever else the kind needs |
| `Picture` | The object's shapes, in order, from the Shapes chapter |
| `Rendered` | The object's `picture`, and its `depth`: how far ahead of the camera it stands |

One object through one frame
```dot
digraph forms {
  node [shape=box, fontname="Helvetica"];
  placed [label="Geom.Placed(kind)\nroad_point, lift, kind"];
  sighted [label="Pipeline.Sighted(kind)\nspot, kind"];
  rendered [label="Rendered\ndepth, picture"];
  sorted [label="List(Rendered)\nfar to near"];
  placed -> sighted [label="  Pipeline.scenery_sighting_of\n  asks the kind's scenery_height"];
  sighted -> rendered [label="  Pipeline.rendering_of\n  asks the kind's scenery_picture"];
  rendered -> sorted [label="  Rendered.depth_sorted_renderings"];
}
```

A box is a type, and an arrow is a function that makes the next one. The kind goes in at the top and comes out of `Pipeline.rendering_of` as a picture. `Rendered` has no kind, so a tree's rendering and a cow's are the same type, and every rendering in the frame goes in one list for the depth sort. That sort is `DepthSort`, a stable merge sort that orders the list from far to near.

### A type with a type variable

We've used types that take an argument since Shapes. A `Picture` is a `List(Shapes.Shape)` underneath, and a `List` can hold any one type, named in its parentheses. `Geom.Placed` is a type of our own that works the same way:

{{code Geom.Placed}}

The `kind` in its head, `Placed(kind)`, is lowercase, and that makes it a type variable: a name for whatever type goes in the parentheses. The fields use it like any other type. So `Geom.Placed(Conifer)` is a record of a `road_point`, a `lift`, and a `kind` that holds a `Conifer`, just as `List(Shapes.Shape)` is a list that holds shapes. A cow is a `Geom.Placed(Billboard)`.

`Along` is a place along a segment, and `Across` is a place across the road, measured from its middle. Both are opaque, like `Clock`, so passing one as the other is a compile-time error. One place minus another is a `Distance`, not a place, and Roc's `-` always gives back its left side's type, so that subtraction is a named method, `distance_from`, rather than `-`.

A type's head declares its variables. A function's annotation needs no head: a lowercase name in it is a type variable, and it means one type wherever it appears in that annotation. `Pipeline.sighting_of` takes a `Geom.Placed(kind)` and answers with a `Try` that holds a `Pipeline.Sighted(kind)` when the object isn't behind the camera. Both name the same `kind`, so a placed conifer can only come back as a sighted conifer, never as a sighted cow.

`Picture.Setting(context)` has a variable named `context`. A conifer's context is a `TreeShapes.Detail`, `{ nearer_tree_count : U64 }`, how many trees are nearer than it. A billboard needs nothing more, so its context is `{}`, the empty record.

### Asking a kind by name

`Pipeline` imports neither `Conifer` nor `Billboard`, and neither of them imports `Pipeline`. Yet `Pipeline.rendering_of`, the one function this chapter shows in full, gets a picture out of either one:

{{code Pipeline.rendering_of}}

It hands the sighting's whole `spot`, the lens and the context to the kind's own `scenery_picture`. It answers with a `Rendered`: the picture it gets back, and how far forward the spot's foot is, `spot.foot().forward()`, as the depth.

The second line of the annotation, indented under the first, is a `where` clause. Its square brackets hold a list of requirements on the annotation's type variables, here one. `kind.scenery_picture : kind, Picture.Setting(context) -> Picture` says that the type `kind` has a method named `scenery_picture`, of the type after the colon. A kind meets it by having a method of that name and that type. `Conifer` has one, and so does `Billboard`. Neither says it meets a requirement, and no interface names the two. The name and the type are the whole contract, and the compiler checks them wherever `rendering_of` is called.

`context` appears twice in the annotation, in the record and in the `where`, so the context a caller passes has to be the one its kind's `scenery_picture` wants. Pass `{}` as a conifer's context, and Safari Ride doesn't compile:

{{fails conifer_without_context}}

`Pipeline.scenery_sighting_of` asks for a kind's height the same way, with `where [kind.scenery_height : kind -> Distance]`, where a `Distance` is a length in metres. It finds the sighting, then asks the kind for its `scenery_height`, to see whether the object stands tall enough on the screen to draw, and answers `TooSmall` when it doesn't. A tower and the truck skip that test, through `Pipeline.sighting_of`, which has no `where` at all.

Because a name and a type are the whole contract, the name has to say what it's for. A kind could well have a method called `height`, of type `kind -> Distance`, that measures something else, and a `where` clause that asked for `height` would take it without a word. The first word of `scenery_height` and `scenery_picture` says that the method is there for the objects along the road, so a kind meets the contract only on purpose.

Trees, towers, critters and the truck all go through these forms. The grass, the sky, the sun, the mountains and the road don't, and the rails make their `Rendered` by hand. The next three chapters are about trees.

## A simple tree

Let's draw a tree. Forget the road for now, and the rider, and the ride. All we know is what kind of tree it is, and where it stands from the camera.

Drawing a tree and placing trees along a road are two nearly separate problems. This chapter and the next draw one tree. The chapter after that, Roadside trees, puts trees in the world, relative to the road and the rider.

A tree is a trunk under eight tiers of foliage, and a far tree's tiers are flat triangles. Every tree a long way off is drawn exactly this way. The tree's kind decides how tall it is and what color.

New in this chapter:

- Roc: nominal types, one branch for two tags
- Modules: `Conifer`, `TreeShapes`, `Distance`, `Fraction`, `Camera`

### Get the types right

A tree passes through these types on its way to the screen:

| Type | What it is |
|---|---|
| `Conifer` | A tree's kind: `Green`, `SmallGreen`, `Red` or `Gold` |
| `Distance` | A length in metres, opaque like `Clock` and an `F64` underneath |
| `RiderView.RaisedPointAhead` | A point in front of the camera: `right` and `forward` of it, and `height` above the rider's level. `spot.base()` gives the middle of a tree's foot as one |
| `Camera.Upright` | Where an upright thing lands on the screen: its `foot`, and its `height_on_screen` in `Pixels` |
| `TreeShapes.Tier` | One layer of the crown, as fractions of the crown |

A conifer draws from a `Picture.Setting(TreeShapes.Detail)`, the setting from Nature types with the count of nearer trees as its context.

Each step of the job is a signature:

| Job | Function | Its type |
|---|---|---|
{{types row Conifer.scenery_picture Draw a conifer}}
{{types row TreeShapes.tree_picture Draw a tree of any height and color}}
{{types row TreeShapes.tree_outline Find it on the screen}}
{{types row TreeShapes.tier_triangle Make one tier}}

One tree, from the top
```dot
digraph tree {
  node [shape=box, fontname="Helvetica"];
  "Conifer.scenery_picture" [style=bold];
  "Conifer.scenery_picture" -> "TreeShapes.tree_picture" [label="  hands the height and color to"];
  "TreeShapes.tree_picture" -> "tier_inputs_of" [label="  calls"];
  "tier_inputs_of" -> "Camera.upright_on_screen" [label="  finds the outline with"];
  "TreeShapes.tree_picture" -> "trunk_shape" [label="  calls"];
  "TreeShapes.tree_picture" -> "tier_shape" [label="  calls"];
  "tier_shape" -> "tier_triangle" [label="  calls"];
}
```

A box is a function, and an arrow is a call. `Conifer.scenery_picture` is the only box that knows the kind. It works out a height and a color from the kind, and everything below it works from those and never learns the kind. `Conifer` imports `TreeShapes`, and `TreeShapes` doesn't import `Conifer`, so a fifth kind of tree wouldn't touch a line of `TreeShapes`.

### The functions

Here's all of `Conifer`:

{{module Conifer}}

`Conifer := [Green, SmallGreen, Red, Gold].{ ... }` is a nominal type. Like `Clock`, it carries a block of definitions. Unlike `Clock`, it isn't opaque. The one symbol that differs, `:=` here against `::` for `Clock`, is what decides that. Because it isn't opaque, other modules can use its tags. `Trees.accent_conifer`, back in The world, picks `Gold` for a scheme of gold and green.

No tree stores its height. `scenery_height` works it out from the kind, so there's no stored copy to disagree with it. In `foliage_color`, `Green | SmallGreen =>` is one branch for two tags, because both greens share one color.

`scenery_picture` takes the kind and a setting, and hands the setting whole to `TreeShapes.tree_picture`, with the tree's height and color in the record that function wants.

`tree_picture` finds the tree on the screen, then makes a trunk and eight tiers. Its bars take the setting apart into `spot`, `focal_length` and `context`, as `Polygon.triangle` did with its corners.

{{code TreeShapes.tree_picture}}

`spot.base()` is the middle of the tree's foot, as a point in front of the camera. `tier_inputs_of` works out from it what every tier needs, among them the tree's `outline` on the screen. `trunk_shape` makes the trunk, a rectangle, and `tier_shape` makes each tier. `tiers.map(...)` calls it for every tier and gives back the list of answers, and `[trunk].concat(...)` puts the trunk first, so the tiers paint over it. What `trunk_finish_of` and the crown do for near trees can wait, but notice the tags of `TrunkFinish`, `[Shaded, Flat]`. This `Flat` has nothing to do with the fill `Flat` from Shapes. Two tags with one name in two unrelated unions are two different tags. For a far tree, `tier_shape` answers with `tier_triangle`, and the next chapter shows the rest of it.

The tree's outline is where it lands on the screen, and how tall it looks there:

{{code TreeShapes.tree_outline}}

`Camera.upright_on_screen` projects two points through the lens: the tree's foot, and its top, `height` above the foot. The difference between them on the screen is how tall the tree looks.

The trunk and the crown split the tree's height between them:

{{code TreeShapes.trunk_height_share}}

{{code TreeShapes.crown_height_share}}

A `Fraction` is a number from 0 to 1. `Fraction.of` makes one, and it crashes on a number outside that range, because a ratio out of range is a bug in the sum behind it. `complement` is one minus a fraction, so the two shares add up to 1 by construction.

### Triangles

A tier is three fractions:

{{code TreeShapes.Tier}}

`tiers` is a list of eight of these, and each overlaps the next. A tier is one triangle, worked out in pixels, with its apex on the tree's middle line and its base across the tier's bottom:

{{code TreeShapes.tier_triangle}}

That's a tree, and from a distance nobody can tell it's flat. Ride close to one, though, and it looks like cardboard.

## A conifer

A near tree needs to look round, and it has to fatten as you ride past it. So Safari Ride draws two styles of crown: flat triangles far off, and 3-D cones up close. The tree is still alone in front of the camera, and the road can wait one more chapter.

New in this chapter:

- Roc: a payload that exists only where it means something, a list pattern that takes from the end
- Modules: nothing new

### Get the types right

The whole decision is one type:

{{code TreeShapes.Crown}}

The square brackets list everything a `Crown` can be. This is a tag union, as in The world, and `Cones` and `Triangles` are its tags. A tag is a capitalized name, and it needs no other declaration. So far a `Crown` is one of two names.

The parentheses are where it goes further. As in Shapes, a tag can carry a value, its payload. The payload of `Cones` is a record with one field, `shade`, and `Triangles` has no payload at all. So a `Crown` is written one of two ways:

| Value | What it says |
|---|---|
| `Cones({ shade: Fraction.of(0.5) })` | Cones, half shaded |
| `Triangles` | Triangles, and nothing more to say |

A triangle has nowhere to put a shade, and a cone can't be missing one. The only way to reach a `shade` is a `match` branch for `Cones`, and we'll see one shortly.

Three functions carry the decision:

| Job | Function | Its type |
|---|---|---|
{{types row TreeShapes.crown_of Decide, once for the tree}}
{{types row TreeShapes.tier_shape Act on it, for each tier}}
{{types row ConvexHull.cone_hull_points Outline a cone}}

A near tree's tiers
```dot
digraph cone {
  node [shape=box, fontname="Helvetica"];
  "TreeShapes.tree_picture" -> "crown_of";
  "TreeShapes.tree_picture" -> "tier_shape";
  "tier_shape" -> "tier_triangle";
  "tier_shape" -> "tier_cone";
  "tier_cone" -> "Camera.project";
  "tier_cone" -> "cone_hull_points";
  "cone_hull_points" -> "hull_points_of_sorted";
  "hull_points_of_sorted" -> "trim_hull";
  "trim_hull" -> "trim_hull";
  "crown_of" [style=bold];
}
```

`tree_picture` asks `crown_of` once, and hands the answer to `tier_shape` for every tier. The arrow from `trim_hull` to itself is a function calling itself, and we'll see why.

### The functions

`crown_of` answers with a `Crown`:

{{code TreeShapes.crown_of}}

Two `TreeShapes` thresholds decide how much of a tree gets drawn: `cone_reach`, 200 metres, and `round_trunk_limit`, 4 nearer trees. Shade fades from full at the camera to none at 80 metres.

```widget tree
Three gold trees, each drawn by `Conifer.scenery_picture`. Under each are its distance and what `crown_of` said.
```

`tier_shape` acts on that decision. Its `TierInputs` is the record `tree_picture` built as `inputs`: what every tier of one tree needs, from the tree's tip and the lens to its color and its crown.

{{code TreeShapes.tier_shape}}

`Camera.project` needs points in front of the camera, and `RiderView` draws that line at its near plane, 0.4 metres ahead. `cone_ring_points` builds a ring of 16 points around the tier's base, and it answers `Err(BehindCamera)` if any of them reaches back past the near plane. Then the tier falls back to the flat triangle.

A frame has no cones, only polygons, so we work out the polygon a cone would make. We leave pixels behind for a moment and work in metres. `height_down_crown` says how high a point stands, given how far down the crown it is. `top` and `bottom` count down from the crown's tip, so the ring stands at the tier's `bottom` and the apex at its `top`. `tier_cone` projects the ring and the apex onto the screen:

{{code TreeShapes.tier_cone}}

`shaded_polygon` makes a polygon whose fill is darker at its edges and lighter in its middle, and `strength` says how much, so a near cone looks rounder than a far one. The shade from `crown_of` goes in as that strength.

That leaves 17 points on the screen, and a cone's outline is whatever wraps around them. That's a convex hull:

{{code ConvexHull.cone_hull_points}}

This is Andrew's monotone chain, which A. M. Andrew published in 1979. Put the points in order from left to right, walk along the top, and walk back along the bottom. Any points can be sorted into that order, and `convex_hull_points` does that for a ring too small to have two arcs:

{{code ConvexHull.convex_hull_points}}

`sort_with` sorts by a function that compares two points and answers `Before`, `Same` or `After`, and `left_to_right` is that function: left first, and the higher of two at one x. A cone's ring doesn't need the sort. It's convex on the screen and keeps its order around the circle, so `ring_hull_points` merges its two arcs from the leftmost point to the rightmost, slots the apex in, and has the points in order already. If rounding leaves the merge out of order, it sorts after all. Either way, the walks are `hull_points_of_sorted`:

{{code ConvexHull.hull_points_of_sorted}}

The top walk ends on the rightmost point, where the bottom walk starts, and the bottom walk ends on the leftmost, where the top walk started. So each walk drops its last point before the `concat`, and no corner appears twice. `fold` walks a list from the front, carrying an answer from item to item, and `fold_rev` is the same from the far end, with its arguments the other way around. `trim_hull` serves both walks: before a point goes on, it drops the last point of the hull while that point would make a dent, and it calls itself until none does. `[.., a, b]` is a list pattern that takes the last two items.

{{code ConvexHull.trim_hull}}

A whole cone comes out as one polygon. The ring gets wider on the screen as it gets nearer, so the tree fattens as you pass.

So much for one tree. The road has hundreds.

## Roadside trees

Here's the other tree problem. Safari Ride places 392 trees along its road, and only some of them are in view at any moment. For each frame, it has to find those, and say where each one stands from the camera. Once a tree is found, `Conifer.scenery_picture` from A simple tree draws it. The kind still matters here in two places: a gold tree is placed farther from the road, and a tree's height decides whether it's tall enough on the screen to draw.

```widget frame trees
Step 1,570 of the ride, with only the trees on.
```

This is step 1,570 again, the frame with the frozen cat, showing only its trees. There are 184 of them, out of 392. At nine shapes each, they make up 1,656 of the 2,713 shapes in that frame, more than everything else put together.

A tree goes through the three forms from Nature types, with a `Conifer` as its kind. It's placed once, for the whole ride, and sighted and rendered for each frame that can see it.

New in this chapter:

- Roc: `var` and `while` in a pure function
- Modules: `TreeSighting`, `RoadAhead`

### Get the types right

A placed tree has a name of its own: `Trees.RoadsideTree` is another name for `Geom.Placed(Conifer)`. A tree's sighting is a `Pipeline.Sighted(Conifer)`, and its rendering is a `Rendered` like any other. A tree never looks at its sighting's `place`, `along` or `across` again, but a radio tower will.

| Job | Function | Its type |
|---|---|---|
{{types row Trees.roadside_trees Place a segment's trees, once}}
{{types row TreeSighting.trees_in_view Find the trees in view, for each frame}}
{{types row TreeSighting.tree_renderings Render them, for each frame}}

A tree, once and for each frame
```dot
digraph roadside {
  node [shape=box, fontname="Helvetica"];
  fontname="Helvetica";
  subgraph cluster_once {
    label="once";
    "World.built_segment" -> "Segment.from_choices" [label="  builds a segment with"];
    "Segment.from_choices" -> "Trees.roadside_trees" [label="  places its trees with"];
  }
  subgraph cluster_frame {
    label="for each frame";
    "TreeSighting.trees_in_view" -> "TreeSighting.segment_trees" [label="  asks for each segment's"];
    "TreeSighting.segment_trees" -> "Pipeline.scenery_sighting_of" [label="  sights each tree with"];
    "Pipeline.scenery_sighting_of" -> "Pipeline.sighting_of" [label="  starts with"];
    "TreeSighting.tree_renderings" -> "Pipeline.rendering_of" [label="  renders each tree with"];
    "Pipeline.rendering_of" -> "Conifer.scenery_picture" [label="  calls through its where clause"];
  }
  "Trees.roadside_trees" -> "TreeSighting.trees_in_view" [style=dotted, label="  the trees, read again"];
  "TreeSighting.trees_in_view" -> "TreeSighting.tree_renderings" [style=dotted, label="  the sightings, handed on by Scene"];
  "Conifer.scenery_picture" [style=bold];
}
```

A box is a function, and a solid arrow is a call. A dotted arrow is a step's answer going on to the next step: the trees that `World` placed, read again for each frame, and then the sightings, which go on to be rendered. `Conifer.scenery_picture`, in bold, is where A simple tree began.

### Placing

Placing a segment's trees walks along the segment and keeps a list, and a loop says that best.

{{code Trees.roadside_trees}}

`var` makes a name that can change, and a `$` marks every use of one, so the names that change stand out. The function is still pure, because nothing outside it can see them change.

Trees stand in pairs, one on each side of the road, every 30 metres. `{ ..left_tree, across: ... }` makes the right tree from the left one, with the record update from The world. The pairs take turns: a big green pair, then a pair of the segment's accent, which is small green, red or gold, then big green again. A gold pair stands farther from the road, because it's so much taller:

{{code Trees.tree_line_distance}}

### Seeing the trees

For each frame, `trees_in_view` goes through the segments of the road ahead, the ones the rider can see. `join_map` is a `map` followed by a flatten:

{{code TreeSighting.trees_in_view}}

{{code TreeSighting.segment_trees}}

From here on, things are measured from the camera, which travels with the rider. We don't need to know much about the rider yet.

{{code Pipeline.scenery_sighting_of}}

`place` says which segment of the road ahead the tree stands on. It's usually `Ahead(position)`: a segment so many ahead of the rider's. The size test asks for 2 pixels, through the camera's own lens.

`Pipeline.scenery_sighting_of`, from Nature types, starts with `Pipeline.sighting_of`, which asks `RoadAhead.rider_point_at` where the tree's spot on the road lies from the rider. The math layer chapter shows how. If that spot is no farther ahead than the near plane from A conifer, the answer is `BehindCamera`. Otherwise it's a sighting.

Then `scenery_sighting_of` calls a tree under 2 pixels tall on the screen `TooSmall`. So the answer is a `Try`: a sighting, or one of those two reasons. `keep_oks`, in `segment_trees`, keeps the sightings and drops the reasons.

### Spending the detail

Far trees are cheap. They get eight triangles and a plain trunk. A cone costs a ring of 16 points and a hull, so only trees within 200 metres get cones. A shaded trunk looks round, and the effect only shows on a trunk wide enough on the screen, so it goes to the nearest four trees and no others.

"The nearest few" is the one thing a tree alone can't tell us, because it depends on the other trees. So `tree_renderings` counts them, and the count goes in as the conifer's context, the `nearer_tree_count` from Nature types:

{{code TreeSighting.tree_renderings}}

{{code TreeSighting.nearer_tree_count}}

`count_if` answers a `U64`, and that's the type the context wants, so the count goes in as it is.

`Pipeline.rendering_of` hands that context to `Conifer.scenery_picture`, and the tree's `Rendered` joins the towers' and the critters' in the frame's one list.

So `World` holds every tree's place for the whole ride, and no frame remembers anything. Every sighting is thrown away, and the next frame makes them all again.

Most things in a frame work this way: placed once, then sighted and rendered for each frame. Grass needs none of that.

## Grass

The grass is one rectangle.

New in this chapter:

- Roc: nothing new
- Modules: `Grass`

`Grass` has one color:

{{code Grass.grass_color}}

The backdrop is what's behind the ride. `FrameView.backdrop_shapes` paints it as the sky, the sun and the grass, and this is the grass:

{{code Grass.grass_shape}}

It starts a pixel above the horizon, so no seam shows between the grass and the sky:

{{code Grass.grass_top_y}}

It's much wider than the screen because the whole picture tilts when the rider leans, and the corners have to stay filled.

Nothing else in the program draws grass. A segment doesn't have any, and there's no sighting for it. The grass is whatever hasn't been painted over.

The other big thing in the backdrop is more interesting.

## The sun

The sun is a circle. That's the easy part, so it's the part we'll do here.

New in this chapter:

- Roc: tags in place of `null`
- Modules: `Sun`, `Angle`

### A circle

A frame is a list of shapes, and a circle is one of them. `Disc` is a tag from `lib.Shapes`. This is the sun's, from `Sun.sun_shapes`:

{{code Sun.sun_shapes from "Disc({" to "fill: look.disc,"}}

A `Disc` has a center, a radius and a fill. The grass comes after it in the list and paints over whatever falls below the horizon, so the sun can sink behind the land with no more code.

The fill makes it look like a sun. `Sun.look` builds two, a disc and a glow behind it:

{{code Sun.look}}

`Radial` runs from pale yellow in the middle to orange at the edge. `Glow` is a wide haze that fades to nothing. Both are tags with records inside, so a fill is plain data, and the browser does the painting. The lens's `focal_length` sets how large the sun is drawn, because a wider view makes it look smaller.

### Angles that can't be mixed up

The sun stands in one direction, and the rider may not be facing it. That needs angles. `Angle.Bearing` is a direction in the world and `Angle.Turn` is a change of direction. Here we pass a `Turn` where a `Bearing` is wanted:

{{fails turn_as_bearing}}

Opaque types do the most work from here on. A `Bearing` and a `Turn` are both floats underneath, but only the `Angle` module can build or open one.

Two tags say whether the sun is in view, so there's no `null` and no off-screen sentinel value. A caller has to handle `OutOfView`, because `match` must cover every tag.

{{code Sun.Sighting}}

{{code Sun.sun_in_view}}

`sun_in_view` asks `Lens.far_point` where the sun lands on the screen. `far_point` takes one record argument, destructured in its parameter list. `turn.abs() >= quarter_turn` compares two `Turn`s. The code never touches radians until it has to do trigonometry, because `.tan()` works on a float.

{{code Lens.far_point}}

Its caller, `FrameView.frame_view_at`, is short enough to read whole:

{{code FrameView.frame_view_at}}

Those functions all take a `clock`, and that's the hard part. The sun sinks a little with every step, and the sky's colors, the mountains and the truck's headlights all follow it. That's a lot of heavy lifting for a circle. It gets a chapter of its own, The setting sun, once things start to move.

## The sky

The sky changes all through the ride, but a frame only has to ask one question: what color is it right now? The answer depends only on the clock.

New in this chapter:

- Roc: `->` as a promise
- Modules: `Sky`

`Sky` is a set of functions that each take a clock and answer with a color.

The modules around `Sky`
```dot
digraph sky {
  node [shape=box, fontname="Helvetica"];
  Sky [style=bold];
  FrameView -> Sky [label="  asks for the colors and the darkness"];
  Sky -> SunPath [label="  asks how high the sun is"];
  Sky -> ColorShade [label="  blends two colors"];
  Sky -> Fraction [label="  measures darkness and warmth"];
  ColorShade -> Fraction [label="  takes a share of the way"];
}
```

`Sky` sits near the bottom of the system. It imports `SunPath` and a few small types, and it knows nothing of the rider or the road. `FrameView`, above it, asks for the colors at a given clock, and for how dark the sky is.

Every function in this chapter has a `->` arrow, not `=>`. That tells you the function has no effects, and the compiler holds it to that. So the same clock always gives the same sky. If you don't see a `=>`, you only have to think about what the function is given.

Here's the question being asked. `FrameView.frame_view_at` takes the clock from the current instant and hands it to `Sky.colors_at`, which answers both colors.

{{code FrameView.frame_view_at from "sky_colors: Sky.colors_at" to "sky_colors: Sky.colors_at"}}

### Two colors

The sky is two colors, the top of the sky and the horizon. Here they are at five steps of the ride:

| Step | Top of the sky | Horizon |
|---|---|---|
| 0 | `0x8ecae6` | `0x8ecae6` |
| 2,000 | `0x86bfdb` | `0x86bfdb` |
| 3,000 | `0x73a6c4` | `0x9a898f` |
| 4,000 | `0x517697` | `0x9c6662` |
| 5,000 | `0x243a5e` | `0x243a5e` |

Every color in the sky is a blend of two others, and a blend needs a ratio. `Fraction` is another small opaque type, a ratio from 0 to 1, and only its own block can build one, so a `Fraction` is always in range. It has two ways in. `Fraction.of` takes a ratio that can only be in range and crashes on anything else, because that would be a bug in the sum. `Fraction.clamp` takes a ratio that can rightly fall outside, and holds it at the nearest end.

`color_between` takes one record argument, destructured in its parameter list, so callers name every field. Each channel moves the same share of the way. An `RgbColor` is opaque, and its `red`, `green` and `blue` each answer a `U8`.

{{code ColorShade.color_between}}

`sky_top_color`, one of the two colors `Sky.colors_at` answers, calls it to blend day into night. `Sky.darkness_at` says how dark the sky is. That's a `Fraction` too, and The setting sun works it out.

{{code Sky.sky_top_color}}

`sky_horizon_color` is the same sky, warmed toward red near sunset.

{{code Sky.sky_horizon_color}}

`Sky.sky_shape` paints the two as a gradient, down to the horizon. It stays on the top color for the first fifth of the way, then fades:

{{code Sky.sky_shape from "Linear({" to "end_point: { x: 0.0, y: Screen.horizon_y.to_f64() },"}}

A color is one integer all along, `0xRRGGBB`, the form a `Brush` wants. `RgbColor.from_channels` builds one from three channels with method calls on plain numbers. Static dispatch finds `to_i64`, `shl_wrap` and `bitwise_or` on Roc's own types. That makes `from_channels` a leaf: it calls nothing of Safari Ride's own.

{{code RgbColor.from_channels}}

One more thing in the frame goes dark with the sky: the mountains.

## Mountains

However far the rider goes, the mountains never get any closer. They only turn as the rider turns. That makes them much simpler than they look.

New in this chapter:

- Roc: a function in a record field
- Modules: `Skyline`

There are two ranges, one to the north with snow on its peaks, and a lower one to the west. A range is a record:

{{code Skyline.MountainRange}}

It's measured in bearings and pixels, not metres. There's no terrain behind it. All a mountain has is a height at a bearing:

{{code Skyline.range_height}}

A range is highest in its middle and falls to nothing at its ends. Two waves on top of that make the ridges. The rolling land in front of the ranges is a single wave of its own, in the same green as the grass.

To draw a range, we go across the screen two pixels at a time and ask how high the skyline is at each bearing. The caller passes in `height_at`, a function in a record field, so one `silhouette` draws all three:

{{code Skyline.silhouette}}

`Skyline.skyline_shapes` paints them back to front:

{{code Skyline.skyline_shapes}}

The rock darkens with `darkness`, the same `Fraction` that darkens the sky, and the snow goes blue. `snow_color` uses the sky's own `ColorShade.color_between`:

{{code Skyline.snow_color}}

That's nature. Next come the things people built.

## The road

A road of straight segments still has to get round its bends. Where two segments meet, something has to pave the corner and put up a rail.

```widget bends
Three bends from above. The rail changes sides with the bend, and a sharper bend pushes the apex further out.
```

Each road here is two segments, seen from above, and the white dot is where the view is from. The rail runs along the outer edge of the bend, and the yellow dot is the apex, where the outer edges of the two segments meet. The first bend turns left and the second right, so their outer edges are on opposite sides. The third is a sharper turn to the right.

New in this chapter:

- Roc: closures that give a repeated call a short name, `List.from_iter` with `until`
- Modules: `BendInView`, `GroundSighting`

`BendInView` knows where two segments meet. `GroundSighting` and `RailSighting` each ask it about a bend, and each answers with plain data for another module to draw.

The modules around `BendInView`
```dot
digraph road {
  node [shape=box, fontname="Helvetica"];
  BendInView [style=bold];
  GroundSighting -> BendInView [label="  asks about a bend"];
  RailSighting -> BendInView [label="  asks about a bend"];
  GroundSighting -> GroundPatch [label="  makes patches"];
  GroundSighting -> Pond [label="  asks for its outlines"];
  RailSighting -> GuardRail [label="  cuts the path into quads"];
  GroundSighting -> RoadAhead [label="  sees road points from the rider"];
  RailSighting -> RoadAhead [label="  sees road points from the rider"];
  BendInView -> RoadAhead [label="  sees road points from the rider"];
  BendInView -> Geom [label="  finds the outer edge"];
}
```

### Get the types right

A point at a bend can be measured two ways. On the road, a point is a `Geom.RoadPoint`, measured along and across the segment before the bend. From the rider, it's a `RiderView.RiderPoint`, right and forward of the camera. `RoadAhead.rider_point_at` is the one map between them. The corner is worked out on the road first, then seen from the rider, and the paving and the rail only ever take rider points.

A bend is a small record:

{{code BendInView.BendInView from "A bend as the rider sees it" to "}.{"}}

`before` says where the first segment lies from the rider, and `bend` holds its length and its turn. The turn is positive to the right. Where the segment after lies comes from `place_after`.

The outer corner is three points. Its type takes the kind of point as a type variable, so the same record holds road points or rider points:

{{code BendInView.OuterCorner}}

Each step of the job is a signature:

| Job | Function | Its type |
|---|---|---|
{{types row BendInView.outer_edge Find the outer edge}}
{{types row BendInView.outer_corner Find the corner, on the road}}
{{types row BendInView.outer_corner_in_view See the corner from the rider}}
{{types row GroundSighting.bend_paving Pave it}}

### Where two segments meet

{{code BendInView.outer_edge}}

A bend to the right has its outer edge on the left. That's why the rail changes sides between the first two bends.

{{code BendInView.outer_corner}}

All three points are measured on the segment before. `end_before` is where its outer edge ends. The next segment is turned, so its outer edge starts a little past that end and a little in from the edge: that's `start_after`, carried back onto this segment. Follow the next segment's outer edge from `start_after` until it meets this segment's outer edge, and that's the apex, the yellow dot. For a turn under a right angle, that's a run back along the road, so `along_to_apex` comes out negative.

The road is 4 metres wide, and the apex sits halfway round the turn, so at a turn of 45 degrees it lies 4 × tan(22.5°) past the end of the first segment. That's the 1.7 metres the widget shows.

`outer_corner_in_view` turns the three points into the rider's view, for the paving and the rail.

### Paving a corner

A piece of ground is a list of corners and a color.

{{code GroundSighting.road_patch}}

That's what `GroundPatch` paints. It's plain data, so it can be checked with numbers. The widget counts three patches, and here's where they come from.

{{code GroundSighting.road_along}}

Every whole-number type has an `until`, like `U64.until`, and the `U32` one here counts from 0 up to just short of its second argument. `List.from_iter` collects that count into a list.

A segment's road is one patch. Its edges are cut into chunks of 25 metres or less, which keeps each straight cut within a pixel of the curve where the road meets the horizon. The widget's two segments make two patches, and the bend makes the third.

`corner` is a closure: it captures `road`, `vantage` and `place`, so each call names only a chunk and an edge.

{{code GroundSighting.lead_in_length}}

The bend's patch also lays the last 40 metres of the road before it, so the bend's own paving is all the rider needs from a segment just behind.

{{code GroundSighting.bend_paving}}

The patch goes round in order: up the left edge, across the end of the next segment's first chunk, and back down the right. The side on the outside of the turn takes a detour through the outer corner's three points. `before` and `after` are two more closures, so the two lists read alike.

A pond is ground too. A segment that ends at a pond adds two more patches, its bank and then its water, laid out by `Pond.pond_outlines`.

The corner has its paving. Next, it needs a rail.

## Rails

A guard rail is a metal bar on thin posts, along a path on the ground. At each bend, the path runs along the road's outer edge, out to the apex, where the outer edges of the two segments meet, back, and on along the next segment.

New in this chapter:

- Roc: nothing new
- Modules: `RailSighting`, `GuardRail`

The path of a guard rail
```dot
digraph rail {
  rankdir=LR;
  node [shape=box, fontname="Helvetica"];
  up [label="runup_points:\n10 metres along\nthe first segment"];
  out [label="leg_points:\nout to the apex"];
  back [label="leg_points:\nback to the\nsecond segment"];
  on [label="runout_points:\n10 metres along\nthe second segment"];
  up -> out [label="  turns out"];
  out -> back [label="  turns back"];
  back -> on [label="  runs on"];
}
```

### Get the types right

A quad is a flat piece with four corners: one for each stretch of bar, and one for each post.

{{code GuardRail.RailQuad}}

Each quad goes into the frame's depth sort on its own, so a tree can stand in front of one post and behind the next. A quad has no kind for `Pipeline` to ask about, so it makes its own `Rendered`, at its own depth:

{{code GuardRail.quad_rendering}}

### The functions

For every bend in view, `RailSighting` finds the rail's path and cuts it into quads:

{{code RailSighting.rail_quads_in_view}}

{{code RailSighting.rail_points}}

The four parts of the list are the four boxes.

{{code RailSighting.leg_points}}

A leg gets a point about every metre, because a post stands at every point. It leaves out its first point, which is the last point of the leg before it.

`GuardRail.quads_along` turns the path into quads: the bars between neighbouring points, then a post at each point. At a turn of 45 degrees, the path has 25 points, so the rail is 24 bars and 25 posts: 49 quads, each in the depth sort on its own.

A rail is never stored. Every frame works out its bars and posts again, from the route and the rider, and throws them away.

## Radio towers

The radio towers stand well back from the road. One stands past the end of every segment, off to the right, and a long segment has one more halfway along, off to the left. Each is a lattice of thin rods, 80 metres tall.

A tower raises two problems a tree doesn't. Far off, it should sink over the horizon, and up close, it can stand partly behind the camera. It comes in three parts: a place by the road, worked out each frame from its segment; one deliberate cheat, an earth that curves much faster than ours; and a shape, a lattice of rods on a square footprint.

New in this chapter:

- Roc: a `match` on a pair
- Modules: `TowerSighting`, `Tower`

### Get the types right

The tower itself is two facts: which way it's turned, and its beacon. The tower at a segment's end is turned to the road, and the one halfway along stands square with it.

{{code Tower.Tower from "A tower in a frame" to "Tower :: {"}}

While its shapes are worked out, a tower's measurements for this frame travel together, including how far the earth's curve has sunk it:

{{code Tower.TowerGeometry}}

Each step of the job is a signature:

| Job | Function | Its type |
|---|---|---|
{{types row TowerSighting.end_tower Place a tower past a segment's end}}
{{types row Tower.scenery_picture Draw it}}
{{types row EarthCurve.exaggerated_drop Sink it}}
{{types row RiderView.line_ahead Make one rod}}

### Where a tower stands

Trees get their spots once, when the world is built. A tower doesn't: each frame, its sighting works out its spot from its segment. Here's the tower past a segment's end:

{{code TowerSighting.end_tower}}

The `beacon` line lights the beacon for this step. The tower halfway along is the same, with `Midway` for its beacon, a square yaw, and a second way to fail, `NoMidTower`. `mid_tower_point` says whether a segment is longer than a kilometre, and where its halfway tower stands. It sits in `TowerSighting` beside the end tower's numbers, so where towers stand has one home, and the world itself knows nothing about towers.

To draw a tower, `scenery_picture` also needs the road and where the camera stands, to find the four corners of its base in the rider's view. So those two go in as its extra input, its context:

{{code Tower.scenery_picture}}

### Over the horizon

As a tower gets further away, it sinks below the horizon from the bottom up:

{{code EarthCurve.exaggerated_drop}}

The ride's ground already curves, with a radius of 100 km. Towers sink over a tighter curve, 20 km, so an 80-metre tower is gone by 1.8 km instead of 4 km, and you can watch it go.

### Rods

Here's the whole tower, from the top. Nothing is drawn once the curve has hidden it all. Otherwise come the legs, the rings and the braces, and the beacon's disc last, at the top:

{{code Tower.tower_shapes}}

A tower's footprint is a square, and four tags name its corners. Going round the square is a `match`:

{{code Tower.next_corner}}

Four legs run from the corners up to the top. Each starts at the geometry's `sunk`, the height the curve has hidden, so nothing below the horizon is drawn:

{{code Tower.leg_shapes}}

Every 20 metres up, short of the top, a ring of four rods joins each corner to the next, which is what `next_corner` is for. Crossed braces fill the lowest two storeys.

Each rod is a line between two points in the rider's view, and it needs some care, because a near tower can stand partly behind the camera:

{{code RiderView.line_ahead}}

The `match` is on a pair, so it has to cover all four combinations. A rod with one end behind the near plane, 0.4 metres ahead of the camera, is cut where it crosses that plane, and a rod with both ends behind it isn't drawn.

That's a tower: a few dozen rods and a disc, worked out again each frame from its segment. The rods never change. The disc on top blinks, and that waits until the clock starts.

## Stills: how we draw a critter

Before we can stand an elephant by the road, we have to be able to draw one. Every critter in Safari Ride is a *still*: a small picture made of filled polygons, stored as data. An elephant has one still. A cat has seven, one for each pose, and a bird has six. Those two have to wait until things start moving, but we can look at them now. Animating a critter comes down to choosing which still to show, and where.

```widget stills
Every pose of the cat and the bird. Click one to see it large, and click it again for its polygons.
```

New in this chapter:

- Roc: a large table of plain data
- Modules: `Still`, `StillShapes`, `CatStills`, `BirdStills`, `EmojiStills`

The stills are the least readable code in Safari Ride, and nobody is meant to read them. They're generated data, encoded as Roc, and this chapter ends with how they got made. Here's how much data each set holds:

| Stills | Kind | Pictures | Polygons | Points |
|---|---|---|---|---|
| `BirdStills` | Hand-drawn | 6 poses | 32 | 119 |
| `CatStills` | Hand-drawn | 7 poses | 275 | 13,219 |
| `EmojiStills` | Emoji-based | one for each animal by the road | 129 | 4,998 |

The distinction matters. The cat and the bird were drawn for this game, and they have poses. The animals by the road started as emoji, and each has one picture.

A polygon is one record: its fill, which is either one flat color or a gradient, and its points:

{{code Still.Polygon}}

The bird is the smallest set, because the perched bird is Roc's logo, and the logo is made of a few straight-edged shapes. The cat has far more points, because its curves are made of many short straight lines. Its seven stills fit in a 31-line file, and those lines are very long.

Every point is measured in units of the still's height. Its feet are at `y` 0, and a standing critter is about 1 tall. That's why no pixels or metres appear here. The same numbers draw a cat in the distance and a cat in the lane.

`StillShapes` does the rest. An `Anchor` says where a still stands on screen, which way it faces and how tall it is:

{{code StillShapes.Anchor}}

Drawing a still is then one sum for each point. The height in pixels scales the point, and the feet place it:

{{code StillShapes.screen_point}}

That's all there is to drawing a critter. Each stills module names its stills, a posed kind picks one with a `match` on its pose, and `StillShapes.still_shapes` puts it on screen.

### How the stills got made

That's all the Roc in this chapter. If you came for the Roc, you can skip ahead to [The elephant](the-elephant.html). The rest of this chapter is the story of where the pictures came from.

At a larger company, a picture like these would pass through three people. An artist would draw it. A software developer would build the tools that get it into the game. A project manager would look at the result and decide whether it's good enough. On Safari Ride, Claude played the first two roles, and Steve played the third.

The artist's cat was a program. An early version of Safari Ride drew the cat in TypeScript, with splines for its body, tapered capsules for its limbs, chains of joints for its legs, and strokes for its whiskers. That's a lot of code to carry from language to language, and a game only ever shows seven poses.

So the developer wrote a baker, a small program that ran the real drawing code once for each pose. A recorder stood in for the canvas. It kept every filled shape as a polygon and turned every stroke into a thin filled quad, and the result was a flat table of polygons. The drawing code stayed behind, and the table moved on.

The emoji-based animals took a different route. They come from Microsoft's Fluent Emoji, in its Flat style. That set draws every animal whole and from the side, where another set draws a rhino as a face, which looks like a bug beside a road. A second baker read each SVG file, walked its shapes in painting order, and cut each curve into short straight lines.

The bull is a hybrid. It comes from the same emoji set, but in its Color style, which is shaded. It's the only still with gradients, on 40 of its 43 polygons, which is why a polygon's fill can be `Shaded`. Its 2,212 points are nearly half of `EmojiStills`.

The Roc bird came last. Its perched pose is the logo, and Claude drew the five flight poses to match, directly as polygons, in the logo's two purples.

The project manager's tool was a contact sheet: every still, side by side, in one image. Each bake wrote one, and Steve looked at it. No test can say whether a cat looks like a cat. The comment in the emoji baker puts the standard well: "an elephant is an elephant".

The bakers belong to the older versions of Safari Ride, in TypeScript and Zig. The polygons they made have been carried along ever since, which is why these files look like generated data. They are.

Now that we can draw a critter, we can stand one by the road.

## The elephant

The critters in this stretch of the book are billboards: one emoji still, standing in one place, always facing the camera. The code calls them billboards too. We'll start with the elephant. It stands at 14 of the route's 18 bends, so it's the bend animal you'll see most. A grown elephant waits beyond the guard rail on the outside of the bend, and its baby stands 14 metres straight on past the bend, where the road would run if it didn't turn.

New in this chapter:

- Roc: a wrapper only one module can build; a `match` that answers with a list
- Modules: `Billboard`, `BendAnimal`

### Get the types right

A billboard is three facts: its still, its height, and which way it faces.

{{code Billboard.Billboard from "Billboard :: {" to "}.{"}}

Where it stands isn't one of them. That's the `Geom.Placed` around it. A kind of animal is its emoji and how tall a grown one stands, so a baby is the same species at half the height:

{{code Billboard.Species}}

The emoji is a named still, such as `EmojiStills.elephant`, and only `EmojiStills` can make one:

{{code EmojiStills.EmojiStill}}

So a billboard always holds a still that exists.

### Drawing one

An emoji faces left, so a billboard facing right is its still mirrored. A `match` on which way it faces picks the `flip`, and `StillShapes.standing_still_shapes` draws the still standing at the billboard's spot:

{{code Billboard.scenery_picture}}

### Placing one at a bend

A segment's ending carries its `bend_life`, what's at its bend. The segment turns that into billboards:

{{code Segment.segment_bend_billboards}}

What's at the bend gives its own billboards. A quiet bend gives nothing, a pond gives its ducks, and an animal gives two, itself and its baby:

{{code Segment.bend_billboards}}

The animal places itself:

{{code BendAnimal.bend_billboards}}

A `match` on the bend's outer side picks which side of the road the grown animal stands on, and which way it faces. It stands just beyond the rail, a metre and a half past the road's edge plus half its own width.

An elephant has no state. Nothing in that function says "elephant". That's what makes the next chapter short.

## Rhinos, giraffes and the other corner critters

A giraffe, a rhino and a zebra have one bend each. They all use the same code as the elephant, and they differ by one row:

{{code BendAnimal.species_of}}

Each animal is a tag, and each answers with its emoji and how tall it stands. The `match` has to cover all four.

To add a lion, we'd add a tag, a row here and a still in `EmojiStills`. The compiler would point at every `match` that needs the new tag.

These animals stand at the bends. Most of the others come in crowds.

## Herds: cows and pigs

Safari Ride's farms are crowds of animals, and a crowd is just a list of critters. The world stores only each herd's counts or shape. Its segment says where along the road the herd stands, and the herd's own module lays out the animals whenever it's asked.

New in this chapter:

- Roc: nothing new
- Modules: `CowHerd`, `Scatter`

### Cows

A herd of 14 cows grazes on the left of the road, in columns of three. Every fourth cow, from the second, is a calf, at half the height.

{{code CowHerd.herd_cows}}

A herd in a perfect grid would look like a parking lot, so each cow strays a little from its place:

{{code CowHerd.herd_cow}}

The stray comes from the sine and cosine of the cow's number. It looks random, but it's the same on every run, so the frames stay exact.

A bull may stand in front of the herd, by the trees. It's the same record again, a bit taller than a cow:

{{code CowHerd.herd_bull}}

### Pigs

A pig is a species, like the elephant's:

{{code PigHerd.pig_species}}

Pigs graze on the right of the road, near the end of a segment. The first two segments with pigs get a big herd, 7 rows of 7. After that, it's two short rows.

{{code PigHerd.herd_pigs}}

The `match` is on the herd's two shapes. How the rider takes a herd is a separate choice the route makes, `Unnoticed` or `Distracting`, and `Distracting` is one a cow doesn't have. On the first two herds, the standout pig catches the rider's eye, and the rider slows down to look. That's about the rider more than the pig, so it waits for the rider's chapters.

That's every critter that stands still, and the end of what we can say about one frame.

## The ride instant

We've held one frame still for a long time. Now it's time to turn the page. Each time the clock ticks, Safari Ride moves the rider and the truck and draws everything again. `RideInstant` is the one record it keeps from one tick to the next, and it holds the rider, the truck's journey, the clock, and the plan for the encounter on the rider's segment. One tick is a step.

```widget step
Press play to run the ride, and the outer buttons to go to either end.
```

The first three lines under the picture read three of that record's four fields, the clock, the rider and the truck, from a real ride. Press the last button, and the ride plays up to step 2,000, eight steps a frame. Press the first, and it's back at the start almost at once, because the steps it has been through are kept in a list.

New in this chapter:

- Roc: nothing new
- Modules: `RideInstant`, `Tour`, `FrameView`

`RideInstant := { ... }.{ ... }` is a nominal type, from A simple tree: a record with a block of definitions, whose fields stay readable.

{{code RideInstant.RideInstant from "One instant of the ride" to "}.{"}}

### Worked out, not stored

Those four fields are the whole of what Safari Ride keeps from one step to the next. The sun and the beacons keep nothing. The cat and the bird keep one thing between them, the step their animation started on, which is the plan. Each frame works everything else out again from those four. Call this *worked out, not stored*: keep the few things that have to last, and work out the rest. We'll see it everywhere from here on.

That gives three kinds of moving thing, and the rest of the tour is organized around them:

| Kind | Things | How it works |
|---|---|---|
| Clock-driven | The sun, the sky, the beacons, the headlights | Worked out from the clock, with nothing stored |
| Stepped | The rider, the truck | Stored in `RideInstant`, and moved once a step from where it was |
| Rider-driven | The cat, the bird | Worked out from the clock and one stored start step, planned from how the rider is approaching |

Trees and cows are a fourth kind, the easiest of all: they never change.

The game itself has no effectful functions at all. No function's name ends in `!`, and no function's type has the `=>` arrow that marks an effect. Effects live in the platform. A `?` appears in nine places, such as `Pipeline.scenery_sighting_of`, and it isn't an effect: it hands an `Err`, such as `BehindCamera`, straight back to the caller.

### Pausing and stepping

Mostly, Safari Ride is a screensaver: you sit back and watch it. You can also take the controls. Click the ride to give it the keyboard, and Space pauses it. While it's paused, Right moves one step forward and Left moves one step back. While it's running, each moves four steps at a time. J jumps to the next segment of the road, and R starts over.

`SafariApp.model_at_next_step` handles all of that. It takes the model, which is the `Tour` and a pause flag, and a snapshot of the input. It returns the next model:

{{code SafariApp.model_at_next_step from "motion = if input.key_pressed(KeySpace)" to "m.tour.step_forward()"}}

There's no event handler here. Each frame, the platform hands `model_at_next_step` a snapshot, and `model_at_next_step` reads it. `key_pressed` says a key went down since the last frame, so one tap of Space pauses the ride once. `key_down` says a key is being held, so holding Right keeps the ride moving.

Stepping forward is the ordinary step. Stepping back is more interesting, because it's where keeping so little pays off. `Tour` holds the current instant and a list of the instants before it, so going back just means taking the last one off the list:

{{code Tour.step_back}}

Nothing has to be undone. An old `RideInstant` is still a perfectly good value. The cat ends up in the right place because its position was only ever worked out from the rider's, and the sun ends up in the right place because it was only ever worked out from the clock. Neither one needs any code for going backward.

We've seen the things that never change. The beacons are next, because they follow the clock alone.

## The beacons

In Safari Ride, every radio tower has a beacon on top, and the beacons blink. A beacon is the simplest thing in the game that moves. How bright it is depends only on which beacon it is and which step of the ride it is.

```widget beacon
Press play and watch the two towers blink out of step.
```

The widget stands two towers side by side, with beacons that blink opposite each other, and plays two whole blinks, from step 5,400 to step 5,640.

New in this chapter:

- Modules: `Beacon`

### Three rules

A beacon follows three rules:

1. A blink takes 120 steps, from dark up to full brightness and back down.
2. Neighboring towers start their blinks at different points, so the towers along a road don't blink together.
3. A segment longer than a kilometre has a second tower halfway along, and its beacon blinks exactly opposite the one at the segment's end. Only one segment on the route is that long.

None of those rules needs a memory. Ask a beacon about step 5,430 cold, and it can answer. So Safari Ride stores nothing about beacons at all. That's *worked out, not stored*, in its purest form.

### Get the types right

A beacon needs three types, all opaque:

| Type | What it is | Under it |
|---|---|---|
| `Clock` | Which step of the ride it is | A `U32` |
| `Steps` | How many steps something lasts | A `U32` |
| `Beacon` | A beacon at one moment of its blink | A `Fraction`, how bright it is |

`Clock` and `Steps` are the same type of number underneath, so only the types tell them apart. A step of the ride and a length of time are different questions, and neither can stand in for the other.

A `Clock` is the ride's own time. It counts the ride's steps, from 0 at the start to about 7,000 at the end, and it moves on one step each frame. The game draws 30 frames a second, so the clock keeps roughly in step with real time, but it's simulated time: pause the ride and it stops, and step back and it runs backward. This is all the arithmetic a clock does with `Steps`:

{{signatures Clock.steps_since Clock.plus Clock.minus}}

A clock is a place in time, and `Steps` is a distance between two of them. Two clocks give the steps between them, and a clock and some steps give a later clock, or an earlier one. Adding two clocks means nothing, so there's no function for it. Adding two `Steps` does mean something, so `Steps` has a `plus`. This book calls the pattern *places and distances*: one opaque type says where something is, a second says how far apart two of them are, and only the sums that make sense get a function.

A `Beacon` is the light on a tower as the scene draws it: a magenta disc, at a brightness. You ask for one by the index of the tower's segment, whether the tower stands at the segment's end or midway along it, and the step of the ride:

{{signatures Beacon.at}}

A beacon knows how bright it is, and it draws itself. Give it where its middle goes on the screen and how many pixels a metre spans there, and it gives back a magenta disc, as opaque as it is bright, or says it's too dim or too small to draw.

### The functions

The modules behind a beacon
```dot
digraph beacon {
  node [shape=box, fontname="Helvetica"];
  Beacon [style=bold];
  Scene -> TowerSighting [label="  hands it the clock"];
  Scene -> Clock [label="  carries the clock"];
  TowerSighting -> Beacon [label="  asks for each beacon"];
  TowerSighting -> Tower [label="  stands each tower"];
  TowerSighting -> Clock [label="  reads the step"];
  Beacon -> Clock [label="  counts steps since the start"];
  Beacon -> Steps [label="  works out its head start"];
  Beacon -> Fraction [label="  measures its brightness"];
  Beacon -> Route [label="  takes a segment's index"];
  Clock -> Steps [label="  measures time between clocks"];
  Tower -> Beacon [label="  holds it"];
}
```

A box is a module, and an arrow is an import. Each frame, `Scene` hands the clock to `TowerSighting`, which finds the towers in view and asks for each tower's beacon at that frame. The clock goes no further. A tower holds its beacon as it shines that frame and decides where it sits, at the tower's top, and the beacon does the rest. Here's the line where the tower past the end of a segment gets its beacon:

{{code TowerSighting.end_tower from "beacon = Beacon.at" to "beacon = Beacon.at"}}

The segment's index and the tower's place say which beacon, and the clock says how bright it is. The tower halfway along a segment has the same line with `Midway` in place of `AtEnd`.

Now down into `Beacon`:

{{code Beacon.at}}

Inside the module, `Beacon.(...)` builds a beacon from its brightness. No other module can. `clock.steps_since(Clock.start)` is how a place becomes a distance, and it says which distance: the one from the start of the ride. Adding the beacon's head start gives its phase, and a cosine turns that into a brightness:

{{code Beacon.beacon_brightness}}

`wrapped_to` is the only `%` that `Steps` offers, so a phase of 130 is a phase of 10. (The period is written `Beacon.beacon_period`, with its type's name, even here, because it's defined in the type's block.) `(1 - cos) / 2` runs from 0 up to 1 and back to 0 over one period, and it can't leave that range. So `Fraction.of`, which crashes on a ratio outside 0 to 1, is safe here.

A beacon gets its head start from its segment's index and its tower's place:

{{code Beacon.head_start}}

Each segment's beacon starts 37 steps further into its blink than the last one's, so towers along the road don't blink in unison, which would be boring. 37 shares no factor with 120, so the first 120 segments' beacons all start at different points of the blink. Plenty of other numbers would do.

The tower halfway along a segment blinks opposite the one at its end, and opposite means half a blink on. `half_period` is worked out from the period, so it stays right if the period changes.

The widget's two beacons are the first segment's: the one at its end, with no head start, and the midway one, half a blink on. Step 5,400 is 45 whole blinks in, so the first is dark there and the second is at full brightness. A quarter of a blink later, at step 5,430, they're equally bright, and by step 5,460 they've changed places.

Because the beacon draws itself, its tests need no tower. `Beacon`'s own tests check that a beacon blinks, that the midway one blinks the other way, and that its disc comes out the right size and color, or not at all when it's too dim.

There's no blink abstraction, because nothing else in the game blinks. A beacon goes round and round. The sun goes one way, and a lot more hangs on it.

## The setting sun

Safari Ride needs a sunset. We'll build it the way we build everything here: concepts, then types, then functions.

The concept is three jobs:

1. Move the sun down the sky.
2. Darken the sky.
3. Warm the horizon.

All three come from the clock, and the game stores none of them.

### Get the types right

The types do the work, and a sunset needs four:

| Type | What it is | Under it |
|---|---|---|
| `Clock` | A step of the ride | A `U32` |
| `FarHeight` | A height above the horizon of something far off, like the sun, in pixels through the lens at rest | An `F64`, because a shape can sit between two pixels |
| `Fraction` | A ratio from 0 to 1, like how far toward dusk we are | An `F64` |
| `RgbColor` | A color | An `I64`, `0xRRGGBB` |

All four are opaque. Each is still a number, and the type gives it a name, so a height can't be passed where a dusk is wanted. With those in hand, each job is a signature:

| Job | Function | Its type |
|---|---|---|
{{types row SunPath.height_at Move the sun}}
{{types row Sky.darkness_at Darken the sky}}
{{types row Sky.sky_top_color}}
{{types row Sky.horizon_warmth_at Warm the horizon}}
{{types row Sky.sky_horizon_color}}

Every one is a `->`, and every one starts from a `Clock`. That's most of the design, before we've read a line of code.

### The functions

The sunset, from the top
```dot
digraph sunset {
  node [shape=box, fontname="Helvetica"];
  frame [label="each frame"];
  frame -> "Sun.sun_in_view" [label="  places the sun"];
  frame -> "Sky.colors_at" [label="  colors the sky"];
  "Sky.colors_at" -> "Sky.sky_top_color" [label="  colors the top"];
  "Sky.colors_at" -> "Sky.sky_horizon_color" [label="  colors the horizon"];
  "Sky.sky_top_color" -> "Sky.darkness_at" [label="  asks how dark"];
  "Sky.sky_horizon_color" -> "Sky.sky_top_color" [label="  starts from the top"];
  "Sky.sky_horizon_color" -> "Sky.horizon_warmth_at" [label="  asks how warm"];
  "Sun.sun_in_view" -> "SunPath.sun_direction_at" [label="  asks where the sun stands"];
  "Sky.darkness_at" -> "SunPath.height_at" [label="  asks how high"];
  "Sky.horizon_warmth_at" -> "SunPath.height_at" [label="  asks how high"];
  "SunPath.height_at" -> "SunPath.sun_direction_at" [label="  reads the height"];
  "SunPath.sun_direction_at" [style=bold];
  clock [label="the clock"];
  "SunPath.sun_direction_at" -> clock [label="  turns the sky by"];
}
```

A box is a function, and an arrow is a call. Under the frame, `Sun.sun_in_view` does the first job, and `Sky.colors_at` does the other two: the top of the sky and the horizon. They all end at `SunPath.sun_direction_at`, because everything in a sunset comes down to where the sun stands.

Here's the top of that diagram in code. Each frame, the game asks for two things, and they make the backdrop:

{{code FrameView.frame_view_at from "backdrop: {" to "sun_sighting: Sun.sun_in_view"}}

`FrameView` hands the clock straight to `Sun` and `Sky`, so everything from here on is in those two and `SunPath`. Let's take the three jobs in order.

### Job one: the sun goes down

```widget sky sun
Press play. The two middle buttons step one frame at a time, for the patient.
```

This widget does only the first job, so the sky stays blue. For each frame it calls `SunPath.height_at`, reads out the answer, and marks it on the chart's gold line.

The sun chapter showed how `Sun.sun_in_view` places a sun. All it needs from the clock is a height:

{{code SunPath.height_at}}

### Job two: the sky darkens

```widget sky sky
Press play. Now the sky darkens too.
```

This widget adds one call, `Sky.darkness_at`, and the sky finally does something. Its answer is the blue line. The top of the sky blends day into night, by that `Fraction`:

{{code Sky.sky_top_color}}

`darkness_at` works out that `Fraction`:

{{code Sky.darkness_at}}

It asks for the sun's height, then picks one of two shapes. They meet when the sun has fully set, one radius below the horizon, and you can see the join in the blue line. Before that, dusk grows with the square of how far the sun has fallen. After that, it runs on in a straight line to full dark.

{{signatures Sky.darkness_while_up Sky.darkness_after_set}}

As always, anything outside a module's block is private, so these two are helpers without any keyword.

Neither has heard of the clock. The outer functions take a clock, because that's what the frame has to give. The helpers take a height, because that's what dusk depends on, and now that's all it can depend on.

### Job three: the horizon warms

```widget sky warmth
Press play. This is the whole sunset.
```

This widget adds `Sky.horizon_warmth_at`, the red line. This job is polish. A sunset without it is still a sunset, just a sad one.

The horizon is the same sky, warmed toward red:

{{code Sky.sky_horizon_color}}

`horizon_warmth_at` asks for the sun's height, just as dusk did:

{{code Sky.horizon_warmth_at}}

The horizon is warmest when the sun's height is zero. `ratio_to` says how far away the sun is, as a share of 110 pixels, and `abs` makes the two sides match, which gives the red line its tent. `Fraction.clamp` holds that share at one for everything past 110 pixels. The share measures distance, and the horizon gets cooler with distance, so `complement` turns it into warmth: one minus the share. A height of zero gives full warmth, and anything past 110 pixels gives no warmth at all.

### Going backward

Play any of those widgets backward, and the sun rises. No code does that. Every function here takes a clock and answers, so it doesn't matter which way the clock runs.

The sun and the beacons can be asked about any step, cold. Hand `Sky.darkness_at` a clock and it answers. The rider and the truck can't do that.

## Stepping through the ride: RideInstant

Where the rider and the truck are depends on where they were, so their state has to be kept. `RideInstant` keeps four things from one step to the next: the rider, the truck, the clock, and the plan for the encounter on the rider's segment. Two of those, the rider and the truck, move by their own physics. This chapter and the next few are about them.

```widget step
Press the last button, then the first.
```

Going forward, the ride has to be played, because each step starts from the one before. Going back, it only reads a list. The rider and the truck are the reason for that difference.

New in this chapter:

- Roc: nothing new
- Modules: none yet. This chapter shows what calls the modules below, and the next few open them.

The modules that do the stepping
```dot
digraph stepped {
  node [shape=box, fontname="Helvetica"];
  RideInstant [style=bold];
  RideInstant -> Rider [label="  steps the rider"];
  RideInstant -> TruckJourney [label="  steps the truck"];
  Rider -> RiderMind [label="  asks for its controls"];
  Rider -> Motorcycle [label="  moves the bike"];
  Rider -> RiderEyes [label="  moves the eyes"];
  RiderMind -> Throttle [label="  asks for an acceleration"];
  RiderMind -> LeanSearch [label="  asks for a lean"];
  RiderMind -> Gaze [label="  asks where to look"];
  Throttle -> VehicleLimits [label="  keeps to the limits"];
  TruckJourney -> VehicleLimits [label="  keeps to the limits"];
  LeanSearch -> Motorcycle [label="  tries leans on it"];
}
```

Here's the step again, this time whole. Its body is a block: names, then a record, which is the value of the block. The order of those names is a rule of the game. First the rider reads the stage of the encounter on its segment, at the old clock. Then the rider steps, and then the clock ticks. Then the truck and the encounter plan answer the rider who has just moved. The rider never reads the truck.

{{code RideInstant.next}}

`Clock.next`, `Rider.rider_at_next_step` and `TruckJourney.truck_progress_at_next_step` all have the same shape: a value goes in, and the next value comes out. Call that *the step function*. There's no mutable rider being nudged. There's a rider, and another rider one step on.

Stepping has a cost, which shows up when we compare it with the sun:

- We can ask about the sun at any step. To find a truck at step 4,000, we have to play the ride that far, or write the answer down by hand.
- A wrong sky only affects the frames it touches. A wrong step moves the rider for the rest of the ride.
- The lines of `RideInstant.next` have to run in order. Frames can be worked out in any order.

The rider's step is the bigger of the two, and it takes up the next four chapters. The truck gets the chapter after those.

## The rider

The rider is two things: a motorcycle, and a pair of eyes.

| Part | Its parts' fields | Type | What it is |
|---|---|---|---|
| motorcycle | `route_place` | `RoutePlace` | which segment, and its `road_point` on it, along and across |
| | `yaw` | `Angle.Turn` | which way the bike points |
| | `speed` | `Speed` | how far it goes in a step |
| | `lean` | `Angle.Lean` | how far it leans |
| eyes | `gaze_yaw` | `Angle.Turn` | where the rider is looking |
| | `look_depth` | `Fraction` | how deep the last look went |

New in this chapter:

- Roc: a nominal record of nominal records, record update three levels deep, a value for a motorcycle that doesn't exist
- Modules: `Rider`, `Motorcycle`, `RiderEyes`, `RiderMind`, `RiderCamera`

{{code Rider.Rider from "Rider := {" to "}.{"}}

Nothing in the rider is a bare float. Three of the fields under it are angles, of two different types, and passing a `Lean` where a `Turn` is wanted is a compile-time error. The eyes get a chapter of their own.

The step does its work in order, and the code reads that way: decide, move, cross a bend or stop, then choose where to look:

{{code Rider.rider_at_next_step}}

Static dispatch finds `segment_on` on the `RoutePlace`. The `match` on `segment.segment_ending()` has two tags, and `..` in `Bends({ bend, .. })` ignores the rest of its payload.

Every decision the rider makes is `RiderMind`'s. The bike's controls are the lean to take and an acceleration. There's something to notice in the last line here. `Throttle`, which picks the acceleration, is asked about a motorcycle that doesn't exist yet: the motorcycle as it would be at the new lean, which `Motorcycle.with_lean` makes by building a new record. The real one isn't touched, because nothing can touch it.

{{code RiderMind.controls}}

The Rehearsal chapter takes that idea much further. A small version of it decides what happens at the end of a segment. `cross_bend_if_on_road` carries the motorcycle past the bend onto the next segment, and keeps that only if it lands on the road. The rejected motorcycle simply stops being referred to, and nothing has to be undone:

{{code Motorcycle.cross_bend_if_on_road}}

Record update does most of the writing here. Stopping dead updates three levels deep: `..motorcycle` keeps everything but the fields named, `route_place` is itself an update of the old place, and its `road_point` is an update of the old point:

{{code Motorcycle.stopped_at}}

### The picture leans too

When the rider leans, the whole picture leans with it. This is all of that:

{{code RiderCamera.roll_deadband}}

{{code RiderCamera.rider_roll}}

A lean inside the deadband leaves the canvas level, and any other lean passes straight through. It's called once a frame:

{{code RiderCamera.of from "roll: rider_roll" to "roll: rider_roll"}}

The camera turns as well. `Rider.head_yaw` follows the gaze and turns a little with the lean, as a rider's head turns into a bend, and the camera adds it to the motorcycle's yaw.

So a decision is a lean and an acceleration. The motorcycle is what turns them into movement.

## The bike

A lean of 1 degree turns the bike by a tenth of a degree each step, so at a metre a step it goes round a circle 573 metres in radius. That's nearly all the physics.

New in this chapter:

- Roc: nothing new

The modules around `Motorcycle`
```dot
digraph bike {
  node [shape=box, fontname="Helvetica"];
  Motorcycle [style=bold];
  Rider -> Motorcycle [label="  steps it"];
  RiderMind -> Motorcycle [label="  makes its controls"];
  Coast -> Motorcycle [label="  steps a pretend one"];
  LeanSearch -> Motorcycle [label="  tries leans on it"];
  Motorcycle -> RoutePlace [label="  holds its place"];
  Motorcycle -> VehicleLimits [label="  keeps to the top speed"];
  Motorcycle -> Angle [label="  turns by its lean"];
}
```

The motorcycle is four fields: where it is on the route, which way it points, how fast it goes, and how far it leans. Its controls are a lean and an acceleration:

{{code Motorcycle.Motorcycle from "Motorcycle := {" to "}.{"}}

{{code Motorcycle.Controls}}

The step is the whole of the physics, in order:

{{code Motorcycle.motorcycle_at_next_step}}

First the speed: the acceleration is applied, and the result is held to the top speed. Then the turn: a `Lean` changes only by a `LeanChange`, and it reaches direction only through `lean.steer(turn_per_lean)`, the single door from roll to yaw. Then the move: the bike goes along the middle of the step's turn, and `speed.step_length()` is a `Distance`, so the move is places and distances. The new place is a record update of `route_place` with a new `road_point`, inside a new motorcycle.

The bike turns the same amount per step at any speed. That's a cheat, chosen by eye, and it's fine here because the rider chooses each step's lean by trying it out on this same physics.

Two small helpers let the rest of the program pretend:

{{code Motorcycle.with_lean}}

{{code Motorcycle.steady_controls}}

`{ ..motorcycle, lean }` is record update with a shorthand: the field and the local have the same name. Both of these make values for a motorcycle that doesn't exist, and the Rehearsal chapter runs hundreds of them every step.

So the work is split. The throttle chooses an acceleration, and the bike turns it into a speed. Choosing the lean has to wait for the Rehearsal chapter.

## The throttle

The rider is always deciding whether to accelerate, brake or hold steady. `Throttle` makes that decision, once a step.

New in this chapter:

- Modules: `Throttle`, `ThrottleLimit`, `Speed`, `Acceleration`, `VehicleLimits`

The modules around `Throttle`
```dot
digraph throttle {
  node [shape=box, fontname="Helvetica"];
  Throttle [style=bold];
  RiderMind -> Throttle [label="  asks for an acceleration"];
  Throttle -> EncounterReaction [label="  asks about the encounter"];
  Throttle -> Gawking [label="  asks about a pig"];
  Throttle -> Coast [label="  coasts once"];
  Throttle -> ThrottleLimit [label="  folds limits"];
  Throttle -> VehicleLimits [label="  starts from the cruise acceleration"];
  Speed -> Acceleration [label="  makes one"];
}
```

The chain of limits
```dot
digraph limits {
  rankdir=LR;
  node [shape=box, fontname="Helvetica"];
  offered -> bend_limit -> encounter_throttle -> gawk_brake -> shoulder_limit -> acceleration;
}
```

The rider has several reasons to slow down, and they don't know about each other. A bend is coming. A cat is in the lane. There's a pig to look at. Coasting on would carry the bike off the road. `Throttle` writes them as a line of limits. It starts from the cruise acceleration, and each limit lets that through or lowers it:

{{code Throttle.next_acceleration from "limits = [" to "limits.fold(offered, held_to)"}}

Call this *the chain of limits*. Each limit answers the same type and can be read alone, and adding a reason is one more line. It reads like a list of rules because that's what it is.

Each limit is a `ThrottleLimit`: nothing, or at most some acceleration. `held_to` takes the lower:

{{code ThrottleLimit.ThrottleLimit}}

{{code Throttle.held_to}}

The throttle answers an acceleration, and the motorcycle turns it into a speed.

`Speed` and `Acceleration` are places and distances again. A speed is the place, and an acceleration is the change from one speed to another, so an acceleration moves a speed. The `Distance` in `acceleration_to` is a different thing: it's how much road the change has to happen in. The formula behind braking for a bend is the first line of a physics textbook, v² = u² + 2as, solved for a. In the code the speed goes from `s` to `t` within a distance. `target: Speed.(t)` opens the field's `Speed` where it's destructured:

{{code Speed.acceleration_to}}

It has one caller, `VehicleLimits.braking_to`, which also holds the speed steady when the target is within a micrometre, and crashes on a brake that would take the speed below zero. The rider's bend brake, the gawk brake and the truck all brake through it. The first limit is the bend's:

{{code Throttle.bend_limit}}

The last limit, `shoulder_limit`, comes back in the Rehearsal chapter, because it simulates the bike ahead of itself. The two in the middle come from what the rider sees: `encounter_throttle` is the cat's, and `gawk_brake` the pig's. The cat's has its own chapter, so we'll take the pig first.

## The rider's gaze

The herds chapter left one pig waiting. On the first two segments with pigs, one pig in the big herd catches the rider's eye. The rider turns to look and slows down, and the camera turns too.

Those are two different things, and they don't last the same time. The eyes follow the pig, and they give up once it's too far round. The speed drops for the pig, and it stays down until the segment ends. So `Gaze` has two words. A *look* is what the eyes do, and *gawking* is what the speed does. This chapter takes them in that order.

```widget gaze
Press play to ride the stretch around the first distracting pig, seen from above. Each step is one call to `Rider.rider_at_next_step`, and the lines under the picture read the rider's `speed`, `gaze_yaw` and `look_depth`.
```

### Get the types right

The rider's record has two fields we haven't used yet:

| Field | Type | What it is |
|---|---|---|
| `gaze_yaw` | `Angle.Turn` | How far the rider looks from the way the bike points |
| `look_depth` | `Fraction` | How far a look went, from 0 to 1, fading once the gaze is back on the road |

Mind what `gaze_yaw` is measured from. The road has a direction, `yaw` is how far the bike points from the road, and `gaze_yaw` is how far the eyes point from the bike. Each is measured from the one before it, which is what a `Turn` is.

Three small types say what a pig can do to the rider. Each one carries its payload only where it means something. A segment's `pigs` says whether it has a herd, and only a `Herd` has one. Its `interest` is `Distracting` or `Unnoticed`, which says whether the herd catches the rider's eye:

{{code Segment.Pigs}}

The rider looks at a pig or at the road, and only a pig has an angle:

{{code Gaze.GazeTarget}}

A pig asks something of the throttle, or it doesn't, and that's the `ThrottleLimit` from The throttle.

So the job is a short list:

| Job | Function | Its type |
|---|---|---|
{{types row Gaze.desired_gaze Choose where to look}}
{{types row RiderEyes.next_gaze_yaw Turn the head}}
{{types row RiderEyes.next_look_depth Keep the depth of the look}}
{{types row Gawking.is_gawking Know whether the rider is gawking}}
{{types row Gawking.gawk_brake Work out the brake}}

One step of the gaze
```dot
digraph gaze {
  rankdir=LR;
  node [shape=box, fontname="Helvetica"];
  desired_gaze -> next_gaze_yaw [label="  aims"];
  next_gaze_yaw -> next_look_depth [label="  hands its yaw to"];
  next_gaze_yaw -> camera [label="  turns"];
  next_look_depth -> "width of the view" [label="  widens"];
  gawk_brake -> speed [label="  lowers"];
}
```

The chain from `desired_gaze` is the look, and `gawk_brake` is the gawking. Nothing joins them. Both ask about the same pig, and neither asks about the other.

### The look

`Rider.rider_at_next_step` moves the eyes last, after the bike has moved:

{{code RiderEyes.eyes_at_next_step}}

Choosing where to look comes first. The rider asks `RiderMind.gaze_target`, since every decision is `RiderMind`'s, and it hands the question to the gaze's own rule:

{{code Gaze.desired_gaze}}

The pig has to be near, and it has to be in sight. Near means within 150 metres, measured along the road. In sight is an angle:

{{code Gaze.turn_to}}

That's the direction to the pig, less the way the bike points. The pig stands beside the road, so the angle grows as the rider comes closer. At 35 degrees the rider lets it go. There's no timer and no flag saying the look is over. The first pig stands about 11 metres from the middle of the road, so it reaches 35 degrees about 16 metres ahead.

### Turning the head

{{code RiderEyes.next_gaze_yaw}}

Toward a pig, the gaze turns by at most 4 degrees a step, and `clamped_within` holds the change to that limit on either side. On the way back the same clamp holds it to 0.2 degrees a step.

A gaze within 0.2 degrees of straight ahead goes all the way there, so the last step of the return lands exactly home, and the return ends.

Nothing here turns the bike. The gaze goes to the camera, and to nothing else that moves:

{{code Rider.head_yaw}}

The second term is the rider's head going with the lean. So when the rider looks right, the road slides left on the page, and the bike keeps going where it was going.

### The depth of a look

{{code RiderEyes.next_look_depth}}

While the gaze is off straight ahead, the depth rises with how far it has turned, and it doesn't drop. Once the gaze is home, the depth fades by 0.0012 a step, so a full look takes more than 800 steps to fade.

The depth has one job. It widens the view:

{{code RiderEyes.attention}}

`RiderCamera.ride_focal_length`, which sets how wide the view is, asks `Rider.attention`, which takes the stronger of this and what a crossing on the road asks for, which we'll meet with the cat. So a pig widens the view, and the view stays wide for a while after.

### Gawking

Whether the rider is gawking is a plainer question than whether it's looking:

{{code Gawking.is_gawking}}

It starts at the same 150 metres, but it only asks where the rider is. There's no angle in it, so it outlasts the look.

`gawk_brake` is the third link in the throttle's chain. It gives a brake while the rider has noticed a pig, and `held_to` takes it if that's harder than what it was offered:

{{code Throttle.next_acceleration from "Gawking.gawk_brake(motorcycle, segment)," to "Gawking.gawk_brake(motorcycle, segment),"}}

{{code Gawking.gawk_brake}}

The formula is the one the throttle uses for a bend, with a pig for a bend. The rider aims to be down to 0.2 metres a step by 25 metres before the pig. Past that point `room` would go below zero, so `gawk_least_distance` holds it at a metre and the brake stays on.

### The first pig

Here's all of that on the third segment of the route:

| Step | What happens | Speed | `gaze_yaw` | `look_depth` |
|---|---|---|---|---|
| 885 | The rider looks, with the pig just inside 150 metres | 1.94 metres a step | 4.0 degrees | 0.114 |
| 1,049 | The gaze is at its widest | 0.2 metres a step | 34.95 degrees | 0.999 |
| 1,050 | The rider lets the pig go | 0.2 metres a step | 34.75 degrees | 0.999 |
| 1,224 | The gaze is back on the road | 0.2 metres a step | 0 degrees | 0.997 |

The look takes 165 steps, and getting the eyes back takes 174. The rider crawls for 173 steps more with nothing to look at, and reaches the next segment at step 1,397. The gaze is home at every one of the ride's 18 seams between segments, and an expect holds that. A seam needs no reset anyway: the bike doesn't turn at a seam, and `gaze_yaw` is measured from the bike.

That's the pig's part of the rider's step. The truck is the other stepped thing.

## The truck

All through the ride, the rider follows a truck up the road. How the truck moves comes in the next chapter, and its lights in the one after. This chapter draws it: a plain truck, standing at a place on the road that's already known, and facing along the road.

```widget truck
A truck from behind, from behind and to one side, and from the side.
```

New in this chapter:

- Modules: `TruckSighting`, `TruckShape`, `TruckBody`

The modules that draw the truck
```dot
digraph truck_drawing {
  node [shape=box, fontname="Helvetica"];
  TruckBody [style=bold];
  Scene -> TruckSighting [label="  finds it with truck_in_view"];
  TruckSighting -> Truck [label="  sights a Truck"];
  Truck -> TruckBody [label="  draws its body with body_picture"];
  TruckBody -> TruckShape [label="  places each corner with road_point_on_truck"];
  TruckBody -> EarthCurve [label="  lowers it with raised_ground_point"];
}
```

`TruckSighting` finds the truck on the road ahead. What it finds is a `Truck`, the truck with its lights, and with the lights off that's just the body this chapter draws. The truck is drawn however small it stands, because the rider is always looking for it.

### Shape, placement, projection

The truck is a real box, with a back, two sides, a roof, a windshield and a nose. It gets to the screen in three stages:

| Stage | What it does |
|---|---|
| Shape | Says where each corner is in the truck's own frame, measured from the middle of the trailer |
| Placement | Carries one point onto the road at the truck's spot, then lowers it for the earth's curve |
| Projection | Turns one whole face into a polygon on the screen |

Placement works a point at a time, because each corner stands at its own place on the road. Projection works a face at a time, for two reasons. A face that reaches behind the camera is clipped, and clipping can cut corners off a face and add new ones, so it needs the whole outline. And the faces are sorted by depth before they're drawn, and the sort orders faces, not points.

### Get the types right

A point in the truck's own frame is three distances, measured from the middle of the trailer:

{{code TruckShape.TruckPoint}}

A `TruckSetting` is what the truck is drawn from. It's a `Picture.Setting`, the setting every kind of thing beside the road draws from:

{{code Picture.Setting}}

{{code TruckShape.TruckSetting}}

The truck's context is the road its points are measured on, and the camera's vantage:

{{code TruckShape.TruckOnRoad}}

### The functions

Placement is two functions. `TruckShape` moves one point along and across the road from the truck's spot, and lifts it:

{{code TruckShape.road_point_on_truck}}

`EarthCurve` finds where that lands in the rider's view, and lowers it by however far the ground has curved away beneath it. The headlights and the brake lights use it too:

{{code EarthCurve.raised_ground_point}}

`TruckBody.face` places each corner of a face that way. So a face is just a color and a list of `TruckPoint`s. Here's a side, walked around its outline from the back of the trailer to the nose and back:

{{code TruckBody.side}}

The back, the roof, the windshield and the nose are each a strip across the truck, so they share `TruckShape.strip_corners`. The tires are circles standing on the road.

Projection comes last. `TruckBody` sorts the faces far to near, so a nearer face drawn later covers a farther one, and then clips and projects each one:

{{code TruckBody.body_picture}}

That's a truck. Next, it moves.

## The truck's motion

The truck is what the rider chases. It starts 500 metres up the road, and for most of the ride the rider closes in on it, but not steadily:

| Step | Rider, along the route | Truck, along the route | Lead |
|---|---|---|---|
| 0 | 0 metres | 500 metres | 500 metres |
| 2,000 | 1,831 metres | 2,274 metres | 443 metres |
| 4,000 | 4,796 metres | 5,051 metres | 255 metres |
| 6,000 | 6,790 metres | 6,931 metres | 141 metres |

The closest the rider gets is 50 metres, at step 6,374. After that the rider slows to stop at the route's end, at step 6,746. The truck doesn't wait. It drives on past the end of the route and vanishes, since nothing is drawn beyond the end. You never catch it. Some riders have complained about the darn truck, and that's the design. At least for now haha.

New in this chapter:

- Modules: `TruckJourney`

### A tease, carried out by physics

The truck's driver is teasing the rider: staying ahead, but letting the rider gain. That's the hand of god, a rule that bends the world on purpose, for the story. Here it's one function, `tease_position`. Given how far the rider has come, it says where the truck would like to be. The lead it aims for shrinks from 500 metres at the start of the route to 100 at the end.

Everything else is plain physics. The truck speeds up while it's short of that mark and holds its speed once it's past it. It slows for the bends, and that's mostly where the rider gains. The tease only ever speeds the truck up, so near the end the rider can get closer than the 100 metres it aims for. The truck can always pull away again, because it outdoes the rider by 10%, in both its acceleration and its top speed.

### Remembered, not worked out

The sun is worked out from the clock. `sun_direction_at` takes a clock, so you can ask about any step and get an answer, without running the ride up to it.

The truck can't be worked out that way, because where it is depends on where the rider has been. So the truck is carried forward. Its step, `truck_progress_at_next_step`, takes a `TruckProgress` and returns the next one. The ride remembers four things from one step to the next, the rider, the truck, the clock and the encounter plan, and the truck is one of them.

That's what makes the order of a step matter. The rider moves first, and then the truck reads where the rider has got to. The rider never reads the truck.

### Get the types right

The truck's state is three fields:

{{code TruckJourney.TruckProgress from "How far along" to "pace : TruckJourney.Pace,"}}

`route_position` is a `Distance` along the whole route, the same measure as the rider's progress, so the two can be compared directly. `Pace` says whether the truck's last step slowed it down:

{{code TruckJourney.Pace}}

A bend ahead of the truck is its own type, and so is the answer to "is there one":

{{code TruckJourney.ComingBend}}

{{code TruckJourney.NextBend}}

`BendAhead` carries a `ComingBend`: how far off the bend is, and its turn, an angle. `NoBendAhead` carries nothing: the route ends before another bend, or the truck is already past the end. The only way to read a bend's distance is inside the branch where there is a bend.

### The functions

The modules around `TruckJourney`
```dot
digraph truck_motion {
  node [shape=box, fontname="Helvetica"];
  TruckJourney [style=bold];
  RideInstant -> TruckJourney [label="  steps it"];
  TruckJourney -> Route [label="  finds the next bend on"];
  TruckJourney -> VehicleLimits [label="  keeps to the limits"];
  TruckJourney -> Speed [label="  measures how fast it goes in"];
  TruckJourney -> Acceleration [label="  measures speeding up in"];
}
```

`RideInstant` moves the truck once a step. All it hands over is how far along the route the rider has just got to, and the route itself:

{{code RideInstant.next from "truck = TruckJourney.truck_progress_at_next_step(" to "{ rider_distance: rider_place.distance_along(route), route },"}}

That record is the whole of the chase. `TruckJourney` imports none of the rider's modules, and the rider's modules don't import `TruckJourney`. What the two share is `VehicleLimits`, the limits both keep to, which is where the truck's 10% comes from.

The step works out the tease, then looks for the next bend:

{{code TruckJourney.truck_progress_at_next_step}}

Here's the tease itself. The lead shrinks in step with the rider's progress along the route:

{{code TruckJourney.tease_position}}

Finding the next bend walks the route's segments with their ends, and takes the first one that ends past the truck:

{{code TruckJourney.next_bend}}

Read its signature out loud: `next_bend : Route, Distance -> NextBend`. The next bend, on a route, past a distance. That's what a signature should do: say what the function is for, before you read its body.

Then the two ways to take a step. Both sit below the module's block, so they're private, and both are arithmetic on `Speed`. Within 60 metres of a bend, the truck brakes so it reaches the bend at its cautious speed. `VehicleLimits.turn_speed` is the speed a turn allows, and the rider's throttle asks it too. The truck's own rule is that limit times its caution, 80%, to leave a margin:

{{code TruckJourney.cautious_turn_speed}}

{{code TruckJourney.progress_braking_for}}

`VehicleLimits.braking_to` works out one steady brake that reaches the target speed at the bend. A steady brake can land a little under the target, so `target_speed.max(...)` holds the truck there. A brake that would take the speed below zero is a bug, and `braking_to` crashes on one. Otherwise, the truck chases:

{{code TruckJourney.progress_toward_tease}}

That's a truck you can chase. The next chapter lights it.

## The truck's lights

The ride runs from day into night, so the truck's headlights come on near the end. The truck brakes for bends, so its brake lights show whenever you're close to it, even by day. The truck drives exactly the same with its lights on or off.

New in this chapter:

- Modules: `Truck`, `TruckHeadlights`, `TruckBrakeLights`

### One module per lamp

Each kind of lamp gets a module, and each module owns two things: whether its lamp is on, and how the lamp looks.

The headlights work like a light sensor on the lamps themselves: once the sky is dark enough, they're on. The Sky module tells us how dark it is: `Sky.darkness_at` answers a `Fraction`, 0 by day and 1 at full dark. The sensor reads that.

The brake lights come on while the truck is slowing down. That's a fact about the truck's own last step, its `Pace`, so they follow the truck.

### Get the types right

`TruckHeadlights` and `TruckBrakeLights` are each `[On, Off]`. A `Truck` is the truck as the scene draws it this frame, so it holds one field per lamp:

{{code Truck.Truck from "Which of" to "Truck := {"}}

### The functions

Each frame, `FrameView` builds the `Truck`. It hands the sky's darkness to `TruckHeadlights` and the truck's pace to `TruckBrakeLights`:

{{code FrameView.ride_facts from "headlights: TruckHeadlights.at(" to "brake_lights: TruckBrakeLights.at("}}

Each lamp's module applies its own rule:

{{code TruckHeadlights.at}}

{{code TruckBrakeLights.at}}

The headlights come on at this darkness:

{{code TruckHeadlights.headlights_on_darkness}}

On this ride, that's step 3,555 of 6,746. Once on, they stay on, because from there the sky only darkens.

Each lamp's `picture` matches both tags, and an `Off` lamp is an empty picture. `TruckHeadlights` paints the beams as wedges that fade from the lamp toward their far end. `TruckBrakeLights` paints two lamps on the back of the trailer, each with a glow around it. Both place their points the way the body does, with `TruckShape.road_point_on_truck` and `EarthCurve.raised_ground_point`.

`Truck` puts the three pictures together. `Picture.composite` makes one picture of several, each painted over the ones before:

{{code Picture.composite}}

The beams go first, then the body, then the brake lights:

{{code Truck.scenery_picture}}

`TruckBody` knows nothing of the lights: they're drawn around it.

Step the ride back past step 3,555, and the headlights go off again. Nothing turns them off; they only ever read the sky. The brake lights read the truck's last step, which the ride keeps, so they come back with it.

## The cat

A cat walks out into the lane, freezes as the rider bears down on it, and leaps clear at the last possible moment. It's one of the most elaborate effects in Safari Ride, and it's where the rider and the world start to push on each other.

```widget cat
Press play and watch the crossing.
```

Play it, and the gap falls from 50 metres to 0, with the rider held at a metre a step. The cat waits on the right verge until 41 metres, where the last line changes to "The rider may not accelerate". It walks out, and at 31 metres it freezes in the lane. It stays frozen until 7 metres, where it coils, leaps at 6 and lands at 4. At 3 metres it has collapsed on the far verge, and the rider may accelerate again. Below that, nothing changes.

New in this chapter:

- Roc: a list of frames as data; a `crash` that the data rules out
- Modules: `CatCrossing`, `Cat`, `Animation`, `EncounterPlan`, `EncounterPoses`, `EncounterSighting`

### Two halves, and one fact remembered

A crossing comes in two halves. `CatCrossing` is what the cat does: where it crosses, and what it does at each step of its crossing. `Cat` is how it looks this frame, which is just its pose. The poses are `CatCrossing`'s, because the crossing is what changes them:

{{code Cat.Cat from "Cat := {" to "}.{"}}

The animation itself is a list of frames, played one a step on the ride's clock. All the ride has to remember is the step it started on. That's an `EncounterPlan`:

{{code EncounterPlan.EncounterPlan from "When the encounter" to "].{"}}

Everything else about the cat is worked out from that one step and the clock.

The modules around `CatCrossing`
```dot
digraph cat {
  node [shape=box, fontname="Helvetica"];
  CatCrossing [style=bold];
  World -> Segment [label="  marks some segments CatCrosses"];
  Segment -> CatCrossing [label="  builds and holds it"];
  RideInstant -> EncounterPlan [label="  keeps the plan"];
  EncounterReaction -> CatCrossing [label="  reacts to it"];
  EncounterSighting -> EncounterPoses [label="  asks where it stands"];
  EncounterPoses -> CatCrossing [label="  asks for its instant"];
  Cat -> CatCrossing [label="  takes its poses from"];
  CatCrossing -> Animation [label="  plays its frames"];
  CatCrossing -> EncounterPlan [label="  is planned by its span"];
  EncounterPlan -> Animation [label="  answers a Stage"];
  Cat -> CatStills [label="  draws a still"];
}
```

### When it plays

The ride plans the crossing once, when the rider first comes within reach, from how fast the rider is coming then. The aim is for the cat to be across just as the rider arrives 3 metres short of it. A faster rider covers more road while the crossing plays, so the plan is made farther off:

| Rider's speed | The crossing starts at a gap of |
|---|---|
| 1 metre a step | 41 metres |
| 1.5 metres a step | 60 metres |
| 2 metres a step | 79 metres |

What the ride plans by is a span: how many steps the animation takes, and the gap it ends at.

{{code EncounterPlan.StepSpan}}

The cat's span is its 38 frames, ending 3 metres short:

{{code CatCrossing.crossing_span}}

The plan is made on the first step where a rider keeping their speed would arrive within the span. Until then, and while the rider is at rest, nothing is planned:

{{code EncounterPlan.plan_for}}

After that one look, the cat doesn't care what the rider does. If the rider brakes, the cat still crosses on time, and the rider simply arrives a little later.

Once a plan exists, the ride's clock says where the animation has got to. That's a `Stage`:

{{code Animation.Stage}}

`Waiting` before it starts, `Playing` while it runs, counting steps in, and `Past` after it ends, counting steps since. The tags carry only what each case needs, so there's no step count to misread while the cat is waiting.

A plan and the clock together make a `Timing`:

{{code EncounterPlan.Timing}}

{{code EncounterPlan.timing_at}}

and a `Timing` and a length make the `Stage`:

{{code EncounterPlan.stage_at}}

### Who moves first

Each step, the world and the rider change each other, and the order matters. The rider reacts to the cat as it stood at the start of the step: if the crossing is playing, the throttle holds. Then, with the rider moved, the ride looks again. If the rider has just come within reach, the plan is made now, at the new clock. And at each new segment the plan is forgotten, because only the encounter on the rider's own segment is ever live.

So within one step, the rider answers the world, and then the world answers the rider. The cat never sees the rider again once it's planned, but the rider sees the cat every step.

### What it looks like

The whole crossing is a list of frames, one a step:

| Frames | Frame numbers | What the cat does |
|---|---|---|
| walking out | 1 to 10 | strides and rests, from behind its tree most of the way to the middle of the road |
| frozen | 11 to 34 | stands in the lane |
| the leap | 35 to 38 | coils, flies twice, lands on the far verge |

That counts frames from 1, as the widget does; in the code, a `Playing` stage counts the steps in from 0.

After the last frame it lies collapsed on the far verge. Each frame is a pose and where the cat is on its way across:

{{code CatCrossing.CrossingFrame}}

{{code CatCrossing.CrossingWay}}

The leap is four keyframes, set by eye:

{{code CatCrossing.leap_frames}}

`crossing_timeline` puts the frames on the road. A closure, `location_of`, turns each frame's way across into a place by this crossing's tree:

{{code CatCrossing.crossing_timeline}}

The span and the timeline both come from the one list, `crossing_frames`, so the animation's length and its frames can't disagree.

### How a timeline plays

Asking for the cat at a stage is one function:

{{code CatCrossing.cat_instant_at}}

The timeline answers with a `match` on the stage and a lookup in the list:

{{code Animation.Timeline from "instant : Animation.Timeline" to "Past(_) => timeline.after"}}

A `Playing` stage past the end of the frames would be a bug, and the timeline crashes rather than guess. It can't happen here, because the length the ride plans by is the length of the list.

### Getting it on screen

Seeing the cat takes two steps, and the camera is only in the second. First, `EncounterPoses` works out where each cat in view stands this frame, with no camera at all. Only the rider's own segment plays its crossing; a cat on a segment ahead is still waiting behind its tree:

{{code EncounterPoses.cat_poses}}

Then `EncounterSighting` asks where the camera sees each one. Through `Pipeline.scenery_sighting_of`, it drops any behind the camera or too small to draw:

{{code EncounterSighting.cats_in_view}}

From there, a cat is a kind like a tree or a cow, and it joins the frame's depth sort.

The ride remembers one step for the cat, and works out everything else, frame by frame, from it and the clock. What the cat asks of the rider while it crosses, the held throttle and the eye, is the rider's side of the story, and it comes later.

## The bird

The bird is Roc's logo, sitting on a treetop. As the rider comes near it takes off, flies across the road and ahead, and drops onto a tree on the far side. It moves the way the cat does, through the same plan and the same kind of timeline, and it cost much less.

```widget bird
Press play and watch the bird fly.
```

The picture is a fixed eye, 18 metres short of the first tree; the gap only drives the clock. Play it, and the gap falls from 75 metres to 0, with the rider held at 1.25 metres a step. The bird sits on the tip of the left tree, 6.4 metres up, until 60 metres. It takes off side on, turns away at about 55 metres, and reaches 10.7 metres near the middle of its flight, shrinking as it goes. It dives from 20 metres, and at 15 it's perched on the tip of the far tree, 4.9 metres up. Below that, the picture stays as it is.

New in this chapter:

- Roc: tags inside tags, opening a `Try` by hand, `match` as an expression
- Modules: `BirdFlight`, `Bird`

### Two halves

A bird comes in the same two halves as a cat. `BirdFlight` is what it does: the tree it leaves and the tree it flies to. `Bird` is how it looks this frame, which is its pose:

{{code Bird.Bird from "Bird := {" to "}.{"}}

A pose can carry a tag of its own. A bird side on or seen from behind has its wings up or down, so those tags carry a `WingBeat`. As with the cat, the poses are the flight's:

{{code BirdFlight.BirdPose}}

The modules around `BirdFlight`
```dot
digraph bird {
  node [shape=box, fontname="Helvetica"];
  BirdFlight [style=bold];
  World -> Segment [label="  marks some segments BirdHere"];
  Segment -> BirdFlight [label="  builds and holds it"];
  Scene -> EncounterSighting [label="  asks for the birds in view"];
  RideInstant -> EncounterPlan [label="  keeps the plan"];
  EncounterSighting -> EncounterPoses [label="  asks where it stands"];
  EncounterPoses -> BirdFlight [label="  asks for its instant"];
  Bird -> BirdFlight [label="  takes its poses from"];
  BirdFlight -> Animation [label="  plays its frames"];
  BirdFlight -> EncounterPlan [label="  is planned by its span"];
  Bird -> BirdStills [label="  draws a still"];
}
```

### When it plays

The ride plans the flight the way it plans a cat's crossing: once, when the rider first comes within reach, from how fast the rider is coming. A flight is 36 frames, and it's planned to end as a rider keeping their speed comes within 15 metres of the tree the bird left, so the rider sees it land before passing that tree:

{{code BirdFlight.flight_span}}

So a faster rider sets the bird off sooner:

| Rider's speed | The flight starts at a gap of |
|---|---|
| 1 metre a step | 51 metres |
| 1.25 metres a step | 60 metres |
| 2 metres a step | 87 metres |

The widget's rider comes at 1.25 metres a step, so the bird takes off at 60. Once it's planned, the flight plays on the ride's clock, a frame a step, whatever the rider does. Its stage is worked out exactly as the cat's is, from the plan's timing and the flight's own length:

{{code BirdFlight.flight_stage}}

### What it looks like

A flight is a list of poses, one a step: a flap side on as it takes off, seven flaps seen from behind, then a flap's length of diving.

| Frames | What the bird does |
|---|---|
| 1 to 4 | one flap, side on |
| 5 to 32 | seven flaps, seen from behind |
| 33 to 36 | dives |

That counts frames from 1, as the widget does. Before the first frame the bird sits on the tree it leaves, and after the last it sits on the tree it flew to.

`flight_timeline` puts the poses on a path:

{{code BirdFlight.flight_timeline}}

The path eases along the straight line between the two treetops, and rises above it in an arc 5 metres high at the middle:

{{code BirdFlight.flight_location}}

`4t(1 − t)` is 0 at both ends and 1 halfway, so the arc starts and ends on the line. The last line is a record update: everything about the point on the line, with its lift raised.

### Finding a tree

A segment's bird is chosen when the world is built. The segment picks the perch, the fifth tree on the left:

{{code Segment.fifth_left_tree}}

Then the bird picks where to fly: the first tree on the far side of the road at least 25 metres farther along.

{{code BirdFlight.flight_from}}

`find_first` answers a `Try`, and the `match` opens it by hand, turning "not found" into the bird's own error, `NoTreeToFlyTo`. The bird always starts on the left because its perched and side-on stills face right and are never mirrored, so on a left tree it faces the road.

The segment puts the two together. A route that plans a bird on a segment with no tree for it is a bug, so each failure crashes with its own reason:

{{code Segment.from_choices from "BirdHere =>" to "QuietRoad => QuietRoad"}}

`match` is an expression here. Its answer is the value of the `encounter` field.

### Getting it on screen

The bird reaches the screen the way the cat does: `EncounterPoses` places it with no camera, and `EncounterSighting` asks where the camera sees it. Only the rider's own segment plays its flight. A bird on a segment ahead is still perched on its first tree.

`Bird` draws it from its still, at its height:

{{code Bird.scenery_picture}}

A perched bird stands exactly where its tree's top is, at the same depth, and the scene puts trees before birds when depths tie, so the bird is drawn over its tree.

The bird asks nothing of the rider, so the rider's reactions pass it by. All it adds to the game is a list of poses, a path, and the stills to draw them.

## What a cat does to the rider

A crossing cat asks two things of the rider: hold the throttle, and look. Both are the rider's own reactions, and they live on the rider's side, in one module that knows which encounters ask anything of the rider at all.

New in this chapter:

- Roc: a `match` inside a `match`
- Modules: `EncounterReaction`, `Attention`

The modules around `EncounterReaction`
```dot
digraph reaction {
  node [shape=box, fontname="Helvetica"];
  EncounterReaction [style=bold];
  Throttle -> EncounterReaction [label="  asks for a throttle limit"];
  Rider -> EncounterReaction [label="  asks how hard it's held"];
  RiderCamera -> Rider [label="  reads its attention"];
  EncounterReaction -> Segment [label="  reads its encounter"];
  EncounterReaction -> CatCrossing [label="  reads its peak and span"];
  EncounterReaction -> ThrottleLimit [label="  answers one"];
  EncounterReaction -> Attention [label="  answers one"];
}
```

### When the rider feels it

The order inside a step matters here. The rider reacts to the cat as it stood at the start of the step, then moves. Only after the move does the ride make its plan, if the rider has just come within reach. So on the step the crossing is planned, the rider hasn't felt it yet; the hold starts on the next step. The camera, drawing the frame, reads the cat as it stands now.

Once planned, the cat never reads the rider again. The rider's speed sets the cat off once, and from then on the effect runs one way: the cat keeps the rider from speeding up, and nothing the rider does moves the cat.

### Hold the throttle

A limit on the throttle is a `ThrottleLimit`, from The throttle: either nothing, or at most some acceleration.

While a cat crosses, the rider may not speed up. That's `AtMost(Acceleration.steady)`, which caps the acceleration at zero without braking:

{{code EncounterReaction.encounter_throttle}}

The outer `match` asks what's on the segment, and the inner one asks where the crossing has got to. `Waiting | Past(_)` is one branch for two tags, and `_` ignores a payload. A bird and a quiet road both answer `NoLimit`.

The cat's limit is one of four that the throttle folds together, with the bends, the gawking and the road's shoulder, starting from the cruise acceleration and held to the lowest. Holding at steady also keeps the rider from going faster than the plan assumed, so the cat is across before the rider arrives.

### Look

How hard something holds the rider's eye is an `Attention`. A full look to the side is 1, and a crossing cat holds the eye harder than that, so underneath it's an `F64`, not a `Fraction`:

{{code Attention.Attention from "Attention :: F64.{" to "Attention :: F64.{"}}

The encounter on the rider's segment answers one:

{{code EncounterReaction.encounter_attention}}

The cat's pull rises as it crosses, up to its peak of 1.8, then fades over 83 steps once it's across, about 80 metres past the cat at a metre a step:

{{code EncounterReaction.cat_attention}}

`Playing` and `Past` both carry a step count, and this is where both are used: one says how far into the crossing, the other how long since it ended.

The rider takes the stronger of the cat's pull and what's left of the rider's last look, its depth, which lingers after the eyes come home. The camera widens its view to at least match, or wider if the rider is leaning harder. That's how a crossing cat seems to fill more of the picture.

Each segment has one encounter at most: a cat, a bird, or a quiet road. A cat asks for both, a bird for neither, and the rider's reactions to everything else, the bends and the pigs, live in the rider's own chapters.

## Rehearsal

The rider has no steering wheel. Nothing tells it where to go. Each step, it has to choose a lean, and it does that by working out what would happen. Call this *rehearsal*: run the real rules on a pretend copy, read the result, and throw it away.

Safari Ride's rider steers by rehearsing. Each step it tries twelve leans, each narrowing its bounds, and then takes the lean halfway between the bounds the twelfth try left.

```widget rehearsal
Click a mark to see that try at a lean.
```

Each try lets a motorcycle that doesn't exist coast down the road with one lean, and the white arc is where it goes. The yellow line is the road's middle, where the search wants each coast to end. A try that ends left of it sends the next try further right, and one that ends right of it sends the next further left, and by the twelfth they've closed in. This is step 374 of the ride, just after a bend.

New in this chapter:

- Roc: a `while` that stops early, with `return`; `for` over a range
- Modules: `Coast`, `LeanSearch`

The calls of one rehearsal
```dot
digraph rehearsal {
  rankdir=LR;
  node [shape=box, fontname="Helvetica"];
  controls [label="RiderMind.controls"];
  best [label="LeanSearch.best_lean"];
  search [label="LeanSearch.search_tries"];
  project [label="Coast.coast_outcome"];
  keeping [label="Coast.coast_keeping"];
  advance [label="Motorcycle.motorcycle_at_next_step"];
  throttle [label="Throttle.next_acceleration"];
  controls -> best [label="  asks for a lean"];
  best -> search [label="  runs 12 tries"];
  search -> project [label="  coasts each try"];
  controls -> throttle [label="  asks about that lean"];
  throttle -> project [label="  the 13th coast"];
  project -> keeping [label="  drops the path"];
  keeping -> advance [label="  a step at a time"];
}
```

`Coast` answers one question. If the rider stopped changing anything now, and coasted, what would happen? It takes the motorcycle alone, never the eyes, and runs the physics. The step is the same `Motorcycle.motorcycle_at_next_step` that moves the real rider, handed `steady_controls()`: the current lean, and no acceleration. The step is a function, so a pretend motorcycle can be stepped as easily as the real one.

{{code Coast.coast_outcome}}

`coast_outcome` is a coast that drops the path it took. The loop itself is in `coast_keeping`:

{{code Coast.coast_keeping}}

The coast's bounds are the road's edges, 5 centimetres in, or wherever it starts if that's further out. The `while` moves the motorcycle a step at a time until it crosses one of those bounds, gets 25 metres further along its segment, or runs for 2,000 steps, and `return` leaves the function from inside the loop. The answer says where the coast went:

{{code Coast.Outcome}}

`LeanSearch` asks `Coast` that question at a dozen different leans. The rider wants the coast to end near the middle of the road, and more lean to the right moves the end of a coast to the right, so this is a bisection. It's a `for` loop, with `$bounds.low` and `$bounds.high` closing in on each other. `motorcycle.with_lean(mid)` is a motorcycle that doesn't exist, handed to `Coast`, which gives it a future that didn't happen:

{{code LeanSearch.search_tries from "mid = middle_lean($bounds)" to "$bounds = bounds_after(lean_try)"}}

The search starts with bounds a degree either side of the current lean, `max_lean_change`, so the lean it picks is never more than a degree from the last. That's what stops the bike flicking from one lean to another. Which way each try sends the next is a `match` on what the rehearsal found. Running off the left means more right, running off the right means less, and staying on the road compares the end of the coast with the target:

{{code LeanSearch.lean_correction}}

After the last try, the lean it keeps is the midpoint of the bounds that try narrowed to:

{{code LeanSearch.best_lean}}

`RiderMind.controls` calls that on its first line, and on its second asks the throttle about the motorcycle at that lean. That's where the rehearsals start: `RiderMind.controls` is the top of the calls in the picture above.

Each real step of the ride runs thirteen coasts that never happen: twelve for the lean, and one more in `Throttle`, which uses `Coast` to ask whether the road is about to run out.

In a language with mutable objects, a rehearsal has a problem to solve before it starts. It needs to copy the rider, or save it and restore it, and it needs to be sure the copy really is one, all the way down. It needs to know that the physics doesn't quietly update something global, like a scoreboard or a random number generator. In Roc, none of that comes up. `Motorcycle.motorcycle_at_next_step` has a `->`, so it can't reach anything but its arguments. The old motorcycle stays intact because every value does. A rehearsal that goes wrong costs nothing, and `LeanSearch` is about 100 lines above its tests.

The last limit of the throttle is the same idea with one rehearsal in it. It runs the coast, and brakes only if the coast leaves the road:

{{code Throttle.shoulder_limit}}

That's the last of the rider.

## The math layer

All this time, a layer of math has been doing the measuring. This chapter works up from the floor.

New in this chapter:

- Roc: records as coordinate systems, `fold` and `map2`, a record type with a type variable for a region
- Modules: `Lens`, `Geom`, `RoadAhead` and `Camera` up close

A lot of Safari Ride is math and physics, and most of it is geometry a reader could do on paper. It's here because this kind of code suits a compiled functional language unusually well, for a short list of reasons:

- A formula is an expression, and a function with no effects is the same thing with a name.
- Units can be types, and a type that only wraps a number is still just the number when the program runs.
- A coordinate system can be a record, so the fields say which one a point is in.
- It's compiled, so even the last chapter's rehearsals are affordable.

### The most imported modules

Safari Ride has 96 modules, not counting `web.roc`, `main.roc` and `game.roc`. The import graph is lopsided in a good way. Counting who imports what, leaving out the test programs, a handful stand out, and the lines here are the ones above each module's `expect`s:

| Module | Imported by | Lines | What it is |
|---|---|---|---|
| `Distance` | 55 | 66 | A length in metres |
| `Fraction` | 28 | 88 | A ratio from 0 to 1 |
| `Geom` | 25 | 146 | Road points, bends, and how a point moves round one |
| `Angle` | 21 | 194 | Four opaque types for rotation |
| `Along` | 19 | 61 | A place along a segment |
| `Pixels` | 18 | 69 | A length on screen |
| `RoadAhead` | 16 | 208 | Where the road ahead lies from where the rider is |
| `Across` | 15 | 68 | A place across the road |
| `RiderView` | 15 | 241 | Points measured from the rider, and the near plane |
| `Screen` | 15 | 104 | The canvas: its size, its middle, its horizon |

`Picture` is imported by 15 as well. It's how one object looks in one frame, so every kind of object that draws one imports it. After those the count drops to 13, for `Animation` and `Steps`, and then 11, for `Segment`. Most modules are imported by one, two or three others. `Shapes` is imported about as widely. It's in `lib/`, a folder of modules shared with the repository's other canvas apps.

These are the core utility modules. There are only ten, and nearly everything else is a small module that takes one of these and adds a single idea. Six of the ten are nothing but numbers with rules, and most of those are under 100 lines. A cat, a tower and a truck are all found on the road through `RoadAhead`, and all reach the screen through `Camera`.

The modules of the math layer
```dot
digraph math {
  node [shape=box, fontname="Helvetica"];
  LeanSearch -> Coast [label="  coasts a try"];
  LeanSearch -> Motorcycle [label="  tries a lean"];
  LeanSearch -> Angle [label="  bounds a lean"];
  Coast -> Motorcycle [label="  steps it"];
  Coast -> Geom [label="  reads the road's width"];
  Motorcycle -> Angle [label="  turns by its lean"];
  Motorcycle -> Geom [label="  crosses a bend"];
  RoadAhead -> Geom [label="  carries points round bends"];
  RoadAhead -> RiderView [label="  answers rider points"];
  Camera -> Lens [label="  asks the pinhole"];
  Camera -> RiderView [label="  takes rider points"];
  Camera -> Screen [label="  answers screen points"];
  Lens -> Angle [label="  turns by the view"];
  Lens -> Screen [label="  finds the horizon"];
  Geom -> Angle [label="  turns by the bend"];
}
```

In this picture, which leaves out the unit types everyone shares, two families meet only at `Angle` and `Geom`: `RoadAhead`, `Camera` and `Lens` say how the world looks from the bike, and `Motorcycle`, `Coast` and `LeanSearch` say where it's going.

### Numbers with units

Here we add a speed to a length:

{{fails speed_as_distance}}

Eighteen small opaque types run through Safari Ride, and the tour has met most of them one at a time. Set side by side, they're a system:

| Type | Under it | What it measures |
|---|---|---|
| `Clock` | `U32` | A place in the ride |
| `Steps` | `U32` | A length of time |
| `Angle.Bearing` | `F64` | A place on the compass |
| `Angle.Turn` | `F64` | The angle between two bearings |
| `Angle.Lean` | `F64` | Roll, which only reaches direction through a rate |
| `Angle.LeanChange` | `F64` | How much a lean changes |
| `Distance` | `F64` | A length in metres |
| `Along` | `F64` | A place along a segment |
| `Across` | `F64` | A place across the road |
| `Pixels` | `F64` | A length on screen |
| `FarHeight` | `F64` | A place above the horizon, far off, as the resting lens draws it |
| `FarRise` | `F64` | How far apart two far heights stand |
| `Speed` | `F64` | Metres a step |
| `Acceleration` | `F64` | Metres a step, each step |
| `Fraction` | `F64` | A ratio from 0 to 1 |
| `Attention` | `F64` | How strongly something holds the eye, from 0 up |
| `Route.SegmentIndex` | `U32` | A place in the route |
| `SegmentFromRider.Position` | `U32` | How many segments ahead of the rider |

This is the opaque type doing the job of a unit. The block after each type is a small statement of dimensional analysis. `Speed.distance_in` takes `Steps` and gives a `Distance`. `Along.plus` takes a `Distance`, and two `Along`s give a `Distance`. `Lean.steer` takes a rate and gives a `Turn`. There's no `Bearing.plus(Bearing)`, because that sum has no meaning. If you try to write one, the compiler stops you.

The bug these prevent is the most common one in this kind of code: a correct formula with the wrong number in it. Most physics bugs type-check in a language where everything's a float.

The price is a long list of short methods, and a certain amount of `.to_radians()`.

The units run from the road to the screen. Once a point is measured from the rider, its `right` and `forward` are `Distance`s, and a length on screen is `Pixels`. `Pixels` is signed, because a place on screen is measured from the corner, so a point off the left of the screen is negative, and so is one above its top edge. It stops at the edge of `lib.Shapes`, which takes plain numbers. A formula wants floats, so `.to_metres()` unwraps one at the top of a function that's about to do trigonometry, and the answer is wrapped again at the end. `Along` can't be passed as `Across`, which rules out the classic swap in a function with both.

### One record per space

A point in Safari Ride is in one of four spaces, and the record's fields say which. Here we hand a point measured from the rider to a function that wants a point on the road:

{{fails rider_point_as_road_point}}

The points are plain records. They don't need to be opaque, since a record's type is its fields, and a `RoadPoint`'s fields are opaque already.

{{code Geom.RoadPoint}}

{{code RiderView.RiderPoint}}

{{code RiderView.RaisedPoint}}

{{code Screen.Point}}

Structural records give us *one record per space* at no cost: `along` and `across` are on the road, `right` and `forward` are from the rider, `right`, `forward` and `height` are from the rider with a height, and `x` and `y` are pixels. Reading any function, the field names say where it is.

Going from the road to the rider is a translation and a rotation, and this is the function where the opaque places give way to floats. `distance_from` makes the translation, and the rotation is written the way it would be on paper:

{{code RoadAhead.to_rider_point}}

From there to the screen is a pinhole camera, which is similar triangles. Dividing by `forward` is all of perspective. Nearly everything on screen passes through this function, and it's short:

{{code Camera.project}}

`project` takes a `RaisedPointAhead`, and that one is opaque. The only way to make one is to check the point against the near plane, a little ahead of the camera, so `forward` is never zero or negative by the time it's divided by.

A thing standing on the ground is projected twice, at its feet and at its head. `StillShapes.standing_anchor` calls `upright_on_screen` with a record of the height and focal length built on the spot:

{{code Camera.upright_on_screen}}

These two functions cover two of the three kinds of thing from The problem, and the third needs neither:

| Sort | Examples | Has | Lacks |
|---|---|---|---|
| Solids | the truck, the radio towers, the guard rails, the road and its ponds | every corner has its own place along, across and above the road | nothing |
| Cards | the cat, the bird, the cows, pigs and other animals by the road, the far trees | a foot on the road, and a width and a height on the screen | depth: they're flat, and always face you |
| Far scenery | the sun, the mountains, the rolling land | a direction and a height above the horizon | distance: they never come nearer |

A solid is projected corner by corner, each corner through `project`, as `Polygon.clipped_polygon` does for the truck's faces, the rails and the ground. A card is one projected foot plus a size, which is `upright_on_screen`. Far scenery needs no projection of distance at all: its direction picks a place across the screen, and its height above the horizon is already in pixels. A tree is the one thing that changes kind. Far off it's a card, but up close its crown is cones, and every point of a cone's ring goes through `project` like a solid's corner.

The focal length comes from a lens. `resting_focal_length` is a value computed from other values, with no function in sight, and `field_of_view` is a `Turn`, so taking half of it needs no comment about radians.

{{code Lens.resting_focal_length}}

The view widens as the rider leans. One `Fraction` goes in, and a focal length comes out. `RiderCamera.ride_focal_length` calls `focal_length_for`, which takes the shorter of the two focal lengths, the lean's and the attention's, so the wider view wins:

{{code RiderCamera.focal_length_for_lean}}

{{code RiderCamera.focal_length_for}}

### Round the bends

```widget route
The route again. This map comes from adding up the turns, which the ride itself never does. The white stretch is the record quoted below.
```

The road has no global coordinates. A point on it is measured within one segment, `along` and `across`, and nothing in the game holds a world coordinate for it. Each segment knows only its length and the turn at its end. `World.bending_plans` is eighteen records like this one, and a last plan ends the route. It reads like configuration: a list of plain values, with tags declared by the types that `SegmentPlan` and `BendingPlan` name, and an opaque `Distance` and `Turn` built from their units. It's checked like any other Roc, so a misspelled tag is a compile-time error. Here's the inside of one plan:

{{code World.bending_plans from "length: Distance.metres(1200.0)," to "bend_life: Animal(Rhino),"}}

So to see something three segments ahead, a point has to be carried back round each bend between it and the rider, one at a time. That's one rotation per bend. A `while` walks the road view's worked bends backward. The point starts on the far segment, and each pass moves it onto the segment before. The last line does the one translation and rotation from above:

{{code RoadAhead.rider_point_ahead from "var $point = road_point" to "to_rider_point($point, vantage)"}}

The rotation itself is one formula. Where the next segment starts was worked out once per bend, and the two segments share the corner on the inside of the bend, whichever way it turns:

{{code Geom.point_before_worked_bend}}

This is what lets the sightings not care where a segment is. They hand `RoadAhead.rider_point_at` a place on the road ahead and a point on that segment, and they get back a `RiderPoint`.

The ground also curves away. That's one formula, the small-angle drop of a sphere, with a record destructured in the parameter list and `right` and `forward` taken out to metres before they're squared. There are two radii in `EarthCurve`, and neither is the earth's. The ground's curve, 100 km, is the surface the road and the truck stand on, and it puts the horizon 490 metres out. The exaggerated curve, 20 km, only sets how soon a far tower goes: an 80 m tower is gone at 1.8 km, where the ground's curve would leave it in view to 4 km.

{{code EarthCurve.drop_over_radius}}

### Cutting a polygon

Here's a triangle with one corner behind the rider, before and after cutting:

| | Corners, as metres right and metres ahead |
|---|---|
| Before | (0, -1), (2, 5), (-2, 5) |
| After | (0.47, 0.4), (2, 5), (-2, 5), (-0.47, 0.4) |

The corner behind the camera has gone, and two new ones stand on the near plane, 0.4 metres ahead.

Anything that crosses the near plane has to be cut, or dividing by `forward` flips it across the screen. The textbook algorithm walks a polygon's edges, keeping corners in view and adding a new corner wherever an edge crosses the plane. The cut is written once, for any region with an edge, as a record with a type variable for the kind of point:

{{code RiderView.Region}}

In Roc, the walk is a pairing and a `fold`. `map2` zips each corner with the next one, which is the list rotated by one, and `fold` builds the new polygon. `List.with_capacity` is the one line about performance, and `edge_points_onto` is passed by name:

{{code RiderView.points_in_region}}

A fold's step is a plain function of the list so far and one edge:

{{code RiderView.edge_points_onto}}

The near plane is one region, and cutting by it is one line:

{{code RiderView.clipped_points}}

The ground's horizon is the other region, a circle round the rider.

The cut can change the kind of point as well as the count. The near plane takes `RaisedPoint`s and gives back `RaisedPointAhead`s, the kind `project` will take, while the horizon gives back `RaisedPoint`s. That's what the type variable is for.

`GroundPatch`, `GuardRail`, `TruckBody` and `TruckBrakeLights` all cut through `Polygon.clipped_polygon`. `GroundPatch` first cuts its corners at the horizon, with `EarthCurve.points_before_horizon`:

{{code Polygon.clipped_polygon from "in_front = RiderView.clipped_points(" to "Ok(Polygon.flat_polygon(Camera.projected_points(in_front, focal_length), color))"}}

### Arithmetic all the way down

At the very bottom are Roc's own builtins: `.sin()`, `.cos()`, `.sqrt()` and the rest. `Throttle.shoulder_brake` uses `F64.e.pow(x)` to turn the steps a rehearsed coast takes to reach the shoulder into a braking limit.

So from top to bottom, a rider chooses a lean by simulating physics, and the physics is plain arithmetic on opaque numbers. None of it has any effects. In the next chapter, we'll see what that's worth when the program has to change.

## Proving it

There are no animals in this chapter. It's about what happens to a program of this size when something has to change, which is the question a reader who cares whether Roc scales should ask.

A language with no hidden state doesn't make a refactor safe by itself. It makes it possible to write a test strict enough to be trusted, and that rests on one fact from the ride instant chapter. Four fields decide a frame, and a frame is a value. So a frame can be compared, exactly, with the same frame from an hour ago.

| Step | What the frame shows | Hash of its pixels | Shapes |
|---|---|---|---|
{{proof row 0 The start of the ride}}
{{proof row 100 A bird in flight}}
{{proof row 1529 A cat frozen in the road}}
{{proof row 1542 The same cat in mid-leap}}
{{proof row 3000 The ride under way}}
{{proof row 3698 A distant truck, its glow barely a pixel}}
{{proof row 5700 The truck at dusk, lights on}}
{{proof row 6250 The truck braking in plain view}}
{{proof row 9000 Past the end, on the second lap}}

Each row is one frame of the ride. Run the ride to that step today and you get that hash and that many shapes, and a change to the program has to leave every row as it is. This page's numbers come from the same file the check reads, `gates/proof.expected`.

New in this chapter:

- Roc: `expect` with its data beside it, `crash` as an assertion, a fold whose direction matters
- Modules: `RasterFrame`, `ShapesFrame`, `StepBack`, `SafariFrame`, `ShapesPixels`

The proof tools and what they read
```dot
digraph proving {
  node [shape=box, fontname="Helvetica"];
  gates [label="the proof tools\nRasterFrame, ShapesFrame, StepBack", style=dashed];
  Tour [style=bold];
  gates -> Tour [label="  ride it"];
  gates -> SafariFrame [label="  paint the frame"];
  gates -> ShapesPixels [label="  paint the shapes alone"];
  SafariFrame -> ShapesPixels [label="  paints the shapes"];
  SafariFrame -> backdrop [label="  paints the backdrop"];
  ShapesPixels -> ScanlineFill [label="  fills each shape"];
  backdrop [label="the backdrop\nSkyAndGrassPixels, SunPixels", style=dashed];
}
```

Everything here lives in `gates/`, and the game never runs any of it. The merge gate is the check a change has to pass before it lands. It runs the lints, every `expect`, the tutorial's build and the proof tools. Its programs reach the game through `game.roc`, a package whose only job is to list the modules they read.

### A fixture is a value

Getting a test to step 1,529 of a game normally takes some doing. Here it takes a loop. `Tour.initial` is a value, and `Tour.step_forward` is the outermost step function. It wraps `RideInstant.next_or_restart`, quoted below, which either continues the ride or starts it again. A `match` takes the next tour either way:

{{code Tour.step_forward}}

Testing here is just calling a function. There are no mocks, no fakes, no browser and no waiting. The tests are completely deterministic.

`RideInstant.next_or_restart` is one `if`, and it's worth seeing because it puts the end of the ride in one place. A ride that's finished starts again, so `Tour` needs no notion of game over:

{{code RideInstant.next_or_restart}}

### The frame hash

`RasterFrame` rides to a step, paints the frame into 576,000 exact pixels, and prints an FNV-1a hash of them. The painter is `SafariFrame`, in pure Roc. Its `ShapesPixels` does what `shapes_canvas.js`, the JavaScript that paints the page, does on a canvas. The gate holds each hash to a line of `gates/proof.expected`, exactly. There's no tolerance: one different pixel in one frame fails it.

A frame is only evidence for what's in it, so the steps in the table at the top of this chapter aren't arbitrary. Most are there for a scene. Step 0 is the start, and 3,000 shows the ride under way, with no scene of its own. Step 9,000 is past the end: the ride lasts 7,071 steps, so the clock at step 9,000 reads 1,928, and the frame shows the ride started again.

We add a frame whenever something could go wrong without any listed frame changing. A brake light wired to `Off`, for example, would pass every hash but one: step 6,250's, the truck braking in plain view.

Exact hashes have a consequence that reaches into the code. Float addition isn't associative, so a sum's order is part of its meaning here. `Route.segments_with_ends` says so in its doc comment, and it's one of the few places in Safari Ride where the direction of a fold is a decision:

{{code Route.segments_with_ends}}

That's also why each operation on `Speed`, `Fraction`, `Angle` and the rest does the plain float arithmetic its name says. An opaque type adds names and takes nothing away. A retyping that adds `Speed` to a module changes the types throughout, and if it leaves the arithmetic alone, every hash stays where it is. If a hash moves, the retyping changed the program, and the gate says so.

This is how the code in this tour got its shape. Its modules were renamed, retyped and reorganized, and each merge had to leave the frames alone. Roc's types caught what they catch, the hashes caught the rest, and the picture didn't change.

There's one limit to all this. The hash proves `ShapesPixels`'s pixels, and the page's pixels come from the browser's canvas, with anti-aliasing. What the two share is the list of shapes. `web/page_check.mjs` runs each built page against a stand-in canvas, and past that the JS has only its own checks.

### Two more proofs

The second of these two proofs is here because of a real bug:

| | One step back from step 3,000 lands on |
|---|---|
| When the history kept its first 2,048 instants | 2,047 |
| Now | 2,999 |

`ShapesFrame` paints each frame twice: once with its polygons whole, as the browser gets them, and once cut into triangles, as the native program gets them. It counts the pixels that differ, and the gate requires zero of 576,000, at every step in the table.

`StepBack` checks that one step back goes back exactly one step, at every depth of the whole ride, and that as many steps back as the ride took land on step 0. It's in the gate because the answer was once no: the list stopped recording when full, so a step back from frame 3,000 landed on 2,047. Holding the first 2,048 instants was a perfectly consistent thing for a list to do. The test works by asking `Tour.step_back` and comparing clocks, and since `Tour.step_back` is this small, there isn't much else to ask:

{{code Tour.step_back}}

### `expect`

The rest of the testing is ordinary `expect`s. An `expect` sits at the top level of a module, under the code it checks, and `roc test` runs it. There are over a thousand, and they're Safari Ride's only other tests. The tour has already shown sixteen of them, in the whole of `Clock` and `Pond`. A pure function needs nothing else: literal arguments, literal answer. Each `expect` asserts one thing, and they cover both sides. Two of `Clock`'s checks say a clock is not less than another, that step 9 isn't less than itself and step 10 isn't less than step 9, so they're written with `!`.

A test's data can sit beside it as a plain definition. Here's a motorcycle to step, with no rider around it, because `Motorcycle` doesn't import `Rider`. The test needs nothing the module doesn't:

{{code Motorcycle.riding}}

It's called like any other value, and the steps that follow are named, so three `expect`s can read them:

{{code Motorcycle.first_step}}

The gate makes `expect` honest in one further way. The gate takes its count from the source: every line that starts `expect`, in a module that one of its `roc test` runs compiles, has to print `PASS` exactly once. An `expect` that nothing compiles fails, and so does one that's indented out of reach. One more consequence: an `expect` can only name what its module imports, so a check sits where its test data can be seen, and a module doesn't take on an import for a test's sake. A check that needs more than one module goes in `gates/expects/`, a folder of expect modules, one for each topic, that import whatever their checks need. `Coast`'s projections and `LeanSearch`'s search are checked in its `RiderExpects`, the one for the rider.

Even a truck can be checked this way, though it can't be asked about step 4,000 cold. A `TruckJourney.TruckProgress` is a record, so a test writes one down and calls `TruckJourney.truck_progress_at_next_step` once.

### Crashes that help

{{code Fraction.of}}

Every `Fraction.of` in the game is an assertion, and the gate runs a lot of them. A ratio outside 0 to 1 stops the program, with a sentence saying the sum behind it is wrong. `Try` is the right answer when a value can honestly be absent. This isn't that case. A wrong ratio is a bug, and the sooner it's a crash the better.

Here's one of the many places it's used, with `smoothstep` trusting its own algebra. A proof run rides through it thousands of times, so if the algebra were wrong, the gate would be first to know.

{{code Easing.smoothstep}}

The same holds for the code's other `crash`es, including two dozen `?? crash`es on lookups that can't miss. Each one states a belief about the program, and every gate run tests it.

### The page itself

This tutorial is built from the code. Every fenced snippet here came through Roc's own parser, by name, and each failing program is run through the compiler, which is quoted. The gate builds the page. So renaming a function quoted here fails the gate until the prose catches up, and the compiler message under `turn_as_bearing`, in The sun, is the compiler's.

Lints round it out: a set of lints for Roc source runs first, with each count held exactly, and every count is at zero. A name that's vague or a boolean parameter that should be a tag fails before a single hash is computed.

All of that runs without a screen. The tour still hasn't said how a list of shapes reaches one, or where the effects went.

## The platform

The platform is what puts the list of shapes on a screen: the host, the JavaScript, and the modules every canvas app shares. Safari Ride has very little to say about it, on purpose. "The part that isn't Roc", in the modules chapter, gave the outline, and this chapter adds the code.

The modules around `SafariApp`
```dot
digraph platform {
  node [shape=box, fontname="Helvetica"];
  web [label="web.roc"];
  SafariApp [style=bold];
  web -> WasmApp;
  web -> SafariApp;
  WasmApp -> CanvasApp;
  SafariApp -> CanvasApp;
  SafariApp -> Input;
  SafariApp -> Tour;
  SafariApp -> Backdrop;
  SafariApp -> Screen;
  SafariApp -> Shapes;
  CanvasApp -> Input;
  CanvasApp -> Shapes;
  Tour -> Shapes;
  Backdrop -> Shapes;
}
```

New in this chapter:

- Roc: an app as a record, `roc glue`
- Modules: `WasmApp`, `CanvasApp`, `Input`, `Shapes`

`WasmApp`, `CanvasApp`, `Input` and `Shapes` are in `lib/`, and they're the same for every canvas app.

| The same modules, built as | By | For |
|---|---|---|
| Wasm | `web.roc` | The page |
| A native program | The merge gate | The proof tools |
| A native program on roc-ray | `main.roc` | A desktop window |

### An app is a value

{{code SafariApp.canvas_app}}

An app here is a record, handed to a runner. `CanvasApp(model)` has a type parameter for whatever the app keeps. Safari Ride's model is its `Tour` and a pause flag, and the app reads like configuration, because almost all of it is.

`CanvasApp.untimed_model_at_next_step` takes a function and answers a function, the same one with a seconds argument to ignore. Safari Ride counts steps, and this is the place that says so: a runner offers the seconds, and they go nowhere.

`web.roc` is ten lines. Its last is `program = WasmApp.program(SafariApp.canvas_app)`, and that's the whole connection between the game and the web.

### Keys

The ride instant chapter showed `SafariApp.model_at_next_step` reading a snapshot of the keys. A snapshot is a value, so a test could write one down. Everything the keys do is a function from `Tour` to `Tour`, so moving four steps or one is a loop of single steps. `Tour.steps_forward` takes the count as `Steps` and steps forward that many times. `var` is back, in a function that's still pure. `$tour` can't be seen from outside.

{{code Tour.steps_forward}}

`Tour.steps_back` is the same loop around `Tour.step_back`. The app passes four steps a frame while playing and one while paused:

{{code SafariApp.model_at_next_step from "steps_a_frame = match motion {" to "m.tour.steps_back(steps_a_frame)"}}

### A frame is a list

| What's in the shapes of step 1,570 | How many |
|---|---|
| `Poly` | 2,706 |
| `Disc` | 7 |

What the game hands back each frame is a `List(Shapes.Shape)`. A shape is a tag: `Poly`, `Disc`, `Rect` and a few more, each with its fill. Two of them aren't shapes. `Blend` and `View` are marks in the list that change how what comes after them is painted, because a frame is a list, and a mark is the cheapest way to say that.

The rider's lean is one of those marks. The whole picture banks into a turn, backdrop included, so `FrameView.leaned_shapes` builds a camera out of nested tags and puts it at the front. The rest is `Tour` answering questions, each a one-liner:

{{code FrameView.leaned_shapes}}

{{code Screen.leaned_by}}

### Where the effects went

One tick, in order
```dot
digraph one_tick {
  rankdir=LR;
  node [shape=box, fontname="Helvetica"];
  pace [label="canvas_app_runner.js\npaces the clock"];
  advance [label="advance\n(Roc)", style=bold];
  frame [label="frame\n(Roc)", style=bold];
  read [label="roc_glue.js\nreads the shapes"];
  paint [label="shapes_canvas.js\npaints them"];
  release [label="release\n(Roc)", style=bold];
  pace -> advance -> frame -> read -> paint -> release;
}
```

The game has no effectful functions, so where did the effects go? They never got as far as Roc. The wasm platform asks for a record of functions over a boxed model:

`init`, `model_at_next_step`, `frame_shapes`, `release`, `sounds`, `width`, `height` and `fps`, and for sound, which Safari Ride leaves empty, `tone_count`, `tone_freq` and `tone_ms`. Every one has a thin arrow, `->`. The host in `web/platform/host.zig` keeps the box, and all that crosses is numbers and a list of shapes. Wasm's edge has no records, so the input is flattened into seven numbers, and `Input.of` rebuilds it. `roc glue` generates `roc_glue.js`, which knows the layout of a frame in wasm memory, from `web/platform/Frame.roc`, so `roc_glue.js` is never edited.

Each step goes like this. `canvas_app_runner.js` paces the clock and gathers the keys. It calls `model_at_next_step`, then `frame_shapes`, in Roc. It reads the shapes back through the generated glue, and `shapes_canvas.js` paints them on a canvas. The host keeps the list until the next frame, then hands it back so that Roc can drop it. That's `release`, a function whose body is `{}`: Roc knows the layout of what it's dropping, and the host shouldn't have to.

The JS is about 490 lines for every canvas app there is. It knows nothing of cats. The only `!` names near Safari Ride are the `main!` and `echo!` of the gate programs, which are ordinary command-line apps, and the proof tools need them to print a hash.

The roc-ray build is the spike that proved the idea, and it isn't kept current, as Safari Ride's README says.

That's the last of the parts. Next, we'll put them back together by returning to the loop from the start of the tour.

## Zooming back out

Safari Ride is a loop. It designs a world once, and each time the clock steps, it moves what moves, finds what's near enough to see, and draws it. Every box on that loop has now been opened.

```widget ride
The ride again, with nothing in it left unexplained.
```

The loop, and the chapters that opened it
```dot
digraph opened {
  node [shape=box, fontname="Helvetica"];
  world [label="design the world (once)\nThe world, The road"];
  tick [label="the clock steps\nOne whole module"];
  move [label="move the rider and the truck\nStepping through the ride to The truck's motion,\nRehearsal"];
  look [label="look around\nRoadside trees, Radio towers,\nThe cat, The bird"];
  draw [label="draw it against the backdrop\nThe sky, The platform"];
  world -> tick [label="  starts the clock"];
  tick -> move [label="  each step"];
  move -> look [label="  from the new places"];
  look -> draw [label="  hands what it sees"];
  draw -> tick [label="  next step"];
}
```

### Four things remembered

Here's the whole book in one sentence: four things are remembered, and everything else is worked out.

{{code RideInstant.RideInstant from "One instant of the ride" to "}.{"}}

Those four fields are all the state there is. The sky's colors, where the sun stands, the beacons, the headlights, the cat's pose and the bird's, every sighting and every picture are worked out again from them on every page of the flipbook, and thrown away. `Tour` keeps a list of the instants before this one, for stepping back, but each of those is the same record of four fields.

### One step, in order

The four don't move independently. They read each other, so the order within a step is part of the game. `RideInstant.next`, shown in full in Stepping through the ride, takes them in this order:

1. The rider reads the world as it stood at the old clock: where the encounter on the rider's segment has got to. If a cat is crossing, the throttle holds.
2. The rider moves, and the clock ticks.
3. The truck reads how far along the route the new rider is, and aims at that. The rider never reads the truck.
4. The encounter plan is kept, forgotten if the rider has just reached a new segment, or made now, from the new rider at the new clock.

The rider reacts to the cat every step. The cat reacts to the rider once, when its plan is made, and never again: after that, it plays on the clock alone. So on the step a crossing is planned, the rider hasn't felt it yet.

Swap two of those lines and you get a different ride: a truck that read the rider from before the move would aim at a mark one step behind. Going backward never meets the order at all: `Tour.step_back` takes an old instant off the list, and nothing is replayed.

### All four at a glance

| Remembered | Type | What moves it each step | What reads it |
|---|---|---|---|
| The rider | `Rider` | `Rider.rider_at_next_step`, reading the encounter's stage at the old clock | The camera, and so every sighting; the truck and the plan, within the step |
| The truck | `TruckJourney.TruckProgress` | `TruckJourney.truck_progress_at_next_step`, reading how far along the new rider is | `TruckSighting`, and the brake lights |
| The clock | `Clock` | `Clock.next` | The sky, the sun, the mountains, the beacons, the headlights, and the encounter's stage |
| The encounter plan | `EncounterPlan` | `EncounterPlan.plan_at_next_step`: kept, forgotten at a new segment, or made from the new rider at the new clock | With the clock, the encounter's stage: the cat's and the bird's poses, and the rider's held throttle and look |

That's the loop from the start of the tour. The patterns that kept turning up along the way are gathered in the appendix that follows.

## Appendix: the patterns

Eight patterns kept turning up in the tour. They're patterns in the loose sense: shapes that kept turning up, and that Roc makes easy to write and hard to break.

| Name | What it is | Where to see it |
|---|---|---|
| Worked out, not stored | Keep the few things that must persist, and derive the rest each frame | `RideInstant`, `Cat`, `Sky` |
| A sighting decides, drawing paints | A pure function answers with plain data, and something else draws it | `EncounterSighting`, `TowerSighting` |
| Places and distances | One opaque type for where, a second for how far apart, and only the sums that make sense | `Clock` and `Steps`, `Bearing` and `Turn`, `Along` and `Distance`, `Speed` and `Acceleration` |
| Rule and timeline | One function says how far along, and one piece of data says what that looks like | `BirdFlight.flight_stage` and `BirdFlight.flight_timeline` |
| The step function | A value goes in, and the next value comes out | `Rider.rider_at_next_step`, `TruckJourney.truck_progress_at_next_step`, `Tour.step_forward` |
| The chain of limits | One value passes through independent rules, each of which can only lower it | `Throttle.next_acceleration` |
| One record per space | Field names say which coordinate system a point is in | `RoadPoint`, `RiderPoint`, `RaisedPoint`, `Screen.Point` |
| Rehearsal | Run the real rules on a pretend copy, read the result, and throw it away | `Coast`, `LeanSearch`, `Motorcycle.cross_bend_if_on_road` |

Code that reads like configuration deserves a line of its own, because the tour kept stopping to admire it: `Pond`, `World.bending_plans`, the timelines, and `SafariApp.canvas_app`. None of them is a config format. They're ordinary Roc values, so the compiler checks them, and a tag that's misspelled is a compile-time error.

## Appendix: what catches you out

This page lists what catches a reader of Roc out in Safari Ride, sorted by what shows up first. Everything on it comes from a chapter, and the last column says which.

### Reading the code

| What you see | What's going on | Chapter |
|---|---|---|
| A method call with no import | Static dispatch finds `next` from the type of the value | One whole module |
| A helper with no keyword to say it's private | Anything outside the module's block is private | The setting sun |
| `var` and `for` under a `->` | A local that nothing outside can see, with `$` marking what changes. The function is still pure | Roadside trees, Rehearsal |
| `?? crash` on a lookup | It isn't error handling. It states a belief about the program, and every gate run tests it | The world, Proving it |
| An `expect` that can't see a type | It can only name what its module imports, so `Coast`'s projections are checked in the gate's `RiderExpects` | Proving it |

### Running it

| What you see | What's going on | Chapter |
|---|---|---|
| A crash with a sentence about a sum | `Fraction.of` takes a ratio that can only be in range. A ratio that can rightly fall outside the range has to be held to it first | The sky, Proving it |
| The first frame of an animation shown too soon | `Waiting` and `Past` aren't progress of 0 and 1, because a critter can rest where no part of its animation reaches | The cat |
| Beacons that stop, or run backward | The clock counts steps, not seconds, so pausing freezes them and stepping back reverses them | The beacons |
| A frame hash that moves after a sum was reordered | Float addition isn't associative, so a sum's order is part of its meaning | Proving it |
| A green gate over a wrong brake light | The gate is blind to whatever no listed frame shows | Proving it |
| A page that differs from the hashed frame | The hash proves `ShapesPixels`'s pixels. The page's come from the browser's canvas, with anti-aliasing | Proving it |

## Appendix: glossary

This book uses these words in one sense only.

| Word | What it means |
|---|---|
| Across | A place across the road, measured from its middle. Left is negative. |
| Along | A place along a segment, measured from its start. |
| Backdrop | The sky, the grass and the sun. It's the first thing in every frame. |
| Billboard | A critter that stands still and always faces the camera, like the elephant. The bull is the fanciest one, with gradients in its still. |
| Canvas | Where the painter puts shapes. Safari Ride's frames are for a canvas 960 pixels wide and 600 pixels tall. |
| Card | A flat thing that always faces you, with a foot on the road and a width and a height on the screen, like the cat. |
| Corner | One of the points of a polygon. |
| Critter | Any animal in the ride, from the cat to the elephant. It's just our word for them: other people would say animals. A tree or a tower is never a critter. Critters come in two sorts: billboards, and motion critters. |
| Depth | How far ahead of the camera something is. Far things come first in a frame. |
| Encounter plan | One of the four things remembered: whether the encounter on the rider's segment is planned yet, and the step it starts at. |
| Far scenery | The sun, the mountains and the rolling land: a direction and a height above the horizon, and never any nearer. |
| Frame | Everything shown for one step: the backdrop, the mountains and the ground, then a series of pictures, far to near. |
| Gawking | What the speed does for a pig: it drops, and it stays down to the end of the segment. |
| Kind | Which sort of object something is, like `Conifer`. |
| Look | What the eyes do for a pig: they follow it until it's too far round. |
| Motion critter | A hand-drawn critter that moves, like the cat and the bird. |
| Near plane | The closest the camera can see, 0.4 metres ahead, where anything that crosses it is cut. |
| Object | A thing in the picture with a place of its own: a tree, a tower, a critter or the truck. |
| Painter | What puts shapes on the canvas. The page's painter is the browser's canvas, and the proof's is written in Roc. |
| Picture | How one object looks in one frame. A frame holds a series of pictures, so the app never draws "a new picture" at each step. |
| Placed | Put on the road, measured `along` and `across` a segment, and `lift` off the ground. |
| Polygon | A shape with three or more corners, and nearly every shape in a frame is one. |
| Rendered | Made into a picture, with its depth attached. |
| Road ahead | The rider's segment and the segments after it, as far as the rider can see. |
| Route | The list of segments that makes up the whole ride. |
| Segment | One stretch of road, from one bend to the next. |
| Shape | One item in a frame's list, such as a polygon, a disc or a rectangle. |
| Sighting | An object's spot and its kind, for one frame. It's a `Pipeline.Sighted`. |
| Solid | A thing whose every corner has its own place along, across and above the road, like the truck. |
| Spot | Where an object stands in one frame: its place on the road, its height off the ground, and where that puts its foot in the rider's view. Its sighting works it out once, and every picture is drawn from it. It's a `Spot`, from the module `Spot`. |
| Step | One tick of the ride. Each step has one frame. |
| Still | A critter's drawing, as polygons traced ahead of time. |
| Tier | One layer of a conifer's crown. |

## Credits

Safari Ride was designed by Steve Howell. Claude wrote most of the code and this tutorial under his direction.

The animals by the road are drawn from Microsoft's [Fluent Emoji](https://github.com/microsoft/fluentui-emoji), in its Flat style, under the MIT license.

The way these chapters open and close, the predictions under the widgets and the appendix "what catches you out" are ideas from Braeden Foster's [Rocco tutorial](https://github.com/Pixelsprout/rocco-engine).
