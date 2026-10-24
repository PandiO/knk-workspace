# syntax=docker/dockerfile:1
# knk-alpha web app image (runbook Phase 6). Context layout: source/ (git archive of knk-web-app), nginx.conf,
# .dockerignore. Create React App reads REACT_APP_* at build time, so they are fixed here.

ARG SOURCE_REVISION
ARG SOURCE_ARCHIVE_SHA256
ARG BUILD_DATE

FROM node:24-bookworm-slim@sha256:55fb5f5a527ea2c5c4a95f963e48ef90aa38c7b346054fdc8ee9957a2b55d205 AS build

WORKDIR /src

# CYPRESS_INSTALL_BINARY=0: the e2e test runner isn't needed for a build. No source maps in a public bundle.
ENV CI=false \
    CYPRESS_INSTALL_BINARY=0 \
    GENERATE_SOURCEMAP=false \
    REACT_APP_API_BASE_URL=/api \
    REACT_APP_MC_SERVER_ADDRESS=play.knightsandkings.net

COPY source/package.json source/package-lock.json ./
RUN npm ci --no-audit --no-fund

COPY source/ ./
RUN npm run build

FROM nginxinc/nginx-unprivileged:1.28-alpine@sha256:7377697a821c131a924a7105fafbe7414db4e9fcc77a6f08f776f33f141ec3f8 AS runtime

ARG SOURCE_REVISION
ARG SOURCE_ARCHIVE_SHA256
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Knights & Kings web app" \
      org.opencontainers.image.version="alpha-${SOURCE_REVISION}" \
      org.opencontainers.image.revision="${SOURCE_REVISION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/PandiO/knk-web-app" \
      net.knightsandkings.source-archive.sha256="${SOURCE_ARCHIVE_SHA256}"

COPY --from=build /src/build/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=4 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1
