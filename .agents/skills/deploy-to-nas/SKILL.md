---
name: deploy-to-nas
description: >-
  Deploy the Maybe app to the self-hosted NAS instance (frad-nas). Use this whenever the user asks to deploy, redeploy, re-deploy, or "重新部署" the app to the NAS, frad-nas, 10.10.0.195, or the self-hosted instance — even if they just say "部署一下" or "push to the NAS". The workflow is: rsync the repo to /root/maybe-app, rebuild the maybe-app Docker image, then recreate the single `maybe` container (Rails + Sidekiq + PostgreSQL + Redis under supervisord).
compatibility:
  - ssh with host alias `frad-nas` (root@10.10.0.195, ed25519 key) configured in ~/.ssh/config
  - rsync on the local machine
  - docker on the NAS (root access)
---

# Deploy Maybe to frad-nas

The self-hosted production instance runs on the home NAS: `frad-nas` = `root@10.10.0.195`. The app is a plain file copy at `/root/maybe-app` (NOT a git repo — local repo is the source of truth).

Deployment runs as a SINGLE container `maybe` that bundles everything:

- `maybe` — Rails + Sidekiq + PostgreSQL 15 + Redis 7 under supervisord (4 programs), host port 3006 -> container 3000, restart `unless-stopped`, stop-timeout 180, data in named volume `maybe-data:/data` (postgres at /data/postgres, redis at /data/redis)

Deployment is three steps: sync code, build image, recreate the one container.

## Step 1: Sync the code

The NAS directory is a mirror of the local checkout. rsync with `--delete` so removed local files are removed there too, excluding repo junk and runtime state:

```bash
rsync -az --delete \
  --exclude='.git/' --exclude='.git-agent/' --exclude='.cursor/' --exclude='.devcontainer/' \
  --exclude='.Codex/' --exclude='.env*' --exclude='node_modules/' --exclude='tmp/' --exclude='log/' \
  --exclude='storage/' --exclude='app/assets/builds/' --exclude='public/assets/' \
  --exclude='coverage/' \
  ./ frad-nas:/root/maybe-app/
```

`.env*` is excluded so NAS-side secrets are never overwritten or deleted. `storage/` is excluded because production data lives in the postgres data dir inside the volume. `.Codex/` is excluded because it holds local tool config — rsync never reads git excludes, so this must be explicit here (it also protects the local-only skill below from being deployed).

## Step 2: Build the image

Run the build over SSH in the background (bundle install + assets precompile takes a few minutes):

```bash
ssh frad-nas "cd /root/maybe-app && DOCKER_BUILDKIT=0 docker build --build-arg BUNDLE_MIRROR=https://mirrors.aliyun.com/rubygems/ -t maybe-app . > ~/maybe-build-deploy.log 2>&1; echo BUILD_EXIT=\$?"
```

- Keep `DOCKER_BUILDKIT=0` (legacy builder) — it matches how this NAS has always built the image; don't change it without a reason.
- Keep the Aliyun mirror build-arg — bundler needs it on this network, especially when Gemfile.lock changes.
- When the build finishes, confirm `BUILD_EXIT=0` and tail `~/maybe-build-deploy.log` on the NAS if it failed.
- No manual migration step: the rails supervisord program runs `./bin/rails db:prepare` on every (re)start, which no-ops when schema_migrations is current.
- The base image is pinned to `ruby:3.4.4-slim-bookworm` — do not unpin (trixie ships postgresql-17 at different paths and the pg_dropcluster build step would break).

## Step 3: Recreate the container

Dump the running container's env and reuse it verbatim — this keeps config identical and avoids hardcoding secrets (SECRET_KEY_BASE etc. exist only in the container env):

```bash
ssh frad-nas "docker inspect maybe --format '{{range .Config.Env}}{{.}}{{\"\n\"}}{{end}}'"
```

Recreate the single container with the same env, changing only `DB_HOST`/`REDIS_URL` if they point at old container names (must be `127.0.0.1` / `redis://127.0.0.1:6379`):

```bash
ssh frad-nas "cat > /tmp/recreate-maybe.sh" <<'SCRIPT'
#!/bin/bash
set -e
APP_ENV=( -e RAILS_ENV=production -e SELF_HOSTED=true -e DB_HOST=127.0.0.1 -e DB_PORT=5432 ... )  # <-- all vars from the dump

docker stop -t 180 maybe || true
docker rm maybe || true

docker run -d --name maybe \
  --restart unless-stopped --stop-timeout 180 \
  -p 3006:3000 \
  -v maybe-data:/data \
  "${APP_ENV[@]}" \
  maybe-app
SCRIPT
ssh frad-nas "bash /tmp/recreate-maybe.sh && rm -f /tmp/recreate-maybe.sh"
```

- The named volume `maybe-data:/data` holds ALL production data. NEVER drop the `-v` flag, never `docker volume rm maybe-data`.
- Never start the legacy containers (`maybe-app`, `maybe-worker`, `maybe-postgres`, `maybe-redis`) alongside `maybe` — the old app/worker conflict on port 3006, and postgres/redis are now inside the container.
- Keep `--restart unless-stopped` and `--stop-timeout 180` — the former auto-recovers after a NAS reboot, the latter gives supervisord time to shut postgres down gracefully.

## Step 4: Verify

1. `ssh frad-nas "docker ps --filter name=maybe"` — `maybe` should be `Up`.
2. `ssh frad-nas "curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://10.10.0.195:3006/up"` — 200 is healthy. `/` returns 302 (redirect to /sessions/new) for unauthenticated requests — also normal.
3. `ssh frad-nas "docker exec maybe supervisorctl status"` — all 4 programs RUNNING (postgres, redis, rails, sidekiq).
4. `ssh frad-nas "docker logs maybe --tail 20"` — puma listening, sidekiq connected to redis, no stack traces.
5. Data check: `ssh frad-nas "docker exec maybe psql -h /tmp -U postgres -d maybe_production -tAc 'SELECT count(*) FROM accounts;'"` — should match expectations.

The app URL is `http://10.10.0.195:3006` — verify against that, not localhost.

## One-time switchover (only if `maybe` does not exist yet)

If this is the first deploy of the single-container architecture, the legacy containers must be retired with a data migration:

1. Snapshot: `docker tag maybe-app:latest maybe-app:pre-single` on the NAS.
2. Dump (old postgres still running): `docker exec maybe-postgres pg_dump -U postgres -F p -d maybe_production > /root/maybe_production.sql` — then strip PG17-only syntax for PG15: `sed -e '/^\\restrict /d' -e '/^SET transaction_timeout/d' /root/maybe_production.sql > /root/maybe_production_pg15.sql`.
3. `docker stop maybe-app maybe-worker` (old postgres/redis stay up for rollback).
4. Start `maybe` per Step 3, wait for boot, stop rails+sidekiq via `docker exec maybe supervisorctl stop rails sidekiq`.
5. `docker exec maybe dropdb -h /tmp -U postgres maybe_production && docker exec maybe createdb -h /tmp -U postgres maybe_production`, then `docker exec -i maybe psql -h /tmp -U postgres -d maybe_production -v ON_ERROR_STOP=1 -f - < /root/maybe_production_pg15.sql`.
6. `docker exec maybe supervisorctl start rails sidekiq`, verify with Step 4 plus a row-count diff between the old and new databases.
7. Rollback if needed: `docker stop -t 180 maybe && docker start maybe-app maybe-worker` (old containers pin the old image; old postgres volume is untouched after the dump). Keep legacy containers stopped ~1 week before `docker rm`-ing them.

## Gotchas

- This skill itself is local-only: it lives at `.Codex/skills/deploy-to-nas/` and is excluded from git via `.git/info/exclude` (not tracked, never pushed, never deployed). Do not commit it, do not remove the exclude entry, and do not write secrets into it.
- Never `git pull` on the NAS — `/root/maybe-app` has no `.git`. rsync from the local checkout is the only way code gets there.
- Never write the container secrets (SECRET_KEY_BASE, OPENAI_ACCESS_TOKEN, POSTGRES_PASSWORD) into the skill, the repo, or logs — always re-derive them from `docker inspect`.
- If the build fails, read `~/maybe-build-deploy.log` on the NAS. A bundler failure usually means Gemfile.lock changed and the mirror path should be double-checked; an assets error means a bad ERB/CSS change; a `pg_dropcluster` failure means the base image drifted off bookworm.
- Data lives ONLY in the `maybe-data` volume — the container itself is disposable, the volume is not.
