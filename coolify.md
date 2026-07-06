# Deploying to Coolify

This repo deploys as a Docker Compose resource. `docker-compose.yml` defines two services:

- `mongodb` — `mongo:4.4`, pinned to match the app's `pymongo==3.5.1` client (newer Mongo
  speaks a wire protocol that old pymongo can't negotiate). If you ever see a wire-version
  error in the `airnotifier` logs, try dropping to `mongo:3.6` before anything else.
- `airnotifier` — built from the `Dockerfile` in this repo (clones upstream AirNotifier,
  layers this fork's `config.py`/`start.sh` on top).

## Setup steps

1. In Coolify: **New Resource → Docker Compose**, point it at this repo/branch, and let it
   detect `docker-compose.yml`.
2. **Domain**: the compose file sets `SERVICE_FQDN_AIRNOTIFIER_8801` as a Coolify "magic
   variable" — Coolify auto-generates a domain and routes it to the `airnotifier` service's
   port 8801 through its own proxy. If your Coolify version doesn't pick this up, delete
   that line and set the domain/port manually on the `airnotifier` service in the UI instead
   (Configuration → Domains → port `8801`).
3. **TLS**: Coolify's proxy terminates TLS in front of the container, so leave `config.py`'s
   `https = False` as-is — the app itself should keep speaking plain HTTP internally.
4. Deploy. On first boot, `start.sh` runs `pipenv run ./install.py` automatically before
   starting `app.py` — it creates the Mongo collections and a default admin user
   (`admin@airnotifier` / `admin`). **Change that password immediately** after first login.
   `install.py` is safe to run repeatedly (it's what happens on every container restart), so
   you don't need to guard against re-running it.

## Why no host port bindings / container names

Coolify runs multiple resources on the same Docker host and manages its own reverse proxy
network, so:
- No `ports:` host bindings — services are reached over Coolify's internal network
  (`expose: ["8801"]` documents the port without publishing it to the host).
- No `container_name:` — Coolify assigns its own names per deployment/preview and a fixed
  name would collide across environments.

## Persistent storage

`mongodb-data`, `airnotifier-certs`, and `airnotifier-logs` are named volumes so data survives
redeploys. If you'd rather browse certs/logs directly on the host, switch them to bind mounts
via Coolify's **Storage** tab on the service instead of editing the compose file — Coolify
manages the host path for you there.

## Manual DB install / re-install

If you ever need to run the installer by hand (e.g. after wiping the `mongodb-data` volume):

```bash
docker exec -it <airnotifier-container-name> pipenv run ./install.py
```

Find the container name with `docker ps` (Coolify prefixes it with the resource/service name).
