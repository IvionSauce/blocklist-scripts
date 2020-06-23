#!/usr/bin/awk -f

# With help from https://backreference.org/2010/02/10/idiomatic-awk/
# and https://backreference.org/2014/10/13/range-of-fields-in-awk/

BEGIN {
    # Whitelist count defaults to 1.
    if (wl_count + 0 < 1) wl_count = 1

    # Error, not enough arguments.
    if (ARGC == wl_count) {
	show_help()
	exit 2
    }
    # Remove domains from stdin if only whitelist files on the commandline.
    if (ARGC == wl_count + 1) {
	ARGV[wl_count + 1] = "-"
	ARGC++
    }
    # Record which files are the whitelist files.
    for (i = 1; i <= wl_count; i++) {
	whitelist_files[ARGV[i]]
    }
}

(FILENAME in whitelist_files) {
    if (/^\s*[^#]/) {
	# Wildcarded domain.
	if (index($1, "*.") == 1) {
	    # Massage it into the correct regular expression.
	    wildcard_dom = substr($1, 2) "$"
	    gsub(/\./, "\\.", wildcard_dom)

	    wildcards[wildcard_dom]
	}
	# Regular domain.
	else {
	    # Whitelist the absolute domain name.
	    whitemap[$1]
	}

	# Whitelist all domains from the root down, else we might have a domain
	# up the chain returning NXDOMAIN.
	nf = split($1, fields, ".")
	# Last field is the TLD.
	dom = fields[nf]
	whitemap[dom]
	# So we work our way downward, stopping short of adding the absolute
	# domain name.
	for (i = nf - 1; i >= 2; i--) {
	    dom = fields[i] "." dom
	    whitemap[dom]
	}
	# Cheat: also add the 'www' subdomain if not explicitely stated. This
	# runs parallel to what is done in `reduce-domains.sh`, where the 'www'
	# subdomain is implicitly removed.
	if (nf > 1 && fields[1] != "www" && fields[1] != "*") {
	    whitemap["www." $1]
	}
    }
    next
}

# This is run for all the input that isn't the whitelist file...
!($0 in whitemap || wildcarded()) {
    print $0
}

function wildcarded() {
    # Awk doing this regexp is still much slower than using grep with
    # --invert-match (about 10 times slower).
    for (dom in wildcards) {
	if (match($0, dom) > 1) {
	    return 1
	}
    }

    return 0

function show_help() {
    # Perform some trickery to get the script name.
    name_cmd = "basename \"$(ps -p $PPID -o cmd= | cut -d ' ' -f 3)\""
    name_cmd | getline script_name
    close(name_cmd)

    OFS="\n"
    # God, this is ugly as sin. I wish awk had heredocs or something similar.
    print "Usage: "script_name " [-v wl_count=N] " \
	"<whitelist-file...> [blocklist-file...]",
	"\nReads whitelist file(s) and removes whitelisted domains from the \
input, either", "blocklist files or standard input. Results are printed on \
standard output.", "Setting 'wl_count' determines how many files on the \
command line are whitelists."
}
