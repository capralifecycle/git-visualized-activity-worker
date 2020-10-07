FROM alpine:3.12@sha256:a15790640a6690aa1730c38cf0a440e2aa44aaca9b0e8931a9f2b0d7cc90fd65

RUN set -eux; \
    apk add --no-cache \
      bash \
      g++ \
      git \
      libsecret-dev \
      make \
      npm \
      perl \
      pkgconfig \
      py3-pip \
      python3 \
    ; \
    pip3 install awscli; \
    npm config --global set unsafe-perm true; \
    git config --global credential.helper cache; \
    mkdir /app

ENV DATA_DIR /data
COPY * /app/

WORKDIR /app

# renovate: datasource=npm depName=@capraconsulting/cals-cli
ENV CALS_CLI_VERSION=2.9.4

RUN npm install -g @capraconsulting/cals-cli@${CALS_CLI_VERSION}

CMD ["/app/main.sh"]
