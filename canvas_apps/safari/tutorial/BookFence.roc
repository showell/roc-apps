## This module is the hook that turns a chapter's own fences into HTML. A
## ```widget fence becomes a live frame and a ```dot fence becomes its drawing.
## Every other fence stays code.
import md.Md
import md.MdDocument
import Manuscript

BookFence := [].{

	## The hook for a manuscript. Roc's hook is pure, so a diagram has to be
	## drawn before the render and a widget's folder looked for before it. A
	## fence that names something missing crashes the program, which stops the
	## build.
	hook : Manuscript.Contents -> MdDocument.FenceHook
	hook = |manuscript| |{ tag, args, body }|
		if tag == "widget".to_utf8() {
			Html(widget_html(manuscript.widget_folders, { word: text_of(args), caption: text_of(body).trim() }).to_utf8())
		} else if tag == "dot".to_utf8() {
			Html(diagram_html(manuscript.diagrams, text_of(args)).to_utf8())
		} else {
			Pass
		}
}

## The page behind a widget's word, and the shape of its canvas: `Screen.roc`
## sets the ride's, and `ScrubWidget.roc` sets the widgets'.
Frame : { folder : Str, aspect : Str, loading : Str }

frame_of : Str -> Frame
frame_of = |word|
	if word == "ride" {
		{ folder: "safari", aspect: "960 / 600", loading: "eager" }
	} else {
		{ folder: "${word}_widget", aspect: "640 / 360", loading: "lazy" }
	}

widget_html : List(Str), { word : Str, caption : Str } -> Str
widget_html = |folders, { word, caption }| {
	frame = frame_of(word)
	if !folders.contains(frame.folder) {
		crash "book: the widget `${word}` needs a folder canvas_apps/${frame.folder}, and there's none"
	}
	if caption.is_empty() {
		crash "book: the widget `${word}` needs a caption in its fence"
	}
	safe_caption = text_of(Md.escape(caption.to_utf8()))
	figure =
		\\<figure class="widget"><iframe class="canvas-app" src="../${frame.folder}/" title="${safe_caption}" loading="${frame.loading}" style="aspect-ratio: ${frame.aspect}"></iframe><figcaption>${safe_caption}</figcaption></figure>
	figure
}

diagram_html : List(Manuscript.Diagram), Str -> Str
diagram_html = |diagrams, id| match diagrams.find_first(|diagram| diagram.id == id) {
	Ok(diagram) => diagram.svg
	Err(NotFound) => crash "book: no drawing for the diagram `${id}`"
}

text_of : List(U8) -> Str
text_of = |bytes| match Str.from_utf8(bytes) {
	Ok(text) => text
	Err(_) => crash "book: a fence that isn't UTF-8"
}
