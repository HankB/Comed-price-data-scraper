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
