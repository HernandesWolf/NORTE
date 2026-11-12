# NORTE — Escopo do MVP (v0.1)

Este documento separa a visão do produto do que já existe no repositório. O objetivo é evitar que decisões planejadas sejam confundidas com funcionalidades entregues.

## 1. Direção do produto

O NORTE pretende ajudar pessoas a compreender seu momento, organizar prioridades e construir próximos passos possíveis. A experiência deve escutar antes de orientar, considerar o contexto e preservar a autonomia de quem usa.

### Público-âncora do primeiro piloto

Pessoas no Brasil que desejam entrar ou migrar para a área de tecnologia. Esse recorte permite validar a experiência com um público definido e não limita a visão futura do produto.

### Princípios

1. **MVP menor:** um único fluxo de conversa, em vez de quatro personas rígidas (Professor, Mentor, Guia e Resolve).
2. **Segurança desde o início:** autenticação, autorização, proteção de dados e gestão de sessão fazem parte da fundação.
3. **Flutter em evolução incremental:** o cliente já existe e possui autenticação conectada; os demais domínios serão integrados gradualmente.
4. **IA com responsabilidade:** avaliar provedores por qualidade em português, custo e privacidade antes de escolher; não enviar dados pessoais sem finalidade e transparência.
5. **Temas sensíveis exigem cuidado:** saúde mental, crise e dívidas precisam de critérios de segurança e avaliação antes de um piloto.
6. **Custo de IA é requisito técnico:** limites por usuário, observabilidade e controle de consumo devem existir antes de liberar a integração.
7. **Finanças fora do MVP:** sem gestão financeira ou movimentação de dinheiro na primeira versão.
8. **Modo de baixa energia:** planejar uma alternativa mínima e realista para dias difíceis, sem transformar isso em cobrança.

## 2. Escopo funcional desejado do MVP

- Cadastro, login, logout e renovação de sessão.
- Conversa com IA por texto.
- Resumo do contexto compreendido, sujeito à confirmação da pessoa.
- Perfil progressivo e memória básica consultável, corrigível e excluível.
- Objetivos, plano de 7 dias, tarefas e lembretes.
- Revisão de progresso e adaptação do plano.
- Consentimento, exportação e exclusão de dados.
- Limites de uso e controle de custo da IA.

## 3. Fora do MVP inicial

Voz, aplicativo web independente em Next.js, pagamentos, Redis/filas, busca vetorial, oportunidades externas, gestão financeira, comunidade, gamificação e integrações externas.

## 4. Estado de implementação em 12/11/2026

### Entregue no repositório

| Área | Estado observado |
|---|---|
| Backend Java 21 / Spring Boot 3.5.7 | Implementado |
| PostgreSQL e migrações Flyway | Configurados |
| Cadastro e login | Implementados |
| Access token JWT | Implementado |
| Refresh token com rotação | Implementado |
| Logout com revogação de refresh token | Implementado |
| Consulta autenticada do próprio perfil | Implementada |
| Limitação de tentativas de login e de cadastros por IP | Implementada em memória |
| CORS configurável | Implementado |
| Check-in diário de estado (um por pessoa por dia, fuso configurável) | Implementado (backend + Flutter) |
| Objetivos: listar, criar, editar, concluir e excluir, sempre filtrados pelo dono do token | Implementado no backend, com testes de isolamento entre usuários |
| Flutter com navegação Início, Conversa, Objetivos e Perfil | Implementado; Início, Conversa, Objetivos e autenticação usam a API; Perfil segue demonstrativo |
| Cadastro/login Flutter integrado à API | Implementado |
| Restauração de sessão, renovação e logout no Flutter | Implementados |
| Objetivos no Flutter | Listar, criar, editar, concluir e excluir integrados à API |
| Tarefas por objetivo e plano de 7 dias | Implementado (backend + Flutter), filtrado pelo dono do token |
| Conversa com IA (AI Gateway, Groq e Gemini) | Implementada; desligada por padrão; limites por pessoa (minuto e dia) e teto global por dia |
| Validação do perfil `prod` | Implementada: exige senha do banco, CORS e segredo JWT próprios; recusa os valores de desenvolvimento |
| Integração contínua (GitHub Actions) | Testes do backend e análise/testes do Flutter a cada push e pull request |

### Ainda não entregue

| Área | Próximo trabalho |
|---|---|
| Perfil progressivo | Modelagem, API e telas |
| Testes de integração com banco real | Cobrir isolamento entre usuários, o refresh token atômico e as migrações com PostgreSQL (por exemplo, Testcontainers) |
| Conversa orientada | Contexto (objetivos e check-in), memória e avaliação de segurança com temas sensíveis; a conversa atual não guarda histórico |
| Plano adaptável | Geração, edição, revisão e histórico |
| Lembretes | Definir mecanismo e preferências |
| Privacidade | Consentimento, exportação e exclusão reais |
| Segurança operacional | Limite distribuído, observabilidade e revisão de produção |
| Flutter Web | Rever estratégia de armazenamento de tokens antes de uso com dados reais |

**Importante:** a conversa com IA funciona, mas não guarda histórico e ainda não conhece os objetivos nem o check-in da pessoa. A tela de perfil apresenta opções ilustrativas ainda sem operação de gestão de dados (memória, privacidade, exportação e exclusão de conta). Os planos gratuitos dos provedores de IA servem apenas para desenvolvimento com dados fictícios. Estar autenticado e ter os módulos integrados não significa que o produto esteja pronto para uso público.

Os limitadores (login, cadastro por IP e uso da IA) mantêm estado em memória e atendem apenas a uma instância. Para múltiplas instâncias, será necessário armazenamento compartilhado. Atrás de proxy, configure `NORTE_FORWARD_HEADERS`; sem isso o IP visto pela API é o do proxy.

No Flutter Web, o armazenamento de tokens tem proteção inferior à oferecida por Keychain/Keystore nos dispositivos móveis. A versão Web atual deve ser tratada como ambiente de desenvolvimento/demonstração até que a estratégia seja revista.

## 5. Ordem de construção recomendada

| Etapa | Entrega | Critério de pronto |
|---|---|---|
| 1 | Validar a fundação atual | Testes backend e Flutter executados; Postgres e Flyway validados localmente |
| 2 | Validar autenticação ponta a ponta | Cadastro/login/perfil/refresh/logout testados, inclusive expiração e revogação |
| 3 | Perfil e objetivos | CRUD protegido; um usuário nunca acessa dados de outro (objetivos e check-in prontos e testados; perfil progressivo pendente) |
| 4 | AI Gateway | Interface de provedor, limites, registro de consumo e tratamento de falhas |
| 5 | Conversa orientada | Fluxo de compreensão → confirmação → próxima ação, com avaliação de segurança |
| 6 | Plano e tarefas | Plano editável, persistido e adaptável |
| 7 | Privacidade | Consentimento, consulta, exportação e exclusão implementados e testados |
| 8 | Piloto controlado | Segurança, custo, suporte e avaliação com usuários definidos |

## 6. Decisões pendentes

- Provedor de IA: comparar opções com testes reais em português, custo e condições de privacidade.
- Hospedagem do piloto: definir ambiente, orçamento, backups e observabilidade.
- Estratégia de sessão para Web: rever armazenamento antes de qualquer piloto com dados reais.
- Marca e domínio: verificar disponibilidade e registro no INPI antes de investimento comercial relevante.

---

**Regra de manutenção:** sempre que uma funcionalidade mudar de estado, atualizar esta tabela e o README na mesma alteração. Documentação deve refletir o código existente, não antecipar o produto desejado.
