#!/bin/bash

# Set file paths
CSV_FILE="users.csv"
LOG_FILE="/var/log/user_onboarding_audit.log"
PROJECTS_DIR="/opt/projects"

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Run this as root."
    exit 1
fi

# Make sure the CSV exists
if [ ! -f "$CSV_FILE" ]; then
    echo "CSV file not found."
    exit 1
fi

# Make sure the projects directory exists
mkdir -p "$PROJECTS_DIR"

# Start the log
echo "$(date) - Starting user onboarding" >> "$LOG_FILE"

# Read CSV, skipping the first line (header)
tail -n +2 "$CSV_FILE" | while IFS=',' read username groups shell
do
    # Skip if any field is empty
    if [ -z "$username" ] || [ -z "$groups" ] || [ -z "$shell" ]; then
        echo "$(date) - Missing fields, skipping." >> "$LOG_FILE"
        continue
    fi

    # Split group names by "/" into an array
    IFS='/' read -ra group_array <<< "$groups"

    # First group is the primary group
    primary_group="${group_array[0]}"

    # Create each group if it doesn't exist
    for g in "${group_array[@]}"; do
        if ! getent group "$g" > /dev/null; then
            groupadd "$g"
            echo "$(date) - Group $g created." >> "$LOG_FILE"
        fi
    done

    # Check if user already exists
    if id "$username" &>/dev/null; then
        # If user exists, just update their shell
        usermod -s "$shell" "$username"
        echo "$(date) - Updated shell for $username." >> "$LOG_FILE"
    else
        # Join all groups with commas for -G option
        all_groups=$(IFS=','; echo "${group_array[*]}")
        # Create new user with home directory and group memberships
        useradd -m -s "$shell" -g "$primary_group" -G "$all_groups" "$username"
        echo "$(date) - User $username created." >> "$LOG_FILE"
    fi

    # Fix home directory permissions
    chmod 700 /home/"$username"
    chown "$username":"$primary_group" /home/"$username"

    # Create project directory for the user
    mkdir -p "$PROJECTS_DIR/$username"
    chown "$username":"$primary_group" "$PROJECTS_DIR/$username"
    chmod 750 "$PROJECTS_DIR/$username"
    echo "$(date) - Project dir for $username created." >> "$LOG_FILE"

done

# Finish log
echo "$(date) - Finished user onboarding" >> "$LOG_FILE"