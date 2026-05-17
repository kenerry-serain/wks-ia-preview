# Kubernetes Manifest Conventions

This rule MUST be followed for ALL Kubernetes YAML manifests in this project.

---

## 1. Minimum Replicas

Every Deployment must have at least 2 replicas to ensure high availability. A single replica means any pod restart causes downtime.

```yaml
spec:
  replicas: 2
```

---

## 2. Pod Disruption Budgets (PDB)

Every Deployment must have a corresponding PodDisruptionBudget. PDBs protect availability during voluntary disruptions like node drains, cluster upgrades, and autoscaler scale-downs. Without a PDB, Kubernetes can evict all pods simultaneously.

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: <app-name>
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: <app-name>
```

Use `minAvailable: 1` for 2-replica deployments. For 3+ replicas, prefer `maxUnavailable: 1`.

---

## 3. Health Probes

Every container must define both `readinessProbe` and `livenessProbe`. These serve different purposes — readiness controls traffic routing, liveness controls restart decisions. Missing probes means Kubernetes can't detect unhealthy pods.

```yaml
containers:
  - name: app
    readinessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
      failureThreshold: 3
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 20
      failureThreshold: 3
```

- **readinessProbe**: lower `initialDelaySeconds`, checked more frequently — controls whether the pod receives traffic
- **livenessProbe**: higher `initialDelaySeconds`, checked less frequently — restarts the pod if it fails
- Use `startupProbe` for slow-starting apps instead of inflating `initialDelaySeconds` on liveness

---

## 4. Resource Requests and Limits

Every container must specify both `requests` and `limits` for CPU and memory. Without resource specs, the scheduler can't make informed placement decisions, and a single pod can starve others on the node.

```yaml
containers:
  - name: app
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
```

- `requests` = guaranteed minimum — the scheduler uses this for placement
- `limits` = hard ceiling — the container gets OOMKilled or CPU-throttled beyond this
- Set `requests` based on actual observed usage, `limits` at 2-4x requests as headroom
- Never set limits equal to requests unless you need Guaranteed QoS class

---

## 5. Security Context — Non-Root User

Every pod and container must run as a non-root user. Running as root inside a container is a security risk — container escape vulnerabilities are significantly more dangerous with root privileges.

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
  containers:
    - name: app
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
```

- `runAsNonRoot: true` at the pod level enforces the policy even if the image sets USER root
- `allowPrivilegeEscalation: false` prevents `setuid` binaries from escalating
- `readOnlyRootFilesystem: true` prevents writes to the container filesystem (use `emptyDir` volumes for temp files)
- `drop: ALL` capabilities removes all Linux capabilities — add back only what's needed

---

## 6. No Latest Tag

Never use the `latest` tag or omit the tag on container images. The `latest` tag is mutable — it can point to different content on each pull, making deployments non-reproducible and rollbacks impossible.

### WRONG

```yaml
image: 968225077300.dkr.ecr.us-east-1.amazonaws.com/workshop-backend:latest
image: 968225077300.dkr.ecr.us-east-1.amazonaws.com/workshop-backend
```

### CORRECT

```yaml
image: 968225077300.dkr.ecr.us-east-1.amazonaws.com/workshop-backend:v1.0
image: 968225077300.dkr.ecr.us-east-1.amazonaws.com/workshop-backend@sha256:abc123...
```

Use semantic versioning (`v1.0.0`), git short SHA (`abc1234`), or digest-based references.

---

## 7. Image Pull Policy — IfNotPresent

Set `imagePullPolicy: IfNotPresent` to avoid pulling images that already exist on the node. This speeds up pod startup, reduces bandwidth, and avoids failures when the registry is temporarily unavailable.

```yaml
containers:
  - name: app
    image: 968225077300.dkr.ecr.us-east-1.amazonaws.com/workshop-backend:v1.0
    imagePullPolicy: IfNotPresent
```

This is safe when combined with the "no latest tag" rule — versioned tags are immutable, so the cached image is always correct.

---

## 8. Standard Labels

Every resource must include standard Kubernetes labels for identification and grouping:

```yaml
metadata:
  labels:
    app: <app-name>
    version: <version>
    environment: <environment>
    managed-by: <tool>
```

---

## 9. Summary Checklist

Before creating or reviewing any Kubernetes manifest, verify:

- [ ] Deployment has `replicas: 2` or more
- [ ] PodDisruptionBudget exists for every Deployment
- [ ] `readinessProbe` defined on every container
- [ ] `livenessProbe` defined on every container
- [ ] `resources.requests` and `resources.limits` set for CPU and memory on every container
- [ ] Pod `securityContext` has `runAsNonRoot: true`
- [ ] Container `securityContext` has `allowPrivilegeEscalation: false`
- [ ] No `latest` tag or untagged images — use versioned or digest references
- [ ] `imagePullPolicy: IfNotPresent` set on every container
- [ ] Standard labels (`app`, `version`, `environment`) present
- [ ] Capabilities dropped with `drop: ALL`
