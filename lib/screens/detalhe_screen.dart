import 'package:flutter/material.dart';
import 'carrinho_screen.dart';
import 'produto_form_screen.dart';
import '../components/botao_customizado.dart';
import '../database/database_helper.dart';
import '../database/sessao.dart';
import '../estado/carrinho.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';
import '../widgets/foto_prato.dart';
import '../widgets/comuns.dart';

/// Detalhe do prato: foto grande, nota, descrição e seletor de quantidade.
///
/// Recebe pelo construtor a linha do banco correspondente ao item tocado
/// na tela inicial.
class DetalheScreen extends StatefulWidget {
  final Map<String, dynamic> prato;

  const DetalheScreen({super.key, required this.prato});

  @override
  State<DetalheScreen> createState() => _DetalheScreenState();
}

class _DetalheScreenState extends State<DetalheScreen> {
  int _quantidade = 1;
  bool _favorito = false;

  /// Cópia local do prato: quando a administradora edita o produto, os
  /// dados novos entram aqui sem precisar fechar e reabrir a tela.
  late Map<String, dynamic> _prato = widget.prato;

  int get _estoque => (_prato['res_nu_estoque'] as num?)?.toInt() ?? 0;

  /// Envia o prato para o carrinho na quantidade escolhida.
  void _adicionarAoCarrinho() {
    if (_estoque <= 0) {
      _avisar('Produto esgotado no momento.');
      return;
    }

    Carrinho.instancia.adicionar(_prato, quantidade: _quantidade);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$_quantidade × ${_prato['res_nm_restaurante']} '
          'adicionado ao carrinho.',
        ),
        action: SnackBarAction(
          label: 'Ver carrinho',
          textColor: Colors.white,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CarrinhoScreen()),
          ),
        ),
      ),
    );
  }

  /// Atalho de edição disponível somente para a conta administradora.
  Future<void> _editarProduto() async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProdutoFormScreen(produto: _prato),
      ),
    );

    if (salvou != true) return;

    final id = (_prato['res_id_restaurante'] as num).toInt();
    final atualizado =
        await DatabaseHelper.instancia.buscarRestaurante(id);

    if (!mounted) return;

    // Se o produto foi excluído no formulário, não há o que exibir aqui.
    if (atualizado == null) {
      Navigator.pop(context);
      return;
    }

    setState(() => _prato = atualizado);
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final prato = _prato;
    final preco = (prato['res_vl_preco'] as num?)?.toDouble() ?? 0;
    final nota = (prato['res_nu_ranking'] as num?)?.toDouble() ?? 0;
    final avaliacoes = (prato['res_nu_avaliacoes'] as num?)?.toInt() ?? 0;
    final total = preco * _quantidade;

    return Scaffold(
      backgroundColor: AppCores.fundo,

      body: CustomScrollView(
        slivers: [
          // SliverAppBar com foto de fundo: a imagem encolhe conforme a
          // pessoa rola a tela, deixando só a barra no topo.
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppCores.escuro,
            leading: _botaoCircular(
              icone: Icons.arrow_back,
              rotulo: 'Voltar',
              aoTocar: () => Navigator.pop(context),
            ),
            actions: [
              // A engrenagem de edição só existe para quem administra.
              if (Sessao.isAdmin)
                _botaoCircular(
                  icone: Icons.edit_outlined,
                  rotulo: 'Editar este produto',
                  aoTocar: _editarProduto,
                ),
              _botaoCircular(
                icone: _favorito ? Icons.favorite : Icons.favorite_border,
                rotulo: _favorito
                    ? 'Remover dos favoritos'
                    : 'Salvar nos favoritos',
                cor: _favorito ? AppCores.laranja : AppCores.texto,
                aoTocar: () => setState(() => _favorito = !_favorito),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: FotoPrato(
                asset: prato['res_nm_asset'] as String?,
                url: prato['res_ds_url_imagem'] as String?,
                caminhoLocal: prato['res_im_foto'] as String?,
                raio: 0,
                descricao: 'Foto de ${prato['res_nm_restaurante']}',
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppCores.fundo,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome e preço lado a lado.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          prato['res_nm_restaurante'] as String,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: AppCores.texto,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatarReal(preco),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: AppCores.laranja,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  NotaAvaliacao(nota: nota, avaliacoes: avaliacoes),

                  const SizedBox(height: 12),

                  // Etiquetas com a categoria e o tipo de culinária.
                  Wrap(
                    spacing: 8,
                    children: [
                      _etiqueta(prato['res_ds_categoria'] as String? ?? ''),
                      _etiqueta(
                        prato['res_ds_tipo_culinaria'] as String? ?? '',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 20),

                  const Text(
                    'Descrição',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppCores.texto,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (prato['res_ds_recomendacao'] as String?)?.isNotEmpty ==
                            true
                        ? prato['res_ds_recomendacao'] as String
                        : 'Nenhuma descrição cadastrada para este prato.',
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.65,
                      color: AppCores.textoSuave,
                    ),
                  ),

                  // A localização só aparece se o GPS foi usado no cadastro.
                  if ((prato['res_nu_latitude'] as String?)?.isNotEmpty ==
                      true) ...[
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppCores.superficie,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppCores.borda),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 20,
                            color: AppCores.laranja,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Local do cadastro',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppCores.texto,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${prato['res_nu_latitude']}, '
                                  '${prato['res_nu_longitude']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppCores.textoSuave,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 26),

                  // Seletor de quantidade.
                  Row(
                    children: [
                      const Text(
                        'Quantidade',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppCores.texto,
                        ),
                      ),
                      const Spacer(),
                      _botaoQuantidade(
                        icone: Icons.remove,
                        rotulo: 'Diminuir quantidade',
                        // Abaixo de 1 o botão fica desabilitado.
                        aoTocar: _quantidade > 1
                            ? () => setState(() => _quantidade--)
                            : null,
                      ),
                      SizedBox(
                        width: 46,
                        child: Text(
                          '$_quantidade',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppCores.texto,
                          ),
                        ),
                      ),
                      _botaoQuantidade(
                        icone: Icons.add,
                        rotulo: 'Aumentar quantidade',
                        destaque: true,
                        // Não deixa pedir mais do que existe em estoque.
                        aoTocar: _quantidade < _estoque
                            ? () => setState(() => _quantidade++)
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppEspacos.md),

                  // Aviso de disponibilidade, alimentado pelo estoque que
                  // a administradora controla no painel de gerenciamento.
                  Row(
                    children: [
                      Icon(
                        _estoque > 0
                            ? Icons.inventory_2_outlined
                            : Icons.remove_shopping_cart_outlined,
                        size: 16,
                        color: _estoque > 0
                            ? AppCores.textoSuave
                            : AppCores.vermelho,
                      ),
                      const SizedBox(width: AppEspacos.sm),
                      Text(
                        _estoque > 0
                            ? '$_estoque unidades disponíveis'
                            : 'Produto esgotado no momento',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _estoque > 0
                              ? AppCores.textoSuave
                              : AppCores.vermelho,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Botão fixo no rodapé, sempre visível durante a rolagem.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppCores.superficie,
          border: Border(top: BorderSide(color: AppCores.borda)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: SafeArea(
          top: false,
          child: BotaoCustomizado(
            texto: _estoque > 0
                ? 'Adicionar ao carrinho — ${formatarReal(total)}'
                : 'Produto esgotado',
            icone: Icons.add_shopping_cart,
            dicaAcessibilidade:
                'Coloca $_quantidade unidades no carrinho de compras',
            aoPressionar: _estoque > 0 ? _adicionarAoCarrinho : null,
          ),
        ),
      ),
    );
  }

  /// Botão redondo branco sobre a foto, usado no voltar, no favoritar e na
  /// edição administrativa. O [rotulo] é obrigatório porque um ícone
  /// sozinho não diz nada a quem usa leitor de tela.
  Widget _botaoCircular({
    required IconData icone,
    required VoidCallback aoTocar,
    required String rotulo,
    Color cor = AppCores.texto,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: BotaoIconeCustomizado(
        icone: icone,
        rotulo: rotulo,
        cor: cor,
        fundo: AppCores.superficie,
        aoPressionar: aoTocar,
      ),
    );
  }

  Widget _botaoQuantidade({
    required IconData icone,
    required VoidCallback? aoTocar,
    required String rotulo,
    bool destaque = false,
  }) {
    final habilitado = aoTocar != null;

    return Semantics(
      button: true,
      enabled: habilitado,
      label: rotulo,
      child: ExcludeSemantics(child: _desenhoBotaoQuantidade(
        icone: icone,
        aoTocar: aoTocar,
        destaque: destaque,
      )),
    );
  }

  Widget _desenhoBotaoQuantidade({
    required IconData icone,
    required VoidCallback? aoTocar,
    bool destaque = false,
  }) {
    final habilitado = aoTocar != null;

    return Material(
      color: destaque && habilitado
          ? AppCores.laranja
          : AppCores.superficieAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: destaque && habilitado ? AppCores.laranja : AppCores.borda,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: aoTocar,
        child: SizedBox(
          width: AppEspacos.alvoToque,
          height: AppEspacos.alvoToque,
          child: Icon(
            icone,
            size: 18,
            color: destaque && habilitado
                ? Colors.white
                : (habilitado ? AppCores.texto : AppCores.textoClaro),
          ),
        ),
      ),
    );
  }

  Widget _etiqueta(String texto) {
    if (texto.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppCores.laranjaFundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppCores.laranjaEscuro,
        ),
      ),
    );
  }
}
