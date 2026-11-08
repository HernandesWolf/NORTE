package br.com.norte.auth.dto;

/**
 * Par de tokens entregue ao cliente.
 * O {@code accessToken} é curto (JWT) e vai no cabeçalho Authorization; o {@code refreshToken} é longo, opaco,
 * serve só para renovar a sessão e deve ficar em armazenamento seguro.
 */
public record TokenResponse(String accessToken, String refreshToken, String tipo, long expiraEmSegundos) {}
