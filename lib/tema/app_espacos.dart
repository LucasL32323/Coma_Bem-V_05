import 'package:flutter/material.dart';
import 'app_cores.dart';

/// Escala de espaçamento do aplicativo, baseada em múltiplos de 4.
///
/// Usar estas constantes no lugar de números soltos evita que cada tela
/// invente o próprio respiro: se um dia o layout precisar ficar mais
/// compacto, muda-se aqui e o app inteiro acompanha.
class AppEspacos {
  /// 4 — separação mínima, entre um ícone e o texto ao lado.
  static const double xs = 4;

  /// 8 — respiro interno de chips e selos.
  static const double sm = 8;

  /// 12 — distância entre itens de uma mesma lista.
  static const double md = 12;

  /// 16 — espaço entre campos de um formulário.
  static const double lg = 16;

  /// 20 — margem lateral padrão das telas.
  static const double xl = 20;

  /// 24 — separação entre blocos diferentes da mesma tela.
  static const double xxl = 24;

  /// 32 — respiro no fim da rolagem.
  static const double xxxl = 32;

  /// Margem lateral usada em praticamente todas as telas.
  static const EdgeInsets margemTela = EdgeInsets.symmetric(horizontal: xl);

  /// Área mínima de toque recomendada pelas diretrizes de acessibilidade
  /// (Material Design e WCAG 2.5.5): 48 x 48 pixels lógicos.
  ///
  /// Qualquer elemento clicável do app deve respeitar este tamanho, mesmo
  /// que o desenho visível seja menor — o toque é que precisa ser grande.
  static const double alvoToque = 48;
}

/// Raios de arredondamento, seguindo o protótipo do Figma.
class AppRaios {
  /// 8 — etiquetas e blocos pequenos.
  static const double pequeno = 8;

  /// 12 — campos de digitação.
  static const double campo = 12;

  /// 14 — botões.
  static const double botao = 14;

  /// 16 — cartões.
  static const double cartao = 16;

  /// 20 — chips de categoria e folhas que sobem pela base da tela.
  static const double pilula = 20;

  static BorderRadius circular(double valor) => BorderRadius.circular(valor);
}

/// Escala tipográfica do aplicativo.
///
/// Cada estilo tem um papel definido. Telas novas devem escolher um estilo
/// desta lista em vez de criar um TextStyle do zero.
class AppTextos {
  /// 26 — título de abertura de tela (ex.: "Bem-vindo de volta").
  static const TextStyle display = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppCores.texto,
    letterSpacing: -0.4,
  );

  /// 23 — nome do prato na tela de detalhe.
  static const TextStyle titulo = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.bold,
    color: AppCores.texto,
    letterSpacing: -0.4,
  );

  /// 17 — título de seção dentro de uma tela.
  static const TextStyle secao = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: AppCores.texto,
    letterSpacing: -0.3,
  );

  /// 15 — rótulo em negrito dentro de cartões.
  static const TextStyle destaque = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppCores.texto,
  );

  /// 14.5 — texto corrido padrão.
  static const TextStyle corpo = TextStyle(
    fontSize: 14.5,
    height: 1.5,
    color: AppCores.texto,
  );

  /// 13 — texto auxiliar, em cinza.
  static const TextStyle auxiliar = TextStyle(
    fontSize: 13,
    color: AppCores.textoSuave,
  );

  /// 11 — legenda, o menor tamanho aceitável para leitura confortável.
  static const TextStyle legenda = TextStyle(
    fontSize: 11,
    color: AppCores.textoSuave,
  );

  /// Preço em laranja, usado nos cartões e no resumo do carrinho.
  static const TextStyle preco = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: AppCores.laranja,
  );
}
