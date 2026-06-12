#!/usr/bin/env bash
# =============================================================================
# 5min-prices-json.sh
# Fetches the most recently completed ComEd 5-minute price interval and prints:
#   report_time  current_time  price  delay_seconds  retries
#
# Designed to be run by a systemd timer shortly after each 5-minute boundary.
# If the new interval's price is not yet published, retries every 10s
# indefinitely (outages have been observed lasting hours, so no retry cap).
#
# During an outage, if the wall clock crosses into a new 5-minute interval
# while still waiting, the target interval is advanced to match — the API
# does not backfill skipped intervals, it just resumes with the latest one.
#
# On curl errors or invalid/empty JSON responses, diagnostics are written
# to STDERR (curl errors are shown directly since --silent is no longer used).
#
# Usage:  bash 5min-prices-json.sh
# Requires: curl, jq
# =============================================================================

BASE_URL="https://hourlypricing.comed.com/api"
RETRY_DELAY=10

retries=0
target_interval_end=$(( ($(date +%s) / 300) * 300 ))

while true; do
  interval_start=$(( target_interval_end - 300 ))

  datestart=$(date -d "@${interval_start}" +"%Y%m%d%H%M" 2>/dev/null \
           || date -r "${interval_start}"  +"%Y%m%d%H%M")
  dateend=$(date -d "@${target_interval_end}" +"%Y%m%d%H%M" 2>/dev/null \
         || date -r "${target_interval_end}"  +"%Y%m%d%H%M")

  URL="${BASE_URL}?type=5minutefeed&datestart=${datestart}&dateend=${dateend}&format=json"

  response=$(curl --silent --show-error --fail "$URL")
  curl_status=$?

  if [[ $curl_status -eq 0 ]]; then
    if [[ -n "$response" && "$response" != "[]" ]]; then
      result=$(echo "$response" | jq -r \
        'max_by(.millisUTC | tonumber)
         | [(.millisUTC | tonumber / 1000 | floor), .price]
         | @tsv' 2>/dev/null)
      jq_status=$?

      if [[ $jq_status -ne 0 ]]; then
        echo "WARNING: invalid JSON response (jq exit ${jq_status}) from API:" >&2
        echo "$response" >&2
      else
        read -r report_time price <<< "$result"

        if (( report_time >= interval_start )); then
          current_epoch=$(date +%s)
          jq -ncj \
            --arg t "$current_epoch" \
            --arg price_t "$report_time" \
            --arg price "$price" \
            --arg delay "$(( current_epoch - report_time ))" \
            --arg retries "$retries" \
            --arg device "comed_api" \
            '{t: ($t|tonumber), price_t: ($price_t|tonumber), price: ($price|tonumber), delay: ($delay|tonumber), retries: ($retries|tonumber), device: $device}'
          exit 0
        fi
        # else: latest available record is still older than our target; retry
      fi
    else
      echo "WARNING: empty response from API" >&2
    fi
  else
    echo "WARNING: curl failed (exit ${curl_status})" >&2
  fi

  retries=$(( retries + 1 ))
  sleep "$RETRY_DELAY"

  current_interval_end=$(( ($(date +%s) / 300) * 300 ))
  if (( current_interval_end > target_interval_end )); then
    target_interval_end=$current_interval_end
  fi
done