/// Endereço base da API do NORTE.
///
/// Dá para trocar na hora de rodar, sem mexer no código:
///
///     flutter run -d chrome --dart-define=NORTE_API_URL=http://localhost:8080
///
/// No emulador Android, o "localhost" do computador é `10.0.2.2`.
const String apiBaseUrl = String.fromEnvironment(
  'NORTE_API_URL',
  defaultValue: 'http://localhost:8080',
);
