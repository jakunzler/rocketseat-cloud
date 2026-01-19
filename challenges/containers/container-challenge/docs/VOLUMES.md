# Volumes e Persistência de Dados

## Visão Geral

Este documento detalha a estratégia de **persistência de dados** implementada no projeto, utilizando **volumes Docker** para garantir que os dados não sejam perdidos ao reiniciar ou recriar containers.

---

## Volumes Configurados

### Volumes Nomeados

O projeto utiliza **volumes nomeados** do Docker para persistência:

```yaml
volumes:
  mongodb-data:      # Dados do MongoDB
  mongodb-config:    # Configurações do MongoDB
```

### Estrutura de Volumes

#### 1. `mongodb-data`
- **Caminho no container:** `/data/db`
- **Tipo:** Volume nomeado
- **Conteúdo:**
  - Coleções do banco de dados
  - Índices
  - Dados de assinantes (subscribers)
  - Metadados do MongoDB

#### 2. `mongodb-config`
- **Caminho no container:** `/data/configdb`
- **Tipo:** Volume nomeado
- **Conteúdo:**
  - Configurações do MongoDB
  - Scripts de inicialização

### Volumes Bind Mount (Logs)

Além dos volumes nomeados, o projeto utiliza **bind mounts** para logs:

```
logs/
├── amf/              # Logs do AMF
├── smf/              # Logs do SMF
├── upf/              # Logs da UPF
├── ueransim/         # Logs do UERANSIM
└── ...
```

**Benefícios:**
- ✅ Logs acessíveis diretamente do host
- ✅ Facilita troubleshooting
- ✅ Permite análise de logs sem entrar no container

---

## Gerenciamento de Volumes

### Listar Volumes

```bash
# Listar todos os volumes
docker volume ls

# Listar volumes do projeto
docker volume ls | grep container-challenge
```

### Inspecionar Volume

```bash
# Inspecionar volume específico
docker volume inspect container-challenge_mongodb-data

# Ver localização no host
docker volume inspect container-challenge_mongodb-data --format '{{ .Mountpoint }}'
```

### Verificar Tamanho dos Volumes

```bash
# Ver tamanho de um volume
docker system df -v | grep mongodb-data
```

### Backup de Volumes

#### Backup do MongoDB

```bash
# Criar backup
docker run --rm \
  -v container-challenge_mongodb-data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/mongodb-$(date +%Y%m%d).tar.gz /data

# Restaurar backup
docker run --rm \
  -v container-challenge_mongodb-data:/data \
  -v $(pwd)/backups:/backup \
  alpine sh -c "cd /data && tar xzf /backup/mongodb-20260116.tar.gz"
```

### Remover Volumes

#### Remover Volume Específico

```bash
# Parar serviços primeiro
docker compose down

# Remover volume
docker volume rm container-challenge_mongodb-data
```

#### Remover Todos os Volumes do Projeto

```bash
# Usar script down.sh com flag --volumes
./scripts/down.sh --volumes

# Ou manualmente
docker compose down -v
```

**⚠️ ATENÇÃO:** Remover volumes apaga TODOS os dados persistidos!

---

## Persistência de Dados

### Dados Persistidos

#### MongoDB
- ✅ **Subscribers:** Dados de assinantes (IMSI, chaves, slices)
- ✅ **Configurações:** Configurações do banco
- ✅ **Índices:** Índices criados para otimização

#### Logs
- ✅ **Logs de serviços:** Histórico de operações
- ✅ **Logs de erros:** Troubleshooting
- ✅ **Logs de acesso:** Auditoria

### Dados NÃO Persistidos

- ❌ **Estado dos containers:** Recriados a cada `docker compose up`
- ❌ **Redes:** Recriadas a cada inicialização
- ❌ **IPs dinâmicos:** Podem mudar entre reinicializações

---

## Boas Práticas

### 1. Backup Regular

```bash
# Script de backup automático (exemplo)
#!/bin/bash
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

docker run --rm \
  -v container-challenge_mongodb-data:/data \
  -v "$BACKUP_DIR:/backup" \
  alpine tar czf "/backup/mongodb-$DATE.tar.gz" /data

echo "Backup criado: $BACKUP_DIR/mongodb-$DATE.tar.gz"
```

### 2. Verificação de Integridade

```bash
# Verificar se volume está montado corretamente
docker compose exec mongodb ls -la /data/db

# Verificar dados
docker compose exec mongodb mongosh open5gs --eval "db.subscribers.countDocuments()"
```

### 3. Limpeza de Logs

```bash
# Limpar logs antigos (manter últimos 7 dias)
find logs/ -name "*.log" -mtime +7 -delete
```

---

## Troubleshooting

### Volume não persiste dados

**Problema:** Dados são perdidos após reiniciar containers.

**Solução:**
1. Verificar se volume está montado:
   ```bash
   docker compose exec mongodb ls -la /data/db
   ```

2. Verificar se volume existe:
   ```bash
   docker volume inspect container-challenge_mongodb-data
   ```

3. Verificar permissões:
   ```bash
   docker compose exec mongodb ls -ld /data/db
   ```

### Volume muito grande

**Problema:** Volume ocupando muito espaço.

**Solução:**
1. Verificar tamanho:
   ```bash
   docker system df -v
   ```

2. Limpar dados não utilizados:
   ```bash
   docker compose exec mongodb mongosh open5gs --eval "db.subscribers.deleteMany({})"
   ```

3. Compactar banco:
   ```bash
   docker compose exec mongodb mongosh open5gs --eval "db.runCommand({compact: 'subscribers'})"
   ```

### Erro de permissão

**Problema:** Container não consegue escrever no volume.

**Solução:**
1. Verificar propriedade do diretório:
   ```bash
   docker volume inspect container-challenge_mongodb-data --format '{{ .Mountpoint }}' | xargs ls -ld
   ```

2. Ajustar permissões (se necessário):
   ```bash
   sudo chown -R 999:999 $(docker volume inspect container-challenge_mongodb-data --format '{{ .Mountpoint }}')
   ```

---

## Referências

- [Docker Volumes Documentation](https://docs.docker.com/storage/volumes/)
- [MongoDB Data Persistence](https://www.mongodb.com/docs/manual/core/persistence/)
- [Docker Compose Volumes](https://docs.docker.com/compose/compose-file/compose-file-v3/#volumes)

---

**Última Atualização:** 2026-01-16

