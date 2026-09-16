import 'package:flutter/material.dart';
import '../components/botao_customizado.dart';
import '../estado/carrinho.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';
import '../widgets/comuns.dart';
import '../widgets/foto_prato.dart';
import 'checkout_screen.dart';

/// Carrinho de compras: revisão dos itens antes de fechar o pedido.
///
/// A tela inteira fica dentro de um [ListenableBuilder] ligado ao
/// `Carrinho.instancia`. Assim, quando a pessoa muda a quantidade de um
/// item, apenas o carrinho é alterado — a tela se redesenha sozinha, sem
/// precisar de setState espalhado.
class CarrinhoScreen extends StatelessWidget {
  const CarrinhoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrinho = Carrinho.instancia;

    return Scaffold(
      backgroundColor: AppCores.fundo,
      appBar: AppBar(
        title: const Text('Meu carrinho'),
        actions: [
          ListenableBuilder(
            listenable: carrinho,
            builder: (context, _) {
              if (carrinho.vazio) return const SizedBox.shrink();

              return BotaoIconeCustomizado(
                icone: Icons.delete_outline,
                rotulo: 'Esvaziar carrinho',
                cor: Colors.white,
                aoPressionar: () => _confirmarLimpeza(context),
              );
            },
          ),
        ],
      ),

      body: ListenableBuilder(
        listenable: carrinho,
        builder: (context, _) {
          if (carrinho.vazio) return _carrinhoVazio(context);

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppEspacos.xl,
              AppEspacos.xl,
              AppEspacos.xl,
              AppEspacos.xxxl,
            ),
            itemCount: carrinho.itens.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppEspacos.md),
            itemBuilder: (context, indice) {
              // O último item da lista é o resumo de valores.
              if (indice == carrinho.itens.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppEspacos.sm),
                  child: _resumo(carrinho),
                );
              }

              return _linhaItem(carrinho, carrinho.itens[indice]);
            },
          );
        },
      ),

      // Barra fixa no rodapé com o total e o botão de avançar.
      bottomNavigationBar: ListenableBuilder(
        listenable: carrinho,
        builder: (context, _) {
          if (carrinho.vazio) return const SizedBox.shrink();

          return Container(
            decoration: const BoxDecoration(
              color: AppCores.superficie,
              border: Border(top: BorderSide(color: AppCores.borda)),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppEspacos.xl,
              AppEspacos.md,
              AppEspacos.xl,
              AppEspacos.md,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        '${carrinho.totalItens} '
                        '${carrinho.totalItens == 1 ? "item" : "itens"}',
                        style: AppTextos.auxiliar,
                      ),
                      const Spacer(),
                      Text(
                        formatarReal(carrinho.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppCores.laranja,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppEspacos.md),
                  BotaoCustomizado(
                    texto: 'Continuar para o pagamento',
                    icone: Icons.arrow_forward,
                    dicaAcessibilidade:
                        'Abre a tela de endereço e forma de pagamento',
                    aoPressionar: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckoutScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -----------------------------------------------------------------
  // LINHA DE UM ITEM
  // -----------------------------------------------------------------
  Widget _linhaItem(Carrinho carrinho, ItemCarrinho item) {
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
            width: 62,
            child: FotoPrato(
              asset: item.asset,
              url: item.urlImagem,
              caminhoLocal: item.caminhoLocal,
              altura: 62,
              raio: AppRaios.pequeno,
              descricao: 'Foto de ${item.nome}',
            ),
          ),
          const SizedBox(width: AppEspacos.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextos.destaque,
                ),
                const SizedBox(height: AppEspacos.xs),
                Text(
                  '${formatarReal(item.preco)} a unidade',
                  style: AppTextos.legenda,
                ),
                const SizedBox(height: AppEspacos.sm),
                Text(
                  formatarReal(item.subtotal),
                  style: AppTextos.preco,
                ),
              ],
            ),
          ),

          // Controles de quantidade, com área de toque de 48 px.
          Column(
            children: [
              BotaoIconeCustomizado(
                icone: Icons.add,
                rotulo: 'Adicionar uma unidade de ${item.nome}',
                cor: AppCores.laranja,
                aoPressionar: () =>
                    carrinho.alterarQuantidade(item.idPrato, 1),
              ),
              Semantics(
                label: 'Quantidade de ${item.nome}',
                value: '${item.quantidade}',
                child: Text(
                  '${item.quantidade}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppCores.texto,
                  ),
                ),
              ),
              BotaoIconeCustomizado(
                // Com uma unidade só, o "menos" vira lixeira: fica claro
                // que o próximo toque remove o item do carrinho.
                icone: item.quantidade > 1
                    ? Icons.remove
                    : Icons.delete_outline,
                rotulo: item.quantidade > 1
                    ? 'Remover uma unidade de ${item.nome}'
                    : 'Excluir ${item.nome} do carrinho',
                cor: item.quantidade > 1
                    ? AppCores.texto
                    : AppCores.vermelho,
                aoPressionar: () =>
                    carrinho.alterarQuantidade(item.idPrato, -1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // RESUMO DE VALORES
  // -----------------------------------------------------------------
  Widget _resumo(Carrinho carrinho) {
    final freteGratis = carrinho.taxaEntrega == 0;
    final falta = Carrinho.minimoFreteGratis - carrinho.subtotal;

    return Container(
      padding: const EdgeInsets.all(AppEspacos.lg),
      decoration: BoxDecoration(
        color: AppCores.superficie,
        borderRadius: BorderRadius.circular(AppRaios.cartao),
        border: Border.all(color: AppCores.borda),
      ),
      child: Column(
        children: [
          _linhaValor('Subtotal', formatarReal(carrinho.subtotal)),
          const SizedBox(height: AppEspacos.sm),
          _linhaValor(
            'Taxa de entrega',
            freteGratis ? 'Grátis' : formatarReal(carrinho.taxaEntrega),
            destaqueVerde: freteGratis,
          ),

          if (!freteGratis) ...[
            const SizedBox(height: AppEspacos.sm),
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 15,
                  color: AppCores.textoSuave,
                ),
                const SizedBox(width: AppEspacos.sm),
                Expanded(
                  child: Text(
                    'Faltam ${formatarReal(falta)} para a entrega grátis.',
                    style: AppTextos.legenda,
                  ),
                ),
              ],
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppEspacos.md),
            child: Divider(),
          ),

          Row(
            children: [
              const Text('Total', style: AppTextos.destaque),
              const Spacer(),
              Text(
                formatarReal(carrinho.total),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppCores.laranja,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linhaValor(
    String rotulo,
    String valor, {
    bool destaqueVerde = false,
  }) {
    return Row(
      children: [
        Text(rotulo, style: AppTextos.auxiliar),
        const Spacer(),
        Text(
          valor,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: destaqueVerde ? AppCores.verde : AppCores.texto,
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------
  // ESTADO VAZIO
  // -----------------------------------------------------------------
  Widget _carrinhoVazio(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 56,
              color: AppCores.textoClaro,
            ),
            const SizedBox(height: AppEspacos.lg),
            const Text('Seu carrinho está vazio', style: AppTextos.secao),
            const SizedBox(height: AppEspacos.sm),
            const Text(
              'Volte para a tela inicial e toque no + de um prato para '
              'começar o pedido.',
              textAlign: TextAlign.center,
              style: AppTextos.auxiliar,
            ),
            const SizedBox(height: AppEspacos.xxl),
            BotaoCustomizado(
              texto: 'Ver o cardápio',
              estilo: EstiloBotao.contorno,
              larguraTotal: false,
              aoPressionar: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarLimpeza(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppCores.superficie,
        title: const Text('Esvaziar o carrinho?'),
        content: const Text('Todos os itens serão removidos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppCores.vermelho),
            child: const Text('Esvaziar'),
          ),
        ],
      ),
    );

    if (confirmou == true) Carrinho.instancia.limpar();
  }
}
