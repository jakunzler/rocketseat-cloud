# Documentação da pipeline CI/CD

## Visão geral

A pipeline [`ci-cd.yml`](../.github/workflows/ci-cd.yml) automatiza:

1. **Qualidade** — testes unitários da API (`app/`)
2. **Infraestrutura + imagem (dev)** — ECR, build Docker, `terraform apply` com `image_uri`
3. **Confiança** — health check HTTP em `/health` no URL do App Runner dev
4. **Produção** — mesmo fluxo para o ambiente `prod`, somente se o passo 3 passar

Em **pull requests**, apenas `test` e `terraform plan` (matriz dev/prod) rodam — sem deploy.

## Jobs

| Job | Quando | Função |
|-----|--------|--------|
| `test` | PR e push | `npm test` + lint no diretório `app` |
| `terraform-plan` | PR | `terraform plan` em dev e prod |
| `deploy-dev` | push `main` | ECR target → build/push → apply App Runner dev |
| `health-check-dev` | após deploy-dev | Script `scripts/health-check.sh` (30 tentativas, 10s) |
| `deploy-prod` | após health OK | ECR prod → build/push → apply App Runner prod |

## Decisões de projeto

### Por que Terraform + build na mesma pipeline?

- O desafio pede **IaC** para App Runner, variáveis de ambiente e IAM.
- A **imagem** muda a cada commit; a pipeline passa `-var=image_uri=...` no `apply`, mantendo o estado no Terraform e evitando drift manual.

### Por que `-target` no ECR?

Na primeira execução, o repositório ECR precisa existir antes do `docker push`. O target `module.apprunner.aws_ecr_repository.app` cria só o ECR; o `apply` completo atualiza o serviço com a imagem nova.

### Health check antes de prod

- Reduz risco de promover build quebrada.
- Usa o endpoint `/health` exposto pela API (mesmo path configurado no `health_check_configuration` do App Runner).

### OIDC vs access keys

O workflow usa `aws-actions/configure-aws-credentials` com `role-to-assume`. Configure o provedor OIDC no IAM (`token.actions.githubusercontent.com`) e restrinja a role ao repositório/branch.

## Variáveis de ambiente (runtime)

Definidas no Terraform por ambiente:

| Variável | dev | prod |
|----------|-----|------|
| `APP_ENV` | `dev` | `prod` |
| `NODE_ENV` | `development` | `production` |
| `EXTERNAL_API_URL` | configurável (`variables.tf`) | idem |

Segredos (ex.: `API_KEY`): use `runtime_environment_secrets` no módulo `apprunner` com ARN do Secrets Manager — **não** coloque o valor no GitHub em texto plano.

## Outputs Terraform úteis

- `service_url` — URL HTTPS do App Runner (usado no health check)
- `ecr_repository_url` — base do registry para push manual
- `apprunner_access_role_arn` — role de acesso ao ECR (auditoria)

## Troubleshooting

| Sintoma | Ação |
|---------|------|
| `AccessDenied` no ECR | Verifique permissões da role OIDC (ECR + App Runner) |
| Health check timeout | App Runner pode levar alguns minutos; aumente `HEALTH_CHECK_ATTEMPTS` no script |
| Plan falha no PR | Confirme `AWS_ROLE_ARN` e `AWS_REGION` nos secrets |
| Paths não disparam workflow | Confirme alteração sob `challenges/ci-cd/ci-cd-challenge/**` ou ajuste `paths` no YAML |
