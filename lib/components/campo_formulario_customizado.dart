import 'package:flutter/material.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';

/// Campo de formulário reutilizável do aplicativo.
///
/// Nasceu da sessão de Code Review: a tela de cadastro repetia o mesmo
/// bloco `RotuloCampo + TextField + SizedBox` para cada informação. Este
/// widget concentra esse padrão em um lugar só (princípio DRY), incluindo
/// o suporte a leitores de tela.
///
/// É um StatelessWidget porque o visual do campo não muda por si só — quem
/// guarda o texto digitado é o [controlador], que vem de fora.
class CampoFormularioCustomizado extends StatelessWidget {
  /// Rótulo exibido acima do campo (ex.: "Nome do prato").
  final String titulo;

  /// Controlador que captura o texto digitado.
  final TextEditingController controlador;

  /// Texto de exemplo dentro do campo.
  final String? dica;

  /// Ícone à esquerda do campo.
  final IconData? icone;

  /// Tipo de teclado: texto, número, e-mail...
  final TextInputType tipoTeclado;

  /// Esconde os caracteres, para campos de senha.
  final bool ocultarTexto;

  /// Número de linhas. Acima de 1 vira caixa de texto livre.
  final int linhas;

  /// Texto colado antes do valor, como "R$ ".
  final String? prefixo;

  /// Explicação lida por leitores de tela, além do título.
  final String? dicaAcessibilidade;

  /// Widget exibido no canto direito do campo (ex.: botão de ver senha).
  final Widget? sufixo;

  /// Primeira letra de cada palavra em maiúscula.
  final TextCapitalization capitalizacao;

  const CampoFormularioCustomizado({
    super.key,
    required this.titulo,
    required this.controlador,
    this.dica,
    this.icone,
    this.tipoTeclado = TextInputType.text,
    this.ocultarTexto = false,
    this.linhas = 1,
    this.prefixo,
    this.dicaAcessibilidade,
    this.sufixo,
    this.capitalizacao = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspacos.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rótulo acima do campo, como no protótipo.
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppCores.texto,
              ),
            ),
          ),

          // Semantics conecta o rótulo ao campo: o leitor de tela anuncia
          // "Nome do prato, caixa de edição" em vez de só "caixa de edição".
          Semantics(
            textField: true,
            label: titulo,
            hint: dicaAcessibilidade,
            child: TextField(
              controller: controlador,
              keyboardType: tipoTeclado,
              obscureText: ocultarTexto,
              maxLines: ocultarTexto ? 1 : linhas,
              textCapitalization: capitalizacao,
              style: const TextStyle(fontSize: 14.5, color: AppCores.texto),
              decoration: InputDecoration(
                hintText: dica,
                prefixText: prefixo,
                prefixIcon: icone == null ? null : Icon(icone, size: 20),
                suffixIcon: sufixo,
                alignLabelWithHint: linhas > 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Versão em lista suspensa do campo acima, para escolhas fechadas
/// (categoria, forma de pagamento). Mantém o mesmo rótulo e o mesmo
/// espaçamento, para o formulário não ficar desalinhado.
class CampoSelecaoCustomizado extends StatelessWidget {
  final String titulo;
  final String valor;
  final List<String> opcoes;
  final ValueChanged<String> aoMudar;
  final IconData? icone;

  const CampoSelecaoCustomizado({
    super.key,
    required this.titulo,
    required this.valor,
    required this.opcoes,
    required this.aoMudar,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspacos.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppCores.texto,
              ),
            ),
          ),
          Semantics(
            label: titulo,
            value: valor,
            child: DropdownButtonFormField<String>(
              initialValue: opcoes.contains(valor) ? valor : null,
              decoration: InputDecoration(
                prefixIcon: icone == null ? null : Icon(icone, size: 20),
              ),
              items: opcoes
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (novo) {
                if (novo != null) aoMudar(novo);
              },
            ),
          ),
        ],
      ),
    );
  }
}
