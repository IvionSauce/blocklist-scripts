#!/bin/bash

# Regexp list of common bogus addresses, either remnants or errors
# from a hosts file.
BOGUS='0\.0\.0\.0|127\.0\.0\.1|localhost|local'
# How relevant entries start in the hosts file.
HOST_BEGIN='^\s*(127\.0\.0\.1|0\.0\.0\.0)'

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

awk "$awk_script" < \
    <(grep --text --no-filename -E "$HOST_BEGIN" "$@" \
	  | sed -E s/"$HOST_BEGIN"'\s+(\S+).*$/\2/' \
	  | sed -E "/^(${BOGUS})$/d" \
	  | rev \
	  | sort -t '.' -k 1,1 -k 2,2 -k 3,3 -k 4,4) \
    | rev
