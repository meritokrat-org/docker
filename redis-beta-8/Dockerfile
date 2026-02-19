FROM ubuntu

RUN apt-get update -qq \
 && apt-get install -qq --yes --no-install-recommends \
    build-essential

ADD https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/redis/redis-beta-8.tar.gz /tmp/redis-beta-8.tar.gz
RUN mkdir -p /usr/lib/redis \
 && tar -xzvf /tmp/redis-beta-8.tar.gz -C /usr/lib/redis --strip 1 \
 && cd /usr/lib/redis \
 && make \
 && cp redis.conf /etc/redis.conf \
 && cd ../../bin \
 && ln -s ../lib/redis/redis-server redis-server

EXPOSE 6379
WORKDIR /usr/lib/redis

CMD ["redis-server", "/etc/redis.conf"]

