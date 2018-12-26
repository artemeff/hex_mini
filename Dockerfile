FROM alpine:edge AS builder

WORKDIR /tmp

RUN apk add git elixir erlang-runtime-tools \
 && mix local.rebar --force \
 && mix local.hex --force

# copy source code into the build container
COPY . .

# assemble release to /tmp/built
RUN export APP_NAME=hex_mini \
 && export APP_VERSION=$(grep 'version:' mix.exs | cut -d '"' -f2) \
 && export MIX_ENV=prod \
 && mix do deps.get, clean, compile \
 && mkdir -p /tmp/built \
 && mix release --verbose \
 && cp _build/${MIX_ENV}/rel/${APP_NAME}/releases/${APP_VERSION}/${APP_NAME}.tar.gz /tmp/built \
 && cd /tmp/built \
 && tar -xzf ${APP_NAME}.tar.gz \
 && rm ${APP_NAME}.tar.gz

# release docker image
FROM alpine:edge

RUN apk add bash libcrypto1.1 \
 && mkdir -p /etc/hex_mini \
 && mkdir -p /var/lib/hex_mini

ENV REPLACE_OS_VARS=true

WORKDIR /app

COPY --from=builder /tmp/built .

EXPOSE 4000

CMD trap 'exit' INT; /app/bin/hex_mini foreground
