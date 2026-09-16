# Coma Bem — v03

Etapa de interface, refatoração e regras de negócio, em cima do que já
existia nas atividades anteriores (SQLite, câmera e GPS continuam
intactos).

## Estrutura nova de pastas

```
lib/
├── components/                        # criados na sessão de Code Review
│   ├── campo_formulario_customizado.dart
│   └── botao_customizado.dart
├── estado/
│   └── carrinho.dart                  # estado global do carrinho
├── tema/
│   ├── app_cores.dart                 # paleta (já existia)
│   ├── app_espacos.dart               # NOVO: espaçamento, raios, tipografia
│   └── app_tema.dart
├── screens/
│   ├── carrinho_screen.dart           # NOVO
│   ├── checkout_screen.dart           # NOVO
│   ├── rastreamento_screen.dart       # NOVO
│   ├── aba_admin.dart                 # NOVO (painel da loja)
│   └── produto_form_screen.dart       # NOVO (CRUD de produto)
└── ...
```

## Design System

Tokens centralizados em `lib/tema/`:

| Token | Valores |
|---|---|
| Espaçamento | 4, 8, 12, 16, 20, 24, 32 (`AppEspacos.xs → xxxl`) |
| Raios | 8 etiquetas, 12 campos, 14 botões, 16 cartões, 20 pílulas |
| Tipografia | `display` 26, `titulo` 23, `secao` 17, `destaque` 15, `corpo` 14.5, `auxiliar` 13, `legenda` 11 |
| Alvo de toque | `AppEspacos.alvoToque` = 48 px |

O coral do protótipo (`#FF5E36`) ficou registrado como
`AppCores.laranjaPrototipo`. A cor em uso é `#C9633B`, que passa no
contraste 4.5:1 exigido pela WCAG AA para texto pequeno.

## Acessibilidade

- Todo elemento clicável tem no mínimo 48 x 48 px de área de toque.
- Ícones sem texto exigem `rotulo` no construtor (`BotaoIconeCustomizado`)
  — não é possível criar um botão de ícone mudo por descuido.
- Campos de formulário anunciam rótulo + dica (`Semantics(textField: true)`).
- Botões anunciam texto e estado habilitado/desabilitado.
- Etapas do rastreamento anunciam "concluída" ou "pendente".

## Navegação

`HomeScreen` monta as abas conforme a permissão da conta. A troca passa
por `_trocarAba`, que ignora o toque quando o índice já é o atual — sem
`setState`, sem redesenho e sem empilhar tela.

| Aba | Conta comum | Administradora |
|---|---|---|
| Início, Pedidos, Carteira, Perfil | ✅ | ✅ |
| Gerenciar | — | ✅ |

## Banco de dados (versão 3)

Colunas novas em `restaurante`: `res_nu_estoque`, `res_ds_url_imagem`.

Tabelas novas:

- `pedido` — usuário, data, status, subtotal, entrega, total, endereço,
  pagamento.
- `pedido_item` — item, quantidade e preço unitário congelado na compra.

Métodos novos em `DatabaseHelper`: `buscarRestaurante`,
`atualizarRestaurante` (UPDATE), `excluirRestaurante` (DELETE),
`baixarEstoque`, `criarPedido` (transação), `listarPedidos`,
`avancarStatusPedido`.

## Regra de negócio: administradora

`Sessao.isAdmin` é definido no login comparando o e-mail autenticado com
`Sessao.emailAdmin` (`maria@comabem.com`, senha `123456`, já semeada no
banco). Com a flag ligada:

- aparece a aba **Gerenciar** e o cartão "Painel da loja" no perfil;
- o detalhe do prato ganha o botão de edição;
- CRUD completo em `ProdutoFormScreen`: nome, descrição, preço,
  quantidade em estoque e URL da imagem.

`AbaAdmin` também checa `Sessao.isAdmin` no `build`, então mesmo quem
chegar à tela por outro caminho vê "Acesso restrito".

## Fluxo de compra

Cardápio → carrinho (`Carrinho.instancia`, `ChangeNotifier`) → checkout
(endereço, pagamento, resumo) → gravação em transação → rastreamento com
linha do tempo em quatro etapas.

Entrega: R$ 7,90, grátis a partir de R$ 60,00. Pagamento com saldo é
bloqueado quando não há dinheiro suficiente na carteira.

## Refatoração (guia de Code Review)

`cadastro_screen.dart` e `login_screen.dart` deixaram de repetir
`RotuloCampo + TextField + SizedBox` e passaram a usar
`CampoFormularioCustomizado`. Os `ElevatedButton` com estilo próprio
deram lugar ao `BotaoCustomizado`, que é o desafio do botão da dupla.

---

# Coma Bem — v04

Etapa de testes de integração (QA) e atualização do logotipo.

## Testes de integração

`integration_test/app_test.dart` roda o app de verdade no emulador e
simula o usuário: preenche e-mail/senha, entra, valida o catálogo e
navega até a tela de cadastro.

```bash
flutter pub get
flutter test integration_test/app_test.dart
```

Dependência nova em `dev_dependencies`: `integration_test` (SDK do Flutter).

Conta usada pelo robô: `admin@comabem.com` · `senha123` (semeada em
`_carregarDadosIniciais` e recriada pelo próprio teste caso o banco já
existisse). Ela entra na lista de administradoras porque o FAB de novo
cadastro só aparece para esse perfil.

Detalhes de implementação:

- A Splash tem `LinearProgressIndicator` (animação infinita), então o
  teste avança o tempo com `pump(Duration)` no lugar de `pumpAndSettle()`,
  que ficaria preso esperando a tela "assentar".
- `find.byIcon(Icons.add)` casa com vários widgets (o botão de adicionar
  ao carrinho de cada card), por isso a busca é limitada ao
  `FloatingActionButton` com `find.descendant`.

## Logotipo novo

`assets/images/Logo_Principal_Coma_Bem.jpg` — prato com salmão e grãos
ladeado pelos talheres. Usado no Login (`height: 150`).

O arquivo original vinha com o xadrez de transparência "chapado" dentro
do JPEG. Ele foi limpo e gerado em duas versões:

- `.jpg` — fundo em `#E9EAEC`, igual ao `AppCores.fundo`, usado no Login.
- `.png` — fundo realmente transparente, usado na Splash (fundo escuro).

## Âncoras de texto criadas para o teste

- `aba_inicio.dart`: título de seção **Catálogo de Restaurantes**.
- `cadastro_screen.dart`: rótulo **Foto do Prato** acima do bloco da foto.
