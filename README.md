# Coma Bem

Aplicativo de ranking de restaurantes desenvolvido em Flutter/Dart para a disciplina de Desenvolvimento de Sistemas — SENAI Santos.

A interface segue o protótipo criado no Figma: fundo acinzentado, tons escuros nas barras e laranja suave como cor de marca.

## Telas

| Tela | Arquivo | O que faz |
|---|---|---|
| Apresentação | `screens/splash_screen.dart` | Marca do app por 3 segundos, depois vai para o login |
| Login | `screens/login_screen.dart` | Autentica e-mail e senha na tabela `usuario` |
| Criar conta | `screens/criar_conta_screen.dart` | Cadastra usuário e endereço no SQLite |
| Principal | `screens/home_screen.dart` | Casca com a barra de navegação de 4 abas |
| Início | `screens/aba_inicio.dart` | Busca, filtros por categoria e grade de pratos |
| Detalhe | `screens/detalhe_screen.dart` | Foto grande, nota, descrição e quantidade |
| Pedidos | `screens/aba_pedidos.dart` | Histórico com status de cada pedido |
| Carteira | `screens/aba_carteira.dart` | Saldo e recarga (UPDATE real no banco) |
| Perfil | `screens/aba_perfil.dart` | Dados da conta, saldo e menu de opções |
| Ajuda | `screens/ajuda_screen.dart` | Busca e perguntas frequentes |
| Novo prato | `screens/cadastro_screen.dart` | Formulário com câmera e GPS |

## Estrutura

```
lib/
├── main.dart
├── database/
│   ├── database_helper.dart    # conexão SQLite, INSERT, SELECT, autenticação
│   └── sessao.dart             # dados do usuário logado
├── screens/                    # as onze telas listadas acima
├── tema/
│   ├── app_cores.dart          # paleta
│   └── app_tema.dart           # ThemeData global
└── widgets/
    ├── foto_prato.dart         # imagem com fallback
    └── comuns.dart             # formatação de moeda, nota, selos
assets/
└── images/                     # fotos dos pratos (ver LEIA-ME.txt)
```

## Paleta

| Uso | Cor |
|---|---|
| Fundo geral | `#E9EAEC` |
| Cartões | `#FAFAFB` |
| Barras e splash | `#23272E` |
| Marca | `#C9633B` |
| Texto | `#1C2026` |

## Banco de dados

Criado automaticamente na primeira execução.

**usuario:** `usu_id_usuario`, `usu_nm_usuario`, `usu_ds_email`, `usu_ds_senha`, `usu_ds_telefone`, `usu_ds_endereco`, `usu_vl_saldo`

**restaurante:** `res_id_restaurante`, `res_nm_restaurante`, `res_ds_tipo_culinaria`, `res_ds_categoria`, `res_vl_preco`, `res_nu_ranking`, `res_nu_avaliacoes`, `res_ds_recomendacao`, `res_nu_latitude`, `res_nu_longitude`, `res_im_foto`, `res_nm_asset`

Acesso de teste: `maria@comabem.com` / `123456`

## Como executar

```bash
flutter pub get
flutter run
```

As permissões de câmera, GPS e internet já estão no `AndroidManifest.xml`.

## Imagens

Coloque as fotos dos pratos em `assets/images/`. Os nomes esperados estão no arquivo `LEIA-ME.txt` dentro da pasta. Sem elas o app roda igual: onde faltar imagem aparece um bloco cinza com ícone.

## Tecnologias

Flutter · Dart · SQLite (`sqflite`) · `image_picker` · `geolocator`
