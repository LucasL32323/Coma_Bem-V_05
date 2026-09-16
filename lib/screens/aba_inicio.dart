import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../database/sessao.dart';
import '../estado/carrinho.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';
import '../widgets/comuns.dart';
import '../widgets/foto_prato.dart';
import 'cadastro_screen.dart';
import 'carrinho_screen.dart';
import 'detalhe_screen.dart';

/// Tela inicial (home-inicio): saudação, busca, filtros por categoria e
/// grade dos pratos lidos da tabela 'restaurante'.
class AbaInicio extends StatefulWidget {
  const AbaInicio({super.key});

  @override
  State<AbaInicio> createState() => _AbaInicioState();
}

class _AbaInicioState extends State<AbaInicio> {
  final _buscaController = TextEditingController();

  List<Map<String, dynamic>> _pratos = const [];
  List<String> _categorias = const ['Todos'];
  String _categoriaAtual = 'Todos';
  String _busca = '';
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final categorias = await DatabaseHelper.instancia.listarCategorias();
    final pratos = await DatabaseHelper.instancia.listarRestaurantes(
      categoria: _categoriaAtual,
      busca: _busca,
    );

    if (!mounted) return;
    setState(() {
      _categorias = ['Todos', ...categorias];
      _pratos = pratos;
      _carregando = false;
    });
  }

  Future<void> _abrirDetalhe(Map<String, dynamic> prato) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => DetalheScreen(prato: prato)),
    );
    _carregarDados();
  }

  Future<void> _abrirCarrinho() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _abrirCadastro() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
    _carregarDados();
  }

  void _adicionarAoCarrinho(Map<String, dynamic> prato) {
    final estoque = (prato['res_nu_estoque'] as num?)?.toInt() ?? 0;
    if (estoque <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto esgotado no momento.')),
      );
      return;
    }

    Carrinho.instancia.adicionar(prato);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${prato['res_nm_restaurante']} foi para o carrinho.'),
        action: SnackBarAction(
          label: 'Ver carrinho',
          textColor: Colors.white,
          onPressed: _abrirCarrinho,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundo,
      floatingActionButton: Sessao.isAdmin
          ? FloatingActionButton(
              onPressed: _abrirCadastro,
              backgroundColor: AppCores.laranja,
              tooltip: 'Cadastrar novo prato',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _cabecalho(),
            _campoBusca(),
            _tituloCatalogo(),
            _filtrosCategoria(),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _carregarDados,
                      child: _grade(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Título da seção do cardápio. Também serve de âncora para o teste de
  /// integração, que valida a chegada na tela principal por este texto.
  Widget _tituloCatalogo() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, AppEspacos.md, 20, AppEspacos.xs),
      child: Text(
        'Catálogo de Restaurantes',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppCores.texto,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // CABEÇALHO
  // ---------------------------------------------------------------
  Widget _cabecalho() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${Sessao.primeiroNome}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppCores.texto,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppEspacos.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: AppCores.laranja,
                    ),
                    const SizedBox(width: AppEspacos.xs),
                    Expanded(
                      child: Text(
                        Sessao.endereco,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppCores.textoSuave,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _botaoCarrinho(),
        ],
      ),
    );
  }

  Widget _botaoCarrinho() {
    final total = Carrinho.instancia.totalItens;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: _abrirCarrinho,
          tooltip: 'Abrir o carrinho',
          icon: const Icon(Icons.shopping_bag_outlined,
              color: AppCores.texto, size: 26),
        ),
        if (total > 0)
          Positioned(
            right: 4,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: AppCores.laranja,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$total',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // BUSCA E FILTROS
  // ---------------------------------------------------------------
  Widget _campoBusca() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppEspacos.xl),
      child: TextField(
        controller: _buscaController,
        textInputAction: TextInputAction.search,
        onChanged: (texto) {
          _busca = texto;
          _carregarDados();
        },
        decoration: InputDecoration(
          hintText: 'Buscar prato ou culinária...',
          filled: true,
          fillColor: AppCores.superficie,
          prefixIcon: const Icon(Icons.search, color: AppCores.textoSuave),
          suffixIcon: _busca.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _buscaController.clear();
                    _busca = '';
                    _carregarDados();
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRaios.pilula),
            borderSide: const BorderSide(color: AppCores.borda),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRaios.pilula),
            borderSide: const BorderSide(color: AppCores.borda),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRaios.pilula),
            borderSide: const BorderSide(color: AppCores.laranja, width: 1.6),
          ),
        ),
      ),
    );
  }

  Widget _filtrosCategoria() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppEspacos.xl,
          vertical: AppEspacos.sm,
        ),
        itemCount: _categorias.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppEspacos.sm),
        itemBuilder: (_, indice) {
          final categoria = _categorias[indice];
          final ativa = categoria == _categoriaAtual;

          return ChoiceChip(
            label: Text(categoria),
            selected: ativa,
            showCheckmark: false,
            selectedColor: AppCores.laranja,
            backgroundColor: AppCores.superficie,
            side: const BorderSide(color: AppCores.borda),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: ativa ? Colors.white : AppCores.textoSuave,
            ),
            onSelected: (_) {
              _categoriaAtual = categoria;
              _carregarDados();
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------
  // GRADE DE PRATOS
  // ---------------------------------------------------------------
  Widget _grade() {
    if (_pratos.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 90),
          Icon(Icons.search_off, size: 40, color: AppCores.textoClaro),
          SizedBox(height: AppEspacos.md),
          Text(
            'Nenhum prato encontrado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppCores.textoSuave),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _pratos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppEspacos.md,
        mainAxisSpacing: AppEspacos.md,
        childAspectRatio: 0.70,
      ),
      itemBuilder: (_, indice) => _cartaoPrato(_pratos[indice]),
    );
  }

  Widget _cartaoPrato(Map<String, dynamic> prato) {
    final nome = prato['res_nm_restaurante'] as String? ?? '';
    final preco = (prato['res_vl_preco'] as num?)?.toDouble() ?? 0;
    final nota = (prato['res_nu_ranking'] as num?)?.toDouble() ?? 0;

    return InkWell(
      onTap: () => _abrirDetalhe(prato),
      borderRadius: BorderRadius.circular(AppRaios.cartao),
      child: Container(
        decoration: BoxDecoration(
          color: AppCores.superficie,
          borderRadius: BorderRadius.circular(AppRaios.cartao),
          border: Border.all(color: AppCores.borda),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FotoPrato(
              asset: prato['res_nm_asset'] as String?,
              caminhoLocal: prato['res_im_foto'] as String?,
              url: prato['res_ds_url_imagem'] as String?,
              altura: 104,
              descricao: 'Foto do prato $nome',
            ),
            Padding(
              padding: const EdgeInsets.all(AppEspacos.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppCores.texto,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppEspacos.xs),
                  NotaAvaliacao(nota: nota, tamanho: 11.5),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppEspacos.md,
                0,
                AppEspacos.sm,
                AppEspacos.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatarReal(preco),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppCores.laranja,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _adicionarAoCarrinho(prato),
                    tooltip: 'Adicionar ao carrinho',
                    visualDensity: VisualDensity.compact,
                    icon: const CircleAvatar(
                      radius: 14,
                      backgroundColor: AppCores.laranja,
                      child: Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
