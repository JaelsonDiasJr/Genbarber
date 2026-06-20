<p align="center">
  <img src="assets/images/splash_screen.png" alt="GenBarber Splash Screen" width="220"/>
</p>

<h1 align="center">GenBarber 💈</h1>

<p align="center">
  Plataforma mobile de agendamento para barbearias, conectando clientes e barbeiros de forma simples e eficiente.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white"/>
  <img src="https://img.shields.io/badge/OpenStreetMap-7EBC6F?style=flat&logo=openstreetmap&logoColor=white"/>
</p>

---

## 📱 Sobre o projeto

O **GenBarber** é um aplicativo mobile desenvolvido em Flutter que reúne barbearias em uma única plataforma, tornando o processo de agendamento e gerenciamento mais simples tanto para clientes quanto para barbeiros.

- **Clientes** podem localizar barbearias próximas no mapa, visualizar serviços disponíveis e realizar agendamentos de forma rápida.
- **Barbeiros** têm acesso a um painel completo de gerenciamento com agenda, catálogo de serviços e resumo financeiro.

---

## 🛠️ Tecnologias utilizadas

| Tecnologia | Finalidade |
|---|---|
| **Flutter** | Framework principal para desenvolvimento mobile |
| **Dart** | Linguagem de programação |
| **Firebase Auth** | Autenticação de usuários (email/senha) |
| **Cloud Firestore** | Banco de dados em tempo real |
| **Firebase Storage** | Armazenamento de imagens |
| **Provider** | Gerenciamento de estado (MVVM) |
| **flutter_map** | Renderização de mapas (OpenStreetMap) |
| **geolocator** | Localização do usuário |

---

## 👥 Integrantes

| Nome | Função |
|---|---|
| Jaelson | Desenvolvedor |

---

## ▶️ Como executar

### Pré-requisitos

- Flutter SDK 3.0 ou superior
- Android Studio ou VS Code
- Conta no Firebase
- Dispositivo Android ou emulador

### Passo a passo

**1. Clone o repositório**
```bash
git clone https://github.com/seu-usuario/genbarber.git
cd genbarber
```

**2. Configure o Firebase**
- Acesse [console.firebase.google.com](https://console.firebase.google.com)
- Crie um projeto chamado `genbarber`
- Ative: **Authentication** (E-mail/senha), **Firestore** e **Storage**
- Registre um app Android com o package `com.genbarber.app`
- Baixe o `google-services.json` e coloque em `android/app/`

**3. Instale as dependências**
```bash
flutter pub get
```

**4. Execute o app**
```bash
flutter run
```

---

## 📁 Arquitetura

O projeto adota o padrão **MVVM + Repository**:

```
lib/
├── models/           # Entidades de dados
├── core/
│   ├── services/     # Comunicação com Firebase (Repository)
│   └── providers/    # Gerenciamento de estado (ViewModel)
├── screens/          # Telas do app (View)
└── widgets/          # Componentes reutilizáveis
```

---

## 📄 Licença

Este projeto foi desenvolvido para fins acadêmicos.
