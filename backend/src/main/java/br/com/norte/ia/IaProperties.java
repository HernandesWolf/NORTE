package br.com.norte.ia;

import java.util.Locale;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuração da IA da conversa. Tudo vem de variáveis de ambiente (veja o application.yml).
 *
 * <ul>
 *   <li>{@code provedor}: {@code desligado} (padrão), {@code groq} ou {@code gemini};</li>
 *   <li>{@code chave}: a chave de API do provedor. Nunca vai para log, resposta ou repositório;</li>
 *   <li>{@code modelo}: obrigatório no Gemini (o nome muda com o tempo); no Groq já existe um padrão;</li>
 *   <li>{@code limitePorMinuto} e {@code limitePorDia}: mensagens por pessoa, para proteger a cota do provedor;</li>
 *   <li>{@code limiteGlobalPorDia}: mensagens por dia somando todas as pessoas. A cota gratuita do provedor é da
 *       organização inteira, então este teto impede que muitas contas juntas a esgotem.</li>
 * </ul>
 */
@ConfigurationProperties(prefix = "norte.ia")
public record IaProperties(
        String provedor,
        String chave,
        String modelo,
        Integer limitePorMinuto,
        Integer limitePorDia,
        Integer limiteGlobalPorDia) {

    static final int PADRAO_POR_MINUTO = 5;
    static final int PADRAO_POR_DIA = 30;
    static final int PADRAO_GLOBAL_POR_DIA = 300;

    public IaProperties {
        provedor = provedor == null || provedor.isBlank() ? "desligado" : provedor.trim().toLowerCase(Locale.ROOT);
        chave = chave == null ? "" : chave.trim();
        modelo = modelo == null ? "" : modelo.trim();
        limitePorMinuto = limitePorMinuto == null || limitePorMinuto <= 0 ? PADRAO_POR_MINUTO : limitePorMinuto;
        limitePorDia = limitePorDia == null || limitePorDia <= 0 ? PADRAO_POR_DIA : limitePorDia;
        limiteGlobalPorDia =
                limiteGlobalPorDia == null || limiteGlobalPorDia <= 0 ? PADRAO_GLOBAL_POR_DIA : limiteGlobalPorDia;
    }

    /** Esconde a chave: o toString padrão de um record imprimiria todos os campos. */
    @Override
    public String toString() {
        return "IaProperties[provedor=" + provedor + ", modelo=" + modelo + ", chave=" + (chave.isEmpty() ? "(vazia)" : "***")
                + ", limitePorMinuto=" + limitePorMinuto + ", limitePorDia=" + limitePorDia
                + ", limiteGlobalPorDia=" + limiteGlobalPorDia + "]";
    }
}
