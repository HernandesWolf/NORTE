package br.com.norte.ia;

/** Uma mensagem da conversa, no formato interno (independente do provedor de IA). */
public record MensagemIa(Papel papel, String texto) {

    public enum Papel {
        USUARIO,
        ASSISTENTE;

        /** Converte o rótulo usado pela API ("usuario" ou "assistente"). */
        static Papel deRotulo(String rotulo) {
            return "assistente".equals(rotulo) ? ASSISTENTE : USUARIO;
        }
    }
}
