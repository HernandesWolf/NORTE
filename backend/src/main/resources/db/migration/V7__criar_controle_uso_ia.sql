CREATE TABLE ia_uso_diario_usuario (
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    dia DATE NOT NULL,
    chamadas INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (usuario_id, dia),
    CONSTRAINT ck_ia_uso_diario_chamadas CHECK (chamadas >= 0)
);

CREATE TABLE ia_uso_mensal_global (
    mes DATE PRIMARY KEY,
    chamadas INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT ck_ia_uso_mensal_chamadas CHECK (chamadas >= 0)
);
