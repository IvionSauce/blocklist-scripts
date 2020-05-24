# Blocklist parsing/filtering/transforming scripts

## About
A variety of shell (Bash) and awk scripts to whip into shape the large amounts of domains contained in common blocklists. When you combine multiple blocklists you naturally get duplicates, these are easily caught by using something like `sort -u` … but there’s more to gain if one runs their own recursive and/​or caching name server.

Most of these blocklists are not made or curated with the capabilities of name servers in mind. By using the `NXDOMAIN` response code a name server signals that the domain does not exist, and by extension no domains exist below said domain. We can use this [fact](https://tools.ietf.org/html/rfc8020) to further reduce the amount of domains we need to keep track of.

### Overview of scripts
What follows are the scripts in the order that I use them. They’re kept seperate to aid in mixing and matching.

#### parse-blocklists.sh
Given a number of files, either hosts files or files containing just a list of domains, will output just the domains seperated by newlines. This will be the starting point of the pipeline.

#### map-idn-conditionally.awk
Scans through a list of domains and runs them through `idn2` when necessary.

#### domains-reduce.sh
Takes in a list of domains and reduces domains to their topmost common domain, so if a domain and various of its subdomains are specified in the blocklists only the domain will be output. This functionality is why I made these scripts, the rest are to facilitate this or to deal with the idiosyncrasies that come with filtering/​transforming blocklists of varying formats and quality.

#### select-reasonable-domains.sh
Filters out domains that are probably errors in the source blocklists, these rejected domains are printed on stderr. This also rejects domain names containing non-ASCII characters, it is therefore prudent to run this after `map-idn-conditionally.awk`.

#### output-unbound-zones.awk
At the end of the pipeline this transforms the list of bare domains into the zone format Unbound uses.

#### The odd one out: retrieve-blocklists.sh
Does not participate in the pipeline above, but downloads a number of predefined blocklists.

### Dependencies
These scripts judiciously use various GNU utilities: `bash` of course, but also `tr`, `grep`, `awk`, `sed` and `sort`. No care was taken to ensure compatibility with non-GNU variants.

## Comparisons
With the set of blocklists I have the number of domains returned by `parse-blocklists.sh` is a little over a million: 1,025,170. Running those through a simple `sort -u` lowers it to 750,681 – so we’ve got about 250 thousand straight up duplicates. Instead running the full list of domains through `domains-reduce.sh` returns 481,948 domains, so we’ve got another 250 to 300 thousand domains that are unneeded when responding with `NXDOMAIN`.

The downside to this is that `domains-reduce.sh` is about 2 to 3 times slower than just `sort -u`. Still, with about 1 million domains it does its thing in 6 to 7 seconds on my machine – which has an Intel i5-3350P and a Crucial SATA SSD. Faster would be better, and analyzing the run time shows that `sort` command in `domains-reduce.sh` is where the most time is spent. Effort should be focused on optimizing that part of the pipeline, the time taken by the rest is negligible.

## Copyright and stuff
I can be short and clear: these scripts are released into the public domain. You are free to use, modify, share and not share them in any way you see fit.
