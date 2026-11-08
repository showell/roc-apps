## This module is the hook that turns a chapter's own fences into HTML. A
## ```widget fence becomes a live frame and a ```dot fence becomes its drawing.
## A code fence with a title after its language, as build.shale writes them,
## becomes a listing with that title over it, and any other fence stays code. A
## ```widget fence names its widget and, for a widget that opens partway, the
## word it opens at: ```widget frame trees.
import md.MdDocument
import BookText
import Manuscript

BookFence := [].{

	## The class of a widget's frame, which is how a page knows it holds one.
	widget_frame_class : Str
	widget_frame_class = "canvas-app"

	## The hook for a manuscript. Roc's hook is pure, so a diagram has to be
	## drawn before the render and a widget's folder looked for before it. A
	## fence that names something missing crashes the program, which stops the
	## build.
	fence_hook : Manuscript.Contents -> MdDocument.FenceHook
	fence_hook = |manuscript| |{ tag, args, body }|
		match BookText.text_from_bytes(tag) {
			"widget" => {
				fence = {
					words: BookText.text_from_bytes(args),
					caption: BookText.text_from_bytes(body).trim(),
				}
				Html(widget_html(manuscript.widget_folders, fence).to_utf8())
			}
			"dot" => Html(
				diagram_html(manuscript.diagrams, BookText.text_from_bytes(args)).to_utf8(),
			)
			_ if args.is_empty() => Pass
			language => {
				listing = {
					language,
					title: BookText.text_from_bytes(args),
					code: BookText.text_from_bytes(body),
				}
				Html(listing_html(listing).to_utf8())
			}
		}
}

## The page behind a widget's word, and the shape of its canvas: `Screen.roc`
## sets the ride's, `FrameWidgetApp.roc` the paused frame's, and `WidgetPage.roc`
## the other widgets'.
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
		aspect: "960 / 700",
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

fence_words : Str -> FenceWords
fence_words = |words|
	match words.split_on(" ") {
		[word] => { word, address_end: "" }
		[word, start] => { word, address_end: "?start=${start}" }
		_ => crash "book: a widget fence is a widget and at most one word to start at: `${words}`"
	}

widget_html : List(Str), { words : Str, caption : Str } -> Str
widget_html = |folders, { words, caption }| {
	{ word, address_end } = fence_words(words)
	frame = frame_of(word)
	if !folders.contains(frame.folder) {
		crash "book: the widget `${word}` needs a folder canvas_apps/${frame.folder}, and there's none"
	}
	if caption.is_empty() {
		crash "book: the widget `${word}` needs a caption in its fence"
	}
	safe_caption = BookText.escaped_text(caption)
	caption_html = BookText.inline_html(caption)
	frame_class = BookFence.widget_frame_class
	loading = loading_html(frame.loading)
	iframe =
		\\<iframe class="${frame_class}" src="../${frame.folder}/${address_end}" title="${safe_caption}" loading="${loading}" style="aspect-ratio: ${frame.aspect}"></iframe>
	"<figure class=\"widget\">${iframe}<figcaption>${caption_html}</figcaption></figure>"
}

## The drawing, or a phone's and a desktop's for a wide diagram, over its title.
## The drawing goes into the page as it is, so one holding a comment's opening
## stops the build: it could close the page early with a forged page mark.
diagram_html : List(Manuscript.Diagram), Str -> Str
diagram_html = |diagrams, id| match diagrams.find_first(|diagram| diagram.id == id) {
	Ok(
		{ svg, .. },
	) if svg.contains("<!--") => crash "book: the drawing for the diagram `${id}` holds an HTML comment"
	Ok({ title, svg, .. }) => {
		named = svg.replace_each(
			"role=\"img\"",
			"role=\"img\" aria-label=\"${BookText.escaped_text(title)}\"",
		)
		"<figure class=\"diagram\">${named}<figcaption>${BookText.inline_html(title)}</figcaption></figure>"
	}
	Err(NotFound) => crash "book: no drawing for the diagram `${id}`"
}

## The renderer's own markup for code, with the title over it.
listing_html : {
	language : Str,
	title : Str,
	code : Str,
} -> Str
listing_html = |{ language, title, code }| {
	safe_title = BookText.escaped_text(title)
	safe_code = BookText.escaped_text(code)
	listing =
		\\<figure class="listing"><figcaption>${safe_title}</figcaption><pre><code class="language-${language}">${safe_code}</code></pre></figure>
	listing
}

expect frame_of("ride").folder == "safari"
expect frame_of("sky").folder == "sky_widget"
expect frame_of("frame").folder == "frame_widget"
expect frame_of("frame").aspect == "960 / 700"
expect [
	frame_of("ride"),
	frame_of("frame"),
	frame_of("sky"),
].map(|frame| loading_html(frame.loading)) == ["eager", "lazy", "lazy"]
expect widget_html(
	["sky_widget"],
	{ words: "sky", caption: "a <b>" },
).contains("title=\"a &lt;b&gt;\"")
expect widget_html(
	["sky_widget"],
	{ words: "sky", caption: "a" },
).contains("src=\"../sky_widget/\"")
expect
	widget_html(["frame_widget"], { words: "frame trees", caption: "a" })
		.contains("src=\"../frame_widget/?start=trees\"")
expect
	diagram_html(
		[
			{
				id: "d1",
				title: "Around `Sky`",
				svg: "<svg role=\"img\">",
			},
		],
		"d1",
	)
		== "<figure class=\"diagram\"><svg role=\"img\" aria-label=\"Around `Sky`\"><figcaption>Around <code>Sky</code></figcaption></figure>"
expect
	listing_html({
		language: "roc",
		title: "A.roc, in b",
		code: "a < b\n",
	})
		== "<figure class=\"listing\"><figcaption>A.roc, in b</figcaption><pre><code class=\"language-roc\">a &lt; b\n</code></pre></figure>"
expect widget_html(
	["sky_widget"],
	{ words: "sky", caption: "Press `play`." },
).contains("<figcaption>Press <code>play</code>.</figcaption>")
expect widget_html(
	["sky_widget"],
	{ words: "sky", caption: "Press `play`." },
).contains("title=\"Press `play`.\"")
