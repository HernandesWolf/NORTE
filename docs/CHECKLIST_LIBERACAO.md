# NORTE — checklist de liberação

Use este documento como fonte única do estado da transição. Marque itens somente após evidência verificável.

## Repositório e automação
- [x] PR de infraestrutura criado sobre a main atual: #10.
- [x] Documentação do caminho gratuito adicionada.
- [ ] PR #10 revisada e integrada à main.
- [ ] CI backend e frontend aprovado no commit final.
- [ ] Workflow de APK validado com assinatura release persistente.
- [ ] Release de teste criada e artefato baixado/verificado.

## Serviços gratuitos
- [ ] Projeto Neon Free criado.
- [ ] Exportação/backup do banco testada.
- [ ] Serviço Render Free criado a partir do Blueprint.
- [ ] Variáveis de ambiente configuradas sem segredos no Git.
- [ ] Migrações Flyway aplicadas sem erro.
- [ ] Endpoint HTTPS de saúde retorna UP.
- [ ] Cold start e suspensão testados.
- [ ] Nenhum plano pago ou cobrança automática ativados.

## Segurança e privacidade — bloqueadores de uso real
- [ ] Política de privacidade clara, acessível e coerente com o tratamento real.
- [ ] Consentimento explícito e informado, inclusive para dados enviados a provedor de IA.
- [ ] IA desligada por padrão e sem envio de conversa a terceiros sem consentimento.
- [ ] Exclusão de conta e dos dados associados implementada e testada.
- [ ] Exportação dos dados da pessoa implementada e testada.
- [ ] Recuperação de acesso implementada com fluxo seguro ou alternativa documentada.
- [ ] Proteção contra abuso no cadastro/login e limites de requisição revisados.
- [ ] Logs não registram senha, token, conteúdo privado ou dados pessoais desnecessários.
- [ ] CORS restrito aos domínios realmente usados.
- [ ] Tokens armazenados com segurança no Android e logout revoga refresh token.
- [ ] Isolamento entre contas verificado por testes.
- [ ] Plano de retenção, backup e resposta a incidente documentado.

## Android
- [ ] Identificador de pacote e nome do app conferidos.
- [ ] Keystore de release criado e guardado com backup.
- [ ] Secrets Android configurados no GitHub.
- [ ] APK assinado e assinatura conferida.
- [ ] Instalação limpa testada em aparelho Android.
- [ ] Atualização por cima da versão anterior testada.
- [ ] Cadastro/login/logout testados.
- [ ] Objetivos, tarefas, check-ins e conversa testados.
- [ ] Erros de rede/cold start tratados com mensagens compreensíveis.
- [ ] Teste em aparelho da Aisi concluído com consentimento dela.

## Liberação
- [ ] Todos os bloqueadores de segurança e privacidade resolvidos.
- [ ] Teste com conta fictícia concluído.
- [ ] Aisi recebeu explicação sobre limites do plano gratuito e consentiu em usar.
- [ ] Nenhum dado real inserido antes da liberação formal.

**Status atual:** preparação técnica em andamento. Não distribuir como versão pronta para dados pessoais enquanto houver itens bloqueadores pendentes.
