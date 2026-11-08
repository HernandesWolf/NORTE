-- V2: sessões renováveis. Guardamos apenas o HASH do refresh token (nunca o valor bruto):
-- se o banco vazar, os tokens vazados não servem para entrar.
CREATE TABLE refresh_tokens (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id  UUID        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    token_hash  VARCHAR(64) NOT NULL,
    criado_em   TIMESTAMPTZ NOT NULL DEFAULT now(),
    expira_em   TIMESTAMPTZ NOT NULL,
    revogado_em TIMESTAMPTZ,
    CONSTRAINT uk_refresh_tokens_hash UNIQUE (token_hash)
);

CREATE INDEX ix_refresh_tokens_usuario ON refresh_tokens (usuario_id);
