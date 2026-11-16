## This module is how the Safari Ride book's pages look beyond what the
## manuscript says: the book's name, its parts and categories in the lists of
## chapters, each chapter's page name, the bar across the top of every page,
## the book's scripts, and two rewrites of each rendered page, the draft notes
## marked and the tables' code given its break points.
import bb.Pages
import BookTable
import DraftNotes
import SafariFences

SafariLook := [].{

	## The book's look, for the builder.
	look : Pages.Look
	look = {
		book_name: Named("Safari Ride"),
		slugs,
		dividers,
		head_end: "<script src=\"book.js\" defer></script>\n",
		body_start: "${top_bar}\n",
		body_end: script_at_end,
		body_rewrite: |html| BookTable.with_break_points(DraftNotes.highlight(html)),
	}
}

## The book's parts, and the categories inside them.
dividers : List(Pages.Divider)
dividers = [
	{
		before: "Introduction",
		level: Part,
		title: "The big picture",
	},
	{
		before: "Things",
		level: Part,
		title: "One frame",
	},
	{
		before: "The sky and the grass",
		level: Category,
		title: "Nature",
	},
	{
		before: "The road",
		level: Category,
		title: "Man-made",
	},
	{
		before: "Herds",
		level: Category,
		title: "Critters that stand still",
	},
	{
		before: "Immutable values: a flip book",
		level: Part,
		title: "Motion",
	},
	{
		before: "The beacons",
		level: Category,
		title: "The passage of time",
	},
	{
		before: "The rider",
		level: Category,
		title: "Vehicles",
	},
	{
		before: "The cat",
		level: Category,
		title: "Critter motion",
	},
	{
		before: "The math layer",
		level: Part,
		title: "Under the hood",
	},
	{
		before: "Appendix: the patterns",
		level: Part,
		title: "Appendices",
	},
]

## A chapter's page is named for its slug, never for its title, so a
## published page keeps its address when its chapter is retitled. To retitle
## a chapter, change its `chapter` here and keep its `slug`.
slugs : List(Pages.Slug)
slugs = [
	{ chapter: "Introduction", slug: "introduction" },
	{ chapter: "One page", slug: "one-page" },
	{ chapter: "The problem", slug: "the-problem" },
	{ chapter: "Platforms, packages and modules", slug: "platforms-packages-and-modules" },
	{ chapter: "Types", slug: "types" },
	{ chapter: "Functions", slug: "functions" },
	{ chapter: "Things", slug: "things" },
	{ chapter: "Tag unions: billboard critters", slug: "billboard-critters" },
	{ chapter: "Shapes", slug: "shapes" },
	{ chapter: "Lists and map: a far tree", slug: "a-far-tree" },
	{ chapter: "The pipeline", slug: "the-pipeline" },
	{ chapter: "Errors as tag unions", slug: "refused" },
	{ chapter: "Where clauses: asking a kind", slug: "asking-a-kind" },
	{ chapter: "The sky and the grass", slug: "the-sky" },
	{ chapter: "Mountains", slug: "mountains" },
	{ chapter: "The road", slug: "the-road" },
	{ chapter: "Rails", slug: "rails" },
	{ chapter: "Radio towers", slug: "radio-towers" },
	{ chapter: "Herds", slug: "herds" },
	{ chapter: "Immutable values: a flip book", slug: "a-flip-book" },
	{ chapter: "Records", slug: "records" },
	{ chapter: "Pure functions and effects", slug: "pure-functions-and-effects" },
	{ chapter: "Opaque types: the clock", slug: "the-clock" },
	{ chapter: "The ride instant", slug: "the-ride-instant" },
	{ chapter: "The beacons", slug: "the-beacons" },
	{ chapter: "The setting sun", slug: "the-setting-sun" },
	{ chapter: "The rider", slug: "the-rider" },
	{ chapter: "The throttle", slug: "the-throttle" },
	{ chapter: "Variables and loops: rehearsal", slug: "rehearsal" },
	{ chapter: "The rider's gaze", slug: "the-riders-gaze" },
	{ chapter: "The truck", slug: "the-truck" },
	{ chapter: "The truck's motion", slug: "the-trucks-motion" },
	{ chapter: "The cat", slug: "the-cat" },
	{ chapter: "The bird", slug: "the-bird" },
	{ chapter: "What a cat does to the rider", slug: "what-a-cat-does-to-the-rider" },
	{ chapter: "The math layer", slug: "the-math-layer" },
	{ chapter: "Proving it", slug: "proving-it" },
	{ chapter: "The platform", slug: "the-platform" },
	{ chapter: "Zooming back out", slug: "zooming-back-out" },
	{ chapter: "Appendix: the patterns", slug: "appendix-the-patterns" },
	{ chapter: "Appendix: list functions", slug: "appendix-list-functions" },
	{ chapter: "Appendix: what catches you out", slug: "appendix-what-catches-you-out" },
	{ chapter: "Appendix: glossary", slug: "appendix-glossary" },
	{ chapter: "Appendix: index", slug: "appendix-index" },
	{ chapter: "Credits", slug: "credits" },
]

repo_url : Str
repo_url = "https://github.com/showell/roc-apps"

## The site the book is published on. The link is absolute because the book's
## checker holds every relative link to a page of the book.
site_url : Str
site_url = "https://roc.lynrummy.com/"

## The bar across the top of every page leads back to the site, and to the
## code the book reads.
top_bar : Str
top_bar =
	\\<header class="top-bar">
	\\<a class="home-link" href="${site_url}">Steve's Roc Apps</a>
	\\<a class="repo-link" href="${repo_url}">roc-apps on GitHub</a>
	\\</header>

## A page that holds a widget's frame loads the script that sizes it. Every
## page ends with a line here, empty on a page with no widget, as the book's
## pages always have.
script_at_end : Str -> Str
script_at_end = |main|
	if main.contains("class=\"${SafariFences.widget_frame_class}\"") {
		"<script src=\"embed.js\"></script>\n"
	} else {
		"\n"
	}

expect script_at_end("<iframe class=\"canvas-app\" src=\"x\">") == "<script src=\"embed.js\"></script>\n"
expect script_at_end("<p>no widget</p>") == "\n"
expect slugs.len() == 45
expect dividers.len() == 11
expect (SafariLook.look.body_rewrite)("<table><td><code>a_b</code> [check: c]</td></table>") == "<table><td><code>a_<wbr>b</code> <span class=\"draft-note\">[check: c]</span></td></table>"
