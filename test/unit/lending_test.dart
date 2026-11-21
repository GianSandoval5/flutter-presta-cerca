import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:presta_cerca/features/lending/domain/item.dart';
import 'package:presta_cerca/features/lending/data/mobilelab_repository.dart';
import 'package:presta_cerca/features/lending/presentation/controller.dart';

Item sample() => Item(id: 'a', name: 'Proyector', category: 'Tecnología');
void main() {
  final today = DateTime(2026, 11, 21);
  final uri = Uri.parse('http://localhost:4566');
  test('loan and return preserve history without mutating previous item', () {
    final original = sample();
    final lent = original.lend(' Demo ', today, today);
    expect(original.active, isNull);
    expect(lent.active!.borrower, 'Demo');
    expect(lent.active!.overdue(today), false);
    expect(lent.active!.overdue(today.add(const Duration(days: 1))), true);
    final received = lent.receive();
    expect(received.active, isNull);
    expect(received.loans.single.returned, true);
    expect(received.lend('Otro', today, today).loans.length, 2);
  });
  test('invalid dates, empty alias and double loan rejected', () {
    expect(() => sample().lend(' ', today, today), throwsStateError);
    expect(
      () =>
          sample().lend('Demo', today.subtract(const Duration(days: 1)), today),
      throwsStateError,
    );
    expect(
      () => sample().lend('Demo', today, today).lend('Otro', today, today),
      throwsStateError,
    );
    expect(() => sample().receive(), throwsStateError);
    expect(() => sample().rename('', 'x'), throwsArgumentError);
  });
  test('JSON round trip retains calendar date and history', () {
    final item = sample()
        .lend('Demo', today, today)
        .receive()
        .rename('Nuevo', 'Otra');
    final decoded = ItemDto.decode(
      jsonDecode(jsonEncode(ItemDto.encode(item))) as Map<String, dynamic>,
    );
    expect(decoded.name, 'Nuevo');
    expect(decoded.loans.single.due, today);
    expect(decoded.loans.single.returned, true);
  });
  test('HTTP adapter performs GET PUT DELETE with declared routes', () async {
    final methods = <String>[];
    final client = MockClient((request) async {
      methods.add(request.method);
      expect(
        request.url.path,
        request.method == 'GET' ? '/api/items' : '/api/items/a',
      );
      if (request.method == 'PUT') {
        expect((jsonDecode(request.body) as Map)['name'], 'Proyector');
      }
      return http.Response(
        request.method == 'GET' ? jsonEncode([ItemDto.encode(sample())]) : '',
        request.method == 'DELETE' ? 204 : 200,
      );
    });
    final repo = MobileLabRepository(client, uri);
    expect((await repo.load()).single.id, 'a');
    await repo.save(sample());
    await repo.delete('a');
    expect(methods, ['GET', 'PUT', 'DELETE']);
  });
  for (final status in [401, 403, 500]) {
    test('HTTP $status rejected', () async {
      final repo = MobileLabRepository(
        MockClient((_) async => http.Response('', status)),
        uri,
      );
      await expectLater(repo.load(), throwsStateError);
    });
  }
  test('malformed JSON and timeout are observable', () async {
    await expectLater(
      MobileLabRepository(
        MockClient((_) async => http.Response('!', 200)),
        uri,
      ).load(),
      throwsFormatException,
    );
    final repo = MobileLabRepository(
      MockClient((_) => Completer<http.Response>().future),
      uri,
      timeout: const Duration(milliseconds: 5),
    );
    await expectLater(repo.load(), throwsA(isA<TimeoutException>()));
  });
  test('controller preserves data after failure and recovers', () async {
    var fail = false;
    final client = MockClient(
      (request) async => http.Response(
        fail ? '' : jsonEncode([ItemDto.encode(sample())]),
        fail ? 500 : 200,
      ),
    );
    final controller = LendingController(MobileLabRepository(client, uri));
    addTearDown(controller.dispose);
    expect(await controller.refresh(), true);
    fail = true;
    expect(await controller.save(sample().rename('Cambio', 'Otra')), false);
    expect(controller.items.single.name, 'Proyector');
    expect(controller.error, isNotNull);
    fail = false;
    expect(await controller.refresh(), true);
    expect(controller.error, isNull);
  });
}
