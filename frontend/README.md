# NORTE — Aplicativo Flutter

Cliente móvel do NORTE, com identidade visual **Rose Edition**.

## Estado atual

Esta primeira entrega é um **protótipo navegável de interface**. Inclui:
- Entrada e criação de conta (fluxo demonstrativo, sem autenticação real).
- Visão inicial com acolhimento e check-in de estado.
- Área de conversa com composição local de mensagens (sem chamada à IA).
- Objetivos e tarefas demonstrativas com marcação de conclusão.
- Área de perfil com pontos de entrada para privacidade e gestão de dados.

## Executar

Requisitos: Flutter SDK instalado.

```powershell
flutter pub get
flutter run
```

## Próximas integrações obrigatórias

Antes de qualquer piloto com usuários reais, conectar os fluxos à API Spring Boot e implementar/testar autenticação, isolamento por usuário, consentimento, exportação e exclusão de dados, tratamento seguro de tokens, erros e estados de carregamento. Os controles de perfil exibidos ainda são apenas representativos.

## Identidade visual

Paleta Rose Edition centralizada em `NorteColors` no arquivo `lib/main.dart`: rose, blush, creme, nude e vinho suave. O objetivo é acolher sem infantilizar, orientar sem pressionar e respeitar a energia e as circunstâncias da pessoa.
