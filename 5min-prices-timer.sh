#!/usr/bin/env bash
# =============================================================================
# comed_5min_prices.sh
# Fetches the most recent ComEd 5-minute price and prints:
#   report_time  current_time  price  delay_seconds
#
# Usage:  bash comed_5min_prices.sh
# Requires: curl, jq
# =============================================================================

BASE_URL="https://hourlypricing.comed.com/api"

now_epoch=$(date +%s)
start_epoch=$(( now_epoch - 1200 ))
end_epoch=$(( now_epoch + 1200 ))

datestart=$(date -d "@${start_epoch}" +"%Y%m%d%H%M" 2>/dev/null \
         || date -r "${start_epoch}"  +"%Y%m%d%H%M")
dateend=$(date -d "@${end_epoch}" +"%Y%m%d%H%M" 2>/dev/null \
       || date -r "${end_epoch}"  +"%Y%m%d%H%M")

URL="${BASE_URL}?type=5minutefeed&datestart=${datestart}&dateend=${dateend}&format=json"

response=$(curl --silent --fail "$URL")

if [[ $? -ne 0 || -z "$response" || "$response" == "[]" ]]; then
  exit 1
fi

# Pick the record with the highest millisUTC, extract report_time (seconds) and price
read -r report_time price <<< "$(
  echo "$response" \
  | jq -r 'max_by(.millisUTC | tonumber)
           | [(.millisUTC | tonumber / 1000 | floor), .price]
           | @tsv'
)"

echo "$report_time $now_epoch $price $(( now_epoch - report_time ))"