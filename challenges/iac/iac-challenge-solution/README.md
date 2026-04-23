# Solução do desafio IaC (Terraform + Google Cloud Platform)

Infraestrutura multi-ambiente (**dev**, **staging**, **prod**) no **GCP** com **VPC** em modo custom, **sub-rede** privada com **Private Google Access**, **Cloud Router** + **Cloud NAT** (saída sem IP público nas VMs), **Managed Instance Group regional** (Debian 12 + nginx de exemplo), **balanceador HTTP regional** (`EXTERNAL_MANAGED`) e **Secret Manager** para credenciais (valor do segredo fora do Terraform).

## Arquitetura (visão geral)

| Recurso | Função |
|--------|--------|
| **Rede (módulo `network`)** | `google_compute_network` (custom), sub-rede privada das VMs, **sub-rede proxy-only** (`REGIONAL_MANAGED_PROXY`) exigida pelo L7 regional, roteador, NAT, logs de fluxo (amostra) |
| **VMs** | MIG regional, sem IP externo, tags para firewall, disco criptografado (PD), imagem **Debian 12** |
| **Balanceamento** | **Application Load Balancer** regional HTTP: `region_backend_service` (EXTERNAL\_MANAGED) → `region_url_map` → `region_target_http_proxy` → `forwarding_rule` (porta 80; regra **externa** — sem `network`/`subnetwork` no recurso) |
| **Escalamento** | `google_compute_region_autoscaler` (CPU 65% entre mín. e máx. de réplicas) |
| **Segurança** | Firewall: HTTP (80) apenas das faixas de health check do L7; SSH por CIDR; SA da aplicação com acesso a **Secret Manager**; escopos limitados a workload via `cloud-platform` (ajuste se quiser o modelo “least privilege” por API) |
| **APIs** | `google_project_service` habilita `compute` e `secretmanager` (idempotente) |

Cada ambiente em `environments/<env>/` é um **módulo raiz** com estado próprio; os módulos reutilizáveis ficam em `modules/`.

## Diferenças entre ambientes (padrão)

| | dev | staging | prod |
|---|-----|---------|------|
| **CIDR da sub-rede** | 10.0.0.0/20 | 10.1.0.0/20 | 10.2.0.0/20 |
| **Tipo de máquina** | e2-micro | e2-small | e2-standard-2 |
| **Réplicas (min / max)** | 1 / 2 | 1 / 4 | 2 / 6 |
| **Disco (GiB)** | 20 | 20 | 30 |
| **Variáveis de app (não sensíveis)** | `LOG_LEVEL=debug`, `APP_PROFILE=development` | `info` / `staging` | `warn` / `production` |
| **Origem SSH** | 0.0.0.0/0 (só estudo) | 0.0.0.0/0 (ajustar) | 10.255.255.0/32 (placeholder — **defina o seu** antes de produção) |

## Pré-requisitos

- Terraform ≥ 1.3, [google provider](https://registry.terraform.io/providers/hashicorp/google/latest) ~5.x  
- Projeto no GCP, faturamento ativo, permissões para criar Compute, Load Balancing, Secret Manager, IAM, APIs  
- Autenticação: `gcloud auth application-default login` ou `GOOGLE_APPLICATION_CREDENTIALS` (conta de serviço) — **não** commite chaves

## Ficheiro `.env` (não comitar)

1. Na raiz `iac-challenge-solution`, copie [`.env.example`](./.env.example) para **`.env`** (este nome está no [`.gitignore`](./.gitignore)).  
2. Preencha pelo menos `TF_VAR_project_id` com o **ID** real do projeto GCP. Opcionalmente `TF_VAR_region`, `TF_VAR_zone`, `TF_VAR_common_labels` (JSON numa linha), etc.  
3. Pode ainda colocar um **`.env`** em `environments/<env>/` para sobrescrever só nesse ambiente (carregado depois do da raiz).  
4. **Precedência no Terraform:** variáveis `TF_VAR_*` no ambiente têm **menor** precedência do que ficheiros `terraform.tfvars`. Por isso, os scripts `subir.sh` e `descer.sh` leem o `.env` e passam os valores com **`-var=...` na linha de comando** (máxima precedência), evitando conflito com ficheiros locais.  
5. **Alternativa:** crie `environments/<env>/terraform.tfvars` a partir de `terraform.tfvars.example` (também não versionado) e defina `project_id` aí. Não comite `terraform.tfvars` nem `.env` com o seu projeto.

**Credenciais:** em `.env` pode fazer `export GOOGLE_APPLICATION_CREDENTIALS=/caminho/para/sa.json` (ficheiro de chave **fora** do repositório).

## Uso

1. Com `.env` ou `terraform.tfvars` local configurado (ver acima), use os **scripts** a partir da raiz `iac-challenge-solution`:

   | Ação | Comando |
   |------|---------|
   | Criar / atualizar | `./scripts/subir.sh dev` (ou `staging`, `prod`) — executa `terraform init` e `apply -auto-approve` e mostra os outputs. |
   | Remover tudo | `./scripts/descer.sh dev` — pede confirmação antes de `terraform destroy` (ou `./scripts/descer.sh dev -y` sem prompt). |

3. **Sem os scripts** (defina o projeto, por exemplo: `source ../.env` a partir de `environments/dev` e depois `terraform apply -var=project_id=$TF_VAR_project_id`, ou use só `terraform.tfvars` local):

   ```bash
   cd challenges/iac/iac-challenge-solution/environments/dev
   terraform init
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

4. O output `http_url` mostra o endereço HTTP do balanceador (demo com nginx; **sem TLS**). Para produção, use **Google-managed SSL** (certificado) e listener 443.  
5. **Segredos:** se o módulo criar o `Secret` no Manager, o corpo do segredo **não** fica no código; após o `apply`, defina o valor com:

   ```bash
   echo -n '{"password":"seu-valor"}' | gcloud secrets versions add NOME_DO_SEGRETO --data-file=-
   ```

   Ou com `gcloud`/`Console`. O Terraform mantém o `google_secret_manager_secret_version` com `ignore_changes` no payload para evitar regravar o valor.  
6. Pode ainda derrubar com `./scripts/descer.sh <ambiente>`; ou `terraform destroy` no diretório do ambiente (cuidado com custo de NAT/ balanceador enquanto existirem).

## Segredos e boas práticas

- Prefira `TF_VAR_app_secret_id` (ou o nome equivalente) para apontar segredos **já** criados por pipeline.  
- Não versione `terraform.tfstate` com segredos em repositórios públicos; use **backend remoto** (GCS) com bloqueio (opcional) em times.  
- **SSH em produção:** restinja `ssh_ingress_cidr` ou use **IAP** (`35.235.240.0/20` em outra regra) com `gcloud compute ssh` e documentação de identidade.  
- Avalie **Shielded VM** e políticas de organização (OS Login, CMEK) conforme a política da empresa.  

## Estrutura

```
iac-challenge-solution/
  modules/
    network/   # VPC, sub-rede, router, NAT
    app/       # SA, template, MIG, autoscaler, firewall, HC, BE, URL map, proxy, FR, Secret
  environments/
    dev/ | staging/ | prod/
  .env.example  # copiar para .env (não comitar)
  scripts/
    subir.sh
    descer.sh
    lib/terraform-env.sh
  README.md
  .gitignore
```

Custo: NAT, balanceador, instâncias e tráfego geram cobrança. Remova o ambiente de teste quando não precisar.

### Migração: sub-rede `proxy` do módulo `network` para o módulo `app`

Se já tens no state `module.network.google_compute_subnetwork.proxy_only` e fazes `terraform plan` após atualizar o código, o plano pode mostrar *destroy* no `network` e *create* no `app` para a mesma sub-rede. Para evitar destruição/criação, a partir de `environments/<env>/` executa **uma** vez, antes de `apply`:

```bash
terraform state mv 'module.network.google_compute_subnetwork.proxy_only' 'module.app.google_compute_subnetwork.proxy_only'
```

Se o endereço antigo não existir (projeto novo), ignora o comando. Se falhar, verifica o state com `terraform state list` | `grep proxy`.
