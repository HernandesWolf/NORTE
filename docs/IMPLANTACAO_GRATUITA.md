# Implantação gratuita do NORTE

Este documento é o roteiro operacional para preparar a primeira instalação real do NORTE sem contratar serviços pagos. A configuração não deve ser considerada concluída até que cada etapa da lista de liberação seja executada e comprovada.

## Arquitetura-alvo (R$ 0/mês)

- **Código e automação:** GitHub.
- **API:** Render Free, usando o Dockerfile deste repositório.
- **Banco:** Neon Free (PostgreSQL), separado da Render.
- **Aplicativo:** Flutter Android, compilado pelo GitHub Actions e distribuído como APK em uma GitHub Release.
- **Tráfego:** somente HTTPS entre o aplicativo e a API.
- **IA:** desligada por padrão. Não configurar chave de provedor no piloto.

Os planos gratuitos têm limites, podem suspender serviços ociosos e não oferecem as mesmas garantias de disponibilidade, suporte ou recuperação de dados de um plano pago. O banco gratuito da Render não deve ser usado: ele tem prazo de expiração. Antes de cadastrar dados pessoais, confirmar no painel da Neon os limites, política de suspensão, retenção e opções de exportação/backup vigentes.

## Ordem de implantação

### 1. Preparar o banco Neon

1. Criar uma conta/projeto Neon no plano gratuito.
2. Criar um banco dedicado ao NORTE.
3. Copiar os dados de conexão **sem publicar a URL ou senha**.
4. Preferir conexão TLS e, para o serviço Render, usar a URL JDBC no formato:
   `jdbc:postgresql://HOST/NOME_DO_BANCO?sslmode=require`
5. Confirmar se a URL escolhida é a conexão direta recomendada para migrações Flyway. Não adicionar `-pooler` sem validar compatibilidade.
6. Registrar em gerenciador de senhas onde a senha foi guardada.
7. Definir um procedimento de exportação/backup e testar uma restauração antes de armazenar dados importantes.

### 2. Criar a API na Render

1. Conectar o repositório GitHub `HernandesWolf/NORTE`.
2. Criar serviço a partir do Blueprint `render.yaml` (ou New > Blueprint).
3. Manter o plano **Free**. Não selecionar upgrade ou recurso pago.
4. Preencher no painel, nunca no Git:
   - `NORTE_DB_URL`
   - `NORTE_DB_USER`
   - `NORTE_DB_PASSWORD`
5. Confirmar que `SPRING_PROFILES_ACTIVE=prod` e que `NORTE_JWT_SECRET` foi gerado pela Render. Não substituir por segredo curto ou previsível.
6. Manter `NORTE_IA_PROVEDOR=desligado`.
7. Aguardar o deploy e conferir `https://<dominio-render>/actuator/health`. A resposta esperada é status UP, sem expor detalhes internos.
8. Guardar a URL HTTPS pública da API. Não usar URL HTTP no aplicativo.

### 3. Configurar o GitHub

No repositório, abrir Settings > Secrets and variables > Actions.

Criar a variável de repositório:
- `NORTE_API_URL`: URL HTTPS da API, sem barra final.

Criar os secrets de assinatura Android descritos em [ASSINATURA_ANDROID.md](./ASSINATURA_ANDROID.md). Segredos e arquivos de chave nunca devem ser enviados em commits, issues, comentários ou mensagens.

### 4. Gerar o APK

1. Abrir Actions > APK Android (piloto).
2. Selecionar Run workflow.
3. Deixar o campo de URL vazio para usar `NORTE_API_URL`, ou informar a mesma URL HTTPS.
4. A execução deve falhar se a assinatura release não estiver configurada.
5. Baixar o APK da Release criada somente após todos os passos do workflow concluírem com sucesso.
6. Guardar o keystore original e suas senhas em local seguro e com cópia de segurança. Perder a chave impede atualizar a instalação existente com a mesma identidade.

### 5. Teste controlado antes do uso

Usar primeiro uma conta de teste, sem dados pessoais da Aisi. Verificar:
- instalação limpa e abertura;
- cadastro, login, renovação de sessão e logout;
- criação, edição e conclusão de objetivo/tarefa;
- check-in e plano de 7 dias, se disponíveis;
- encerramento e reabertura do app;
- comportamento quando a API está suspensa/indisponível;
- persistência após reiniciar a API;
- isolamento entre duas contas de teste;
- mensagens de erro sem stack trace, tokens ou dados sensíveis.

Não iniciar o uso real até que privacidade, consentimento, exclusão/exportação de dados, política de privacidade e recuperação de conta estejam implementados e testados.

## Variáveis de ambiente da API

| Variável | Obrigatória | Valor |
|---|---:|---|
| `SPRING_PROFILES_ACTIVE` | Sim | `prod` |
| `NORTE_JWT_SECRET` | Sim | Gerado pela Render; forte e exclusivo |
| `NORTE_DB_URL` | Sim | JDBC TLS do Neon |
| `NORTE_DB_USER` | Sim | Usuário do banco |
| `NORTE_DB_PASSWORD` | Sim | Senha do banco |
| `NORTE_IA_PROVEDOR` | Sim | `desligado` no piloto |
| `NORTE_CORS_ORIGINS` | Condicional | Domínios web reais; não abrir com curingas |

Nunca incluir valores reais em `application.yml`, `render.yaml`, arquivos de exemplo ou documentação.

## Voltar atrás / contingência

- Não apagar o banco para corrigir um deploy.
- Antes de migração de banco, exportar os dados e validar que o arquivo pode ser lido.
- Se o deploy falhar, voltar à versão anterior da API e preservar o banco.
- Se a API gratuita ficar suspensa, aguardar o cold start; não reinstalar o app nem limpar seus dados.
- Se houver suspeita de exposição de credencial, rotacionar a senha/segredo no provedor e revisar logs.
- Se o limite gratuito for atingido, pausar o uso e decidir conscientemente o próximo passo. Não autorizar upgrade automático.

## Critério de conclusão

A implantação só estará concluída quando API e banco estiverem ativos, migrações aplicadas, endpoint de saúde validado, APK assinado com chave persistente, testes no aparelho Android aprovados, e os requisitos de privacidade e recuperação de dados concluídos. Até lá, classificar como **piloto técnico — não liberar dados pessoais reais**.
