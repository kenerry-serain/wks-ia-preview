# ADR-005: Estrutura Kustomize para Manifests Kubernetes

**Status**: Aceito
**Data**: 2026-05-17
**Decisores**: Time de infraestrutura / DevOps lead

---

## Sumario Executivo

Adotar Kustomize como mecanismo de gerenciamento de manifests Kubernetes, com estrutura `base/` + `overlays/production/`. O pipeline de CI/CD usa `kustomize edit set image` para atualizar tags de imagem deterministicamente no overlay de producao, e o ArgoCD aponta para o overlay para sincronizar com o cluster. A estrutura ja foi implementada e esta em uso.

---

## Contexto

O projeto tem duas aplicacoes containerizadas deployadas no EKS:

1. **Backend**: .NET API em `dvn-workshop-apps/backend/YoutubeLiveApp` (porta 8080, health check em `/backend/health`)
2. **Frontend**: Next.js em `dvn-workshop-apps/frontend/youtube-live-app` (porta 3000, health check em `/`)

Os manifests Kubernetes precisam ser gerenciados de forma que:

1. **Manifests base** sejam reutilizaveis e environment-agnostic
2. **Variantes por ambiente** (production, staging, etc.) sejam aplicadas como patches
3. **Tags de imagem** sejam atualizadas automaticamente pelo pipeline de CI/CD
4. **ArgoCD** consiga ler e renderizar os manifests nativamente, sem plugins ou ferramentas externas
5. **Atualizacao de tags** seja semantica (entenda a estrutura YAML), nao baseada em text replacement

### Dependencias

- **EKS Cluster**: `workshop-eks` (ADR-003)
- **ECR Repositories**: `workshop-backend` e `workshop-frontend` no account 968225077300
- **Kubernetes Manifests**: Ja criados com todas as convencoes do projeto (replicas >= 2, PDBs, health probes, resource limits, security contexts)
- **ArgoCD**: Sera instalado conforme ADR-006

---

## Decisao

### Estrutura de Diretorios

```
kubernetes/
  base/
    kustomization.yaml            # Lista todos os recursos base
    backend-deployment.yaml       # Deployment do backend (2 replicas, probes, security context)
    backend-service.yaml          # Service ClusterIP do backend
    backend-pdb.yaml              # PodDisruptionBudget do backend
    frontend-deployment.yaml      # Deployment do frontend (2 replicas, probes, security context)
    frontend-service.yaml         # Service ClusterIP do frontend
    frontend-pdb.yaml             # PodDisruptionBudget do frontend
  overlays/
    production/
      kustomization.yaml          # Referencia base + override de image tags
```

### Arquivo `kubernetes/base/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - backend-deployment.yaml
  - backend-service.yaml
  - backend-pdb.yaml
  - frontend-deployment.yaml
  - frontend-service.yaml
  - frontend-pdb.yaml
```

### Arquivo `kubernetes/overlays/production/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

images:
  - name: 968225077300.dkr.ecr.us-east-1.amazonaws.com/workshop-backend
    newTag: abc1234
  - name: 968225077300.dkr.ecr.us-east-1.amazonaws.com/workshop-frontend
    newTag: def5678
```

> **Nota**: Os valores de `newTag` (`abc1234`, `def5678`) sao exemplos de git short SHA. Em operacao, esses valores sao atualizados automaticamente pelo pipeline de CI/CD via `kustomize edit set image`.

### Como o Pipeline Atualiza Tags

O pipeline de CI/CD executa o seguinte comando apos o push da imagem Docker para o ECR:

```bash
cd kubernetes/overlays/production

kustomize edit set image \
  968225077300.dkr.ecr.us-east-1.amazonaws.com/workshop-backend:${GIT_SHORT_SHA}
```

Esse comando:
1. **Parseia** o `kustomization.yaml` como YAML estruturado (nao como texto)
2. **Encontra** a entrada `images` que corresponde ao `name` da imagem
3. **Atualiza** o campo `newTag` com o novo valor
4. **Preserva** toda a estrutura e formatacao do arquivo

Se a entrada `images` nao existir, o Kustomize a cria automaticamente.

### Como o ArgoCD Consome

O ArgoCD e configurado para apontar para `kubernetes/overlays/production/`:
1. ArgoCD detecta mudancas no Git (polling ou webhook)
2. Executa `kustomize build kubernetes/overlays/production/` internamente
3. Compara o output renderizado com o estado atual do cluster
4. Aplica as diferencas automaticamente (com `selfHeal: true` e `prune: true`)

Kustomize e suportado nativamente pelo ArgoCD -- nao requer plugins, sidecar containers, ou configuracao adicional.

### Manifests Base

Os manifests em `kubernetes/base/` seguem integralmente as convencoes do projeto (`.claude/rules/kubernetes-manifests.md`):

| Recurso | Arquivo | Convencoes aplicadas |
|---|---|---|
| Backend Deployment | `backend-deployment.yaml` | 2 replicas, readiness/liveness probes em `/backend/health:8080`, resource requests/limits, securityContext non-root, drop ALL capabilities, readOnlyRootFilesystem, imagePullPolicy IfNotPresent, standard labels |
| Backend Service | `backend-service.yaml` | ClusterIP, porta 8080 |
| Backend PDB | `backend-pdb.yaml` | `minAvailable: 1` |
| Frontend Deployment | `frontend-deployment.yaml` | 2 replicas, readiness/liveness probes em `/:3000`, resource requests/limits, securityContext non-root, drop ALL capabilities, readOnlyRootFilesystem, volumes emptyDir para `/tmp` e `/app/.next/cache`, imagePullPolicy IfNotPresent, standard labels |
| Frontend Service | `frontend-service.yaml` | ClusterIP, porta 3000 |
| Frontend PDB | `frontend-pdb.yaml` | `minAvailable: 1` |

> **Nota sobre imagens no base**: Os Deployments no `base/` referenciam imagens com tag fixa (ex: `v1.0`). O overlay de producao sobrescreve essas tags via bloco `images` no `kustomization.yaml`. Isso garante que o `base/` funcione standalone para testes locais (`kustomize build kubernetes/base/`).

---

## Justificativa

### 1. Kustomize ao inves de Helm

Para o escopo deste projeto (2 aplicacoes, 1 ambiente, manifests relativamente simples), Kustomize e a escolha superior:

| Aspecto | Kustomize | Helm |
|---|---|---|
| Complexidade | YAML puro + patches | Templates Go + values.yaml + chart structure |
| Curva de aprendizado | Baixa -- conhecimento de YAML e suficiente | Media -- requer entender template syntax, helpers, hooks |
| Suporte ArgoCD | Nativo (built-in) | Nativo, mas com complexidade adicional (values files, hooks) |
| Debugging | `kustomize build` mostra o YAML final | `helm template` mostra YAML, mas erros de template sao crpticos |
| Manutenibilidade | Manifests sao YAML valido -- qualquer ferramenta YAML funciona | Templates nao sao YAML valido -- ferramentas de linting nao funcionam |
| Reutilizacao | Base + overlays para variantes | Charts empacotaveis e versionaveis |
| Ecosistema | Parte do kubectl (`kubectl apply -k`) | Repositorio de charts, dependency management |

**Decisao**: Kustomize. Para 2 apps com 1 ambiente, Helm adicionaria complexidade (chart boilerplate, templates, helpers, hooks) sem beneficio. Kustomize mantem os manifests como YAML puro, legivel e validavel.

### 2. `kustomize edit set image` ao inves de sed/yq/envsubst

| Ferramenta | Abordagem | Problemas |
|---|---|---|
| `sed` | Text replacement (`sed -i "s/old-tag/new-tag/"`) | Fragil: nao entende YAML, pode quebrar com mudancas de formatacao, multiplas ocorrencias, ou caracteres especiais na tag |
| `yq` | YAML-aware update | Funciona, mas exige instalacao adicional e path YAML exato (`yq '.spec.template.spec.containers[0].image = ...'`). Mudancas na estrutura do manifest quebram o comando |
| `envsubst` | Substituicao de variaveis de ambiente | Exige templates com placeholders (`${IMAGE_TAG}`), transforma YAML em templates, nao e idempotente |
| `kustomize edit set image` | Atualizacao semantica | Entende o conceito de "imagem de container", encontra automaticamente onde aplicar, preserva formatacao, e idempotente |

**Decisao**: `kustomize edit set image`. E a unica abordagem que:
- Entende semanticamente o que e uma imagem de container
- Nao depende da posicao ou formatacao do campo `image` nos manifests
- E idempotente (pode ser executada multiplas vezes com o mesmo resultado)
- Faz parte do proprio Kustomize (sem dependencia adicional)

### 3. Overlay `production` ao inves de patches inline

O overlay de producao usa o mecanismo `images` do Kustomize (que e um transformer built-in) ao inves de patches JSON ou strategic merge patches:

```yaml
# Abordagem USADA — images transformer (simples, semantica)
images:
  - name: 968225077300.dkr.ecr.us-east-1.amazonaws.com/workshop-backend
    newTag: abc1234

# Abordagem DESCARTADA — strategic merge patch (verbosa, fragil)
patches:
  - target:
      kind: Deployment
      name: workshop-backend
    patch: |
      - op: replace
        path: /spec/template/spec/containers/0/image
        value: 968225077300.dkr.ecr.us-east-1.amazonaws.com/workshop-backend:abc1234
```

O transformer `images` e mais simples, menos propenso a erros, e automaticamente encontra todos os containers que usam a imagem especificada.

---

## Alternativas Consideradas

### Por que nao Helm

- **Descartado porque**: Para 2 aplicacoes com 1 ambiente, Helm adiciona overhead significativo sem beneficio proporcional. A chart structure (`Chart.yaml`, `values.yaml`, `templates/`, `helpers.tpl`) triplica o numero de arquivos. O template syntax (`{{ .Values.image.tag }}`) transforma YAML valido em templates que nao podem ser validados por ferramentas YAML padrao. Os participantes do workshop precisariam aprender Go template syntax alem de YAML/Kubernetes.
- **Quando reconsiderar**: Se o projeto crescer para 5+ aplicacoes, multiplos ambientes (dev, staging, production), ou precisar de features como chart dependencies, hooks, ou rollback nativo do Helm.

### Por que nao YAML puro sem Kustomize

- **Descartado porque**: Sem Kustomize, cada ambiente exigiria uma copia completa dos manifests (duplicacao). Atualizar tags de imagem exigiria `sed` ou `yq` (fragil). ArgoCD suportaria, mas sem a semantica de overlays para diferenciar ambientes.
- **Quando reconsiderar**: Nunca, dado que Kustomize e parte do kubectl (`kubectl apply -k`) e nao adiciona dependencia externa.

### Por que nao sed/yq para atualizar tags no pipeline

- **Descartado porque**: `sed` e text replacement puro -- nao entende YAML e pode quebrar formatacao, multiplas ocorrencias, ou imagens com caracteres especiais na tag. `yq` e YAML-aware mas depende do path exato no YAML (`spec.template.spec.containers[0].image`), que quebra se a estrutura mudar. `kustomize edit set image` e semantico, idempotente, e built-in.
- **Quando reconsiderar**: Nunca. `kustomize edit set image` e estritamente superior.

### Por que nao ArgoCD Image Updater

- **Descartado porque**: O ArgoCD Image Updater monitora registries (ECR) e atualiza automaticamente as tags de imagem. Embora poderoso, adiciona um componente extra no cluster, requer configuracao de credenciais ECR no ArgoCD, e torna o fluxo menos explicito (a atualizacao de tag nao aparece como commit no Git). Para um workshop, o fluxo explicito (pipeline -> git commit -> ArgoCD sync) e mais didatico e rastreavel.
- **Quando reconsiderar**: Para producao com muitos microservicos onde o commit-back pattern (pipeline faz git push) se torna um gargalo.

---

## Riscos e Trade-offs

| Risco | Mitigacao | Severidade |
|---|---|---|
| Tag `latest` no overlay initial | Sera substituida pelo primeiro run do pipeline com git short SHA. ADR-007 garante que o pipeline nunca usa `latest` | Media (temporario) |
| Overlay de producao com tag desatualizada | ArgoCD detecta drift entre Git e cluster automaticamente (ADR-006, `selfHeal: true`) | Baixa (mitigada) |
| Conflito de merge no kustomization.yaml (race condition) | Pipeline faz `git pull --rebase` antes do push. Detalhado no ADR-007 | Media (mitigada) |
| Base com imagem tag hard-coded (`v1.0`) | Nao impacta producao -- overlay sobrescreve. Base e para referencia e testes locais | Baixa (aceita) |
| Kustomize version drift entre local e pipeline | GitHub Actions usa `kustomize` instalado via action padrao. Fixar versao no workflow se necessario | Baixa (aceita) |

### Trade-off aceito: Simplicidade vs. Flexibilidade

Kustomize sem Helm significa que nao temos chart versioning, dependency management, ou repositorio de charts reutilizaveis. Para 2 apps com 1 ambiente, essa flexibilidade nao e necessaria. Se o projeto crescer significativamente, migrar para Helm sera necessario, mas os manifests base do Kustomize sao YAML puro e podem ser convertidos em templates Helm com esforco minimo.

### Trade-off aceito: Single overlay vs. Multi-environment

Atualmente so existe `overlays/production/`. Se futuramente forem necessarios ambientes adicionais (staging, dev), basta criar novos diretorios de overlay (ex: `overlays/staging/`) com seus proprios `kustomization.yaml`. A estrutura base + overlays do Kustomize suporta isso nativamente.

---

## Conformidade com Convencoes do Projeto

Checklist de validacao contra `.claude/rules/kubernetes-manifests.md`:

- [x] Deployments tem `replicas: 2` ou mais
- [x] PodDisruptionBudget existe para cada Deployment (`backend-pdb.yaml`, `frontend-pdb.yaml`)
- [x] `readinessProbe` definido em cada container
- [x] `livenessProbe` definido em cada container
- [x] `resources.requests` e `resources.limits` definidos para CPU e memoria
- [x] `securityContext` do pod tem `runAsNonRoot: true`
- [x] `securityContext` do container tem `allowPrivilegeEscalation: false`
- [x] Tags de imagem versionadas no base (overlay atualiza via `newTag`)
- [x] `imagePullPolicy: IfNotPresent` em cada container
- [x] Labels padrao (`app`, `version`, `environment`) presentes
- [x] Capabilities dropped com `drop: ALL`

---

## Proximos Passos

1. **Atualizar tags iniciais** no overlay de producao apos o primeiro push de imagem pelo pipeline (substituir `latest` por git short SHA).
2. **Instalar ArgoCD** no cluster (ADR-006) e apontar para `kubernetes/overlays/production/`.
3. **Configurar GitHub Actions** (ADR-007) com o comando `kustomize edit set image` no pipeline.
4. **Validar o fluxo end-to-end**: push de codigo -> build de imagem -> update de tag -> ArgoCD sync.

---

## Revisao Recomendada

Reavaliar esta decisao quando:

- O projeto crescer para 5+ aplicacoes (considerar Helm para chart reuse e dependency management).
- Multiplos ambientes forem necessarios (staging, dev) -- a estrutura de overlays suporta isso nativamente, mas avaliar se Helm values files seriam mais praticos.
- O commit-back pattern se tornar gargalo (considerar ArgoCD Image Updater).
- A equipe precisar de chart versioning e repositorio de artifacts (considerar Helm + ChartMuseum/OCI).
