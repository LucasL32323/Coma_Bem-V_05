// Testes unitários das funções auxiliares do aplicativo.
//
// A tela de apresentação usa um Timer de 3 segundos, o que exigiria
// controlar o relógio do teste. Por isso testamos aqui a formatação de
// moeda, que é lógica pura e não depende da interface.

import 'package:flutter_test/flutter_test.dart';
import 'package:coma_bem/widgets/comuns.dart';

void main() {
  group('formatarReal', () {
    test('usa vírgula como separador decimal', () {
      expect(formatarReal(32.9), 'R\$ 32,90');
    });

    test('sempre mostra duas casas decimais', () {
      expect(formatarReal(50), 'R\$ 50,00');
    });

    test('arredonda valores com mais de duas casas', () {
      expect(formatarReal(18.955), 'R\$ 18,96');
    });
  });
}
