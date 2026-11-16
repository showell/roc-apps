## This module holds the Safari Ride book's own fences, as the book builder's
## hooks. A ```widget fence becomes a live frame, and a ```dot fence becomes
## its drawing. A ```widget fence names its widget and, for a widget that opens
## partway, the word it opens at: ```widget frame trees. Its body is the
## caption. A ```dot fence names its drawing, `diagram-N`, as Diagrams writes
## it, and the drawing comes from the pre-step, already read.
##
## Roc's hooks are pure, so a widget's folder is looked for, and a diagram
## drawn and read, before the build. A fence that names something missing is
## refused, which stops the build.
import bb.Fences
import BookText
import Diagrams

SafariFences := [].{

	## The class of a widget's frame, which is how a page knows it holds one.
	widget_frame_class : Str
	widget_frame_class = "canvas-app"

	## The hook for ```widget fences, given the folders that hold a widget.
	widget : List(Str) -> Fences.Hook
	widget = |folders| {
		language: "widget",
		html_of: |{ words, body }| widget_html(folders, { words, caption: body.trim() }),
	}

	## The hook for ```dot fences, given the drawings.
	dot : List(Diagrams.Drawn) -> Fences.Hook
	dot = |drawings| {
		language: "dot",
		html_of: |{ words, .. }| diagram_html(drawings, words),
	}
}

## The page behind a widget's word, and the shape of its canvas: `Screen.roc`
## sets the ride's, `FrameWidgetApp.roc` the paused frame's, `CowWidgetApp.roc`
## the cow's, `RouteWidgetApp.roc` the map's, `HerdWidgetApp.roc` the herd's,
## `BendAnimalsWidgetApp.roc` the bend animals', `FarTreeWidgetApp.roc` the far
## tree's, `ConifersWidgetApp.roc` the four conifers', `KindsWidgetApp.roc` the
## five kinds', `PipelineWidgetApp.roc` the pipeline's, and `WidgetPage.roc` the
## other widgets'.
Frame : {
	folder : Str,
	aspect : Str,
	loading : [Eager, Lazy],
}

frame_of : Str -> Frame
frame_of = |word| match word {
	"ride" => {
		folder: "safari",
		aspect: "960 / 600",
		loading: Eager,
	}
	"frame" => {
		folder: "frame_widget",
		aspect: "960 / 600",
		loading: Lazy,
	}
	"route" => {
		folder: "route_widget",
		aspect: "640 / 220",
		loading: Lazy,
	}
	"cow" => {
		folder: "cow_widget",
		aspect: "960 / 600",
		loading: Lazy,
	}
	"herd" => {
		folder: "herd_widget",
		aspect: "640 / 116",
		loading: Lazy,
	}
	"bend_animals" => {
		folder: "bend_animals_widget",
		aspect: "640 / 160",
		loading: Lazy,
	}
	"far_tree" => {
		folder: "far_tree_widget",
		aspect: "640 / 240",
		loading: Lazy,
	}
	"conifers" => {
		folder: "conifers_widget",
		aspect: "640 / 240",
		loading: Lazy,
	}
	"kinds" => {
		folder: "kinds_widget",
		aspect: "640 / 240",
		loading: Lazy,
	}
	"pipeline" => {
		folder: "pipeline_widget",
		aspect: "640 / 340",
		loading: Lazy,
	}
	"shapes" => {
		folder: "shapes_widget",
		aspect: "640 / 324",
		loading: Lazy,
	}
	widget => {
		folder: "${widget}_widget",
		aspect: "640 / 360",
		loading: Lazy,
	}
}

## The iframe's `loading` attribute.
loading_html : [Eager, Lazy] -> Str
loading_html = |loading| match loading {
	Eager => "eager"
	Lazy => "lazy"
}

## A fence's widget, and the end of its frame's address, which says where it opens.
FenceWords : { word : Str, address_end : Str }

fence_words : Str -> Try(FenceWords, Str)
fence_words = |words|
	match words.split_on(" ") {
		[word] => Ok({ word, address_end: "" })
		[word, start] => Ok({ word, address_end: "?start=${start}" })
		_ => Err("a widget fence is a widget and at most one word to start at: `${words}`")
	}

widget_html : List(Str), { words : Str, caption : Str } -> [Html(Str), Refused(Str)]
widget_html = |folders, { words, caption }|
	match fence_words(words) {
		Err(why) => Refused(why)
		Ok({ word, address_end }) => {
			frame = frame_of(word)
			if !folders.contains(frame.folder) {
				Refused("the widget `${word}` needs a folder canvas_apps/${frame.folder}, and there's none")
			} else if caption.is_empty() {
				Refused("the widget `${word}` needs a caption in its fence")
			} else {
				match BookText.inline_html(caption) {
					Err(why) => Refused(why)
					Ok(caption_html) => {
						safe_caption = BookText.escaped_text(caption)
						frame_class = SafariFences.widget_frame_class
						loading = loading_html(frame.loading)
						iframe =
							\\<iframe class="${frame_class}" src="../${frame.folder}/${address_end}" title="${safe_caption}" loading="${loading}" style="aspect-ratio: ${frame.aspect}"></iframe>
						Html("<figure class=\"widget\">${iframe}<figcaption>${caption_html}</figcaption></figure>")
					}
				}
			}
		}
	}

## The drawing, or a phone's and a desktop's for a wide diagram, over its title.
## The drawing goes into the page as it is, so one holding a comment's opening
## is refused: it could close the page early with a forged page mark.
diagram_html : List(Diagrams.Drawn), Str -> [Html(Str), Refused(Str)]
diagram_html = |drawings, id| match drawings.find_first(|drawn| drawn.id == id) {
	Ok({ svg, .. }) if svg.contains("<!--") => Refused("the drawing for the diagram `${id}` holds an HTML comment")
	Ok({ title, svg, .. }) =>
		match BookText.inline_html(title) {
			Err(why) => Refused(why)
			Ok(caption_html) => {
				named = svg.replace_each(
					"role=\"img\"",
					"role=\"img\" aria-label=\"${BookText.escaped_text(title)}\"",
				)
				Html("<figure class=\"diagram\">${named}<figcaption>${caption_html}</figcaption></figure>")
			}
		}
	Err(NotFound) => Refused("no drawing for the diagram `${id}`")
}

folders : List(Str)
folders = ["sky_widget", "frame_widget"]

html_of : Fences.Hook, { words : Str, body : Str } -> [Html(Str), Refused(Str)]
html_of = |hook, fence| (hook.html_of)(fence)

expect frame_of("ride").folder == "safari"
expect frame_of("sky").folder == "sky_widget"
expect frame_of("cow").aspect == "960 / 600"
expect
	[frame_of("herd"), frame_of("bend_animals"), frame_of("far_tree"), frame_of("pipeline"), frame_of("route"), frame_of("shapes")].map(|frame| frame.aspect)
		== ["640 / 116", "640 / 160", "640 / 240", "640 / 340", "640 / 220", "640 / 324"]
expect [frame_of("ride"), frame_of("frame"), frame_of("sky")].map(|frame| loading_html(frame.loading)) == ["eager", "lazy", "lazy"]
expect
	html_of(SafariFences.widget(folders), { words: "sky", body: "Press `play` <now>.\n" })
		== Html("<figure class=\"widget\"><iframe class=\"canvas-app\" src=\"../sky_widget/\" title=\"Press `play` &lt;now&gt;.\" loading=\"lazy\" style=\"aspect-ratio: 640 / 360\"></iframe><figcaption>Press <code>play</code> &lt;now&gt;.</figcaption></figure>")
expect
	match html_of(SafariFences.widget(folders), { words: "frame trees", body: "a\n" }) {
		Html(html) => html.contains("src=\"../frame_widget/?start=trees\"")
		Refused(_) => Bool.False
	}
expect html_of(SafariFences.widget(folders), { words: "frame trees now", body: "a\n" }) == Refused("a widget fence is a widget and at most one word to start at: `frame trees now`")
expect html_of(SafariFences.widget(folders), { words: "cow", body: "a\n" }) == Refused("the widget `cow` needs a folder canvas_apps/cow_widget, and there's none")
expect html_of(SafariFences.widget(folders), { words: "sky", body: " \n" }) == Refused("the widget `sky` needs a caption in its fence")
expect html_of(SafariFences.widget(folders), { words: "sky", body: "a\n\nb\n" }) == Refused("a caption isn't one paragraph of Markdown: a\n\nb")

drawings : List(Diagrams.Drawn)
drawings = [
	{ id: "diagram-1", title: "Around `Sky`", svg: "<svg role=\"img\">" },
	{ id: "diagram-2", title: "A note", svg: "<svg><!-- x -->" },
]

expect
	html_of(SafariFences.dot(drawings), { words: "diagram-1", body: "digraph {}\n" })
		== Html("<figure class=\"diagram\"><svg role=\"img\" aria-label=\"Around `Sky`\"><figcaption>Around <code>Sky</code></figcaption></figure>")
expect html_of(SafariFences.dot(drawings), { words: "diagram-2", body: "" }) == Refused("the drawing for the diagram `diagram-2` holds an HTML comment")
expect html_of(SafariFences.dot(drawings), { words: "diagram-3", body: "" }) == Refused("no drawing for the diagram `diagram-3`")
