#!/usr/bin/awk -f

{
    if ($0 ~ /[^\0-\177]/) {
	print $0 | "idn2"
    }
    else {
	print $0
    }
}
