# Kamal Deploy Guide

Deploy apps with Kamal. Debug by evidence, not guesses.

## Core Invariants

1. **Kamal deploys committed changes, not worktree changes.**
   If fix is uncommitted, assume server does not have it.

2. **Accessories are separate lifecycle from app deploy.**
   `kamal deploy` does not substitute for `kamal accessory boot`, `restart`, `remove`, or `details`.

3. **Container hostnames must be DNS-safe.**
   Prefer hyphens, not underscores, for hostnames used between app and accessory containers.

4. **Read timestamps before acting.**
   `502` during health checks can mean "not listening yet", "never listened", or "listened then died".

5. **Do not embed fragile worker supervisors in web role by default.**
   If queue supervisor dying kills Puma, split worker path from web path.

6. **Rails multi-DB boot must cover every configured production database.**
   If using `primary`, `cache`, `queue`, `cable`, create and grant all of them.

7. **Tag deletion alone may not free registry space.**
   Untagged manifests can still hold space.

## Preflight

Run before changing deploy state:

```bash
git status --short
git log --oneline -1
bin/kamal app details
```

Checks:

- intended deploy fix is committed
- you know current image/tag running
- you know current service and accessory names

## Standard Workflow

1. Confirm fix is committed.
2. Read `config/deploy*.yml`, Docker entrypoint, and app boot command.
3. Check live state with `kamal app details` and `kamal app logs`.
4. If app depends on accessories, inspect `kamal accessory details <name>` and `kamal accessory logs <name>`.
5. Classify failure before editing.
6. Apply one fix class at a time.
7. Redeploy, then re-check `/up`, app logs, and container status.

## Failure Classification

### Host Resolution

Symptoms:

- `could not translate host name`
- accessory hostname resolves nowhere

Actions:

- inspect `env.clear.DB_HOST`
- inspect accessory `service:` name
- prefer DNS-safe names like `catalog-manager-db`
- confirm accessory exists on Kamal network

### Postgres Auth Or Bootstrap

Symptoms:

- `password authentication failed`
- `permission denied for schema public`
- `permission denied to create database`

Actions:

- verify whether existing data volume persisted older password
- grant `CREATE, USAGE` on schema, not only `USAGE`
- pre-create all configured production DBs as admin if Rails uses multi-DB
- keep runtime role narrower than admin when possible

### Boot Timeout

Symptoms:

- app eventually starts, but Kamal times out first

Actions:

- compare timestamps between container start, Puma listen, and health timeout
- increase `deploy_timeout` if boot is valid but slower than timeout

### Thruster Or Puma Upstream Refused

Symptoms:

- `dial tcp [::1]:3000: connect: connection refused`
- Thruster returns `502` on `/up`

Actions:

- confirm whether Puma ever logs `Listening on ...`
- if not, app boot died before socket bind
- if yes, compare bound address with Thruster upstream behavior
- prefer fixing server launch path over forcing duplicate Puma binds

### Queue Supervisor Kills Web

Symptoms:

- log says `Detected Solid Queue has gone away, stopping Puma...`
- web serves for a bit, then dies

Actions:

- remove embedded queue supervisor env from web role
- move queue worker to separate role/process later

### Registry Full

Symptoms:

- new images fail to push or space low in DO registry

Actions:

- list tags first
- keep `latest` and a safe rollback set
- delete old tags
- list manifests
- delete untagged manifests when safe
- expect some manifest deletions to fail with `412` if referenced by other manifests

## Kamal Commands

Examples below use placeholder names like `db`, `<repository>`, and `<registry>`.
Project-specific names such as `catalog_manager-web-*`, `catalog-manager-db`, or
`catalog_manager` are exemplar names from one incident, not canonical Kamal requirements.

### App

```bash
bin/kamal app details
bin/kamal app logs -n 200
bin/kamal app logs -n 200 --since 30m
```

### Accessory

```bash
bin/kamal accessory details db
bin/kamal accessory logs db
bin/kamal accessory boot db
bin/kamal accessory remove db
```

### Registry Cleanup

Discover actual repo first:

```bash
doctl registries list
doctl registry repository list-v2 --registry "<registry>"
doctl registry repository list-tags "<repository>" --registry "<registry>" --format Tag,UpdatedAt,ManifestDigest
```

Delete old tags:

```bash
doctl registry repository delete-tag "<repository>" "<tag1>" "<tag2>" --registry "<registry>" --force
```

Then inspect manifests:

```bash
doctl registry repository list-manifests "<repository>" --registry "<registry>"
doctl registry repository delete-manifest "<repository>" "<digest>" --registry "<registry>" --force
```

## Eval Checks

| # | Check | Pass criteria | If fail |
|---|-------|---------------|---------|
| 1 | Commit state | intended deploy fix is committed | commit first, redeploy after commit |
| 2 | Accessory hostname | accessory host/service names are DNS-safe | rename to hyphenated host/service |
| 3 | Accessory running | `kamal accessory details` shows running container | boot or recreate accessory |
| 4 | Multi-DB bootstrap | all configured production DBs exist | create/grant all configured DBs as admin |
| 5 | Web stability | app container stays up after health passes | inspect queue/plugin/boot logs |
| 6 | Health check | `/up` returns 200 after deploy | inspect Thruster + Puma timestamps |
| 7 | Registry cleanup | tag/manifests count drops safely | remove untagged manifests after tags |

## Failure Modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| `could not translate host name "catalog_manager-db"` | accessory hostname derived from underscore service name | use DNS-safe accessory host like `catalog-manager-db` |
| fix not visible after deploy | change was not committed | commit before running `kamal deploy` |
| `permission denied for schema public` | runtime role lacked schema `CREATE` | grant `CREATE, USAGE` on schema |
| `permission denied to create database` | Rails multi-DB prepare ran before missing DBs existed | create `primary/cache/queue/cable` DBs as admin first |
| `dial tcp [::1]:3000: connect: connection refused` | app had not listened yet or died before listen | inspect Puma boot path and timestamps |
| `Detected Solid Queue has gone away, stopping Puma...` | embedded Solid Queue supervisor died inside web container | remove queue-from-web setup; run queue separately |
| registry still full after tag deletes | manifests remained untagged or referenced | inspect manifest graph and delete safe top-level leftovers |

## Exemplar

Representative incident:

- Rails 8 app on Kamal with Postgres accessory and Thruster
- project used names like `catalog_manager-web-*`, `catalog-manager-db`, and `catalog_manager`; treat those as example names only
- failures included:
  - DB hostname resolution from underscore accessory name
  - schema grant gap
  - multi-DB bootstrap gap
  - queue supervisor killing web
  - DO registry cleanup requiring manifest deletion after tag deletion

Use this exemplar when user reports:

- unhealthy `catalog_manager-web-*` container
- Thruster `/up` `502`
- accessory DNS/auth/bootstrap issues
- DO registry space pressure during deploy
