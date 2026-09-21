# The roc-ray end, as a package: every app's main.roc reaches the runner as
# `native.CanvasAppRunner`.
#
# It declares roc-ray itself, because CanvasAppRunner imports roc-ray's own
# modules, and a package may only see a platform it names in its header. Every
# app that uses it names the same one.
package [CanvasAppRunner] {
	rr: platform "../../../roc-ray/platform/main.roc",
	lib: "../lib/main.roc",
}
