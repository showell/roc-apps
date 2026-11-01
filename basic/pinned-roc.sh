# BASIC's compiler, sourced by build.sh and build-run.sh: the nightly named
# in basic/roc-version, installed side by side at ~/tools/roc-<pin>/roc
# (CLAUDE.md §2). BASIC has a pin of its own; the rest of the repo reads
# ../roc-nightly.txt. ROC may name another binary, and is refused unless
# `roc version` names the pin. BASIC_HERE is basic/.
ROC_PIN="$(cat "$BASIC_HERE/roc-version")"
ROC="${ROC:-$HOME/tools/roc-$ROC_PIN/roc}"
[ -x "$ROC" ] || { echo "no $ROC -- install $ROC_PIN at ~/tools/roc-$ROC_PIN/"; exit 1; }
"$ROC" version | grep -qxF "Roc compiler version $ROC_PIN" || { echo "$ROC is $("$ROC" version), not $ROC_PIN"; exit 1; }
