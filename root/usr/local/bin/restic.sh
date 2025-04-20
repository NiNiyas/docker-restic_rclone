#!/bin/bash

set -e

if [ ! -n "$RESTIC_REPOSITORY" ]; then
    echo -e "Using default restic repository: rest:http://127.0.0.1:8080"
    export RESTIC_REPOSITORY="rest:http://127.0.0.1:8080"
fi

echo "------------------------------------------------------------------------------------------"
echo -e "RESTIC_REPOSITORY=${RESTIC_REPOSITORY}\\n\
RESTIC_PASSWORD=${RESTIC_PASSWORD}"

if ! restic snapshots &> /dev/null; then
    echo "Initializing repository"
    restic init --verbose --cache-dir="/config/cache" || (echo "Initializing repository failed"; exit 1)
fi

if [ -n "$PRE_BACKUP_COMMANDS" ]; then
    echo "Executing pre-backup commands"
    IFS='|' read -ra PRE_COMMANDS <<< "${PRE_BACKUP_COMMANDS}"
    for command in "${PRE_COMMANDS[@]}"; do
      echo "Executing '${command}'"
      eval "${command}"
      exit_status=$?
      if [ $exit_status -eq 0 ]; then
          echo "Command executed successfully."
      else
          echo "Error executing command. Exit status: $exit_status"
      fi
    done
fi

echo "Starting backup of /data at $(date +"%Y-%m-%d %H:%M:%S %Z")"
if [ "${NOTIFICATIONS:-false}" = true ]; then
    if [ -n "$APPRISE_BACKUP_ARGS" ]; then
        BACKUP=$(restic --verbose --cache-dir="/config/cache" -r="${RESTIC_REPOSITORY}" backup ${RESTIC_BACKUP_ARGS:-} /data || (echo "Error backing up /data"; exit 1))
        apprise ${APPRISE_BACKUP_ARGS:-} -t "${APPRISE_TITLE:-"Restic Backup"}" -b "$BACKUP" || (echo "Error sending notifications")
    fi
else
    restic --verbose --cache-dir="/config/cache" -r="${RESTIC_REPOSITORY}" backup ${RESTIC_BACKUP_ARGS:-} /data || (echo "Error backing up /data"; exit 1)
fi

if [ -n "$RESTIC_FORGET_ARGS" ]; then
    if [ "${NOTIFICATIONS:-false}" = true ]; then
    if [ -n "$APPRISE_FORGET_ARGS" ]; then
        FORGET=$(restic forget --cache-dir="/config/cache" ${RESTIC_FORGET_ARGS} || (echo "Forgetting old snapshots failed"; exit 1))
        apprise ${APPRISE_FORGET_ARGS:-} -t "Purging older snapshots" -b "$FORGET" || (echo "Error sending forget notifications")
        echo "Successfully ran restic forget command"
    fi
else
    restic forget --cache-dir="/config/cache" ${RESTIC_FORGET_ARGS} || (echo "Forgetting old snapshots failed"; exit 1)
    echo "Successfully ran restic forget command"
fi
fi

if [ -n "$HEALTHCHECK_URL" ]; then
    echo "Performing healthcheck"
    if [ -n "${HEALTHCHECK_HEADERS}" ]; then
        IFS='|' read -ra HEADERS <<< "${HEALTHCHECK_HEADERS}"
        command="wget"
        for header in "${HEADERS[@]}"; do
          command+=" --header='${header}'"
        done
        full_command="${command} ${HEALTHCHECK_URL} -T 10 -t 5 -O /dev/null"
        eval "${full_command}" || (echo "Error occurred when trying to perform healthcheck."; exit 1)
    else
        wget ${HEALTHCHECK_URL} -T 10 -t 5 -O /dev/null || (echo "Error occurred when trying to perform healthcheck."; exit 1)
    fi
    echo "Successfully performed healthcheck"
fi

if [ -n "$POST_BACKUP_COMMANDS" ]; then
    echo "Executing post-backup commands"
    IFS='|' read -ra POST_COMMANDS <<< "${POST_BACKUP_COMMANDS}"
    for command in "${POST_COMMANDS[@]}"; do
      echo "Executing '${command}'"
      eval "${command}"
      exit_status=$?
      if [ $exit_status -eq 0 ]; then
          echo "Command executed successfully."
      else
          echo "Error executing command. Exit status: $exit_status"
      fi
    done
fi

echo "------------------------------------------------------------------------------------------"
