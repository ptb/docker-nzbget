FROM alpine:3.2
# MAINTAINER Peter T Bosse II <ptb@ioutime.com>

RUN \
  BUILD_PACKAGES="ca-certificates openssl wget" \

  && USERID_ON_HOST=1026 \

  && adduser -D -G users -g NZBGet -s /sbin/nologin -u $USERID_ON_HOST nzbget \

  && apk add --update-cache \
    $BUILD_PACKAGES \

  && mkdir -p /app/ \
  && wget \
    --output-document - \
    --quiet \
    http://nzbget.net/info/nzbget-version-linux.json \
    | sed -n "s/^.*stable-download.*: \"\(.*\)\".*/\1/p" \
    | wget \
      --input-file - \
      --output-document /tmp/nzbget-stable.sh \
      --quiet \
  && sh /tmp/nzbget-stable.sh --destdir /app/nzbget \
  && chown -R nzbget:users /app/nzbget/ \

  && wget \
    --output-document - \
    --quiet \
    https://api.github.com/repos/just-containers/s6-overlay/releases/latest \
    | sed -n "s/^.*browser_download_url.*: \"\(.*s6-overlay-amd64.tar.gz\)\".*/\1/p" \
    | wget \
      --input-file - \
      --output-document - \
      --quiet \
    | tar xz -C / \

  && mkdir -p /etc/services.d/nzbget/ \
  && printf "%s\n" \
    "#!/usr/bin/env sh" \
    "set -ex" \
    "exec s6-applyuidgid -g 100 -u $USERID_ON_HOST \\" \
    "  /app/nzbget/nzbget \\" \
    "  -c /home/nzbget/nzbget.conf \\" \
    "  -o outputmode=log -s" \
    > /etc/services.d/nzbget/run \
  && chmod +x /etc/services.d/nzbget/run \

  && apk del \
    $BUILD_PACKAGES \
  && rm -rf /tmp/* /var/cache/apk/* /var/tmp/*

ENTRYPOINT ["/init"]
EXPOSE 6789 6791

# docker build --rm --tag ptb2/nzbget .
# docker run --detach --name nzbget --net host \
#   --publish 6789:6789/tcp \
#   --publish 6791:6791/tcp \
#   --volume /volume1/Config/NZBGet/nzbget.conf:/home/nzbget/nzbget.conf \
#   --volume=/volume1/Media:/home/media \
#   --volume=/volume1/Media/Downloads:/home/nzbget/downloads \
#   ptb2/nzbget

# http://0.0.0.0:6789/
# username: nzbget
# password: tegbzn6789
