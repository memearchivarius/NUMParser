# syntax=docker/dockerfile:1.7

############################
# Builder
############################
FROM golang:1.24-bookworm AS builder

WORKDIR /src

# Enable module mode and caching
ENV CGO_ENABLED=0 \
    GO111MODULE=on

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .

# Build static binary
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -trimpath -ldflags "-s -w" -o /out/numparser ./cmd


############################
# Runtime
############################
FROM alpine:3.20 AS runtime

RUN apk add --no-cache ca-certificates tzdata bash

ENV APP_USER=app \
    APP_GROUP=app

RUN addgroup -S "$APP_GROUP" && adduser -S "$APP_USER" -G "$APP_GROUP"

WORKDIR /app

# App layout:
#  - /app/numparser          (binary)
#  - /app/public             (web assets + releases output)
#  - /app/db                 (bolt db)
#  - /app/*.sh, /app/tmdb.key

COPY --from=builder /out/numparser /app/numparser
COPY public/ /app/public/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/copy.sh /app/copy.sh
COPY docker/proxy.sh /app/proxy.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /app/copy.sh /app/proxy.sh \
    && mkdir -p /app/db /app/public/releases \
    && chown -R "$APP_USER:$APP_GROUP" /app

USER $APP_USER

VOLUME ["/app"]

EXPOSE 38888

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]


