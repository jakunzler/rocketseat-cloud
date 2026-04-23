# Configuração de Infraestrutura Multi-Ambiente

## Conheça o projeto

Este desafio tem o objetivo de consolidar os conhecimentos de IaC com Terraform. Você deverá configurar uma infraestrutura distribuída em três ambientes (prod, staging e dev) usando o Terraform. Cada ambiente requer configurações específicas, como diferentes tamanhos de instâncias, variáveis de ambiente e configurações de rede.

## Tarefas
1. Definição de Arquitetura

Projete uma arquitetura básica para o aplicativo que inclua instâncias EC2, uma VPC e um balanceador de carga.

2. Configuração de Ambientes

- Crie configurações separadas para cada ambiente (prod, staging e dev) usando módulos Terraform para garantir a reutilização de código.
- Cada ambiente deve ter configurações exclusivas, como tamanhos de instâncias EC2, variáveis de ambiente e regras de segurança específicas.

3. Gerenciamento de Variáveis

- Utilize variáveis do Terraform para gerenciar os detalhes específicos de cada ambiente, como chaves de acesso, senhas e IDs de recursos.
- Mantenha as credenciais sensíveis fora do código Terraform, utilizando recursos como o AWS Secrets Manager ou variáveis de ambiente.

4. Segurança

Implemente boas práticas de segurança, como limitar o acesso a recursos, criptografar dados sensíveis e aplicar políticas de controle de acesso a recursos.

5. Documentação

Documente claramente a estrutura da infraestrutura em um arquivo README.md, incluindo a finalidade de cada recurso, dependências entre eles e instruções para implantar e gerenciar a infraestrutura.
Resultados Esperados

- Organização e modularidade do código Terraform.
- Eficiência na utilização de variáveis e módulos para evitar repetição de código.
- Adesão a boas práticas de segurança e gerenciamento de segredos.
- Documentação clara e abrangente da infraestrutura.
