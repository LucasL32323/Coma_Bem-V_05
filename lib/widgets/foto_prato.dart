import 'dart:io';
import 'package:flutter/material.dart';
import '../tema/app_cores.dart';

/// Exibe a foto de um prato seguindo quatro tentativas, nesta ordem:
///
/// 1. [caminhoLocal] — foto tirada pela câmera e salva no aparelho;
/// 2. [url] — endereço na internet, informado pelo administrador;
/// 3. [asset] — arquivo dentro de `assets/images/`;
/// 4. um bloco cinza com ícone, quando nenhuma das três existe.
///
/// Graças ao passo 4, o aplicativo roda normalmente mesmo com a pasta
/// `assets/images/` vazia. Basta colocar os arquivos lá depois.
class FotoPrato extends StatelessWidget {
  final String? asset;
  final String? caminhoLocal;
  final String? url;
  final double? altura;
  final double raio;
  final IconData icone;

  /// Descrição lida por leitores de tela (ex.: "Foto do prato Lasanha").
  final String? descricao;

  const FotoPrato({
    super.key,
    this.asset,
    this.caminhoLocal,
    this.url,
    this.altura,
    this.raio = 14,
    this.icone = Icons.restaurant,
    this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: descricao,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(raio),
        child: SizedBox(
          height: altura,
          width: double.infinity,
          child: _conteudo(),
        ),
      ),
    );
  }

  Widget _conteudo() {
    // 1. Foto capturada pela câmera.
    if (caminhoLocal != null && caminhoLocal!.isNotEmpty) {
      final arquivo = File(caminhoLocal!);
      if (arquivo.existsSync()) {
        return Image.file(arquivo, fit: BoxFit.cover);
      }
    }

    // 2. Imagem da internet, cadastrada pelo administrador na tela de
    //    gerenciamento. Enquanto baixa, mostramos o bloco cinza; se a URL
    //    estiver quebrada, o errorBuilder impede que o app trave.
    if (url != null && url!.trim().isNotEmpty) {
      return Image.network(
        url!.trim(),
        fit: BoxFit.cover,
        loadingBuilder: (context, filho, progresso) {
          if (progresso == null) return filho;
          return _placeholder();
        },
        errorBuilder: (context, erro, pilha) => _placeholder(),
      );
    }

    // 3. Imagem da pasta assets. O errorBuilder evita que o app quebre
    //    quando o arquivo ainda não foi adicionado ao projeto.
    if (asset != null && asset!.isNotEmpty) {
      return Image.asset(
        'assets/images/$asset',
        fit: BoxFit.cover,
        errorBuilder: (context, erro, pilha) => _placeholder(),
      );
    }

    // 4. Nenhuma imagem disponível.
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppCores.superficieAlt,
      child: Center(
        child: Icon(icone, size: 32, color: AppCores.textoClaro),
      ),
    );
  }
}
