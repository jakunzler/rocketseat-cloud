# Configuração de Ambiente com Docker Compose

## Visão Geral do Projeto

Este desafio tem como objetivo consolidar os conhecimentos adquiridos sobre **Dockerfile**, **Docker Compose**, **redes** e **volumes**. A proposta consiste em configurar um **ambiente multi-container** para uma aplicação de sua escolha, explorando boas práticas de conteinerização e o uso de **variáveis de ambiente** para uma configuração flexível e segura.

---

## Objetivos

- Configurar um ambiente multi-container funcional utilizando Docker Compose.
- Garantir a persistência de dados por meio do uso adequado de volumes.
- Utilizar variáveis de ambiente para configuração segura e flexível da aplicação.
- Implementar boas práticas de segurança no acesso ao banco de dados.
- Produzir uma documentação clara e completa do ambiente configurado.

---

## Estrutura, Regras e Requisitos do Projeto

### Etapas de Implementação

#### 1. Criação do Dockerfile

- Desenvolver um arquivo `Dockerfile` para a aplicação escolhida.
- Utilizar uma imagem base adequada à linguagem e ao framework da aplicação.
- Adotar boas práticas, como:
  - Uso de imagens **Alpine**;
  - Construção em **múltiplos estágios** (*multi-stage build*), quando aplicável.

---

#### 2. Definição do Docker Compose

- Criar um arquivo `docker-compose.yml`.
- Configurar **no mínimo dois serviços**:
  - Serviço da aplicação;
  - Serviço de banco de dados (ex.: MySQL, PostgreSQL, MongoDB, entre outros).

---

#### 3. Configuração de Volumes

- Configurar volumes para garantir a **persistência dos dados** do banco de dados.
- Evitar a perda de informações em reinicializações ou recriação dos containers.

---

#### 4. Criação de Rede Customizada

- Criar uma **rede Docker customizada**.
- Garantir comunicação isolada e segura entre os containers do ambiente.

---

#### 5. Utilização de Variáveis de Ambiente

- Utilizar variáveis de ambiente para configurar:
  - URLs de conexão com o banco de dados;
  - Credenciais de acesso;
  - Chaves e parâmetros sensíveis da aplicação.
- Evitar a inclusão de dados sensíveis diretamente no código-fonte.

---

#### 6. Documentação

- Documentar todo o processo de configuração no arquivo `README.md`.
- A documentação deve incluir:
  - Instruções para build e execução dos containers;
  - Configuração das variáveis de ambiente;
  - Procedimentos para testar a comunicação entre a aplicação e o banco de dados.

---

## Informações Adicionais

- A aplicação pode ser desenvolvida em **qualquer linguagem de programação**.
- O banco de dados **não deve ser configurado exclusivamente com o usuário `root`**:
  - Crie um usuário específico para a aplicação;
  - Conceda apenas as permissões necessárias.
- Para gerenciamento seguro de variáveis de ambiente, podem ser utilizadas ferramentas como:
  - Scripts Bash;
  - HashiCorp Vault;
  - Outras soluções equivalentes.
- Evite hardcoding de valores sensíveis ou configurações específicas de ambiente no código.

---

## Resultados Esperados

- Ambiente multi-container funcional utilizando Docker Compose.
- Persistência de dados corretamente implementada por meio de volumes.
- Uso adequado de variáveis de ambiente para gerenciamento de configurações sensíveis.
- Estratégia de segurança aplicada ao acesso ao banco de dados, evitando o uso exclusivo do usuário `root`.
- Documentação clara, organizada e tecnicamente consistente no arquivo `README.md`.
