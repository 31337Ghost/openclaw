ARG OPENCLAW_VERSION=latest
FROM ghcr.io/openclaw/openclaw:${OPENCLAW_VERSION}

USER root

ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV npm_config_cache=/home/node/.npm
ENV PATH=/home/node/.npm-global/bin:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    ffmpeg \
    jq \
    openssh-client \
    python3 \
    python3-venv \
    python3-pip \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/node/.npm-global /home/node/.npm \
    && chown -R node:node /home/node/.npm-global /home/node/.npm

COPY docker/openclaw-restart.sh /usr/local/bin/openclaw-restart
RUN chmod 755 /usr/local/bin/openclaw-restart

RUN curl -fsSL https://github.com/steipete/gogcli/releases/download/v0.12.0/gogcli_0.12.0_linux_arm64.tar.gz \
    | tar -xz -C /usr/local/bin gog \
    && chmod 755 /usr/local/bin/gog

USER node
RUN npm install -g @openai/codex @anthropic-ai/claude-code clawhub @steipete/summarize

CMD ["node", "dist/index.js", "gateway", "--allow-unconfigured"]
