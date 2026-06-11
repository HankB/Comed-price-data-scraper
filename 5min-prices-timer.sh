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

echo "============================================================"
echo " ComEd 5-Minute Pricing Explorer"
echo "============================================================"
echo " Window : $(date -d "@${start_epoch}" 2>/dev/null || date -r "${start_epoch}")"
echo "       → $(date -d "@${end_epoch}"   2>/dev/null || date -r "${end_epoch}")"
echo " API params : datestart=${datestart}  dateend=${dateend}"
echo "------------------------------------------------------------"

# ---------- call the API ------------------------------------------------------
URL="${BASE_URL}?type=5minutefeed&datestart=${datestart}&dateend=${dateend}&format=json"
echo " Requesting: ${URL}"
echo "------------------------------------------------------------"

response=$(curl --silent --fail "$URL")
curl_exit=$?

if [[ $curl_exit -ne 0 ]]; then
  echo " ERROR: curl failed (exit ${curl_exit}). Check network / URL." >&2
  exit $curl_exit
fi

if [[ -z "$response" || "$response" == "[]" ]]; then
  echo " No data returned for this window."
  echo " (ComEd has not yet published prices for this interval; try again shortly.)"
  exit 0
fi

# ---------- pretty-print + decode — pass response as argv[1] to avoid stdin conflict
python3 - "$response" <<'PYEOF'
import sys, json, datetime

raw = sys.argv[1]

try:
    records = json.loads(raw)
except json.JSONDecodeError as e:
    print(f"  JSON parse error: {e}")
    sys.exit(1)

# Pretty-print raw JSON
print(" Raw JSON:")
print(json.dumps(records, indent=4))
print()
print("------------------------------------------------------------")
print(" Decoded timestamps (UTC millis → local time):")
print("------------------------------------------------------------")

if not records:
    print("  (no records)")
    sys.exit(0)

# Sort ascending by time
records.sort(key=lambda r: int(r["millisUTC"]))

print(f"  {'Local Time':<25} {'UTC millis':<16} {'Price (¢/kWh)'}")
print(f"  {'-'*25} {'-'*16} {'-'*13}")
for r in records:
    millis = int(r["millisUTC"])
    price  = r["price"]
    dt_local = datetime.datetime.fromtimestamp(millis / 1000)
    print(f"  {dt_local.strftime('%Y-%m-%d %H:%M:%S'):<25} {millis:<16} {price}")

print()
prices = [float(r["price"]) for r in records]
print(f"  Slots returned : {len(records)}")
print(f"  Price range    : {min(prices):.1f} – {max(prices):.1f} ¢/kWh")
print(f"  Average        : {sum(prices)/len(prices):.2f} ¢/kWh")
PYEOF

echo "============================================================"