# CI/CD com GitHub Actions para AWS App Runner e Terraform

## Visão Geral do Projeto

Neste desafio, você irá expandir seus conhecimentos em CI/CD, utilizando GitHub Actions para automatizar o processo de integração contínua e entrega contínua de uma aplicação hospedada no AWS AppRunner.

### Instruções

>Estrutura, regras e requisitos do projeto

Neste desafio, você irá expandir seus conhecimentos em CI/CD, utilizando GitHub Actions para automatizar o processo de integração contínua e entrega contínua de uma aplicação hospedada no AWS AppRunner. O objetivo é configurar uma pipeline que permita a implantação da aplicação em diferentes ambientes (dev e prod), com uma etapa de verificação da aplicação em dev e a entrega disso em produção caso tudo esteja bem.

### Etapas

1. Configuração do Repositório no GitHub

- Crie um repositório no GitHub para hospedar o código da aplicação e os arquivos de configuração da pipeline.
- Personalize o README.md com instruções claras sobre como configurar o ambiente de desenvolvimento, executar testes e contribuir para o projeto.
- Escolha uma licença apropriada para o projeto, considerando as necessidades e restrições de uso.
- Configure o arquivo .gitignore para excluir arquivos e diretórios desnecessários do controle de versão.

2. Configuração da Pipeline CI/CD

- Defina os estágios da pipeline de acordo com as necessidades do projeto, incluindo testes, integração, build da aplicação e implantação.
- Utilize as actions do GitHub de forma eficiente para automatizar cada estágio da pipeline.

3. Provisionamento de Infraestrutura com Terraform

- Utilize o Terraform para provisionar a infraestrutura necessária nos ambientes dev e prod, como recursos no AWS AppRunner, variáveis de ambiente e políticas de acesso.
- Organize o código Terraform de forma modular e reutilizável, separando as configurações de cada ambiente.

4. Implantação no Ambiente de Dev

- Configure a pipeline para implantar automaticamente a aplicação no ambiente de desenvolvimento após a conclusão bem-sucedida dos estágios de teste e build.
- Garanta que as variáveis de ambiente necessárias estejam corretamente configuradas no ambiente de desenvolvimento, incluindo chaves de API, URLs de serviços externos e configurações de banco de dados.

5. Verificação da Saúde da aplicação em Dev

- Adicione uma etapa à pipeline para verificar a saúde da aplicação implantada no ambiente de desenvolvimento.
- Implemente testes de integração ou utilize ferramentas de monitoramento para verificar se a aplicação está funcionando corretamente.

6. Implantação no Ambiente de Produção

- Implante a aplicação no ambiente de produção de forma automatizada, garantindo que as configurações e variáveis de ambiente estejam corretas.

### Resultados Esperados

- Uma pipeline CI/CD configurada no GitHub Actions que automatize o processo de integração contínua e entrega contínua da aplicação hospedada no AWS AppRunner.
- Código Terraform organizado de forma modular e reutilizável para provisionar a infraestrutura nos ambientes dev e prod.
- Uma pipeline CI/CD configurada no GitHub Actions que automatize o processo de criação da infraestrutura.
- Implantação automatizada da aplicação nos ambientes dev e prod, com verificação da saúde da aplicação no ambiente de desenvolvimento antes da implantação em produção.
- Documentação detalhada de todo o processo, incluindo configurações, decisões de projeto e fluxo da pipeline.
