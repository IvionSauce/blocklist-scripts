#!/bin/bash

# This might be technically too strict, but everything that was not reasonable
# has turned out to be an error in the source file(s).
REASONABLE='^[[:alnum:]_-]+\.[[:alnum:]\._-]*[a-zA-Z]$'

export LC_ALL=C

main() {
    # Output rejected domain names on stderr.
    tee >(1>&2 grep --invert-match -E "$REASONABLE") \
	| grep -E "$REASONABLE"
}

if [[ $# > 0 ]]; then
    cat -- "$@" | main
else
    main
fi
