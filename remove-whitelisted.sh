#!/bin/bash

wl_count=1

show-help() {
    cat << EOF
Usage: $(basename "$0") [option] <whitelist-file...> [domainlist-file...]
Reads whitelist file(s) and removes whitelisted domains from the input, which is
either standard input or files given on the commandline.

Options:

  -h, --help    Show this help.
  -p            Run in pipe mode, which means that all the files on the
		commandline are taken to be whitelist files.
  -w <count>	The first 'count' files are taken to be whitelist files, the
		rest are domainlist files. Defaults to 1.

Specifying more than one option is unsupported.
EOF
}

case $1 in
    -h|--help)
	show-help >&2
	exit 0
	;;
    -p)
	shift
	if [[ $# -gt 1 ]]; then
	    wl_count=$#
	fi
	;;
    -w)
	shift
	if [[ $1 =~ ^[1-9][0-9]*$ ]]; then
	    wl_count=$1
	    shift
	else
	    printf 'ERROR: Whitelist count is not a positive integer: "%s"\n' \
		   "$1" >&2
	    exit 3
	fi
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
