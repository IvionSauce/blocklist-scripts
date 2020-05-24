#!/bin/bash

# Both of these _approximately_ match IPv4/6 addresses, but they seem to catch
# all occurrences in the block list source files.
IPV4='([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}'
IPV6='::|([[:xdigit:]]{1,4}::?){1,7}([[:xdigit:]]{1,4})?'

# How relevant entries start in the hosts file.
HOST_BEGIN='^\s*(127\.0\.0\.1|0\.0\.0\.0)\s+[^#]'
# Regexp of bogus domains, either errors or remnants of a hosts file.
BOGUS="${IPV4}|${IPV6}|"'local(host(\.localdomain)?)?'
# The inverse of how lines in a domain list begin.
NOT_DOMAIN_BEGIN="^\s*($|#|${IPV4}(\s|#|$)|${IPV6})"

export LC_ALL=C

# Concatenate all blocklists, making sure the last and first line of subsequent
# files don't get mushed together. Unless we're dealing with no arguments,
# assume stdin in that case.
# Then normalize by making everything lowercase and replacing carriage returns.
normalize() {
    tr '[:upper:]\r' '[:lower:]\n'
}
pre() {
    if [[ $# > 0 ]]; then
	for file in $@; do
	    cat -- "$file"
	    echo
	done | normalize
    else
	normalize
    fi
}

awk-prep() {
    # To appease awk: replace a backslash with two backslashes.
    echo "${@//\\/\\\\}"
}
# Strip away all the extraneous stuff from the input so that we get a list of
# just domains, seperated by newlines.
strip-fluff() {
    awk -v host_begin=$(awk-prep "$HOST_BEGIN") \
	-v bogus=$(awk-prep "^(${BOGUS})$") \
	-v domain_begin_inverse=$(awk-prep "$NOT_DOMAIN_BEGIN") \
	'$0 ~ host_begin { if ($2 !~ bogus) { print $2 } next }
	 $0 !~ domain_begin_inverse { print $1 }'
}

pre "$@" | strip-fluff
