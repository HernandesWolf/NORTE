CREATE TABLE consentimentos_ia (
    usuario_id UUID PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
    habilitado BOOLEAN NOT NULL DEFAULT FALSE,
    versao VARCHAR(30) NOT NULL,
    aceito_em TIMESTAMPTZ,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_consentimento_ia_aceite
        CHECK ((habilitado = FALSE) OR (aceito_em IS NOT NULL))
);
