import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Classe responsável por toda a comunicação com o banco de dados SQLite.
///
/// Usa o padrão Singleton: existe uma única instância dela no aplicativo
/// inteiro, acessada por DatabaseHelper.instancia.
class DatabaseHelper {
  // Construtor privado: ninguém de fora consegue instanciar esta classe.
  DatabaseHelper._interno();

  /// A única instância disponível para o app todo.
  static final DatabaseHelper instancia = DatabaseHelper._interno();

  // Guarda a conexão já aberta para não abrir o banco várias vezes.
  static Database? _banco;

  /// Retorna a conexão com o banco. Se ainda não existir, cria o arquivo.
  Future<Database> get banco async {
    if (_banco != null) return _banco!;
    _banco = await _iniciarBanco();
    return _banco!;
  }

  Future<Database> _iniciarBanco() async {
    // getDatabasesPath() devolve a pasta interna do app onde o SQLite fica.
    final caminho = join(await getDatabasesPath(), 'coma_bem.db');

    return openDatabase(
      caminho,
      version: 3,
      onCreate: _criarTabelas,
      // Se um banco antigo existir no aparelho, apagamos e recriamos com a
      // estrutura nova. Suficiente para um app de estudo.
      onUpgrade: (db, anterior, nova) async {
        await db.execute('DROP TABLE IF EXISTS pedido_item');
        await db.execute('DROP TABLE IF EXISTS pedido');
        await db.execute('DROP TABLE IF EXISTS restaurante');
        await db.execute('DROP TABLE IF EXISTS usuario');
        await _criarTabelas(db, nova);
      },
    );
  }

  /// Executado apenas na primeira vez que o app roda no aparelho.
  Future<void> _criarTabelas(Database db, int versao) async {
    // Tabela de usuários (tela de Login e de Criar Conta).
    await db.execute('''
      CREATE TABLE usuario (
        usu_id_usuario   INTEGER PRIMARY KEY AUTOINCREMENT,
        usu_nm_usuario   TEXT NOT NULL,
        usu_ds_email     TEXT NOT NULL UNIQUE,
        usu_ds_senha     TEXT NOT NULL,
        usu_ds_telefone  TEXT,
        usu_ds_endereco  TEXT,
        usu_vl_saldo     REAL NOT NULL DEFAULT 0
      )
    ''');

    // Tabela de restaurantes (tela Principal e tela de Cadastro).
    await db.execute('''
      CREATE TABLE restaurante (
        res_id_restaurante    INTEGER PRIMARY KEY AUTOINCREMENT,
        res_nm_restaurante    TEXT NOT NULL,
        res_ds_tipo_culinaria TEXT NOT NULL,
        res_ds_categoria      TEXT NOT NULL DEFAULT 'Massas',
        res_vl_preco          REAL NOT NULL DEFAULT 0,
        res_nu_ranking        REAL NOT NULL DEFAULT 0,
        res_nu_avaliacoes     INTEGER NOT NULL DEFAULT 0,
        res_ds_recomendacao   TEXT,
        res_nu_latitude       TEXT,
        res_nu_longitude      TEXT,
        res_im_foto           TEXT,
        res_nm_asset          TEXT,
        res_nu_estoque        INTEGER NOT NULL DEFAULT 0,
        res_ds_url_imagem     TEXT
      )
    ''');

    // Cabeçalho do pedido: quem pediu, quando, quanto e em que status está.
    await db.execute('''
      CREATE TABLE pedido (
        ped_id_pedido    INTEGER PRIMARY KEY AUTOINCREMENT,
        ped_id_usuario   INTEGER NOT NULL,
        ped_dt_pedido    TEXT NOT NULL,
        ped_ds_status    TEXT NOT NULL,
        ped_vl_subtotal  REAL NOT NULL,
        ped_vl_entrega   REAL NOT NULL,
        ped_vl_total     REAL NOT NULL,
        ped_ds_endereco  TEXT,
        ped_ds_pagamento TEXT,
        FOREIGN KEY (ped_id_usuario) REFERENCES usuario (usu_id_usuario)
      )
    ''');

    // Itens do pedido: uma linha por prato, com a quantidade e o preço
    // congelados no momento da compra (se o preço mudar depois, o pedido
    // antigo continua mostrando quanto foi pago de verdade).
    await db.execute('''
      CREATE TABLE pedido_item (
        pit_id_item       INTEGER PRIMARY KEY AUTOINCREMENT,
        pit_id_pedido     INTEGER NOT NULL,
        pit_id_prato      INTEGER,
        pit_nm_item       TEXT NOT NULL,
        pit_nu_quantidade INTEGER NOT NULL,
        pit_vl_unitario   REAL NOT NULL,
        FOREIGN KEY (pit_id_pedido) REFERENCES pedido (ped_id_pedido)
      )
    ''');

    await _carregarDadosIniciais(db);
  }

  /// Dados de exemplo para o app não abrir vazio na primeira execução.
  Future<void> _carregarDadosIniciais(Database db) async {
    await db.insert('usuario', {
      'usu_nm_usuario': 'Maria Silva',
      'usu_ds_email': 'maria@comabem.com',
      'usu_ds_senha': '123456',
      'usu_ds_telefone': '+55 11 99999-0000',
      'usu_ds_endereco': 'Av. Paulista, 1000 - São Paulo, SP',
      'usu_vl_saldo': 45.00,
    });

    // Conta usada pela suíte de testes de integração (integration_test).
    await db.insert('usuario', {
      'usu_nm_usuario': 'Admin Coma Bem',
      'usu_ds_email': 'admin@comabem.com',
      'usu_ds_senha': 'senha123',
      'usu_ds_telefone': '+55 13 98888-0000',
      'usu_ds_endereco': 'Av. Ana Costa, 100 - Santos, SP',
      'usu_vl_saldo': 100.00,
    });

    // O campo res_nm_asset guarda o nome do arquivo dentro de assets/images.
    // Se o arquivo não existir, a tela mostra um ícone no lugar da foto.
    final exemplos = [
      {
        'res_nm_restaurante': 'Fettuccine ao Pesto',
        'res_ds_tipo_culinaria': 'Italiana',
        'res_ds_categoria': 'Massas',
        'res_vl_preco': 32.90,
        'res_nu_ranking': 4.8,
        'res_nu_avaliacoes': 120,
        'res_ds_recomendacao':
            'Massa fresca ao molho pesto de manjericão, servida com lascas de '
                'parmesão e azeite extra virgem. Serve 1 pessoa.',
        'res_nm_asset': 'fettuccine_pesto.jpg',
        'res_nu_estoque': 20,
      },
      {
        'res_nm_restaurante': 'Salada Caesar',
        'res_ds_tipo_culinaria': 'Contemporânea',
        'res_ds_categoria': 'Saladas',
        'res_vl_preco': 26.00,
        'res_nu_ranking': 4.7,
        'res_nu_avaliacoes': 86,
        'res_ds_recomendacao':
            'Alface romana, frango grelhado, croutons crocantes e molho Caesar '
                'da casa com parmesão ralado na hora.',
        'res_nm_asset': 'salada_caesar.jpg',
        'res_nu_estoque': 20,
      },
      {
        'res_nm_restaurante': 'Filé Mignon c/ Fritas',
        'res_ds_tipo_culinaria': 'Brasileira',
        'res_ds_categoria': 'Carnes',
        'res_vl_preco': 49.90,
        'res_nu_ranking': 4.9,
        'res_nu_avaliacoes': 214,
        'res_ds_recomendacao':
            'Medalhão de filé mignon grelhado no ponto de sua preferência, '
                'acompanhado de batatas rústicas e manteiga de ervas.',
        'res_nm_asset': 'file_mignon.jpg',
        'res_nu_estoque': 20,
      },
      {
        'res_nm_restaurante': 'Petit Gâteau',
        'res_ds_tipo_culinaria': 'Francesa',
        'res_ds_categoria': 'Sobremesas',
        'res_vl_preco': 18.95,
        'res_nu_ranking': 4.6,
        'res_nu_avaliacoes': 64,
        'res_ds_recomendacao':
            'Bolo quente de chocolate meio amargo com recheio cremoso, servido '
                'com uma bola de sorvete de creme.',
        'res_nm_asset': 'petit_gateau.jpg',
        'res_nu_estoque': 20,
      },
      {
        'res_nm_restaurante': 'Lasanha Bolonhesa',
        'res_ds_tipo_culinaria': 'Italiana',
        'res_ds_categoria': 'Massas',
        'res_vl_preco': 38.90,
        'res_nu_ranking': 4.8,
        'res_nu_avaliacoes': 158,
        'res_ds_recomendacao':
            'Camadas de massa fresca, ragu de carne cozido lentamente e molho '
                'bechamel, gratinada com muçarela.',
        'res_nm_asset': 'lasanha.jpg',
        'res_nu_estoque': 20,
      },
      {
        'res_nm_restaurante': 'Filé à Parmegiana',
        'res_ds_tipo_culinaria': 'Brasileira',
        'res_ds_categoria': 'Carnes',
        'res_vl_preco': 42.50,
        'res_nu_ranking': 4.9,
        'res_nu_avaliacoes': 120,
        'res_ds_recomendacao':
            'Filé de carne bovina empanado com farinha especial, coberto com '
                'queijo muçarela derretido e nosso clássico molho de tomate '
                'artesanal. Acompanha arroz branco e batatas fritas.',
        'res_nm_asset': 'file_parmegiana.jpg',
        'res_nu_estoque': 20,
      },
    ];

    for (final restaurante in exemplos) {
      await db.insert('restaurante', restaurante);
    }
  }

  // ---------------------------------------------------------------
  // OPERAÇÕES GENÉRICAS
  // ---------------------------------------------------------------

  /// INSERT genérico: recebe o nome da tabela e um Mapa com coluna/valor.
  Future<int> inserirDados(String tabela, Map<String, dynamic> dados) async {
    final db = await banco;
    return db.insert(tabela, dados);
  }

  /// SELECT genérico: devolve todas as linhas da tabela informada.
  Future<List<Map<String, dynamic>>> consultarDados(String tabela) async {
    final db = await banco;
    return db.query(tabela);
  }

  // ---------------------------------------------------------------
  // USUÁRIO
  // ---------------------------------------------------------------

  /// Verifica se existe um usuário com aquele e-mail e senha.
  /// Retorna o registro encontrado ou null quando o login é inválido.
  Future<Map<String, dynamic>?> autenticarUsuario(
    String email,
    String senha,
  ) async {
    final db = await banco;

    // O uso de "?" (parâmetros) evita SQL Injection.
    final resultado = await db.query(
      'usuario',
      where: 'usu_ds_email = ? AND usu_ds_senha = ?',
      whereArgs: [email.trim().toLowerCase(), senha],
      limit: 1,
    );

    if (resultado.isEmpty) return null;
    return resultado.first;
  }

  /// Cadastra um novo usuário. Devolve null se o e-mail já estiver em uso.
  Future<Map<String, dynamic>?> cadastrarUsuario(
    Map<String, dynamic> dados,
  ) async {
    final db = await banco;

    final jaExiste = await db.query(
      'usuario',
      where: 'usu_ds_email = ?',
      whereArgs: [dados['usu_ds_email']],
      limit: 1,
    );
    if (jaExiste.isNotEmpty) return null;

    final id = await db.insert('usuario', dados);
    final novo = await db.query(
      'usuario',
      where: 'usu_id_usuario = ?',
      whereArgs: [id],
      limit: 1,
    );
    return novo.first;
  }

  /// Soma um valor ao saldo do usuário e devolve o saldo atualizado.
  Future<double> adicionarSaldo(int idUsuario, double valor) async {
    final db = await banco;

    await db.rawUpdate(
      'UPDATE usuario SET usu_vl_saldo = usu_vl_saldo + ? '
      'WHERE usu_id_usuario = ?',
      [valor, idUsuario],
    );

    final linha = await db.query(
      'usuario',
      columns: ['usu_vl_saldo'],
      where: 'usu_id_usuario = ?',
      whereArgs: [idUsuario],
      limit: 1,
    );

    return (linha.first['usu_vl_saldo'] as num).toDouble();
  }

  // ---------------------------------------------------------------
  // RESTAURANTE
  // ---------------------------------------------------------------

  /// Lista os restaurantes, com filtro opcional por categoria e por busca.
  Future<List<Map<String, dynamic>>> listarRestaurantes({
    String? categoria,
    String? busca,
  }) async {
    final db = await banco;

    final condicoes = <String>[];
    final valores = <Object>[];

    if (categoria != null && categoria != 'Todos') {
      condicoes.add('res_ds_categoria = ?');
      valores.add(categoria);
    }

    if (busca != null && busca.trim().isNotEmpty) {
      condicoes.add(
        '(res_nm_restaurante LIKE ? OR res_ds_tipo_culinaria LIKE ?)',
      );
      final termo = '%${busca.trim()}%';
      valores.add(termo);
      valores.add(termo);
    }

    return db.query(
      'restaurante',
      where: condicoes.isEmpty ? null : condicoes.join(' AND '),
      whereArgs: valores.isEmpty ? null : valores,
      orderBy: 'res_nu_ranking DESC',
    );
  }

  /// Devolve as categorias distintas já cadastradas, para montar os chips.
  Future<List<String>> listarCategorias() async {
    final db = await banco;
    final linhas = await db.rawQuery(
      'SELECT DISTINCT res_ds_categoria FROM restaurante '
      'ORDER BY res_ds_categoria',
    );
    return linhas.map((l) => l['res_ds_categoria'] as String).toList();
  }

  /// Busca um prato específico pelo id (usado ao reabrir o detalhe depois
  /// de uma edição feita pelo administrador).
  Future<Map<String, dynamic>?> buscarRestaurante(int id) async {
    final db = await banco;
    final linhas = await db.query(
      'restaurante',
      where: 'res_id_restaurante = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (linhas.isEmpty) return null;
    return linhas.first;
  }

  /// UPDATE de um prato. Devolve quantas linhas foram alteradas.
  ///
  /// Faz parte do CRUD liberado apenas para a conta administradora.
  Future<int> atualizarRestaurante(
    int id,
    Map<String, dynamic> dados,
  ) async {
    final db = await banco;
    return db.update(
      'restaurante',
      dados,
      where: 'res_id_restaurante = ?',
      whereArgs: [id],
    );
  }

  /// DELETE de um prato. Devolve quantas linhas foram removidas.
  Future<int> excluirRestaurante(int id) async {
    final db = await banco;
    return db.delete(
      'restaurante',
      where: 'res_id_restaurante = ?',
      whereArgs: [id],
    );
  }

  /// Desconta do estoque a quantidade comprada, sem deixar o valor
  /// ficar negativo (MAX garante o piso em zero).
  Future<void> baixarEstoque(int idPrato, int quantidade) async {
    final db = await banco;
    await db.rawUpdate(
      'UPDATE restaurante SET res_nu_estoque = MAX(res_nu_estoque - ?, 0) '
      'WHERE res_id_restaurante = ?',
      [quantidade, idPrato],
    );
  }

  // ---------------------------------------------------------------
  // PEDIDOS
  // ---------------------------------------------------------------

  /// Status possíveis de um pedido, na ordem em que acontecem.
  static const List<String> statusPedido = [
    'Confirmado',
    'Em preparo',
    'A caminho',
    'Entregue',
  ];

  /// Grava o pedido e seus itens dentro de uma transação.
  ///
  /// Transação garante o tudo-ou-nada: se algo falhar no meio, nenhuma
  /// linha é gravada e o banco não fica com um pedido sem itens.
  /// Devolve o id do pedido criado.
  Future<int> criarPedido({
    required int idUsuario,
    required List<Map<String, dynamic>> itens,
    required double subtotal,
    required double entrega,
    required String endereco,
    required String pagamento,
  }) async {
    final db = await banco;

    return db.transaction<int>((txn) async {
      final idPedido = await txn.insert('pedido', {
        'ped_id_usuario': idUsuario,
        'ped_dt_pedido': DateTime.now().toIso8601String(),
        'ped_ds_status': statusPedido.first,
        'ped_vl_subtotal': subtotal,
        'ped_vl_entrega': entrega,
        'ped_vl_total': subtotal + entrega,
        'ped_ds_endereco': endereco,
        'ped_ds_pagamento': pagamento,
      });

      for (final item in itens) {
        await txn.insert('pedido_item', {
          'pit_id_pedido': idPedido,
          'pit_id_prato': item['id'],
          'pit_nm_item': item['nome'],
          'pit_nu_quantidade': item['quantidade'],
          'pit_vl_unitario': item['preco'],
        });

        // Baixa no estoque dentro da mesma transação.
        await txn.rawUpdate(
          'UPDATE restaurante SET res_nu_estoque = '
          'MAX(res_nu_estoque - ?, 0) WHERE res_id_restaurante = ?',
          [item['quantidade'], item['id']],
        );
      }

      return idPedido;
    });
  }

  /// Lista os pedidos do usuário, do mais recente para o mais antigo,
  /// já com a lista de itens de cada um dentro da chave 'itens'.
  Future<List<Map<String, dynamic>>> listarPedidos(int idUsuario) async {
    final db = await banco;

    final pedidos = await db.query(
      'pedido',
      where: 'ped_id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'ped_id_pedido DESC',
    );

    final resultado = <Map<String, dynamic>>[];

    for (final pedido in pedidos) {
      final itens = await db.query(
        'pedido_item',
        where: 'pit_id_pedido = ?',
        whereArgs: [pedido['ped_id_pedido']],
      );

      // Map.of cria uma cópia editável: a linha devolvida pelo sqflite é
      // somente-leitura e não aceita a chave nova 'itens'.
      final copia = Map<String, dynamic>.of(pedido);
      copia['itens'] = itens;
      resultado.add(copia);
    }

    return resultado;
  }

  /// Avança o pedido para o próximo status da lista [statusPedido].
  /// Devolve o novo status, ou o atual se já estiver entregue.
  Future<String> avancarStatusPedido(int idPedido) async {
    final db = await banco;

    final linhas = await db.query(
      'pedido',
      columns: ['ped_ds_status'],
      where: 'ped_id_pedido = ?',
      whereArgs: [idPedido],
      limit: 1,
    );
    if (linhas.isEmpty) return statusPedido.first;

    final atual = linhas.first['ped_ds_status'] as String;
    final indice = statusPedido.indexOf(atual);

    if (indice < 0 || indice >= statusPedido.length - 1) return atual;

    final proximo = statusPedido[indice + 1];
    await db.update(
      'pedido',
      {'ped_ds_status': proximo},
      where: 'ped_id_pedido = ?',
      whereArgs: [idPedido],
    );

    return proximo;
  }
}
