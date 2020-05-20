#!/bin/sh

# These sources are sourced (heh) from:
# https://v.firebog.net/hosts/lists.php?type=nocross

# I've made these changes due to issues:
# ---
# 1. https://hosts.nfz.moe/basic/hosts
# Issue: serves up some cloudflare anti-DDoS/bot bullshit.
# Fix: replace with
# https://cdn.jsdelivr.net/gh/neoFelhz/neohosts@gh-pages/full/hosts
# ---
BLOCKLIST_SOURCES='https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts_without_controversies.txt
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts
https://v.firebog.net/hosts/static/w3kbl.txt
https://v.firebog.net/hosts/BillStearns.txt
https://sysctl.org/cameleon/hosts
https://www.dshield.org/feeds/suspiciousdomains_Low.txt
https://www.dshield.org/feeds/suspiciousdomains_Medium.txt
https://www.dshield.org/feeds/suspiciousdomains_High.txt
https://raw.githubusercontent.com/matomo-org/referrer-spam-blacklist/master/spammers.txt
https://hostsfile.org/Downloads/hosts.txt
https://someonewhocares.org/hosts/zero/hosts
https://raw.githubusercontent.com/vokins/yhosts/master/hosts
https://winhelp2002.mvps.org/hosts.txt
https://cdn.jsdelivr.net/gh/neoFelhz/neohosts@gh-pages/full/hosts
https://raw.githubusercontent.com/RooneyMcNibNug/pihole-stuff/master/SNAFU.txt
https://ssl.bblck.me/blacklists/hosts-file.txt
https://adaway.org/hosts.txt
https://v.firebog.net/hosts/AdguardDNS.txt
https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt
https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
https://v.firebog.net/hosts/Easylist.txt
https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts
https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts
https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts
https://v.firebog.net/hosts/Easyprivacy.txt
https://v.firebog.net/hosts/Prigent-Ads.txt
https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-blocklist.txt
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts
https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt
https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt
https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt
https://hostfiles.frogeye.fr/multiparty-trackers-hosts.txt
https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt
https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt
https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/AmazonFireTV.txt
https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt
https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt
https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt
https://mirror1.malwaredomains.com/files/justdomains
https://v.firebog.net/hosts/Prigent-Malware.txt
https://mirror.cedia.org.ec/malwaredomains/immortal_domains.txt
https://www.malwaredomainlist.com/hostslist/hosts.txt
https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt
https://phishing.army/download/phishing_army_blocklist_extended.txt
https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt
https://v.firebog.net/hosts/Shalla-mal.txt
https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts
https://urlhaus.abuse.ch/downloads/hostfile/
https://raw.githubusercontent.com/HorusTeknoloji/TR-PhishingList/master/url-lists.txt
https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser'

if [ -z $1 ]; then
    echo "Provide a directory to download blocklists to."
    exit 2
fi
cd -- "$1" || exit 1

failed=""
for url in $BLOCKLIST_SOURCES; do
    wget "$url" || failed="${failed}${url}\n"
done
if [ $failed ]; then
    echo "Failed to download:"
    echo -e "$failed"
fi

### WALL OF SHAME ###
# Removing the title (first line) that really should be commented out.
tail -n+2 simple_malvertising.txt > simple_malvertising.FIX.txt && \
    rm -f simple_malvertising.txt
# There are more errors in SNAFU (apt), but this is the only one that cause us
# to miss domains.
sed 's/<BR>/\n/g' SNAFU.txt > SNAFU.FIX.txt && \
    rm -f SNAFU.txt
