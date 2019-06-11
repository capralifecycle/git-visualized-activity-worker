FROM alpine:3.9

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
      # Python 2 needed for node-gyp during cals-cli install. No Python 3 support.
      python2 \
      python3 \
    ; \
    pip3 install awscli; \
    npm config --global set unsafe-perm true; \
    git config --global credential.helper cache; \
    mkdir /app

ENV DATA_DIR /data
COPY * /app/

WORKDIR /app
CMD ["/app/main.sh"]
