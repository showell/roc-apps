# The Safari Ride book: its mission and its rules

Read this before you touch the book, and again after every compaction. It says how to write a strong book. It is also an example of the voice: strong and authoritative, with a simple, clear structure. The book won't copy this document, but it shares that voice.

Steve agreed to this on 2026-11-10. It pulls together a week of his feedback on drafts. Change it only when he does.

## 1. The mission

The book walks a programmer through one real Roc program, Safari Ride, from the whole down to the details and back out. A reader should finish it knowing two things. First, how a program with a lot going on can stay simple: a small state carried from step to step, everything else derived from it, and types that leave a wrong state nowhere to live. Second, how Roc makes that natural, mostly with vanilla code.

The reader is a working programmer, probably coming from TypeScript or something like it, who can read a little Roc. The book never compares Roc to another language. It explains each Roc idea on its own terms, where it first bites.

Take Moby Dick as an inspiration, alongside Hemingway. One theme rides through the whole book: a small carried state, with everything else derived from it. Each chapter is still a strong vignette on its own.

The book is honest about the code. It quotes the real code, its numbers come from the real program, and when a sentence is hard to write, we fix the code first.

The book is a book-like experience, made for the desktop: a reader at a wide screen, with the ride and the widgets running beside the text. The phone is extremely low priority.

## 2. The requirements, axis by axis

Each axis fails in its own way, and catching each failure takes a different kind of read. Truth needs the code open beside the page. Order needs a reader who has seen only the pages before. Voice and tone need an ear. Vocabulary needs the glossary. The code axis needs a smell-hunter. Pictures need eyes. Completeness needs a checklist. Purpose needs the whole book in view.

### Axis A. Purpose: every chapter teaches something real

- **A0.** **Keep simple things simple.** The reader already knows what a triangle, a tree and a cow are. The code's job is to express those concepts plainly. The book's job is to add only what the reader can't guess: the choices Safari Ride made, and why. Every reader knows a triangle has three corners; what they can't guess is that Roc describes the triangle instead of painting it. Everyone knows a tree is a trunk and a crown; the news is that the ride draws two versions of a tree, and why. A cow is a cow; the news is that the ride draws it as a billboard emoji, because that's less code and it's charming. When a simple thing takes long to explain, the code is too complicated: fix the code first (G1). This rule governs every other one.

- **A1.** A chapter teaches one idea about writing clear Roc, or one axis of difficulty from the axes note (essay-repl-server notes/axes-of-difficulty.md), or a harder case of one. The axes are shapes, placement and projection; motion; the camera; rider physics; what covers what; honest cheats; the platform edge; proving it.
- **A2.** "Who owns this behavior?" is the question every chapter answers again. It is not a chapter of its own.
- **A3.** The spine shows through every chapter:
  - each step carries four things, and the program derives the rest;
  - within a step, the world and the rider change each other, and order matters;
  - there are three sorts of thing: solids, cards and far scenery;
  - each tick is a pipeline.
- **A4.** Really teach something without forcing the issue. Most of the code is vanilla, and that's a feature. Don't invent a new Roc concept for every chapter.
- **A5.** Say what Roc *is*. Don't bash OO or any other style.
- **A6.** The scope is Safari Ride. The repository's other canvas apps are completely out of scope: never mention them.

### Axis B. Truth: every sentence matches the code today

- **B1.** Code comes in by include (`{{code M.f}}`), never pasted. The gate holds stale names at zero, and the book must name every module.
- **B2.** Every number in the prose is the program's number, pinned by an expect or a table the gate builds. Nothing is "about right".
- **B3.** No old bugs, no history and no "used to". Write in the present tense. "By construction" says enough.
- **B4.** No complicated design reasons inferred for simple choices. Give a constant its plain reason, and a computed one its calculation.
- **B5.** An argument is earned by what the reader has seen. Don't defend a feature the book hasn't shown.
- **B6.** A rewritten sentence is a new claim. Check it against the code before it lands, above all when it turns a "doesn't" into a "does". In batch 2, three of the twelve false sentences came from rewrites like that.

### Axis C. Order: a reader who has read only what's above

- **C1.** Top-down and simplest first. The forest comes before the trees. Lead with the function that frames the problem, as `Truck.truck_picture` does for the truck chapter.
- **C2.** Inside a chapter: the problem first, as needs. Then "Get the types right", with the flowchart right after it. Then the functions.
- **C3.** Never lean on something unseen. A forward pointer names what's coming and why, or it goes.
- **C4.** Every chapter's opening stands alone, usually by restating the premise. A chapter's end may leave a question hanging. Readers land anywhere, so avoid "remember the first chapter" callbacks for simple ideas: explain them in place.
- **C5.** **Finish one thing before you start the next.** Take the triangle all the way from its call to its `Poly`. Only then say "Next, let's build a rectangle", and let the rectangle lean on what the triangle taught. Two things explained side by side make the reader hold both at once. The headlights and the brake lights taught this first. One job gets one section, and the job comes before its details.
- **C6.** Difficulty rises, tempered by categories: nature, man-made, critters. The exception is the opening: critters standing still come first (Things, then Billboard Critters), because a billboard is the simplest thing the ride draws, and the most charming. One frame is held still for the first half, and motion starts at The ride instant. Teasing an idea early is fine.
- **C7.** Everything that appears says why the reader needs it now. A type or module with no reason to be in this chapter moves to the chapter that needs it. Telling the reader that a `GroundPatch` is a patch of ground, with no reason it's here, leaves them disoriented.
- **C8.** Motivate the need before the code (D5), but never describe a function's details before the reader has seen it. A function with a long body shows its type annotation alone (`{{signatures M.f}}`) until the body's turn comes, and the prose calls it an annotation. A very small function shows whole.
- **C10.** **Put yourself in the reader's shoes.** Read every draft as someone who has read only the chapters before it. At each paragraph, ask: do I know why I'm reading this, and could I explain it back? A chapter that follows the drawing of a triangle with a map of a hundred modules fails that reader, however true the map is. The thread the reader just picked up comes first.
- **C11.** Every item in "New in this chapter" is really taught: what it is, the line of code that shows it, and why it matters here. A list of four Roc ideas waved at in passing is worse than no list. Fewer ideas, each explained properly.
- **C12.** **If you promise something to the reader, you must pay it off. The sooner the better.** A teaser, an opening, a "we'll see", a question left hanging: each is a promise. Pay it in the same chapter when you can. A promise paid later says so plainly ("the second half of the book shows…"), and the later chapter really pays it. Orient the reader, then summarize. Readers think well in concepts, but their memories are short and their attention wanders. So say what's coming, say it, then say what you said, and keep the three in sync. When in doubt, get straight to the point. The book teaches Roc, so it shows a lot of Roc; that goes without saying. Don't brag about what the reader should expect anyway ("That's a feature"). Safari Ride is a screensaver, and the book says so plainly. A game can come up, with restraint: briefly, where the chapter at hand leads to it, and after the book has earned it. The book's mission comes first, so a mention never pulls the reader away from it or oversells what the ride could become.
- **C14.** **After "A far tree", the reader reads Roc, so stop walking through code.** By then the reader knows how a function's arguments take a record apart, what `map` does, and how a body names its values. Show readable code and call out only what is new to the reader or runs against intuition. Set a high bar for the code's readability: code that needs a walkthrough to be understood is a code finding first (G1), so fix the code, then show it. (Steve, 2026-11-11.)
- **C13.** **Fix by subtraction first.** When a reader stumbles on something unexplained, first ask whether it can leave the page, then whether it can move to where it's needed, and only then explain it in place. A paragraph carries at most two new ideas, and an animation idea (a frame, perspective, a lens, depth order) counts as one just as a Roc idea does: the reader is learning both at once (Anton on Zulip, 2026-11-11). Fixes by addition are how a short section ends up holding eight ideas in two paragraphs.
- **C15.** **The opening says what's ahead.** A chapter's opening tells the reader quickly what's coming, so a reader who knows it already can skim. Don't offer the skim in so many words. When a chapter's point is a Roc concept, such as `match` or `where`, the paragraph after its picture can name it. Most chapters need no such preview, and one where the code speaks plainly is just more words. (Steve, 2026-11-11.)
- **C9.** Name other chapters rarely. When you must, put the title in quotes ("A simple tree"), and say what it holds.

### Axis D. Voice: the sentences themselves

- **D1.** **Active voice.** "We carry a small amount of state… we derive values from it", never "four things are remembered" or "everything else is worked out".
- **D2.** **Say what happens. Never say what something isn't.** No sentence describes a thing by what it isn't, can't do, doesn't do, never says or doesn't remember: "The plans never say where a single tree stands", "can't go stale", "has never heard of a tower". Say what it does, or cut the sentence; usually the sentence wasn't needed. Negative contractions (can't, isn't, doesn't) are a smell: a run of them, such as "We can't place a tree we can't draw", is always rewritten or struck. A negative is fine only where the program's own behavior is a refusal, such as a tag that says why a thing isn't drawn.
- **D3.** Short sentences: Hemingway, not Faulkner. A strong sentence stands alone. Don't join two sentences that could stand on their own with a comma or ", but".
- **D4.** Talk to the reader with "we", "you" and contractions. Start the book, and each chapter, with a full sentence, never a fragment. The first sentence makes a strong first impression. It doesn't have to be "Call me Ishmael", but it earns the reader's attention.
- **D5.** **Let the code speak for itself.** Functions and records mostly do, so a line of setup before them and a little syntax after is plenty. An idiom that doesn't speak for itself, such as `where`, gets its motivation before the code: the need, in ordinary causal words ("That's because…"). The prose after a snippet clarifies only syntax the reader can't read yet. Be flexible: it's a judgment for each snippet, not a template. (Steve, 2026-11-11.)
- **D6.** Use plain verbs (is, does, gives, takes), not abstract nouns. Keep prepositions ("For each frame it calls", not "Each frame it calls").
- **D7.** No agent-speak:
  - appositives ("`truck_blue`, a navy, paints…");
  - "the way from X to Y is…";
  - "and that's the point of this chapter";
  - "worth saying again";
  - a pronoun (this, that, it) whose noun the reader has to hunt for. A pronoun points at the nearest noun it can mean, or the name goes back in. Steve leans further against pronouns than most writers, so when in doubt, use the name. Still, a pronoun in a short sentence whose noun is right beside it is fine; don't strip them all. A "this" or "that" where a name belongs. After the cat's code, "This is why the cat waits" makes the reader hunt for what "this" is. "`plan_crossing` is why the cat waits" names it;
  - aphorisms, "not X but Y" drumbeats, or a closing moral.
- **D8.** Explain a type precisely rather than apologizing for its name.
- **D9.** A paragraph makes one point and holds together. A connective such as "Either way" or "So" points at something named in that paragraph, or it goes. A claim is complete: "checks" says what it checks.
- **D11.** **Precise verbs for Roc's constructs.** Code isn't a person: a `where` clause constrains a type variable, a type describes values, and a function takes and gives back. When the official tutorial or the langref phrases a concept, say the same thing in our own words, with its core terms. (Steve, 2026-11-11.)
- **D10.** Write with the authority of this document: confident, declarative claims, in a simple, clear structure. The book is warmer and slower than a rules document, but just as sure of itself.

### Axis E. Tone: how it feels to read

- **E1.** Dry, plain and technical, with the jargon the audience already knows ("completely deterministic"). Some cleverness is charming ("a tour of a tour"), but don't overdo it.
- **E2.** Humor is restrained: at most one exclamation mark a chapter, and a rare "hooray".
- **E3.** Repetition teaches, so keep a returning idea. A returning idea is the place for a wink ("Guess which technique comes up again?"). A guess is about an idea, never about arithmetic.
- **E4.** No bragging that simple code is simple. No presumed reactions from the reader.
- **E5.** Vary the chapter endings. Ending on what's still missing is a good move, but it isn't a template.

### Axis F. Vocabulary: one word for one thing

- **F1.** These words keep their meanings: frame, step, sighting, spot, kind, picture, sprite, rendering, segment, critter (an English word, never a type), solid, card, far scenery, carried, derived.
- **F2.** Every term goes in the glossary, and the book uses the glossary's word.
- **F3.** Write "math", not "maths". "Metres" and "colour" are fine. Write "forward" and "backward", never the "-s" forms.
- **F4.** Types name numbers. Never say a `Pixels` isn't a number.
- **F6.** Always say what a name is. "`FrameView`" alone leaves the reader guessing whether it's a module or a type. Say "the `next_or_restart` function takes…", "the `World` module holds…", "a value of the `SegmentPlan` record type goes to…".
- **F5.** "Picture" means everything on the screen in one frame, what the camera takes in. One thing's shapes in a frame are its **sprite** (the `Sprite` type), a word we use in the loose sense. Introduce it once with authority ("We call these sprites"), with no apology.

### Axis G. The code behind the prose

- **G1.** The book is a code review. A sentence that's hard to write, or that exposes an odd design, is a code finding first, and the chapter follows the fix.
- **G2.** Quote code that reads more or less like English. Code should answer to its name.
- **G3.** Coordinate transforms belong in one home. A chapter that has to explain the same transform twice is a smell.
- **G4.** The smells in `docs/smells.md` apply: a fat API, a derived value stored beside its source, a name that needs a comment to translate it.
- **G5.** Keep a fact in the type rather than checking for it later. A triangle that passes its corners through a list loses their count, then needs a crash to win it back. A record of three corners is a triangle by construction, and needs no check. A one-line wrapper that adds no meaning goes: inline it.

### Axis H. Pictures: diagrams, tables and widgets

- **H0.** A widget is just a picture. It keeps the reader engaged, and shows what the code produces, in a tiny bit of context. A chapter about cows shows a cow standing on the grass by the road, seen from an angle. Don't overcomplicate it: a picture's code is a thin wrapper around Safari Ride's own code, never a project of its own.
- **H1.** Put a diagram early. Every edge has a label, a verb and often the function that does the work ("finds it with truck_in_view"). An edge whose only honest verb is "imports" is worth a look.
- **H1a.** Every box stands for something real in the code, and the diagram shows the reader something the prose needs. A box labelled "triangle" pointing at `Polygon.triangle` shows nothing. A diagram that illustrates no point goes.
- **H2.** In the One frame half, a widget is a static frame. VCR controls come only once time passes. There are no sliders.
- **H3.** A widget gets one sentence of explanation, not a listing of its code. It says which call it adds and what it shows.
- **H4.** A table is welcome wherever it shows data the program really produced.
- **H6.** **Be relentless about cruft.** Anything pulled in from prior work, a widget above all, has to fit this page completely. A readout made for another chapter ("Added: The moving things") is cruft here. When the picture does the job, show the picture alone, and change the widget's code to do so.
- **H7.** **The picture comes before the details.** A picture orients the reader to the task at hand, so put a chapter's widget right after its opening, before most of its code and prose. (Steve, 2026-11-11.)
- **H8.** **When a code snippet introduces several concepts, a table is effective for the reader.** By default it's concept-driven, with three columns: Concept (a Roc idea in plain words), Purpose (one well-chosen word) and Explanation (which points at the code that shows it). The Purpose words form one set, as "The problem"'s challenges do. One brief sentence before the table says it explains the code's concepts. "The problem"'s table and the `Conifer` table in "Nature types" are the models. A syntax-driven table, one row per piece of code, suits some other snippets. (Steve, 2026-11-11.)
- **H9.** **Every chapter gets a picture of its own.** When two chapters share an illustration, that's a smell that one of them isn't load-bearing. Look at the chapter first, then give it the picture only it needs. (Steve, 2026-11-11.)
- **H5.** Lay pages out for a desktop reader. A diagram is sized for a wide screen. On a phone it may be small or scroll; that's acceptable.

### Axis I. Completeness: what "done" means for a chapter

- **I1.** It has a problem, its types, its functions and an ending, plus "New in this chapter" when it introduces something new.
- **I2.** Every sentence in book-parked-sentences.md (essay-repl-server notes) that points at it is fixed or struck out.
- **I3.** The gate is green, and the book is rebuilt on the dev channel.
- **I4.** Steve has read it, and his replies are answered.
- **I5.** For the whole book: the glossary is current, the appendices match the chapters, and Zooming back out sums up exactly what the chapters showed.

## 3. How the book gets finished

### Who does what

Claude is the author and the coder. Claude writes every sentence and every line of code, and Claude runs the project plan: what comes next, what waits, and who is doing what.

Steve is the editor and the customer. He reads, he marks what's wrong, and he has the final word on everything. He is also a member of the project, so the plan keeps him on one task at a time and never pulls him off it for something that can wait. Every message to him ends with one line: what he is working on now, or the one thing to do next.

On the things that matter most, the two of us are collaborators. Together we refine this mission, and together we decide how to improve the code's internals.

### The loop

The work is a linear pass, one chapter at a time, in book order, starting again from the Introduction.

**We're starting over from scratch.** The book is the chapters that have passed this loop, and nothing else. The rest of tutorial.md was written by another team, old Steve and old Claude. It's a source of facts and includes, never a structure we owe anything to. We're bound by what the new chapters promise, not by the old book's order.

**Know which assets are durable.** Two things go wrong with assets, and we're far more prone to the second. Forgetting a good asset, such as rebuilding by hand what a debugged script already does, means doing the same thing twice. Trusting a bad one means shoddy work never dies. So assets come in two classes:
- **Durable:** tools whose job doesn't depend on the book's content. That's the gates, `build.shale` and its includes, `book.shale`, `color_roc.shale`, `book_check.mjs`, the lints, and this document. Use them every time.
- **Provisional:** anything that carries old content or old structure. That's widgets and everything they draw, captions, the code comments an include quotes, `Book.dividers`, the glossary, the appendices, and the old chapters' sentences and order. A provisional asset is wrong until re-read. Its first appearance in the new book is a critical review: keep it only if it fits this page completely, change it or its code if it doesn't, and cut it if it can't (H6, C13). This session's cruft all came from this class: the flipbook and route readouts, `Book.dividers`, the `Picture` name, a false comment in `Geom.Placed`, and a chapter shaped by an outline built for another purpose.

**Write a clean draft every time.** Every chapter gets a clean draft, written fresh, every round. Don't regurgitate the old text, and don't edit it yet. Editing comes later, once a clean draft has earned it. Reworded old sentences are the old draft in disguise, and Steve can tell.

**The loop, for one chapter:**

0. Before drafting, pause and ask Steve three questions, one at a time, each a why: "Why did we put Clock so early in the original drafts?" A why digs out the reason a chapter, a section or a piece of code exists, and his answers shape the draft.
1. Read the chapter and the code it quotes.
2. If the prose exposes a smell (G1), fix the code first. A small fix lands now. A bigger one goes in the queue, and the chapter describes the code as it stands.
3. **The spine.** Before any prose, write the chapter as one sentence per paragraph, usually six to ten. Each sentence after the first follows from the one before by "so" or "but", never "and also". The first sentence orients the reader, and the last says what the reader now has; write those two together, so the opening's promises and the close's summary stay in sync (C12). If the spine doesn't flow, the prose won't either, and a spine is cheap to fix. When a chapter's structure changes, write a new spine and a clean draft from it, never surgery on the old text.
3b. **The draft.** Write a clean draft from the spine, with a strong voice, from the reader's questions: what is this for, why now, what does it show? Close the old draft before you write. It is a source of facts and of includes, never of sentences. Then check it against axes B through I. The writer writes the prose; nobody else does. Check every diagram edge against the code, and give every edge its label (H1).
3c. **The author's read.** Read the whole chapter top to bottom in the built page, as a reader who has read only what's above. This read happens after every change, not just the first draft. Check:
   - every hand-off: read each paragraph's first sentence right after the last sentence before it. A paragraph nothing leads into, or that leads nowhere, is an orphan, and it goes;
   - every widget, its caption, and everything it draws, against this page (H6);
   - the title against the chapter;
   - any word used in two senses in one stretch ("frame" for a picture and for framing a problem) (F1);
   - the opening against the close.
4. Run the quick gates (`part=tutorial` and the lints), commit, push, and rebuild the book. A change under a widget's folder, `widget_kit` or `BookFence.roc` also runs `part=widgets` before the push; a widget's own `roc check` and `roc test` are not enough. The long gates (`part=expects`, the widget release builds) are the only thing a chapter defers: they run in the background and catch up with it.
5. **The promise check.** Before Steve sees anything, a cold agent reads the draft for promises (C12). It lists every promise the text makes to the reader, and for each it says where it's paid: in this chapter, or later, framed as later, in a chapter that really pays it. A promise that's unpaid, or paid later without saying so, gets fixed before the note goes out. Phrase every fix yourself. We run this check on every draft until keeping promises is a habit.
6. A note to Steve holds the chapter and nothing else. He reviews a chapter on its own merits, so leave out the meta: no recap of the whys, no list of fixes. The chapter's own heading marks where it starts. Anything he must decide goes in the console, not the note.
7. Steve reviews the chapter. His replies are answered, and the chapter is done (I4), before the next chapter's whys begin.

**One chapter at a time.** Each chapter goes through the whole loop, Steve's review included, before the next one starts. Nothing batches up but the long gates.

**Cold readers.** Every chapter also gets one cold reader that checks just two things: truth against the code (B), and order for a reader who has seen only the pages before (C). Those are the two axes where the writer can't see past their own outline. It runs alongside the promise check, before the note goes out. Take its findings with restraint, and phrase every fix yourself.

**The animation reader.** The reader learns Roc and animation at once (Anton on Zulip, 2026-11-11), so every chapter also gets a cold reader who knows a little Roc and nothing about animation or graphics. It tags each new idea as Roc or animation, and reports the paragraphs where the two pile up, the animation used before it's explained, and any math that shows through. It runs with the truth-and-order reader. The first audit, of chapters 1 to 10, found "A far tree" and "The pieces as types" the heaviest.

**The think-aloud reader.** A third cold reader reads the whole chapter and narrates its understanding paragraph by paragraph: "Now I know X. I expect Y next. This paragraph gave me Z instead." Where its expectation and the page part, there's a flow break. It proposes no prose.

**Nitpick rounds.** After the fixes from those three, a fresh cold agent reads the built chapter and lists the five things a careful reader would stumble on. Its brief gives no clues: no axes, no worries of ours, no list of past findings. Fix what's real, rebuild, and send a new agent. Stop when a round turns up nothing worth fixing, or after three rounds. Nitpickers find friction well and real-world sense poorly (a bull isn't a cow), so the author's read still checks the world.

**One voice.** However many readers a chapter gets, none of them writes the book. Their findings are reports; one voice phrases every fix, and it fixes by subtraction first (C13). Take suggestions with restraint, or the book reads as if a committee wrote it.

**The order before Steve sees a chapter:** the author's read and the quick gates, then the promise check and the truth-and-order reader together, then the think-aloud reader, then the nitpick rounds, with a fix and a rebuild after each. Steve gets a chapter that has survived all of them.

**The vocabulary.** The carried-and-derived wording reaches each chapter as it comes up, not in one sweep, so every change lands in a chapter Steve is about to read.

**The order of the pass:**

1. Introduction, The problem, Platforms, The pieces as types, Things (the cow), Billboard Critters (tag unions and `match`), then the far tree (functions: a body, local names, `map`, paint order). Shapes is its own chapter before the far tree, or the far tree's opening; Steve decides when we get there. The modules and The world are open.
2. Nature types, Grass. Trees get only the far-tree chapter, plus a paragraph that tells the reader what the rest of the tree code does.
3. The sun, The sky, Mountains, The road, Rails, Radio towers
4. Stills, The elephant, the corner critters, Herds
5. The clock (merge its overlap with The beacons), The ride instant, The beacons, The setting sun, Stepping through the ride
6. The rider, The bike, The throttle, The rider's gaze
7. The truck, The truck's motion, The truck's lights
8. The cat, The bird, What a cat does to the rider, Rehearsal
9. The math layer, Proving it, The platform, Zooming back out, the appendices, the credits

When the day runs short, the chapters Steve has already read get the lightest pass, and the rest wait at the same standard. Never lower the standard to make a date.
