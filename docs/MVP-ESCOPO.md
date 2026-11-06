# NORTE — Escopo fechado do MVP (v0.1)

Revisão do documento mestre. O documento original é ótimo como visão; para virar software, ele precisa de recorte. Abaixo, o que mudei e por quê.

## 1. Melhorias propostas sobre o documento original

1. **MVP menor.** O original lista 18 funcionalidades obrigatórias, incluindo quatro "modos" (Professor, Mentor, Guia, Resolve). No MVP, isso vira **um único fluxo de conversa** com a IA escolhendo o tom/finalidade internamente. Os modos viram uma escolha de interface só depois de validar o fluxo.
2. **Um público-âncora para validar.** O original diz "adultos em mudança" (amplo demais para testar). Para o piloto: **pessoas querendo entrar ou migrar para tecnologia no Brasil**. Isso dá métricas claras (completou o plano de 7 dias? aprendeu o conceito X?) e é um domínio que o criador conhece. O produto continua geral; só o piloto é focado.
3. **Web e Flutter em fases.** O backend e a API vêm primeiro (testáveis sozinhos). Depois, o app Flutter. Next.js só depois, como o próprio documento já indica.
4. **Segurança e LGPD desde o primeiro commit**, mas só o essencial no MVP: autenticação, exclusão e exportação de conta, consentimento claro de uso de IA, sem treinar modelos com dados do usuário.
5. **Rede de segurança para temas sensíveis antes de abrir para usuários reais.** Saúde mental, crise e dívidas exigem respostas testadas (suíte de avaliação do item 13.5 do original) *antes* do piloto. Isso é requisito de lançamento, não "depois".
6. **Custo de IA como funcionalidade, não detalhe.** Limite diário por usuário e registro de tokens por chamada desde a primeira integração com IA.
7. **Finanças fora do MVP.** O original já diz "sem gestão financeira avançada". Eu iria além: nenhum lançamento financeiro no MVP; só educação e orientação em conversa.
8. **Modo Sobrevivência** (aparece na Fase 3 do original, mas sem definição): defino como *plano mínimo de 15 minutos por dia*, ativado quando o usuário diz "hoje está difícil".

## 2. Dentro do MVP

- Cadastro, login, exclusão e exportação de conta
- Conversa com IA (texto), com resumo/diagnóstico confirmável pelo usuário
- Perfil progressivo e memória básica (consultável, corrigível, excluível)
- Objetivos, plano de 7 dias, tarefas e lembretes
- Revisão de progresso e adaptação do plano
- Limites de uso e controle de custo da IA

## 3. Fora do MVP

Voz, web (Next.js), pagamentos, Redis/filas, pgvector, oportunidades/vagas externas, finanças, comunidade, gamificação, integrações externas.

## 4. Ordem de construção

| Etapa | Entrega | Critério de pronto |
|---|---|---|
| 1.1 | Fundação do backend | Testes passam, Postgres sobe, Flyway migra |
| 1.2 | Autenticação | Cadastro/login/refresh/logout com testes de autorização |
| 1.3 | Perfil e objetivos | CRUD protegido, um usuário nunca acessa dados de outro (teste) |
| 2.1 | AI Gateway | Interface de provedor + limites + log de custo |
| 2.2 | Conversa orientada | Fluxo compreensão → diagnóstico → primeira ação |
| 3.x | Plano de 7 dias, tarefas, revisão | Plano gerado, editável e adaptável |
| 4 | App Flutter | Fluxo completo no celular |
| 5 | Piloto | Teste com pessoas reais e avaliação de custo |

## 5. Decisões a tomar (suas)

- **Provedor de IA** para o MVP (qualidade em português, custo, privacidade). Recomendo avaliar 2–3 em testes reais antes de fixar.
- **Nome e domínio**: "NORTE" é um nome comum; vale checar marca registrada (INPI) antes de investir em identidade visual.
- **Hospedagem** do piloto (custo mensal que você aceita pagar).
