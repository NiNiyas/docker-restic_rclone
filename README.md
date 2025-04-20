# restic-rclone

Minimal docker image for running scheduled backups using restic with rclone as the backend.

Based on [jasonccox/restic-rclone-docker](https://github.com/jasonccox/restic-rclone-docker)

## Setup

### Supported Architectures

Simply pulling `ghcr.io/niniyas/restic-rclone:latest` should retrieve the correct image for your arch, but you can
also pull specific arch images via tags.

| Architecture | Tag   |
|--------------|-------|
| amd64        | amd64 |
| arm64        | arm64 |

### Docker Compose (recommended)

```
version: "3.9"
services:
  restic:
    container_name: Restic
    image: ghcr.io/niniyas/restic-rclone:latest
    environment:
      - PUID=1000
      - PGID=1000
      - CRON=0 2 * * *
      - TZ=Europe/Brussels
      - ...
    volumes:
      - .logs:/logs # Optional. Required to see the logs.
      - .data:/data # Required. This is the backup directory.
      - .rclone/rclone.conf:/config/rclone/rclone.conf
```

### Docker CLI

```shell
docker run -d \
    --name=Restic \
    -e PUID=1000 \
    -e PGID=1000 \
    -e UMASK=002 \
    -e .... \
    -v .data:/data \
    -v ....
    ghcr.io/niniyas/restic-rclone:latest
```

### Available environment variables

- PUID
    - User ID. Optional.
- PGID
    - Group ID. Optional.
- TZ
    - Timezone. View available values [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). Default is
      `Europe/Brussels`.
- CRON
    - Use [crontab.guru](https://crontab.guru). Required. No defaults.
- RESTIC_PASSWORD
    - Password for restic repo. Required.
- RESTIC_REPOSITORY
    - restic repository location. Default `rest:http://0.0.0.0:8080/`.
- RCLONE_REMOTE_NAME
    - rclone remote name as given in config. Required if you are using rclone as `RESTIC_REPOSITORY`.
- RCLONE_REMOTE_LOCATION
    - rclone remote location. Required if you are using `RCLONE_REMOTE_NAME` .
- RCLONE_CONFIG_LOCATION
    - rclone config location. Optional. Default is `/config/rclone/rclone.conf`.
- RCLONE_SERVE_ARGS
    - See [here](https://rclone.org/commands/rclone_serve_restic/#options) for more info. Optional. No defaults.
- RESTIC_BACKUP_ARGS
    - restic arguments to use when backing up. See [here](https://restic.readthedocs.io/en/stable/) for more info.
      Optional. No defaults.
- RESTIC_FORGET_ARGS
    - See [here](https://restic.readthedocs.io/en/stable/060_forget.html) for more info. Optional. No defaults.
- NOTIFICATIONS
    - `true` or `false`. Optional. Default is `false`.
- APPRISE_BACKUP_ARGS
    - Required if `NOTIFICATIONS` is set to `true`. If using one or more endpoints, use space to separate.
      See [here](https://github.com/caronc/apprise/wiki) for more info.
- APPRISE_FORGET_ARGS
    - Required if you need to get notifications about restic forget command. If using one or more endpoints, use space
      to separate. Optional. No defaults.
- APPRISE_TITLE
    - Default is `Restic Backup`. Optional.
- HEALTHCHECK_URL
    - healthchecks.io url. See [here](https://healthchecks.io/) for more info. Optional. No defaults.
- HEALTHCHECK_HEADERS
    - Headers to be used while performing healthcheck. Optional. No defaults. Use `|` to separate multiple headers.
        - Example: Key1:Value1|Key2:Value2
- PRE_BACKUP_COMMANDS
    - Commands to run before backup. Optional. No defaults. Use `|` to separate multiple commands.
- POST_BACKUP_COMMANDS
    - Commands to run after backup. Optional. No defaults. Use `|` to separate multiple commands.
