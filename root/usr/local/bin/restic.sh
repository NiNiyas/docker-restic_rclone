#!/bin/sh

set -e

echo -e ------------------------------------------------------------------------------------------
echo -e "RESTIC_REPOSITORY=${RESTIC_REPOSITORY}\\n\
RESTIC_PASSWORD=${RESTIC_PASSWORD}"

if ! restic snapshots &> /dev/null; then
    echo "Initializing repository"
    restic init --verbose || (echo "Initializing repository failed"; exit 1)
fi

echo "Starting backup of /data at $(date +"%Y-%m-%d %H:%M:%S %Z")"
if [ "${NOTIFICATIONS:-false}" = true ]; then
    if [ -n "$APPRISE_BACKUP_ARGS" ]; then
        BACKUP=$(restic --verbose -r="${RESTIC_REPOSITORY}" backup ${RESTIC_BACKUP_ARGS:-} /data || (echo "Error backing up /data"; exit 1))
        apprise ${APPRISE_BACKUP_ARGS:-} -t "${APPRISE_TITLE:-"Restic Backup"}" -b "$BACKUP" || (echo "Error sending notifications")
    else
        echo "NOTIFICATIONS is True, but APPRISE_BACKUP_ARGS is not set. Please check your configuration. Notifications will not work."
    fi
else
    restic --verbose -r="${RESTIC_REPOSITORY}" backup ${RESTIC_BACKUP_ARGS:-} /data || (echo "Error backing up /data"; exit 1)
fi

if [ -n "$RESTIC_FORGET_ARGS" ]; then
    if [ "${NOTIFICATIONS:-false}" = true ]; then
    if [ -n "$APPRISE_FORGET_ARGS" ]; then
        FORGET=$(restic forget ${RESTIC_FORGET_ARGS} || (echo "Forgetting old snapshots failed"; exit 1))
        apprise ${APPRISE_FORGET_ARGS:-} -t "Purging older snapshots" -b "$FORGET" || (echo "Error sending forget notifications")
        echo "Successfully ran restic forget command"
    else
        echo "NOTIFICATIONS is True, but APPRISE_FORGET_ARGS is not set. Please check your configuration. Notifications will not work."
    fi
else
    restic forget --verbose ${RESTIC_FORGET_ARGS} || (echo "Forgetting old snapshots failed"; exit 1)
    echo "Successfully ran restic forget command"
fi
fi

if [ -n "$HEALTHCHECK" ]; then
    echo "Performing healthcheck"
    wget --header="${HEALTHCHECKS_HEADER_KEY}: ${HEALTHCHECKS_HEADER_VALUE}" ${HEALTHCHECK} -T 10 -t 5 -O /dev/null || (echo "Error occurred when trying to perform healthcheck."; exit 1)
    echo "Successfully performed healthcheck"
fi

echo -e ------------------------------------------------------------------------------------------
