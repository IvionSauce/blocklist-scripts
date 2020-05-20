#!/bin/bash

# Forcing the C locale makes rev/sort(/regex?) run _slightly_ faster, but it's
# near negligible. While it shouldn't cause any issues - since proper domain
# names are ASCII - there are some hosts files that do erroneously contain
# non-ASCII characters in domain names. Unicode domain names should be punycode
# encoded. This environment variable does ensure sort collates the way we want.
export LC_ALL=C

read -d '' -r awk_script << 'EOA'
BEGIN {
    # Domain names don't contain spaces, so this is a nice 'empty' value.
    checking=" "
}

$0 !~ checking {
    # Output domain name if it isn't a subdomain of the domain name we're
    # checking for.
    print $0
    # Update the pattern we're checking for. We have to escape literal dots
    # because this is a regexp.
    gsub(/\./, "\\.", $0)
    checking="^" $0 "\\..+"
}
EOA

# Manually writing out key-indices is for chumps. Also 63 subdomains should be
# enough for everyone.
# Limiting this to fewer subdomains, for example 3, can shave a few seconds off
# the runtime of sort. But I prefer the certainty of a more exhaustive sort.
auto_keys() {
    for i in {1..64}; do
	printf -- "-k %s,%s " $i $i
    done
}

# Besides removing duplicates and subdomains we also make the assumption that
# if the 'www' subdomain is to be blocked that we might as well block the entire
# domain.
sed -E 's/^www\.//' -- "$@" \
    | rev | sort -u -t '.' $(auto_keys) | awk "$awk_script" | rev
