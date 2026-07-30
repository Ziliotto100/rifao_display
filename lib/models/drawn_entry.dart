/// Representa um número sorteado, com um id único que permite excluir ou
/// editar exatamente esse registro, mesmo que o número se repita.
class DrawnEntry {
  final String id;
  final String number;

  const DrawnEntry({required this.id, required this.number});

  DrawnEntry copyWith({String? number}) {
    return DrawnEntry(id: id, number: number ?? this.number);
  }

  Map<String, dynamic> toJson() => {'id': id, 'number': number};

  factory DrawnEntry.fromJson(Map<String, dynamic> json) {
    return DrawnEntry(
      id: json['id'] as String,
      number: json['number'] as String,
    );
  }
}
