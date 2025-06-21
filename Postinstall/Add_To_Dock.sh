#!/bin/zsh

#====================================================================
# Add_To_Dock.sh
#====================================================================
# 
# Purpose: Adds an application to the macOS Dock for all user accounts on the
#          system. This is commonly used as a postinstall script to ensure
#          newly installed applications appear in users' Docks automatically.
#
# Requirements: dockutil must be installed at /usr/local/bin/dockutil
#               (https://github.com/kcrawford/dockutil)
#
# Usage:   Set APP_NAME to the target application's full path
#          The script will add the app to all user Docks and restart Dock
#
# Exit Codes:
#   0 - Successfully added application to Dock(s)
#   1 - Application not found or dockutil not available
#
#====================================================================

# Path to the app you want to add to the Dock
APP_PATH="/Applications/{{APP_NAME}}.app"

# Check that the app exists
if [[ ! -d "$APP_PATH" ]]; then
    echo "App not found at $APP_PATH"
    exit 1
fi

# Path to dockutil
DOCKUTIL="/usr/local/bin/dockutil"

# Check that dockutil exists
if [[ ! -f "$DOCKUTIL" ]]; then
    echo "dockutil not found at $DOCKUTIL"
    exit 1
fi

# Track users who had dock changes
USERS_CHANGED=()

# Loop through all user home directories
for USER_HOME in /Users/*; do
    # Skip if not a directory
    if [[ ! -d "$USER_HOME" ]]; then
        continue
    fi
    
    USER_NAME=$(basename "$USER_HOME")
    echo "Processing user: $USER_NAME"

    # Skip system directories and validate user directory
    if [[ "$USER_NAME" == "Shared" || "$USER_NAME" == ".localized" ]]; then
        echo "Skipping system directory: $USER_NAME"
        continue
    fi
    
    # Skip if not a real user directory (check for UID > 500)
    USER_ID=$(id -u "$USER_NAME" 2>/dev/null)
    if [[ $? -ne 0 || $USER_ID -lt 500 ]]; then
        echo "Skipping system user: $USER_NAME (UID: $USER_ID)"
        continue
    fi

    # Check if user has dock preferences (skip service accounts that never logged in)
    DOCK_PLIST="$USER_HOME/Library/Preferences/com.apple.dock.plist"
    if [[ ! -f "$DOCK_PLIST" ]]; then
        echo "No dock preferences found for $USER_NAME, skipping (likely service account?)"
        continue
    fi

    # Check if app already exists in dock, if so skip
    EXISTING_CHECK=$(su "$USER_NAME" -l -c "$DOCKUTIL --list" | grep -c "$(basename "$APP_PATH" .app)")
    
    if [[ $EXISTING_CHECK -gt 0 ]]; then
        echo "App already exists in $USER_NAME's Dock, skipping..."
        continue
    fi
    
    # Add the app to dock
    if su "$USER_NAME" -l -c "$DOCKUTIL --add \"$APP_PATH\" --no-restart"; then
        echo "Successfully added $APP_PATH to $USER_NAME's Dock"
        USERS_CHANGED+=("$USER_NAME")
    else
        echo "Failed to add $APP_PATH to $USER_NAME's Dock"
    fi
done

# Restart Dock only for users who had changes made
if [[ ${#USERS_CHANGED[@]} -gt 0 ]]; then
    echo "Restarting Dock for users with changes: ${USERS_CHANGED[*]}"
    for CHANGED_USER in "${USERS_CHANGED[@]}"; do
        # Check if user is currently logged in
        if who | grep -q "^$CHANGED_USER "; then
            su "$CHANGED_USER" -l -c "pkill Dock" 2>/dev/null && echo "Restarted Dock for $CHANGED_USER"
        else
            echo "$CHANGED_USER not currently logged in, dock will update on next login"
        fi
    done
else
    echo "No dock changes made, skipping Dock restart"
fi

exit 0