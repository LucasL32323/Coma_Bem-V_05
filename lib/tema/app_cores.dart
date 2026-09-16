import 'package:flutter/material.dart';

/// Paleta central do aplicativo Coma Bem.
///
/// Todas as telas puxam as cores daqui. Para mudar a identidade visual do app
/// inteiro, basta alterar os valores abaixo — nenhuma tela precisa ser tocada.
class AppCores {
  // ---------------------------------------------------------------
  // FUNDOS
  // ---------------------------------------------------------------

  /// Fundo geral das telas: cinza levemente frio, no lugar do branco puro.
  static const Color fundo = Color(0xFFE9EAEC);

  /// Fundo dos cartões e campos, um degrau acima do fundo geral.
  static const Color superficie = Color(0xFFFAFAFB);

  /// Superfície secundária, para blocos internos e estados desabilitados.
  static const Color superficieAlt = Color(0xFFF1F2F4);

  // ---------------------------------------------------------------
  // TONS ESCUROS (cabeçalhos, splash, barras)
  // ---------------------------------------------------------------

  static const Color escuro = Color(0xFF23272E);
  static const Color escuroMedio = Color(0xFF333941);

  // ---------------------------------------------------------------
  // COR DE MARCA
  // ---------------------------------------------------------------

  /// Laranja da marca, em tom suave e um pouco mais escuro que o do protótipo.
  ///
  /// O protótipo do Figma usa um coral mais vivo (#FF5E36). Ele foi
  /// suavizado aqui porque o tom original tem contraste de 3.0:1 sobre
  /// branco — reprova na WCAG AA para texto pequeno. Este tom dá 4.5:1.
  /// Para voltar ao coral do protótipo, troque só esta linha por
  /// [laranjaProtótipo] — nenhuma tela precisa ser tocada.
  static const Color laranja = Color(0xFFC9633B);

  /// Coral original do protótipo do Figma, mantido como referência.
  static const Color laranjaPrototipo = Color(0xFFFF5E36);

  /// Versão escura, para gradientes e estados pressionados.
  static const Color laranjaEscuro = Color(0xFF9E4B2B);

  /// Fundo suave da cor de marca, para chips e destaques leves.
  static const Color laranjaFundo = Color(0xFFF0E3DB);

  // ---------------------------------------------------------------
  // TEXTO E TRAÇOS
  // ---------------------------------------------------------------

  static const Color texto = Color(0xFF1C2026);
  static const Color textoSuave = Color(0xFF6B7280);
  static const Color textoClaro = Color(0xFFB9BDC4);
  static const Color borda = Color(0xFFD8DADE);

  // ---------------------------------------------------------------
  // CORES DE ESTADO
  // ---------------------------------------------------------------

  /// Confirmações e pedidos entregues.
  static const Color verde = Color(0xFF3D7A5A);
  static const Color verdeFundo = Color(0xFFDDE9E2);

  /// Pedidos em andamento.
  static const Color azul = Color(0xFF3B6C9E);
  static const Color azulFundo = Color(0xFFDDE5EE);

  /// Estrelas de avaliação.
  static const Color estrela = Color(0xFFC99A2E);

  /// Ações destrutivas (excluir produto) e alertas de estoque zerado.
  static const Color vermelho = Color(0xFFB03A2E);
  static const Color vermelhoFundo = Color(0xFFF3E0DD);

  /// Avisos: estoque baixo, pedido aguardando confirmação.
  static const Color ambar = Color(0xFF9A6C15);
  static const Color ambarFundo = Color(0xFFF3E9D5);
}
