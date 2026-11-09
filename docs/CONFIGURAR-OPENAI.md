# Configurar a OpenAI no NORTE

A integração está implementada no backend, mas permanece **desligada por padrão**. Não é necessário criar uma chave para desenvolver ou executar o restante do aplicativo.

## 1. Criar a chave quando decidir ativar

1. Entre na [plataforma de desenvolvedores da OpenAI](https://platform.openai.com/).
2. Abra a área de API keys e crie uma chave exclusiva para o NORTE.
3. Configure a forma de pagamento e um limite de gastos compatível com seu orçamento.
4. Copie a chave uma única vez e guarde-a em um gerenciador de segredos.

A API é cobrada separadamente da assinatura do ChatGPT. Os limites de chamadas do NORTE não são um limite financeiro da conta OpenAI.

## 2. Configurar no ambiente do backend

O backend lê estas variáveis:

| Variável | Padrão | Finalidade |
|---|---:|---|
| `NORTE_OPENAI_ENABLED` | `false` | Habilitação explícita |
| `NORTE_OPENAI_API_KEY` | vazia | Chave privada |
| `NORTE_OPENAI_MODEL` | `gpt-4.1-mini` | Modelo |
| `NORTE_IA_LIMITE_DIARIO` | `5` | Chamadas por usuário/dia |
| `NORTE_IA_LIMITE_MENSAL_GLOBAL` | `100` | Chamadas globais/mês |

Para um teste local temporário no PowerShell, defina as variáveis apenas na janela atual do terminal antes de iniciar o backend:

```powershell
$env:NORTE_OPENAI_ENABLED = "true"
$env:NORTE_OPENAI_API_KEY = "cole-a-chave-apenas-no-seu-terminal"
$env:NORTE_OPENAI_MODEL = "gpt-4.1-mini"
cd backend
mvn spring-boot:run
```

O valor ilustrativo acima não é uma chave real. Não coloque a chave em código, README, arquivo versionado, comando salvo no histórico compartilhado, Flutter ou `--dart-define`.

Em produção, cadastre as variáveis no gerenciador de segredos ou configuração de ambiente do serviço que hospeda o backend. Não basta cadastrá-las no GitHub se o backend não for executado por um workflow que as injete com segurança.

## 3. Como o consentimento funciona

- A integração só chama a OpenAI se o backend estiver habilitado, a chave existir e a pessoa tiver consentido.
- O consentimento é individual, fica registrado no banco e pode ser revogado na tela Conversa.
- Ao consentir, a pessoa autoriza o envio das 12 mensagens mais recentes daquela conversa, limitadas a 1.500 caracteres por mensagem.
- O NORTE não envia automaticamente dados de check-in, objetivos ou perfil como contexto da OpenAI.
- A proposta de objetivo é apenas exibida para revisão; o aplicativo só grava depois que a pessoa confirma.
- As chamadas usam `store=false`, que solicita à API não armazenar a resposta. Isso não é promessa de ausência de logs ou retenção operacional do provedor.

## 4. Limites de uso

Por padrão, o backend permite até 5 chamadas por usuário em cada dia do calendário de Brasília e 100 chamadas globais por mês. Os contadores são aplicados atomicamente no PostgreSQL.

Esses limites restringem quantidade de chamadas, não calculam o valor em reais ou dólares. Configure também um orçamento financeiro na plataforma OpenAI e acompanhe o consumo.

## 5. Como verificar

Depois de iniciar o backend e autenticar no aplicativo, a tela Conversa consulta:

- `GET /api/v1/conversa/ia/status`: informa se a integração está habilitada e se existe consentimento para a conta autenticada.
- `PUT /api/v1/conversa/ia/consentimento`: registra ou revoga a autorização.

Se a integração estiver desligada, o histórico continua funcionando sem enviar mensagens para a OpenAI.
