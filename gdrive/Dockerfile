FROM alpine:3.18

RUN apk add --no-cache bash curl

# Встановлюємо gdrive
RUN curl -L https://github.com/glotlabs/gdrive/releases/latest/download/gdrive_linux-x64.tar.gz \
    | tar -xz -C /usr/local/bin

ENTRYPOINT ["gdrive"]