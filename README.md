# NORTE

Plataforma de orientação pessoal com IA: ajuda a pessoa a entender onde está, descobrir para onde pode ir e construir o caminho.

> Estado atual: **Fase 1 — Fundação técnica**. Escopo fechado do MVP em `docs/MVP-ESCOPO.md`.

## Estrutura

```
norte/
├── backend/            Java 21 + Spring Boot 3.5.x (monólito modular)
├── docs/               Escopo do MVP, decisões e roadmap
├── docker-compose.yml  PostgreSQL 16 para desenvolvimento local (porta 5433)
└── README.md
```

## Como rodar

Pré-requisitos: JDK 21+, Maven 3.9+, Docker Desktop (com WSL2 no Windows).

```bash
docker compose up -d      # banco em localhost:5433
cd backend
mvn test                  # testes (não precisam do banco)
mvn spring-boot:run       # API em http://localhost:8080
```

Verificação:

- `GET /api/v1/status` → `{"app":"NORTE","status":"ok",...}`
- `GET /actuator/health` → `{"status":"UP"}`

## Autenticação (v0.2)

| Método | Rota | Acesso | Descrição |
|---|---|---|---|
| POST | `/api/v1/auth/registro` | público | Cria conta (e-mail + senha de 8 a 72 caracteres) |
| POST | `/api/v1/auth/login` | público | Retorna `accessToken` (JWT, validade de 15 min) |
| GET | `/api/v1/me` | token | Perfil do dono do token |

Decisões de segurança:

- Senha guardada só como hash **BCrypt** (custo 12). Nunca em texto puro, nunca devolvida pela API.
- API **stateless**: JWT HS256 no cabeçalho `Authorization: Bearer <token>`.
- `/me` usa o usuário do **token**, nunca de parâmetro da URL.
- Login devolve a mesma mensagem para e-mail inexistente e senha errada, e gasta tempo equivalente nos dois casos.
- Segredo do JWT vem de `NORTE_JWT_SECRET`. O valor padrão serve **só para desenvolvimento**; com o perfil `prod` ativo, a aplicação se recusa a iniciar com ele.

Teste manual (PowerShell, com a API rodando):

```powershell
$u = "http://localhost:8080/api/v1"
$cred = @{ email = "ana@exemplo.com"; senha = "senhaforte123"; nomeExibicao = "Ana" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$u/auth/registro" -ContentType "application/json" -Body $cred
$t = Invoke-RestMethod -Method Post -Uri "$u/auth/login" -ContentType "application/json" -Body $cred
Invoke-RestMethod -Uri "$u/me" -Headers @{ Authorization = "Bearer $($t.accessToken)" }
```

## Limitações conhecidas

- Ainda **não há** refresh token, logout com revogação, limite de tentativas de login (rate limiting) nem recuperação de senha. São as próximas etapas.
- Cadastro revela se um e-mail já existe (mensagem de conflito). Aceito no MVP; reavaliar quando houver verificação de e-mail.
- Testes de integração com banco real (Testcontainers) ainda não foram adicionados.

## Próximos passos

1. Refresh token, logout e rate limiting no login.
2. Perfil progressivo e objetivos.
3. AI Gateway (interface independente de provedor) com limites de uso e custo.
