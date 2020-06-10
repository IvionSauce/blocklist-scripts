# Blocklist parsing/filtering/transforming scripts

## About
A variety of shell (Bash) and awk scripts to whip into shape the large amounts of domains contained in common blocklists. When you combine multiple blocklists you naturally get duplicates, these are easily caught by using something like `sort -u` … but there’s more to gain if one runs their own recursive and/​or caching name server.

Most of these blocklists are not made or curated with the capabilities of name servers in mind. By using the `NXDOMAIN` response code a name server signals that the domain does not exist, and by extension no domains exist below said domain. We can use this [fact](https://tools.ietf.org/html/rfc8020) to further reduce the amount of domains we need to keep track of.

### Overview of scripts
What follows are the scripts in the order that I use them, they’re kept seperate to aid in mixing and matching. All commands, except `get-blocklists.sh`, output their results on stdout. Commands that optionally accept a list of files also accept input from stdin instead of those files.

#### parse-blocklists.sh [blocklist-file...]
Given a number of files, either hosts files or files containing just a list of domains, will output just the domains seperated by newlines. This will be the starting point of the pipeline.

#### map-idn-conditionally.awk [domain-file...]
Takes in a list of domains and runs domains through `idn2` when necessary.

#### reduce-domains.sh [domain-file...]
Takes in a list of domains and reduces domains to their topmost common domain, so if a domain and various of its subdomains are specified in the blocklists only the domain will be output. This functionality is why I made these scripts, the rest are to facilitate this or to deal with the idiosyncrasies that come with filtering/​transforming blocklists of varying formats and quality.

#### select-reasonable-domains.sh [domain-file...]
Takes in a list of domains and filters out domains that are probably errors in the source blocklists, these rejected domains are printed on stderr. This also rejects domain names containing non-ASCII characters, it is therefore prudent to run this after `map-idn-conditionally.awk`.

#### remove-whitelisted.sh \<whitelist-file> [domain-file...]
Takes in a list of domains and removes domains that are in the whitelist. This requires a file with whitelisted domains to be passed as the first argument.

#### output-unbound-zones.awk [domain-file...]
At the end of the pipeline this transforms the list of bare domains into the zone format Unbound uses.

#### The odd one out: get-blocklists.sh \<save-path>
Does not participate in the pipeline above, but downloads a number of predefined blocklists. The downloaded blocklists are stored in _save-path_.

#### The sidetrack: domain-stats.awk [-v d=N] [domain-file...]
Takes in a list of domains and prints statistics on how many subdomains a domain has. Setting `d` determines the **d**epth: 1 will start aggregating and counting domains below the top-level domain, 2 will start at one domain below that, etc. Setting `d` to a negative value will instead count domain occurrences verbatim (no counting of subdomains). The default value for `d` is 2.

### Dependencies
These scripts judiciously use various GNU utilities: `bash` of course, but also `tr`, `grep`, `awk`, `sed` and `sort`. No care was taken to ensure compatibility with non-GNU variants.

As the name suggests, `map-idn-conditionally.awk` depends on `idn2` from the [libidn2](https://gitlab.com/libidn/libidn2) project.

## Comparisons
With the set of blocklists I have the number of domains returned by `parse-blocklists.sh` is a little over a million: 1,025,197. Running those through a simple `sort -u` lowers it to 750,705 – so we’ve got about 275 thousand straight up duplicates. Instead running the full list of domains through `reduce-domains.sh` returns 481,970 domains – so there are another 270 thousand domains, that are superfluous when responding with `NXDOMAIN`.

The downside to this is that `reduce-domains.sh` is about 2 to 3 times slower than just `sort -u`. But as it is multiple commands in a pipeline some of the commands can run parallel, as each is run in a subshell. The actual run time on my machine (Intel i5-3350P, Crucial SATA SSD) is 60 to 70% slower; 4 to 5 seconds for a little over 1 million domains. Faster would be better, and analyzing the run time shows that the `sort` command in `reduce-domains.sh` is where the most time is spent. Effort should be focused on optimizing that part of the pipeline, the time taken by the rest is negligible.

## Copyright and stuff
I can be short and clear: these scripts are released into the public domain. You are free to use, modify, share and not share them in any way you see fit.
