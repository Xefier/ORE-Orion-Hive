#!/bin/bash

# Load h-manifest configuration
if [[ ! -f h-manifest.conf ]]; then
    echo "h-manifest.conf not found. Exiting..."
    exit 1
fi

. h-manifest.conf

if [[ ! -f $CUSTOM_CONFIG_FILENAME ]]; then
    echo "Configuration file $CUSTOM_CONFIG_FILENAME not found. Exiting..."
    exit 1
fi

. "$CUSTOM_CONFIG_FILENAME"

# TODO: Configure gpu, cpu, block size, pool, etc in flightsheet
./OrionClient mine --key "$TEMPLATE" --gpu --disable-cpu --gpu-batch-size 2048 --gpu-block-size 512 --pool excalivator