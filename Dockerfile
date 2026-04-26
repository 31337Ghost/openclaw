ARG OPENCLAW_VERSION=latest
FROM ghcr.io/openclaw/openclaw:${OPENCLAW_VERSION}

USER root

ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PIPX_HOME=/home/node/.openclaw/.pipx
ENV PIPX_BIN_DIR=/home/node/.openclaw/.pipx/bin
ENV XDG_CONFIG_HOME=/home/node/.openclaw/.config
ENV PATH=/home/node/.npm-global/bin:/home/node/.openclaw/.pipx/bin:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    ffmpeg \
    jq \
    openssh-client \
    pipx \
    python3 \
    python3-venv \
    python3-pip \
    ripgrep \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/node/.npm-global \
    && chown -R node:node /home/node/.npm-global

COPY docker/openclaw-restart.sh /usr/local/bin/openclaw-restart
RUN chmod 755 /usr/local/bin/openclaw-restart

RUN curl -fsSL https://github.com/steipete/gogcli/releases/download/v0.12.0/gogcli_0.12.0_linux_arm64.tar.gz \
    | tar -xz -C /usr/local/bin gog \
    && chmod 755 /usr/local/bin/gog

RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

USER node
RUN npm_config_cache=/tmp/npm-build-cache npm install -g clawhub @steipete/summarize mcporter \
    && rm -rf /tmp/npm-build-cache

CMD ["node", "dist/index.js", "gateway", "--allow-unconfigured"]
