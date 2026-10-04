#!/bin/bash
# One Codex unit on the floor: built by build.sh, then run with the host's own
# flags. A `.disk` or `.disk2` beside the unit is attached unless -disk or
# -disk2 says otherwise; the file itself is never written, because the host
# reads the image into its own memory (-disk-out writes the primary one back).
#
#   floor/run.sh <unit.codex> [-disk <path>] [-disk2 <path>] [-disk-out <path>]
#                             [-wall] [-fault <kind>] [-fault-every <n>]
#                             [-fault-lba <lba>] [-report]
#
#   floor/run.sh ~/showell_repos/cobblestone-u66rel/codex/test/fat16-write.codex -report
#   floor/run.sh .../fat16-write.codex -fault tear-write -fault-every 3 -report
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../tests/test_disk.sh"
GEN="$HOME/build/roc-apps/gen/floor"
src="$(realpath "$1")"; shift
n="$(basename "$src" .codex)"
"$HERE/build.sh" "$src" > "$GEN/$n-build.log" 2>&1 || { tail -20 "$GEN/$n-build.log"; exit 1; }
args=()
# A minted disk is minted in the checkout the unit sits in.
CHECKOUT="$(git -C "$(dirname "$src")" rev-parse --show-toplevel)"
case " $* " in *" -disk "*) ;; *) d=$(test_disk "$src" disk "$CHECKOUT"); [ -n "$d" ] && args+=(-disk "$d") ;; esac
case " $* " in *" -disk2 "*) ;; *) d=$(test_disk "$src" disk2 "$CHECKOUT"); [ -n "$d" ] && args+=(-disk2 "$d") ;; esac
exec "$GEN/$n/native" "${args[@]}" "$@"
