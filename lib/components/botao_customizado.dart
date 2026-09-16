import 'package:flutter/material.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';

/// Estilos possíveis do botão do aplicativo.
enum EstiloBotao {
  /// Fundo laranja preenchido. Ação principal da tela.
  principal,

  /// Apenas contorno laranja. Ação secundária.
  contorno,

  /// Fundo verde. Confirmação (finalizar pedido, salvar).
  confirmar,

  /// Contorno vermelho. Ação destrutiva (excluir).
  perigo,
}

/// Botão padrão do Coma Bem — resposta ao desafio colaborativo do guia de
/// refatoração: um único componente que exige um texto e uma função, e
/// devolve sempre o mesmo visual.
///
/// Antes, cada tela montava o próprio ElevatedButton com cor, tamanho de
/// fonte e raio repetidos. Agora, mudar a identidade dos botões do app
/// inteiro é mexer em um arquivo só.
///
/// Acessibilidade: a altura mínima é [AppEspacos.alvoToque] (48 px), e o
/// botão é anunciado como botão pelos leitores de tela, com o estado
/// "desabilitado" quando está carregando.
class BotaoCustomizado extends StatelessWidget {
  /// Texto exibido no botão.
  final String texto;

  /// Função executada no toque. Se for nula, o botão fica desabilitado.
  final VoidCallback? aoPressionar;

  /// Ícone opcional à esquerda do texto.
  final IconData? icone;

  /// Variação visual do botão.
  final EstiloBotao estilo;

  /// Mostra a rodinha de progresso e bloqueia o toque.
  final bool carregando;

  /// Se false, o botão ocupa só o espaço do próprio conteúdo.
  final bool larguraTotal;

  /// Explicação extra lida pelo leitor de tela.
  final String? dicaAcessibilidade;

  const BotaoCustomizado({
    super.key,
    required this.texto,
    required this.aoPressionar,
    this.icone,
    this.estilo = EstiloBotao.principal,
    this.carregando = false,
    this.larguraTotal = true,
    this.dicaAcessibilidade,
  });

  bool get _contornado =>
      estilo == EstiloBotao.contorno || estilo == EstiloBotao.perigo;

  Color get _corPrincipal {
    switch (estilo) {
      case EstiloBotao.principal:
        return AppCores.laranja;
      case EstiloBotao.contorno:
        return AppCores.laranja;
      case EstiloBotao.confirmar:
        return AppCores.verde;
      case EstiloBotao.perigo:
        return AppCores.vermelho;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto carrega, o toque é bloqueado passando null para o onPressed.
    final habilitado = aoPressionar != null && !carregando;
    final acao = habilitado ? aoPressionar : null;

    final conteudo = carregando
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _contornado ? _corPrincipal : Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icone != null) ...[
                Icon(icone, size: 19),
                const SizedBox(width: AppEspacos.sm),
              ],
              Flexible(
                child: Text(
                  texto,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final botao = _contornado
        ? OutlinedButton(
            onPressed: acao,
            style: OutlinedButton.styleFrom(
              foregroundColor: _corPrincipal,
              side: BorderSide(color: _corPrincipal),
              // minimumSize garante a área de toque mínima de 48 px.
              minimumSize: Size(
                larguraTotal ? double.infinity : 0,
                AppEspacos.alvoToque,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppEspacos.xl,
                vertical: 14,
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRaios.botao),
              ),
            ),
            child: conteudo,
          )
        : ElevatedButton(
            onPressed: acao,
            style: ElevatedButton.styleFrom(
              backgroundColor: _corPrincipal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppCores.borda,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size(
                larguraTotal ? double.infinity : 0,
                AppEspacos.alvoToque,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppEspacos.xl,
                vertical: 15,
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRaios.botao),
              ),
            ),
            child: conteudo,
          );

    // Semantics informa ao leitor de tela que isto é um botão, qual o texto
    // e se ele está disponível no momento.
    return Semantics(
      button: true,
      enabled: habilitado,
      label: texto,
      hint: dicaAcessibilidade,
      child: ExcludeSemantics(child: botao),
    );
  }
}

/// Botão redondo de ícone com área de toque garantida em 48 x 48, usado
/// nas barras superiores e sobre as fotos.
class BotaoIconeCustomizado extends StatelessWidget {
  final IconData icone;
  final VoidCallback? aoPressionar;

  /// Descrição obrigatória: um ícone sozinho não diz nada para quem usa
  /// leitor de tela.
  final String rotulo;

  final Color cor;
  final Color? fundo;

  const BotaoIconeCustomizado({
    super.key,
    required this.icone,
    required this.aoPressionar,
    required this.rotulo,
    this.cor = AppCores.texto,
    this.fundo,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: aoPressionar != null,
      label: rotulo,
      child: ExcludeSemantics(
        child: Material(
          color: fundo ?? Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: aoPressionar,
            child: SizedBox(
              width: AppEspacos.alvoToque,
              height: AppEspacos.alvoToque,
              child: Icon(icone, size: 20, color: cor),
            ),
          ),
        ),
      ),
    );
  }
}
