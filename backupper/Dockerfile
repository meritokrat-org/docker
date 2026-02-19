FROM alpine:latest
#FROM alpine:3.18

RUN apk add --no-cache \
    bash jq \
    nodejs npm yarn \
    postgresql-client mysql-client \
    ca-certificates \
    curl wget rclone \
    p7zip unzip \
 && update-ca-certificates

WORKDIR /app

COPY rclone.conf /root/.config/rclone/rclone.conf
COPY --chmod=0755 backupper.sh /usr/local/bin/backupper

ENTRYPOINT ["backupper"]
