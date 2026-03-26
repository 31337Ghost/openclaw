# OpenClaw Container

## Python virtualenv

The image includes `python3`, `python3-pip`, and `python3-venv`, so you can create isolated Python environments in the persisted home volume:

```sh
python3 -m venv /home/node/venvs/myenv
```

## Restart

The gateway container includes a built-in restart command:

```sh
openclaw-restart
```

By default it requests a full container restart by sending a delayed `SIGTERM` to the OpenClaw launcher process. Because the Compose service is configured with `restart: unless-stopped`, Docker starts the container again automatically.

Recommended usage from an agent:

```sh
sh -lc "openclaw-restart"
```

Notes:

- The restart is a full container restart, not a hot reload.
- This does not pull a newer image.
- The helper waits one second before sending the signal.

## Gateway-only restart

OpenClaw documents `SIGUSR1` as the in-process restart signal for a foreground gateway. Use `--gateway` to send that signal directly to `openclaw-gateway` without tearing down the whole container:

```sh
openclaw-restart --gateway
```

Recommended usage from an agent:

```sh
sh -lc "openclaw-restart --gateway"
```

This mode sends `SIGUSR1`, which matches OpenClaw's documented in-process restart signal for the foreground gateway.
