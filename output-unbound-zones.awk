#!/usr/bin/awk -f

{
    print "local-zone: \"" $0 "\" always_nxdomain"
}
