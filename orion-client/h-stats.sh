#!/usr/bin/env bash

. $MINER_DIR/$CUSTOM_MINER/h-manifest.conf

# Define the JSON log file
JSON_LOG_FILE="events.log"
DEFAULT_LOG_PATH="/hive/miners/custom/orion-client/events.log"
LOG_FILE="custom.log"

# Redirect all output to a log file for debugging
exec > >(tee -a "$LOG_FILE") 2>&1

# Check if the JSON log file exists and is readable
if [[ ! -f "$JSON_LOG_FILE" || ! -s "$JSON_LOG_FILE" ]]; then
  if [[ -f "$DEFAULT_LOG_PATH" && -s "$DEFAULT_LOG_PATH" ]]; then
    JSON_LOG_FILE="$DEFAULT_LOG_PATH"
  else
    echo "Error: JSON log file is missing or empty." >&2
    exit 1
  fi
fi

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
  echo "Error: 'jq' command not found. Please install jq to proceed." >&2
  exit 1
fi

# Extract the latest group of SubEventType 1 entries
hashes=$(jq '[.[] | select(.SubEventType == 1 and .DeviceId != null and .AverageHashesPerSecond != null) | {id: .DeviceId, hashrate: .AverageHashesPerSecond}]' "$JSON_LOG_FILE")

# Format the hashes array into the required structure
hs=$(echo "$hashes" | jq '[.[] | .hashrate] | map(tonumber)')

# If no hashes are found, default to [0]
hs=${hs:-[0]}

# Calculate total hashrate (sum of all GPUs)
khs=$(echo "$hs" | jq 'add')

# Extract temperature and fan speed using a placeholder (replace this logic if needed)
if command -v nvidia-smi &> /dev/null; then
  temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | tr '\n' ',' | sed 's/,$//')
  fan=$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits | tr '\n' ',' | sed 's/,$//')
else
  echo "Warning: 'nvidia-smi' command not found. Defaulting temp and fan values." >&2
  temp="[60]"  # Default temperature
  fan="[25]"   # Default fan speed
fi

# Ensure temp and fan arrays are JSON-compatible
temp=${temp:-[60]}
fan=${fan:-[25]}

# Get uptime from the system
uptime=$(awk '{print $1}' /proc/uptime)

# Other fixed parameters
ver="1.0.0"
algo="${CUSTOM_ALGO:-COAL/ORE}"  # Default to COAL/ORE if CUSTOM_ALGO is not set
bus_numbers="[null]"

# Construct the stats JSON
stats=$(jq -n --argjson uptime "$uptime" --argjson hs "$hs" --argjson temp "$temp" --argjson fan "$fan" --arg algo "$algo" --arg ver "$ver" --argjson bus_numbers "$bus_numbers" '{$hs, $temp, $fan, $uptime, $algo, $ver, $bus_numbers}')

# Output stats
echo "$stats"
