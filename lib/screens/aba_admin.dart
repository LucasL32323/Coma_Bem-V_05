import 'package:flutter/material.dart';
import '../components/botao_customizado.dart';
import '../database/database_helper.dart';
import '../database/sessao.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';
import '../widgets/comuns.dart';
import '../widgets/foto_prato.dart';
import 'produto_form_screen.dart';

/// Painel administrativo da loja — visível apenas para contas com
/// [Sessao.isAdmin] verdadeiro.
///
/// Reúne o CRUD completo dos produtos: a listagem (Read) fica aqui, o
/// Create e o Update abrem o [ProdutoFormScreen], e o Delete é feito pelo
/// botão da lixeira, sempre com confirmação antes.
class AbaAdmin extends StatefulWidget {
  const AbaAdmin({super.key});

  @override
  State<AbaAdmin> createState() => _AbaAdminState();
}

class _AbaAdminState extends State<AbaAdmin> {
  List<Map<String, dynamic>> _produtos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final produtos = await DatabaseHelper.instancia.listarRestaurantes();

    if (!mounted) return;
    setState(() {
      _produtos = produtos;
      _carregando = false;
    });
  }

  /// Abre o formulário em branco (novo produto) ou preenchido (edição).
  Future<void> _abrirFormulario([Map<String, dynamic>? produto]) async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProdutoFormScreen(produto: produto),
      ),
    );

    // A tela do formulário devolve true quando gravou algo no banco.
    if (salvou == true) _carregar();
  }

  Future<void> _excluir(Map<String, dynamic> produto) async {
    final nome = produto['res_nm_restaurante'] as String;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppCores.superficie,
        title: const Text('Excluir produto?'),
        content: Text(
          '"$nome" será removido do cardápio. Esta ação não pode ser '
          'desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppCores.vermelho),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    final id = (produto['res_id_restaurante'] as num).toInt();
    await DatabaseHelper.instancia.excluirRestaurante(id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$nome" foi excluído.')),
    );

    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    // Trava de segurança: mesmo que alguém chegue nesta tela por outro
    // caminho, sem a permissão nada é exibido.
    if (!Sessao.isAdmin) return _semPermissao();

    return Scaffold(
      backgroundColor: AppCores.fundo,
      appBar: AppBar(
        title: const Text('Gerenciar cardápio'),
        automaticallyImplyLeading: false,
      ),

      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppCores.laranja),
            )
          : RefreshIndicator(
              onRefresh: _carregar,
              color: AppCores.laranja,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppEspacos.xl,
                  AppEspacos.xl,
                  AppEspacos.xl,
                  90,
                ),
                itemCount: _produtos.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppEspacos.md),
                itemBuilder: (context, indice) {
                  if (indice == 0) return _painelResumo();
                  return _cartaoProduto(_produtos[indice - 1]);
                },
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: AppCores.laranja,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
      ),
    );
  }

  // -----------------------------------------------------------------
  // RESUMO DO ESTOQUE
  // -----------------------------------------------------------------
  Widget _painelResumo() {
    final total = _produtos.length;

    final semEstoque = _produtos
        .where((p) => ((p['res_nu_estoque'] as num?)?.toInt() ?? 0) == 0)
        .length;

    final estoqueBaixo = _produtos.where((p) {
      final quantidade = (p['res_nu_estoque'] as num?)?.toInt() ?? 0;
      return quantidade > 0 && quantidade <= 5;
    }).length;

    return Container(
      padding: const EdgeInsets.all(AppEspacos.lg),
      decoration: BoxDecoration(
        color: AppCores.escuro,
        borderRadius: BorderRadius.circular(AppRaios.cartao),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, ${Sessao.primeiroNome} — modo administradora',
            style: const TextStyle(
              fontSize: 13,
              color: AppCores.textoClaro,
            ),
          ),
          const SizedBox(height: AppEspacos.lg),
          Row(
            children: [
              _indicador('$total', 'produtos', Colors.white),
              _indicador('$estoqueBaixo', 'estoque baixo', AppCores.estrela),
              _indicador('$semEstoque', 'esgotados', AppCores.laranja),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicador(String valor, String rotulo, Color cor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            style: const TextStyle(fontSize: 11, color: AppCores.textoClaro),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // CARTÃO DE PRODUTO
  // -----------------------------------------------------------------
  Widget _cartaoProduto(Map<String, dynamic> produto) {
    final nome = produto['res_nm_restaurante'] as String;
    final preco = (produto['res_vl_preco'] as num?)?.toDouble() ?? 0;
    final estoque = (produto['res_nu_estoque'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppEspacos.md),
      decoration: BoxDecoration(
        color: AppCores.superficie,
        borderRadius: BorderRadius.circular(AppRaios.cartao),
        border: Border.all(color: AppCores.borda),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: FotoPrato(
              asset: produto['res_nm_asset'] as String?,
              url: produto['res_ds_url_imagem'] as String?,
              caminhoLocal: produto['res_im_foto'] as String?,
              altura: 60,
              raio: AppRaios.pequeno,
              descricao: 'Foto de $nome',
            ),
          ),
          const SizedBox(width: AppEspacos.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextos.destaque,
                ),
                const SizedBox(height: 3),
                Text(
                  '${produto['res_ds_categoria']} · '
                  '${produto['res_ds_tipo_culinaria']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextos.legenda,
                ),
                const SizedBox(height: AppEspacos.sm),
                Row(
                  children: [
                    Text(formatarReal(preco), style: AppTextos.preco),
                    const SizedBox(width: AppEspacos.sm),
                    _seloEstoque(estoque),
                  ],
                ),
              ],
            ),
          ),

          // Ações do CRUD, cada uma com 48 px de área de toque.
          Column(
            children: [
              BotaoIconeCustomizado(
                icone: Icons.edit_outlined,
                rotulo: 'Editar $nome',
                cor: AppCores.laranja,
                aoPressionar: () => _abrirFormulario(produto),
              ),
              BotaoIconeCustomizado(
                icone: Icons.delete_outline,
                rotulo: 'Excluir $nome',
                cor: AppCores.vermelho,
                aoPressionar: () => _excluir(produto),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seloEstoque(int estoque) {
    if (estoque == 0) {
      return const Selo(
        texto: 'Esgotado',
        cor: AppCores.vermelho,
        fundo: AppCores.vermelhoFundo,
      );
    }

    if (estoque <= 5) {
      return Selo(
        texto: 'Só $estoque un.',
        cor: AppCores.ambar,
        fundo: AppCores.ambarFundo,
      );
    }

    return Selo(
      texto: '$estoque un.',
      cor: AppCores.verde,
      fundo: AppCores.verdeFundo,
    );
  }

  // -----------------------------------------------------------------
  // ACESSO NEGADO
  // -----------------------------------------------------------------
  Widget _semPermissao() {
    return Scaffold(
      backgroundColor: AppCores.fundo,
      appBar: AppBar(title: const Text('Área restrita')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 52,
                color: AppCores.textoClaro,
              ),
              const SizedBox(height: AppEspacos.lg),
              const Text('Acesso restrito', style: AppTextos.secao),
              const SizedBox(height: AppEspacos.sm),
              const Text(
                'Esta área é exclusiva das contas administradoras da loja.',
                textAlign: TextAlign.center,
                style: AppTextos.auxiliar,
              ),
              const SizedBox(height: AppEspacos.xxl),
              BotaoCustomizado(
                texto: 'Voltar',
                estilo: EstiloBotao.contorno,
                larguraTotal: false,
                aoPressionar: () => Navigator.maybePop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
