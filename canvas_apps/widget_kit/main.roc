# What the Safari tutorial's widgets share, as a package. A widget reaches this
# as `widget: "../widget_kit/main.roc"` and says `import widget.ScrubWidget`,
# `import widget.VcrButtons` or `import widget.ReadoutText`.
package
	[
		ReadoutText,
		ScrubWidget,
		VcrButtons,
	]
	{
		game: "../safari/game.roc",
		lib: "../lib/main.roc",
	}
