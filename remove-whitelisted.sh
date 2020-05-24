#!/bin/bash

export LC_ALL=C

read -d '' -r awk_script << 'EOA'
(NR == FNR && FILENAME == ARGV[1]) {
    if (/^\s*[^#]/) {
	whitemap[$1]
    }
    next
}

!($0 in whitemap) {
    print $0
}
EOA

case $# in
    0) echo "Provide a file with whitelisted domains:"
       echo "$(basename $0) <whitelist> [blocklist]..."
       exit 2 ;;
    1) wfile="$1"; rest='-' ;;
    *) wfile="$1"; shift; rest="$@" ;;
esac

awk -- "$awk_script" "$wfile" $rest
