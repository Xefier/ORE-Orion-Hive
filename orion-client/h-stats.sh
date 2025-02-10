#!/usr/bin/env bash

. $MINER_DIR/$CUSTOM_MINER/h-manifest.conf

#STATS_UPTIME=$(curl --connect-timeout 2 --max-time 30 --silent --noproxy '*' http://127.0.0.1:4000/uptime)
uptime=$(awk '{print $1}' /proc/uptime)
#uptime=`echo $STATS_UPTIME | jq -r '.Seconds'`
#uptime=1
hs=[0.001]
temp=[60]
fan=[25]
ver="1.0.0"
bus_numbers=[null]

khs=0.001
stats=$(jq -n --argjson uptime "$uptime" --argjson hs "$hs" --argjson temp "$temp" --argjson fan "$fan" --arg algo "COAL/ORE" --arg ver "$ver" --argjson bus_numbers "$bus_numbers" '{$hs, $temp, $fan, $uptime, $algo, $ver, $bus_numbers}')

