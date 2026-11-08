# roc-apps' compiler, sourced by every script that runs Roc: the nightly
# named in roc-version at the repository's root, installed side by side at
# ~/tools/roc-<pin>/roc (CLAUDE.md §2). ROC may name another binary, and is
# refused unless `roc version` names the pin. Shale scripts find the same
# compiler, with the same refusals, through `pinned_roc` in .shale/prelude.shale.
ROC_APPS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC_PIN="$(cat "$ROC_APPS_ROOT/roc-version")"
ROC="${ROC:-$HOME/tools/roc-$ROC_PIN/roc}"
# A bare name, as CI gives it (`ROC=roc`), is the one on the PATH.
ROC="$(command -v "$ROC" || echo "$ROC")"
[ -x "$ROC" ] || { echo "no $ROC: install $ROC_PIN at ~/tools/roc-$ROC_PIN/"; exit 1; }
"$ROC" version | grep -qxF "Roc compiler version $ROC_PIN" || { echo "$ROC is $("$ROC" version), not $ROC_PIN"; exit 1; }
