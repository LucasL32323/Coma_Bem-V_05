import 'package:flutter/material.dart';
import '../components/botao_customizado.dart';
import '../components/campo_formulario_customizado.dart';
import '../database/database_helper.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';
import '../widgets/foto_prato.dart';

/// Formulário do CRUD administrativo.
///
/// A mesma tela atende os dois casos:
/// * [produto] nulo  → **Create**: campos em branco, botão "Cadastrar";
/// * [produto] preenchido → **Update**: campos carregados, botão "Salvar
///   alterações" e opção de excluir.
///
/// Ao fechar, devolve `true` pelo Navigator quando algo foi gravado, para
/// a lista do painel se recarregar sozinha.
class ProdutoFormScreen extends StatefulWidget {
  final Map<String, dynamic>? produto;

  const ProdutoFormScreen({super.key, this.produto});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();
  final _estoqueController = TextEditingController();
  final _urlImagemController = TextEditingController();
  final _culinariaController = TextEditingController();
  final _notaController = TextEditingController();

  String _categoria = 'Massas';
  bool _salvando = false;

  static const List<String> _categorias = [
    'Massas',
    'Saladas',
    'Carnes',
    'Sobremesas',
    'Bebidas',
    'Lanches',
  ];

  /// true quando a tela foi aberta a partir de um produto existente.
  bool get _editando => widget.produto != null;

  @override
  void initState() {
    super.initState();

    // No modo edição, os controllers já nascem com os dados do banco.
    final produto = widget.produto;
    if (produto == null) return;

    _nomeController.text = (produto['res_nm_restaurante'] as String?) ?? '';
    _descricaoController.text =
        (produto['res_ds_recomendacao'] as String?) ?? '';
    _precoController.text =
        ((produto['res_vl_preco'] as num?)?.toDouble() ?? 0)
            .toStringAsFixed(2)
            .replaceAll('.', ',');
    _estoqueController.text =
        ((produto['res_nu_estoque'] as num?)?.toInt() ?? 0).toString();
    _urlImagemController.text =
        (produto['res_ds_url_imagem'] as String?) ?? '';
    _culinariaController.text =
        (produto['res_ds_tipo_culinaria'] as String?) ?? '';
    _notaController.text =
        ((produto['res_nu_ranking'] as num?)?.toDouble() ?? 0)
            .toStringAsFixed(1)
            .replaceAll('.', ',');

    final categoria = produto['res_ds_categoria'] as String?;
    if (categoria != null && _categorias.contains(categoria)) {
      _categoria = categoria;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _estoqueController.dispose();
    _urlImagemController.dispose();
    _culinariaController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // VALIDAÇÃO E GRAVAÇÃO
  // ---------------------------------------------------------------
  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      _avisar('Informe o nome do produto.');
      return;
    }

    // Aceita tanto "32,90" quanto "32.90".
    final preco = double.tryParse(
      _precoController.text.trim().replaceAll(',', '.'),
    );
    if (preco == null || preco <= 0) {
      _avisar('Informe um preço válido, como 32,90.');
      return;
    }

    final estoque = int.tryParse(_estoqueController.text.trim());
    if (estoque == null || estoque < 0) {
      _avisar('A quantidade em estoque deve ser um número inteiro.');
      return;
    }

    final nota = double.tryParse(
      _notaController.text.trim().replaceAll(',', '.'),
    );
    if (_notaController.text.trim().isNotEmpty &&
        (nota == null || nota < 0 || nota > 5)) {
      _avisar('A nota deve ficar entre 0 e 5.');
      return;
    }

    setState(() => _salvando = true);

    final dados = <String, dynamic>{
      'res_nm_restaurante': nome,
      'res_ds_recomendacao': _descricaoController.text.trim(),
      'res_vl_preco': preco,
      'res_nu_estoque': estoque,
      'res_ds_url_imagem': _urlImagemController.text.trim(),
      'res_ds_tipo_culinaria': _culinariaController.text.trim().isEmpty
          ? 'Variada'
          : _culinariaController.text.trim(),
      'res_ds_categoria': _categoria,
      'res_nu_ranking': nota ?? 0,
    };

    if (_editando) {
      // UPDATE: altera a linha existente, mantendo o mesmo id.
      final id = (widget.produto!['res_id_restaurante'] as num).toInt();
      await DatabaseHelper.instancia.atualizarRestaurante(id, dados);
    } else {
      // INSERT: produto novo começa sem avaliações.
      dados['res_nu_avaliacoes'] = 0;
      await DatabaseHelper.instancia.inserirDados('restaurante', dados);
    }

    if (!mounted) return;
    setState(() => _salvando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editando ? 'Produto atualizado!' : 'Produto cadastrado!',
        ),
      ),
    );

    // true avisa a tela anterior de que a lista precisa ser recarregada.
    Navigator.pop(context, true);
  }

  Future<void> _excluir() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppCores.superficie,
        title: const Text('Excluir produto?'),
        content: const Text('Esta ação não pode ser desfeita.'),
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

    final id = (widget.produto!['res_id_restaurante'] as num).toInt();
    await DatabaseHelper.instancia.excluirRestaurante(id);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundo,
      appBar: AppBar(
        title: Text(_editando ? 'Editar produto' : 'Novo produto'),
        actions: [
          if (_editando)
            BotaoIconeCustomizado(
              icone: Icons.delete_outline,
              rotulo: 'Excluir este produto',
              cor: Colors.white,
              aoPressionar: _excluir,
            ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppEspacos.xl,
          AppEspacos.xl,
          AppEspacos.xl,
          AppEspacos.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pré-visualização: mostra na hora se a URL digitada funciona.
            _previaImagem(),
            const SizedBox(height: AppEspacos.xl),

            CampoFormularioCustomizado(
              titulo: 'Nome do produto',
              controlador: _nomeController,
              icone: Icons.restaurant_outlined,
              dica: 'Ex.: Lasanha Bolonhesa',
              capitalizacao: TextCapitalization.words,
              dicaAcessibilidade: 'Nome exibido no cardápio',
            ),

            CampoFormularioCustomizado(
              titulo: 'Descrição',
              controlador: _descricaoController,
              dica: 'Ingredientes, porção, acompanhamentos...',
              linhas: 4,
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoFormularioCustomizado(
                    titulo: 'Preço',
                    controlador: _precoController,
                    tipoTeclado: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixo: 'R\$  ',
                    dica: '32,90',
                    dicaAcessibilidade: 'Preço em reais',
                  ),
                ),
                const SizedBox(width: AppEspacos.md),
                Expanded(
                  child: CampoFormularioCustomizado(
                    titulo: 'Estoque',
                    controlador: _estoqueController,
                    tipoTeclado: TextInputType.number,
                    icone: Icons.inventory_2_outlined,
                    dica: '20',
                    dicaAcessibilidade: 'Quantidade disponível para venda',
                  ),
                ),
              ],
            ),

            CampoFormularioCustomizado(
              titulo: 'URL da imagem',
              controlador: _urlImagemController,
              tipoTeclado: TextInputType.url,
              icone: Icons.link,
              dica: 'https://...',
              dicaAcessibilidade:
                  'Endereço da foto que aparece no cardápio',
              // onChanged não existe no componente, então o botão abaixo
              // atualiza a prévia sob demanda.
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: BotaoCustomizado(
                texto: 'Atualizar prévia da imagem',
                estilo: EstiloBotao.contorno,
                icone: Icons.refresh,
                larguraTotal: false,
                aoPressionar: () => setState(() {}),
              ),
            ),
            const SizedBox(height: AppEspacos.xl),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoFormularioCustomizado(
                    titulo: 'Tipo de culinária',
                    controlador: _culinariaController,
                    icone: Icons.public,
                    dica: 'Italiana',
                    capitalizacao: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: AppEspacos.md),
                Expanded(
                  child: CampoFormularioCustomizado(
                    titulo: 'Nota (0 a 5)',
                    controlador: _notaController,
                    tipoTeclado: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    icone: Icons.star_border,
                    dica: '4,8',
                  ),
                ),
              ],
            ),

            CampoSelecaoCustomizado(
              titulo: 'Categoria',
              valor: _categoria,
              opcoes: _categorias,
              icone: Icons.category_outlined,
              aoMudar: (nova) => setState(() => _categoria = nova),
            ),

            const SizedBox(height: AppEspacos.md),

            BotaoCustomizado(
              texto: _editando ? 'Salvar alterações' : 'Cadastrar produto',
              icone: Icons.save_outlined,
              estilo: EstiloBotao.confirmar,
              carregando: _salvando,
              aoPressionar: _salvar,
            ),

            if (_editando) ...[
              const SizedBox(height: AppEspacos.md),
              BotaoCustomizado(
                texto: 'Excluir produto',
                icone: Icons.delete_outline,
                estilo: EstiloBotao.perigo,
                aoPressionar: _excluir,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previaImagem() {
    final url = _urlImagemController.text.trim();

    return Column(
      children: [
        FotoPrato(
          url: url.isEmpty ? null : url,
          asset: widget.produto?['res_nm_asset'] as String?,
          caminhoLocal: widget.produto?['res_im_foto'] as String?,
          altura: 170,
          raio: AppRaios.cartao,
          descricao: 'Prévia da imagem do produto',
        ),
        const SizedBox(height: AppEspacos.sm),
        const Text(
          'Prévia — cole uma URL de imagem abaixo para trocar a foto.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: AppCores.textoSuave),
        ),
      ],
    );
  }
}
