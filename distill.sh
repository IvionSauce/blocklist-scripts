#!/bin/bash


# Commandline argument handling
# -----------------------------

whitelist_file=''
rejected='/dev/null'
output_format='none'
output='-'

show-help() {
    cat << EOF
Usage: $(basename "$0") [option...] [blocklist-file...]
Distills domains in blocklist(s) to their topmost common domain. These can be
used by name servers to return NXDOMAIN as a means of blocking.
If no files are given on the commandline standard input will be assumed.

Options:

  -f, --format <type>	    Format of the output data. Valid types are: 'none',
			    'unbound'. Default is 'none'.
  -h, --help		    Show this help.
  -o, --output <file>	    Write output to file; '-' writes to standard output,
			    which is also the default.
  -r, --rejects <file>	    Write rejected domains to file; default is
			    '/dev/null'. Writing to standard output is not
			    supported. Rejected domains are deemed to be invalid
			    domains, most likely errors in the blocklist(s).
  -w, --whitelist <file>    Read whitelist file and ensure whitelisted domains
			    aren't blocked.
EOF
}

missing() {
    printf 'ERROR: Missing %s (%s)\n' "$1" "$2" >&2
    exit 2
}

get-rejects() {
    # Block it from being stdout, cause it'll clobber the stdout used in the
    # pipeline carrying the domains we do want.
    if [[ $1 == /dev/stdout ]]; then
	echo ERROR: Writing rejected domains to standard output is not \
	     supported >&2
	return
    fi

    echo "$1"
}

get-format() {
    local allowed='none unbound'
    for f in $allowed; do
	if [[ $1 == $f ]]; then
	    echo "$1"
	    return
	fi
    done

    printf 'ERROR: Unsupported output format "%s"\n' "$1" >&2
}

while :; do
    case $1 in
	-h|--help)
	    show-help >&2
	    exit 0
	    ;;
	-w|--whitelist)
	    if [[ $2 ]]; then
		whitelist_file="$2"
		shift
	    else
		missing "whitelist file" $1
	    fi
	    ;;
	-r|--rejects)
	    if [[ $2 ]]; then
		rejected="$(get-rejects "$2")"
		[[ $rejected ]] || exit 3
		shift
	    else
		missing "rejected domains output" $1
	    fi
	    ;;
	-f|--format)
	    if [[ $2 ]]; then
		output_format="$(get-format "$2")"
		[[ $output_format ]] || exit 3
		shift
	    else
		missing "output format" $1
	    fi
	    ;;
	-o|--output)
	    if [[ $2 ]]; then
		output="$2"
		shift
	    else
		missing "output" $1
	    fi
	    ;;
	--) shift; break ;;
	-?*) printf 'WARN: Ignoring unknown option %s\n' $1 >&2 ;;
	*) break ;;
    esac

    shift
done


# Actually setting up the pipeline
# --------------------------------

parse() {
    parse-blocklists.sh "$@" | map-idn-conditionally.awk
}

reasonable-domains() {
    case "$rejected" in
	# The default output for rejected domains is stderr, so do nothing.
	/dev/stderr) select-reasonable-domains.sh ;;
	# Otherwise redirect stderr.
	*) select-reasonable-domains.sh 2>"$rejected" ;;
    esac
}

reduce() {
    # Add in the whitelist step if we got a whitelist.
    if [[ -z $whitelist_file ]]; then
	reduce-domains.sh
    else
	remove-whitelisted.awk "$whitelist_file" | reduce-domains.sh
    fi | reasonable-domains
}

format-switch() {
    case "$output_format" in
	unbound) reduce | output-unbound-zones.awk ;;
	*) reduce ;;
    esac
}

parse "$@" | case "$output" in
    -|/dev/stdout) format-switch ;;
    *) format-switch >"$output" ;;
esac
