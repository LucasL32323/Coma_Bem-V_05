import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../components/botao_customizado.dart';
import '../components/campo_formulario_customizado.dart';
import '../database/database_helper.dart';
import '../tema/app_cores.dart';
import '../tema/app_espacos.dart';

/// Cadastro de prato: formulário + câmera (image_picker) + GPS (geolocator).
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeController = TextEditingController();
  final _culinariaController = TextEditingController();
  final _precoController = TextEditingController();
  final _rankingController = TextEditingController();
  final _estoqueController = TextEditingController(text: '10');
  final _descricaoController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  static const List<String> _categorias = [
    'Massas',
    'Saladas',
    'Carnes',
    'Sobremesas',
    'Bebidas',
  ];

  String _categoria = 'Massas';
  File? _fotoPrato;
  String _latitude = '';
  String _longitude = '';
  bool _buscandoLocalizacao = false;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _culinariaController.dispose();
    _precoController.dispose();
    _rankingController.dispose();
    _estoqueController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // CÂMERA
  // ---------------------------------------------------------------
  Future<void> _tirarFoto(ImageSource origem) async {
    final XFile? fotoCapturada =
        await _picker.pickImage(source: origem, imageQuality: 70);
    if (fotoCapturada == null) return;
    setState(() => _fotoPrato = File(fotoCapturada.path));
  }

  void _escolherOrigemFoto() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppCores.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (contexto) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppEspacos.sm),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppCores.laranja),
              title: const Text('Tirar foto com a câmera'),
              onTap: () {
                Navigator.pop(contexto);
                _tirarFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppCores.laranja),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(contexto);
                _tirarFoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: AppEspacos.sm),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // GEOLOCALIZAÇÃO
  // ---------------------------------------------------------------
  Future<void> _pegarLocalizacao() async {
    setState(() => _buscandoLocalizacao = true);

    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!mounted) return;
      setState(() => _buscandoLocalizacao = false);
      _avisar('Ative a localização do aparelho.', AppCores.vermelho);
      return;
    }

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() => _buscandoLocalizacao = false);
      _avisar('Permissão de localização negada.', AppCores.vermelho);
      return;
    }

    final Position posicao = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;
    setState(() {
      _latitude = posicao.latitude.toStringAsFixed(6);
      _longitude = posicao.longitude.toStringAsFixed(6);
      _buscandoLocalizacao = false;
    });
  }

  // ---------------------------------------------------------------
  // SALVAR NO BANCO
  // ---------------------------------------------------------------
  Future<void> _salvarCadastro() async {
    // 1. VALIDAÇÃO DE FRONT-END
    if (_nomeController.text.trim().isEmpty ||
        _culinariaController.text.trim().isEmpty) {
      _avisar('Por favor, preencha os campos obrigatórios!', AppCores.vermelho);
      return;
    }

    final double? preco = double.tryParse(
      _precoController.text.trim().replaceAll(',', '.'),
    );
    if (preco == null || preco <= 0) {
      _avisar('Informe um preço válido, como 32,90.', AppCores.vermelho);
      return;
    }

    // 2. VALIDAÇÃO DO RANKING (restrição CHECK de 1 a 5 no banco).
    // tryParse no lugar de parse: texto vazio ou "abc" cairia em
    // FormatException e derrubaria a tela antes da nossa mensagem.
    final int? ranking = int.tryParse(_rankingController.text.trim());
    if (ranking == null || ranking < 1 || ranking > 5) {
      _avisar('O Ranking deve ser uma nota de 1 a 5!', AppCores.vermelho);
      return;
    }

    final int estoque = int.tryParse(_estoqueController.text.trim()) ?? 0;

    setState(() => _salvando = true);

    // 3. TRATAMENTO DE EXCEÇÕES
    try {
      final Map<String, dynamic> dadosRestaurante = {
        'res_nm_restaurante': _nomeController.text.trim(),
        'res_ds_tipo_culinaria': _culinariaController.text.trim(),
        'res_ds_categoria': _categoria,
        'res_vl_preco': preco,
        'res_nu_ranking': ranking,
        'res_nu_avaliacoes': 1,
        'res_ds_recomendacao': _descricaoController.text.trim(),
        'res_nu_latitude': _latitude,
        'res_nu_longitude': _longitude,
        'res_im_foto': _fotoPrato?.path ?? '',
        'res_nu_estoque': estoque,
      };

      await DatabaseHelper.instancia
          .inserirDados('restaurante', dadosRestaurante);

      if (!mounted) return;
      setState(() => _salvando = false);
      _avisar('Restaurante cadastrado com sucesso!', AppCores.verde);
      Navigator.pop(context);
    } catch (erro) {
      // ignore: avoid_print
      print('DEBUG - Erro ao salvar no SQLite: $erro');

      if (!mounted) return;
      setState(() => _salvando = false);
      _avisar('Ocorreu um erro inesperado ao salvar.', AppCores.vermelho);
    }
  }

  void _avisar(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: cor),
    );
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundo,
      appBar: AppBar(title: const Text('Novo cadastro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rótulo da seção da foto. Também é a âncora usada pelo teste
            // de integração para confirmar a chegada nesta tela.
            const Text(
              'Foto do Prato',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppCores.texto,
              ),
            ),
            const SizedBox(height: AppEspacos.md),
            _blocoFoto(),
            const SizedBox(height: AppEspacos.xxl),

            CampoFormularioCustomizado(
              titulo: 'Nome do restaurante',
              controlador: _nomeController,
              icone: Icons.restaurant_outlined,
              dica: 'Ex.: Fettuccine ao Pesto',
              capitalizacao: TextCapitalization.words,
            ),
            CampoFormularioCustomizado(
              titulo: 'Tipo de culinária',
              controlador: _culinariaController,
              icone: Icons.public,
              dica: 'Ex.: Italiana',
              capitalizacao: TextCapitalization.words,
            ),
            CampoSelecaoCustomizado(
              titulo: 'Categoria',
              valor: _categoria,
              opcoes: _categorias,
              icone: Icons.category_outlined,
              aoMudar: (nova) => setState(() => _categoria = nova),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoFormularioCustomizado(
                    titulo: 'Preço',
                    controlador: _precoController,
                    tipoTeclado:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixo: 'R\$  ',
                    dica: '32,90',
                  ),
                ),
                const SizedBox(width: AppEspacos.md),
                Expanded(
                  child: CampoFormularioCustomizado(
                    titulo: 'Ranking (1 a 5)',
                    controlador: _rankingController,
                    tipoTeclado: TextInputType.number,
                    icone: Icons.star_border,
                    dica: '5',
                  ),
                ),
              ],
            ),
            CampoFormularioCustomizado(
              titulo: 'Quantidade em estoque',
              controlador: _estoqueController,
              tipoTeclado: TextInputType.number,
              icone: Icons.inventory_2_outlined,
              dica: '10',
            ),
            CampoFormularioCustomizado(
              titulo: 'Recomendações',
              controlador: _descricaoController,
              linhas: 4,
              dica: 'O que torna esse prato especial?',
            ),

            const SizedBox(height: AppEspacos.xxl),
            _blocoLocalizacao(),
            const SizedBox(height: AppEspacos.xxxl),

            BotaoCustomizado(
              texto: 'Salvar cadastro',
              icone: Icons.save_outlined,
              estilo: EstiloBotao.confirmar,
              carregando: _salvando,
              aoPressionar: _salvarCadastro,
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocoFoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _escolherOrigemFoto,
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              color: AppCores.superficieAlt,
              borderRadius: BorderRadius.circular(AppRaios.cartao),
              border: Border.all(color: AppCores.borda, width: 1.4),
            ),
            child: _fotoPrato != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRaios.cartao - 1),
                    child: Image.file(_fotoPrato!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 32,
                        color: AppCores.textoClaro,
                      ),
                      SizedBox(height: AppEspacos.md),
                      Text(
                        'Toque para adicionar a foto do prato',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppCores.textoSuave,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_fotoPrato != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _escolherOrigemFoto,
                icon: const Icon(Icons.refresh, size: 17),
                label: const Text('Trocar foto'),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _fotoPrato = null),
                icon: const Icon(Icons.delete_outline, size: 17),
                label: const Text('Remover'),
                style: TextButton.styleFrom(
                  foregroundColor: AppCores.textoSuave,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _blocoLocalizacao() {
    return Container(
      padding: const EdgeInsets.all(AppEspacos.lg),
      decoration: BoxDecoration(
        color: AppCores.superficie,
        borderRadius: BorderRadius.circular(AppRaios.botao),
        border: Border.all(color: AppCores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 19,
                color: AppCores.laranja,
              ),
              const SizedBox(width: AppEspacos.sm),
              const Text(
                'Localização',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppCores.texto,
                ),
              ),
              const Spacer(),
              if (_latitude.isNotEmpty)
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppCores.verde,
                ),
            ],
          ),
          const SizedBox(height: AppEspacos.sm),
          Text(
            _latitude.isEmpty
                ? 'Nenhuma coordenada capturada ainda.'
                : 'Lat $_latitude  ·  Long $_longitude',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppCores.textoSuave,
            ),
          ),
          const SizedBox(height: AppEspacos.md),
          BotaoCustomizado(
            texto: _buscandoLocalizacao
                ? 'Buscando sinal de GPS...'
                : 'Obter localização atual',
            icone: Icons.my_location,
            estilo: EstiloBotao.contorno,
            carregando: _buscandoLocalizacao,
            aoPressionar: _pegarLocalizacao,
          ),
        ],
      ),
    );
  }
}
