#!/bin/bash

export LC_ALL=C

# With help from https://backreference.org/2010/02/10/idiomatic-awk/
# and https://backreference.org/2014/10/13/range-of-fields-in-awk/
read -d '' -r awk_script << 'EOA'
(NR == FNR && FILENAME == ARGV[1]) {
    if (/^\s*[^#]/) {
	# Whitelist the absolute domain name.
	whitemap[$1]

	# Whitelist all domains from the root down, else we might have a domain
	# up the chain returning NXDOMAIN.
	nf = split($1, fields, ".")
	# Last field is the TLD.
	dom = fields[nf]
	# So we work our way downward, stopping short of adding the absolute
	# domain name.
	for (i = nf - 1; i >= 2; i--) {
	    whitemap[dom]
	    dom = fields[i] "." dom
	}
	whitemap[dom]
    }
    next
}

!($0 in whitemap) {
    print $0
}
EOA

case $# in
    0) echo "Provide a file with whitelisted domains:" >&2
       printf '%s <whitelist-file> [blocklist-file...]\n' "$(basename "$0")" >&2
       exit 2 ;;
    # If just 1 argument, the whitelist, remove domains from stdin.
    1) set -- "$1" '-' ;;
esac

awk -- "$awk_script" "$@"
