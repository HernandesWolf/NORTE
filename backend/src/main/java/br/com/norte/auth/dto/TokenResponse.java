package br.com.norte.auth.dto;

public record TokenResponse(String accessToken, String tipo, long expiraEmSegundos) {}
