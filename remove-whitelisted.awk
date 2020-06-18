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

# Read in the whitelist file and store domains in the whitelist map.
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

# This is run for all the input that isn't the whitelist file...
!($0 in whitemap) {
    print $0
}
