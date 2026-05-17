---
name: dockerfile-create
description: |
  Creates production-ready Dockerfiles for applications, then builds, tests, and reports
  image size and security. Generates the smallest possible image using Alpine bases,
  multi-stage builds, non-root users, health checks, and CVE scanning. After creating
  the Dockerfile, it builds the image, verifies the health check works, prints the
  image size, and runs a vulnerability scan. Use this skill whenever the user wants to
  create a Dockerfile, containerize an application, dockerize a service, build a Docker
  image, or asks about container security. Also trigger when the user says things like
  "create a Dockerfile for this app", "dockerize the backend", "containerize this service",
  "build a docker image", or "I need a Dockerfile".
---

# Dockerfile Create

Create production-ready Dockerfiles and verify they work — smallest image, fewest CVEs.

## Arguments

- `/dockerfile-create <path-to-app>` — creates a Dockerfile for the app at the given path
- `/dockerfile-create` — if no path given, ask the user which application to containerize

## Pipeline

### Step 1: Analyze the application

Before writing anything, understand what you're containerizing:

1. Read the app directory to identify the tech stack:
   - `package.json` → Node.js (check for Next.js, React, Express, etc.)
   - `*.csproj` / `*.sln` → .NET
   - `go.mod` → Go
   - `requirements.txt` / `pyproject.toml` → Python
   - `Cargo.toml` → Rust
2. Identify the build command, output directory, and entry point
3. Identify the port the app listens on
4. Check if a health endpoint exists (look for `/health`, `/healthz`, `/readyz` routes)
5. Check if a Dockerfile or .dockerignore already exists — if so, ask the user if they want to overwrite

### Step 2: Read the Dockerfile rules

Read `.claude/rules/dockerfile.md` and follow every convention. The key requirements are:

- **Multi-stage build** — separate build dependencies from runtime
- **Alpine base images** — always use `-alpine` variants
- **Non-root user** — create `appuser`/`appgroup` in the runtime stage
- **Health check** — use `wget` (built into Alpine, no extra install)
- **Layer optimization** — copy dependency files before source code
- **Pinned versions** — pin base image to major.minor, no `latest`
- **OCI labels** — include `org.opencontainers.image.source` and `.description`
- **.dockerignore** — create alongside the Dockerfile
- **No secrets** — never bake credentials into the image
- **COPY over ADD** — unless tar extraction is needed

### Step 3: Write the Dockerfile and .dockerignore

Place both files in the same directory as the application code.

Adapt the Dockerfile to the specific tech stack. Make choices that minimize image size:
- For Go/Rust: build a static binary, use bare `alpine` as runtime (no language runtime needed)
- For Node.js: use a deps stage to cache `npm ci`, then a builder stage, then a minimal runtime
- For .NET: use `dotnet/sdk` to build, `dotnet/aspnet` (Alpine) or bare `alpine` with self-contained publish for runtime
- For Python: install packages with `--prefix` in builder, copy only the installed packages to runtime

### Step 4: Build the image

```bash
cd <app-directory>
docker build -t <image-name>:latest .
```

Use a descriptive image name based on the app (e.g., `workshop-frontend`, `my-api`).

If the build fails, read the error, fix the Dockerfile, and retry. Common issues:
- Missing build dependencies in Alpine (add with `apk add --no-cache`)
- Framework-specific config needed (e.g., Next.js needs `output: 'standalone'`)
- Wrong WORKDIR or COPY paths

### Step 5: Test the health check

Run the container and verify the health check passes:

```bash
# Start container
docker run -d --name test-container -p <port>:<port> <image-name>:latest

# Wait for startup
sleep 5

# Test health endpoint
curl -f http://localhost:<port>/health || curl -f http://localhost:<port>/

# Check Docker's built-in health status
docker inspect --format='{{.State.Health.Status}}' test-container
```

If the health check fails:
- Check if the app actually started: `docker logs test-container`
- Verify the port and health endpoint path
- Fix and rebuild if needed

### Step 6: Print image size

```bash
docker images <image-name> --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

Show the size prominently — this is a key metric the user cares about.

### Step 7: Scan for CVEs

Run a vulnerability scan to identify known CVEs in the image:

```bash
docker scout cves <image-name>:latest 2>/dev/null
```

If `docker scout` is not available, try:

```bash
# Fallback: use trivy if installed
trivy image <image-name>:latest 2>/dev/null
```

If neither scanner is available, inform the user and suggest installing one:
- `docker scout` comes with Docker Desktop
- `trivy` can be installed via `brew install trivy`

Report:
- Total number of CVEs by severity (Critical, High, Medium, Low)
- Any critical or high CVEs that should be addressed
- Suggestions to reduce CVEs (e.g., using a newer base image version, removing unnecessary packages)

### Step 8: Clean up and report

Stop and remove the test container:

```bash
docker stop test-container && docker rm test-container
```

Present a summary table:

```
## Results

| Metric          | Value              |
|-----------------|---------------------|
| Image           | <image-name>:latest |
| Size            | <size>              |
| Health Check    | <pass/fail>         |
| CVEs (Critical) | <count>             |
| CVEs (High)     | <count>             |
| CVEs (Medium)   | <count>             |
| CVEs (Low)      | <count>             |
```

If there are critical/high CVEs, suggest mitigation steps.

## Tips for smaller images

When the image seems larger than expected, consider:

- Are dev dependencies being included? Use `npm ci --only=production` or equivalent
- Is the build output being copied correctly? Only copy what's needed for runtime
- Are unnecessary system packages installed in the runtime stage?
- Could a smaller base work? (e.g., `alpine:3.20` instead of `node:22-alpine` if using standalone output)
- For .NET: self-contained publish with trimming can reduce size significantly
