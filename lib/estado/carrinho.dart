import 'package:flutter/foundation.dart';

/// Uma linha do carrinho: o prato escolhido e quantas unidades dele.
class ItemCarrinho {
  final int idPrato;
  final String nome;
  final double preco;
  final String? asset;
  final String? urlImagem;
  final String? caminhoLocal;
  int quantidade;

  ItemCarrinho({
    required this.idPrato,
    required this.nome,
    required this.preco,
    this.asset,
    this.urlImagem,
    this.caminhoLocal,
    this.quantidade = 1,
  });

  /// Quanto esta linha custa no total (preço × quantidade).
  double get subtotal => preco * quantidade;
}

/// Carrinho de compras do aplicativo.
///
/// É um [ChangeNotifier]: as telas que quiserem acompanhar o carrinho se
/// inscrevem nele com um `ListenableBuilder` e são redesenhadas sozinhas
/// sempre que um item entra, sai ou muda de quantidade. Isso evita ficar
/// passando o carrinho de tela em tela por parâmetro.
///
/// Assim como o [DatabaseHelper], usa o padrão Singleton: existe um único
/// carrinho no app inteiro, acessado por `Carrinho.instancia`.
class Carrinho extends ChangeNotifier {
  Carrinho._interno();

  static final Carrinho instancia = Carrinho._interno();

  final List<ItemCarrinho> _itens = [];

  /// Lista somente-leitura: ninguém de fora consegue alterar sem passar
  /// pelos métodos abaixo, que avisam as telas da mudança.
  List<ItemCarrinho> get itens => List.unmodifiable(_itens);

  bool get vazio => _itens.isEmpty;

  /// Quantidade total de unidades, para o selo vermelho no ícone da sacola.
  int get totalItens =>
      _itens.fold(0, (soma, item) => soma + item.quantidade);

  /// Soma dos itens, sem a entrega.
  double get subtotal =>
      _itens.fold(0.0, (soma, item) => soma + item.subtotal);

  /// Taxa de entrega fixa, gratuita a partir de R$ 60,00.
  static const double valorEntrega = 7.90;
  static const double minimoFreteGratis = 60.0;

  double get taxaEntrega {
    if (_itens.isEmpty) return 0;
    return subtotal >= minimoFreteGratis ? 0 : valorEntrega;
  }

  double get total => subtotal + taxaEntrega;

  /// Adiciona um prato vindo do banco. Se ele já estiver no carrinho,
  /// apenas soma a quantidade em vez de criar uma linha repetida.
  void adicionar(Map<String, dynamic> prato, {int quantidade = 1}) {
    final id = (prato['res_id_restaurante'] as num?)?.toInt() ?? -1;

    final existente = _itens.where((i) => i.idPrato == id).toList();

    if (existente.isNotEmpty) {
      existente.first.quantidade += quantidade;
    } else {
      _itens.add(
        ItemCarrinho(
          idPrato: id,
          nome: (prato['res_nm_restaurante'] as String?) ?? 'Item',
          preco: (prato['res_vl_preco'] as num?)?.toDouble() ?? 0,
          asset: prato['res_nm_asset'] as String?,
          urlImagem: prato['res_ds_url_imagem'] as String?,
          caminhoLocal: prato['res_im_foto'] as String?,
          quantidade: quantidade,
        ),
      );
    }

    // notifyListeners avisa todas as telas inscritas que o carrinho mudou.
    notifyListeners();
  }

  /// Soma ou subtrai uma unidade. Ao chegar em zero, o item sai da lista.
  void alterarQuantidade(int idPrato, int variacao) {
    final encontrados = _itens.where((i) => i.idPrato == idPrato).toList();
    if (encontrados.isEmpty) return;

    final item = encontrados.first;
    item.quantidade += variacao;

    if (item.quantidade <= 0) {
      _itens.remove(item);
    }

    notifyListeners();
  }

  void remover(int idPrato) {
    _itens.removeWhere((i) => i.idPrato == idPrato);
    notifyListeners();
  }

  /// Esvazia o carrinho, chamado depois que o pedido é confirmado.
  void limpar() {
    _itens.clear();
    notifyListeners();
  }
}
