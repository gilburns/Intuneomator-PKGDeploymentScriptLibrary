#!/bin/zsh

#==============================================================================
# Check_For_Managed_Config.sh
#==============================================================================
# 
# Purpose: Waits for a macOS configuration profile to be installed before 
#          proceeding with package installation. This is commonly used as a 
#          preinstall script to ensure required profiles are deployed via MDM
#          before an application is installed.
#
# Usage:   Set BUNDLE_ID to the target configuration profile's bundle identifier
#          The script will wait up to 10 minutes for the profile to appear
#
# Exit Codes:
#   0 - Configuration profile found and installed
#   1 - Timeout reached, profile not found within time limit
#
#==============================================================================

# Set the bundle ID you want to check
BUNDLE_ID="{{BUNDLE_ID}}"

# Wait 10 minutes for the config to show up
timelimit=600
time=0

# Loop and wait for configuration profile
while [[ $time -lt $timelimit ]]; do
    profiles=$(profiles -C -v | awk -F: '/attribute: name/{print $NF}' | grep "${BUNDLE_ID}")
    
    if [[ "$profiles" == *"$BUNDLE_ID"* ]]; then
        echo "Profile exists"
        exit 0
    fi
    
    echo "Profile does not exist, waiting..." && sleep 60; time=$((time+60))
    if [[ $time == $timelimit ]]; then
        echo "The profile was not installed within the wait time"
        exit 1
    fi
done
