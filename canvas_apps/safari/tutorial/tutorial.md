# Safari Ride: a tour of a real Roc program

Safari Ride is a small Roc program with a lot to look at. This book reads it with you.

## Introduction

Safari Ride is running in the page below. It's a big page, so give the ride a little while to load. Then it starts by itself.

```widget ride
The ride, running as you read. Click it to give it the keyboard: Space pauses it, and the arrow keys step it.
```

Watch it all the way through. A motorcycle carries its rider down a long country road. Cows and pigs graze in the fields, and trees crowd the roadside. A truck runs on ahead. A cat waits by the road for its moment to cross, and a bird takes off as the rider comes near. As the sun sets behind the mountains, the truck turns on its headlights. At the end of the road the rider stops, and the ride starts over.

Safari Ride is written in Roc, and this is a book about Roc. If you're brand new to Roc, the [official Roc tutorial](https://www.roc-lang.org/tutorial) makes a quick first stop. The tutorial teaches the language through small examples. This book picks up from there, with one real program: how its code is organized across many modules, and how Roc's larger ideas, such as opaque types, type variables and `where` clauses, solve the problems the ride poses. Roc is fun to read, and the book quotes the real code behind everything on the screen. The book explains each new Roc idea where the code first needs it.

You'll learn two things as you read: Roc, and how a ride like this one is animated. The animation is a handful of plain ideas. Each frame is one picture, and a step moves the world on before the next. Far things look small, and near things cover far ones. The book explains each of these in plain words where the ride first needs it, and the trigonometry behind them waits for a chapter of its own near the end. If you know animation already, skim those parts. If both are new to you, you'll get both at a walking pace.

## One page

Safari Ride works like a flip book. Each frame is one page, and the ride shows a new page thirty times a second. Here's one page, held still. It's the page at step 1,529, with the cat out on the road:

```widget frame moving
Step 1,529 of the ride, held still.
```

This chapter makes a first pass over that page. It names the page's parts in the code, and it skips how each part is made.

In the code, a page starts as one value of the `FrameView` type:

{{code FrameView.FrameView from "FrameView := {" to "}.{"}}

You can read it as English for now. A `# ...` line marks code the book leaves out. Four of the fields are parts of the picture you can see: the backdrop of sky and grass, with the sun when it's in view; the mountains; the road and its ponds; and the scene, which holds the things in view on and beside the road. The fifth field, the camera's roll, leans the whole page when the bike leans. The roll comes from the rider, so it waits for the second half of the book.

One function gives back the `FrameView` for any moment of the ride:

{{signatures FrameView.frame_view_at}}

That line is a type annotation: the function's name, a colon, and its type. `frame_view_at` takes a `Route`, the whole road, and a `RideInstant`, one moment of the ride, such as the one at step 1,529. After the arrow comes what it gives back, the moment's `FrameView`. One more function turns the `FrameView`, backdrop and all, into a single list of shapes, leaned by the roll:

{{signatures FrameView.leaned_shapes}}

Roc code runs on a platform, and Safari Ride's platform paints that list on the screen. So each page starts from one moment of the ride and ends as one list of shapes.

The first half of the book holds this page still and builds it part by part, starting with the things beside the road. The second half turns the pages. The chapters ahead read Roc slowly, one idea at a time, so the syntax here can wait for them. The next chapter breaks the ride into the pieces we build.

## The problem

Safari Ride shows a world in motion, seen from the rider's seat. Thirty times a second, it puts a new picture of that world on the screen. Each picture is a frame, and between frames a step moves the world on, so the pictures move. Whoever is watching can take the controls at any moment.

That's what you see. For us, it's an engineering problem, and our first job is to break it into pieces we can build one at a time. A screen shows things from a world, and those come first. We hold one frame still and get it right before anything moves, and the controls come last. That plan costs something: the first half of the book holds one frame still. In return, every piece we build stands on a piece that already works. The plan gives the problem five pieces:

The five pieces
```dot
digraph pieces {
  rankdir=TB;
  node [shape=box, style=rounded, fontname="Helvetica"];
  edge [fontname="Helvetica", fontsize=10];
  subgraph cluster_frame {
    label="one frame, held still"; style="rounded,dashed"; fontname="Helvetica";
    things [label="things"];
    world [label="the world"];
    view [label="the rider's view"];
    { rank=same; things; world; view; }
  }
  motion [label="motion"];
  person [label="the person watching"];
  { rank=same; motion; person; }
  things -> world [label="  stand in"];
  world -> view [label="  is seen in"];
  world -> motion [dir=back, label="  moves"];
  view -> person [label="  shows a frame to"];
  motion -> person [dir=back, label="  pauses, steps"];
}
```

| Piece | Challenge | The problem |
|---|---|---|
| Things | Components | A tree, a cow and a radio tower must each be built from shapes the screen can show. Every frame starts from a blank screen, so every frame must hold all of its shapes, every time. |
| The world | Structure | A long road runs through open country, past trees, herds, ponds and radio towers. Something must lay it all out, and say where every one of them stands. |
| The rider's view | Perception | The screen shows only what the rider sees. A tree far down the road looks small, and a tree close by looks big. For everything in the world, the program must work out what the rider perceives: where it lands on the screen, and how big, if the rider sees it at all. Where two things overlap, the nearer one covers the farther one. |
| Motion | Persistence | The rider rides on, the truck drives ahead, the cat crosses the road and the sun goes down. At every step, something must carry each of them on from where it was, and the moves must fit together. The cat times its crossing to the rider coming toward it, and a cat in the road stops the rider speeding up. |
| The person watching | Interaction | A viewer mostly sits back and watches, but they also need to pause the ride, step it forward and rewind it. So the program must give them controls they can find, and answer each one straight away. |

Each of those pieces lives somewhere in the code. So before we read the first one, a short chapter shows how a Roc program is laid out: the platform it runs on, the modules it's made of, and the packages it uses.

## Platforms, packages and modules

A Roc program runs on a platform, it's made of modules, and it can use packages. Those three words say where Safari Ride's code lives.

A platform is the layer underneath a Roc program that deals with the outside world. For Safari Ride, that's the screen and the keyboard. The Roc code describes each frame, and the platform paints it. In this page, the platform is WebAssembly and a little JavaScript. On a desktop, the same Roc code runs on a native platform called roc-ray.

Each Roc program is an app, and the app's first line of code names its platform. Here's Safari Ride's app for the web, the whole file:

{{module web}}

Lines that start with `#` are comments. The first line of code names the platform, and gives it the short name `pf`.

The first line also names a package, `lib`. A package is a bundle of modules: the app gives it a short name, and the path says where it is. The `lib` package holds what Safari Ride shares with the live pictures in this book, such as what a shape is and what a key press is.

A module is one file of Roc, named for what it holds. `SafariApp.roc` holds the `SafariApp` module, and `import SafariApp` brings it in. `import lib.WasmApp` brings in the `WasmApp` module from the `lib` package.

The brackets after `app` name the two things the app hands the platform, and the last two lines define them. `Model` is the type of what the app keeps as it runs, and here it's the one in `SafariApp`.

`SafariApp.canvas_app` is the whole ride as one value, and the `WasmApp.program` function fits it to the web platform. What it gives back is the app's `program`.

## Types

Types are at the heart of every Roc program. A type says what a value holds, and the compiler checks every value against its type. So a good way to meet a Roc program is to read its types.

This chapter takes one tour across Safari Ride, with a stop for each of the five pieces from the {{chapter The problem}} chapter: things, the world, the rider's view, motion and the person watching. On the way, you learn to read the types Roc programs are built from: numbers, records, tags, type variables and the types of functions. The next chapter reads one function closely, and the rest come piece by piece.

### Numbers at the bottom

Every type is built from smaller ones, and at the bottom are Roc's own primitive types. Safari Ride's are nearly all numbers. Here's a type built around one, `Distance`, in full:

{{code Distance.Distance}}

Here's what its parts say:

| Code | What it says |
|---|---|
| `Distance ::` | `Distance` names the type. The `::` makes it opaque: only the `Distance` module reads what's inside. |
| `F64` | What's inside: one of Roc's number types, a 64-bit floating-point number. A `Distance` is a length in metres. |
| `.{` and `}` | The type's own functions sit between these braces. |
| `##` | A doc comment, which describes the code under it. |
| `metres : F64 -> Distance` | The type of a function: `metres` takes an `F64` and returns a `Distance`. |
| `metres = \|metres\| Distance.(metres)` | The function itself. `Distance.(metres)` wraps the number it's given as a `Distance`. |
| `to_metres = \|Distance.(d)\| d` | The other way round: `Distance.(d)` opens a `Distance`, and the function gives back the number inside. |
| `is_gt` to `is_lte` | These four let `>`, `>=`, `<` and `<=` compare two lengths. |
| `is_eq : _` | This lets `==` compare two lengths, and the `_` asks the compiler to write its definition from the number inside. |

Everywhere outside this module, a length is a `Distance`, and the compiler keeps it apart from every other number. The functions between the braces are the only ways to make a length, change one or read one.

### Things

```widget frame moving
Step 1,529 of the ride, held still: the frame these types describe.
```

Every thing beside the road has a kind, and each kind is a type. A tree is a `Conifer`, a cat is a `Cat`, and a radio tower is a `Tower`. A cow is a `Billboard`, an emoji that stands on the grass, square to the rider, looking left or right:

{{code Billboard.Billboard from "Billboard ::" to "}.{"}}

Here's what each piece of it says:

| Code | What it says |
|---|---|
| `Billboard ::` | `Billboard` names the type. The `::` makes it opaque, as it does `Distance`: only the `Billboard` module reads its fields. |
| `emoji : EmojiStill,` | `emoji` names a field, and `EmojiStill` names its type: the `EmojiStill` type in the `EmojiStill` module. |
| `height : Distance,` | `height` names a field, and `Distance` names its type: the main type of the `Distance` module. |
| `facing : Billboard.Facing,` | `facing` names a field, and `Billboard.Facing` names its type: the `Facing` type in the `Billboard` module. |

A module's main type has the module's own name, as `Billboard` and `Distance` do. Wherever it's used, every other type a module offers carries the module's name in front, as `EmojiStill` and `Billboard.Facing` do.

A `Billboard.Facing` is one of two tags, `FacesLeft` or `FacesRight`. A tag is a name the compiler knows, and a type made of tags lists every one it allows.

For each frame, a thing produces the shapes that show it, in the order they're painted. We call those shapes its sprite. Here's the `Sprite` type:

{{code Sprite.Sprite from "Sprite ::" to ").{"}}

A `Sprite` is opaque, like `Billboard`, and it holds a `List(Shapes.Shape)`: a list whose items are each a `Shape`, from the `Shapes` module. Nearly every shape has straight edges. A far tree's sprite is one rectangle of trunk under eight triangles.

### The world

A sprite says how a thing looks. Where it stands is the world's job. The `World` module plans the road as a short list of stretches, called segments, and each segment's plan is a record of the `SegmentPlan` type:

{{code World.SegmentPlan}}

A plain `:` gives the record type a short name: any record with these fields is a `SegmentPlan`, so any module can build a plan and read its fields. Here's the plan for the last stretch of road:

{{code World.last_plan}}

After a value's name, a `:` gives the value its type, so the first line says `last_plan` is a `SegmentPlan`, and the rest defines it. `Distance.metres(300.0)` calls the `metres` function in the `Distance` module. On this stretch, a cat crosses the road. The `World.route` value is the whole road, built from the plans once, before the ride starts, and every tree, herd, pond and tower takes its place along it.

```widget route
The whole route from above, one stretch of road for each plan. A mark in the middle of a stretch shows that its plan has a cat cross or a bird fly.
```

### The rider's view

The screen shows only what the rider sees. So each frame is produced as if by a camera on the rider: it sits where the rider sits, and faces where the rider looks. Each thing takes three forms on its way to the screen, and each form is a type. First, the thing is placed on the road:

{{code Geom.Placed}}

The `kind` in parentheses is a type variable: it stands for whatever type fills it. So a cow on the road is a `Geom.Placed(Billboard)`, whose `kind` field holds a `Billboard`, and a tree is a `Geom.Placed(Conifer)`. One type serves every kind.

Then the camera sights the thing:

{{code Pipeline.Sighted}}

A sighting keeps the kind, and adds a `Spot`: where the thing stands in the rider's view, so far ahead and so far to the side.

From the spot, we work out where the thing lands on the screen, and how big it looks there. One rule gives both: twice as far away looks half as big.

The camera refuses a thing out of the rider's sight with the tag `OutOfSight`: it's behind the camera, too close to show, or too far off to show over the horizon.

Last, the thing is rendered:

{{code Rendered.Rendered from "Rendered ::" to "}.{"}}

A rendering holds the thing's sprite, and its depth: how far ahead of the camera it stands. The kind is gone, so trees, cows and towers all meet in one list of renderings.

To finish the frame, the `DepthSort` module sorts that list far to near, and the platform paints it in that order, as a painter paints the far hills before the near trees.

### Motion

So far the ride stands still. To set it moving, one record holds the whole ride at one moment:

{{code RideInstant.RideInstant from "RideInstant := {" to "}.{"}}

The `:=` makes `RideInstant` nominal: a new type, apart from every other record with the same fields, as an opaque type is. Any module can read a nominal type's fields.

Those four fields are everything the ride carries from one step to the next: the rider, the truck, the clock, and the plan for when the cat or the bird ahead starts to move. We derive everything else that changes from them. The sun goes down because the clock says so.

A step is one function's job, and its type tells the story:

{{signatures RideInstant.next_or_restart}}

When a function's body is long, the book shows its type annotation alone, until the body's turn comes. `next_or_restart` gives back a type written in place, in square brackets: one of two tags. A tag can carry a value, and each of these carries the next moment. `Continued` carries the moment one step on, and `Restarted` carries the ride's first moment, once the rider has finished the route.

Inside the step, the four fields move in a fixed order, so the moves fit together: the rider reads what the cat or bird ahead is doing, and then moves. The second half of the book reads that order line by line.

### The person watching

The controls are a handful of keys, named beside the ride. The app's model is one line:

{{code SafariApp.Model}}

The `motion` field's type is written in place, as two tags. The tour holds the route, the moment on show, and every moment before it since the ride last started:

{{code Tour.Tour from "Tour :: {" to "}.{"}}

Because the tour keeps every past moment, stepping back is as quick as stepping forward: the tour takes the moment before, and the frame is produced from it like any other.

### Where we start

On the way, you've read three ways to name a type. A `:` gives a type a short name, and any value of that shape fits it. A `::` makes a new, opaque type, and only its module reads inside it. A `:=` makes a new, nominal type, and any module reads its fields.

Every one of these types comes with functions, and every chapter from here on reads them. So the next chapter takes one function apart. After it, we start with things: what a cow, a tree or a tower is in the code, and how a thing becomes a sprite.

## Functions

Every chapter from here on reads Roc functions, so this short chapter takes one apart. It works out how dark the sky is at a step of the ride:

{{code Sky.darkness_at}}

In Roc, a function is an ordinary value, like a number. Its code is an anonymous function, and `=` gives it a name. Roc calls a named value a constant: once named, it keeps its value. Inside a function's body, the constants are named again on each run, so each run has its own. Here's the function, piece by piece:

| Code | Term | What it says |
|---|---|---|
| `##` | doc comment | Describes the code under it. |
| `darkness_at : Clock -> Fraction` | type annotation | The function's name, a colon, and its type. `darkness_at` takes a `Clock`, which counts the ride's steps, and returns a `Fraction`, a number from 0 to 1. |
| `->` | thin arrow | Separates what the function takes from what it returns. |
| `darkness_at =` | constant | `=` names the function. |
| `\|clock\|` | anonymous function | The function itself starts here. |
| `clock` | argument | What the function is given. |
| `{` and `}` | block | Names for values, then one last expression. A block is an expression too, and its value is that last expression's value. |
| `height = ` | constant | A name for a value, which the lines below it use. |
| `SunPath.height_at(clock)` | function call | Calls `height_at` from the `SunPath` module, with `clock` as its argument. |
| `if` and its two branches | `if` expression | The block's last expression, so its value is what the function returns: one of the two calls, picked by whether the sun is still up. `SunPath.height_when_set`, the sun's height once it has set, is a constant from the same module. `darkness_while_up` and `darkness_after_set` are functions further down in the `Sky` module, outside its type's braces, and a module calls those by their bare names. |

A function's body is always one expression. A block is one kind, and a short body can be a plain expression, written straight after the `|`. Here's one from the `Distance` module, which turns a number of metres, an `F64`, into a length:

{{code Distance.metres}}

Inside the body, `metres` is the argument. The function sits inside `Distance`'s braces, so it goes by `Distance.metres`, and the bare name is free for the argument. `Distance.(metres)` wraps the number as a `Distance`.

The book often shows a function's annotation alone, until its body's turn comes. An annotation lists the things a function takes with commas between them:

{{signatures Sky.color_at_darkness}}

`color_at_darkness` takes an `RgbColor` and a `Fraction`, and returns an `RgbColor`.

### Methods

Many calls in the book put a value first, as in `SunPath.height_at(clock).minus(FarHeight.zero)`. That's a method call. A method is a function associated with a particular type. Here's a function built from them, which works out how warm the horizon's color is, from how near the sun stands to the horizon:

{{code Sky.horizon_warmth_at}}

| Code | Term | What it says |
|---|---|---|
| `SunPath.height_at(clock)` | function call | Returns the sun's height, a `FarHeight`. |
| `.minus(FarHeight.zero)` | method call | `FarHeight` has a `minus` method. The value before the dot is its first argument, so this is `FarHeight.minus(SunPath.height_at(clock), FarHeight.zero)`. |
| `.abs()` | method call | A method whose one argument is the value before the dot. `minus` returns a `FarRise`, the rise from one height to another, so this calls `FarRise.abs`. |
| `from_horizon.ratio_to(warmth_reach)` | method call | Divides one `FarRise` by another: how far the sun stands from the horizon, as a share of `warmth_reach`, a constant rise further down in the module. |
| `Fraction.clamp(…).complement()` | function call, then method call | `clamp` keeps a number between 0 and 1, as a `Fraction`, and `complement` returns 1 minus it. |

The compiler knows every value's type, so it turns each method call into a call of that type's own function when the program compiles. A type's methods are the functions between its `.{` and `}`, as `Distance`'s were. Even `>=` in `darkness_at` calls a method, `is_gte`.

The next chapter starts on the things beside the road. Every function from here on has a block body or a one-expression body, and calls functions and methods like these.

## Things

The things beside the road are its trees, its radio towers and its animals. Here's a cow and a bull on the grass, produced by Safari Ride's own code:

```widget cow
A cow and a bull on the grass beside the road.
```

The ride has a lot of animals: herds of cows, some led by a bull, herds of pigs, ducks on the ponds, and an elephant at a bend in the road. The cat and the bird move, and they get chapters of their own.

Every other animal is a billboard: a flat picture of its emoji, standing on the grass and turned square to the camera, like a cardboard cutout. That takes far less code than modeling an animal, and it's charming.

A billboard faces left or right, and one that faces right is its emoji mirrored. That's the `Billboard` type from the {{chapter Types}} chapter: an emoji, a height and a facing. Each emoji was traced into polygons ahead of time, and the `EmojiStill` module holds them as plain data.

A billboard animal starts from a record of the `Billboard.Species` type: its emoji, and how tall a grown one stands. A plain `:` names that type, so any module reads its fields. Here are the cow's and the bull's, from the `CowHerd` module:

{{code CowHerd.cow}}

{{code CowHerd.bull}}

The bull's height comes from the cow's: `cow.adult_height` reads a field of the `cow` record, and `.times(1.15)` is a method call on that `Distance`.

### Calves

A herd looks better with a few calves in it. The ride's rule is simple: number a herd's cows from 0, and make cows 1, 5, 9 and so on calves: every fourth cow, starting with cow 1. A calf is a billboard half as tall as a grown cow. Here are twenty cows in a row, numbered:

```widget herd
Twenty cows, numbered from 0. Cows 1, 5, 9, 13 and 17 are calves.
```

The code picks the calves with a function:

{{code CowHerd.is_calf}}

`is_calf` takes a `U64`, a whole number from zero up, and returns a `Bool`, `True` or `False`. `cow_number.rem_by(4)` is the remainder after dividing by 4, and `==` compares it with 1, which gives the `Bool`.

A second function puts `is_calf` to work. It gives each cow in a herd its billboard:

{{code CowHerd.cow_billboard}}

Its `if` picks one of two billboards: a young one when `is_calf` says `True`, and a grown one when it says `False`. A `Billboard` is opaque, so only the `Billboard` module can build one, and `young_billboard` and `adult_billboard` are two of the ways it offers. The herd calls `cow_billboard` for every cow it places.

### What a thing's sprite takes

Calf, cow or bull, the ride produces a billboard's sprite the way it produces the sprite of every kind of thing beside the road: with a function called `scenery_sprite`, in that kind's module. The `Billboard` module's `scenery_sprite` has a longer definition, built around a `match`, a way of choosing between tags that the next chapter teaches. So here's its annotation alone:

{{signatures Billboard.scenery_sprite}}

It takes a `Billboard` and a setting, and gives back a sprite. The `Conifer` module's `scenery_sprite` takes a tree instead, and the `Tower` module's takes a tower, but every one takes a setting and gives back a sprite. So whatever its kind, a thing in a frame comes out as a sprite.

A setting is a record:

{{code Sprite.Setting}}

The `focal_length` says how strong the camera's lens is: the longer it is, the bigger everything looks, as when a camera zooms in. The `darkness` says how dark the sky is, from 0 by day to 1 at night, so everything beside the road can dim as night falls.

The `spot` comes from a camera: it's what a sighting holds. So for the cow and the bull, the picture at the top of this chapter puts each one on the road by hand, the cow 10 metres ahead and 5 metres left of the middle, and lets a camera at the start of the road sight them. The rider's own camera comes in a later chapter.

What comes back is a sprite, and every sprite is a list of shapes. The cow's sprite is its emoji, as polygons. At step 1,529, the ride produces 2,121 shapes on top of the sky and the grass: 868 triangles, 727 quads, 518 polygons and 8 discs. The trees' trunks are 136 of the quads.

At the bends in the road stand four more kinds of billboard animal: elephants, giraffes, zebras and rhinos. They come next, with the `match` that mirrors the ones that face right.

## Billboard Critters

Four kinds of big animal stand at the bends in the ride's road: elephants, giraffes, zebras and rhinos. Each animal stands with its baby:

```widget bend_animals
The four bend animals and their babies, lined up on the grass: two pairs face right, and two face left.
```

The Roc ideas here are tag unions and `match`: a type that is exactly one of a few tags, and code that handles each tag in turn. A nominal type and a tag that carries a value come along with them.

### Two ways to face

Each emoji shows its animal from the side, so a billboard faces left or right, and your eye follows its gaze. The `Billboard` module gives those two ways a type of their own:

{{code Billboard.Facing}}

The type is a list of tags in square brackets. A tag is a name the compiler knows, and it's a value in its own right: `FacesLeft` is a value, and so is `FacesRight`. A type made of tags is a tag union, and a value of a tag union is always exactly one of its tags.

The {{chapter Things}} chapter showed the annotation of `Billboard.scenery_sprite` alone. Here's the whole function:

{{code Billboard.scenery_sprite}}

A `Billboard` is opaque, and `Billboard.(billboard)` in the arguments opens it: it unwraps the billboard into a record named `billboard`, so the function can read `billboard.facing` and the other fields. Only the `Billboard` module can write that.

Braces hold a block or a record: a block holds lines of code, where a record holds fields with colons. The block names `flip`, and its last expression makes the sprite. `billboard.emoji.still()` gives the emoji's traced still. `StillShapes.standing_still_shapes` makes shapes from it at the billboard's height, and `Sprite.from_shapes` makes those shapes a sprite. In that last record, `flip` alone is short for `flip: flip`.

Every emoji faces left, so a billboard that faces right needs its emoji mirrored. The `match` makes that choice. It looks at `billboard.facing`, and each line under it takes one tag and gives back what to do: `FacesLeft` gives `AsDrawn`, and `FacesRight` gives `Mirrored`. Those two are the tags of another tag union, `StillShapes.Flip`, and `flip` names the one the `match` picks. The compiler works out the type of `flip` from where it's used.

A `match` handles every tag of its type, and the compiler checks that it does. Leave out the `FacesRight` line, and the compiler stops with an error that names it:

```text
This match expression doesn't cover all possible cases.

Missing patterns:
        FacesRight
```

### Four animals

The bend animals are a tag union too, with four tags:

{{code BendAnimal.BendAnimal from "BendAnimal :=" to "Rhino]"}}

Each tag is an animal. `BendAnimal` uses `:=`, so it's a nominal type: a new type, apart from any other tag union with the same tags. The `species_of` function turns each one into its species record, an emoji and a grown height, like the cow's in the {{chapter Things}} chapter:

{{code BendAnimal.species_of}}

This `match` is about as plain as one gets: a tag in, a record out, one line per animal. Its four lines are the four tags, so every bend animal has a species, and a grown giraffe is always 4.5 metres tall.

### One thing at a bend

A bend is quiet, or it holds one thing: an animal and its baby, or a pond of ducks. The `Segment` module's `BendLife` type says what's at a bend, and it says exactly that:

{{code Segment.BendLife}}

`Quiet` and `DuckPond` are plain tags, like the ones above. `Animal(BendAnimal)` is a tag that carries a value: an `Animal` always comes with one `BendAnimal`. So `Animal(Giraffe)` is a whole value, a bend with a giraffe at it.

The route's plan stores a `BendLife` for each bend. A plain list of billboards there would let a giraffe and a duck pond share one bend. A `BendLife` is exactly one of its three tags, so a bend gets one thing, and the list of its billboards is worked out from that one thing.

What a bend's life can be
```dot
digraph bend_life {
  rankdir=LR;
  node [shape=box, fontname="Helvetica"];
  edge [fontname="Helvetica", fontsize=10];
  BendLife;
  Quiet; DuckPond;
  Animal [label="Animal(BendAnimal)"];
  BendLife -> Quiet [label="  is one of"];
  BendLife -> Animal [label="  is one of"];
  BendLife -> DuckPond [label="  is one of"];
  Animal -> Elephant [label="  carries one of"];
  Animal -> Giraffe [label="  carries one of"];
  Animal -> Zebra [label="  carries one of"];
  Animal -> Rhino [label="  carries one of"];
}
```

The function that gives a bend its billboards takes the bend's life and the bend itself, a `Geom.Bend`, and takes the life apart with a `match`:

{{code Segment.bend_billboards}}

The `Animal(animal)` line matches a bend with any animal at it, and names the animal it carries `animal`, ready to use. Then `animal.bend_billboards(bend)` calls a different function with the same name. `animal` is a `BendAnimal`, so the call goes to the `bend_billboards` that comes with `BendAnimal`, which places the animal and its baby. A duck pond gets its ducks from the `Pond` module, and a quiet bend gets the empty list, `[]`. The code has the same shape as the type: one line for each tag, and the value a tag carries named right where the line needs it.

### Elephants, mostly

The route's plans say what lives at each bend, and most of them say `Animal(Elephant)`. Only a handful say `Animal(Giraffe)`, `Animal(Zebra)`, `Animal(Rhino)` or `DuckPond`. That's on purpose. The ride is more interesting when most of it is ordinary: the elephants are the fixture, so the rare animal is a surprise.

A tag union lists everything a value can be, and a `match` handles each case. The emojis came ready-made, traced ahead of time. Next, we build shapes of our own: a triangle and a rectangle.

## Shapes

A far tree in the ride is a trunk under eight triangles. So before we build a tree, we build its two shapes: a triangle and a rectangle.

In Safari Ride, a shape is a value that describes something to paint. The first four tags of the `Shapes` module's `Shape` type are the kinds of region the ride paints, each a region of the screen with a fill:

{{code Shapes.Shapes from "Shape : [" to "Polygon({ corners :"}}

Each tag carries a record, and every record ends with a `fill`, the paint for the inside. The ride produces a great many triangles, plenty of four-cornered things, a few round lights, and outlines traced from emoji and mountains, so those are its four regions. More tags follow them in the type, for other jobs, such as a line of text.

### A triangle

Here's a triangle:

```widget shapes triangle
A green triangle on a plain background.
```

And here's the code that makes it:

{{code ShapesWidgetApp.green_triangle}}

The value is a `Triangle` tag with its record. The record names three corners, `first`, `second` and `third`, so every triangle has exactly three, by construction. A corner is a `Point`, a record with an `x` and a `y`. `Point.at` makes one from two plain numbers, measured from the top left of the picture, with `y` growing downward. The picture is 640 pixels wide and 324 tall.

`Point.at` turns each of those numbers into a `Pixels`, an opaque type around an `F64`, like `Distance`. The ride works in metres on the road and in pixels on the screen, and two types keep the two apart, so each number says which one it is. In a program that moves between the road and the screen all the time, the types earn their keep.

The `fill` is green. `RgbColor.of` makes a color from `0x2e8b57`, a number in hex, as `0x` says: the six digits a web page writes after its `#`, and `Brush.flat` makes a fill of that one color.

A shape only describes. So what paints the triangle? The platform does. The picture is a small Roc app of its own, and it hands the platform a list of two shapes: the background, a rectangle that fills the picture, and then the triangle. The platform paints the list from first to last, so the triangle lands on the background.

### A rectangle

Next, a rectangle:

```widget shapes rectangle
A brown rectangle on a plain background.
```

{{code ShapesWidgetApp.brown_rectangle}}

Look how closely the rectangle's structure echoes the triangle's, as it should:

| | The triangle | The rectangle |
|---|---|---|
| Its type | `Shapes.Shape` | `Shapes.Shape` |
| What builds it | the `Triangle` tag | the `Shapes.rectangle` function, which gives back a `Quad` |
| Where it is | three corners, each from `Point.at` | a top left corner from `Point.at`, and a width and a height from `Pixels.of` |
| Its fill | `Brush.flat(RgbColor.of(0x2e8b57))`, green | `Brush.flat(RgbColor.of(0x8b5a2b))`, brown |

Here's the function:

{{code Shapes.rectangle}}

`|{ top_left, width, height, fill }|` takes the record apart, naming each of its fields. The body works out where the right and bottom edges are, with `plus`, which adds two `Pixels`. Then it gives the quad its four corners, clockwise from the top left. Each side's two corners share an `x` or a `y`, so the sides are always square to the screen.

That's both of a far tree's shapes. Next, we put them together, with functions of our own.

## A far tree

With a triangle and a rectangle in hand, we can build the far tree. This chapter builds it from small functions: the tiers of its crown, a test that pins them, a triangle for each tier, and the order the trunk and the tiers are painted in.

```widget far_tree
One far tree, magnified so that it stands tall in the picture.
```

### Eight tiers

The crown is eight tiers, stacked from the tip down. Each tier is a record of three fractions:

{{code TreeShapes.Tier}}

A `Fraction` is a number from 0 to 1. `top` and `bottom` say where the tier starts and ends, as shares of the crown's height, measured down from the tip. `width` says how wide the tier's bottom is, as a share of the crown at its widest.

The widths start as a list of eight plain numbers:

{{code TreeShapes.tier_widths}}

In a type, square brackets list tags. In a value, as here, they make a list, and every item in a list has the same type. These eight are `F64`s, chosen by eye, from the narrow top tier to the full-width bottom one.

`map` calls a function on each item of a list and gives back a list of the answers. Here we hand it `Fraction.of` by name, and `Fraction.of` turns an `F64` into a `Fraction`, so `tier_widths` is a `List(Fraction)`. `Fraction.of` crashes on a number outside 0 to 1, because a share out of range means the sum behind it is wrong.

### Tops and bottoms

Each tier also needs a top and a bottom. They follow a rule, so another `map` works them out:

{{code TreeShapes.tiers}}

`map_with_index` is `map` with one more thing for the function: the item's place in the list, counting from 0. The function here is written in place, right where `map_with_index` takes it, and it returns a record. Each tier's top is a tenth of the crown lower than the top of the tier above, and its bottom is three tenths below its top, so each tier overlaps the next. `index` is a `U64`, a whole number, and `to_f64` turns it into an `F64` for the division.

### Freezing the tiers

`tiers` is a constant, the same eight records every time the program runs. So we can write all eight down, and have Roc check them:

{{expect TreeShapes.tiers}}

An `expect` is a test. Its body is a `Bool`, and `roc test` runs every `expect` in a program and reports each one that comes out `False`. This one turns each tier into a list of its three numbers, so that the table can be plain numbers. The table is the tiers, written out by hand. Change a width or the rule, and the test reports it.

### A triangle for each tier

A tier is a set of shares. A triangle is corners on the screen. Between the two stands the tree's outline: where its foot lands on the screen, and how tall the tree looks there.

{{code Camera.Upright}}

Three small functions read the crown's place from the outline:

{{signatures TreeShapes.crown_top_y TreeShapes.crown_height TreeShapes.crown_half_width}}

`crown_top_y` gives the tree's tip, `height_on_screen` above its foot. The other two scale the outline's height: the crown's height is a fixed share of the tree's height, and so is its widest half-width, both chosen by eye. Then `tier_triangle` makes one tier:

{{code TreeShapes.tier_triangle}}

It takes the outline and a record, and `|outline, { tier, foliage_color }|` takes the record apart into its fields, as `Shapes.rectangle` did. The body names four constants on the way, `crown_top`, `bottom_y`, `top_y` and `half_base`, and its last expression is the `Triangle`. Like `Distance`, `Pixels` has its own `plus`, `minus` and `scaled_by`. `scaled_by` multiplies a length by a `Fraction`, and `minus` subtracts one length from another.

On the screen, `y` grows downward, as it did in the {{chapter Shapes}} chapter, so `plus` moves down from the tip. The triangle's first corner sits on the tree's middle line at the tier's top. The other two sit at the tier's bottom, `half_base` to either side.

### Painting the tree

The trunk is a rectangle:

{{signatures TreeShapes.trunk_shape}}

Its body works out the trunk's width, its height and its top left corner from the outline, and hands them to `Shapes.rectangle`. Its `finish` says whether the trunk is shaded, which we come to at the end of the chapter.

The order of the shapes matters as much as the shapes. `tree_sprite` produces the whole tree's sprite:

{{code TreeShapes.tree_sprite}}

It takes the tree's setting and a record, and `|{ spot, focal_length, darkness }, { height, foliage_color }|` takes each one apart into its fields.

The body first darkens the foliage and the trunk's brown as dusk falls. Then `tier_inputs_of` works out what every tier needs, the tree's outline among them, once for the whole tree. `inputs.base.forward()` is how far ahead of the camera the tree's foot stands. From that distance, `crown_of` and `trunk_finish_of` choose how much detail the tree gets. For a far tree, `crown` is `Triangles`, and the trunk's finish is `Flat`. The end of the chapter says what nearer trees get.

The last line puts the list together. `[trunk]` is a list of one shape, and `concat` joins two lists into one, so the trunk comes first. The platform paints a list from first to last, so the tiers land on the trunk. Each tier also lands on the tier above it and covers that tier's bottom, which is where the overlap goes. `Sprite.from_shapes` makes the list the tree's sprite.

`tiers.map(...)` makes one shape for each tier, top tier first, with `tier_shape`. A `match` in `tier_shape` reads the crown, and its `Triangles` branch is the far tree's:

{{code TreeShapes.tier_shape from "Triangles =>" to "Triangles =>"}}

`colored_tier` is the tier with the tree's foliage color, so a far tree's tier goes straight to `tier_triangle`. The other branch builds the near tree's tiers, and the end of this chapter says what it does.

### What you're missing

Every tree 200 metres or more ahead of the camera is built this way: 200 metres is `cone_reach`. Nearer than that, the ride builds more. Each tier becomes a cone, which looks round and fattens as the rider passes under it, and the nearest cones are shaded. `crown_of` makes that choice, and `tier_shape` builds the cones.

`round_trunk_reach` is 60 metres. Within it, `trunk_finish_of` gives `Shaded` in place of `Flat`, and the trunk looks round.

Cones take far more work to build, and far off they look just like triangles, so the ride spends that work only where it shows.

So a far tree is a handful of small functions over one list of tiers. The `expect` pins the tiers, each tier becomes a triangle, and one list puts the trunk first and the tiers over it. Every tree beside the road runs through this same code, wherever it stands.

## Types for places

Safari Ride measures a place in two ways: on the road, and from the camera. Each way has types of its own, and this chapter reads them. The next chapter moves every thing beside the road from the first to the second.

### On the road

A place on the road is a `Geom.RoadPoint`:

{{code Geom.RoadPoint}}

`along` is how far the place lies along its segment of road, and `across` is how far it lies from the middle of the road. Each is a type of its own around a number of metres, as `Distance` is:

{{code Distance.Distance from "Distance ::" to "metres = |metres|"}}

{{code Along.Along from "Along ::" to "metres = |metres|"}}

An `Along` counts metres from the start of a segment, and an `Across` counts metres from the middle of the road, growing to the right. The compiler keeps the two apart, so a place along the road always goes where a place along the road belongs.

### From the camera

A place seen from the camera is a `Spot`:

{{code Spot.Spot from "Spot ::" to "}.{"}}

`lift` is how far off the ground the thing stands, and `road_heading` is which way the road runs there. `foot` is where the thing stands in the rider's view, and its type starts from a plain record of two distances:

{{code RiderView.RiderPoint}}

`right` and `forward` count metres from the camera, and a negative `forward` is behind it. A `RiderView.RiderPointAhead` is the same record behind a `::`, and only `RiderView.rider_point_ahead` builds one, from a point in front of the camera. So a spot's foot is always in front of the camera, by construction.

So a place on the road is a `RoadPoint`, and a place seen from the camera is a `Spot`. A thing placed on the road holds the first, and a thing the camera sights holds the second. The {{chapter The pipeline}} chapter follows every thing from one to the other.

## The pipeline

Every frame, every thing beside the road takes the same trip to the screen. In the {{chapter A far tree}} chapter, `TreeShapes.tree_sprite` takes a setting and gives back a tree's sprite. This chapter follows the trip around that function: where the setting comes from, and where the sprite goes. A tree, a cow, a radio tower, the cat, the bird and the truck each start from a place on the road and end as a rendering, a sprite with a depth, in the frame's one list. The `Pipeline` module holds the trip's types and the functions that sight and render, so we call the trip the pipeline.

```widget pipeline
Step 1,529 of the ride, with only what came through the pipeline: its trees, critters and towers, the cat and the truck.
```

Here's the trip:

The pipeline
```dot
digraph pipeline {
  rankdir=TB;
  nodesep=0.6;
  ranksep=0.7;
  node [shape=box, fontname="Helvetica", fontsize=18, margin="0.25,0.12"];
  edge [fontname="Helvetica", fontsize=16];
  finder [label="each kind's\nsighting module"];
  placed [label="Geom.Placed(kind)"];
  sighted [label="Pipeline.Sighted(kind)"];
  refused [label="a refusal:\nOutOfSight"];
  rendered [label="Rendered"];
  list [label="one list,\nfar to near"];
  finder -> placed [label="  gathers the ones\n  on the road ahead"];
  placed -> sighted [label="  is sighted by\n  a Pipeline sighting function"];
  placed -> refused [label="  or refused by it"];
  sighted -> rendered [label="  is rendered by\n  Pipeline.rendering_of"];
  rendered -> list [label="  is sorted by\n  Rendered.depth_sorted_renderings"];
}
```

Each kind has a sighting module, such as `TreeSighting`. It gathers the placed things of its kind on the road ahead, and hands each one to a `Pipeline` function that sights it.

### Placed

The trip starts from where a thing stands on the road:

{{code Geom.Placed}}

`road_point` is the thing's place on the road, a `RoadPoint` from the {{chapter Types for places}} chapter, and `lift` says how far off the ground it stands. `kind` says what the thing is. Its type is the type variable `kind`, so a placed tree is a `Geom.Placed(Conifer)`, and a placed cow is a `Geom.Placed(Billboard)`.

### Sighted

The screen shows what the camera sees. So for each frame, the pipeline sights every placed thing in play, and works out where it stands from the camera:

{{code Pipeline.Sighted}}

The `Spot` is the thing's place seen from the camera, as the {{chapter Types for places}} chapter showed. This `spot` is the one `tree_sprite` took from its setting in the {{chapter A far tree}} chapter.

Some placed things stay off the screen, because a sighting can refuse a thing. The rest of this chapter follows the sightings that are kept.

### Rendered

Each sighting that's kept is rendered by `Pipeline.rendering_of`, which the {{chapter Asking a kind}} chapter explains. It gives back a `Rendered`:

{{code Rendered.Rendered from "Rendered ::" to "of = "}}

A `Rendered` holds a depth and a sprite. The `::` makes it opaque, as it does `Distance`. The sprite is what a kind's `scenery_sprite` gives back from a setting, and the depth is how far ahead of the camera the thing stands. The kind has done its job by now, and it's gone: a tree's rendering and a cow's have the same type.

In a body, as here, `Rendered.({ depth, sprite })` builds a `Rendered` by wrapping the record. Among a function's arguments, as `Billboard.(billboard)` was, the same form takes one apart.

### One list

Every rendering has that one type, so a frame gathers them all in one list:

{{code Scene.scene_renderings}}

A `Scene` holds a list of renderings for each sort of thing, and `join` makes one list of them all. The guard rail along the road makes its own `Rendered`s, as a later chapter shows, and `scene.rails` joins them to the list. `Rendered.depth_sorted_renderings` sorts the list from far to near, and the platform paints it in that order, so a near thing covers a far one.

So every thing beside the road makes the same trip: placed on the road, sighted by the camera, rendered as a sprite with a depth, and sorted into the frame's one list. Its kind rides through the first two types and is gone by the third. The trip can also end early, at the sighting, and the next chapter goes back to that box.

## Refused

Every frame, the pipeline tries to sight each thing on the road ahead, and its sighting functions refuse some of them. A thing behind the camera, a thing the horizon hides and a thing too small to see all stay out of the frame. This chapter is about how a Roc function gives back an answer that can fail, and how that answer travels up through the functions that ask for it.

Here are some things from step 1,529 and what their sightings decide. `right` and `forward` place each thing's foot from the camera, in metres, and a `forward` below zero is behind it. A thing less than 0.4 metres in front of the camera, short of what we call its near plane, counts as behind it too. The road bends, so a tree on a segment far ahead can stand far to one side:

| What it is | `right` | `forward` | What its sighting decides |
|---|---|---|---|
| The cat, frozen in the road | 0.38 | 23.63 | kept |
| The nearest tree, a big green one | 3.45 | 21.63 | kept |
| The nearest tree behind the camera, a gold one | -8.09 | -8.36 | out of sight: behind the camera |
| The nearest tree the horizon hides, a small green one | -1,433.43 | 446.00 | out of sight: below the horizon |
| A big green tree just past it | -1,446.07 | 473.21 | kept |
| The radio tower past the end of the rider's segment | 20.40 | 355.61 | kept |
| The truck | 92.19 | 489.15 | kept |

A small tree far off sinks below the horizon, while a taller one just past it still shows its top. The ride's ground curves on a radius of 100 km, far tighter than the earth's, so its horizon is near. Distance counts the whole way, sideways too: the hidden tree stands about 1,500 metres from the camera. Of the 214 trees on the segments in view, 136 are kept, 30 are behind the camera, and 48 are below the horizon. Those three counts add up to all 214 trees, so at this step every tree the horizon leaves in view also passes the size test, which comes later in this chapter. The table says which test refused each tree. The program itself keeps only the answer that the tree is out of sight, as the code below shows.

Each test lives in its own function, and each function asks the one below it first. A radio tower takes two of the tests, the near plane and the horizon, so here's its stack:

How a refusal travels
```dot
digraph refusal {
  rankdir=TB;
  nodesep=0.6;
  ranksep=0.7;
  node [shape=box, fontname="Helvetica", fontsize=18, margin="0.25,0.12"];
  edge [fontname="Helvetica", fontsize=16];
  horizon [label="Pipeline.sighting_above_horizon_of\ntests the horizon"];
  sighting [label="Pipeline.sighting_of"];
  ahead [label="RiderView.rider_point_ahead\ntests the near plane"];
  horizon -> sighting [dir=back, label="  passes up\n  an Err(OutOfSight)"];
  sighting -> ahead [dir=back, label="  passes up an Err(BehindCamera),\n  renamed OutOfSight"];
}
```

### An answer that can fail

A sighting function's answer is a `Try`, Roc's type for an answer that can fail. A `Try` is one of two tags: `Ok`, holding the answer, or `Err`, holding a tag that says what went wrong. Here's the first sighting function, whole:

{{code Pipeline.sighting_of}}

Its type ends in `Try(Pipeline.Sighted(kind), [OutOfSight])`: a sighting, or `OutOfSight`. The last line wraps the spot and the kind in an `Ok`.

The test itself happens one level down. `RiderView.rider_point_ahead` gives back a `Try` of its own, and the `?` after it decides what happens next. When the answer is an `Ok`, the `?` unwraps it, and `foot` is the point ahead. When it's an `Err`, the `?` ends `sighting_of` right there and gives back an `Err`. So every line after the `?` runs only for a thing in front of the camera, and the body reads as one straight path.

`rider_point_ahead` works on a `RiderPoint`, a bare point seen from the rider, and its refusal says what's wrong with that point:

{{signatures RiderView.rider_point_ahead}}

A sighting's callers need only to know the thing is out of sight. So the `?` has a function after it, `|BehindCamera| OutOfSight`, and the `Err`'s tag goes through that function on its way up. The function's argument is written as the tag itself, a pattern like the ones a `match` lists, and `BehindCamera` is the only tag `rider_point_ahead` gives, so that one pattern covers it.

### A test on top

The next function asks `sighting_of` first, then makes a test of its own:

{{code Pipeline.sighting_above_horizon_of}}

Its `where` line says what the function needs from a kind: its height. The {{chapter Asking a kind}} chapter reads that line. A `Spot` gives its parts through methods, such as `lift()` and `foot()`. The ride's ground curves away from the rider, and `drop()` gives how far it has dropped below level at the thing's foot.

The first line asks `sighting_of`, and its plain `?` passes an `Err(OutOfSight)` straight up. Then the function tests the horizon, and gives back the same tag for its own refusal. So both functions have the same type after the arrow, and a caller treats the two refusals alike.

`Pipeline.scenery_sighting_of` stacks one more test on top in the same way: a thing that would stand under 2 pixels tall on the screen is out of sight too. The trees, the billboards, the cat and the bird take all three tests. A radio tower is kept however small it looks, so it's sighted by `sighting_above_horizon_of`. The truck takes only the near-plane test, so it's sighted by `sighting_of`.

### Where the refusals stop

A segment holds many trees, so its sighting module asks for all of their sightings at once:

{{code TreeSighting.segment_trees}}

`scenery_sighting_of` takes a `camera`, which holds the vantage and the lens's focal length, because its size test needs the lens. `keep_oks` is a `List` function. It calls the function it's given on each item, keeps the `Ok` values, and drops the `Err`s. So `segment_trees` gives back a plain list of sightings, and the refusals stop there.

There's one truck, so `Scene` matches on its answer instead:

{{code Scene.truck_renderings}}

A `match` on a `Try` covers both tags, as any `match` covers every tag. An empty list leaves the truck out of the frame.

### All through the ride

The same kind of answer runs all through Safari Ride, wherever a function can come up empty:

| Job | Function | Its type |
|---|---|---|
{{types row RoutePlace.at_distance Find a place on the route}}
{{types row BirdFlight.flight_from Pick a tree for the bird to fly to}}
{{types row GroundPatch.patch_shape Shape a patch of the road}}
{{types row Camera.clipped_polygon Cut a shape at the near plane}}

Each tag names one way its function can fail, and the ground patch has two.

So a refusal is an ordinary value. A sighting gives back a `Try`, a `?` passes an `Err` up or unwraps an `Ok`, a function after the `?` can rename the tag on the way, and `keep_oks` or a `match` decides where the refusals stop. The kept sightings go on to be rendered. That leaves two questions from the trip, and the next two chapters answer them: what is a kind, and how does `rendering_of`, written once, get a sprite out of every kind?

## Nature types

Every thing beside the road carries its kind through the first two types of the pipeline, a `Geom.Placed` and a `Pipeline.Sighted`. In this chapter we look inside one kind, the tree's.

```widget conifers
The four conifers, left to right: Green, SmallGreen, Red and Gold.
```

A tree needs a height and a color. Where it stands is the job of the forms around it. So the `Conifer` type says which tree it is, and its methods give the height and the color:

{{module Conifer}}

`Conifer` is a nominal type. A nominal type has a name, and Roc treats it as different from every other type, even one with exactly the same shape. Another union of `Green`, `SmallGreen`, `Red` and `Gold` would be a different type, and only a `Conifer` fits where a `Conifer` is expected. Its set of tags is fixed, too: the four the definition lists, and only those.

The module's code shows these Roc concepts:

| Concept | Purpose | Explanation |
|---|---|---|
| A nominal type | Identity | `Conifer :=` gives `Conifer` a name of its own. Roc keeps it apart from every other type, even another union of the same four tags. |
| A tag union | Variants | The backing type, `[Green, SmallGreen, Red, Gold]`, lists every sort of tree a `Conifer` can be, and the list is fixed. |
| Methods | Behavior | Functions inside the type's braces: `scenery_height` and `scenery_sprite`. A value calls one with a dot, as in `conifer.scenery_height()`. The next chapter shows why they sit inside the braces. |
| Privacy | Hiding | Everything outside the braces stays private to the module: the heights, the colors and `foliage_color`. A call names a private function plainly: `foliage_color(conifer)`. |
| One branch, two tags | Grouping | In a `match`, `Green \| SmallGreen =>` gives both greens one color. |
| Equality | Comparison | `is_eq : _` asks the compiler to write `==`, as it did for `Distance`, and here `==` compares tags. |

`scenery_sprite` hands the height and the color to `TreeShapes.tree_sprite`, the function that produces the far tree's sprite. A module's definitions can come in any order, so the methods use values defined below them.

So a kind describes a thing, and the pipeline does the rest. But the pipeline is one piece of code for every kind alike. So how does it get a height and a sprite out of a `Conifer`?

## Asking a kind

One function, `Pipeline.rendering_of`, renders every kind of thing beside the road. Here it renders five of them:

```widget kinds
A tree, a cow, a radio tower, the cat and the bird, each rendered by `Pipeline.rendering_of`, and each at its own distance so that it shows clearly.
```

One function can render every kind because of this chapter's new Roc idea, the `where` clause, which constrains a type variable to types that have certain methods.

`rendering_of` takes a sighting, with the focal length and the darkness that the whole frame shares, and it gives back a `Rendered`, the thing's sprite and its depth. The sprite comes from the kind, so `rendering_of` calls the kind's own `scenery_sprite` method.

The `Rendered` coming out is the same type for every kind. The sighting going in carries its kind: it's a `Pipeline.Sighted(kind)`, and `kind` is a type variable, so it stands for any type at all: a number, a record or a `Conifer`. Only some types have a `scenery_sprite`. So `rendering_of` needs a constraint on `kind`: any type, as long as that type has a `scenery_sprite`.

Roc writes that constraint as a `where` clause, on the line after the annotation:

{{code Pipeline.rendering_of}}

This table explains the code's concepts:

| Concept | Purpose | Explanation |
|---|---|---|
| A type variable | Generality | `kind` in `Pipeline.Sighted(kind)` stands for whatever type the caller's sighting holds. |
| A `where` clause | Constraint | `where [kind.scenery_sprite : kind, Sprite.Setting -> Sprite]` constrains `kind` to types that have a method named `scenery_sprite`, which takes a `kind` and a `Sprite.Setting` and gives back a `Sprite`. The square brackets hold a list of constraints, here just one. |
| A method | Placement | A method is a function inside a type's braces, and only a method meets a `where` clause. That's why `Conifer` keeps `scenery_sprite` inside, with `scenery_height`, while its private helpers sit outside. |
| A method call | Dispatch | `sighting.kind` is the sighting's `kind` field, which holds a value of the type `kind`. `.scenery_sprite(...)` calls that type's method, with the value before the dot as its first argument. |

The rest of the body builds the setting. A `Sprite.LensAndLight` holds the shared part of a `Sprite.Setting`, the focal length and the darkness, and the body adds the sighting's own spot. `sighting.spot.foot().forward()` is how far ahead of the camera the thing's foot stands.

### The compiler checks each call

Each call to `rendering_of` fills `kind` with one particular type. The ride renders its trees in one line of `Scene.scene_in_view`. There `trees_seen` is a `List(Pipeline.Sighted(Conifer))`, so the type is `Conifer`:

{{code Scene.scene_in_view from "trees:" to "trees:"}}

The compiler looks inside `Conifer`'s braces, finds a `scenery_sprite` of the right type, and the call compiles. The compiler checks every other call the same way, one type at a time. So the choice of which `scenery_sprite` runs is made when the program compiles, once for each type. Every call gives back a `Rendered`, whatever the kind, so a frame's renderings of trees, cows and towers all go in one list.

Every type that fills `kind` has to pass the compiler's check. Here a `Rock`, a kind that is just one tag, is handed to `rendering_of`. The program is a small app of its own, which uses Safari Ride's modules as its `game` package. Only `Rock` and `rock_rendering` matter here. The rest makes the program an app, and the `_` names an argument that `main!` leaves unused:

{{fails kind_without_sprite}}

The message names the method the clause requires, and the type the compiler checked. The fix is a `.{ }` after `Rock`'s tags with a `scenery_sprite` inside, as `Conifer` has.

### Asking for a height

Sighting a thing needs its height. A far thing shows only when its top clears the horizon, and only when it stands tall enough on the screen to be worth showing. So `Pipeline.scenery_sighting_of`, which sights the trees, the billboard critters, the cat and the bird, constrains its kind with a `where` clause of its own, to types that have a `scenery_height`:

{{code Pipeline.scenery_sighting_of from "where" to "where"}}

### Names that say what they're for

Roc matches a `where` clause by the method's name and type alone. Suppose the clause named a method called just `height`. The bird could well have one that says how high it flies, and the sighting would test the bird against the wrong number, while the compiler stays quiet. So every method the pipeline's clauses name starts with "scenery", which makes an accidental match unlikely.

So a kind meets the pipeline with two methods inside its braces, `scenery_height` and `scenery_sprite`. The tree, the cow, the radio tower, the cat and the bird each have both, and the compiler checks both methods of every kind when the program compiles.

That finishes how a thing beside the road reaches the frame. The rest of the frame is the world the things stand in, and the next chapters build it from the ground up.

## Grass

The ground under the things beside the road is grass, and it's the simplest part of the ride: one rectangle. Here's step 1,529 with only its trees and the grass under them:

```widget frame grass
Step 1,529 of the ride: its trees, and the grass they stand on.
```

The horizon on the screen is the line halfway down it, where a level look from the rider lands. The grass fills the screen below it, and the rest of the frame, the mountains, the road and the things beside it, covers the grass. So the grass shows wherever the rest of the frame leaves it uncovered, and that one rectangle is all the grass code the ride needs.

The `Grass` module holds the grass's color by day, as a constant:

{{code Grass.grass_color}}

A constant in a module carries an annotation, as a function does, and here the type is an `RgbColor`. Like `Distance`'s functions, the `Grass` module's sit inside the braces of a type named for the module, so other code calls this one `Grass.grass_color`. `0x4A8F43` is the color in hex, the way a web page writes it after a `#`.

As the sun sets, the grass darkens with the sky:

{{code Grass.grass_color_at}}

`Sky.color_at_darkness` takes a color by day and how dark the sky is, and returns the color dimmed to match. Everything the sky lights dims through it, from the grass to the truck.

The grass's top edge sits one pixel above the horizon:

{{code Grass.grass_top_y}}

`Screen.horizon_y` is the horizon, and `y` grows downward, so `minus` one pixel moves the edge up. The sky, in the next chapter, is painted before the grass and stops at the horizon, so the grass's top row covers the sky's last one and the two always meet.

Here's the rectangle itself:

{{code Grass.grass_shape}}

When the bike leans, the camera rolls with it, and the whole frame turns about the middle of the screen. A rectangle the size of the screen would turn with it and leave its corners bare. So `Screen.margin_rect` makes a rectangle from a top and a bottom that reaches `Screen.roll_margin`, 200 pixels, past each side of the screen, and the grass reaches 200 pixels below the screen too. That covers a lean of up to 30°, more than the ride ever leans.

That rectangle is all the grass there is. The sky goes above it, in the next chapter.


## The sky

Above the grass is the sky, and in a frame the sky is two colors: one at the top of the frame and one at the horizon, with a fade between them. At step 1,529 the two happen to match, for a reason the end of this chapter gives.

```widget frame sky
Step 1,529 of the ride: the trees, the grass, and the sky over them, one day blue.
```

A frame asks the `Sky` module for both colors at the ride's clock, and gets them back as one record:

{{code Sky.colors_at}}

`Sky.Colors` is a record of two `RgbColor`s, `top` and `horizon`. Each color has a function of its own.

### The top of the sky

The top of the sky blends from day into night, by how dark the sky is:

{{code Sky.sky_top_color}}

`day_sky` and `night_sky` are two constants in the module, a pale blue and a deep one. `Sky.darkness_at`, which the {{chapter Functions}} chapter took apart, says how dark the sky is, as a `Fraction`. It sits inside the `Sky` type's braces, so even its own module calls it by its full name, and the bare names belong to the module's helpers outside the braces. `ColorShade.color_between` does the blending:

{{code ColorShade.color_between}}

It takes one record, so every call names its three fields. A color is three channels, its red, green and blue, and each channel moves the same share of the way from `from` to `to`. `blend` is a function named inside the body, and it takes a function as its argument: `RgbColor.red`, say, which reads one channel of a color. The last line calls `blend` once for each channel. The share is a `Fraction`, which its type keeps between 0 and 1, so `color_between` can trust it.

### The horizon

The horizon has the top's color, warmed toward red while the sun is near it:

{{code Sky.sky_horizon_color}}

`Sky.horizon_warmth_at` says how near the sun stands to the horizon, as a `Fraction`, and `horizon_warmth_at_most` holds the warmest horizon to 85% of the way to `sunset_red`, so a little of the sky's own color still shows.

### The fade

`Sky.sky_shape` paints the two colors as one shape:

{{code Sky.sky_shape}}

`Screen.above_horizon_rect` is the rectangle from above the top of the screen down to the horizon, 200 pixels past each side, as the grass's rectangle is. A fill is a tag union, `Brush.Fill`, and `Brush.flat` makes its plainest tag, one color. This fill is its `Linear` tag, whose color fades along a line, from `start_point` to `end_point`. Both points sit at `x` zero, so the line runs straight down, from the top of the screen to the horizon. Its `stops` say where along that line the fade begins and ends: it holds the top color for the first fifth of the way, `sky_top_stop`, then reaches the horizon's color at the end. The platform works out every color in between. `Brush.opaque_rgba` makes each color fully solid.

Every function here works from the clock alone, or from colors worked out from it. So the sky at step 1,529 is the same on every run of the ride. At that step the sun is still high: the sky is near its day color and the horizon has yet to warm, so the two colors match and the picture shows one pale blue. The second half of the book turns the clock to watch them part. One more part of the frame darkens with it: the mountains.

## Mountains

However far the rider goes, the mountains stay as far away as ever. They only turn as the rider turns. So the ride treats them as far scenery: a mountain is just a height at a direction.

```widget frame mountains
Step 1,529 of the ride: the trees, the grass, the sky, and the mountains along the horizon.
```

There are two ranges: a high one to the north, with snow on its peaks, and a lower one to the west. In front of both runs a band of low, rolling land, in the grass's own green.

### Directions

A direction needs a type, and so does a change of direction. `Angle.Bearing` is a direction in the world, such as north, and `Angle.Turn` is how far to turn from one direction to another. Both are opaque types around one float, and only the `Angle` module builds or opens them. Here a `Turn` is passed where a `Bearing` belongs:

{{fails turn_as_bearing}}

The compiler refuses it. A bearing plus a turn is a bearing, and the turn from one bearing to another is a turn, and the `Angle` module's functions keep the two apart everywhere.

### A range

A range is a record:

{{code Skyline.MountainRange}}

Its `center` is the bearing of its middle, and `half_width` is the turn from the middle to either end. `height_ceiling` is how high above the horizon it reaches at most. The two wave counts shape its ridges. A range's height at a bearing comes from one function:

{{signatures Skyline.range_height}}

The range is highest in its middle and falls to zero at its ends, and two waves on top of that make its ridges, with their sizes tuned by eye. The rolling land is a little under one wave of its own, all the way round.

### Across the screen

To paint a range, the ride goes across the screen two pixels at a time, and asks which bearing each column looks along. The middle of the screen looks along the camera's heading, and a column to its right looks a little further right, by a turn the lens decides. A column is a record:

{{code Skyline.SkylineColumn}}

A silhouette is one flat region whose top edge follows the heights along the columns. One function paints a silhouette, whichever range or land it is:

{{code Skyline.silhouette}}

The record it takes has a field that holds a function: `height_at`, which says how high the silhouette stands at a column. A function is a value like any other, so it can sit in a record field. `silhouette` calls `height_at(column)` for each column and finds where that height lands on the screen with `Lens.y_for_height`. A mountain is so far off that its distance drops out: how high it looks depends only on its height above the horizon and the lens. Then `silhouette` joins the tops into one region closed along `base_y`, which is the grass's top for the ranges and the horizon for the land. The `if` keeps the top from dipping below `base_y`.

### Back to front

`Skyline.skyline_shapes` calls `silhouette` three times, with a different `height_at` each time, and paints the results back to front: the west range, the north range, the north's snow, then the land:

{{code Skyline.skyline_shapes}}

`aim` is the camera, as far as the skyline needs it. The `..` in its type, `{ heading : …, focal_length : …, .. }`, means the record may hold more fields, and this function reads just these two.

Each `height_at` is an anonymous function written in place. The west range's asks `west_range_height` for the column's bearing. The north range's reads the height the column already holds, since the snow needs it too. The land's asks `land_height`. The snow is a `Try`: when too little of it shows on the screen, it's `Err(NoSnow)`, and the `match` gives an empty list.

At dusk the rock darkens through `Sky.color_at_darkness`, as the grass does, and the land takes the grass's own color. The snow goes blue, through the same blend the sky uses:

{{code Skyline.snow_color}}

That's the far scenery: it turns with the rider and stays where it is. Next comes the road.

## The road

In front of the mountains, the road comes nearer as the rider rides. It's ground, laid on the grass in front of the mountains and under everything beside the road.

```widget frame road
Step 1,529 of the ride: the road, over the grass and under the trees.
```

The ground comes in patches, and a patch is a list of corners on the ground and a color. The road's patches all come from one function:

{{code GroundSighting.road_patch}}

Each corner is a `RiderPoint`, a point on the ground seen from the rider, so the `GroundPatch` module can find where each corner lands on the screen and paint the patch there.

### A segment's ground

The route is a chain of straight segments with a bend between each one and the next. Each segment in view lays its own ground, with one function:

{{code GroundSighting.ground_patches from "ground_patches : RoadAhead.RoadView," to "].join()"}}

A segment lays up to three things: the road along it, the paving at its bend into the next segment, and a pond if it ends at one. Each comes as a list, and `join` makes them one. The two `match`es leave a part out by giving an empty list. The segment just behind the rider can still show its last stretch, and its bend's paving lays that stretch, so its own road list is empty. The last segment of the road ahead gets an empty list for its bend, `RoadEndsInView`, since the road in view ends there.

### Along a segment

The road along a segment is one patch:

{{code GroundSighting.road_along}}

`corner` is a function named inside the body. It uses `road`, `vantage` and `from_rider` from around it, so each call names only a chunk and an edge. A function that uses names from around it like this is a closure.

The patch starts at the left corner of the segment's start, runs up the right edge to the end of every chunk, and comes back down the left, so its corners go round in order. That's why the right edge counts one corner more than the left: the left's first corner is already the patch's first. `U32.until(0, n)` counts from 0 up to just short of `n`, and `List.from_iter` collects the count into a list of chunk numbers.

The edges are cut into chunks of at most `road_chunk_length`, 25 metres. The ride's ground curves away from the rider, on its 100 km radius, and a straight edge any longer would part from the curve by more than a pixel near the horizon.

All of a segment's chunks share one patch. The platform smooths each patch's edges on its own, and where two patches met, the grass would show through as a pale seam.

### At a bend

Where one segment bends into the next, the two roads leave a gap on the outside of the turn. Here are three bends, seen from above:

```widget bends
Three bends from above. The off-white dot is where the view is from, the orange lines are the guard rails, and the yellow dot is each bend's apex, where the two roads' outer edges meet.
```

The paving fills the bend's outer corner. The `BendInView` module works it out, one step at a time:

| Job | Function | Its type |
|---|---|---|
{{types row BendInView.outer_edge Find the outer edge}}
{{types row BendInView.outer_corner Find the corner, on the road}}
{{types row BendInView.outer_corner_in_view See the corner from the rider}}

A bend to the right has its outer edge on the left, so the paving changes sides as the road turns. An outer corner is three points: where the first road's outer edge ends, where the next road's outer edge starts, and between them the apex, where the two outer edges, carried on straight, cross. `OuterCorner` takes the kind of point as a type variable, so the same record holds road points first and rider points after.

`GroundSighting.bend_paving` lays the corner as one more patch. It starts 40 metres before the bend, `lead_in_length`, runs up the left edge, across the end of the next road's first chunk, and back down the right, and whichever side is outside the turn takes in the corner's three points. Both roads end inside the paving, so road lies over road where they meet, and the patches join cleanly. Since the paving lays the last 40 metres of the road before the bend, it stands in for the road along the segment just behind. Forty metres is enough, because only a bend sharper than a right angle would show road further back, and every bend on the route is gentler than that.

The ponds are ground too. A segment that ends at a pond lays two more patches, its bank and then its water.

The corner has its paving. Next, each bend gets a rail around its outside.

## Rails

At each bend, a guard rail runs along the outside of the turn: a metal bar half a metre up, on thin posts. It's the first part of the road itself that stands up off the ground.

```widget frame rails
Step 1,529 of the ride: the road, with its guard rails at the bends ahead.
```

The rail follows a path on the ground. It runs along the road's outer edge for the last 10 metres before the bend, out to the apex, back to the next segment's outer edge, and on along it for 10 metres more:

The path of a guard rail
```dot
digraph rail {
  rankdir=TB;
  nodesep=0.6;
  ranksep=0.6;
  node [shape=box, fontname="Helvetica", fontsize=18, margin="0.25,0.12"];
  edge [fontname="Helvetica", fontsize=16];
  up [label="runup_points:\nthe last 10 metres\nbefore the bend"];
  out [label="leg_points:\nout to the apex"];
  back [label="leg_points:\nback to the next\nsegment's edge"];
  on [label="runout_points:\nthe first 10 metres\nafter the bend"];
  up -> out [label="  turns out"];
  out -> back [label="  turns back"];
  back -> on [label="  runs on"];
}
```

### From path to quads

`RailSighting` finds the rail at every bend in view:

{{code RailSighting.rail_quads_in_view}}

`join_map` maps each segment in view to a list, here the quads of its bend's rail, and joins the lists into one. For each segment with a bend after it, `rail_points` finds the path, and `GuardRail.quads_along` cuts it into quads. The path joins four lists, one for each box of the diagram:

{{code RailSighting.rail_points}}

The first line takes apart the record that `outer_corner_in_view` returns, naming its three fields, the corner from the road chapter. A leg between two of them gets a point about every metre:

{{code RailSighting.leg_points}}

The points are about a metre apart, and a post will stand at each one. `drop_first(1)` leaves out a leg's first point, `from`, because that's the last point of the leg before it.

### Bars and posts

`GuardRail.quads_along` turns the path into flat pieces with four corners each: a bar between each two neighbouring points, then a post at each point. A piece is a record:

{{code GuardRail.RailQuad}}

Its corners are `PointAtHeight`s, points seen from the rider at a height measured from the rider's own level, so a bar's top corners stand higher than its bottom ones. Where the ground has curved away, that height can be below zero.

Each quad goes into the frame's depth sort on its own, at a depth that's the mean distance of its corners, so a tree can stand in front of one post and behind the next. A quad holds only its corners and a color, so it makes its own rendering, where the things beside the road go through `Pipeline.rendering_of`:

{{code GuardRail.quad_rendering}}

`{ ..quad, color: … }` is a record update: a new record, like `quad` with its `color` changed, and `quad` itself stays as it was. Here the new color is the quad's own, dimmed with the sky. `map_ok` works on a `Try`: it applies its function to an `Ok` and leaves an `Err` as it is, so a quad wholly behind the camera stays refused, and `Scene` drops those with `keep_oks`.

The ride works out each rail afresh every frame, its bars and posts from the route and the rider, and the depth sort places each one. Next come the radio towers, which go back through the pipeline as things beside the road.

## Radio towers

The radio towers are the tallest things beside the road: lattices of thin rods, 80 metres high, standing well back from it. One stands past the end of every segment, off to the right, and a long segment has one more halfway along, off to the left.

```widget frame towers
Step 1,529 of the ride: the road and its rails, with the radio towers standing back from it.
```

A tower raises two problems of its own. Far off, it should sink below the horizon from the bottom up, as the ground curves away under it. Up close, it can stand partly behind the camera. The chapter takes them in that order, after the tower's place by the road.

### Where a tower stands

A tower is two facts: its yaw, which way its square footprint is turned, and its beacon, the light at its top:

{{code Tower.Tower from "A tower in a frame" to "Tower :: {"}}

Trees get their places once, when the world is built. A tower's beacon blinks with the clock, so its sighting builds the tower afresh each frame, from its segment and the clock. Here's the tower past a segment's end:

{{code TowerSighting.end_tower}}

It turns the tower to face the road where it ends. The tower halfway along is the same, with its footprint square to the road, a `Midway` beacon, and one more way to fail: `mid_tower_point` gives `Err(NoMidTower)` for a segment of a kilometre or less. Where towers stand has one home, `TowerSighting`, and the world itself holds only the segments.

### Over the horizon

The ride's ground curves away on its 100 km radius, and a tower stands on it. From the rider's eye, 1.2 metres up, the ground curves out of sight 490 metres out. Past that horizon, the lowest thing the rider can see lies on the line from the eye that grazes the ground there. One function finds that lowest height at any point on the ground:

{{signatures EarthCurve.lowest_visible_height}}

The ground hides whatever part of a tower is under that line, so as a tower gets further away, it sinks from the bottom up. An 80-metre tower still shows its tip about 4.5 km off. Once all of it is under the line, `Pipeline.sighting_above_horizon_of` refuses it as `OutOfSight`, as the {{chapter Refused}} chapter showed. So a sighted tower always has something to paint.

### Rods

A tower is drawn as a few dozen rods and a disc for its beacon, by `Tower.tower_shapes`. It starts with one check:

{{code Tower.tower_shapes from "if hidden_on_tower(geometry) >= tower_height" to "a tower hidden wholly below the horizon"}}

Its sighting has already refused a tower the horizon hides wholly, so here that case is a `crash`: a stop with a message, for a case that would be a bug. Otherwise come the legs, the rings and the braces, and the beacon's disc last, at the top.

A tower's footprint is a square, and four tags name its corners. Going round the square is a `match`:

{{code Tower.next_corner}}

Four legs run from the corners up to the top, each starting at the height the horizon hides. Every 20 metres up, a ring of four rods joins each corner to the next one round, and crossed braces fill the lowest two storeys.

Each rod is a line between two points seen from the rider. A near tower is wide, so its foot can stand ahead of the camera while a corner of its footprint stands beside or behind it. So each rod goes through this function:

{{code RiderView.line_ahead}}

The `match` is on a pair, `(start, end)`, so it covers all four combinations of its two `Try`s. A rod with one end short of the near plane, 0.4 metres ahead of the camera, is cut where it crosses that plane. A rod with both ends behind it is refused.

That's a tower: rods and a disc, worked out again each frame from its segment, the clock and the camera. The disc on top blinks, and the blinking waits for the second half, when the clock starts.

## Stills

The cows of the {{chapter Things}} chapter and the bend animals after it are drawn from stills, and this chapter opens one up. Every animal in Safari Ride is drawn from a still: a small picture made of filled polygons, stored as data. The cow and the elephant each have one still. The cat has seven, one for each pose, and the bird has six. Those two wait for the second half, when things move, but their stills are pictures like any other, and here they are:

```widget stills
Every pose of the cat and the bird. Click one to see it large, and click it again for its polygons.
```

Animating a critter comes down to choosing which still to show, and where.

### A still is data

A still is a list of polygons, in the order they're painted. A polygon is one record:

{{code Still.Polygon}}

Its fill is one flat color or a gradient, and its points are its corners. The animals by the road started as emoji, and the `EmojiStill` module holds one still for each. The cat and the bird were drawn for this ride, and their stills have poses. The bird's perched pose is Roc's own logo, made of a few straight-edged shapes, so the bird has very few points. The cat's curves are many short straight lines, so it has far more.

Every point is measured in units of the still's height. Its feet are at `y` 0, and a standing critter is about 1 tall. So a still is free of pixels and metres, and the same numbers draw a cat in the distance and a cat in the lane.

### Putting a still on the screen

The `StillShapes` module does the rest. An `Anchor` says where a still stands on the screen, which way it faces, and how tall it is there:

{{code StillShapes.Anchor}}

Drawing a still is then one small sum for each point. `screen_vector` scales the point by the height on the screen, mirrors it if the still is flipped, and turns its `y` over, since a still's `y` grows upward and the screen's grows down. Then the foot places it:

{{code StillShapes.screen_point}}

A billboard's sprite is its still, drawn this way, at the height its spot and the lens give it. A critter with poses picks its still with a `match` on its pose, and the second half of the book does that.

### How the stills got made

The stills are the least readable code in Safari Ride, because programs generated most of them. They're generated data, encoded as Roc, and here's where they came from.

At a larger company, a picture like these would pass through three people. An artist would draw it. A software developer would build the tools that get it into the game. A project manager would look at the result and decide whether it's good enough. On Safari Ride, Claude, the AI that wrote its code, played the first two roles, and Steve, who made the ride, played the third.

The artist's cat was a program. An early version of Safari Ride drew the cat in TypeScript, with splines for its body, tapered capsules for its limbs, chains of joints for its legs, and strokes for its whiskers. That's a lot of code to carry from language to language, and the ride only ever shows seven poses.

So the developer wrote a baker, a small program that ran the real drawing code once for each pose. A recorder stood in for the canvas. It kept every filled shape as a polygon and turned every stroke into a thin filled quad, and the result was a flat table of polygons. The drawing code stayed behind, and the table moved on.

The emoji-based animals took a different route. They come from Microsoft's Fluent Emoji, in its Flat style. That set draws every animal whole and from the side, where another set draws a rhino as a face, which looks wrong beside a road. A second baker read each SVG file, walked its shapes in painting order, and cut each curve into short straight lines.

The bull is a hybrid. It comes from the same emoji set, but in its Color style, which is shaded. It's the one still with gradients, which is why a polygon's fill can be `Shaded`.

The Roc bird came last. Its perched pose is the logo, and Claude drew the five flight poses to match, directly as polygons, in the logo's two purples.

The project manager's tool was a contact sheet: every still, side by side, in one image. Each bake wrote one, and Steve looked at it. A cat looking like a cat is a judgment for eyes, and the comment in the emoji baker puts the standard well: "an elephant is an elephant".

The bakers belong to the older versions of Safari Ride, in TypeScript and Zig. The polygons they made have been carried along ever since, which is why these files look like generated data. They are. The next chapter puts many stills on the grass at once: the herds.

## Herds

The farms along the road are crowds of billboards: herds of cows on the left, herds of pigs on the right. A herd is just a list of placed billboards, and its module lays the animals out whenever it's asked.

```widget frame critters
Step 1,529 of the ride: the whole still frame so far, now with its herds and the animals at the bends.
```

### Cows

The world stores a cow herd as two counts: how many cows, and how many rows stand behind the front one. The route's herd is fourteen cows, in columns of three:

{{code CowHerd.herd_cows}}

`U64.until(0, cow_count)` counts the cows, and each number becomes a cow. A bull, if the herd has one, goes at the front of the list.

A herd in a perfect grid would look like a parking lot, so each cow strays a little from its place:

{{code CowHerd.herd_cow}}

The cow's number picks its column and its row: `div_trunc_by` divides and drops the remainder, and `rem_by` keeps only the remainder. Each row stands a little further along the road than the one in front of it, and further from the road. Then `Scatter.stray_of` moves the cow a little, along and across. The stray is worked out from the cow's number, so it looks random but comes out the same on every run, and every frame of the ride stays exact. The last expression is the placed cow: a place on the road, a lift of zero, and the billboard `cow_billboard` picks, a calf for every fourth cow.

### Pigs

A pig herd has two shapes, as a tag union:

{{code PigHerd.herd_pigs}}

The first two herds of pigs are big, seven rows of seven, and the rest are two short rows. A `BigHerd` carries its sizes, and `TwoRows` is a plain tag, so the `match` hands each shape to its own function. In the first two herds, one pig stands out from the rest and catches the rider's eye, and the rider's chapters in the second half come back to it.

`BillboardSighting` sights every herd's billboards, as the pipeline sights any thing beside the road.

That's every animal that stands still. Everything in the frame at step 1,529 now has its chapter, except the things that move: the cat, the bird and the truck. The first half of the book ends here: one frame, built part by part, from the things beside the road to the world they stand in. The second half turns the pages.

## A flip book

The first half of the book held one page still, step 1,529, and built it part by part. Now the pages turn. The picture below holds a real ride. The bar is the whole route, with the rider and the truck as two dots on it, and the lines of text read out the clock, the rider and the truck. The figure under the bar is the rider seen from behind, which the rider's chapters come back to. Press play and let it run for a moment. Press play again to stop it, then press the step-back button a few times.

```widget step
Press play, press it again to stop, then step back.
```

The ride steps back one moment at a time, as easily as it went forward. That ease comes from how Roc values work, and it starts with a puzzle. A Roc value stays exactly as it was made, yet the ride is change from start to finish.

The answer is in the flip book from the {{chapter One page}} chapter. Each page is a still drawing, and the motion comes from the flipping. In Safari Ride, each page is a moment, a value of the `RideInstant` type, and one function makes the next one:

{{signatures RideInstant.next_or_restart}}

It takes the road and a moment, and returns a tag union written in place: the next moment, tagged `Continued`, or the ride's first moment again, tagged `Restarted`, once the rider reaches the end of the road. Either way, it returns a new moment and leaves the old one as it was.

The platform does the flipping. Thirty times a second it asks the app for its next state, and while the ride plays, the app moves on to the next moment through `next_or_restart`. Then the platform paints that moment's picture, which `FrameView.frame_view_at` works out from the moment and the road. The picture above flips much faster than that, to cover more road. The same moment always gives the same picture, so any page can be held still and studied, as the first half did with step 1,529.

### Turning back

Every old moment stays as it was made, so the ride keeps the ones since it last started, and stepping back turns to an earlier page. Here's the function behind the step-back button you just pressed:

{{code Tour.step_back}}

A `Tour` holds the moment on show, and a list of the moments before it. `Tour.(tour)` opens the tour to read its fields. `step_back` takes the last moment off that list and puts it on show, with a record update: `{ ..tour, instant: previous_instant, past_instants }` is a new tour, the same as `tour` but for those two fields. The old tour stays as it was.

### What a moment holds

Here, once more, is everything a moment holds:

{{code RideInstant.RideInstant from "RideInstant := {" to "}.{"}}

That's four things: the rider, the truck, the clock, and the plan for when the cat or the bird ahead starts to move. The ride carries those four from step to step, and derives everything else in a frame from them and the road. The chapters ahead take the four in turn, starting with the simplest: the clock.

## The clock

A moment's clock says which step of the ride this is. It's a single number, and it still gets a module of its own, because the ride keeps two kinds of time apart.

### A moment and a length

Everyone knows what a clock does. The news is what this one refuses to do. Here's a line that adds 7 to a clock:

{{fails clock_plus_seven}}

The compiler refuses it. `+` calls the `plus` method, and `Clock.plus` takes a `Steps`, a count of steps, where this line hands it a bare 7. A `Clock` is a moment, and a `Steps` is a length of time, as a `Bearing` is a direction and a `Turn` is a change of one.

Here's the whole module:

{{module Clock}}

`Clock :: U32.{ … }` makes a clock an opaque `U32`, so only the module's own functions read the number inside. They keep the two kinds of time apart:

| Function | Takes | Returns |
|---|---|---|
| `plus` | a clock and a length | a later clock |
| `minus` | a clock and a length | an earlier clock |
| `steps_since` | two clocks | the length between them |

Two moments make a meaningless sum, so the module leaves adding two clocks out. `next` moves a clock on by one step, and the ride calls it once a step.

### Two crashes

`minus` crashes when it would go back past step 0, and `steps_since` crashes when it would count backward. Either one means the caller has a bug, so the clock stops the program and says why, with a `crash` and its message.

### Tests

Below the module's braces, each `expect` is a test, and `roc test` runs them all. A clock is a plain value, so a test builds one directly: `Clock.at_step(9).plus(Steps.of(3))` starts at step 9 and checks the answer is step 12, before any ride has run. The last three tests check `<` below, at and above the line: one clock before another, a clock against itself, and one after. `!` flips a `Bool`, and `length.to_u32()` reads the number inside a `Steps`.

The clock is the whole of the ride's time of day. Everything that follows the time of day, from the sky to the truck's headlights, works it out from the clock. The next chapter turns to the moment itself, the `RideInstant`, and how one step moves all four of its parts on.

## The ride instant

A moment carries four things: the rider, the truck, the clock, and the plan for when the cat or the bird ahead starts to move. A step makes the next moment from this one. This chapter reads that step, and sorts the ride's moving parts by how they change.

### One step

Here's the step, whole:

{{code RideInstant.next}}

`next_or_restart`, from the {{chapter A flip book}} chapter, calls this step until the rider reaches the end of the road. Its doc comment gives the order, and the order matters. The rider moves first, reading where the encounter ahead has got to. Then the clock ticks. Then the world answers the rider who has just moved: the truck aims at how far along the route the rider now is, and the encounter plan is kept, dropped at a new segment, or made from this step's rider. The last line puts the four together into the next moment, and the old moment stays as it was.

### Carried and derived

Those four fields are all the ride carries from one step to the next. Everything else in a frame is derived from them and the road, worked out again each time. So the ride's moving parts come in three kinds:

| Kind | Things | How it changes |
|---|---|---|
| Clock-driven | The sun's height, the sky, the beacons | Derived from the clock, and for a beacon its tower |
| Stepped | The rider, the truck | Carried in the moment, and moved once a step from where it was |
| Rider-driven | The cat, the bird | Derived from the clock and the carried plan, which the rider's approach sets |

The trees and the cows stay put, which is easiest of all. The chapters ahead start with the clock-driven kind, the simplest.

### Pure functions

A Roc function with effects, such as reading a key or the time, has a name that ends in `!` and the thick arrow `=>` in its type, between what it takes and what it returns. (A `match` branch's `=>` is another use of the same symbol.) Every function in the ride's own code is pure instead: it works out an answer from what it's given, with the thin arrow, and the effects live in the platform. So the same moment always gives the same next moment, and the same picture.

### Pausing and stepping

Mostly, Safari Ride is a screensaver: you sit back and watch it. You can also take the controls. Click the ride to give it the keyboard, and Space pauses it. While it's paused, Right moves a step forward and Left a step back, one each frame while the key is held. While it's running, each moves four steps at a time. J jumps to the next segment of the road, and R starts the ride over, running.

One function handles all of that. It takes the model, which is the tour and whether it's paused, and a snapshot of the input, and returns the next model:

{{code SafariApp.model_at_next_step from "motion = if input.key_pressed(KeySpace)" to "m.tour.step_forward()"}}

Each frame, the platform hands the app a snapshot of the keys, and the app reads it. `key_pressed` says a key went down since the last frame, so one tap of Space pauses the ride once. `key_down` says a key is held, so holding Right keeps the ride moving. Reading the keys is the platform's effect, and the app sees only the snapshot, a plain value.

The clock-driven things come first, and the beacons are the simplest of them: they follow the clock alone.

## The beacons

Every radio tower has a beacon on top, and the beacons blink. A beacon is the simplest moving thing in the ride: how bright it is depends only on which beacon it is and the clock.

```widget beacon
Press play and watch the two towers blink out of step.
```

The picture stands two towers side by side, with beacons that blink opposite each other, and plays two whole blinks, from step 5,400 to step 5,640.

### Three rules

A beacon follows three rules:

1. A blink takes 120 steps, from dark up to full brightness and back down.
2. Neighboring towers start their blinks at different points, so the towers along a road blink at different times.
3. The second tower halfway along a long segment blinks exactly opposite the one at the segment's end.

Each rule works from the clock alone. Ask a beacon about step 5,430 cold, and it answers. So the ride derives every beacon afresh each frame, from the clock: derived, in its purest form.

### Asking for a beacon

A tower asks for its beacon when its sighting builds it, with this line from the tower past a segment's end:

{{code TowerSighting.end_tower from "beacon = Beacon.at" to "beacon = Beacon.at"}}

The segment's index and the tower's place say which beacon, and the clock says how bright it is. The tower halfway along a segment has the same line with `Midway` in place of `AtEnd`. Here's the function it calls:

{{code Beacon.at}}

A `Beacon` is opaque, around a `Fraction`, its brightness. Inside the module, `Beacon.(…)` builds one, and only this module can. The brightness comes from the beacon's phase, how far it is into its blink:

{{code Beacon.blink_phase}}

`clock.steps_since(Clock.start)` turns a moment into a length: the steps since the ride began. Adding the beacon's head start gives its phase, and `wrapped_to` brings that back inside one blink, so a phase of 130 is a phase of 10. A cosine turns the phase into a brightness:

{{code Beacon.beacon_brightness}}

`(1 - cos) / 2` runs from 0 up to 1 and back to 0 over one blink, and it stays inside that range. So `Fraction.of`, which crashes on a ratio outside 0 to 1, is safe here.

### Out of step

A beacon's head start comes from its segment's index and its tower's place:

{{code Beacon.head_start}}

Each segment's beacon starts 37 steps further into its blink than the last one's. 37 and 120 share only the factor 1, so the first 120 segments' beacons all start at different points of the blink. The tower halfway along a segment starts half a blink on, so it blinks opposite the one at its end. `half_period` is worked out from the period, so it stays right if the period changes.

The picture's two beacons are the first segment's: the one at its end, with a head start of zero, and the one halfway along, half a blink on. Step 5,400 is 45 whole blinks in, so the first is dark there and the second is at full brightness. A quarter of a blink later, at step 5,430, they're equally bright, and by step 5,460 they've changed places.

A beacon also draws itself. Given where its middle lands on the screen and how many pixels a metre spans there, it returns a magenta disc whose transparency follows its brightness, or a refusal when it's too dim or too small to show. So its tests stand alone, apart from any tower: `Beacon`'s own tests check that a beacon blinks, that the halfway one blinks the other way, and that its disc comes out the right size and color.

A beacon goes round and round. The sun goes one way, and a lot more hangs on it.

## The setting sun

The sun is the one thing in the sky that moves, and a lot hangs on it. As it sinks, the sky darkens, the horizon warms, and everything the sky lights dims with it. All of that is derived from the clock alone. This chapter takes the sunset in three jobs: the sun goes down, the sky darkens, and the horizon warms.

### The sun goes down

```widget sky sun
Press play. The two middle buttons step one frame at a time.
```

This picture does only the first job, so its sky stays blue. Each frame, it asks `SunPath` how high the sun stands, reads out the answer, and marks it on the chart's gold line:

{{code SunPath.height_at}}

`SunPath.sun_direction_at` works out the sun's direction at a clock, a bearing and a height, with the ride's one piece of spherical trigonometry. The rest of the sunset needs only the height.

### In view, or out of view

The sun stands in one direction, and the rider may be facing another. Two tags say whether it's in view:

{{code Sun.Sighting}}

An `OutOfView` sun paints an empty list, and a `match` on a `Sighting` handles that tag too, since a `match` covers every tag. Here's the function that decides:

{{code Sun.sun_in_view}}

`Lens.far_point` says where something infinitely far off lands on the screen, and refuses with `BehindCamera` when it lies behind the camera. A sun that lands somewhere is still out of view when its glow stays wholly off the screen. At step 1,529, the frame the first half held still, the sun stands behind the rider, which is why that frame showed only sky.

The sun in view is a glow and a disc:

{{code Sun.sun_shapes}}

The glow adds its light to the sky, over the rectangle above the horizon, and the disc paints over that. The grass comes after the backdrop's sun and covers whatever of the disc has sunk below the horizon, so the sun sets behind the land by paint order alone.

### The sky darkens

```widget sky sky
Press play. Now the sky darkens too.
```

This picture adds one call, `Sky.darkness_at`, whose answer is the blue line. The {{chapter Functions}} chapter took that function apart: it asks for the sun's height and picks one of two shapes, on either side of the moment the sun has fully set:

{{signatures Sky.darkness_while_up Sky.darkness_after_set}}

While the sun is up, the darkness grows with the square of how far the sun has fallen since the ride began, and reaches `darkness_at_set`, 0.6, as it fully sets. After that, the darkness climbs in a straight line to full night as the sun sinks a further `night_depth`. The two shapes meet as the sun fully sets, and you can see the join in the blue line. Both helpers take only a height, so the darkness depends on the sun's height alone.

The sky's top color blends from day to night by that darkness, as the {{chapter The sky}} chapter showed, and everything the sky lights, the grass and the rock and the trees, dims through `Sky.color_at_darkness` by the same `Fraction`.

### The horizon warms

```widget sky warmth
Press play. This is the whole sunset.
```

This picture adds `Sky.horizon_warmth_at`, the red line. The horizon is warmest when the sun's height is zero, on the horizon itself. `from_horizon` is how far the sun is from it, above or below, and `abs` makes the two sides match, which gives the red line its tent. The share of `warmth_reach`, 110, is held at 1 by `Fraction.clamp`, and `complement` turns it around, so a height of zero gives full warmth, and 110 or more gives a warmth of zero.

### Going backward

Play any of those pictures backward, and the sun rises, with the same code. Every function here takes a clock and answers, so the clock can run either way. The sun, the sky and the beacons can each be asked about any step, cold.

The rider and the truck are another kind of thing: the ride carries them, and moves them one step at a time. The next chapter shows what that costs.

## Stepping

Where the rider and the truck are depends on where they were a step ago, so the ride carries them in the moment and moves them one step at a time. That's the stepped kind of moving part, and this chapter shows what does the stepping and what it costs.

The modules that do the stepping
```dot
digraph stepped {
  rankdir=TB;
  nodesep=0.5;
  ranksep=0.6;
  node [shape=box, fontname="Helvetica", fontsize=18, margin="0.25,0.12"];
  edge [fontname="Helvetica", fontsize=16];
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

A box is a module, and an arrow points to a module it calls. `RideInstant.next`, from the {{chapter The ride instant}} chapter, steps the rider and the truck, and the modules below them do the work.

### The step function

`Clock.next`, `Rider.rider_at_next_step` and `TruckJourney.truck_progress_at_next_step` all have the same shape: a value goes in, and the next value comes out. Call that a step function. The ride holds a rider, and another rider one step on, and the old one stays as it was.

### What stepping costs

Stepping has a cost, which shows beside the sun:

- The sun can be asked about any step, cold. To find the truck at step 4,000, the ride has to play that far.
- A wrong sky spoils only the frames it touches. A wrong step moves the rider for the rest of the ride.
- The lines of `RideInstant.next` run in order. Frames can be worked out in any order.

So the stepped parts get the most care. The rider's step takes the next four chapters, and the truck's the three after those.

## The rider

The rider is two things: a motorcycle, and a pair of eyes.

| Part | Field | Type | What it is |
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

`Rider := { ... }` is a nominal record, like `RideInstant`, and both of its fields are nominal records too: `Motorcycle` and `RiderEyes`. Nothing in the rider is a bare float. Three of the fields in the table are angles, of two types: `yaw` and `gaze_yaw` are `Turn`s, and `lean` is a `Lean`. Passing a `Lean` where a `Turn` is wanted is a compile-time error. The eyes get a chapter of their own.

The step does its work in order, and the code reads that way: decide, move, cross a bend or stop, then choose where to look:

{{code Rider.rider_at_next_step}}

Static dispatch finds `segment_on` on the `RoutePlace`. The `match` on `segment.segment_ending()` has two tags, and `..` in `Bends({ bend, .. })` ignores the rest of its payload.

{{code RiderMind.controls}}

Every decision the rider makes is `RiderMind`'s. `RiderMind.controls` answers the bike's controls: a lean and an acceleration. Notice its last line. `Throttle` picks the acceleration, and it's asked about a motorcycle that doesn't exist: this motorcycle as it would be at the new lean. `motorcycle.with_lean(lean)` builds that one as a new record. The real motorcycle isn't touched, because no Roc value can be changed.

The Rehearsal chapter takes that idea much further. A small version of it decides what happens at the end of a segment. `cross_bend_if_on_road` makes a motorcycle carried past the bend onto the next segment. If that motorcycle is on the road, it's the answer. If not, the old one is. The rejected motorcycle simply stops being referred to, and nothing has to be undone:

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

The step works in three parts. First the speed: the acceleration is applied, and `allowed_speed` holds the result to the top speed. Then the turn: `lean.steer(turn_per_lean)` turns the lean into a change of direction, a `Turn`. That's the only way a lean affects where the bike points. Then the move: the bike goes one step's length in the direction halfway through the step's turn, `mid`. `along.plus(...)` adds a `Distance` to a place, which is places and distances again. The new place is a record update of `route_place` with a new `road_point`, inside a new motorcycle.

The bike turns the same amount per step at any speed. That's a cheat, chosen by eye, and it's fine here because the rider chooses each step's lean by trying it out on this same physics.

Two small helpers let the rest of the program pretend:

{{code Motorcycle.with_lean}}

{{code Motorcycle.steady_controls}}

`{ ..motorcycle, lean }` is record update with a shorthand: the field and the local have the same name. `with_lean` makes a motorcycle that doesn't exist, and `steady_controls` makes the controls to coast one on. The Rehearsal chapter uses both hundreds of times a step.

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

The rider has several reasons to slow down, and they don't know about each other. A bend is coming. A cat is in the lane. There's a pig to look at. Coasting on would carry the bike off the road. `Throttle` writes them as a list of limits, the chain in the second diagram. It starts from `offered`, the cruise acceleration. `fold` hands each limit in turn to `held_to`, with the acceleration so far, and each limit lets it through or lowers it:

{{code Throttle.next_acceleration from "limits = [" to "limits.fold(offered, held_to)"}}

Call this *the chain of limits*. Each limit answers the same type and can be read alone, and adding a reason is one more line. It reads like a list of rules because that's what it is.

Each limit is a `ThrottleLimit`: nothing, or at most some acceleration. `held_to` takes the lower:

{{code ThrottleLimit.ThrottleLimit}}

{{code Throttle.held_to}}

The throttle answers an acceleration, and the motorcycle turns it into a speed.

`Speed` and `Acceleration` are places and distances again: a speed is the place, and an acceleration is the change from one speed to another. To brake for a bend, the rider needs the steady acceleration that takes its speed to a target within so much road. That's `Speed.acceleration_to`. Its `within` is a `Distance`: the road the change has to happen in. The formula is the first line of a physics textbook, v² = u² + 2as, solved for a, with the speed going from `s` to `t`. In the parameter list, `Speed.(s)` and `target: Speed.(t)` unwrap the two speeds into plain numbers, as `Clock.(n)` did in the One whole module chapter:

{{code Speed.acceleration_to}}

It has one caller, `VehicleLimits.braking_to`. That function also holds the speed steady when less than a micrometre of road is left, and crashes on a brake that would take the speed below zero. The rider's bend brake, the gawk brake and the truck all brake through it. The first limit is the bend's:

{{code Throttle.bend_limit}}

The last limit, `shoulder_limit`, comes back in the Rehearsal chapter, because it runs a pretend copy of the bike forward, which is what that chapter is about. The two in the middle come from what the rider sees: `encounter_throttle` is the cat's, and `gawk_brake` the pig's. The cat's has its own chapter, so we'll take the pig first.

## The rider's gaze

The herds chapter left one pig waiting. On the first two segments with pigs, one pig in the big herd catches the rider's eye. The rider turns to look and slows down, and the camera turns too.

Looking and slowing down are two different things, and they last different lengths of time. The eyes follow the pig, and they give up once it's too far to the side. The speed drops for the pig, and it stays down until the segment ends. So the code has two words for them. A *look* is what the eyes do, and *gawking* is what the speed does. This chapter takes them in that order.

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

Three small types say what a pig can do to the rider. Each one carries its payload only where it means something. A segment's `pigs` field is `NoPigs` or `Herd`, and only `Herd` carries a payload: the herd itself, and its `interest`. The interest is `Distracting` or `Unnoticed`, which says whether the herd catches the rider's eye:

{{code Segment.Pigs}}

The rider looks at a pig or at the road, and only a pig has an angle:

{{code Gaze.GazeTarget}}

A pig asks something of the throttle, or it doesn't, and that's the `ThrottleLimit` from the throttle chapter.

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

Before the eyes move, the rider chooses where to look. `Rider.rider_at_next_step` asks `RiderMind.gaze_target`, since every decision is `RiderMind`'s, and `gaze_target` hands the question to `Gaze.desired_gaze`:

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

`RiderCamera.ride_focal_length` sets how wide the view is. It asks `Rider.attention`, which takes the stronger of two pulls: this look's, and a crossing cat's, which the cat chapters cover. So a pig widens the view, and the view stays wide for a while after.

### Gawking

Whether the rider is gawking is a plainer question than whether it's looking:

{{code Gawking.is_gawking}}

Like the look, it starts when the pig is within 150 metres. It only asks where the rider is, with no angle, so it lasts until the segment ends, long after the look.

`gawk_brake` is the third link in the throttle's chain. It gives a brake while the rider has noticed a pig, and `held_to` keeps the brake when it's lower than the acceleration so far:

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

- Modules: `Truck`, `TruckBody`, `TruckShape`, `TruckSighting`, `TruckPlacement`

### How to draw a truck

Here's the whole job in one function. Given a sighted truck and the camera's lens, it works out the truck's setting, then draws its headlight beams, its body and its brake lights, each painted over the one before:

{{code Truck.scenery_sprite}}

The body is drawn the same way, one level down. It takes the truck's spot, places each face, sorts the faces far to near so that a nearer face covers a farther one, and clips and projects each one:

{{code TruckBody.body_sprite}}

The modules that draw the truck
```dot
digraph truck_drawing {
  node [shape=box, fontname="Helvetica"];
  Truck [style=bold];
  Scene -> TruckSighting [label="  finds it with truck_in_view"];
  Scene -> Truck [label="  draws it with scenery_sprite"];
  Truck -> TruckBody [label="  draws its body with body_sprite"];
  TruckBody -> TruckShape [label="  reads the faces of"];
  TruckBody -> TruckPlacement [label="  places each face with placed_face"];
}
```

The rest of this chapter opens those pieces: what the truck looks like, and how it's placed on the road.

### What the truck looks like

The truck is blue: a dark blue body, darker blue sides, a lighter blue roof, and black tires. There's no glass, so the windshield is the body's color.

`TruckShape` says what the truck looks like, and nothing else. It doesn't know where the truck is, or that there's a road. Each part of the truck is a face, a color and its corners:

{{code TruckShape.TruckFace}}

A corner is a point in the truck's own frame, three distances measured from the middle of the trailer:

{{code TruckShape.TruckPoint}}

The sides come first. Each one is a single outline, the trailer and the cab together, walked from the back of the trailer to the nose and back:

{{code TruckShape.sides}}

The trailer's back, the roof, the windshield and the nose are each a strip across the truck. Here's the windshield, sloping down from the cab's roof to its nose:

{{code TruckShape.windshield}}

The tires are circles standing on the road, one on each side of each axle:

{{code TruckShape.tires}}

And the whole truck is its faces, in one list:

{{code TruckShape.truck_faces}}

### Shape, placement, projection

That shape gets to the screen in three stages:

| Stage | What it does |
|---|---|
| Shape | Says where each corner of each face is in the truck's own frame |
| Placement | Turns one point by the road's heading, carries it out from the truck's foot, and lowers it by the ground's drop |
| Projection | Turns one whole face into a polygon on the screen |

Placement works a point at a time. Projection works a face at a time, for two reasons. A face that reaches behind the camera is clipped, and clipping can cut corners off a face and add new ones, so it needs the whole outline. And the faces are sorted by depth before they're drawn, and the sort orders faces, not points.

### Placement: one rigid body

A truck doesn't bend, so every corner moves together. `TruckSighting` finds the truck on the road ahead and works out two things once: the truck's spot, and which of its lights are on.

{{code Pipeline.Sighted}}

Every sighting's spot holds the object's foot in the rider's view, and which way the road runs there. `road_heading_at` finds that direction from two points on the road: the object's own, and a point one metre further along. It brings both into the rider's view, and the angle between them is the heading.

{{code RoadAhead.road_heading_at}}

A solid thing stands each of its points through its spot. A point is an offset in the thing's own frame. It is turned by the road's heading and by how the thing faces against the road, carried out from the foot, and lowered by the ground's drop. The tower stands its footprint this way, turned by its yaw:

{{code Spot.standing_point}}

The truck faces straight along the road, so its placement is one line. The headlights and the brake lights use it too:

{{code TruckPlacement.point_at_height}}

The truck is drawn from its spot, the camera's lens and the sky's darkness:

{{code TruckPlacement.TruckSetting}}

Every corner is lowered by the same drop, how far the ground has curved away beneath the truck's spot. Across a 12-metre truck the drop changes by a few centimetres at most, far less than a pixel. `TruckPlacement.placed_face` places every corner of a face this way, and that's what `body_sprite` sorts and draws.

With the lights off, the beams and the brake lights are empty pictures, and `scenery_sprite` draws just the body. The truck is drawn however small it stands, because the rider is always looking for it.

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

Each frame, `FrameView` builds both lamps together. It hands the sky's darkness to `TruckHeadlights` and the truck's pace to `TruckBrakeLights`:

{{code FrameView.ride_facts from "headlights: TruckHeadlights.at(" to "brake_lights: TruckBrakeLights.at("}}

New in this chapter:

- Modules: `TruckHeadlights`, `TruckBrakeLights`

Each kind of lamp gets a module, and each module owns two things: whether its lamp is on, and how the lamp looks. Both are `[On, Off]`, and a `Truck` holds one field per lamp:

{{code Truck.Truck from "Which of" to "Truck := {"}}

### The headlights

The headlights work like a light sensor on the lamps themselves: once the sky is dark enough, they're on. `Sky.darkness_at` answers a `Fraction`, 0 by day and 1 at full dark, and the sensor reads that:

{{code TruckHeadlights.at}}

They come on at this darkness:

{{code TruckHeadlights.headlights_on_darkness}}

On this ride, that's step 3,555 of 6,746. Once on, they stay on, because from there the sky only darkens.

Their `sprite` matches both tags, and an `Off` lamp is an empty sprite. When they're on, it paints two beams as wedges that fade from the lamp toward their far end. Their points are placed the way the body's are, with `TruckPlacement.point_at_height`:

{{code TruckHeadlights.sprite}}

### The brake lights

The brake lights have a twist: they don't read the light at all. They follow the truck's pace, so they're on while its last step slowed it, by day or by night:

{{code TruckBrakeLights.at}}

Their picture works the same way as the headlights': two lamps on the back of the trailer, each with a glow around it, and nothing when they're off:

{{code TruckBrakeLights.sprite}}

### All together

`Sprite.composite` makes one picture of several, each painted over the ones before:

{{code Sprite.composite}}

`Truck.scenery_sprite`, from the chapter that drew the truck, puts the beams first, then the body, then the brake lights:

{{code Truck.scenery_sprite from "Sprite.composite([" to "truck.brake_lights.sprite(setting),"}}

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

A crossing comes in two halves. `CatCrossing` is what the cat does: where it crosses, and what it does at each step of its crossing. `Cat` is how it looks this frame, which is just its pose. The pose type, `CatPose`, is defined in `CatCrossing`, not in `Cat`, because the crossing is what changes the pose:

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

The ride plans the crossing once, from how fast the rider is coming. The aim is for the cat to be across just as the rider arrives 3 metres short of it. The crossing takes 38 steps, so the plan is made when a rider who kept their speed would cover the rest of the gap, down to 3 metres, in 38 steps. That's what coming within reach means. A faster rider covers more road in that time, so the plan is made farther off:

| Rider's speed | The crossing starts at a gap of |
|---|---|
| 1 metre a step | 41 metres |
| 1.5 metres a step | 60 metres |
| 2 metres a step | 79 metres |

What the ride plans by is a span: how many steps the animation takes, and the gap it ends at.

{{code EncounterPlan.StepSpan}}

The cat's span is its 38 frames, ending 3 metres short:

{{code CatCrossing.crossing_span}}

The plan is made on the first step where the rider is within reach. Until then, and while the rider is at rest, nothing is planned:

{{code EncounterPlan.plan_for}}

After that one look, the cat doesn't care what the rider does. If the rider brakes, the cat still crosses on time, and the rider simply arrives a little later.

Once a plan exists, the ride's clock says where the animation has got to. That's a `Stage`:

{{code Animation.Stage}}

`Waiting` before it starts, `Playing` while it runs, counting steps in, and `Past` after it ends, counting steps since. The tags carry only what each case needs, so there's no step count to misread while the cat is waiting.

A plan and the clock together make a `Timing`:

{{code EncounterPlan.Timing}}

{{code EncounterPlan.timing_at}}

A `Timing` and the animation's length make the `Stage`:

{{code EncounterPlan.stage_at}}

### Who moves first

Each step, the world and the rider change each other, and the order matters. The rider reacts to the cat as it stood at the start of the step: if the crossing is playing, the throttle holds. Then the rider moves, and the ride checks the plan again. If the moved rider has just come within reach, the plan is made at the new clock. At each new segment the plan is forgotten, because only the encounter on the rider's own segment is ever live.

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

The cat reaches the screen in two parts, and the camera is only in the second. First, `EncounterPoses` works out where each cat in view stands this frame, with no camera at all. Only the rider's own segment plays its crossing; a cat on a segment ahead is still waiting behind its tree:

{{code EncounterPoses.cat_poses}}

Then `EncounterSighting` asks where the camera sees each one. Through `Pipeline.scenery_sighting_of`, it drops any behind the camera or too small to draw:

{{code EncounterSighting.cats_in_view}}

From there, a cat is a kind like a tree or a cow, and it joins the frame's depth sort.

The ride remembers one step for the cat, and works out everything else, frame by frame, from it and the clock. While it crosses, the cat also asks two things of the rider: hold the throttle, and look. That's the rider's side of the story, and it comes two chapters on.

## The bird

The bird is Roc's logo, sitting on a treetop. As the rider comes near it takes off, flies across the road and ahead, and drops onto a tree on the far side. It moves the way the cat does, through the same plan and the same kind of timeline, and it took much less code.

```widget bird
Press play and watch the bird fly.
```

The widget's camera stays put, 18 metres short of the first tree. The gap counts down as if a rider were coming, and it only drives the clock. Play it, and the gap falls from 75 metres to 0, with the rider held at 1.25 metres a step. The bird sits on the tip of the left tree, 6.4 metres up, until a gap of 60 metres. It takes off side on, turns away at about 55 metres, and is highest, 10.7 metres up, near the middle of its flight, shrinking as it goes. It starts to dive at a gap of 20 metres, and at 15 it's perched on the tip of the far tree, 4.9 metres up. Below that, the picture stays as it is.

New in this chapter:

- Roc: tags inside tags, opening a `Try` by hand, `match` as an expression
- Modules: `BirdFlight`, `Bird`

### Two halves

A bird comes in the same two halves as a cat. `BirdFlight` is what it does: the tree it leaves and the tree it flies to. `Bird` is how it looks this frame, which is its pose:

{{code Bird.Bird from "Bird := {" to "}.{"}}

A pose can carry a tag of its own. A bird side on or seen from behind has its wings up or down, so those tags carry a `WingBeat`. As with the cat, the pose type is defined in the module that changes it, `BirdFlight`:

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

The ride plans the flight the way it plans a cat's crossing: once, when the rider first comes within reach, from how fast the rider is coming. A flight is 36 frames. It's planned to end when a rider who kept their speed would be 15 metres short of the tree the bird left, so the rider sees it land before passing that tree:

{{code BirdFlight.flight_span}}

So a faster rider sets the bird off farther away:

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

With `t` for `share`, how far through the flight the bird is, `4t(1 − t)` is 0 at both ends and 1 halfway, so the arc starts and ends on the line. The last line is a record update: everything about the point on the line, with its lift raised.

### Finding a tree

A segment's bird is chosen when the world is built. The segment picks the perch, the fifth tree on the left:

{{code Segment.fifth_left_tree}}

Then the bird picks where to fly: the first tree on the far side of the road at least 25 metres farther along.

{{code BirdFlight.flight_from}}

`find_first` answers a `Try`, and the `match` opens it by hand, turning "not found" into the bird's own error, `NoTreeToFlyTo`. The bird always starts on the left because its perched and side-on stills face right and are never mirrored, so on a left tree it faces the road.

The segment puts the two together. A route that plans a bird on a segment with no tree for it is a bug, so each failure crashes with its own reason:

{{code Segment.from_choices from "BirdHere =>" to "QuietRoad => QuietRoad"}}

`match` is an expression here. Its answer is the value of the `encounter` field, an `Encounter`: a cat crossing, a bird's flight, or a quiet road, in a module of its own.

### Getting it on screen

The bird reaches the screen the way the cat does: `EncounterPoses` places it with no camera, and `EncounterSighting` asks where the camera sees it. Only the rider's own segment plays its flight. A bird on a segment ahead is still perched on its first tree.

`Bird` draws it from its still, at its height:

{{code Bird.scenery_sprite}}

A perched bird stands exactly where its tree's top is, at the same depth, and the scene paints trees before birds when depths tie, so the bird is drawn over its tree.

The bird asks nothing of the rider, so the rider's reactions pass it by. All it adds to the game is a list of poses, a path, and the stills to draw them.

## What a cat does to the rider

A crossing cat asks two things of the rider: hold the throttle, and look. Both are the rider's own reactions. They live on the rider's side, in one module, `EncounterReaction`, which knows which encounters ask anything of the rider.

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
  EncounterReaction -> Encounter [label="  asks which it is"];
  EncounterReaction -> CatCrossing [label="  reads its peak and span"];
  EncounterReaction -> ThrottleLimit [label="  answers one"];
  EncounterReaction -> Attention [label="  answers one"];
}
```

### When the rider feels it

The order inside a step matters here. The rider reacts to the cat as it stood at the start of the step, then moves. Only after the move does the ride make its plan, if the rider has just come within reach. So on the step the crossing is planned, the rider hasn't felt it yet; the hold starts on the next step. The camera, drawing the frame, reads the cat as it stands now.

Once planned, the cat never reads the rider again. The rider's speed sets the cat off once, and from then on the effect runs one way: the cat keeps the rider from speeding up, and nothing the rider does moves the cat.

### Hold the throttle

A limit on the throttle is a `ThrottleLimit`, from the throttle chapter: either nothing, or at most some acceleration.

While a cat crosses, the rider may not speed up. That's `AtMost(Acceleration.steady)`, which caps the acceleration at zero without braking:

{{code EncounterReaction.encounter_throttle}}

The outer `match` asks what's on the segment, and the inner one asks where the crossing has got to. `Waiting | Past(_)` is one branch for two tags, and `_` ignores a payload. A bird and a quiet road both answer `NoLimit`.

The cat's limit is one of the four in the throttle's chain of limits, beside the bend, the gawking and the road's shoulder. The chain starts from the cruise acceleration and keeps the lowest. Holding at steady also keeps the rider from going faster than the plan assumed, so the cat is across before the rider arrives.

### Look

How hard something holds the rider's eye is an `Attention`. A full look to the side is 1, and a crossing cat holds the eye harder than that, so underneath it's an `F64`, not a `Fraction`:

{{code Attention.Attention from "Attention :: F64.{" to "Attention :: F64.{"}}

The encounter on the rider's segment answers one:

{{code EncounterReaction.encounter_attention}}

The cat's pull rises as it crosses, up to its peak of 1.8, then fades over 83 steps once it's across, about 80 metres past the cat at a metre a step:

{{code EncounterReaction.cat_attention}}

`Playing` and `Past` both carry a step count, and this is where both are used: one says how far into the crossing, the other how long since it ended.

`Rider.attention` takes the stronger of two pulls: the cat's, and the depth of the rider's last look, which lingers after the eyes come home. The camera widens its view for that attention, or for the lean, whichever asks for the wider view. That's how a crossing cat seems to fill more of the picture.

Each segment has one encounter at most: a cat, a bird, or a quiet road. A cat asks for both, a bird for neither, and the rider's reactions to everything else, the bends and the pigs, live in the rider's own chapters.

## Rehearsal

The rider has no steering wheel. Nothing tells it where to go. Each step, it has to choose a lean, and it does that by working out what would happen. Call this *rehearsal*: run the real rules on a pretend copy, read the result, and throw it away.

Safari Ride's rider steers by rehearsing. Each step it tries twelve leans. It keeps a low and a high bound on the lean, and each try moves one of them in. After the twelfth try, it takes the lean halfway between the two bounds.

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

`coast_keeping` runs the coast, and it can keep the path the motorcycle took, which is what the widget draws as the white arc. `coast_outcome` asks it to drop the path, since the ride only needs where the coast ended. The loop is in `coast_keeping`:

{{code Coast.coast_keeping}}

The coast's bounds are the road's edges, 5 centimetres in, or wherever it starts if that's further out. The `while` moves the motorcycle a step at a time until it crosses one of those bounds, gets 25 metres further along its segment, or runs for 2,000 steps, and `return` leaves the function from inside the loop. The answer says where the coast went:

{{code Coast.Outcome}}

`LeanSearch` asks `Coast` that question at twelve different leans. The rider wants the coast to end near the middle of the road. More lean to the right always moves the end of a coast to the right, so each try can rule out half the leans left between the bounds. That's a bisection, a binary search over leans. It's a `for` loop, with `$bounds.low` and `$bounds.high` closing in on each other. `LeanSearch.tried_motorcycle` is the motorcycle with the lean halfway between the bounds. It doesn't exist, and `Coast` gives it a future that didn't happen:

{{code LeanSearch.search_tries from "lean_try = {" to "$bounds = bounds_after(lean_try)"}}

The search starts with bounds a degree either side of the current lean, `max_lean_change`, so the lean it picks is never more than a degree from the last. That's what stops the bike flicking from one lean to another. Which way each try sends the next is a `match` on what the rehearsal found. Running off the left means more right, and running off the right means more left. A coast that stays on the road compares where it ends with `aimed_across`, the road's middle:

{{code LeanSearch.lean_correction}}

After the last try, the lean it keeps is the midpoint of the bounds that try narrowed to:

{{code LeanSearch.best_lean}}

`RiderMind.controls` calls that on its first line, and on its second asks the throttle about the motorcycle at that lean. That's where the rehearsals start: `RiderMind.controls` is the top of the calls in the picture above.

Each real step of the ride runs thirteen coasts that never happen: twelve for the lean, and one more in `Throttle`, which uses `Coast` to ask whether the road is about to run out.

In a language with mutable objects, a rehearsal has a problem to solve before it starts. It needs to copy the rider, or save it and restore it, and it needs to be sure the copy shares nothing with the original, all the way down. It needs to know that the physics doesn't quietly update something global, like a scoreboard or a random number generator. In Roc, none of that comes up. `Motorcycle.motorcycle_at_next_step` has a `->`, so it can't reach anything but its arguments. The old motorcycle stays intact because every value does. A rehearsal that goes wrong costs nothing, and `LeanSearch` is about 100 lines above its tests.

The last limit of the throttle is the same idea with one rehearsal in it. It runs the coast, and brakes only if the coast leaves the road:

{{code Throttle.shoulder_limit}}

That's the last of the rider.

## The math layer

All this time, a layer of math has been doing the measuring. This chapter opens it up, from the modules everything imports down to Roc's own arithmetic.

New in this chapter:

- Roc: records as coordinate systems, `fold` and `map2`, a record type with a type variable for a region
- Modules: `Lens`, `Geom`, `RoadAhead` and `Camera` up close

A lot of Safari Ride is math and physics, and most of it is geometry a reader could do on paper. It's here because this kind of code suits a compiled functional language unusually well, for a short list of reasons:

- A formula is an expression, and a function with no effects is the same thing with a name.
- Units can be types, and a type that only wraps a number is still just the number when the program runs.
- A coordinate system can be a record, so the fields say which one a point is in.
- It's compiled, so even the last chapter's rehearsals are affordable.

### The most imported modules

Safari Ride has 96 modules, not counting `web.roc`, `main.roc` and `game.roc`. The import graph is lopsided in a good way: a handful of modules are imported by many others. The table counts importers among the game's modules, leaving out the test programs, and its Lines column counts each module's code above its `expect`s:

| Module | Imported by | Lines | What it is |
|---|---|---|---|
| `Distance` | 55 | 66 | A length in metres |
| `Fraction` | 28 | 88 | A ratio from 0 to 1 |
| `Geom` | 25 | 146 | Road points, bends, and how a point moves round one |
| `Angle` | 21 | 199 | Four opaque types for rotation |
| `Along` | 19 | 61 | A place along a segment |
| `Pixels` | 18 | 69 | A length on screen |
| `RoadAhead` | 16 | 219 | Where the road ahead lies from where the rider is |
| `Across` | 15 | 68 | A place across the road |
| `RiderView` | 15 | 249 | Points measured from the rider, and the near plane |
| `Screen` | 15 | 113 | The canvas: its size, its middle, its horizon |

`Sprite` is imported by 15 as well. It's how one object looks in one frame, so every kind of object that draws one imports it. `Shapes` is imported about as widely as the modules in the table, but the table leaves it out because it's in `lib/`, a folder of modules shared with the repository's other canvas apps. After those the count drops to 13, for `Animation` and `Steps`, and then 11, for `Segment`. Most modules are imported by one, two or three others.

These ten are the core utility modules, and nearly everything else is a small module that takes one of them and adds a single idea. Six of the ten are nothing but numbers with rules, and most of those are under 100 lines. Two modules carry every object to the screen: `RoadAhead` finds a cat, a tower or a truck on the road, and `Camera`, which isn't in the table, puts it on the screen.

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

The picture leaves out the unit types that everyone shares. What's left is two families that meet only at `Angle` and `Geom`. `RoadAhead`, `Camera` and `Lens` say how the world looks from the bike, and `Motorcycle`, `Coast` and `LeanSearch` say where it's going.

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

This is the opaque type doing the job of a unit. The methods in the block after each type's declaration are a small statement of dimensional analysis. `Speed.distance_in` takes `Steps` and gives a `Distance`. `Along.plus` takes a `Distance` and gives an `Along`, and `Along.distance_from` takes two `Along`s and gives a `Distance`. `Lean.steer` takes a rate and gives a `Turn`. There's no `Bearing.plus(Bearing)`, because that sum has no meaning. If you try to write one, the compiler stops you.

The bug these prevent is the most common one in this kind of code: a correct formula with the wrong number in it. Most physics bugs type-check in a language where everything's a float.

The price is a long list of short methods, and a certain amount of `.to_radians()`.

The units run from the road to the screen. Once a point is measured from the rider, its `right` and `forward` are `Distance`s, and a length on screen is `Pixels`. `Pixels` is signed, because a place on screen is measured from the top left corner, so a point off the left of the screen is negative, and so is one above its top edge. The units stop at `lib.Shapes`, which takes plain numbers. Inside a function, a formula wants plain floats too. So a function that's about to do trigonometry unwraps its arguments at the top, with `.to_metres()` and the like, and wraps its answer again at the end. And because `Along` can't be passed as `Across`, a function that takes both can't have them swapped.

### One record per space

A point in Safari Ride is in one of four spaces, and the record's fields say which. Here we hand a point measured from the rider to a function that wants a point on the road:

{{fails rider_point_as_road_point}}

The points are plain records. They don't need to be opaque, since a record's type is its fields, and a `RoadPoint`'s fields are opaque already.

{{code Geom.RoadPoint}}

{{code RiderView.RiderPoint}}

{{code RiderView.PointAtHeight}}

{{module Point}}

Roc's records are structural: a record's type is just its field names and their types. That gives *one record per space* at no cost: `along` and `across` are on the road, `right` and `forward` are from the rider, `right`, `forward` and `height` are from the rider with a height, and `x` and `y` are pixels. Reading any function, the field names say where it is.

Going from the road to the rider is a translation and a rotation, and this is the function where the opaque places give way to floats. `distance_from` makes the translation, and the rotation is written the way it would be on paper:

{{code RoadAhead.to_rider_point}}

From there to the screen is a pinhole camera, which is similar triangles. Dividing by `forward` is all of perspective. Nearly everything on screen passes through this function, and it's short:

{{code Camera.project}}

`project` takes a `PointAtHeightAhead`, and that one is opaque. The only way to make one is to check the point against the near plane, a little ahead of the camera, so `forward` is never zero or negative by the time it's divided by.

A thing standing on the ground is projected twice, at its feet and at its head. `StillShapes.standing_anchor` calls `upright_on_screen` with a record of the height and the focal length, written right there in the call:

{{code Camera.upright_on_screen}}

These two functions cover two of the three sorts of thing from the problem chapter, and the third needs neither:

| Sort | Examples | Has | Lacks |
|---|---|---|---|
| Solids | the truck, the radio towers, the guard rails, the road and its ponds | every corner has its own place along, across and above the road | nothing |
| Cards | the cat, the bird, the cows, pigs and other animals by the road, the far trees | a foot on the road, and a width and a height on the screen | depth: they're flat, and always face you |
| Far scenery | the sun, the mountains, the rolling land | a direction and a height above the horizon | distance: they never come nearer |

A solid is projected corner by corner, each corner through `project`, as `Camera.clipped_polygon` does for the truck's faces, the rails and the ground. A card is one projected foot plus a size, which is `upright_on_screen`. Far scenery needs no projection of distance at all: its direction picks a place across the screen, and its height above the horizon is already in pixels. A tree is the one thing that changes sort. Far off it's a card, but up close its crown is cones, and every point of a cone's ring goes through `project` like a solid's corner.

The focal length comes from a lens. `resting_focal_length` is a value computed from other values, with no function in sight, and `field_of_view` is a `Turn`, so taking half of it needs no comment about radians.

{{code Lens.resting_focal_length}}

The view widens as the rider leans. `focal_length_for_lean` takes the lean as a `Fraction` of the full lean, 20 degrees, and gives a focal length. `RiderCamera.ride_focal_length` calls `focal_length_for`, which works out one focal length for the lean and one for the attention and takes the shorter, so the wider view wins:

{{code RiderCamera.focal_length_for_lean}}

{{code RiderCamera.focal_length_for}}

### Round the bends

```widget route
The route again. This map comes from adding up the turns, which the ride itself never does.
```

The road has no global coordinates. A point on it is measured within one segment, `along` and `across`, and nothing in the game holds a world coordinate for it. Each segment knows only its length and the turn at its end. Those come from `World.bending_plans`, a list of eighteen records like the one below, and a last plan ends the route. It reads like configuration, but it's ordinary Roc: plain values, tags whose types `SegmentPlan` and `BendingPlan` declare, and a `Distance` and a `Turn` built from their units. So a misspelled tag is a compile-time error. Here's the inside of one plan:

{{code World.bending_plans from "length: Distance.metres(1200.0)," to "bend_life: Animal(Rhino),"}}

So to see something three segments ahead, a point has to be carried back round each bend between it and the rider, one at a time. That's one rotation per bend. The road ahead, a `RoadAhead.RoadView`, keeps its bends already worked out: each bend's cosine and sine, and where the segment after it starts, computed once for all the points carried across them. A `while` walks those bends backward. The point starts on the far segment, and each pass moves it onto the segment before. The last line does the one translation and rotation from above:

{{code RoadAhead.rider_point_ahead from "var $point = road_point" to "to_rider_point($point, vantage)"}}

The rotation itself is one formula: turn the point by the bend, then move it to where the next segment starts. The two segments share the corner on the inside of the bend, whichever way it turns, so the next segment starts a little past the end of this one, toward the turn:

{{code Geom.point_before_worked_bend}}

This is why a sighting never needs to know where a segment is. It hands `RoadAhead.rider_point_at` which segment the point is on, the point's place on that segment, and the camera's vantage, and gets back a `RiderPoint`.

The ground also curves away. That's one formula, the small-angle drop of a sphere, with `right` and `forward` taken out to metres before they're squared. Its radius, 100 km, isn't the earth's. It's the surface everything by the road stands on, and it puts the horizon 490 metres out. A sighting asks it once per object, at the object's foot, and the whole object is lowered by that one drop.

{{code EarthCurve.ground_drop}}

### Cutting a polygon

Here's a triangle with one corner behind the rider, before and after cutting:

| | Corners, as metres right and metres ahead |
|---|---|
| Before | (0, -1), (2, 5), (-2, 5) |
| After | (0.47, 0.4), (2, 5), (-2, 5), (-0.47, 0.4) |

The corner behind the camera has gone, and two new ones stand on the near plane, 0.4 metres ahead.

Anything that crosses the near plane has to be cut, or dividing by `forward` flips it across the screen. The textbook algorithm walks a polygon's edges, keeping the corners in view and adding a new corner wherever an edge crosses the plane. Safari Ride writes the cut once, for any region with an edge. A `Region` is a record of two functions: one says whether a corner is inside, and one says where an edge crosses the boundary. Its type variable, `point`, is the type of point the cut gives back:

{{code RiderView.Region}}

In Roc, the walk is a pairing and a `fold`. `next_corners` is the list of corners rotated by one, so `map2` pairs each corner with the one after it, and the last with the first. Each pair is an edge. `fold` then builds the new polygon from the edges, one at a time. `List.with_capacity` is the one line about performance, and `edge_points_onto` is passed by name:

{{code RiderView.points_in_region}}

A fold's step is a plain function of the list so far and one edge:

{{code RiderView.edge_points_onto}}

The near plane is one region, and cutting by it is one line:

{{code RiderView.clipped_points}}

The ground's horizon is a second region, a circle round the rider.

The cut can change the type of point as well as the count. The near plane takes `PointAtHeight`s and gives back `PointAtHeightAhead`s, the type `project` takes, while the horizon gives back `PointAtHeight`s. That's what the type variable is for.

`GroundPatch`, `GuardRail`, `TruckBody` and `TruckBrakeLights` all cut through `Camera.clipped_polygon`. `GroundPatch` first cuts its corners at the horizon, with `EarthCurve.points_before_horizon`:

{{code Camera.clipped_polygon from "in_front = RiderView.clipped_points(" to "Brush.flat(color),"}}

### Arithmetic all the way down

At the very bottom are Roc's own builtins: `.sin()`, `.cos()`, `.sqrt()` and the rest. `Throttle.shoulder_brake` uses `F64.e.pow(x)`. It takes the number of steps a rehearsed coast needs to reach the shoulder, and turns that into a braking limit.

So from top to bottom, a rider chooses a lean by simulating physics, and the physics is plain arithmetic on opaque numbers. None of it has any effects. In the next chapter, we'll see what that's worth when the program has to change.

## Proving it

There are no animals in this chapter. It's about what happens to a program of this size when something has to change, which is the question a reader who cares whether Roc scales should ask.

A language with no hidden state doesn't make a refactor safe by itself. It makes it possible to write a test strict enough to be trusted. Such a test rests on one fact from the ride instant chapter: four fields decide a frame, and a frame is a value. So a frame can be compared, exactly, with the same frame from an hour ago.

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

Everything here lives in `gates/`, and the game never runs any of it. The merge gate is the check a change has to pass before it lands. It runs the lints, every `expect`, the tutorial's build and the proof tools. The gate's programs reach the game's modules through `game.roc`, a package whose only job is to list them.

### A fixture is a value

Getting a test to step 1,529 of a game normally takes some doing. Here it takes a loop. `Tour.initial` is a value, and `Tour.step_forward` is the outermost step function. Underneath it is `RideInstant.next_or_restart`, quoted below, which either continues the ride or starts it again. The step answers `Continued` or `Restarted`, each carrying the next tour. `step_forward` doesn't care which, so one `match` branch takes the next tour from either tag:

{{code Tour.step_forward}}

Testing here is just calling a function. There are no mocks, no fakes, no browser and no waiting. The tests are completely deterministic.

`RideInstant.next_or_restart` is one `if`, and it's worth seeing because it puts the end of the ride in one place. A ride that's finished starts again, so `Tour` needs no notion of game over:

{{code RideInstant.next_or_restart}}

### The frame hash

`RasterFrame` rides to a step, paints the frame into 576,000 exact pixels, and prints an FNV-1a hash of them. The painter is `SafariFrame`, in pure Roc. It uses `ShapesPixels`, which does in Roc what `shapes_canvas.js`, the JavaScript that paints the page, does on a canvas. The gate holds each hash to a line of `gates/proof.expected`, exactly. There's no tolerance: one different pixel in one frame fails it.

A frame is only evidence for what's in it, so the steps in the table at the top of this chapter aren't arbitrary. Most are there for a scene. Step 0 is the start, and 3,000 shows the ride under way, with no scene of its own. Step 9,000 is past the end: the ride lasts 7,071 steps, so the clock at step 9,000 reads 1,928, and the frame shows the ride started again.

We add a frame whenever something could go wrong without any listed frame changing. A brake light wired to `Off`, for example, would pass every hash but one: step 6,250's, the truck braking in plain view.

Exact hashes have a consequence that reaches into the code. Float addition isn't associative, so a sum's order is part of its meaning here. `Route.segments_with_ends` says so in its doc comment, and it's one of the few places in Safari Ride where the direction of a fold is a decision:

{{code Route.segments_with_ends}}

That's also why each operation on `Speed`, `Fraction`, `Angle` and the rest does exactly the float arithmetic its name says, and nothing more. Wrapping a number in an opaque type changes the names, not the sums. So a change that retypes a module, say to use `Speed` where it used bare floats, changes the types throughout, and if it leaves the arithmetic alone, every hash stays where it is. If a hash moves, the retyping changed the program, and the gate says so.

This is how the code in this tour got its shape. Its modules were renamed, retyped and reorganized, and each merge had to leave the frames alone. Roc's types caught what they catch, the hashes caught the rest, and the picture didn't change.

There's one limit to all this. The hash proves the pixels `ShapesPixels` paints, but the page's pixels come from the browser's canvas, with anti-aliasing. What the two share is the list of shapes. `web/page_check.mjs` runs each built page against a stand-in canvas, and beyond that the JavaScript is tested only by its own checks.

### Two more proofs

`ShapesFrame` paints each frame twice: once with its polygons whole, as the browser gets them, and once cut into triangles, as the native program gets them. It counts the pixels that differ, and the gate requires zero of 576,000, at every step in the table.

`StepBack` checks that one step back goes back exactly one step, at every depth of the whole ride, and that as many steps back as the ride took land on step 0. It's in the gate because of a real bug. `Tour` keeps a list of the instants before the current one, for stepping back, and that list once stopped recording when it was full:

| | One step back from step 3,000 lands on |
|---|---|
| When the list kept only its first 2,048 instants | 2,047 |
| Now | 2,999 |

Holding the first 2,048 instants was a perfectly consistent thing for a list to do, so nothing else caught it. The test asks `Tour.step_back` and compares clocks, and since `Tour.step_back` is this small, there isn't much else to ask:

{{code Tour.step_back}}

### `expect`

The rest of the testing is ordinary `expect`s. An `expect` sits at the top level of a module, under the code it checks, and `roc test` runs it. There are over a thousand, and they're Safari Ride's only other tests. The tour has already shown sixteen of them, in the whole of `Clock` and `Pond`. A pure function needs nothing else: literal arguments, literal answer. Each `expect` asserts one thing, and the checks test both answers a function can give, not just the one it usually gives. Two of `Clock`'s checks say a clock is not less than another, that step 9 isn't less than itself and step 10 isn't less than step 9, so they're written with `!`, Roc's boolean not.

A test's data can sit beside it as a plain definition. Here's a motorcycle to step, with no rider around it, because `Motorcycle` doesn't import `Rider`. The test needs nothing the module doesn't:

{{code Motorcycle.riding}}

It's called like any other value, and the steps that follow are named, so three `expect`s can read them:

{{code Motorcycle.first_step}}

The gate makes `expect` honest in one further way. It counts the lines that start with `expect` in the source, and each of them has to print `PASS` exactly once when the gate's `roc test` runs. So an `expect` in a module that no test run compiles fails the gate, and so does one indented out of `roc test`'s reach. An `expect` can only name what its module imports, so a check sits where its test data can be seen, and a module never takes on an import just for a test. A check that needs more than one module goes in `gates/expects/`, a folder of expect modules, one for each topic, each importing whatever its checks need. The checks of `Coast`'s projections and `LeanSearch`'s search are in `RiderExpects`, the expect module for the rider.

Even a truck can be checked this way. A test can't ask where the truck is at step 4,000 without riding there, but it doesn't need to. A `TruckJourney.TruckProgress` is a record, so a test writes one down and calls `TruckJourney.truck_progress_at_next_step` once.

### Crashes that help

{{code Fraction.of}}

Every `Fraction.of` in the game is an assertion, and the gate runs a lot of them. A ratio outside 0 to 1 stops the program, with a sentence saying the sum behind it is wrong. `Try` is the right answer when a value can honestly be absent. This isn't that case. A wrong ratio is a bug, and the sooner it's a crash the better.

Here's one of the many places it's used. `smoothstep` wraps its answer in `Fraction.of` because its algebra says the answer stays between 0 and 1, and nothing else checks that. A proof run rides through it thousands of times, so if the algebra were wrong, the gate would be first to know.

{{code Easing.smoothstep}}

The same holds for the code's other `crash`es, including two dozen `?? crash`es on lookups that can't miss. Each one states a belief about the program, and every gate run tests it.

### The page itself

This tutorial is built from the code. Every fenced snippet here came through Roc's own parser, by name. Each program shown failing is run through the compiler, and the compiler's message is quoted as it printed it. The gate builds the page, so renaming a function quoted here fails the gate until the prose catches up, and the message under `turn_as_bearing`, in the sun chapter, is the compiler's own.

The gate also runs a set of lints over the Roc source, before anything else. Each lint's count of violations is held exactly, and every count is zero. So a vague name, or a boolean parameter that should be a tag, fails the gate before a single hash is computed.

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

`CanvasApp.untimed_model_at_next_step` takes a step function and gives back the same function with one more argument, a number of seconds, which it ignores. Safari Ride counts steps, not seconds, and this is the one place that says so: the runner offers the seconds, and they go nowhere.

`web.roc` is ten lines. Its last is `program = WasmApp.program(SafariApp.canvas_app)`, and that's the whole connection between the game and the web.

### Keys

The ride instant chapter showed `SafariApp.model_at_next_step` reading a snapshot of the keys. A snapshot is a value, so a test could write one down. Everything the keys do is a function from `Tour` to `Tour`, so moving four steps or one is a loop of single steps. `Tour.steps_forward` takes the count as `Steps` and steps forward that many times. `var` is back, in a function that's still pure. `$tour` can't be seen from outside.

{{code Tour.steps_forward}}

`Tour.steps_back` is the same loop around `Tour.step_back`. The app passes four steps a frame while playing and one while paused:

{{code SafariApp.model_at_next_step from "steps_a_frame = match motion {" to "m.tour.steps_back(steps_a_frame)"}}

### A frame is a list

| What's in the shapes of step 1,529 | How many |
|---|---|
| `Triangle` | 868 |
| `Quad` | 727 |
| `Polygon` | 518 |
| `Disc` | 8 |

What the game hands back each frame is a `List(Shapes.Shape)`. A shape is a tag: `Triangle`, `Quad`, `Disc`, `Polygon` and a few more, each with its fill. The table counts the shapes of step 1,529, the cat frozen in the road: 2,121 in all, nearly all of them triangles, quads and polygons. Two of the tags aren't shapes. `Blend` and `View` are marks in the list that change how what comes after them is painted. A frame is a flat list, so a mark is the cheapest way to say that.

The rider's lean is one of those marks. The whole picture banks into a turn, backdrop included, so `FrameView.leaned_shapes` puts the whole frame, backdrop first, inside one view: a camera built from nested tags by `Screen.leaned_by`, turned by the rider's roll:

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

The game has no effectful functions, so where did the effects go? They never got as far as Roc. The wasm platform asks the app for a record of eleven functions over a boxed model, a `Box(model)`: the model behind a pointer, which the host can hold without knowing what's inside. They are `init`, `model_at_next_step`, `frame_shapes`, `release`, `sounds`, `width`, `height` and `fps`, and for sound, which Safari Ride leaves empty, `tone_count`, `tone_freq` and `tone_ms`. Every one has a thin arrow, `->`, so none of them has effects. The host, in `web/platform/host.zig`, keeps the box, and all that crosses between it and Roc is numbers and a list of shapes. Wasm's edge has no records, so the snapshot of the keys is flattened into seven numbers, and `Input.of` rebuilds it. `roc glue` reads `web/platform/Frame.roc` and generates `roc_glue.js`, which knows the layout of a frame in wasm memory, so `roc_glue.js` is never edited by hand.

Each step goes like this, as the diagram shows. `canvas_app_runner.js` paces the clock and gathers the keys. It calls `model_at_next_step`, then `frame_shapes`, in Roc. The platform hands those two to the host as its advance and frame functions, which is why the diagram calls them that. The runner reads the shapes back through the generated glue, and `shapes_canvas.js` paints them on a canvas. The host keeps the list until the next frame, then hands it back so that Roc can drop it. That's `release`, a function whose body is `{}`: Roc knows the layout of what it's dropping, and the host shouldn't have to.

The JS is about 490 lines for every canvas app there is. It knows nothing of cats. A name ending in `!` marks a function with effects, and the only ones near Safari Ride are the `main!` and `echo!` of the gate programs. Those are ordinary command-line apps, and the proof tools need effects to print a hash.

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

The four don't move independently. They read each other, so the order within a step is part of the game. `RideInstant.next`, shown in full in the chapter on stepping through the ride, takes them in this order:

1. The rider reads the world as it stood at the old clock: where the encounter on the rider's segment has got to. If a cat is crossing, the throttle holds.
2. The rider moves, and the clock ticks.
3. The truck reads how far along the route the new rider is, and aims at that. The rider never reads the truck.
4. The encounter plan is kept, forgotten if the rider has just reached a new segment, or made now, from the new rider at the new clock.

The rider reacts to the cat every step. The cat reacts to the rider once, when its plan is made, and never again: after that, it plays on the clock alone. So on the step a crossing is planned, the rider hasn't felt it yet.

Swap two of those lines and you get a different ride: a truck that read the rider from before the move would aim at a mark one step behind. Stepping back never runs the four in any order at all: `Tour.step_back` takes an old instant off the list, and nothing is replayed.

### All four at a glance

| Remembered | Type | What moves it each step | What reads it |
|---|---|---|---|
| The rider | `Rider` | `Rider.rider_at_next_step`, reading the encounter's stage at the old clock | The camera, and so every sighting; the truck and the plan, within the step |
| The truck | `TruckJourney.TruckProgress` | `TruckJourney.truck_progress_at_next_step`, reading how far along the new rider is | `TruckSighting`, and the brake lights |
| The clock | `Clock` | `Clock.next` | The sky, the sun, the mountains, the beacons, the headlights, and the encounter's stage |
| The encounter plan | `EncounterPlan` | `EncounterPlan.plan_at_next_step`: kept, forgotten at a new segment, or made from the new rider at the new clock | With the clock, the encounter's stage: the cat's and the bird's poses, and the rider's held throttle and look |

Turn it around, and ask of each thing on the screen where it comes from:

| What you see | Kept, or worked out from |
|---|---|
| The rider's view | Worked out from the rider, the route, the encounter plan and the clock |
| The sky | Worked out from the clock |
| The sun | Worked out from the clock, and the camera's heading and lens |
| The mountains | Worked out from the clock, and the camera's heading and lens |
| The beacons | Worked out from the clock and the tower each one tops |
| The trees, the cows, the pigs and the ducks | Worked out from the world, built once, and the camera |
| The cat and the bird | Worked out from the encounter plan and the clock, and the camera |
| The truck | Kept: one of the four |
| Its headlights | Worked out from the clock, by way of the sky's darkness |
| Its brake lights | Worked out from the truck, which says whether its last step slowed it |

That's the loop from the start of the tour. The patterns that kept turning up along the way are gathered in the appendix that follows.

## The modules

Safari Ride splits cleanly in two: the ride, and the view of the ride. In this chapter we map the modules on both sides, look at the thin layer of JavaScript that runs them, and open up one sighting.

Here is the whole system, simplified. Each arrow points from a module to a module it imports, and its label says what for. A dashed box stands for a family of modules. Roc forbids import cycles, so no path of arrows loops back.

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
- Modules: `SafariApp`, `Tour`, `FrameView`, `Scene`, `EncounterSighting`

### The ride and the view

The ride is what happens. `RideInstant` holds the four things a step carries, and moves them on: `Rider` moves the rider, and `TruckJourney` moves the truck. `World` lays out the route as a list of segments, and each segment holds its critters, such as the cat and the bird.

The view is what the rider sees. `FrameView` reads one instant of the ride and builds its frame. It paints the backdrop of sky, land and sun, and asks `Scene` for everything else. `Scene` gathers the sightings, and each kind of thing has a sighting module that finds it and a drawing module that draws it.

Every arrow between the two halves points the same way: the view reads the ride. The dotted arrow is the one place where drawing code reads a critter's module. `Cat` takes the cat's pose type and its height from `CatCrossing`, because the crossing decides the pose and the drawing only paints it.

`SafariApp` sits on top of both halves. It steps the ride with `Tour`, which can move the ride forward or back, and it draws each frame with `FrameView`.

### The part that isn't Roc

One tick across the line between JavaScript and Roc
```dot
digraph tick {
  node [shape=box, fontname="Helvetica"];
  fontname="Helvetica";
  subgraph cluster_js {
    label="JavaScript";
    runner [label="keeps time,\ngathers the keys"];
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

Safari Ride runs in a browser. The Roc compiles to WebAssembly, or wasm, and a thin layer of JavaScript runs it. Each frame, the JavaScript keeps time, gathers the keys and calls into Roc. Roc answers with a list of shapes, and the JavaScript paints them on a canvas. Everything about the ride lives on the Roc side of that line. The JavaScript paints shapes and never hears of a cat. "The platform" comes back to this line.

### What's a sighting?

"The problem" said we need machinery to work out what the rider sees. A sighting is that machinery's answer for one thing, on one frame. Here is a real one. At step 1,529 of the ride, a cat is frozen in the road, and `EncounterSighting` sights it:

| Field | Value |
|---|---|
| `right` | 0.38 metres |
| `forward` | 23.63 metres |
| `pose` | `Frozen` |
| `lift` | 0 |

`right` and `forward` place the cat's foot in the rider's view, in metres from the camera. `lift` is its height off the ground. `pose` tells the drawing how the cat stands. In code, a sighting is a small record:

{{code Pipeline.Sighted}}

The `spot` says where the thing stands in the rider's view, and the `kind` says what it is. It holds no drawing at all. Since a sighting is plain data, a test can check it with numbers. The gate checks this very cat's numbers without drawing a pixel.

`EncounterSighting` finds the cat in a few moves. It goes through the segments of road ahead. A segment is one stretch of road between two bends. It asks `EncounterPoses.cat_poses` where each cat is and how it stands. Then it works out where each cat lands in the rider's view, and keeps only the ones in front of the camera and tall enough on the screen to draw.

Each kind of thing pairs a sighting module with a drawing module. `EncounterSighting` pairs with `Cat` and `Bird`, `TreeSighting` with `TreeShapes`, `TowerSighting` with `Tower`, `TruckSighting` with `Truck`, and `BillboardSighting` with `Billboard`, which draws the farm animals, the safari animals at the bends and the ducks. `Scene.scene_in_view` gathers every sighting and turns each one into a `Rendered`: a picture from the thing's drawing module, plus its depth. `Scene.scene_renderings` then sorts the renderings far to near, so nearer things paint over farther ones.

A sighting also decides what doesn't get drawn. Here are more things from step 1,529, and what their sightings decide. A `forward` below zero is behind the camera.

| What it is | `right` | `forward` | What its sighting decides |
|---|---|---|---|
| The cat, frozen | 0.38 | 23.63 | drawn |
| The nearest tree, a big green one | 3.45 | 21.63 | drawn |
| The nearest tree behind the camera, a gold one | -8.09 | -8.36 | out of sight: behind the camera |
| The nearest tree the earth's curve hides, a small green one five segments on | -1,433.43 | 446.00 | out of sight: below the horizon |
| A big green tree just past it | -1,446.07 | 473.21 | drawn |
| The radio tower past the end of the rider's segment | 20.40 | 355.61 | drawn |
| The truck | 92.19 | 489.15 | drawn |

The earth curves, so a small tree far away sinks below the horizon, while a taller one just past it still shows its top. Of the 214 trees on the segments in view, 136 are drawn, 30 are behind the camera, and 48 are below the horizon. None is too small. The other 78 never reach the screen.

All of this happens within one frame. The next frame sights everything again, from its own step's four carried things. Next, we hold one frame still and look at what's in it, starting with the parts that never change.

## The world

Safari Ride builds its whole world before the rider moves an inch, and from then on it only reads it. In this chapter we read that world: a route made of road segments, and the plan for each one. It's the easiest part of the program to read, because none of it changes.

```widget route
The whole route in one picture, one stretch of road for each plan.
```

Each stretch of the map is one segment: the road from one bend to the next. The ride itself draws no map, and it never needs one. A place on the road is always measured within its own segment, as how far along and how far across. We drew this map for the book.

New in this chapter:

- Roc: tag unions in place of booleans, `match` covering every tag, void modules, `var`, record update, `crash`
- Modules: `World`, `Route`, `Segment`, `Trees`

### Get the types right

Each segment starts as a plan, and a plan is a record:

{{code World.SegmentPlan}}

The fields are small tag unions. `CowHerd.Bull` is `[WithBull, NoBull]`, so a plan says `bull: WithBull`, and the value names itself.

Here are the route's first six plans, from `World.bending_plans`. Each one also says how its segment turns into the next.

| Segment | Length | Turn at the end | Trees | Encounter | Herds |
|---|---|---|---|---|---|
| 1 | 500 metres | 50 degrees right | all green | a bird | cows |
| 2 | 320 metres | 70 degrees left | all green | quiet | cows |
| 3 | 400 metres | 20 degrees right | all green | a bird | cows and pigs |
| 4 | 300 metres | 20 degrees right | gold and green | a cat | cows |
| 5 | 300 metres | 70 degrees left | all green | quiet | cows, with a bull |
| 6 | 300 metres | 70 degrees left | all green | a bird | cows, with a bull |

`World.route` builds the route from these plans, once, before the first step. Each plan becomes a `Segment`, and the segment plants its trees, places its herds and plans its encounter.

The modules that build the world
```dot
digraph world {
  node [shape=box, fontname="Helvetica"];
  World [style=bold];
  World -> Route [label="  puts the segments together in"];
  World -> Segment [label="  builds each plan into"];
  World -> PigHerd [label="  picks each pig herd's shape from"];
  Route -> Segment [label="  holds, in order"];
  Segment -> Trees [label="  plants its trees with"];
  Segment -> CatCrossing [label="  places its cat by a tree with"];
  Segment -> BirdFlight [label="  plans its bird's flight with"];
}
```

Even the world keeps as little as it can. A segment keeps its herd of cows, not each cow: a cow's place is worked out from the herd whenever something asks for it. Radio towers aren't kept at all. One stands past the end of every segment, and one halfway along any segment longer than a kilometre, so the segment is all a tower needs.

### The functions

`Trees` plants a segment's trees. It's a void module: `Trees :: [].{ ... }` is a type with no values, because `[]` is a tag union with no tags. The type is only a home for the definitions in its block. Here is how it plants a segment:

{{code Trees.roadside_trees}}

The trees stand in pairs, a left tree and a right tree, every few metres along the segment. Three Roc ideas show up here.

`$along`, `$conifer` and `$trees` are each a `var`, a name the loop gives a new value each time around. The `$` marks it. `roadside_trees` is still a pure function, because no code outside it sees a `var` change.

`{ ..left_tree, road_point: ... }` is a record update. It makes a copy of `left_tree` with a new `road_point`, so the right tree matches the left one in everything but its place.

The last `match` picks the next pair's conifer. A green pair is followed by the segment's accent, and any accent is followed by green. `accent_conifer` turns the segment's scheme into its accent:

{{code Trees.accent_conifer}}

A `match` covers every tag of the union it matches on. Leave one out and the program doesn't compile, so a new scheme can't slip past this function unnoticed.

A segment's place in the route is a `Route.SegmentIndex`, an opaque type like `Pixels`, with a `U32` underneath. No other code can mistake an index for a count of trees. `Route.segment_at` looks a segment up:

{{code Route.segment_at}}

An index past the end of the route is a bug in Safari Ride, so `crash` stops the program and says so. `crash` is for bugs, never for a case the program should handle.

Nothing in this chapter moves, and nothing in the next few chapters does either. We hold one frame still and look at everything in it. First, what a picture is made of.


## A simple tree

Let's draw a tree. Forget the road for now, and the rider, and the ride. All we know is what kind of tree it is, and where it stands from the camera.

Drawing a tree and placing trees along a road are two nearly separate problems. This chapter and the next draw one tree. The chapter after that, Roadside trees, puts trees in the world, relative to the road and the rider.

A tree is a trunk under eight tiers of foliage, and a far tree's tiers are flat triangles. Every tree a long way off is drawn exactly this way. The tree's kind decides how tall it is and what color.

New in this chapter:

- Roc: nominal types, one branch for two tags
- Modules: `Conifer`, `TreeShapes`, `Fraction`, `Camera`

### Get the types right

A tree passes through these types on its way to the screen:

| Type | What it is |
|---|---|
| `Conifer` | A tree's kind: `Green`, `SmallGreen`, `Red` or `Gold` |
| `Distance` | A length in metres, opaque like `Pixels` and an `F64` underneath |
| `RiderView.PointAtHeightAhead` | A point in front of the camera: `right` and `forward` of it, and `height` above the rider's level. `spot.base()` gives the middle of a tree's foot as one |
| `Camera.Upright` | Where an upright thing lands on the screen: its `foot`, and its `height_on_screen` in `Pixels` |
| `TreeShapes.Tier` | One layer of the crown, as fractions of the crown |

A conifer draws from a `Sprite.Setting`, the setting from the Nature types chapter.

Each step of the job is a signature:

| Job | Function | Its type |
|---|---|---|
{{types row Conifer.scenery_sprite Draw a conifer}}
{{types row TreeShapes.tree_sprite Draw a tree of any height and color}}
{{types row TreeShapes.tree_outline Find it on the screen}}
{{types row TreeShapes.tier_triangle Make one tier}}

One tree, from the top
```dot
digraph tree {
  node [shape=box, fontname="Helvetica"];
  "Conifer.scenery_sprite" [style=bold];
  "Conifer.scenery_sprite" -> "TreeShapes.tree_sprite" [label="  hands the height and color to"];
  "TreeShapes.tree_sprite" -> "tier_inputs_of" [label="  calls"];
  "tier_inputs_of" -> "TreeShapes.tree_outline" [label="  finds the outline with"];
  "TreeShapes.tree_outline" -> "Camera.upright_on_screen" [label="  projects the foot and top with"];
  "TreeShapes.tree_sprite" -> "trunk_shape" [label="  calls"];
  "TreeShapes.tree_sprite" -> "tier_shape" [label="  calls"];
  "tier_shape" -> "tier_triangle" [label="  calls"];
}
```

A box is a function, and an arrow is a call. `Conifer.scenery_sprite` is the only box that knows the kind. It derives a height and a color from the kind, and everything below it works from those two. `Conifer` imports `TreeShapes`, and the import runs one way, so `TreeShapes` would draw a fifth kind of tree unchanged.

### The functions

Here's all of `Conifer`:

{{module Conifer}}

`Conifer := [Green, SmallGreen, Red, Gold].{ ... }` is a nominal type. Like `Pixels`, it carries a block of definitions. Unlike `Pixels`, its insides are open to other modules. One symbol makes the difference: `:=` makes a nominal type, whose tags other modules can use, and `::` makes an opaque one. `Trees.accent_conifer`, back in The world chapter, picks `Gold` for a scheme of gold and green.

`scenery_height` derives a tree's height from its kind, so the kind is the one home for it. In `foliage_color`, `Green | SmallGreen =>` is one branch for two tags, because both greens share one color.

`scenery_sprite` takes the kind and a setting, and hands the setting whole to `TreeShapes.tree_sprite`, with the tree's height and color in the record that function wants.

`tree_sprite` finds the tree on the screen, then makes a trunk and eight tiers. Its bars take the setting apart into `spot`, `focal_length` and `darkness`, as a function's bars can take any record apart.

{{code TreeShapes.tree_sprite}}

`tier_inputs_of` starts from `spot.base()`, the middle of the tree's foot as a point in front of the camera, and works out what every tier needs, among them the tree's `outline` on the screen. `trunk_shape` makes the trunk, a rectangle. `tier_shape` makes each tier. `tiers.map(...)` calls it for every tier and gives back the list of answers. `[trunk].concat(...)` puts the trunk first, so the tiers paint over it. For a far tree, `tier_shape` answers with `tier_triangle`, and the next chapter shows the rest of it.

What `trunk_finish_of` and the crown do for near trees can wait, but notice the tags of `TrunkFinish`, `[Shaded, Flat]`. This `Flat` is a different tag from the fill `Flat` in the Shapes chapter. Two tags with one name in two unrelated unions are two different tags.

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

### Get the types right

The whole decision is one type:

{{code TreeShapes.Crown}}

The square brackets list everything a `Crown` can be. This is a tag union, as in The world chapter, and `Cones` and `Triangles` are its tags. A tag is a capitalized name, and it needs no other declaration. So far a `Crown` is one of two names.

The parentheses go further. As in the Shapes chapter, a tag can carry a value, called its payload. The payload of `Cones` is a record with one field, `shade`, and `Triangles` has no payload at all. So a `Crown` is written one of two ways:

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
  "TreeShapes.tree_sprite" -> "crown_of" [label="  decides the crown with"];
  "TreeShapes.tree_sprite" -> "tier_shape" [label="  makes each tier with"];
  "tier_shape" -> "tier_triangle" [label="  far off, calls"];
  "tier_shape" -> "cone_ring_points" [label="  up close, rings the base with"];
  "tier_shape" -> "tier_cone" [label="  up close, calls"];
  "tier_cone" -> "Camera.project" [label="  projects the ring with"];
  "tier_cone" -> "cone_hull_points" [label="  outlines the cone with"];
  "cone_hull_points" -> "ring_hull_points" [label="  merges the ring's arcs with"];
  "cone_hull_points" -> "convex_hull_points" [label="  for a tiny ring, sorts with"];
  "ring_hull_points" -> "hull_points_of_sorted" [label="  walks with"];
  "convex_hull_points" -> "hull_points_of_sorted" [label="  walks with"];
  "hull_points_of_sorted" -> "trim_hull" [label="  drops dents with"];
  "trim_hull" -> "trim_hull" [label="  calls itself"];
  "crown_of" [style=bold];
}
```

`tree_sprite` asks `crown_of` once, and hands the answer to `tier_shape` for every tier. The arrow from `trim_hull` to itself is a function calling itself, and we'll see why.

### The functions

`crown_of` answers with a `Crown`:

{{code TreeShapes.crown_of}}

Two `TreeShapes` thresholds decide how much of a tree gets drawn: `cone_reach`, 200 metres, and `round_trunk_reach`, 60 metres. Shade fades from full at the camera to none at 80 metres.

```widget tree
Three gold trees, each drawn by `Conifer.scenery_sprite`. Under each are its distance and what `crown_of` said.
```

`tier_shape` acts on that decision. It takes the `crown`, beside a `TierInputs`, the record that `tree_sprite` built as `inputs`. That record holds what every tier of one tree needs: the tree's base and height, the lens, its outline on the screen, and its color.

{{code TreeShapes.tier_shape}}

`Camera.project` only works on points in front of the camera. `RiderView` puts that limit at its near plane, 0.4 metres ahead of the camera. `cone_ring_points` builds a ring of 16 points around the tier's base. If any of them reaches back past the near plane, it answers `Err(BehindCamera)`, and the tier falls back to the flat triangle.

A frame holds only polygons, so we work out the polygon a cone would make. We leave pixels behind for a moment and work in metres. `height_down_crown` says how high a point stands, given how far down the crown it is. `top` and `bottom` count down from the crown's tip, so the ring stands at the tier's `bottom` and the apex at its `top`. `tier_cone` projects the ring and the apex onto the screen:

{{code TreeShapes.tier_cone}}

`Brush.corners_shade` makes a fill that is darker at its edges and lighter in its middle, and `strength` says how much, so a near cone looks rounder than a far one. The shade from `crown_of` goes in as that strength.

That leaves 17 points on the screen: the ring's 16, and the apex. A cone's outline is the shape that wraps around them all, with no dents. That's called a convex hull:

{{code ConvexHull.cone_hull_points}}

The method is Andrew's monotone chain, which A. M. Andrew published in 1979. Put the points in order from left to right. Walk along the top, then walk back along the bottom. Any points can be sorted into that order. `convex_hull_points` sorts them, for a ring too small to have two arcs:

{{code ConvexHull.convex_hull_points}}

`sort_with` sorts by a function that compares two points and answers `Before`, `Same` or `After`, and `left_to_right` is that function: left first, and the higher of two at one x. A cone's ring comes in order already. It's convex on the screen and keeps its order around the circle, so `ring_hull_points` merges its two arcs from the leftmost point to the rightmost, slots the apex in, and has the points in order already. If rounding leaves the merge out of order, it sorts after all. Either way, the walks are `hull_points_of_sorted`:

{{code ConvexHull.hull_points_of_sorted}}

The top walk ends on the rightmost point, where the bottom walk starts, and the bottom walk ends on the leftmost, where the top walk started. So each walk drops its last point before the `concat`, and no corner appears twice. `fold` walks a list from the front, carrying an answer from item to item, and `fold_rev` is the same from the far end, with its arguments the other way around. `trim_hull` serves both walks: before a point goes on, it drops the last point of the hull while that point would make a dent, and it calls itself until none does. `[.., a, b]` is a list pattern that takes the last two items.

{{code ConvexHull.trim_hull}}

A whole cone comes out as one polygon. The ring gets wider on the screen as it gets nearer, so the tree fattens as you pass.

So much for one tree. The road has hundreds.

## Roadside trees

Here's the other tree problem. Safari Ride places 392 trees along its road, and only some of them are in view at any moment. For each frame, it has to find those, and say where each one stands from the camera. Once a tree is found, `Conifer.scenery_sprite` from the chapter A simple tree draws it. The kind still matters here in two places: a gold tree is placed farther from the road, and a tree's height decides whether it's tall enough on the screen to draw.

```widget frame trees
Step 1,529 of the ride, with only the trees on.
```

This is step 1,529 again, the frame with the frozen cat, showing only its trees. There are 136 of them, out of 392. At nine shapes each, they make up 1,224 of the 2,121 shapes in that frame, more than everything else put together.

A tree goes through the three forms from the Nature types chapter, with a `Conifer` as its kind. It's placed once, for the whole ride, and sighted and rendered for each frame that can see it.

New in this chapter:

- Roc: `while` in a pure function
- Modules: `TreeSighting`, `RoadAhead`

### Get the types right

A placed tree has a name of its own: `Trees.RoadsideTree` is another name for `Geom.Placed(Conifer)`. A tree's sighting is a `Pipeline.Sighted(Conifer)`, and its rendering is a `Rendered` like any other.

| Job | Function | Its type |
|---|---|---|
{{types row Trees.roadside_trees Place a segment's trees, once}}
{{types row TreeSighting.trees_in_view Find the trees in view, for each frame}}

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
    "Pipeline.scenery_sighting_of" -> "Pipeline.sighting_above_horizon_of" [label="  starts with"];
    "Pipeline.sighting_above_horizon_of" -> "Pipeline.sighting_of" [label="  starts with"];
    "Scene.scene_in_view" -> "Pipeline.rendering_of" [label="  renders each tree with"];
    "Pipeline.rendering_of" -> "Conifer.scenery_sprite" [label="  calls through its where clause"];
  }
  "Trees.roadside_trees" -> "TreeSighting.trees_in_view" [style=dotted, label="  the trees, read again"];
  "TreeSighting.trees_in_view" -> "Scene.scene_in_view" [style=dotted, label="  the sightings, handed on to"];
  "Conifer.scenery_sprite" [style=bold];
}
```

A box is a function, and a solid arrow is a call. A dotted arrow is a step's answer going on to the next step: the trees that `World` placed, read again for each frame, and then the sightings, which go on to be rendered. `Conifer.scenery_sprite`, in bold, is where the chapter A simple tree began.

### Placing

Placing a segment's trees walks along the segment and keeps a list, and a loop says that best.

{{code Trees.roadside_trees}}

Guess which Roc idea from The world chapter comes back? `var` makes a name that can change, and a `$` marks every use of one, so the names that change stand out. The `while` loop changes them, and the function is still pure, because the changes stay inside it.

Trees stand in pairs, one on each side of the road, every 30 metres. `{ ..left_tree, road_point: ... }` makes the right tree from the left one, with a new place across the road, by the record update from The world chapter. The pairs take turns: a big green pair, then a pair of the segment's accent, which is small green, red or gold, then big green again. A gold pair stands farther from the road, because it's so much taller:

{{code Trees.tree_line_distance}}

### Seeing the trees

For each frame, `trees_in_view` goes through the segments of the road ahead, the ones the rider can see. `join_map` is a `map` followed by a flatten:

{{code TreeSighting.trees_in_view}}

{{code TreeSighting.segment_trees}}

From here on, things are measured from the camera, which travels with the rider. We don't need to know much about the rider yet.

{{code Pipeline.scenery_sighting_of}}

`Pipeline.scenery_sighting_of`, from the {{chapter Refused}} chapter, puts each tree through three tests, one inside the next:

1. `Pipeline.sighting_of` asks `RoadAhead.rider_point_at` where the tree's place on the road lies from the rider. The math layer chapter shows how. A tree nearer than the near plane, from the chapter A conifer, is `OutOfSight`.
2. `Pipeline.sighting_above_horizon_of` asks whether the curve of the ground hides the whole tree. If it does, the tree is `OutOfSight`.
3. `scenery_sighting_of` itself measures the tree on the screen, through the camera's focal length. A tree under 2 pixels tall is `OutOfSight`.

`segment_trees` passes along `from_rider`, which says which segment of the road ahead the tree stands on, counted from the rider's. It's usually `Ahead(position)`: a segment so many ahead of the rider's.

So the answer is a `Try`: a sighting, or `OutOfSight`. `keep_oks`, in `segment_trees`, keeps the sightings and drops the refusals.

### Spending the detail

Far trees are cheap. They get eight triangles and a plain trunk. A cone costs a ring of 16 points and a hull, so only trees within 200 metres get cones. A shaded trunk looks round, and the effect only shows on a trunk wide enough on the screen, so it goes to the trees within 60 metres, the nearest two pairs, and no others. `tree_sprite` decides it from the tree's distance, as it decides the crown:

{{code TreeShapes.trunk_finish_of}}

{{code Scene.scene_in_view from "trees:" to "trees:"}}

`Pipeline.rendering_of` hands each tree to `Conifer.scenery_sprite`, and the tree's `Rendered` joins the towers' and the critters' in the frame's one list.

So `World` holds every tree's place for the whole ride. Each frame derives its sightings fresh, from those places and the camera, and the next frame derives them all again.

Most things in a frame work this way: placed once, then sighted and rendered for each frame. The grass is simpler still.

## The sun

The sun is a circle. That's the easy part, so it's the part we'll do here.

New in this chapter:

- Roc: tags in place of `null`
- Modules: `Sun`, `Angle`

### A circle

A frame is a list of shapes, and a circle is one of them. `Disc` is a tag from `lib.Shapes`. This is the sun's, from `Sun.sun_shapes`:

{{code Sun.sun_shapes from "Disc({" to "fill: look.disc,"}}

A `Disc` has a center, a radius and a fill. The grass comes after it in the list and paints over whatever falls below the horizon, so the sun can sink behind the land with no more code.

The fill makes it look like a sun. `Sun.look` builds two fills: one for the disc, and a glow behind it:

{{code Sun.look}}

`Radial` runs from pale yellow in the middle to orange at the edge, and `warmed` reddens both as the sun nears the horizon. `Glow` is a wide haze that fades to nothing, and `sun_shapes` adds its light to the sky rather than painting over it. Both are tags with records inside, so a fill is plain data, and the browser does the painting. The lens's `focal_length` sets how large the sun is drawn, because a wider view makes it look smaller.

### Angles that can't be mixed up

The sun stands in one direction, and the rider may not be facing it. That needs angles. `Angle.Bearing` is a direction in the world and `Angle.Turn` is a change of direction. Here we pass a `Turn` where a `Bearing` is wanted:

{{fails turn_as_bearing}}

Opaque types do the most work from here on. A `Bearing` and a `Turn` are both floats underneath, but only the `Angle` module can build or open one.

Two tags say whether the sun is in view, so there's no `null` and no off-screen sentinel value. A caller has to handle `OutOfView`, because `match` must cover every tag.

{{code Sun.Sighting}}

{{code Sun.sun_in_view}}

`sun_in_view` asks `Lens.far_point` where the sun lands on the screen. `far_point` takes one record argument, taken apart in its parameter list. `turn.abs() >= quarter_turn` compares two `Turn`s. The angle stays a `Turn` until the trigonometry. `.tan()` works on a float, so only there does `to_radians()` open it.

{{code Lens.far_point}}

`sun_in_view`'s caller, `FrameView.frame_view_at`, is short enough to read whole:

{{code FrameView.frame_view_at}}

Most of what `frame_view_at` calls takes the clock, and that's the hard part. The sun sinks a little with every step, and the sky's colors, the mountains and the truck's headlights all follow it. That's a lot of heavy lifting for a circle. It gets a chapter of its own, The setting sun, once things start to move.

## Appendix: the patterns

Eight patterns kept turning up in the tour. They're patterns in a loose sense: shapes of code that Roc makes easy to write and hard to break.

| Name | What it is | Where to see it |
|---|---|---|
| Worked out, not stored | Keep the few things that must persist, and derive the rest each frame | `RideInstant`, `Cat`, `Sky` |
| A sighting decides, drawing paints | A pure function answers with plain data, and something else draws it | `EncounterSighting`, `TowerSighting` |
| Places and distances | One opaque type for where, a second for how far apart, and only the sums that make sense | `Clock` and `Steps`, `Bearing` and `Turn`, `Along` and `Distance`, `Speed` and `Acceleration` |
| Rule and timeline | One function says how far along an animation is, and a timeline, plain data, says what the animal looks like at each stage | `BirdFlight.flight_stage` and `BirdFlight.flight_timeline` |
| The step function | A value goes in, and the next value comes out | `Rider.rider_at_next_step`, `TruckJourney.truck_progress_at_next_step`, `Tour.step_forward` |
| The chain of limits | One value passes through independent rules, each of which can only lower it | `Throttle.next_acceleration` |
| One record per space | Field names say which coordinate system a point is in | `RoadPoint`, `RiderPoint`, `PointAtHeight`, `Point` |
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
| A crash with a sentence about a sum | `Fraction.of` crashes on a ratio outside 0 to 1, because such a ratio means the sum behind it is wrong. A ratio that can rightly fall outside the range goes through `Fraction.clamp` instead | The sky, Proving it |
| The first frame of an animation shown too soon | `Waiting` and `Past` aren't progress of 0 and 1. Before its animation starts and after it ends, a critter can rest in a place or pose that no frame of the animation shows | The cat |
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
| Encounter | The one event a segment can hold: a cat crossing, a bird flying, or neither, a quiet road. |
| Encounter plan | One of the four things remembered: whether the encounter on the rider's segment is planned yet, and the step it starts at. |
| Far scenery | The sun, the mountains and the rolling land: a direction and a height above the horizon, and never any nearer. |
| Frame | Everything shown for one step: the backdrop, the mountains and the ground, then a series of pictures, far to near. |
| Gawking | What the speed does for a pig: the rider slows for it, and stays slow to the end of the segment. |
| Kind | Which sort of object something is, like `Conifer`. |
| Look | What the eyes do for a pig: they turn toward it, and follow it until it's too far round. A crossing cat holds the eye without a look: it raises the rider's attention, which widens the view. |
| Motion critter | A hand-drawn critter that moves, like the cat and the bird. |
| Near plane | The closest the camera can see, 0.4 metres ahead. Anything that crosses it is cut there. |
| Object | A thing in the picture with a place of its own: a tree, a tower, a critter or the truck. |
| Painter | What puts shapes on the canvas. The page's painter is the browser's canvas, and the proof's is written in Roc. |
| Sprite | How one object looks in one frame. A frame holds many pictures, one for each object in view, so "a picture" never means the whole frame. |
| Placed | Put on the road, measured `along` and `across` a segment, and `lift` off the ground. |
| Polygon | A shape with five or more corners. A frame's shapes with three or four are triangles and quads. |
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
