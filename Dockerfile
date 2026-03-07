FROM node:22-bookworm-slim

USER root

ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV npm_config_cache=/home/node/.npm
ENV PATH=/home/node/.npm-global/bin:${PATH}

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      chromium \
      curl \
      ffmpeg \
      git \
      python3 \
      python3-pip \
      xvfb; \
    mkdir -p /home/node/.npm-global /home/node/.npm /home/node/.cache /home/node/.local/share; \
    chown -R node:node /home/node; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

USER node
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["openclaw", "gateway", "--allow-unconfigured"]
