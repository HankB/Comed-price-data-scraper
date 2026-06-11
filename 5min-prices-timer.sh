#!/usr/bin/env bash
# =============================================================================
# comed_5min_prices.sh
# Fetches ComEd 5-minute pricing for a window centered on the current time:
#   5 minutes before  →  now  →  5 minutes after
#
# Usage:  bash comed_5min_prices.sh
# Requires: curl, python3 (for JSON pretty-print)
# =============================================================================

BASE_URL="https://hourlypricing.comed.com/api"

# ---------- build timestamps --------------------------------------------------
# ComEd format: YYYYMMDDhhmm  (local time, exact — no rounding)
now_epoch=$(date +%s)
start_epoch=$(( now_epoch - 1200 ))   # 5 minutes ago
end_epoch=$(( now_epoch + 1200 ))     # 5 minutes from now

# Format as YYYYMMDDhhmm in local time (truncates seconds naturally)
datestart=$(date -d "@${start_epoch}" +"%Y%m%d%H%M" 2>/dev/null \
         || date -r "${start_epoch}"  +"%Y%m%d%H%M")   # macOS fallback

dateend=$(date -d "@${end_epoch}" +"%Y%m%d%H%M" 2>/dev/null \
       || date -r "${end_epoch}"  +"%Y%m%d%H%M")       # macOS fallback

# ---------- call the API ------------------------------------------------------
URL="${BASE_URL}?type=5minutefeed&datestart=${datestart}&dateend=${dateend}&format=json"

response=$(curl --silent --fail "$URL")
curl_exit=$?

if [[ $curl_exit -ne 0 ]]; then
  echo " ERROR: curl failed (exit ${curl_exit}). Check network / URL." >&2
  exit $curl_exit
fi

if [[ -z "$response" || "$response" == "[]" ]]; then
  echo " No data returned for this window."
  exit 0
fi

# ---------- pretty-print + decode — pass response as argv[1] to avoid stdin conflict
python3 - "$response" <<'PYEOF'
import sys, json, time

raw = sys.argv[1]

try:
    records = json.loads(raw)
except json.JSONDecodeError as e:
    print(f"  JSON parse error: {e}")
    sys.exit(1)

if not records:
    sys.exit(0)

# Sort descending by time. We only want the latest
records.sort(reverse=True, key=lambda r: int(r["millisUTC"]))

for r in records:
    timestamp = int(int(r["millisUTC"])/1000)
    price  = r["price"]
    present_time = int(time.time())
    delay = int(present_time-timestamp)
    print(f"{timestamp} {present_time} {price} {delay}")
    sys.exit(0);

PYEOF

