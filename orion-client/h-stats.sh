#!/usr/bin/env bash

. $MINER_DIR/$CUSTOM_MINER/h-manifest.conf

# Define a separate stats log file to avoid interfering with the miner
STATS_LOG_FILE="${CUSTOM_LOG_BASENAME}-stats.log"

# Check if the stats log file exists and is readable
if [[ ! -f "$STATS_LOG_FILE" || ! -s "$STATS_LOG_FILE" ]]; then
  echo "Error: Stats log file is missing or empty." >&2
  HASHRATES=""
else
  # Extract Avg Hashrate values for GPUs (skipping CPU row)
  HASHRATES=$(awk '/Pool: Excalivator Pool/ {found=1} found && $3 == "Mining" && $5 ~ /^[0-9.]+$/ {print $5}' "$STATS_LOG_FILE")
fi

# Format hashrates as an array, defaulting to [0] if empty
hs=$(echo "$HASHRATES" | tr '\n' ',' | sed 's/,$//')
hs=${hs:-0}

# Calculate total hashrate (sum of all GPUs) in kH/s, defaulting to 0
khs=$(echo "$HASHRATES" | awk '{sum+=$1} END {print sum}')
khs=${khs:-0}

# Fetch GPU temperature and fan speed using nvidia-smi
if command -v nvidia-smi &> /dev/null; then
  temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | tr '\n' ',' | sed 's/,$//')
  fan=$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits | tr '\n' ',' | sed 's/,$//')
else
  echo "Error: nvidia-smi command not found. Defaulting temp and fan values." >&2
  temp="[60]"
  fan="[25]"
fi

# Ensure temp and fan arrays are JSON-compatible
temp=${temp:-[60]}
fan=${fan:-[25]}

# Get uptime from the system
uptime=$(awk '{print $1}' /proc/uptime)

# Other fixed parameters
ver="1.0.0"
bus_numbers="[null]"

# Construct the stats JSON
stats=$(jq -n --argjson uptime "$uptime" --argjson hs "[$hs]" --argjson temp "[$temp]" --argjson fan "[$fan]" --arg algo "$CUSTOM_ALGO" --arg ver "$ver" --argjson bus_numbers "$bus_numbers" '{$hs, $temp, $fan, $uptime, $algo, $ver, $bus_numbers}')

# Output stats
echo "$stats"
