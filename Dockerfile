FROM node:22-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    dbus-user-session \
    ffmpeg \
    fonts-liberation \
    libatk-bridge2.0-0 \
    libgbm1 \
    libgtk-3-0 \
    libnss3 \
    tini \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER node
ENV HOME=/home/node
ENV TERM=xterm-256color
ENV NPM_CONFIG_CACHE=/home/node/.npm-global/.npm-cache
WORKDIR /home/node

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["gateway", "--bind", "lan", "--port", "18789"]
