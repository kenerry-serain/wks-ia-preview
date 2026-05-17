---
name: Project application stacks
description: Real technology stacks for the workshop frontend and backend — critical to use correct base images in Dockerfiles
type: project
---

The workshop has two real applications under dvn-workshop-apps/, not placeholder Node.js apps.

**Frontend**: Next.js 14 / React 18 / TypeScript / Tailwind CSS
- Source: dvn-workshop-apps/frontend/youtube-live-app/
- Build: `npm run build` produces .next/standalone/ when output:'standalone' is set
- Port: 3000

**Backend**: .NET 8 ASP.NET Core Web API (C#)
- Source: dvn-workshop-apps/backend/YoutubeLiveApp/
- Project file: YoutubeLiveApp.csproj (TargetFramework net8.0)
- Health endpoint: GET /backend/health (mapped via app.Map("/backend", ...))
- Port: 8080 (ASPNETCORE_HTTP_PORTS)

**Why:** Knowing the real stacks prevents choosing wrong base images (e.g. node vs dotnet/sdk, nginx vs self-contained binary).

**How to apply:** Always use mcr.microsoft.com/dotnet/sdk:8.0-alpine for building the backend and alpine:3.20 for the runtime (self-contained publish). Use node:22-alpine for the frontend build and runtime stages.
