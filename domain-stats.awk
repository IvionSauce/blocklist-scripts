#!/usr/bin/awk -f

BEGIN {
    FS = "."
    OFS = "."
    if (d == 0) threshold = 2
    else threshold = d
}

# Simply count domain name occurrences if invoked with a negative `d` value.
threshold <= 0 {
    domcounts[$0]++
    next
}

# With help from https://backreference.org/2014/10/13/range-of-fields-in-awk/
{
    # Chops off the lowest subdomain and adds to the count of the resultant
    # domain, repeat until there's only `threshold` domains left in the domain
    # name. Example, with threshold = 1: ads.example.org -> example.org -> org
    # The counts for example.org and org are incremented.
    for (i = 1; i <= (NF - threshold); i++) {
	$i = ""
	domain = substr($0, i + 1)
	domcounts[domain]++
    }
}

END {
    PROCINFO["sorted_in"] = "@val_num_desc"
    pad = -1
    for (domain in domcounts) {
	count = domcounts[domain]

	# Only true for the first item, which has highest count. Thus we'll use
	# that one for determining the amount of padding.
	if (pad < 0)
	    pad = length(count) + 1

	if (count > 1)
	    printf "%" pad "s   %s\n", count, domain
	else
	    break
    }
}
