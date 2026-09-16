import 'dart:async';
import 'package:flutter/material.dart';
import '../components/botao_customizado.dart';
import '../database/database_helper.dart';
import '../database/sessao.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';
import '../widgets/comuns.dart';

/// Acompanhamento do pedido, no estilo do iFood: uma linha do tempo com as
/// quatro etapas da entrega, destacando em qual delas o pedido está.
///
/// Como não existe uma cozinha de verdade do outro lado, um [Timer] avança
/// o status automaticamente a cada 20 segundos, gravando a mudança no
/// SQLite. É o suficiente para demonstrar a tela funcionando.
class RastreamentoScreen extends StatefulWidget {
  final int idPedido;

  const RastreamentoScreen({super.key, required this.idPedido});

  @override
  State<RastreamentoScreen> createState() => _RastreamentoScreenState();
}

class _RastreamentoScreenState extends State<RastreamentoScreen> {
  Map<String, dynamic>? _pedido;
  bool _carregando = true;
  Timer? _relogio;

  /// Descrição de cada etapa, exibida abaixo do nome do status.
  static const Map<String, String> _descricoes = {
    'Confirmado': 'Recebemos seu pedido e enviamos para a cozinha.',
    'Em preparo': 'Seu prato está sendo preparado agora.',
    'A caminho': 'O entregador saiu para entrega.',
    'Entregue': 'Bom apetite! Seu pedido chegou.',
  };

  static const Map<String, IconData> _icones = {
    'Confirmado': Icons.receipt_long_rounded,
    'Em preparo': Icons.soup_kitchen_rounded,
    'A caminho': Icons.delivery_dining_rounded,
    'Entregue': Icons.check_circle_rounded,
  };

  @override
  void initState() {
    super.initState();
    _carregarPedido();

    // periodic dispara a cada 20 segundos até o pedido ser entregue.
    _relogio = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _avancarStatus(),
    );
  }

  @override
  void dispose() {
    // Cancelar o Timer é obrigatório: sem isso, ele continuaria rodando
    // depois que a tela sai do ar e tentaria chamar setState no vazio.
    _relogio?.cancel();
    super.dispose();
  }

  Future<void> _carregarPedido() async {
    if (Sessao.id == null) return;

    final pedidos =
        await DatabaseHelper.instancia.listarPedidos(Sessao.id!);

    final encontrados = pedidos
        .where((p) => p['ped_id_pedido'] == widget.idPedido)
        .toList();

    if (!mounted) return;
    setState(() {
      _pedido = encontrados.isEmpty ? null : encontrados.first;
      _carregando = false;
    });
  }

  Future<void> _avancarStatus() async {
    final novo =
        await DatabaseHelper.instancia.avancarStatusPedido(widget.idPedido);

    if (!mounted) return;

    if (novo == DatabaseHelper.statusPedido.last) _relogio?.cancel();

    await _carregarPedido();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundo,
      appBar: AppBar(title: Text('Pedido #${widget.idPedido}')),

      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppCores.laranja),
            )
          : _pedido == null
              ? const Center(child: Text('Pedido não encontrado.'))
              : _conteudo(),

      bottomNavigationBar: Container(
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
            texto: 'Voltar ao cardápio',
            estilo: EstiloBotao.contorno,
            icone: Icons.restaurant_menu,
            aoPressionar: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _conteudo() {
    final pedido = _pedido!;
    final statusAtual = pedido['ped_ds_status'] as String;
    final indiceAtual = DatabaseHelper.statusPedido.indexOf(statusAtual);
    final itens = pedido['itens'] as List;

    return RefreshIndicator(
      onRefresh: _carregarPedido,
      color: AppCores.laranja,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppEspacos.xl,
          AppEspacos.xl,
          AppEspacos.xl,
          AppEspacos.xxxl,
        ),
        children: [
          _cartaoStatus(statusAtual),
          const SizedBox(height: AppEspacos.xl),
          _linhaDoTempo(indiceAtual),
          const SizedBox(height: AppEspacos.xl),
          _cartaoEntrega(pedido),
          const SizedBox(height: AppEspacos.lg),
          _cartaoItens(pedido, itens),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // CARTÃO DE STATUS ATUAL
  // -----------------------------------------------------------------
  Widget _cartaoStatus(String status) {
    final entregue = status == DatabaseHelper.statusPedido.last;

    return Container(
      padding: const EdgeInsets.all(AppEspacos.xl),
      decoration: BoxDecoration(
        color: entregue ? AppCores.verdeFundo : AppCores.laranjaFundo,
        borderRadius: BorderRadius.circular(AppRaios.cartao),
      ),
      child: Row(
        children: [
          Icon(
            _icones[status] ?? Icons.info_outline,
            size: 38,
            color: entregue ? AppCores.verde : AppCores.laranjaEscuro,
          ),
          const SizedBox(width: AppEspacos.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: entregue
                        ? AppCores.verde
                        : AppCores.laranjaEscuro,
                  ),
                ),
                const SizedBox(height: AppEspacos.xs),
                Text(
                  _descricoes[status] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: entregue
                        ? AppCores.verde
                        : AppCores.laranjaEscuro,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // LINHA DO TEMPO
  // -----------------------------------------------------------------
  Widget _linhaDoTempo(int indiceAtual) {
    final etapas = DatabaseHelper.statusPedido;

    return Container(
      padding: const EdgeInsets.all(AppEspacos.lg),
      decoration: BoxDecoration(
        color: AppCores.superficie,
        borderRadius: BorderRadius.circular(AppRaios.cartao),
        border: Border.all(color: AppCores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(etapas.length, (i) {
          final concluida = i <= indiceAtual;
          final atual = i == indiceAtual;
          final ultima = i == etapas.length - 1;

          return Semantics(
            label: etapas[i],
            value: concluida ? 'concluída' : 'pendente',
            child: ExcludeSemantics(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coluna da bolinha e do fio que liga as etapas.
                    Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: concluida
                                ? AppCores.laranja
                                : AppCores.superficieAlt,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: concluida
                                  ? AppCores.laranja
                                  : AppCores.borda,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            concluida ? Icons.check : Icons.circle_outlined,
                            size: 14,
                            color: concluida
                                ? Colors.white
                                : AppCores.textoClaro,
                          ),
                        ),
                        if (!ultima)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: concluida
                                  ? AppCores.laranja
                                  : AppCores.borda,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppEspacos.md),

                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: ultima ? 0 : AppEspacos.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              etapas[i],
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: atual
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: concluida
                                    ? AppCores.texto
                                    : AppCores.textoSuave,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _descricoes[etapas[i]] ?? '',
                              style: AppTextos.legenda,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // -----------------------------------------------------------------
  // ENTREGA E PAGAMENTO
  // -----------------------------------------------------------------
  Widget _cartaoEntrega(Map<String, dynamic> pedido) {
    return Container(
      padding: const EdgeInsets.all(AppEspacos.lg),
      decoration: BoxDecoration(
        color: AppCores.superficie,
        borderRadius: BorderRadius.circular(AppRaios.cartao),
        border: Border.all(color: AppCores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _linhaInfo(
            Icons.place_outlined,
            'Endereço',
            (pedido['ped_ds_endereco'] as String?) ?? '—',
          ),
          const SizedBox(height: AppEspacos.md),
          _linhaInfo(
            Icons.payment,
            'Pagamento',
            (pedido['ped_ds_pagamento'] as String?) ?? '—',
          ),
          const SizedBox(height: AppEspacos.md),
          _linhaInfo(
            Icons.schedule,
            'Feito em',
            formatarDataHora(pedido['ped_dt_pedido'] as String?),
          ),
        ],
      ),
    );
  }

  Widget _linhaInfo(IconData icone, String rotulo, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 18, color: AppCores.laranja),
        const SizedBox(width: AppEspacos.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo, style: AppTextos.legenda),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(fontSize: 13.5, color: AppCores.texto),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------
  // ITENS DO PEDIDO
  // -----------------------------------------------------------------
  Widget _cartaoItens(Map<String, dynamic> pedido, List itens) {
    return Container(
      padding: const EdgeInsets.all(AppEspacos.lg),
      decoration: BoxDecoration(
        color: AppCores.superficie,
        borderRadius: BorderRadius.circular(AppRaios.cartao),
        border: Border.all(color: AppCores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Itens do pedido', style: AppTextos.destaque),
          const SizedBox(height: AppEspacos.md),

          ...itens.map((item) {
            final linha = item as Map<String, dynamic>;
            final quantidade = (linha['pit_nu_quantidade'] as num).toInt();
            final unitario = (linha['pit_vl_unitario'] as num).toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: AppEspacos.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
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
              const Text('Total pago', style: AppTextos.destaque),
              const Spacer(),
              Text(
                formatarReal((pedido['ped_vl_total'] as num).toDouble()),
                style: AppTextos.preco,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
