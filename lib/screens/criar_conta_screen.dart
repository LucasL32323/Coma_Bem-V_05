import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../tema/app_cores.dart';
import '../widgets/comuns.dart';

/// Tela de criação de conta, seguindo o formulário do protótipo.
///
/// Ao concluir, devolve o e-mail cadastrado para a tela de Login, que já
/// preenche o campo automaticamente.
class CriarContaScreen extends StatefulWidget {
  const CriarContaScreen({super.key});

  @override
  State<CriarContaScreen> createState() => _CriarContaScreenState();
}

class _CriarContaScreenState extends State<CriarContaScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  final _cepController = TextEditingController();
  final _numeroController = TextEditingController();
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();

  bool _senhaOculta = true;
  bool _confirmarOculta = true;
  bool _aceitouTermos = false;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    _cepController.dispose();
    _numeroController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    super.dispose();
  }

  /// Valida os campos e grava o novo usuário no SQLite.
  Future<void> _cadastrar() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final senha = _senhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      _avisar('Preencha nome, e-mail e senha.');
      return;
    }
    // Checagem básica de formato: precisa ter "@" e um ponto depois dele.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _avisar('Informe um e-mail válido.');
      return;
    }
    if (senha.length < 6) {
      _avisar('A senha precisa ter ao menos 6 caracteres.');
      return;
    }
    if (senha != _confirmarController.text) {
      _avisar('As senhas não conferem.');
      return;
    }
    if (!_aceitouTermos) {
      _avisar('É preciso aceitar os termos de uso.');
      return;
    }

    setState(() => _salvando = true);

    // Monta o endereço completo a partir das partes digitadas, ignorando
    // os campos que ficaram em branco.
    final partes = [
      _ruaController.text.trim(),
      _numeroController.text.trim(),
      _bairroController.text.trim(),
      _cidadeController.text.trim(),
    ].where((p) => p.isNotEmpty).toList();

    final criado = await DatabaseHelper.instancia.cadastrarUsuario({
      'usu_nm_usuario': nome,
      'usu_ds_email': email,
      'usu_ds_senha': senha,
      'usu_ds_telefone': _telefoneController.text.trim(),
      'usu_ds_endereco':
          partes.isEmpty ? 'Endereço não informado' : partes.join(', '),
      'usu_vl_saldo': 0.0,
    });

    if (!mounted) return;
    setState(() => _salvando = false);

    if (criado == null) {
      _avisar('Este e-mail já está cadastrado.');
      return;
    }

    _avisar('Conta criada! Faça login para entrar.');
    Navigator.pop(context, email);
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundo,
      appBar: AppBar(title: const Text('Criar Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RotuloCampo('Nome completo'),
            TextField(
              controller: _nomeController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Digite seu nome completo',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            const RotuloCampo('E-mail'),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'seuemail@exemplo.com',
                prefixIcon: Icon(Icons.mail_outline, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            const RotuloCampo('Telefone'),
            TextField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '(11) 99999-0000',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            const RotuloCampo('Senha'),
            TextField(
              controller: _senhaController,
              obscureText: _senhaOculta,
              decoration: InputDecoration(
                hintText: 'Mínimo de 6 caracteres',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _senhaOculta
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppCores.textoSuave,
                  ),
                  onPressed: () => setState(() => _senhaOculta = !_senhaOculta),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const RotuloCampo('Confirmar senha'),
            TextField(
              controller: _confirmarController,
              obscureText: _confirmarOculta,
              decoration: InputDecoration(
                hintText: 'Repita a senha',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmarOculta
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppCores.textoSuave,
                  ),
                  onPressed: () =>
                      setState(() => _confirmarOculta = !_confirmarOculta),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            const Text(
              'Endereço de entrega',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppCores.texto,
              ),
            ),
            const SizedBox(height: 18),

            // Row com Expanded coloca dois campos lado a lado, dividindo a
            // largura disponível — igual ao protótipo.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RotuloCampo('CEP'),
                      TextField(
                        controller: _cepController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(hintText: '01310-100'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RotuloCampo('Número'),
                      TextField(
                        controller: _numeroController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '1000'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const RotuloCampo('Rua / Logradouro'),
            TextField(
              controller: _ruaController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Avenida Paulista'),
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RotuloCampo('Bairro'),
                      TextField(
                        controller: _bairroController,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(hintText: 'Bela Vista'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RotuloCampo('Cidade'),
                      TextField(
                        controller: _cidadeController,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(hintText: 'São Paulo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Checkbox de aceite dos termos. O InkWell no texto permite
            // marcar a caixa tocando na frase inteira, não só no quadradinho.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _aceitouTermos,
                    activeColor: AppCores.laranja,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: (valor) =>
                        setState(() => _aceitouTermos = valor ?? false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        setState(() => _aceitouTermos = !_aceitouTermos),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Li e aceito os ',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppCores.textoSuave,
                        ),
                        children: [
                          TextSpan(
                            text: 'Termos de Uso',
                            style: TextStyle(
                              color: AppCores.laranja,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ' e a '),
                          TextSpan(
                            text: 'Política de Privacidade',
                            style: TextStyle(
                              color: AppCores.laranja,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _salvando ? null : _cadastrar,
              child: _salvando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Cadastrar'),
            ),

            const SizedBox(height: 8),

            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Já tem conta? Fazer login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
