# Assinatura persistente do APK Android

O APK de distribuição precisa ser assinado sempre com a mesma chave. Uma chave temporária/debug não é adequada: um APK futuro pode não atualizar o instalado e a perda do keystore pode impedir atualizações.

## Secrets necessários no GitHub

Configurar em Settings > Secrets and variables > Actions > New repository secret:

| Secret | Conteúdo |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Keystore de release codificado em Base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Senha do keystore |
| `ANDROID_KEY_ALIAS` | Alias da chave |
| `ANDROID_KEY_PASSWORD` | Senha da chave |

Não colar esses valores em chat, issue, comentário ou arquivo versionado.

## Criar o keystore uma única vez

Em um computador confiável com JDK instalado, executar (ajustando o caminho e o alias):

```powershell
keytool -genkeypair -v -keystore "$HOME\norte-release.jks" -alias norte -keyalg RSA -keysize 4096 -validity 10000
```

Guardar o arquivo `norte-release.jks` e as senhas em gerenciador de senhas seguro, com cópia de segurança offline. A chave privada não deve ficar dentro do repositório.

Para gerar o valor Base64 no PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\norte-release.jks")) | Set-Clipboard
```

Colar diretamente no secret `ANDROID_KEYSTORE_BASE64` do GitHub. Não salvar a saída em arquivo versionado.

## Regras

- Não gerar outro keystore para cada versão.
- Não usar a chave debug para release.
- Não publicar o APK se qualquer secret estiver ausente.
- Não compartilhar o keystore nem as senhas com terceiros.
- Guardar uma cópia de segurança offline. GitHub Secrets não substitui backup da chave.
- Se a chave for perdida, não será possível atualizar normalmente instalações assinadas com ela; será necessário reinstalar e os dados locais podem ser perdidos.

O workflow de APK deve validar os quatro secrets e assinar a saída com esta chave fixa antes de criar a Release.
