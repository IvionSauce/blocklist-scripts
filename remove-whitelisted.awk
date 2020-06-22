#!/usr/bin/awk -f

# With help from https://backreference.org/2010/02/10/idiomatic-awk/
# and https://backreference.org/2014/10/13/range-of-fields-in-awk/

BEGIN {
    # Error, we need at least the whitelist file as argument.
    if (ARGC == 1) {
	# Perform some trickery to get the script name.
	name_cmd = "basename \"$(ps -p $PPID -o cmd= | cut -d' ' -f3)\""
	name_cmd | getline script_name
	close(name_cmd)

	print "Provide a file with whitelisted domains:" > "/dev/stderr"
	print script_name " <whitelist-file> [blocklist-file...]" > \
	    "/dev/stderr"
	exit 2
    }
    # If just 1 argument, the whitelist, remove domains from stdin.
    if (ARGC == 2) {
	ARGV[2] = "-"
	ARGC++
    }
}

(NR == FNR && FILENAME == ARGV[1]) {
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
}
