import 'package:flutter/material.dart';
import '../tema/app_cores.dart';

/// Central de Ajuda: busca, perguntas frequentes e canais de contato.
class AjudaScreen extends StatefulWidget {
  const AjudaScreen({super.key});

  @override
  State<AjudaScreen> createState() => _AjudaScreenState();
}

class _AjudaScreenState extends State<AjudaScreen> {
  final _buscaController = TextEditingController();
  String _busca = '';

  // Lista de perguntas e respostas exibidas na seção de FAQ.
  static const List<Map<String, String>> _faq = [
    {
      'pergunta': 'Como rastrear meu pedido?',
      'resposta':
          'Abra a aba Pedidos e toque no pedido em andamento. O status é '
              'atualizado automaticamente até a entrega.',
    },
    {
      'pergunta': 'Como solicitar reembolso?',
      'resposta':
          'Vá em Pedidos, selecione a refeição correspondente, toque em '
              'Ajuda e descreva o motivo do reembolso. Retornamos em até 24h.',
    },
    {
      'pergunta': 'Como alterar meu endereço?',
      'resposta':
          'No Perfil, entre em Endereços salvos. Você pode editar o endereço '
              'atual ou cadastrar um novo e defini-lo como principal.',
    },
    {
      'pergunta': 'Tive um problema com o pagamento',
      'resposta':
          'Confira se os dados do cartão estão corretos na aba Carteira. '
              'Persistindo o erro, fale com o nosso atendimento.',
    },
    {
      'pergunta': 'Como avaliar um prato?',
      'resposta':
          'Depois que o pedido for entregue, toque no prato e dê sua nota de '
              '1 a 5 estrelas. Sua avaliação entra na média do ranking.',
    },
  ];

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filtra as perguntas conforme o que foi digitado na busca.
    final resultados = _faq.where((item) {
      if (_busca.isEmpty) return true;
      final termo = _busca.toLowerCase();
      return item['pergunta']!.toLowerCase().contains(termo) ||
          item['resposta']!.toLowerCase().contains(termo);
    }).toList();

    return Scaffold(
      backgroundColor: AppCores.fundo,
      appBar: AppBar(title: const Text('Central de Ajuda')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          TextField(
            controller: _buscaController,
            onChanged: (texto) => setState(() => _busca = texto),
            decoration: const InputDecoration(
              hintText: 'Buscar dúvida...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),

          const SizedBox(height: 26),

          const Text(
            'Perguntas frequentes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppCores.texto,
            ),
          ),
          const SizedBox(height: 14),

          if (resultados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Text(
                'Nenhuma dúvida encontrada com esse termo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppCores.textoSuave),
              ),
            )
          else
            // ExpansionTile é o "acordeão": mostra só a pergunta e revela a
            // resposta quando tocada.
            ...resultados.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppCores.superficie,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppCores.borda),
                ),
                child: Theme(
                  // Remove a linha divisória que o ExpansionTile desenha
                  // por padrão ao abrir.
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    shape: const Border(),
                    iconColor: AppCores.laranja,
                    collapsedIconColor: AppCores.textoSuave,
                    title: Text(
                      item['pergunta']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppCores.texto,
                      ),
                    ),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item['resposta']!,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.6,
                            color: AppCores.textoSuave,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 26),

          const Text(
            'Fale conosco',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppCores.texto,
            ),
          ),
          const SizedBox(height: 14),

          // Três canais de contato lado a lado.
          Row(
            children: [
              _canal(
                Icons.chat_bubble_outline,
                'Chat online',
                'Atendimento rápido',
              ),
              const SizedBox(width: 10),
              _canal(
                Icons.mail_outline,
                'E-mail',
                'suporte@comabem.com',
              ),
              const SizedBox(width: 10),
              _canal(
                Icons.phone_outlined,
                'Telefone',
                '0800-COMABEM',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _canal(IconData icone, String titulo, String descricao) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$titulo: em desenvolvimento.')),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: AppCores.superficie,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppCores.borda),
          ),
          child: Column(
            children: [
              Icon(icone, size: 22, color: AppCores.laranja),
              const SizedBox(height: 10),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppCores.texto,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                descricao,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppCores.textoSuave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
