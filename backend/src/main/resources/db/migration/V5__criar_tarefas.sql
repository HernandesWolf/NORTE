-- Tarefas pertencem a um objetivo. "dia" (1 a 7) coloca a tarefa no plano de 7 dias do objetivo;
-- NULL significa que a tarefa ainda não foi encaixada em nenhum dia.
CREATE TABLE tarefas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    objetivo_id UUID NOT NULL REFERENCES objetivos(id) ON DELETE CASCADE,
    titulo VARCHAR(120) NOT NULL,
    dia INTEGER,
    concluida BOOLEAN NOT NULL DEFAULT FALSE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_tarefas_dia CHECK (dia IS NULL OR dia BETWEEN 1 AND 7)
);
CREATE INDEX idx_tarefas_objetivo_usuario ON tarefas(objetivo_id, usuario_id, criado_em);
