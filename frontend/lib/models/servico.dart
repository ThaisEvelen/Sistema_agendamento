class Servico {
  final int id;
  final String nome;
  final String? descricao;
  final int duracaoMinutos;
  final String duracaoFormatada;
  final double preco;
  final bool ativo;

  Servico({
    required this.id,
    required this.nome,
    this.descricao,
    required this.duracaoMinutos,
    required this.duracaoFormatada,
    required this.preco,
    required this.ativo,
  });

  factory Servico.fromJson(Map<String, dynamic> json) {
    return Servico(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      duracaoMinutos: json['duracaoMinutos'],
      duracaoFormatada: json['duracaoFormatada'],
      preco: (json['preco'] as num).toDouble(),
      ativo: json['ativo'],
    );
  }

  // Preço formatado em reais: 50.0 → "R$ 50,00"
  String get precoFormatado {
    return 'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
