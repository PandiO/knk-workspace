# knk-alpha cfproxy (Phase 9, KNG-216): a forward proxy that lets the API reach api.cloudflare.com:443 and nothing
# else. Build context: this directory.
#   docker build -t knk-cfproxy:alpha-<n> --build-arg BUILD_DATE=... .
FROM alpine:3.22@sha256:2e0b81d60597f449baa56dc25d355367869d2dca4cd57e866f1e2b52af3eb55f
ARG BUILD_DATE=unknown
RUN apk add --no-cache tinyproxy \
 && tinyproxy -v
COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf
COPY filter /etc/tinyproxy/filter
RUN chmod 0444 /etc/tinyproxy/tinyproxy.conf /etc/tinyproxy/filter
LABEL org.opencontainers.image.title="knk-cfproxy" \
      org.opencontainers.image.created="${BUILD_DATE}"
USER 2004:2004
EXPOSE 8888
# -d: stay in the foreground; logs go to stdout.
ENTRYPOINT ["tinyproxy", "-d", "-c", "/etc/tinyproxy/tinyproxy.conf"]
