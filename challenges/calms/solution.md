# 📋 Plano de Implementação de Práticas DevOps — Empresa Tech

## ✅ 1. Diagnóstico Cultural (C de CALMS)

### 📌 Processo escolhido: **Deploy**

- **Atual:** realizado manualmente, sem automação, pela equipe de operações.
- **Problemas identificados:**
  - Tempo médio de entrega até o deploy: **2 dias**
  - **80% de sucesso** nos deploys (20% falham).
  - **2 incidentes por semana**.
  - **MTTR (tempo médio de recuperação): 4 horas**
- **Atrito entre equipes:** operações tem que lidar com falhas que poderiam ser antecipadas pela dev; testes são manuais e em produção.

---

## ⚙️ 2. Automação (A de CALMS)

### 🔧 Solução proposta

- Implantar **CI/CD com GitHub Actions**.
- Automatizar:
  - Build, testes e lint do código.
  - Deploy contínuo para ambiente de staging.
  - Deploy controlado para produção via aprovação.

### 📌 Plano de Ação

1. Criar pipelines separados: `build`, `test`, `deploy-staging`, `deploy-prod`.
2. Adotar infraestrutura como código com **Terraform** para EC2, S3 e Lambda.
3. Implementar **pré-checks** automáticos antes do merge.
4. Utilizar ambientes isolados (`staging`/`prod`) com versionamento.

### 💡 Minimizar resistências

- Realizar **workshops de integração entre dev e ops**.
- Mostrar ganhos de agilidade, rastreabilidade e confiança.

---

## 📊 3. Mensuração e Compartilhamento de Conhecimento (M e S de CALMS)

### 🎯 Métricas a monitorar

- **Lead time** entre commit e deploy.
- **Taxa de sucesso dos pipelines**.
- **Número de incidentes pós-deploy**.
- **MTTR real após automação**.
- **Cobertura de testes** (automatizados).
- **Frequência de releases**.

### 📚 Compartilhamento de Conhecimento

- Criar um **repositório de boas práticas DevOps** no GitHub.
- Implantar **retrospectivas quinzenais** com devs e ops.
- Registrar aprendizados de cada incidente em **páginas wiki**.
- Criar um canal interno (Slack ou Teams) dedicado ao tema.

---

## 🔁 4. Três Maneiras do DevOps

### 🔹 **1ª Maneira — Acelerar o Fluxo**

- Automatizar pipeline completo com GitHub Actions.
- Garantir feedback imediato de builds, testes e qualidade.
- Reduzir o tempo entre entrega e deploy de 2 dias para poucas horas.

### 🔹 **2ª Maneira — Ampliar o Feedback**

- Testes automatizados no pipeline.
- Alertas e notificações em tempo real via e-mail ou Slack.
- Dashboards de CI/CD (via Grafana, Datadog ou GitHub Actions insights).

### 🔹 **3ª Maneira — Experimentar e Aprender**

- Deploy canário para features novas no e-commerce.
- Criar ambiente de staging igual ao de produção.
- Estimular contribuições para infraestrutura como código.

---

## ✨ Resultados Esperados (após implantação)

| Métrica                     | Antes        | Esperado após DevOps     |
|-----------------------------|--------------|---------------------------|
| Tempo até deploy            | 2 dias       | < 4 horas                |
| Taxa de sucesso dos deploys | 80%          | > 95%                    |
| Incidentes por semana       | 2            | < 1                      |
| MTTR                        | 4 horas      | < 1 hora                 |
