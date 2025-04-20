#!/bin/bash

set -e

if [ ! -n "$CRON" ] || [ ! -n "$RCLONE_REMOTE_NAME" ] || [ ! -n "$RCLONE_REMOTE_LOCATION" ] || [ ! -n "$RESTIC_PASSWORD" ]; then
    echo -e "\e[31mOne or more required variables are not set. Exiting...\e[0m"
    exit 1
fi

echo "---------------------------------------------------------------------------"
echo -e "TZ: ${TZ}\\n\
CRON: ${CRON}"

if [ -n "$RESTIC_BACKUP_ARGS" ]; then
  echo -e "RESTIC_BACKUP_ARGS: ${RESTIC_BACKUP_ARGS}"
fi

if [ -n "$RESTIC_FORGET_ARGS" ]; then
  echo -e "RESTIC_FORGET_ARGS: ${RESTIC_FORGET_ARGS}"
fi

echo -e "RCLONE_REMOTE_NAME: ${RCLONE_REMOTE_NAME}\\n\
RCLONE_REMOTE_LOCATION: ${RCLONE_REMOTE_LOCATION}\\n\
RCLONE_CONFIG_LOCATION: ${RCLONE_CONFIG_LOCATION:-/config/rclone/rclone.conf}"

if [ -n "$RCLONE_SERVE_ARGS" ]; then
  echo -e "RCLONE_SERVE_ARGS: ${RCLONE_SERVE_ARGS}"
fi

if [ "${NOTIFICATIONS:-false}" = true ]; then
    if [ -n "$APPRISE_BACKUP_ARGS" ]; then
        echo "NOTIFICATIONS: ${NOTIFICATIONS}"
        echo "APPRISE_BACKUP_ARGS: ${APPRISE_BACKUP_ARGS}"
    else
        echo -e "\e[33mNOTIFICATIONS are enabled, but APPRISE_BACKUP_ARGS is not set. You will not receive backup notifications.\e[0m"
    fi
fi

if [ "${NOTIFICATIONS:-false}" = true ]; then
    if [ -n "$APPRISE_FORGET_ARGS" ]; then
        echo "APPRISE_FORGET_ARGS: ${APPRISE_FORGET_ARGS}"
    else
        echo -e "\e[33mNOTIFICATIONS are enabled, but APPRISE_FORGET_ARGS is not set. You will not receive forget notifications.\e[0m"
    fi
fi

if [ -n "$HEALTHCHECK_URL" ]; then
    echo -e "HEALTHCHECK_URL: ${HEALTHCHECK_URL}"
    if [ -n "${HEALTHCHECK_HEADERS}" ]; then
        echo "HEALTHCHECK_HEADERS: ${HEALTHCHECK_HEADERS}"
    fi
fi

if [ -n "$PRE_BACKUP_COMMANDS" ]; then
    echo -e "PRE_BACKUP_COMMANDS: ${PRE_BACKUP_COMMANDS}"
fi

if [ -n "$POST_BACKUP_COMMANDS" ]; then
    echo -e "POST_BACKUP_COMMANDS: ${POST_BACKUP_COMMANDS}"
fi

echo "---------------------------------------------------------------------------"

echo -e "${CRON} /usr/local/bin/restic.sh >> /logs/restic.log 2>&1\n" > /tmp/cron
echo -e "0 0 * * * /usr/sbin/logrotate --force --verbose /etc/logrotate.conf\n"  >> /tmp/cron

nohup supercronic /tmp/cron >> /logs/cron.log 2>&1 &

echo -e "\e[32mStarting rclone restic serve on 127.0.0.1:8080\e[0m"
rclone serve restic ${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_LOCATION} --log-file /logs/rclone.log --config=${RCLONE_CONFIG_LOCATION:-/config/rclone/rclone.conf} ${RCLONE_SERVE_ARGS:-}
