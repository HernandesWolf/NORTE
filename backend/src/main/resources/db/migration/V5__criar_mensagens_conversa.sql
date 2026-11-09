CREATE TABLE mensagens_conversa (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    papel VARCHAR(20) NOT NULL,
    conteudo VARCHAR(4000) NOT NULL,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_mensagens_conversa_papel CHECK (papel IN ('USUARIO', 'NORTE'))
);
CREATE INDEX idx_mensagens_conversa_usuario_criado
    ON mensagens_conversa(usuario_id, criado_em, id);
