FROM alpine:3.21

WORKDIR /usr/src/app

ARG OVERLAY_ARCH
ARG RESTIC_ARCH
ARG OVERLAY_VERSION=3.2.0.2
ARG RESTIC_VERSION=0.18.0

ENV CONFIG_DIR="/config" \
    PUID="1000" \
    PGID="1000" \
    UMASK="002" \
    TZ=Europe/Brussels \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0

RUN apk update && \
    apk add --no-cache tzdata python3 py3-pip logrotate shadow bash wget findutils xz curl unzip supercronic && \
    wget -q -O - https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_${RESTIC_ARCH}.bz2 | bzip2 -d -c > /bin/restic && \
    chmod +x /bin/restic && \
    curl https://rclone.org/install.sh | bash && \
    rclone version && \
    restic version && \
    pip install --upgrade --no-cache-dir --break-system-packages pip apprise

RUN curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${OVERLAY_VERSION}/s6-overlay-noarch.tar.xz | tar Jpxf - -C / && \
    curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.xz | tar Jpxf - -C / && \
    curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz  | tar Jpxf - -C / && \
    curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz | tar Jpxf - -C /

COPY /root /

RUN chmod +x /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/restic.sh && \
    cp /opt/rclone /etc/logrotate.d/rclone && \
    cp /opt/restic /etc/logrotate.d/restic

RUN useradd -u 1000 -U -d "${CONFIG_DIR}" -s /bin/false restic && \
    usermod -G users restic

VOLUME [ "/config", "/data", "/logs" ]

LABEL org.opencontainers.image.source="https://github.com/NiNiyas/docker-restic_rclone"
LABEL org.opencontainers.image.licenses="GPL-3.0-or-later"

ENTRYPOINT ["/init"]
