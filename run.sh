#!/bin/bash

# Check if the 'ddns' directory already exists
if [ -d "ddns" ]; then
    echo "Directory 'ddns' already exists."
else
    # Clone the repository
    git clone https://github.com/charmingyi/ddns.git ddns
fi

# Change directory to the cloned repository
cd ddns

# Check if 'ddns.sh' file exists
if [ -f "ddns.sh" ]; then
    # Execute the script
    ./ddns.sh
else
    echo "Error: 'ddns.sh' file not found in 'ddns' directory."
    exit 1
fi
