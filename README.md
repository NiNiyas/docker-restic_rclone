# Docker Restic_Rclone
Forked from [jasonccox/restic-rclone-docker](https://github.com/jasonccox/restic-rclone-docker) \
Available on Docker hub as [niniyas/restic-rclone](https://hub.docker.com/r/niniyas/restic-rclone).

## Features
- Support for PUID and PGID variables.
- Uses alpine:latest image.
- Uses S6 overlay.
- Timezone support.
- Healthchecks.io support.
- Customizable cron interval.
- Automatically rotates log for rclone and restic.
- Notification support through [apprise](https://github.com/caronc/apprise) which can send notifications to almost every service.

## Supported Architectures

| Architecture | Tag   |
|--------------|-------|
| x86-64       | amd64 |
| arm64        | arm64 |
| armhf        | armhf |

# Usage
## docker run
```
docker run -d --name Restic_Backup -e PUID=1000 -e PGID=1000 -e CRON=0 2 * * * -e TZ=Europe/Brussels -e RESTIC_PASSWORD=supersecret -e RESTIC_REPOSITORY=rest:http://0.0.0.0:8080/ -v /path/to/host/config:/config -v /path/to/backup:/data ghcr.io/niniyas/restic-rclone:amd64 | arm64 | armhf
```

## docker-compose (recommended)
```
version: "3.9"
services:
  restic:
    container_name: Restic_Backup
    #build:                                       #
    #  context: .                                 #
    #  dockerfile: Dockerfile | Dockerfile.armhf  # If you want to build for amd64 and arm64 | Builds for arhmf
    #  args:                                      #
    #      ARCH=amd64                             # 
    #      OVERLAY_ARCH=amd64                     #
    #      RCLONE_ARCH=arm-v7                     # Only if you want to build for armv7
    image: ghcr.io/niniyas/restic-rclone:amd64 | arm64 | armhf
    environment:
      - PUID=1000
      - PGID=1000
      - CRON=0 2 * * *
      - TINI_VERBOSITY=0
      - TZ=Europe/Brussels
      - NOTIFICATIONS=true
      - APPRISE_TITLE=Restic
      - RCLONE_SERVE_ARGS=-vvv
      - RESTIC_PASSWORD=supersecret
      - RCLONE_REMOTE_NAME=RemoteName
      - RCLONE_REMOTE_LOCATION=Backups
      - RESTIC_FORGET_ARGS=--keep-last 2 --prune
      - HEALTHCHECKS_HEADER_KEY=Proxy-Authorization
      - RESTIC_REPOSITORY=rest:http://0.0.0.0:8080/
      - RCLONE_CONFIG_LOCATION=/config/rclone/rclone.conf
      - HEALTHCHECKS_HEADER_VALUE=Basic asjbfaofbasdofnasfoianhsd
      - HEALTHCHECK=https://healthchecks.io/ping/abcde-fghijk-lmnopqrstuvwxyz
      - RESTIC_BACKUP_ARGS=--exclude /data/.cache --exclude /data/node_modules
      - APPRISE_BACKUP_ARGS=discord://1234567891000/hWPpxwdshdfhdfh3uf9NqBdasdasdasddsfhgdfh5iHWxZDxtUes0Mm/?format=markdown&avatar=No
      - APPRISE_FORGET_ARGS=discord://1234567891000/hWPpxwdshdfhdfh3uf9NqBdasdasdasddsfhgdfh5iHWxZDxtUes0Mm/?format=markdown&avatar=No
    volumes:
      - .resticconfig:/config # Optional. Required to see the logs.
      - /home/odin/:/data # Required. This is the backup directory.
      - /home/odin/.config/rclone/rclone.conf:/config/rclone/rclone.conf # Only if you are using rclone.
```

## Variables
- PUID
  - User ID. Optional.
- PGID
  - Group ID. Optional.
- TZ
  - Timezone. View available values [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). Default is `Europe/Brussels`.
- CRON
  - Use [crontab.guru](https://crontab.guru). Required. No defaults.
- TINI_VERBOSITY
  - Supress tini logs. Optional.
- RESTIC_PASSWORD
  - Password for restic repo. Required.
- RESTIC_REPOSITORY
  - restic repository location. Required. Use `rest:http://0.0.0.0:8080/` if you are using rclone as a repo.
- RCLONE_REMOTE_NAME
  - rclone remote name as given in config. Required if you are using rclone as `RESTIC_REPOSITORY`.
- RCLONE_REMOTE_LOCATION
  - rclone remote location. Required if you are using `RCLONE_REMOTE_NAME` .
- RCLONE_CONFIG_LOCATION
  - rclone config location. Optional. Default is `/config/rclone/rclone.conf`.
- RCLONE_SERVE_ARGS
  - See [here](https://rclone.org/commands/rclone_serve_restic/#options) for more info. Optional. No defaults.
- RESTIC_BACKUP_ARGS
  - restic arguments to use when backing up. See [here](https://restic.readthedocs.io/en/stable/) for more info. Optional. No defaults.
- RESTIC_FORGET_ARGS
  - See [here](https://restic.readthedocs.io/en/stable/060_forget.html) for more info. Optional. No defaults.
- NOTIFICATIONS
  - `true` or `false`. Optional. Default is `false`.
- APPRISE_BACKUP_ARGS
  - Required if `NOTIFICATIONS` is set to `true`. If using one or more endpoints, use space to seperate. See [here](https://github.com/caronc/apprise/wiki) for more info.
- APPRISE_FORGET_ARGS
  - Required if you need to get notifications about restic forget command. If using one or more endpoints, use space to seperate. Optional. No defaults.
- APPRISE_TITLE
  - Default is `Restic Backup`. Optional.
- HEALTHCHECK
  - healthchecks.io url. See [here](https://healthchecks.io/) for more info. Optional. No defaults.
- HEALTHCHECKS_HEADER_KEY
  - Header key to be used when performing healthchecks. Optional. No defaults.
- HEALTHCHECKS_HEADER_VALUE
  - Header value to be used when performing healthchecks. Optional. No defaults.

## Volume Mounts
- /config
  - rclone and restic logs.
- /data
  - Backup directory

## Files
- /config/rclone/log/restic-rclone.log
  - rclone log.
- /config/restic/restic-cron.log
  - restic log.
