import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/item.dart';

class ItemDto {
  static String date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  static Map<String, Object?> encode(Item item) => {
    'id': item.id,
    'name': item.name,
    'category': item.category,
    'loans': item.loans
        .map(
          (loan) => {
            'borrower': loan.borrower,
            'due': date(loan.due),
            'returned': loan.returned,
          },
        )
        .toList(),
  };
  static Item decode(Map<String, dynamic> map) => Item(
    id: map['id'] as String,
    name: map['name'] as String,
    category: map['category'] as String,
    loans: (map['loans'] as List).map((value) {
      final loan = value as Map<String, dynamic>;
      return Loan(
        borrower: loan['borrower'] as String,
        due: DateTime.parse(loan['due'] as String),
        returned: loan['returned'] as bool,
      );
    }).toList(),
  );
}

class MobileLabRepository implements ItemRepository {
  MobileLabRepository(
    this.client,
    this.base, {
    this.timeout = const Duration(seconds: 5),
  });
  final http.Client client;
  final Uri base;
  final Duration timeout;
  Uri _url([String? id]) => base.replace(pathSegments: ['api', 'items', ?id]);
  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode}');
    }
  }

  @override
  Future<List<Item>> load() async {
    final response = await client.get(_url()).timeout(timeout);
    _check(response);
    return (jsonDecode(response.body) as List)
        .map((value) => ItemDto.decode(value as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> save(Item item) async {
    final response = await client
        .put(
          _url(item.id),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(ItemDto.encode(item)),
        )
        .timeout(timeout);
    _check(response);
  }

  @override
  Future<void> delete(String id) async {
    _check(await client.delete(_url(id)).timeout(timeout));
  }
}
