# What the Safari tutorial's widgets share, as a package. A widget reaches this
# as `widget: "../widget_kit/main.roc"` and says `import widget.WidgetPage`,
# `import widget.VcrButtons`, `import widget.ReadoutText`, `import widget.Click`
# or `import widget.PlanView`.
package
	[
		Click,
		PlanView,
		ReadoutText,
		VcrButtons,
		WidgetPage,
	]
	{
		game: "../safari/game.roc",
		lib: "../lib/main.roc",
	}
