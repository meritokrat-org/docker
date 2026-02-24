FROM alpine:latest
#FROM alpine:3.18

RUN apk add --no-cache \
    bash jq pv \
    nodejs npm yarn \
    postgresql-client mysql-client \
    ca-certificates \
    curl wget \
    gzip unzip \
 && update-ca-certificates

ADD --chmod=0755 https://dl.min.io/client/mc/release/linux-amd64/mc /usr/local/bin/mc

WORKDIR /app

COPY . .
COPY --chmod=0755 *.sh .
COPY --chmod=0755 backupper.sh /usr/local/bin/backupper

ENV SHELL=/bin/bash
RUN touch ~/.bashrc \
 && mc --autocompletion bash

ENTRYPOINT ["/app/entrypoint.sh"]
