class Cliente {
  final int id;
  final String nome;
  final String telefone;

  Cliente({
    required this.id,
    required this.nome,
    required this.telefone,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nome: json['nome'],
      telefone: json['telefone'],
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'telefone': telefone,
      };

  String get iniciais {
    final partes = nome.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
    }
    return nome[0].toUpperCase();
  }
}
