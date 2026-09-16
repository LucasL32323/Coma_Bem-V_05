import 'package:flutter/material.dart';
import '../components/botao_customizado.dart';
import '../database/database_helper.dart';
import '../database/sessao.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';
import '../widgets/comuns.dart';
import 'rastreamento_screen.dart';

/// Histórico de pedidos, lido das tabelas `pedido` e `pedido_item`.
///
/// Cada cartão abre a tela de rastreamento, que mostra em que etapa da
/// entrega o pedido está.
class AbaPedidos extends StatefulWidget {
  const AbaPedidos({super.key});

  @override
  State<AbaPedidos> createState() => _AbaPedidosState();
}

class _AbaPedidosState extends State<AbaPedidos> {
  List<Map<String, dynamic>> _pedidos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (Sessao.id == null) {
      if (mounted) setState(() => _carregando = false);
      return;
    }

    final pedidos = await DatabaseHelper.instancia.listarPedidos(Sessao.id!);

    if (!mounted) return;
    setState(() {
      _pedidos = pedidos;
      _carregando = false;
    });
  }

  Future<void> _abrirRastreamento(int idPedido) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RastreamentoScreen(idPedido: idPedido),
      ),
    );
    // O status pode ter avançado enquanto a tela estava aberta.
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundo,
      appBar: AppBar(
        title: const Text('Meus Pedidos'),
        automaticallyImplyLeading: false,
        actions: [
          BotaoIconeCustomizado(
            icone: Icons.refresh,
            rotulo: 'Atualizar lista de pedidos',
            cor: Colors.white,
            aoPressionar: _carregar,
          ),
        ],
      ),

      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppCores.laranja),
            )
          : _pedidos.isEmpty
              ? _semPedidos()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  color: AppCores.laranja,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppEspacos.xl,
                      AppEspacos.xl,
                      AppEspacos.xl,
                      AppEspacos.xxxl,
                    ),
                    itemCount: _pedidos.length + 1,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppEspacos.md),
                    itemBuilder: (context, indice) {
                      if (indice == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: AppEspacos.xs),
                          child: Text(
                            'Histórico e andamento das suas refeições',
                            style: AppTextos.auxiliar,
                          ),
                        );
                      }

                      return _cartaoPedido(_pedidos[indice - 1]);
                    },
                  ),
                ),
    );
  }

  // -----------------------------------------------------------------
  // CARTÃO DE PEDIDO
  // -----------------------------------------------------------------
  Widget _cartaoPedido(Map<String, dynamic> pedido) {
    final status = pedido['ped_ds_status'] as String;
    final entregue = status == DatabaseHelper.statusPedido.last;
    final itens = pedido['itens'] as List;
    final id = (pedido['ped_id_pedido'] as num).toInt();

    return Semantics(
      button: true,
      label: 'Pedido número $id, status $status. Toque para acompanhar.',
      child: ExcludeSemantics(
        child: Material(
          color: AppCores.superficie,
          borderRadius: BorderRadius.circular(AppRaios.cartao),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRaios.cartao),
            onTap: () => _abrirRastreamento(id),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRaios.cartao),
                border: Border.all(color: AppCores.borda),
              ),
              padding: const EdgeInsets.all(AppEspacos.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho: data à esquerda, selo de status à direita.
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pedido #$id', style: AppTextos.legenda),
                          const SizedBox(height: 3),
                          Text(
                            formatarDataHora(
                              pedido['ped_dt_pedido'] as String?,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppCores.texto,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Selo(
                        texto: status,
                        cor: entregue ? AppCores.verde : AppCores.azul,
                        fundo: entregue
                            ? AppCores.verdeFundo
                            : AppCores.azulFundo,
                      ),
                    ],
                  ),

                  const Divider(height: AppEspacos.xxl),

                  const Text(
                    'ITENS DO PEDIDO',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppCores.textoSuave,
                    ),
                  ),
                  const SizedBox(height: AppEspacos.sm),

                  // Uma linha por item do pedido.
                  ...itens.map((item) {
                    final linha = item as Map<String, dynamic>;
                    final quantidade =
                        (linha['pit_nu_quantidade'] as num).toInt();
                    final unitario =
                        (linha['pit_vl_unitario'] as num).toDouble();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${quantidade}x',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppCores.laranja,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              linha['pit_nm_item'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppCores.texto,
                              ),
                            ),
                          ),
                          Text(
                            formatarReal(unitario * quantidade),
                            style: AppTextos.auxiliar,
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(height: AppEspacos.xxl),

                  Row(
                    children: [
                      const Text(
                        'Total do pedido',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppCores.texto,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatarReal(
                          (pedido['ped_vl_total'] as num).toDouble(),
                        ),
                        style: AppTextos.preco,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppEspacos.md),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        entregue ? 'Ver detalhes' : 'Acompanhar entrega',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppCores.laranja,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppCores.laranja,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // ESTADO VAZIO
  // -----------------------------------------------------------------
  Widget _semPedidos() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: AppCores.textoClaro,
            ),
            const SizedBox(height: AppEspacos.lg),
            const Text('Nenhum pedido ainda', style: AppTextos.secao),
            const SizedBox(height: AppEspacos.sm),
            const Text(
              'Quando você fechar um pedido no carrinho, ele aparece aqui '
              'com o acompanhamento da entrega.',
              textAlign: TextAlign.center,
              style: AppTextos.auxiliar,
            ),
          ],
        ),
      ),
    );
  }
}
