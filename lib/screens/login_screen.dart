import 'package:flutter/material.dart';

import '../components/botao_customizado.dart';
import '../components/campo_formulario_customizado.dart';
import '../database/database_helper.dart';
import '../database/sessao.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';
import 'criar_conta_screen.dart';
import 'home_screen.dart';

/// Tela de login (login-coma-bem): autentica na tabela 'usuario' do SQLite.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _senhaOculta = true;
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    final String email = _emailController.text.trim();
    final String senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _avisar('Preencha o e-mail e a senha para entrar.', AppCores.vermelho);
      return;
    }

    setState(() => _carregando = true);

    try {
      final usuario =
          await DatabaseHelper.instancia.autenticarUsuario(email, senha);

      if (!mounted) return;
      setState(() => _carregando = false);

      if (usuario == null) {
        _avisar('E-mail ou senha inválidos.', AppCores.vermelho);
        return;
      }

      Sessao.entrar(usuario);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (erro) {
      // ignore: avoid_print
      print('DEBUG - Erro ao autenticar no SQLite: $erro');

      if (!mounted) return;
      setState(() => _carregando = false);
      _avisar('Ocorreu um erro inesperado ao entrar.', AppCores.vermelho);
    }
  }

  Future<void> _abrirCriarConta() async {
    final emailCriado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CriarContaScreen()),
    );

    if (emailCriado != null && mounted) {
      setState(() => _emailController.text = emailCriado);
    }
  }

  void _avisar(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: cor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  // Logo novo: arte circular do prato ladeada pelos talheres.
                  'assets/images/Logo_Principal_Coma_Bem.jpg',
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppCores.laranja,
                      borderRadius: BorderRadius.circular(AppRaios.pilula),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppEspacos.xxl),
              const Text(
                'Bem-vindo de volta!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppCores.texto,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppEspacos.xs),
              const Text(
                'Faça login para continuar sua jornada saudável.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppCores.textoSuave),
              ),
              const SizedBox(height: AppEspacos.xxxl),

              CampoFormularioCustomizado(
                titulo: 'E-mail',
                controlador: _emailController,
                tipoTeclado: TextInputType.emailAddress,
                icone: Icons.mail_outline,
                dica: 'seuemail@exemplo.com',
              ),
              CampoFormularioCustomizado(
                titulo: 'Senha',
                controlador: _senhaController,
                ocultarTexto: _senhaOculta,
                icone: Icons.lock_outline,
                dica: '••••••••',
                sufixo: IconButton(
                  tooltip: _senhaOculta ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _senhaOculta
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppCores.textoSuave,
                  ),
                  onPressed: () =>
                      setState(() => _senhaOculta = !_senhaOculta),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _avisar(
                    'Recuperação de senha ainda não implementada.',
                    AppCores.escuroMedio,
                  ),
                  child: const Text('Esqueci minha senha'),
                ),
              ),
              const SizedBox(height: AppEspacos.md),

              BotaoCustomizado(
                texto: 'Entrar',
                icone: Icons.login,
                carregando: _carregando,
                aoPressionar: _fazerLogin,
              ),

              const SizedBox(height: AppEspacos.xxl),
              Row(
                children: const [
                  Expanded(child: Divider(color: AppCores.borda)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppEspacos.md),
                    child: Text(
                      'ou',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppCores.textoSuave,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppCores.borda)),
                ],
              ),
              const SizedBox(height: AppEspacos.lg),

              Row(
                children: [
                  Expanded(
                    child: BotaoCustomizado(
                      texto: 'Google',
                      icone: Icons.g_mobiledata,
                      estilo: EstiloBotao.contorno,
                      aoPressionar: () => _avisar(
                        'Login social ainda não implementado.',
                        AppCores.escuroMedio,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppEspacos.md),
                  Expanded(
                    child: BotaoCustomizado(
                      texto: 'Apple',
                      icone: Icons.apple,
                      estilo: EstiloBotao.contorno,
                      aoPressionar: () => _avisar(
                        'Login social ainda não implementado.',
                        AppCores.escuroMedio,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppEspacos.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Não tem conta?',
                    style: TextStyle(color: AppCores.textoSuave),
                  ),
                  TextButton(
                    onPressed: _abrirCriarConta,
                    child: const Text(
                      'Cadastre-se',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppEspacos.lg),
              Container(
                padding: const EdgeInsets.all(AppEspacos.md),
                decoration: BoxDecoration(
                  color: AppCores.superficieAlt,
                  borderRadius: BorderRadius.circular(AppRaios.campo),
                  border: Border.all(color: AppCores.borda),
                ),
                child: const Text(
                  'Acesso de teste (administradora)\n'
                  'maria@comabem.com  ·  123456',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: AppCores.textoSuave,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
