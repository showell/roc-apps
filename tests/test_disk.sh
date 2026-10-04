# The disk image a Cobblestone test boots with, for every script that runs one
# (tests/ladder.sh, floor/, machine/). Sourced, not run.
#
#   test_disk <unit.codex> disk|disk2 <checkout>    prints the image's path, or nothing
#
# A `.disk` beside the unit is used as it is. Since Update 63 most are not
# tracked: the test carries a `.disk-mint` (`.disk2-mint`) recipe, and
# upstream's own build/mint-test-disk.ps1 builds the image (sha256-checked,
# reused while it matches its recipe). That script needs PowerShell; the box's
# lives in ~/build/pwsh. It runs from the checkout, as its paths are relative
# to the repo root. A refused mint prints nothing, and the unit then runs as
# the test would without its disk. No image is an answer, not a failure: the
# function always succeeds, so a caller under `set -e` keeps going.
test_disk() {
    local src=$1 ext=$2 root=$3 out
    if [ -f "${src%.codex}.$ext" ]; then echo "${src%.codex}.$ext"; return; fi
    [ -f "${src%.codex}.$ext-mint" ] || return 0
    out=$(cd "$root" && PATH="$PATH:$HOME/build/pwsh" pwsh -NoProfile -File build/mint-test-disk.ps1 -Recipe "${src%.codex}.$ext-mint" 2>/dev/null | tail -1)
    case $out in
        /*) [ -f "$out" ] && echo "$out" ;;
        *) [ -f "$root/$out" ] && echo "$root/$out" ;;
    esac
    return 0
}
