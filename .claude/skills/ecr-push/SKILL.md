---
name: ecr-push
description: |
  Builds Docker images and pushes them to Amazon ECR. Handles ECR login, docker build,
  docker tag, and docker push for one or more images in a single invocation. Accepts
  image names and their Dockerfile locations as parameters. Use this skill whenever the
  user wants to push images to ECR, deploy containers to a registry, build and push
  Docker images, or says things like "push to ECR", "build and push the frontend",
  "deploy images to the registry", "ecr push", "push all images", or "send the
  containers to ECR".
---

# ECR Push

Build Docker images and push them to Amazon ECR in one command.

## Arguments

Pass one or more image entries as `<ecr-repo-name>:<path-to-dockerfile-directory>`:

- `/ecr-push workshop-frontend:./dvn-workshop-apps/frontend/youtube-live-app`
- `/ecr-push workshop-frontend:./dvn-workshop-apps/frontend/youtube-live-app workshop-backend:./dvn-workshop-apps/backend/YoutubeLiveApp`

If no arguments are given, look for all directories containing a `Dockerfile` under `dvn-workshop-apps/` and ask the user which ones to push.

## Pipeline

### Step 1: Determine AWS account and region

Get the AWS account ID and region for the ECR registry URL:

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
```

### Step 2: ECR Login

Authenticate Docker to the ECR registry. This only needs to happen once, regardless of how many images are being pushed:

```bash
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_REGISTRY}
```

If login fails, stop and show the error — likely a credentials or permissions issue.

### Step 3: For each image, build and push

For each `<repo-name>:<path>` entry:

#### 3a: Verify the ECR repository exists

```bash
aws ecr describe-repositories --repository-names <repo-name> --region ${AWS_REGION}
```

If the repository doesn't exist, inform the user and ask if they want to create it. If yes:

```bash
aws ecr create-repository --repository-name <repo-name> --region ${AWS_REGION} \
  --image-scanning-configuration scanOnPush=true
```

#### 3b: Build the image

```bash
cd <path>
docker build -t <repo-name>:latest .
```

If the build fails, show the error and continue to the next image (don't stop the entire pipeline).

#### 3c: Tag for ECR

```bash
docker tag <repo-name>:latest ${ECR_REGISTRY}/<repo-name>:latest
```

#### 3d: Push to ECR

```bash
docker push ${ECR_REGISTRY}/<repo-name>:latest
```

Show push progress. If push fails, show the error and continue to the next image.

### Step 4: Summary

After all images are processed, show a summary table:

```
| Image              | Size    | Build   | Push    | ECR URI                                          |
|--------------------|---------|---------|---------|--------------------------------------------------|
| workshop-frontend  | 258 MB  | OK      | OK      | 123456.dkr.ecr.us-east-1.amazonaws.com/workshop-frontend:latest |
| workshop-backend   | 176 MB  | OK      | FAILED  | -                                                |
```

## Important Notes

- ECR login token is valid for 12 hours — no need to re-login if recently authenticated
- The skill builds images locally then pushes — ensure Docker is running
- If the user passes `all` as the argument, discover all Dockerfiles in `dvn-workshop-apps/` and push them all
- AWS credentials must already be configured in the shell
