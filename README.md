# APS Final - ECO Mobile

A ÚLTIMA APS do curso - Aplicativo android desenvolvido em Flutter

## ⚠️ Importante: Suporte de Plataforma

**Este aplicativo oferece suporte EXCLUSIVAMENTE para Android.**

❌ **iOS NÃO é suportado** devido aos altos custos de licenciamento da Apple, que incluem:
- Taxa anual do Apple Developer Program (USD $99/ano)
- Necessidade de hardware Apple (Mac) para desenvolvimento e compilação

Por estas razões financeiras, o desenvolvimento foi focado exclusivamente na plataforma Android.

## 🛠️ Pré-requisitos

Antes de compilar o aplicativo, certifique-se de ter instalado:

1. **Flutter SDK** (versão 3.9.2 ou superior)
   - Download: https://flutter.dev/docs/get-started/install
   
2. **Android Studio**, **Android SDK** ou **IntelliJ IDEA** com plugin do Android
   - Download: https://developer.android.com/studio
   
3. **Java Development Kit (JDK)** - versão 11 ou superior
   - Download: https://adoptium.net/pt-BR/temurin/releases?version=11&os=any&arch=any
   
4. **Kotlin** (incluído no Android Studio e IntelliJ IDEA)

5. **Git** (para clonar o repositório)

### Configuração do Ambiente

1. Verifique se o Flutter está instalado corretamente:
```bash
flutter doctor
```

2. Aceite as licenças do Android SDK (se necessário):
```bash
flutter doctor --android-licenses
```

3. Certifique-se de ter pelo menos um dispositivo Android disponível:
   - Emulador Android (AVD)
   - Dispositivo físico com modo desenvolvedor e depuração USB ativada

## 🚀 Como Compilar

### 1. Instalar Dependências

Navegue até a pasta do projeto e execute:

```bash
flutter pub get
```

### 2. Compilar para Debug (Desenvolvimento)

Para compilar e executar em modo debug:

```bash
flutter run
```

Ou especificamente para Android:

```bash
flutter run -d android
```

### 3. Compilar para Release (Produção)

#### APK (Android Package)

Para gerar um APK de release:

```bash
flutter build apk --release
```

O APK será gerado em: `build/app/outputs/flutter-apk/app-release.apk`

### 4. Instalar no Dispositivo

Após compilar, você pode instalar diretamente:

```bash
flutter install
```

Ou instalar o APK manualmente:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Ou transfira o APK para o dispositivo e instale através do gerenciador de arquivos.

## 🔧 Configurações do Projeto

### Identificador do Aplicativo
- **Application ID:** `com.allonsve.facul.aps_final`
- **Namespace:** `com.allonsve.facul.aps_final`

### Versões Android
- **Compile SDK:** Definido pelo Flutter
- **Min SDK:** Definido pelo Flutter (mínimo Android 5.0)
- **Target SDK:** Definido pelo Flutter (última versão estável)
- **Java/Kotlin Target:** Java 11

### Permissões

O aplicativo requer as seguintes permissões (devido ao uso do geolocator):
- `ACCESS_FINE_LOCATION` - Localização precisa
- `ACCESS_COARSE_LOCATION` - Localização aproximada

## 🐛 Solução de Problemas

### Erro de Licenças Android

Se encontrar erros relacionados a licenças:
```bash
flutter doctor --android-licenses
```

### Erro de Gradle

Limpe o cache do Gradle:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Erro de Permissões

Certifique-se de que as permissões estão declaradas no `AndroidManifest.xml` e que o usuário concedeu as permissões necessárias no dispositivo.

## 📝 Estrutura do Projeto

```
App/
├── android/              # Código nativo Android (Kotlin)
├── lib/                  # Código Flutter (Dart)
│   └── main.dart        # Ponto de entrada do aplicativo
├── test/                 # Testes unitários
├── pubspec.yaml         # Dependências e configurações
└── README.md            # Este arquivo
```

## 👥 Desenvolvimento

Este projeto foi desenvolvido como trabalho acadêmico (APS) do curso.

## 📄 Licença

Projeto acadêmico - Todos os direitos reservados.

---

**Nota:** Este README foi criado para facilitar a compilação e compreensão do projeto. Para dúvidas ou problemas, consulte a documentação oficial do Flutter em https://flutter.dev/docs

