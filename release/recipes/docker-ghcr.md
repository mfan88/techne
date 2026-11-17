## Release recipe: Docker images to GitHub Container Registry (ghcr.io)

**Secrets:** none; the workflow uses `GITHUB_TOKEN` with `packages: write`. Image: `ghcr.io/<owner>/<repo>` (lowercase).

### Workflow (`.github/workflows/release-image.yml`)
- Trigger on tags `v*` (and optionally pushes to `main` for an `edge` tag).
- `permissions: { contents: read, packages: write, id-token: write, attestations: write }`.
- Steps: checkout → `docker/setup-qemu-action` (for multi-arch) → `docker/setup-buildx-action` → `docker/login-action` (`registry: ghcr.io`, `username: ${{ github.actor }}`, `password: ${{ secrets.GITHUB_TOKEN }}`) → `docker/metadata-action` (`images: ghcr.io/${{ github.repository }}`; tags `type=semver,pattern={{version}}`, `type=semver,pattern={{major}}.{{minor}}`, `type=sha`; OCI labels) → `docker/build-push-action` (`target: runtime`, `platforms` from the image contract, `push: true`, tags/labels from metadata, `cache-from: type=gha`, `cache-to: type=gha,mode=max`, `provenance: true`, `sbom: true`).
- Optional: `actions/attest-build-provenance` on the pushed digest; a Trivy scan that fails on CRITICAL before push.

### Shortcuts
`Makefile`: `image` → `docker build --target runtime -t ghcr.io/<owner>/<repo>:dev .`, `release-prepare` → `scripts/release.sh`, `push-local` → `docker push` (needs `gh auth refresh -s write:packages` and `gh auth token | docker login ghcr.io -u <user> --password-stdin`).

### Gotchas
New packages are private by default: set visibility and link the package to the repo in its settings. Never tag `latest` from a branch build; only from release tags, and only if the project uses `latest`.
