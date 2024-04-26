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

# Execute the script
./ddns.sh
