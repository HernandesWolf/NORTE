<!-- NORTE • README | atualizado em 09/11/2026 -->

<p align="center">
  <img src="assets/images/NORTE_%20Seu%20Guia%20para%20uma%20Vida%20com%20Sentido.png" alt="NORTE — Seu tempo. Sua história. Seu caminho." width="100%" />
</p>

<h1 align="center">NORTE</h1>

<p align="center">
  <strong>Seu tempo. Sua história. Seu caminho.</strong><br/>
  <em>Uma tecnologia que começa escutando.</em>
</p>

<p align="center">
  O NORTE é uma plataforma de orientação pessoal em desenvolvimento. Sua proposta é ajudar pessoas a compreender o momento que vivem, organizar prioridades e construir próximos passos que respeitem sua realidade.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Java-21-ED8B00?logo=openjdk&logoColor=white" alt="Java 21" />
  <img src="https://img.shields.io/badge/Spring_Boot-3.5.7-6DB33F?logo=springboot&logoColor=white" alt="Spring Boot 3.5.7" />
  <img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white" alt="PostgreSQL 16" />
  <img src="https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Identidade-Rose_Edition-B87583" alt="Rose Edition" />
  <img src="https://img.shields.io/badge/Status-MVP_em_construção-8957e5" alt="MVP em construção" />
</p>

---

## A ideia por trás do NORTE

Nem sempre uma pessoa precisa de mais uma lista de tarefas, de uma cobrança ou de um conselho pronto.

Às vezes, ela precisa parar por um instante, entender o que está acontecendo e enxergar uma possibilidade de cada vez. Pode estar enfrentando uma mudança de carreira, responsabilidades acumuladas, insegurança, cansaço ou simplesmente a sensação de ter perdido a direção.

O NORTE nasce de uma convicção: **nenhum planejamento deveria ignorar a pessoa que terá de vivê-lo.**

Queremos construir uma experiência que escute antes de orientar, considere o contexto antes de sugerir e ajude a transformar intenção em passos possíveis — sem julgamentos, fórmulas mágicas ou promessas irreais.

<p align="center">
  <img src="assets/images/NORTE_%20Seu%20Caminho%20para%20Recome%C3%A7ar.png" alt="Conceito NORTE: uma pausa para respirar, refletir e encontrar um próximo passo." width="100%" />
</p>

> **A vida não acontece em uma planilha perfeita. A tecnologia precisa aprender a respeitar isso.**

## Como queremos que a experiência funcione

O NORTE está sendo pensado como um processo de orientação contínua, não como um gerador automático de metas.

1. **Acolher:** entender como a pessoa chega, sem julgamento.
2. **Escutar:** conhecer sua história, seu contexto, suas responsabilidades e seus limites.
3. **Organizar:** ajudar a separar preocupações, prioridades e possibilidades.
4. **Orientar:** construir próximos passos claros e realistas, com participação da própria pessoa.
5. **Adaptar:** rever o caminho quando a vida mudar — porque ela vai mudar.

<p align="center">
  <img src="assets/images/NORTE_%20Encontre%20Sua%20Dire%C3%A7%C3%A3o-1.png" alt="Conceito visual das experiências Início, Conversa, Objetivos e Perfil do NORTE." width="100%" />
</p>

<p align="center"><em>Direção visual do aplicativo. Parte das telas e interações ainda é demonstrativa.</em></p>

### Princípios de produto

- **Humanidade antes da produtividade:** a pessoa não é uma máquina de cumprir metas.
- **Contexto antes de conselho:** recomendações precisam considerar a realidade apresentada.
- **Autonomia:** a pessoa participa das decisões e pode corrigir o que o sistema entendeu.
- **Pequenos passos:** progresso sustentável vale mais do que planos grandiosos e impraticáveis.
- **Transparência:** deixar claro o que é funcional, o que é protótipo e o que ainda é visão.
- **Privacidade desde a concepção:** dados pessoais exigem cuidado, finalidade clara e controle.

## Identidade visual — Rose Edition

A Rose Edition é a direção visual escolhida para o NORTE: delicada, adulta, acolhedora e sofisticada. A intenção é transmitir proximidade e tranquilidade sem infantilizar a interface ou restringir o produto a um único público.

| Cor | Código | Aplicação |
|---|---|---|
| Rose | `#B87583` | Identidade e destaques |
| Blush | `#F3DDDF` | Superfícies e realces suaves |
| Creme | `#FBF7F3` | Fundo principal |
| Nude | `#E9DCD3` | Cartões e áreas de apoio |
| Vinho suave | `#76505D` | Textos e contraste |
| Champagne | `#D7C4B8` | Bordas e detalhes |

**Direção de interface:** tipografia serena, cartões com cantos suaves, espaços generosos, ícones consistentes, movimento discreto, acessibilidade e legibilidade acima de efeitos decorativos.

<p align="center">
  <img src="assets/images/NORTE_%20Seu%20Guia%20de%20Equil%C3%ADbrio%20e%20Prop%C3%B3sito-2.png" alt="Conceito visual de escuta e acolhimento." width="100%" />
</p>

## Visão de produto e escopo

A visão de longo prazo inclui conversa contextual, organização de objetivos, planos adaptáveis, acompanhamento de progresso e lembretes. A construção será incremental: primeiro uma base segura e validável; depois, recursos que comprovem utilidade real.

### Recorte inicial do MVP

- Cadastro, autenticação e gestão da sessão.
- Conversa com IA por texto (em desenvolvimento; ainda sem provedor conectado).
- Síntese do contexto compreendido, sujeita à confirmação da pessoa.
- Perfil progressivo e memória básica sob controle do usuário.
- Objetivos, plano de 7 dias, tarefas e lembretes.
- Revisão do progresso e adaptação do plano.
- Limites de uso e controle de custos da IA.

O primeiro piloto está sendo recortado para pessoas no Brasil que desejam entrar ou migrar para a área de tecnologia. Esse foco serve para validar a experiência com um público definido; não limita a visão futura do produto.

### Fora do MVP inicial

Voz, aplicativo web independente em Next.js, pagamentos, gestão financeira, comunidade, gamificação e integrações externas ficam para etapas posteriores.

---

## Estado real do desenvolvimento

O NORTE já possui autenticação, check-in diário e objetivos persistidos no backend, além de uma primeira etapa de histórico de conversa em desenvolvimento. **Ainda não é um produto pronto para uso público ou para armazenar dados reais.**

### Backend — implementado

- API REST com Java 21 e Spring Boot 3.5.7.
- Cadastro de usuário e login.
- Senhas protegidas com BCrypt.
- Access token JWT e refresh token com rotação.
- Logout com revogação do refresh token.
- Endpoint autenticado para consultar o próprio perfil.
- Persistência com Spring Data JPA e PostgreSQL 16.
- Migrações de banco com Flyway.
- Validação de entrada e respostas de erro no formato Problem Details.
- CORS configurável por variável de ambiente.
- Limitação de tentativas de login em memória.
- Health check com Spring Boot Actuator
- Check-in diário persistido por usuário
- CRUD de objetivos persistido e protegido por usuário
- Histórico de mensagens da Conversa em implementação, com endpoints autenticados e limite de 100 mensagens.

**Limite conhecido:** o limitador de tentativas é mantido em memória. É adequado apenas ao cenário simples de uma única instância e precisa ser substituído por uma solução compartilhada antes de escalar horizontalmente.

### Aplicativo Flutter — implementado parcialmente

- Fluxos de cadastro e login conectados à API.
- Check-in diário conectado ao backend.
- Listagem, criação, conclusão e exclusão de objetivos conectadas ao backend.
- Tela Conversa conectada ao histórico persistido (entrega em revisão no PR #5).
- Restauração da sessão ao abrir o aplicativo.
- Armazenamento e renovação de tokens.
- Renovação coordenada para evitar chamadas simultâneas com o mesmo refresh token.
- Logout local e solicitação de revogação ao backend.
- Consulta do perfil autenticado.
- Tratamento de erros de conexão, validação e respostas HTTP.
- Navegação pelas áreas Início, Conversa, Objetivos e Perfil.
- Primeira aplicação da identidade Rose Edition.

### Ainda demonstrativo ou pendente

- A conversa ainda não está conectada a um modelo de IA; nesta primeira etapa, o envio e o histórico de mensagens são persistidos, sem resposta inteligente.
- Sugestões de conversa ainda não geram respostas da IA.
- Conversão de uma conversa em objetivo ainda depende de um fluxo explícito de proposta e confirmação.
- Check-in e objetivos já são persistidos; tarefas independentes ainda não possuem gestão própria.
- Opções de privacidade, memória, exportação e exclusão de conta são ilustrativas.
- Recuperação de senha, consentimentos e gestão de dados precisam ser implementados.
- O AI Gateway, limites de custo e proteção contra abuso ainda não existem.
- Testes de integração e validação de segurança precisam ser ampliados antes de um piloto.

### Atenção ao Flutter Web

O projeto usa `flutter_secure_storage` para guardar tokens. Em Android e iOS, o pacote utiliza os mecanismos seguros da plataforma. No navegador, não existe um cofre equivalente: a própria documentação do código alerta que a proteção é mais fraca. Portanto, a versão Web atual deve ser tratada como ambiente de desenvolvimento/demonstração, não como uma solução validada para credenciais e dados reais.

## Tecnologias

| Tecnologia | Responsabilidade |
|---|---|
| Java 21 | Linguagem do backend |
| Spring Boot 3.5.7 | Aplicação e API REST |
| Spring Security | Segurança e autenticação |
| JWT | Access token |
| Refresh token | Renovação e continuidade da sessão |
| Spring Data JPA | Persistência e acesso a dados |
| PostgreSQL 16 | Banco de dados relacional |
| Flyway | Versionamento do banco |
| Maven | Dependências e build |
| Docker Compose | Ambiente local do PostgreSQL |
| Spring Boot Actuator | Health check |
| Flutter / Dart | Aplicativo cliente |

**Arquitetura atual:** monólito modular no backend. A prioridade é manter uma base compreensível, testável e segura, evitando complexidade prematura.

## Estrutura do repositório

```text
norte/
├── backend/             # API Java + Spring Boot
├── frontend/            # Aplicativo Flutter
├── docs/                # Escopo, decisões e conceitos visuais
├── docker-compose.yml   # PostgreSQL para desenvolvimento local
└── README.md
```

## Executar localmente

### Pré-requisitos

- JDK 21.
- Maven 3.9 ou superior.
- Docker Desktop com WSL2 no Windows (ou Docker Engine em Linux/macOS).
- Flutter SDK compatível com o `pubspec.yaml`.

### 1. Iniciar o banco de dados

Na raiz do repositório:

```bash
docker compose up -d
```

O PostgreSQL ficará disponível em `localhost:5433`.

> As credenciais definidas no Docker Compose são exclusivas para desenvolvimento local. Não as utilize em produção.

### 2. Executar os testes do backend

Em outro terminal, na raiz:

```bash
cd backend
mvn test
```

### 3. Iniciar a API

Ainda na pasta `backend`:

```bash
mvn spring-boot:run
```

A API ficará disponível em `http://localhost:8080`.

### 4. Executar os testes e o aplicativo Flutter

Em outro terminal, na raiz do repositório:

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Para apontar o aplicativo a outra URL de API:

```bash
flutter run -d chrome --dart-define=NORTE_API_URL=http://localhost:8080
```

No emulador Android padrão, o endereço do computador costuma ser `http://10.0.2.2:8080`, em vez de `localhost`.

### 5. Verificar a API

| Método | Endpoint | Finalidade |
|---|---|---|
| GET | `/api/v1/status` | Status da aplicação |
| GET | `/actuator/health` | Health check |

## Endpoints de autenticação

| Método | Rota | Acesso | Finalidade |
|---|---|---|---|
| POST | `/api/v1/auth/registro` | Público | Criar uma conta |
| POST | `/api/v1/auth/login` | Público | Autenticar e receber tokens |
| POST | `/api/v1/auth/refresh` | Público + refresh token | Rotacionar a sessão |
| POST | `/api/v1/auth/logout` | Público + refresh token | Revogar o refresh token |
| GET | `/api/v1/me` | Access token | Consultar o próprio perfil |
| GET | `/api/v1/conversa/mensagens` | Access token | Listar até 100 mensagens do usuário |
| POST | `/api/v1/conversa/mensagens` | Access token | Registrar uma mensagem do usuário |
| GET | `/api/v1/objetivos` | Access token | Listar objetivos do usuário |
| POST | `/api/v1/objetivos` | Access token | Criar objetivo |
| PUT | `/api/v1/objetivos/{id}` | Access token | Atualizar objetivo |
| PATCH | `/api/v1/objetivos/{id}/conclusao` | Access token | Atualizar conclusão |
| DELETE | `/api/v1/objetivos/{id}` | Access token | Excluir objetivo |
| GET | `/api/v1/status` | Conforme configuração | Verificar status |
| GET | `/actuator/health` | Conforme configuração | Verificar saúde da aplicação |

### Exemplo de uso com PowerShell

Com a API em execução, use dados fictícios:

```powershell
$u = "http://localhost:8080/api/v1"

$cadastro = @{
    email = "ana@exemplo.com"
    senha = "senha-ficticia-123"
    nomeExibicao = "Ana"
} | ConvertTo-Json

# Cadastro
Invoke-RestMethod -Method Post -Uri "$u/auth/registro" -ContentType "application/json" -Body $cadastro

$login = @{
    email = "ana@exemplo.com"
    senha = "senha-ficticia-123"
} | ConvertTo-Json

# Login
$sessao = Invoke-RestMethod -Method Post -Uri "$u/auth/login" -ContentType "application/json" -Body $login

# Perfil autenticado
Invoke-RestMethod -Uri "$u/me" -Headers @{
    Authorization = "Bearer $($sessao.accessToken)"
}

# Renovação: o refresh token anterior é rotacionado
$renovacao = @{ refreshToken = $sessao.refreshToken } | ConvertTo-Json
$novaSessao = Invoke-RestMethod -Method Post -Uri "$u/auth/refresh" -ContentType "application/json" -Body $renovacao

# Logout: revoga o refresh token atual
$logout = @{ refreshToken = $novaSessao.refreshToken } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$u/auth/logout" -ContentType "application/json" -Body $logout
```

## Configuração e segurança

As principais configurações podem ser fornecidas por variáveis de ambiente:

| Variável | Finalidade |
|---|---|
| `NORTE_DB_URL` | URL JDBC do PostgreSQL |
| `NORTE_DB_USER` | Usuário do banco |
| `NORTE_DB_PASSWORD` | Senha do banco |
| `NORTE_JWT_SECRET` | Segredo usado para assinar tokens |
| `NORTE_CORS_ORIGINS` | Origens permitidas pelo CORS |
| `NORTE_API_URL` | URL da API no Flutter, via `--dart-define` |

- O schema do banco é controlado pelo Flyway; o Hibernate usa validação, não criação automática.
- O segredo JWT padrão existe somente para desenvolvimento local. Em produção, configure um segredo forte e exclusivo.
- O perfil `prod` deve ser usado com as configurações de produção devidamente definidas.
- O endpoint de perfil identifica o usuário pelo token autenticado, não por um ID recebido livremente do cliente.
- O refresh token é rotacionado a cada renovação e pode ser revogado no logout.
- O limitador de login atual é local à instância; não substitui uma estratégia distribuída de proteção contra abuso.
- Não inclua segredos, tokens, senhas reais ou dados pessoais em commits, issues ou logs.

**Privacidade ainda é uma frente de desenvolvimento:** consentimento, transparência sobre uso de IA, exportação e exclusão de dados precisam estar implementados e testados antes de qualquer piloto com usuários reais.

## Próximas etapas técnicas

1. Executar e corrigir os testes automatizados localmente.
2. Validar o ciclo completo de cadastro, login, perfil, refresh e logout.
3. Concluir a validação e integração do histórico da Conversa.
4. Integrar o serviço de conversa com IA, com contexto consentido, limites de uso e custo.
5. Permitir propor objetivos a partir da conversa e persistir somente após confirmação.
6. Completar controles de privacidade, consentimento, exportação e exclusão.
7. Reforçar testes de integração, autorização, CORS e segurança.
8. Rever armazenamento de sessão para a estratégia de distribuição escolhida.

## Documentação

- [Escopo do MVP](docs/MVP-ESCOPO.md)
- [Experiência mobile — Rose Edition](docs/norte-experiencia-rose.svg)
- [Momento humano](docs/norte-momento-humano.svg)
- [Escuta e acolhimento](docs/norte-escuta.svg)
- [Clareza e prioridades](docs/norte-clareza.svg)
- [Privacidade](docs/norte-privacidade.svg)

## Contribuição

O NORTE está em desenvolvimento ativo. Sugestões, críticas técnicas e ideias são bem-vindas. Para mudanças maiores, abra uma issue antes de iniciar uma implementação, para que escopo e direção possam ser alinhados.

## Autor

**Hernandes Zion**  
GitHub: [@HernandesWolf](https://github.com/HernandesWolf)

---

<p align="center">
  <strong>NORTE — Seu tempo. Sua história. Seu caminho.</strong><br/>
  <em>Um passo possível já é um começo.</em>
</p>
