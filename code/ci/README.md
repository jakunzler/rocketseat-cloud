# 🚀 CI/CD Workflow com GitHub Actions

Este repositório utiliza um pipeline de **Integração Contínua (CI)** com **GitHub Actions** para garantir a qualidade e a consistência do código localizado em `code/ci/`. Abaixo está uma descrição passo a passo das etapas do workflow definidas no arquivo `.github/workflows/ci.yml`.

## 📦 Disparo do Workflow

O pipeline é executado automaticamente nas seguintes situações:

- A cada `push` na branch `main` que altere arquivos dentro da pasta `code/ci/`
- A cada `pull_request` direcionado para a branch `main`

---

## 🧪 Etapas do CI

### 1. **Checkout do código**

Utiliza a ação `actions/checkout@v4` para clonar o repositório no ambiente do GitHub Actions runner.

```yaml
- name: Checkout code
  uses: actions/checkout@v4
```

---

### 2. **Configuração do Node.js**

Usa `actions/setup-node@v4` para configurar diferentes versões do Node.js (22 e 23) e habilita o cache do `yarn` com base no `yarn.lock` localizado em `code/ci/`.

```yaml
- name: Set up Node.js | ${{ matrix.node-version }}
  uses: actions/setup-node@v4
  with:
    node-version: ${{ matrix.node-version }}
    cache: 'yarn'
    cache-dependency-path: code/ci/yarn.lock
```

> 💡 Essa etapa é executada para cada versão definida na matriz (`node-version: [22, 23]`).

---

### 3. **Instalação de dependências**

Executa `yarn install` dentro da pasta `code/ci/`.

```yaml
- run: 'yarn'
  working-directory: code/ci
```

---

### 4. **Execução dos testes automatizados**

Executa os testes definidos no projeto, também na pasta `code/ci/`.

```yaml
- run: 'yarn run test'
  working-directory: code/ci
```

---

### 5. **Build da imagem Docker**

Cria uma imagem Docker localmente a partir do `Dockerfile` localizado em `code/ci/`.

```yaml
- name: Build docker image
  run: |
    docker build -t rocketseat-ci-api:latest code/ci
```

---

## 📌 Resumo

Este pipeline automatizado ajuda a garantir que o projeto esteja:

- Testado em múltiplas versões do Node.js
- Com dependências validadas e cache eficiente
- Preparado para produção com build Docker funcional
