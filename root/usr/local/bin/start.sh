#!/bin/sh

set -e

echo "---------------------------------------------------------------------------"
echo -e "Variables set:\\n\
TZ: ${TZ}\\n\
CRON: ${CRON}"

if [ -n "$RESTIC_BACKUP_ARGS" ]; then
  echo -e "RESTIC_BACKUP_ARGS: ${RESTIC_BACKUP_ARGS}"
fi

if [ -n "$RESTIC_FORGET_ARGS" ]; then
  echo -e "RESTIC_FORGET_ARGS: ${RESTIC_FORGET_ARGS}"
fi

if [ -n "$RCLONE_REMOTE_NAME" ]; then
  if [ -n "$RCLONE_REMOTE_LOCATION" ]; then
    echo -e "RCLONE_REMOTE_NAME: ${RCLONE_REMOTE_NAME}\\n\
RCLONE_REMOTE_LOCATION: ${RCLONE_REMOTE_LOCATION}\\n\
RCLONE_CONFIG_LOCATION: ${RCLONE_CONFIG_LOCATION:-/config/rclone/rclone.conf}"
  fi
fi

if [ -n "$RCLONE_SERVE_ARGS" ]; then
  echo -e "RCLONE_SERVE_ARGS: ${RCLONE_SERVE_ARGS}"
fi

if [ "${NOTIFICATIONS:-false}" = true ]; then
    if [ -n "$APPRISE_BACKUP_ARGS" ]; then
        echo "NOTIFICATIONS: ${NOTIFICATIONS}"
        echo "APPRISE_BACKUP_ARGS: ${APPRISE_BACKUP_ARGS}"
    else
        echo "NOTIFICATIONS is True, but APPRISE_BACKUP_ARGS is not set. Please check your configuration. Notifications will not work."
    fi
fi

if [ "${NOTIFICATIONS:-false}" = true ]; then
    if [ -n "$APPRISE_FORGET_ARGS" ]; then
        echo "APPRISE_FORGET_ARGS: ${APPRISE_FORGET_ARGS}"
    fi
fi

if [ -n "$HEALTHCHECK" ]; then
    echo -e "HEALTHCHECK: ${HEALTHCHECK}"
    if [ "${HEALTHCHECKS_HEADER_KEY:-}" ]; then
      if [ -n "${HEALTHCHECKS_HEADER_VALUE}" ]; then
        echo "HEALTHCHECKS_HEADER_KEY: ${HEALTHCHECKS_HEADER_KEY}"
        echo "HEALTHCHECKS_HEADER_VALUE: ${HEALTHCHECKS_HEADER_VALUE}"
    else
        echo "HEALTHCHECKS_HEADER_KEY is True, but HEALTHCHECKS_HEADER_VALUE is not set. Please check your configuration. Healthcheck will not work."
      fi
    fi
fi
echo "---------------------------------------------------------------------------"
# create necessary config dirs
mkdir -p /logs/rclone
mkdir -p /logs/restic

# create an empty restic-rclone.log file
[ -f /logs/rclone/restic-rclone.log ] || touch /logs/rclone/restic-rclone.log

if [ -n "$CRON" ]; then
  echo -e "${CRON} /usr/local/bin/restic.sh >> /logs/restic/restic.log 2>&1\n" > /var/spool/cron/crontabs/root
  /sbin/tini -s -- /usr/sbin/crond -b
else
  echo CRON variable not set. Exiting...
  exit 1
fi

echo -e "0 0 * * * /usr/sbin/logrotate --force --verbose /etc/logrotate.conf\n"  >> /var/spool/cron/crontabs/root

if [ -n "$RCLONE_REMOTE_NAME" ]; then
  if [ -n "$RCLONE_REMOTE_LOCATION" ]; then
    echo "Starting rclone restic serve on :8080"
    /sbin/tini -s -- rclone serve restic ${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_LOCATION} --addr 0.0.0.0:8080 --log-file /logs/rclone/restic-rclone.log --config=${RCLONE_CONFIG_LOCATION:-/config/rclone/rclone.conf} \
    ${RCLONE_SERVE_ARGS:-}
  else
    echo "RCLONE_REMOTE_NAME is set, but RCLONE_REMOTE_LOCATION is not. Please check your configuration and restart."
    exit 1
  fi
fi
