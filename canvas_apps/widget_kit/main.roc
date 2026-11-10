# What the Safari tutorial's widgets share, as a package. A widget reaches this
# as `widget: "../widget_kit/main.roc"` and says `import widget.WidgetPage`,
# `import widget.VcrButtons`, `import widget.ReadoutText`, `import widget.Click`,
# `import widget.PlanView` or `import widget.WidgetPalette`.
package
	[
		Click,
		PlanView,
		ReadoutText,
		VcrButtons,
		WidgetPage,
		WidgetPalette,
	]
	{ game: "../safari/game.roc", lib: "../lib/main.roc" }
