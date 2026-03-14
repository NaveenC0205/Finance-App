class Transaction {
  final String id;
  final String date;
  final String person;
  final String bank;
  final String description;
  final double amount;
  final String type;
  final String category;

  Transaction({
    required this.id,
    required this.date,
    required this.person,
    required this.bank,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'person': person,
        'bank': bank,
        'description': description,
        'amount': amount,
        'type': type,
        'category': category,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        date: json['date'] as String,
        person: json['person'] as String,
        bank: json['bank'] as String,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: json['type'] as String,
        category: json['category'] as String,
      );
}
