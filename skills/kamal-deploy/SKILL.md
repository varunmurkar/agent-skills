---
name: kamal-deploy
description: >
  Use when deploying or debugging apps with Kamal, especially unhealthy web
  containers, accessory/Postgres issues, Thruster or Puma health-check failures,
  and DigitalOcean registry cleanup related to Kamal images.
metadata:
  author: varun
  version: "0.1.0"
---

# Kamal Deploy

Open `@references/guide.md` and follow it. Do not proceed without it.

Use this skill for:

- `kamal deploy` and `kamal setup`
- accessory boot, logs, remove, recreate, networking, and host resolution
- unhealthy web containers and `/up` health-check failures
- Rails + Thruster + Puma boot issues under Kamal
- DigitalOcean registry tag and manifest cleanup for Kamal images
