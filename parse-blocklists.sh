#!/bin/bash

# Both of these _approximately_ match IPv4/6 addresses, but they seem to catch
# all occurrences in the block list source files.
IPV4='([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}'
IPV6='::|([[:xdigit:]]{1,4}::?){1,7}([[:xdigit:]]{1,4})?'

# How relevant entries start in the hosts file.
HOST_BEGIN='^\s*(127\.0\.0\.1|0\.0\.0\.0)\s+[^#]'
# Regexp of bogus addresses, either remnants or errors from a hosts file.
BOGUS="${IPV4}|${IPV6}|"'local(host(\.localdomain)?)?'

export LC_ALL=C

# Concatenate all blocklists, making sure the last and first line of subsequent
# files don't get mushed together. Then normalize by making everything lowercase
# and replacing carriage returns.
pre() {
    for file in $@; do
	cat -- "$file"
	echo
    done | tr '[:upper:]\r' '[:lower:]\n'
}

strip-domainlists() {
    pre "$@" \
	| grep --invert-match -E "^\s*($|#|${IPV4}|${IPV6})" \
	| awk '{ print $1 }'
}

strip-hostsfiles() {
    pre "$@" \
	| grep -E "$HOST_BEGIN" \
	| awk '{ print $2 }' \
	| sed -E "/^(${BOGUS})$/d"
}

{ strip-domainlists "$@"; strip-hostsfiles "$@"; }
