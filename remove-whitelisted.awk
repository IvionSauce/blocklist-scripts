#!/usr/bin/awk -f

# With help from https://backreference.org/2010/02/10/idiomatic-awk/
# and https://backreference.org/2014/10/13/range-of-fields-in-awk/

BEGIN {
    # Whitelist count defaults to 1.
    if (wl_count + 0 < 1) wl_count = 1
    # Discard next step if not given an output.
    if (!next_step_out) next_step_out = "/dev/null"

    # Error, not enough arguments.
    if (ARGC == wl_count) exit 2
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
	# Wildcard domain.
	if (index($1, "*.") == 1 && length($1) > 2) {
	    # Prepare domain for the `grep` command.
	    wildcard_dom = substr($1, 2)
	    gsub(/\./, "\\.", wildcard_dom)

	    wildcards = wildcards wildcard_dom "$\n"
	}
	# Regular domain.
	else {
	    # Whitelist the absolute domain name.
	    whitemap[$1]
	}

	# Whitelist all domains from the root down, else we might have a domain
	# up the chain returning NXDOMAIN.
	nf = split($1, fields, ".")
	if (nf > 1) {
	    # Last field is the TLD.
	    dom = fields[nf]
	    whitemap[dom]
	    # So we work our way downward, stopping short of adding the whole
	    # domain name (either wildcard or absolute).
	    for (i = nf - 1; i >= 2; i--) {
		dom = fields[i] "." dom
		whitemap[dom]
	    }
	    # Cheat: also add the 'www' subdomain if not explicitely stated.
	    # This runs parallel to what is done in `reduce-domains.sh`, where
	    # the 'www' subdomain is implicitly removed.
	    if (fields[1] != "www" && fields[1] != "*") {
		whitemap["www." $1]
	    }
	}
    }
    next
}

# Have a way to pass back (through `next_step_out`) what the next step in the
# pipeline is. We do this because piping to grep in awk somehow works out to be
# a lot slower than doing the pipe in the (calling) shell.
!printed_next_step {
    if (wildcards) {
	print "grep --invert-match -E '" \
	    substr(wildcards, 0, length(wildcards) - 1) "'" \
	    > next_step_out
    }
    else {
	print "cat" > next_step_out
    }
    # Close file/pipe, especially important for the latter.
    close(next_step_out)
    printed_next_step = 1
}

# This is run for all the input that isn't a whitelist file...
!($0 in whitemap) {
    print $0
}
