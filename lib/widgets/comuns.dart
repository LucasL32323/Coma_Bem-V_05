import 'package:flutter/material.dart';
import '../tema/app_cores.dart';

/// Formata um número no padrão brasileiro de moeda: 32.9 vira "R$ 32,90".
String formatarReal(num valor) {
  final texto = valor.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $texto';
}

/// Converte a data gravada no banco (formato ISO, "2026-05-12T20:15:00")
/// para o padrão brasileiro: "12/05/2026 às 20:15".
///
/// Feito na mão para não depender do pacote `intl`, que não faz parte das
/// dependências da atividade.
String formatarDataHora(String? iso) {
  if (iso == null || iso.isEmpty) return '—';

  final data = DateTime.tryParse(iso);
  if (data == null) return iso;

  String doisDigitos(int valor) => valor.toString().padLeft(2, '0');

  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year}'
      ' às ${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
}

/// Estrela + nota, usada nos cartões e na tela de detalhe.
class NotaAvaliacao extends StatelessWidget {
  final double nota;
  final int? avaliacoes;
  final double tamanho;

  const NotaAvaliacao({
    super.key,
    required this.nota,
    this.avaliacoes,
    this.tamanho = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: tamanho + 3, color: AppCores.estrela),
        const SizedBox(width: 3),
        Text(
          nota.toStringAsFixed(1),
          style: TextStyle(
            fontSize: tamanho,
            fontWeight: FontWeight.w600,
            color: AppCores.texto,
          ),
        ),
        if (avaliacoes != null) ...[
          const SizedBox(width: 6),
          Text(
            '($avaliacoes avaliações)',
            style: TextStyle(fontSize: tamanho, color: AppCores.textoSuave),
          ),
        ],
      ],
    );
  }
}

/// Selo colorido de status, usado na tela de pedidos.
class Selo extends StatelessWidget {
  final String texto;
  final Color cor;
  final Color fundo;

  const Selo({
    super.key,
    required this.texto,
    required this.cor,
    required this.fundo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cor,
        ),
      ),
    );
  }
}

/// Rótulo acima de um campo de formulário, como no protótipo.
class RotuloCampo extends StatelessWidget {
  final String texto;

  const RotuloCampo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppCores.texto,
        ),
      ),
    );
  }
}
