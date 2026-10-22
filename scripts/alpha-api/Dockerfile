# syntax=docker/dockerfile:1
# knk-alpha API deployment build (KNG-227, runbook Phase 3b). Context layout:
#   source/ (git archive of knk-web-api), docker-entrypoint.sh, migrator-entrypoint.sh, .dockerignore
# Targets: runtime (default, last stage) and migrator (one-off "dotnet ef database update").

ARG SOURCE_REVISION
ARG SOURCE_ARCHIVE_SHA256
ARG BUILD_DATE
ARG KNK_RUNTIME_UID=2002
ARG KNK_RUNTIME_GID=2002

FROM mcr.microsoft.com/dotnet/sdk:8.0-bookworm-slim@sha256:ec9c0a0dc5f60adc2065762050638dd5ed5facfc53716d4580a42d86027c8e80 AS build

WORKDIR /src

COPY source/knkwebapi_v2.csproj ./
RUN dotnet restore ./knkwebapi_v2.csproj

COPY source/ ./
RUN dotnet publish ./knkwebapi_v2.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish \
    /p:UseAppHost=false

FROM build AS migrator

ARG SOURCE_REVISION
ARG SOURCE_ARCHIVE_SHA256
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Knights & Kings Web API migrator" \
      org.opencontainers.image.version="alpha-${SOURCE_REVISION}" \
      org.opencontainers.image.revision="${SOURCE_REVISION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/PandiO/knk-web-api" \
      net.knightsandkings.source-archive.sha256="${SOURCE_ARCHIVE_SHA256}" \
      net.knightsandkings.base.sdk="mcr.microsoft.com/dotnet/sdk@sha256:ec9c0a0dc5f60adc2065762050638dd5ed5facfc53716d4580a42d86027c8e80"

# dotnet-ef matches Microsoft.EntityFrameworkCore.Design 9.0.10 in the csproj.
RUN dotnet tool install --tool-path /opt/dotnet-tools dotnet-ef --version 9.0.10 \
    && dotnet build ./knkwebapi_v2.csproj --configuration Release --no-restore /p:UseAppHost=false

COPY migrator-entrypoint.sh /usr/local/bin/knk-migrator-entrypoint
RUN chmod 0555 /usr/local/bin/knk-migrator-entrypoint

ENV PATH="${PATH}:/opt/dotnet-tools" \
    ASPNETCORE_ENVIRONMENT=Production \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    DOTNET_CLI_HOME=/tmp \
    HOME=/tmp

ENTRYPOINT ["/usr/local/bin/knk-migrator-entrypoint"]

FROM mcr.microsoft.com/dotnet/aspnet:8.0-bookworm-slim@sha256:a3cd573ac05cf88ca496e3309cb7f7c44aa16664352d1ee41eda93154f50cdbf AS runtime

ARG SOURCE_REVISION
ARG SOURCE_ARCHIVE_SHA256
ARG BUILD_DATE
ARG KNK_RUNTIME_UID
ARG KNK_RUNTIME_GID

LABEL org.opencontainers.image.title="Knights & Kings Web API" \
      org.opencontainers.image.version="alpha-${SOURCE_REVISION}" \
      org.opencontainers.image.revision="${SOURCE_REVISION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/PandiO/knk-web-api" \
      net.knightsandkings.source-archive.sha256="${SOURCE_ARCHIVE_SHA256}" \
      net.knightsandkings.base.sdk="mcr.microsoft.com/dotnet/sdk@sha256:ec9c0a0dc5f60adc2065762050638dd5ed5facfc53716d4580a42d86027c8e80" \
      net.knightsandkings.base.aspnet="mcr.microsoft.com/dotnet/aspnet@sha256:a3cd573ac05cf88ca496e3309cb7f7c44aa16664352d1ee41eda93154f50cdbf"

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/publish/ ./
COPY docker-entrypoint.sh /usr/local/bin/knk-api-entrypoint

RUN chmod 0555 /usr/local/bin/knk-api-entrypoint

ENV ASPNETCORE_URLS=http://+:5000 \
    ASPNETCORE_ENVIRONMENT=Production \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    HOME=/tmp

EXPOSE 5000

USER ${KNK_RUNTIME_UID}:${KNK_RUNTIME_GID}

HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=6 \
    CMD curl --fail --silent --show-error http://127.0.0.1:5000/health/ready >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/knk-api-entrypoint"]
