# Variáveis de Ambiente e Segurança

## Visão Geral

Este documento detalha o uso de **variáveis de ambiente** para configuração segura e flexível do ambiente, evitando hardcoding de valores sensíveis e facilitando a portabilidade entre ambientes.

---

## Estratégia de Variáveis de Ambiente

### Arquivo .env

O projeto utiliza um arquivo `.env` para gerenciar variáveis de ambiente:

```bash
# Criar arquivo .env baseado no exemplo
cp .env.example .env

# Editar conforme necessário
nano .env
```

**⚠️ IMPORTANTE:** O arquivo `.env` está no `.gitignore` e **não deve ser versionado**.

---

## Variáveis Disponíveis

### Imagens Docker

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `OPEN5GS_IMAGE` | `gradiant/open5gs:2.7.6` | Imagem do Open5GS |
| `MONGODB_IMAGE` | `mongo:7.0` | Imagem do MongoDB |
| `UERANSIM_IMAGE` | `gradiant/ueransim:3.2.6` | Imagem do UERANSIM |
| `DN_IMAGE` | `alpine:latest` | Imagem da Data Network |

**Uso:**
```bash
# docker-compose.yml
image: ${OPEN5GS_IMAGE:-gradiant/open5gs:2.7.6}
```

### Configurações Gerais

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `TZ` | `America/Recife` | Timezone do sistema |

### Configurações do MongoDB

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `MONGO_INITDB_DATABASE` | `open5gs` | Nome do banco de dados inicial |
| `MONGO_INITDB_ROOT_USERNAME` | - | Usuário root (opcional) |
| `MONGO_INITDB_ROOT_PASSWORD` | - | Senha root (opcional) |

**Exemplo:**
```bash
# .env
MONGO_INITDB_DATABASE=open5gs
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=senha_segura_aqui
```

### Configurações da UPF

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `IPV4_TUN_ADDR` | `10.60.0.1/17` | Endereço TUN da UPF-A |
| `IPV4_TUN_SUBNET` | `10.60.0.0/17` | Subnet para IPs dos UEs |
| `ENABLE_NAT` | `true` | Habilitar NAT na UPF |

### Configurações do UERANSIM

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `MCC` | `001` | Mobile Country Code |
| `MNC` | `01` | Mobile Network Code |
| `TAC` | `7` | Tracking Area Code |
| `AMF_HOSTNAME` | `amf` | Hostname do AMF |
| `GNB_HOSTNAME` | `ueransim-gnb` | Hostname do gNB |

---

## Segurança

### Boas Práticas Implementadas

#### 1. Credenciais Não Hardcoded

✅ **Nunca** incluir senhas no código-fonte  
✅ Usar variáveis de ambiente para credenciais  
✅ Arquivo `.env` no `.gitignore`

**Exemplo:**
```yaml
# ❌ ERRADO (hardcoded)
environment:
  - MONGO_INITDB_ROOT_PASSWORD=senha123

# ✅ CORRETO (variável de ambiente)
environment:
  - MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}
```

#### 2. Usuário Específico para Aplicação

✅ MongoDB não usa exclusivamente o usuário `root`  
✅ Usuário `open5gs` criado com permissões específicas  
✅ Acesso restrito ao banco `open5gs`

**Configuração:**
```javascript
// Script de inicialização do MongoDB
db.createUser({
  user: 'open5gs',
  pwd: 'open5gs',
  roles: [{ role: 'readWrite', db: 'open5gs' }]
});
```

#### 3. Isolamento de Rede

✅ MongoDB acessível apenas na rede `net-sbi`  
✅ Sem exposição de portas para o host  
✅ Comunicação apenas entre containers autorizados

#### 4. Arquivo .env.example

✅ Template fornecido sem valores sensíveis  
✅ Documentação de todas as variáveis  
✅ Instruções claras de uso

---

## Gerenciamento de Secrets

### Opção 1: Arquivo .env (Desenvolvimento)

```bash
# .env
MONGO_INITDB_ROOT_PASSWORD=senha_segura
```

**Vantagens:**
- ✅ Simples e rápido
- ✅ Fácil de usar em desenvolvimento

**Desvantagens:**
- ❌ Não recomendado para produção
- ❌ Arquivo no sistema de arquivos

### Opção 2: Docker Secrets (Produção)

```yaml
# docker-compose.yml
services:
  mongodb:
    secrets:
      - mongo_root_password
    environment:
      - MONGO_INITDB_ROOT_PASSWORD_FILE=/run/secrets/mongo_root_password

secrets:
  mongo_root_password:
    file: ./secrets/mongo_root_password.txt
```

**Vantagens:**
- ✅ Mais seguro
- ✅ Integrado ao Docker

**Desvantagens:**
- ❌ Mais complexo
- ❌ Requer Docker Swarm (ou compatível)

### Opção 3: HashiCorp Vault (Produção Avançada)

```bash
# Obter secret do Vault
export MONGO_PASSWORD=$(vault kv get -field=password secret/mongodb)
```

**Vantagens:**
- ✅ Muito seguro
- ✅ Rotação de credenciais
- ✅ Auditoria

**Desvantagens:**
- ❌ Requer infraestrutura adicional
- ❌ Mais complexo

---

## Validação de Variáveis

### Script de Validação

```bash
#!/bin/bash
# scripts/validate-env.sh

REQUIRED_VARS=(
  "OPEN5GS_IMAGE"
  "MONGODB_IMAGE"
)

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ Variável $var não está definida"
    exit 1
  fi
done

echo "✅ Todas as variáveis necessárias estão definidas"
```

### Verificar Variáveis Carregadas

```bash
# Ver variáveis do Docker Compose
docker compose config | grep -E "^\s+-.*="

# Ver variáveis de um serviço específico
docker compose exec mongodb env | grep MONGO
```

---

## Troubleshooting

### Variável não está sendo carregada

**Problema:** Variável de ambiente não está sendo aplicada.

**Solução:**
1. Verificar se arquivo `.env` existe:
   ```bash
   ls -la .env
   ```

2. Verificar sintaxe do `.env`:
   ```bash
   # Sem espaços ao redor do =
   CORRETO: VAR=value
   ERRADO: VAR = value
   ```

3. Recarregar variáveis:
   ```bash
   docker compose down
   docker compose up -d
   ```

### Credenciais expostas

**Problema:** Credenciais aparecem em logs ou código.

**Solução:**
1. Verificar `.gitignore`:
   ```bash
   grep .env .gitignore
   ```

2. Remover do histórico Git (se necessário):
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch .env" \
     --prune-empty --tag-name-filter cat -- --all
   ```

3. Rotacionar credenciais:
   ```bash
   # Gerar nova senha
   openssl rand -base64 32
   ```

---

## Referências

- [Docker Compose Environment Variables](https://docs.docker.com/compose/environment-variables/)
- [12-Factor App - Config](https://12factor.net/config)
- [OWASP - Secrets Management](https://owasp.org/www-community/vulnerabilities/Use_of_hard-coded_cryptographic_key)

---

**Última Atualização:** 2026-01-16

