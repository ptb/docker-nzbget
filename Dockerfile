FROM alpine:3.2
# MAINTAINER Peter T Bosse II <ptb@ioutime.com>

RUN adduser -D -G users -g NZBGet -s /bin/nologin -u 1026 nzbget \

  && apk add --update-cache \
    wget \

  && wget \
    --output-document - \
    --quiet \
    http://nzbget.net/info/nzbget-version-linux.json \
    | sed -n "s/^.*stable-download.*: \"\(.*\)\".*/\1/p" \
    | wget \
      --input-file - \
      --no-check-certificate \
      --output-document /tmp/nzbget-stable.sh \
      --quiet \
  && sh /tmp/nzbget-stable.sh --destdir /home/nzbget \
  && chown -R nzbget:users /home/nzbget/ \
  && rm -rf /tmp/nzbget-stable.sh \

  && wget \
    --no-check-certificate \
    --output-document - \
    --quiet \
    https://api.github.com/repos/just-containers/s6-overlay/releases/latest \
    | sed -n "s/^.*browser_download_url.*: \"\(.*s6-overlay-amd64.tar.gz\)\".*/\1/p" \
    | wget \
      --input-file - \
      --no-check-certificate \
      --output-document - \
      --quiet \
    | tar xz -C / \

  && mkdir -p /etc/services.d/nzbget/ \
  && printf "%s\n" \
    "#!/usr/bin/env sh" \
    "set -ex" \
    "exec s6-applyuidgid -g 100 -u 1026 /home/nzbget/nzbget -o outputmode=log -s" \
    > /etc/services.d/nzbget/run \
  && chmod +x /etc/services.d/nzbget/run \

  && apk del \
    wget \
  && rm -rf /tmp/* /var/cache/apk/*

ENTRYPOINT ["/init"]
EXPOSE 6789 6791

# docker build --rm --tag ptb2/nzbget .
# docker run --detach --name nzbget --net host \
#   --publish 6789:6789/tcp \
#   --publish 6791:6791/tcp \
#   --volume /volume1/@appstore/NZBGet/nzbget.conf:/home/nzbget/nzbget.conf \
#   --volume=/volume1/Incoming:/home/incoming \
#   --volume=/volume1/Media:/home/media \
#   ptb2/nzbget

# http://0.0.0.0:6789/
# username: nzbget
# password: tegbzn6789
