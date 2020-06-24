#!/bin/bash

wl_count=1

show-help() {
    cat << EOF
Usage: $(basename "$0") [-w N] <whitelist-file...> [domainlist-file...]
Reads whitelist file(s) and removes whitelisted domains from the input, which is
either standard input or files given on the commandline. Multiple whitelist
files are possible by using the -w option and specifying the count N.
EOF
}

case $1 in
    -w)
	shift
	if [[ $1 =~ ^[0-9]+$ ]]; then
	    wl_count=$1
	    shift
	else
	    printf 'ERROR: Whitelist count is not a positive integer: "%s"\n' \
		   "$1" >&2
	    exit 3
	fi
	;;
    -h|--help)
	show-help >&2
	exit 0
	;;
    --) shift ;;
esac

if [[ $# < $wl_count ]]; then
    printf 'ERROR: Insufficient arguments; got %s, expected >=%s\n' \
	   $# $wl_count >&2
    exit 2
fi

# Whilst someone could definitely guess the filename we immediately abort if
# creating the pipe fails; we're not gonna take orders from a named pipe NOT
# of our own making.
pipe="${TMPDIR:-/tmp}/"wl-next-step.$(date +%s).$$
mkfifo -- "$pipe" || {
    echo ERROR: Failed to create pipe >&2
    exit 4
}

# Always clean up the pipe.
trap 'rm -f -- "$pipe"' 0
trap 'exit 1' 2 3 15

remove-whitelisted.awk -v next_step_out="$pipe" \
		       -v wl_count=$wl_count \
		       -- "$@" \
    | eval "$(<"$pipe")"
