import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/sessao.dart';
import '../tema/app_cores.dart';
import '../widgets/comuns.dart';

/// Carteira do usuário: mostra o saldo atual e permite adicionar crédito.
///
/// O saldo fica na coluna `usu_vl_saldo` da tabela `usuario`, então a
/// recarga é um UPDATE de verdade no SQLite.
class AbaCarteira extends StatefulWidget {
  const AbaCarteira({super.key});

  @override
  State<AbaCarteira> createState() => _AbaCarteiraState();
}

class _AbaCarteiraState extends State<AbaCarteira> {
  final _valorController = TextEditingController(text: '50,00');
  final _numeroCartaoController = TextEditingController();
  final _validadeController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nomeCartaoController = TextEditingController();

  // Valores prontos dos botões de atalho.
  final List<double> _atalhos = [20, 50, 100];
  double? _atalhoSelecionado = 50;

  String _metodo = 'Cartão de Crédito';
  bool _processando = false;

  @override
  void dispose() {
    _valorController.dispose();
    _numeroCartaoController.dispose();
    _validadeController.dispose();
    _cvvController.dispose();
    _nomeCartaoController.dispose();
    super.dispose();
  }

  /// Converte o texto digitado ("50,00") em número (50.0).
  double? _valorDigitado() {
    final texto = _valorController.text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(texto);
  }

  Future<void> _confirmar() async {
    final valor = _valorDigitado();

    if (valor == null || valor <= 0) {
      _avisar('Informe um valor válido para adicionar.');
      return;
    }
    if (Sessao.id == null) {
      _avisar('Sessão expirada. Faça login novamente.');
      return;
    }
    // Só o cartão pede os dados extras; PicPay e PayPal seriam
    // redirecionamentos externos.
    if (_metodo == 'Cartão de Crédito' &&
        _numeroCartaoController.text.trim().length < 12) {
      _avisar('Preencha os dados do cartão para continuar.');
      return;
    }

    setState(() => _processando = true);

    final novoSaldo =
        await DatabaseHelper.instancia.adicionarSaldo(Sessao.id!, valor);

    if (!mounted) return;

    setState(() {
      Sessao.saldo = novoSaldo;
      _processando = false;
    });

    _avisar('${formatarReal(valor)} adicionados à sua carteira.');
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
        title: const Text('Carteira'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // ----------------------------------------------------------
          // CARTÃO DE SALDO
          // ----------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppCores.escuro, AppCores.escuroMedio],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: AppCores.laranja,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Saldo disponível',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppCores.textoClaro,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  formatarReal(Sessao.saldo),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Adicionar saldo',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppCores.texto,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          const RotuloCampo('Valor para adicionar'),
          TextField(
            controller: _valorController,
            keyboardType: TextInputType.number,
            // Digitar um valor manualmente desmarca os botões de atalho.
            onChanged: (_) => setState(() => _atalhoSelecionado = null),
            decoration: const InputDecoration(
              prefixText: 'R\$  ',
              prefixStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppCores.texto,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Atalhos de valor.
          Row(
            children: _atalhos.map((valor) {
              final ativo = _atalhoSelecionado == valor;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: valor == _atalhos.last ? 0 : 10,
                  ),
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _atalhoSelecionado = valor;
                        _valorController.text =
                            valor.toStringAsFixed(2).replaceAll('.', ',');
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          ativo ? AppCores.laranjaFundo : AppCores.superficie,
                      side: BorderSide(
                        color: ativo ? AppCores.laranja : AppCores.borda,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      'R\$ ${valor.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            ativo ? AppCores.laranjaEscuro : AppCores.textoSuave,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 26),

          const RotuloCampo('Método de pagamento'),
          const SizedBox(height: 4),

          // Wrap quebra a linha automaticamente se os métodos não couberem.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _opcaoMetodo('PicPay', Icons.account_balance_outlined),
              _opcaoMetodo('PayPal', Icons.payments_outlined),
              _opcaoMetodo('Cartão de Crédito', Icons.credit_card),
            ],
          ),

          // Os campos do cartão só aparecem quando esse método é escolhido.
          if (_metodo == 'Cartão de Crédito') ...[
            const SizedBox(height: 22),
            _formularioCartao(),
          ],

          const SizedBox(height: 26),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock_outline, size: 14, color: AppCores.verde),
              SizedBox(width: 6),
              Text(
                'Pagamento processado com segurança',
                style: TextStyle(fontSize: 12, color: AppCores.verde),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: _processando ? null : _confirmar,
            child: _processando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Confirmar adição de saldo'),
          ),
        ],
      ),
    );
  }

  Widget _opcaoMetodo(String nome, IconData icone) {
    final ativo = _metodo == nome;

    return GestureDetector(
      onTap: () => setState(() => _metodo = nome),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: ativo ? AppCores.laranja : AppCores.superficie,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: ativo ? AppCores.laranja : AppCores.borda,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              size: 17,
              color: ativo ? Colors.white : AppCores.textoSuave,
            ),
            const SizedBox(width: 8),
            Text(
              nome,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ativo ? Colors.white : AppCores.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formularioCartao() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppCores.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppCores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dados do cartão de crédito',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppCores.texto,
            ),
          ),
          const SizedBox(height: 16),

          const RotuloCampo('Número do cartão'),
          TextField(
            controller: _numeroCartaoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '0000 0000 0000 0000',
              prefixIcon: Icon(Icons.credit_card, size: 20),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RotuloCampo('Validade'),
                    TextField(
                      controller: _validadeController,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(hintText: 'MM/AA'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RotuloCampo('CVV'),
                    TextField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        hintText: '123',
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const RotuloCampo('Nome impresso no cartão'),
          TextField(
            controller: _nomeCartaoController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'MARIA S SILVA'),
          ),
        ],
      ),
    );
  }
}
