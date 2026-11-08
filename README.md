# Yolorouter on Railway

Yolorouter — a self-hosted, OpenAI-compatible LLM gateway with multi-provider failover, upstream key pools and a built-in multi-user admin console. Deploy on Railway with one click.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/1sxlrT)

This repository packages the official [Yolorouter](https://github.com/yolorouter/yolorouter) image (`ghcr.io/yolorouter/yolorouter:v0.2.9`, Apache-2.0) for Railway. It is an independent community packaging, not affiliated with or endorsed by the Yolorouter project.

## What you get

- One service from `ghcr.io/onepush-dev/yolorouter:0.2.9`: the upstream image, unmodified, plus a first-boot script (`railway/start.sh`).
- **No setup-screen race.** Upstream's first run asks the first visitor to create the admin. Here the admin account is created over loopback on a private bootstrap port *before* the public port opens: user `admin`, password = the generated `YOLOROUTER_ADMIN_PASSWORD` variable.
- `server.external_url` is pinned to your Railway domain (upstream recommends this for any internet-exposed deployment; OAuth/SSO callbacks use it).
- **Persistent state** on a Railway volume at `/yolorouter`: `configs/config.yaml` (holds the master key that encrypts your upstream provider keys), `data/yolorouter.db` (SQLite) and logs.

## Using it

1. Open the domain, sign in as `admin` / `YOLOROUTER_ADMIN_PASSWORD`.
2. Add a provider with its upstream API key (OpenAI, Anthropic, Gemini, DeepSeek, OpenRouter, …), import models, then issue a gateway API key (`sk-yr-…`).
3. Point clients at it:

```bash
# OpenAI SDKs
export OPENAI_BASE_URL=https://<domain>/v1
export OPENAI_API_KEY=sk-yr-...
# Claude Code
export ANTHROPIC_BASE_URL=https://<domain>
export ANTHROPIC_AUTH_TOKEN=sk-yr-...
```

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `YOLOROUTER_ADMIN_PASSWORD` | generated | Password of the pre-created admin (used only on first boot; change it later in the console) |
| `YOLOROUTER_ADMIN_USERNAME` | `admin` (image default) | Username of the pre-created admin |
| `YOLOROUTER_EXTERNAL_URL` | Railway domain | Override when you add a custom domain |

## Notes

- Back up the whole volume; losing `configs/config.yaml` means stored provider keys can no longer be decrypted.
- Changing the admin password in the console does not update the Railway variable.
- In-place self-update is disabled in containers by upstream. To upgrade, bump the base image tag/digest in the `Dockerfile`; GitHub Actions rebuilds `ghcr.io/onepush-dev/yolorouter`. Migrations run automatically on start (with a pre-migration snapshot).
- Your upstream provider usage is billed by each provider.
