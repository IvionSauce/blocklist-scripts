#!/bin/bash

# This might be technically too strict, but everything that was not reasonable
# has turned out to be an error in the source file(s).
REASONABLE='^[[:alnum:]_-]+\.[[:alnum:]\._-]*[a-zA-Z]$'

export LC_ALL=C
# Output rejected domain names on stderr.
cat -- "$@" \
    | tee >(1>&2 grep --invert-match -E "$REASONABLE") \
    | grep -E "$REASONABLE"
