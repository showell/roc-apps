## This program prints the Safari Ride book as HTML pages, from what
## book.shale hands it, and that script writes them to files. A comment line
## opens each page and names its file. Text from the manuscript can't forge one,
## because the renderer and the fence hook escape it. A diagram's drawing goes
## into its page unescaped, so the hook refuses one that holds a comment.
app [main!] { md: "../../../../roc-markdown/package/main.roc" }

import Book
import Manuscript

main! = |args| {
	manuscript = Manuscript.read(args)
	for page in Book.pages(manuscript, dividers_of(manuscript)) {
		echo!("<!-- book page: ${page.file} -->\n${page.html}")
	}
	Ok({})
}

## The whole book has every divider, and Book.pages stops on one whose chapter
## is missing. The first chapters have the dividers above the chapters they hold.
dividers_of : Manuscript.Contents -> List(Book.Divider)
dividers_of = |manuscript| match manuscript.extent {
	WholeBook => Book.dividers
	FirstChapters => Book.dividers.keep_if(|divider| has_chapter(manuscript, divider.before))
}

## Whether `manuscript` holds the chapter titled `title`.
has_chapter : Manuscript.Contents, Str -> Bool
has_chapter = |manuscript, title| manuscript.pages.any(|page| is_titled(page, title))

## Whether `page` is the chapter titled `title`.
is_titled : Str, Str -> Bool
is_titled = |page, title| page.starts_with("# ${title}\n")
