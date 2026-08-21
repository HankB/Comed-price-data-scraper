# Comed-price-data-scraper

Scrape Comed (Commonwealth Edison) live prices using their API

* <https://hourlypricing.comed.com/hp-api/>

## 2026-04-03 work with Claude to write a script.

Prompt:

* Let's start exploring the COMED API for demand pricing: https://hourlypricing.comed.com/hp-api/. The first thing I would like to do is just explore the 5 minute pricing results. I think a bash script should be suitable for this exploration. Can you craft a script that will request prices for 5 minutes before and 5 minutes after the current time and write the results to the console?
* Let's not round to the nearest 5 minute slot. I'm curious what the results will be as time progresses.

Result is `5min-prices.sh`

## 2026-06-11 investigate timing

Purpose is to explore the timing of updates which seem delayed from real time by over ten minutes. Produce output that includes the most recent reading, time stamp for that reading, time stamp when the script ran and delay between the two time stamps. This can be run 1/minute to observe when a new reading will arrive.

## 2026-08-21 deploy

This has been running several months on `oak` and seems to be providing useful results. Time to describe how to deploy.

```text
cd ../some/convenient/directory
git clone git@github.com:HankB/Comed-price-data-scraper.git # or your fork or the HTTPS URL
cd Comed-price-data-scraper
mkdir -p ~/bin
cp 5min-prices-json.sh ~/bin
./install-comed-timer.sh ~/bin # and follow instructions provided by this script
```

Typical feedback from the install script:

```text
Installed:
  /home/hbarta/.config/systemd/user/comed-5min-price.service
  /home/hbarta/.config/systemd/user/comed-5min-price.timer

Hostname baked in: trixi
Script path: /home/hbarta/bin/5min-prices-json.sh

Next steps:
  systemctl --user daemon-reload
  systemctl --user enable --now comed-5min-price.timer

To check status / logs:
  systemctl --user list-timers comed-5min-price.timer
  journalctl --user -u comed-5min-price.service -f

Note: for the timer to run when you're not logged in, enable lingering:
  loginctl enable-linger $USER
```
