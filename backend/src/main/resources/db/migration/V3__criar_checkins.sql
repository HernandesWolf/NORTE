-- V3: check-in diário ("Como você está chegando hoje?"). No máximo um por usuário por dia;
-- escolher de novo no mesmo dia atualiza o registro. O "dia" é calculado no servidor, no fuso configurado.
CREATE TABLE checkins (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id    UUID        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    dia           DATE        NOT NULL,
    estado        VARCHAR(20) NOT NULL,
    criado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uk_checkins_usuario_dia UNIQUE (usuario_id, dia),
    CONSTRAINT ck_checkins_estado CHECK (estado IN ('COM_ENERGIA', 'INDO_DEVAGAR', 'SOBRECARREGADO', 'AINDA_NAO_SEI'))
);
