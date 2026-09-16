import 'package:flutter/material.dart';
import 'aba_inicio.dart';
import 'aba_pedidos.dart';
import 'aba_carteira.dart';
import 'aba_perfil.dart';
import 'aba_admin.dart';
import '../database/sessao.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';

/// Tela principal do aplicativo.
///
/// Funciona como uma "casca": ela não desenha conteúdo próprio, apenas a
/// barra de navegação inferior e a aba selecionada no momento.
///
/// As abas são montadas conforme a permissão de quem entrou: contas
/// administradoras ganham uma aba extra, "Gerenciar", com o CRUD dos
/// produtos. Contas comuns nem chegam a ver a aba.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Guarda qual aba está aberta. 0 = Início.
  int _abaAtual = 0;

  /// Telas na mesma ordem dos botões da barra inferior.
  late final List<Widget> _abas = [
    const AbaInicio(),
    const AbaPedidos(),
    const AbaCarteira(),
    if (Sessao.isAdmin) const AbaAdmin(),
    const AbaPerfil(),
  ];

  /// Botões da barra inferior, montados na mesma ordem de [_abas].
  late final List<BottomNavigationBarItem> _botoes = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Início',
      tooltip: 'Cardápio e busca de pratos',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      activeIcon: Icon(Icons.receipt_long_rounded),
      label: 'Pedidos',
      tooltip: 'Seus pedidos e o andamento das entregas',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet_outlined),
      activeIcon: Icon(Icons.account_balance_wallet_rounded),
      label: 'Carteira',
      tooltip: 'Saldo e recargas',
    ),
    if (Sessao.isAdmin)
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_outlined),
        activeIcon: Icon(Icons.inventory_2_rounded),
        label: 'Gerenciar',
        tooltip: 'Cadastro e edição dos produtos da loja',
      ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Perfil',
      tooltip: 'Conta, endereços e configurações',
    ),
  ];

  /// Troca de aba com prevenção de redundância.
  ///
  /// Tocar no botão da aba que já está aberta não faz nada: sem setState,
  /// sem redesenho e sem empilhar tela nova. Isso evita perder a posição
  /// da rolagem e o texto digitado na busca por um toque acidental.
  void _trocarAba(int indice) {
    if (indice == _abaAtual) return;
    setState(() => _abaAtual = indice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundo,

      // IndexedStack mantém as abas vivas em segundo plano: ao voltar para
      // a tela inicial, a posição da rolagem e os filtros continuam como
      // estavam. Um simples _abas[_abaAtual] recriaria a tela toda vez.
      body: IndexedStack(index: _abaAtual, children: _abas),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppCores.superficie,
          border: Border(top: BorderSide(color: AppCores.borda)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            // Altura mínima que garante os 48 px de área de toque por
            // botão exigidos pelas diretrizes de acessibilidade.
            height: AppEspacos.alvoToque + 14,
            child: BottomNavigationBar(
              currentIndex: _abaAtual,
              onTap: _trocarAba,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppCores.laranja,
              unselectedItemColor: AppCores.textoSuave,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              items: _botoes,
            ),
          ),
        ),
      ),
    );
  }
}
