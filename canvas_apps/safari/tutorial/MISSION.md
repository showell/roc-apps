# The Safari Ride book: its mission and its rules

Read this before you touch the book, and again after every compaction. It says how to write a strong book. It is also an example of the voice: strong and authoritative, with a simple, clear structure. The book won't copy this document, but it shares that voice.

Steve agreed to this on 2026-11-10. It pulls together a week of his feedback on drafts. Change it only when he does.

## 1. The mission

The book walks a programmer through one real Roc program, Safari Ride, from the whole down to the details and back out. A reader should finish it knowing two things. First, how a program with a lot going on can stay simple: a small state carried from step to step, everything else derived from it, and types that leave a wrong state nowhere to live. Second, how Roc makes that natural, mostly with vanilla code.

The reader is a working programmer, probably coming from TypeScript or something like it, who can read a little Roc. The book never compares Roc to another language. It explains each Roc idea on its own terms, where it first bites.

The book is honest about the code. It quotes the real code, its numbers come from the real program, and when a sentence is hard to write, we fix the code first.

The book is a book-like experience, made for the desktop: a reader at a wide screen, with the ride and the widgets running beside the text. The phone is extremely low priority.

## 2. The requirements, axis by axis

Each axis fails in its own way, and catching each failure takes a different kind of read. Truth needs the code open beside the page. Order needs a reader who has seen only the pages before. Voice and tone need an ear. Vocabulary needs the glossary. The code axis needs a smell-hunter. Pictures need eyes. Completeness needs a checklist. Purpose needs the whole book in view.

### Axis A. Purpose: every chapter teaches something real

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
- **C6.** Difficulty rises, tempered by categories: nature, man-made, critters. One frame is held still for the first half, and motion starts at The ride instant. Teasing an idea early is fine.
- **C7.** Everything that appears says why the reader needs it now. A type or module with no reason to be in this chapter moves to the chapter that needs it. Telling the reader that a `GroundPatch` is a patch of ground, with no reason it's here, leaves them disoriented.
- **C8.** Show the code, then describe it. Never describe a function the reader hasn't seen.
- **C9.** Name other chapters rarely. When you must, put the title in quotes ("A simple tree"), and say what it holds.

### Axis D. Voice: the sentences themselves

- **D1.** **Active voice.** "We carry a small amount of state… we derive values from it", never "four things are remembered" or "everything else is worked out".
- **D2.** **Say what happens.** Never define a thing by what it isn't, can't do or doesn't remember ("can't go stale", "has never heard of a tower"). Say what it does.
- **D3.** Short sentences: Hemingway, not Faulkner. A strong sentence stands alone. Don't join two sentences that could stand on their own with a comma or ", but".
- **D4.** Talk to the reader with "we", "you" and contractions. Start the book, and each chapter, with a full sentence, never a fragment.
- **D5.** Code first, then one plain sentence on what it does, then why, in ordinary causal words ("That's because…").
- **D6.** Use plain verbs (is, does, gives, takes), not abstract nouns. Keep prepositions ("For each frame it calls", not "Each frame it calls").
- **D7.** No agent-speak:
  - appositives ("`truck_blue`, a navy, paints…");
  - "the way from X to Y is…";
  - "and that's the point of this chapter";
  - "worth saying again";
  - a "this" or "that" where a name belongs. After the cat's code, "This is why the cat waits" makes the reader hunt for what "this" is. "`plan_crossing` is why the cat waits" names it;
  - aphorisms, "not X but Y" drumbeats, or a closing moral.
- **D8.** Explain a type precisely rather than apologizing for its name.
- **D9.** A paragraph makes one point and holds together. A connective such as "Either way" or "So" points at something named in that paragraph, or it goes. A claim is complete: "checks" says what it checks.
- **D10.** Write with the authority of this document: confident, declarative claims, in a simple, clear structure. The book is warmer and slower than a rules document, but just as sure of itself.

### Axis E. Tone: how it feels to read

- **E1.** Dry, plain and technical, with the jargon the audience already knows ("completely deterministic"). Some cleverness is charming ("a tour of a tour"), but don't overdo it.
- **E2.** Humor is restrained: at most one exclamation mark a chapter, and a rare "hooray".
- **E3.** Repetition teaches, so keep a returning idea. A returning idea is the place for a wink ("Guess which technique comes up again?"). A guess is about an idea, never about arithmetic.
- **E4.** No bragging that simple code is simple. No presumed reactions from the reader.
- **E5.** Vary the chapter endings. Ending on what's still missing is a good move, but it isn't a template.

### Axis F. Vocabulary: one word for one thing

- **F1.** These words keep their meanings: frame, step, sighting, spot, kind, picture, rendering, segment, critter (an English word, never a type), solid, card, far scenery, carried, derived.
- **F2.** Every term goes in the glossary, and the book uses the glossary's word.
- **F3.** Write "math", not "maths". "Metres" and "colour" are fine. Write "forward" and "backward", never the "-s" forms.
- **F4.** Types name numbers. Never say a `Pixels` isn't a number.
- **F5.** "Picture" means one thing: the program draws a series of pictures for each step, against a backdrop.

### Axis G. The code behind the prose

- **G1.** The book is a code review. A sentence that's hard to write, or that exposes an odd design, is a code finding first, and the chapter follows the fix.
- **G2.** Quote code that reads more or less like English. Code should answer to its name.
- **G3.** Coordinate transforms belong in one home. A chapter that has to explain the same transform twice is a smell.
- **G4.** The smells in `docs/smells.md` apply: a fat API, a derived value stored beside its source, a name that needs a comment to translate it.

### Axis H. Pictures: diagrams, tables and widgets

- **H1.** Put a diagram early. Every edge has a label, a verb and often the function that does the work ("finds it with truck_in_view"). An edge whose only honest verb is "imports" is worth a look.
- **H1a.** Every box stands for something real in the code, and the diagram shows the reader something the prose needs. A box labelled "triangle" pointing at `Polygon.triangle` shows nothing. A diagram that illustrates no point goes.
- **H2.** In the One frame half, a widget is a static frame. VCR controls come only once time passes. There are no sliders.
- **H3.** A widget gets one sentence of explanation, not a listing of its code. It says which call it adds and what it shows.
- **H4.** A table is welcome wherever it shows data the program really produced.
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

The work is a linear pass, one chapter at a time, in book order. Every chapter already has a draft that has had at least one round.

**The loop, for one chapter:**

1. Read the chapter and the code it quotes.
2. If the prose exposes a smell (G1), fix the code first. A small fix lands now. A bigger one goes in the queue, and the chapter describes the code as it stands.
3. Write the chapter mostly from scratch, with a strong voice, from the reader's questions: what is this for, why now, what does it show? The old draft is a source of facts and of includes, never of sentences; keep only the lines Steve has praised. An edit pass over the old sentences is not a rewrite. Then check it against axes B through I. The writer writes the prose; nobody else does. Check every diagram edge against the code, and give every edge its label (H1).
4. Gate, commit, push, and rebuild the book.
5. Every four or five chapters, post a proofread note with the new text, and Steve reads it while the work goes on. His replies come first whenever they arrive.

**Cold readers.** After each batch, one cold reader checks just two things: truth against the code (B), and order for a reader who has seen only the pages before (C). Those are the two axes where the writer can't see past their own outline. Take its findings with restraint, and phrase every fix yourself.

**The vocabulary.** The carried-and-derived wording reaches each chapter as its batch comes up, not in one sweep, so every change lands in a chapter Steve is about to read.

**The batches:**

| Batch | Chapters |
|---|---|
| 1 | Introduction through The world |
| 2 | Shapes, Nature types, A simple tree, A conifer, Roadside trees, Grass |
| 3 | The sun, The sky, Mountains, The road, Rails, Radio towers |
| 4 | Stills, The elephant, the corner critters, Herds |
| 5 | The ride instant, The beacons, The setting sun, Stepping through the ride |
| 6 | The rider, The bike, The throttle, The rider's gaze |
| 7 | The truck, The truck's motion, The truck's lights |
| 8 | The cat, The bird, What a cat does to the rider, Rehearsal |
| 9 | The math layer, Proving it, The platform, Zooming back out, the appendices, the credits |

When the day runs short, the chapters Steve has already read get the lightest pass, and the rest wait at the same standard. Never lower the standard to make a date.
