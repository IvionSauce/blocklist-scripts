#!/bin/bash

# Forcing the C locale shouldn't cause any issues - since proper domain names
# are ASCII - but there are some blocklists that do contain non-ASCII characters
# in domain names. Those domains need to be put through `idn2` before serving as
# input to this script. It _will choke_ on Unicode (mostly `rev`).
# This environment variable ensures sort collates the way we want.
export LC_ALL=C

# This awk script removes duplicated domains and folds subdomains into their
# parent domain in one fell swoop, thanks to the work done by `rev` and `sort`.
# Having `sort` perform the kind of sort we want, parent domains before child
# domains, _without_ using rev is *much* slower. It makes the logic in the awk
# script simpler as well: we just have to check if a (sub)domain starts with the
# current (parent) domain we're checking for.
read -d '' -r awk_script << 'EOA'
BEGIN {
    # Domain names don't contain spaces, so this is a nice 'empty' value.
    checking = " "
}

new_domain() {
    # Output domain name if we haven't seen it before and it isn't a subdomain
    # of the domain name we're checking for.
    print $0
    # Update the domain we're checking for.
    checking = $0
}

# Return false if it's the same domain or a subdomain.
function new_domain() {
    return !(index($0, checking) == 1 &&
	     (length() == length(checking) || index($0, checking ".") == 1))
}
EOA

# Manually writing out key-indices is for chumps. Also 63 subdomains should be
# enough for everyone.
# Limiting this to fewer subdomains, for example 3, can shave a few seconds off
# the run time of `sort`. I specifically mention "3" because, with the blocklist
# data I have, anything more exhaustive doesn't net you any more reductions.
# But I prefer the certainty of a more exhaustive sort; I cannot predict what
# kind of data other people have either.
auto-keys() {
    for i in {1..64}; do
	printf -- '-k %s,%s ' $i $i
    done
}

# Besides removing duplicates and subdomains we also make the assumption that
# if the 'www' subdomain is to be blocked that we might as well block the entire
# domain.
sed -E 's/^(www\.)+(.+\..+)/\2/' -- "$@" \
    | rev | sort -t '.' $(auto-keys) | awk "$awk_script" | rev
