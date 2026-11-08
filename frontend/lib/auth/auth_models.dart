/// Dados públicos do próprio usuário, como a API devolve em `/me`.
class Usuario {
  const Usuario({required this.id, required this.email, this.nomeExibicao});

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        email: json['email'] as String,
        nomeExibicao: json['nomeExibicao'] as String?,
      );

  final String id;
  final String email;
  final String? nomeExibicao;

  /// Nome para mostrar na tela; se a pessoa não informou, usamos o e-mail.
  String get nomeOuEmail {
    final nome = nomeExibicao?.trim();
    return (nome != null && nome.isNotEmpty) ? nome : email;
  }
}

/// Erro de comunicação com a API, já com mensagem pronta para mostrar à pessoa.
class ApiError implements Exception {
  const ApiError(this.mensagem, {this.status, this.erros = const {}});

  /// Falha de rede: sem internet, servidor desligado, CORS bloqueado ou tempo esgotado.
  const ApiError.rede()
      : mensagem = 'Não consegui falar com o servidor. Confira sua conexão e tente de novo.',
        status = null,
        erros = const {};

  final String mensagem;

  /// Código HTTP, ou `null` quando nem chegou resposta (falha de rede).
  final int? status;

  /// Erros por campo (ex.: `{'senha': 'A senha deve ter...'}`), vindos da validação do servidor.
  final Map<String, String> erros;

  bool get naoAutorizado => status == 401;

  @override
  String toString() => mensagem;
}
