## Layers: Docker image building

| Role | Paths | Pattern | Check |
| --- | --- | --- | --- |
| component | `Dockerfile` (one stage per work order), `.dockerignore` | Named multi-stage targets: `deps`, `build`, `runtime` | `hadolint Dockerfile` (if installed) and `docker build --check .` |
| logic | `docker/entrypoint.sh`, `docker/healthcheck.sh`, build strategy (multi-arch, CUDA, cache mounts) | POSIX sh scripts; strategy decided in the contract | `shellcheck <files>` (if installed) |
| wiring | `compose.yaml`, `.github/workflows/*build*.yml`, image tags, registry push | Services and CI steps referencing stage targets by name | `docker compose config -q` |

**Contract format:** an image spec.
```text
stages: deps (FROM python:3.12-slim@sha256:<digest>) → build → runtime
ARG: APP_VERSION   ENV: PORT=8000   EXPOSE: 8000   USER: app (uid 10001)
ENTRYPOINT ["/app/docker/entrypoint.sh"]   CMD ["serve"]
HEALTHCHECK: GET /healthz every 30s   platforms: linux/amd64, linux/arm64
```

**Component rules:** base images pinned by tag and digest; least-specific `COPY` first so layers cache (lockfile before source); package-manager caches as `--mount=type=cache`; secrets only through `--mount=type=secret`, never `ARG`/`ENV`/`COPY`; runtime stage runs as the non-root `USER` from the contract; `.dockerignore` excludes `.git`, env files, caches and build output.
**Logic rules:** entrypoint uses `exec` so signals reach the app; `set -eu`; healthcheck exits non-zero on failure and finishes within its timeout; CUDA images match the framework's CUDA version from the contract.
**Wiring rules:** compose services reference `target:` stages by name; no secrets in compose files; CI uses buildx with registry cache and pushes only the tags the contract lists.
**Integration check (tester):** `docker build --target runtime -t <name>:test .`, then `docker run` with the contract's env, wait for the healthcheck to pass, and check the image runs as the non-root user.

### QA: Docker
- **Levels:** static (Dockerfile lint, `docker build --check`) · structure (files, user, ports, env, entrypoint) with container-structure-test if the project uses it, else `docker inspect` assertions in a script · smoke (container starts, healthcheck passes, one request or command works) · security scan with Trivy or Docker Scout if available.
- **Required case kinds:** runs as the contract's non-root user; no secrets in `docker history` or env; exposes only the contract's ports; healthcheck turns healthy within its interval; SIGTERM stops the container within 10 s; image size under the contract's limit if one is set.
- **Commands:** static `hadolint Dockerfile && docker build --check .` · build `docker build --target runtime -t <name>:test .` · structure `container-structure-test test --image <name>:test --config tests/container.yaml` · scan `trivy image --severity HIGH,CRITICAL <name>:test` · per-test coverage: not applicable.
- **Flakiness:** fixed ports colliding (use random host ports), healthcheck timing (poll with a timeout, never sleep a fixed time), network-dependent build steps (use the cache).
