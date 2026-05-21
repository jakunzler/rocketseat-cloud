# **Desafio: Implantação de uma API e Banco de Dados no Kubernetes**

## **Introdução**

Neste desafio, você irá consolidar os conhecimentos adquiridos sobre Kubernetes, implementando uma **aplicação e conectada a um banco de dados** rodando tudo em um cluster Kubernetes. O objetivo é que você utilize recursos como Deployments, Services, ConfigMaps, Persistent Volumes (PV/PVC), e probes (*liveness* e *readiness*), além de explorar estratégias de escalonamento automático (*Horizontal Pod Autoscaler - HPA*).

Este desafio simula um cenário real, onde você precisa configurar e gerenciar dois componentes principais:

- **Aplicação (API)**: uma aplicação backend (ex.: Node.js, Python, etc.) que realiza operações no banco de dados.
- **Banco de Dados**: um banco de dados relacional (ex.: MySQL ou PostgreSQL) configurado no cluster.

Ao final, você também implementará observabilidade básica para monitorar o comportamento do cluster e verificar a integração entre os dois serviços.

---

## **Tarefas**

1. **Configuração do Cluster Kubernetes:**
    - Configure um cluster Kubernetes local utilizando Kind ou Minikube.
    - Crie um namespace chamado `desafio-api`para isolar os recursos da aplicação e um namespace chamado `desafio-db` para os recursos do banco de dados.
2. **Criação de Deployments:**
    - Configure dois Deployments:
        - Um Deployment para a **API**.
        - Um Deployment para o **Banco de Dados** (ex.: MySQL, PostgreSQL ou MongoDB).
    - Ambos os Deployments devem ter **1 réplica inicial**, podendo ser escalados posteriormente com HPA.
    - Adicione *livenessProbe* e *readinessProbe* ao Deployment da API para verificar a saúde e prontidão da aplicação.
    - No Deployment do Banco de Dados, configure secrets para definir as credenciais de acesso (usuário, senha, etc…).
3. **Configuração de Services:**
    - Crie dois Services para expor os Deployments:
        - Um Service do tipo `ClusterIP` para o banco de dados, permitindo que a API se conecte a ele.
        - Um Service do tipo `ClusterIP` para a API, permitindo que outros componentes no cluster se comuniquem com ela (opcional, se necessário).
4. **Persistência de Dados com PVC:**
    - Configure um Persistent Volume (PV) e um Persistent Volume Claim (PVC) para armazenar os dados do banco de forma persistente.
    - Monte o PVC no Deployment do banco de dados para garantir que as informações persistam mesmo que o pod seja reiniciado.
    - Certifique-se de que o banco de dados use esse diretório montado para armazenar seus dados.
5. **Configuração da API para Conexão com o Banco de Dados:**
    - Utilize um ConfigMap ou Secret para armazenar a string de conexão ou variáveis relacionadas ao banco de dados, como host, porta e nome do banco.
    - Configure o Deployment da API para consumir essas informações através de variáveis de ambiente injetadas pelo ConfigMap ou Secret.
    - Certifique-se de que a API esteja funcionando corretamente e conectada ao banco.
6. **Escalonamento Automático com HPA:**
    - Configure o *Horizontal Pod Autoscaler (HPA)* para o Deployment da API, para escalar automaticamente com base na utilização de CPU. Defina um intervalo entre **50% e 80% de utilização de CPU** como limite para escalonamento.
    - Habilite o *Metric Server* no cluster para coletar métricas.
7. **Testes de Integração:**
    - Após configurar os Deployments e Services, crie uma rota simples na API que permita testar a integração com o banco. Exemplo:
        - Um endpoint GET `/status` que verifica a conectividade com o banco e retorna "Conexão OK".
        - Um endpoint POST `/dados` que insere informações no banco de dados.
8. **Observabilidade:**
    - Implemente uma solução básica de observabilidade para monitorar os pods:
        - Use `kubectl logs` para inspecionar os logs gerados pela API e pelo banco de dados.
        - Use `kubectl top pod` para verificar as métricas de CPU e memória.
        - (Opcional) Configure uma ferramenta de monitoramento, para coletar métricas de desempenho.
9. **Documentação:**
    - Crie um arquivo `README.md` detalhando:
        - Passo a passo para configurar o cluster e aplicar os manifestos do Kubernetes.
        - Estrutura dos recursos criados (Deployments, Services, PV/PVC, ConfigMaps, HPA, etc.).
        - Comandos utilizados para verificar o status dos pods, logs e métricas.
        - Instruções para testar a integração entre a API e o banco de dados.

---

## **Desafios Adicionais** *(Para quem quer ir além!)*

- Configure um Service do tipo `NodePort` para expor a API fora do cluster e permitir o acesso via navegador ou cliente HTTP (Postman, cURL, etc.) sem a utilização de um PortFoward.
- Configure o banco de dados com diferentes usuários e níveis de permissão, garantindo que a API utilize apenas as permissões necessárias.
- Simule um aumento de carga na API para validar o funcionamento do HPA e registre os resultados observados.
- Adicione um endpoint na API que liste os dados armazenados no banco, mostrando as informações persistidas.
- Configure uma estratégia de *Rolling Update* no Deployment da API para atualizar a versão sem downtime.

---

## **Resultados Esperados**

Ao final do desafio, você deverá ter:

- Configurado e aplicado recursos do Kubernetes para uma API e um banco de dados (Deployments, Services, PV/PVC, ConfigMaps, HPA, etc.).
- Garantido persistência de dados no banco com o uso de PVCs.
- Validado a conectividade entre a API e o banco de dados.
- Implementado probes para validar a saúde e a prontidão da API.
- Entendimento sobre escalonamento automático com o HPA.
- Documentação clara e abrangente para que qualquer pessoa possa reproduzir o projeto.

---

## **Entrega**

Após concluir o desafio, você deve:

1. Enviar a URL do repositório no GitHub contendo os arquivos de configuração YAML e o README.md.
2. (Opcional) Faça um post no LinkedIn compartilhando o aprendizado, incluindo screenshots ou logs que demonstrem o funcionamento da aplicação e a integração com o banco de dados.

**Feito com 💜 por Rocketseat 👋**