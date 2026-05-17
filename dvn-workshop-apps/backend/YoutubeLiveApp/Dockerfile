# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS builder

WORKDIR /app

ARG TARGETARCH
RUN ARCH=$(case ${TARGETARCH} in arm64) echo "linux-musl-arm64" ;; *) echo "linux-musl-x64" ;; esac) \
    && echo "${ARCH}" > /tmp/rid

COPY *.csproj ./
RUN dotnet restore -r "$(cat /tmp/rid)"

COPY . .
RUN dotnet publish -c Release -o /app/publish \
    --no-restore \
    -p:PublishSingleFile=true \
    -p:PublishTrimmed=true \
    --self-contained true \
    -r "$(cat /tmp/rid)"

# Stage 2: Runtime
FROM alpine:3.20 AS runtime

LABEL org.opencontainers.image.source="https://github.com/workshop/youtube-live-app"
LABEL org.opencontainers.image.description="YoutubeLiveApp backend API"

RUN apk add --no-cache \
    libstdc++ \
    libgcc \
    icu-libs \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder --chown=appuser:appgroup /app/publish/YoutubeLiveApp ./YoutubeLiveApp

USER appuser

ENV ASPNETCORE_URLS=http://+:8080 \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/backend/health || exit 1

CMD ["./YoutubeLiveApp"]
