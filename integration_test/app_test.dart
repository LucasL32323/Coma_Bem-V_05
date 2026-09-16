// Suíte de testes de integração do app Coma Bem.
//
// Diferente do teste de unidade, aqui o aplicativo roda de verdade no
// emulador (ou no celular) e o "robô" WidgetTester simula os toques do
// usuário: login, chegada no catálogo e navegação até o cadastro.
//
// Como executar:
//   flutter test integration_test/app_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:coma_bem/database/database_helper.dart';
import 'package:coma_bem/main.dart' as app;

void main() {
  // 1. SETUP — liga a ponte entre o teste e o aplicativo real.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo principal do Coma Bem', () {
    testWidgets('Login, catálogo e navegação até o cadastro',
        (WidgetTester tester) async {
      app.main();

      // A Splash usa LinearProgressIndicator (animação infinita), então
      // pumpAndSettle() aqui estouraria o tempo limite. Avançamos o tempo
      // manualmente até o Timer de 3s levar o app para o Login.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Garante a conta de teste mesmo em um banco já criado antes desta
      // versão. Se o e-mail já existir, o método devolve null e segue.
      await DatabaseHelper.instancia.cadastrarUsuario(<String, dynamic>{
        'usu_nm_usuario': 'Admin Coma Bem',
        'usu_ds_email': 'admin@comabem.com',
        'usu_ds_senha': 'senha123',
        'usu_ds_telefone': '+55 13 98888-0000',
        'usu_ds_endereco': 'Av. Ana Costa, 100 - Santos, SP',
        'usu_vl_saldo': 100.00,
      });

      // 2. AUTOMAÇÃO DE LOGIN
      final Finder campoEmail = find.byType(TextField).first;
      final Finder campoSenha = find.byType(TextField).last;

      await tester.enterText(campoEmail, 'admin@comabem.com');
      await tester.enterText(campoSenha, 'senha123');
      await tester.pumpAndSettle();

      // 3. AÇÃO E VALIDAÇÃO INICIAL
      final Finder botaoEntrar = find.text('Entrar');
      await tester.ensureVisible(botaoEntrar);
      await tester.tap(botaoEntrar);
      await tester.pumpAndSettle();

      expect(find.text('Catálogo de Restaurantes'), findsOneWidget);

      // 4. DESAFIO DE NAVEGAÇÃO
      // Há outros Icons.add na tela (botão de adicionar ao carrinho de cada
      // card), por isso limitamos a busca ao FloatingActionButton.
      final Finder botaoNovoCadastro = find.descendant(
        of: find.byType(FloatingActionButton),
        matching: find.byIcon(Icons.add),
      );

      expect(botaoNovoCadastro, findsOneWidget);
      await tester.tap(botaoNovoCadastro);
      await tester.pumpAndSettle();

      expect(find.text('Foto do Prato'), findsOneWidget);
    });
  });
}
