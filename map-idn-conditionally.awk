#!/usr/bin/awk -f

{
    if ($0 ~ /[^\0-\177]/) {
	cmd = "idn2 " $0
	cmd | getline puny
	close(cmd)

	print puny
    }
    else {
	print $0
    }
}
