/// Como a pessoa diz que está chegando no dia. O [codigo] é o nome usado pela API.
enum EstadoCheckin {
  comEnergia('COM_ENERGIA'),
  indoDevagar('INDO_DEVAGAR'),
  sobrecarregado('SOBRECARREGADO'),
  aindaNaoSei('AINDA_NAO_SEI');

  const EstadoCheckin(this.codigo);

  final String codigo;

  /// Converte o texto da API; devolve `null` para um valor que este app não conhece.
  static EstadoCheckin? deCodigo(Object? codigo) {
    for (final estado in values) {
      if (estado.codigo == codigo) {
        return estado;
      }
    }
    return null;
  }
}
