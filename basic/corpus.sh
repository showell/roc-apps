# The corpus as the scripts read it, sourced by run.sh and timings.sh:
# a program's listing, the replies chosen for it (ours, then the corpus's), the names in a
# suite, and a text read whole. BASIC_HERE is basic/.
CORPUS="${BASIC_CORPUS:-$HOME/build/basic-corpus}"

listing_of() { # suite name
    local ext
    for ext in bas BAS; do
        [ -f "$CORPUS/$1/$2.$ext" ] && { echo "$CORPUS/$1/$2.$ext"; return; }
    done
}

# Ours for an NBS program, then the corpus's .input, then its .in.
replies_of() { # suite name
    if [ "$1" = nbs ] && [ -s "$BASIC_HERE/nbs-input/$2.in" ]; then echo "$BASIC_HERE/nbs-input/$2.in"
    elif [ -f "$CORPUS/$1/$2.input" ]; then echo "$CORPUS/$1/$2.input"
    elif [ -f "$CORPUS/$1/$2.in" ]; then echo "$CORPUS/$1/$2.in"
    fi
}

names_of() { # suite
    ls "$CORPUS/$1" | grep -iE '\.bas$' | sed 's/\.[^.]*$//' | sort -u
}

# **A COMMAND SUBSTITUTION DROPS TRAILING NEWLINES**, and a reply file that
# ends in an empty line (banner's answer to SET PAGE is Enter) would lose its
# last reply: the text is read with a marker after it, and the marker cut.
read_text() { # variable file
    local t
    t="$(cat "$2"; printf x)"
    printf -v "$1" '%s' "${t%x}"
}
