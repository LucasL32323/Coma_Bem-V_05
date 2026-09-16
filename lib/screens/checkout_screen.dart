import 'package:flutter/material.dart';
import '../components/botao_customizado.dart';
import '../components/campo_formulario_customizado.dart';
import '../database/database_helper.dart';
import '../database/sessao.dart';
import '../estado/carrinho.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';
import '../widgets/comuns.dart';
import 'rastreamento_screen.dart';

/// Fechamento do pedido: confere o endereço, escolhe a forma de pagamento
/// e grava tudo no SQLite (tabelas `pedido` e `pedido_item`).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _enderecoController = TextEditingController(text: Sessao.endereco);
  final _observacaoController = TextEditingController();

  String _pagamento = 'Saldo Coma Bem';
  bool _finalizando = false;

  static const List<Map<String, dynamic>> _formasPagamento = [
    {'nome': 'Saldo Coma Bem', 'icone': Icons.account_balance_wallet},
    {'nome': 'Cartão de crédito', 'icone': Icons.credit_card},
    {'nome': 'Pix', 'icone': Icons.qr_code_2},
    {'nome': 'Dinheiro na entrega', 'icone': Icons.payments_outlined},
  ];

  @override
  void dispose() {
    _enderecoController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // GRAVAÇÃO DO PEDIDO
  // ---------------------------------------------------------------
  Future<void> _finalizarPedido() async {
    final carrinho = Carrinho.instancia;

    if (carrinho.vazio) {
      _avisar('Seu carrinho está vazio.');
      return;
    }

    if (_enderecoController.text.trim().isEmpty) {
      _avisar('Informe o endereço de entrega.');
      return;
    }

    if (Sessao.id == null) {
      _avisar('Entre na sua conta para finalizar o pedido.');
      return;
    }

    // Pagamento pelo saldo só passa se houver dinheiro suficiente.
    if (_pagamento == 'Saldo Coma Bem' && Sessao.saldo < carrinho.total) {
      _avisar(
        'Saldo insuficiente. Recarregue na aba Carteira ou escolha '
        'outra forma de pagamento.',
      );
      return;
    }

    setState(() => _finalizando = true);

    // Converte as linhas do carrinho no formato que o DatabaseHelper espera.
    final itens = carrinho.itens
        .map(
          (item) => {
            'id': item.idPrato,
            'nome': item.nome,
            'quantidade': item.quantidade,
            'preco': item.preco,
          },
        )
        .toList();

    final idPedido = await DatabaseHelper.instancia.criarPedido(
      idUsuario: Sessao.id!,
      itens: itens,
      subtotal: carrinho.subtotal,
      entrega: carrinho.taxaEntrega,
      endereco: _enderecoController.text.trim(),
      pagamento: _pagamento,
    );

    // Pagando com saldo, descontamos o valor do usuário (valor negativo).
    if (_pagamento == 'Saldo Coma Bem') {
      final novoSaldo = await DatabaseHelper.instancia.adicionarSaldo(
        Sessao.id!,
        -carrinho.total,
      );
      Sessao.saldo = novoSaldo;
    }

    carrinho.limpar();

    if (!mounted) return;
    setState(() => _finalizando = false);

    // pushReplacement: a tela de rastreamento entra no lugar do checkout,
    // então o botão "voltar" leva de volta ao cardápio, e não a um
    // checkout de um pedido que já foi pago.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RastreamentoScreen(idPedido: idPedido),
      ),
    );
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final carrinho = Carrinho.instancia;

    return Scaffold(
      backgroundColor: AppCores.fundo,
      appBar: AppBar(title: const Text('Finalizar pedido')),

      body: ListenableBuilder(
        listenable: carrinho,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppEspacos.xl,
              AppEspacos.xl,
              AppEspacos.xl,
              AppEspacos.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _titulo('Endereço de entrega', Icons.place_outlined),
                const SizedBox(height: AppEspacos.md),
                CampoFormularioCustomizado(
                  titulo: 'Endereço',
                  controlador: _enderecoController,
                  icone: Icons.home_outlined,
                  dica: 'Rua, número, bairro e cidade',
                  dicaAcessibilidade: 'Onde o pedido será entregue',
                  capitalizacao: TextCapitalization.words,
                ),
                CampoFormularioCustomizado(
                  titulo: 'Observações para o entregador',
                  controlador: _observacaoController,
                  dica: 'Ex.: apartamento 42, interfone quebrado',
                  linhas: 3,
                ),

                const SizedBox(height: AppEspacos.sm),
                _titulo('Forma de pagamento', Icons.payment),
                const SizedBox(height: AppEspacos.md),
                _listaPagamentos(carrinho),

                const SizedBox(height: AppEspacos.xxl),
                _titulo('Resumo', Icons.receipt_long_outlined),
                const SizedBox(height: AppEspacos.md),
                _resumoItens(carrinho),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: ListenableBuilder(
        listenable: carrinho,
        builder: (context, _) {
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
              child: BotaoCustomizado(
                texto: 'Confirmar e pagar ${formatarReal(carrinho.total)}',
                icone: Icons.check_circle_outline,
                estilo: EstiloBotao.confirmar,
                carregando: _finalizando,
                dicaAcessibilidade:
                    'Grava o pedido e abre o acompanhamento da entrega',
                aoPressionar: carrinho.vazio ? null : _finalizarPedido,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _titulo(String texto, IconData icone) {
    return Row(
      children: [
        Icon(icone, size: 18, color: AppCores.laranja),
        const SizedBox(width: AppEspacos.sm),
        Text(texto, style: AppTextos.secao),
      ],
    );
  }

  // -----------------------------------------------------------------
  // FORMAS DE PAGAMENTO
  // -----------------------------------------------------------------
  Widget _listaPagamentos(Carrinho carrinho) {
    return Container(
      decoration: BoxDecoration(
        color: AppCores.superficie,
        borderRadius: BorderRadius.circular(AppRaios.cartao),
        border: Border.all(color: AppCores.borda),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRaios.cartao - 1),
        child: Column(
          children: List.generate(_formasPagamento.length, (i) {
            final forma = _formasPagamento[i];
            final nome = forma['nome'] as String;
            final selecionado = nome == _pagamento;

            // Saldo insuficiente desabilita a opção de pagar com saldo.
            final semSaldo = nome == 'Saldo Coma Bem' &&
                Sessao.saldo < carrinho.total;

            return Column(
              children: [
                if (i > 0) const Divider(indent: 52),
                Semantics(
                  inMutuallyExclusiveGroup: true,
                  selected: selecionado,
                  enabled: !semSaldo,
                  label: nome,
                  child: ExcludeSemantics(
                    child: ListTile(
                      // minVerticalPadding mantém a linha com pelo menos
                      // 48 px de altura tocável.
                      minVerticalPadding: AppEspacos.md,
                      enabled: !semSaldo,
                      leading: Icon(
                        forma['icone'] as IconData,
                        size: 21,
                        color: semSaldo
                            ? AppCores.textoClaro
                            : AppCores.laranja,
                      ),
                      title: Text(
                        nome,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: semSaldo
                              ? AppCores.textoClaro
                              : AppCores.texto,
                        ),
                      ),
                      subtitle: nome == 'Saldo Coma Bem'
                          ? Text(
                              'Disponível: ${formatarReal(Sessao.saldo)}',
                              style: AppTextos.legenda,
                            )
                          : null,
                      trailing: Icon(
                        selecionado
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 20,
                        color: selecionado
                            ? AppCores.laranja
                            : AppCores.textoClaro,
                      ),
                      onTap: semSaldo
                          ? null
                          : () => setState(() => _pagamento = nome),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // RESUMO DOS ITENS
  // -----------------------------------------------------------------
  Widget _resumoItens(Carrinho carrinho) {
    return Container(
      padding: const EdgeInsets.all(AppEspacos.lg),
      decoration: BoxDecoration(
        color: AppCores.superficie,
        borderRadius: BorderRadius.circular(AppRaios.cartao),
        border: Border.all(color: AppCores.borda),
      ),
      child: Column(
        children: [
          ...carrinho.itens.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppEspacos.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${item.quantidade}x',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppCores.laranja,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppCores.texto,
                      ),
                    ),
                  ),
                  Text(
                    formatarReal(item.subtotal),
                    style: AppTextos.auxiliar,
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: AppEspacos.xxl),

          Row(
            children: [
              const Text('Subtotal', style: AppTextos.auxiliar),
              const Spacer(),
              Text(
                formatarReal(carrinho.subtotal),
                style: AppTextos.auxiliar,
              ),
            ],
          ),
          const SizedBox(height: AppEspacos.sm),
          Row(
            children: [
              const Text('Entrega', style: AppTextos.auxiliar),
              const Spacer(),
              Text(
                carrinho.taxaEntrega == 0
                    ? 'Grátis'
                    : formatarReal(carrinho.taxaEntrega),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: carrinho.taxaEntrega == 0
                      ? AppCores.verde
                      : AppCores.textoSuave,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppEspacos.md),
          Row(
            children: [
              const Text('Total', style: AppTextos.destaque),
              const Spacer(),
              Text(formatarReal(carrinho.total), style: AppTextos.preco),
            ],
          ),
        ],
      ),
    );
  }
}
