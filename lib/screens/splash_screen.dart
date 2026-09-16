// Pacote base do Flutter para criação de interfaces (Material Design).
import 'package:flutter/material.dart';
// Biblioteca 'dart:async', necessária para usar o Timer (temporizador).
import 'dart:async';
// Próxima tela, para onde o usuário será levado após a Splash Screen.
import 'login_screen.dart';
import '../tema/app_cores.dart';

/// Tela de apresentação. É a primeira que o usuário vê: mostra a marca do
/// aplicativo enquanto os recursos iniciais são carregados.
///
/// Precisa ser um StatefulWidget porque seu estado muda: ela desaparece
/// sozinha depois de alguns segundos.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// O 'with SingleTickerProviderStateMixin' habilita animações nesta tela.
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Guarda o Timer para poder cancelá-lo caso a tela seja fechada antes.
  Timer? _temporizador;

  // Controla a animação de entrada da logo.
  late final AnimationController _animacao;

  // initState() é chamado assim que a tela é carregada pela primeira vez.
  @override
  void initState() {
    super.initState();

    _animacao = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // Timer conta o tempo definido (3 segundos) e executa a função ao fim.
    _temporizador = Timer(const Duration(seconds: 3), () {
      // 'mounted' verifica se a tela ainda está na árvore de widgets.
      // Sem isso, o app quebra se o usuário sair antes dos 3 segundos.
      if (!mounted) return;

      // pushReplacement substitui a Splash pela tela de Login, para que o
      // botão "Voltar" do celular não traga a Splash de volta.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  // dispose() é chamado quando a tela sai da memória. Cancelar o Timer e o
  // controlador de animação aqui evita vazamento de memória.
  @override
  void dispose() {
    _temporizador?.cancel();
    _animacao.dispose();
    super.dispose();
  }

  // build() é onde desenhamos os elementos visuais (widgets) da tela.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.escuro,
      body: Container(
        width: double.infinity,
        // Gradiente sutil entre dois tons escuros, em vez de cor chapada.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppCores.escuro, AppCores.escuroMedio],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // FadeTransition faz a logo surgir suavemente na entrada.
              FadeTransition(
                opacity: _animacao,
                child: Column(
                  children: [
                    // Logo da marca. O arquivo está em assets/images/ e a
                    // pasta já está registrada no pubspec.yaml.
                    Image.asset(
                      // Versão com fundo transparente do logo novo, para não
                      // abrir um retângulo claro sobre o fundo escuro.
                      'assets/images/Logo_Principal_Coma_Bem.png',
                      height: 150,
                      fit: BoxFit.contain,
                      // Se o arquivo faltar, o app não quebra: cai no ícone.
                      errorBuilder: (context, error, stack) => Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppCores.laranja,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // O nome da marca já aparece dentro da logo, então aqui
                    // fica só a frase de apoio.
                    const SizedBox(height: 22),

                    // Frase de apoio explicando o que o app faz.
                    const Text(
                      'O ranking dos melhores pratos da cidade',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppCores.textoClaro,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Barra de carregamento discreta no rodapé, no lugar da
              // rodinha central: ocupa menos atenção que a marca.
              const SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: AppCores.escuroMedio,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppCores.laranja),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
