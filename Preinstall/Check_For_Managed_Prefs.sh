#!/bin/zsh

#====================================================================
# Check_For_Managed_Prefs.sh
#====================================================================
# 
# Purpose: Checks for the existence of a macOS managed preference plist
#          file before proceeding with package installation. This is to
#          ensure required managed preferences are deployed via MDM
#          before an application is installed.
#
# Usage:   Set BUNDLE_ID to the target application's bundle identifier
#          The script will check for the corresponding .plist file in
#          /Library/Managed Preferences/
#
# Exit Codes:
#   0 - Managed preference plist found
#   1 - Managed preference plist not found (Intune will retry installation)
#
#====================================================================

# Set the bundle ID you want to check
BUNDLE_ID="{{BUNDLE_ID}}"

# Path to the managed preference plist
PLIST_PATH="/Library/Managed Preferences/${BUNDLE_ID}.plist"

# Check for existence
if [[ ! -f "$PLIST_PATH" ]]; then
    echo "Managed preference not found: ${BUNDLE_ID}.plist"
    exit 1
else
    echo "Managed preference found: ${BUNDLE_ID}.plist"
    exit 0
fi