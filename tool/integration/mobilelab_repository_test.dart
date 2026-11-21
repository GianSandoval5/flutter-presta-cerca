import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:presta_cerca/features/lending/domain/item.dart';
import 'package:presta_cerca/features/lending/data/mobilelab_repository.dart';

void main() {
  const url = String.fromEnvironment('MOBILELAB_TEST_URL');
  const phase = String.fromEnvironment('MOBILELAB_TEST_PHASE');
  final client = http.Client();
  final repo = MobileLabRepository(client, Uri.parse(url));
  tearDownAll(client.close);
  test('real adapter and restart $phase', () async {
    const id = 'integration-item';
    if (phase == 'create') {
      final item = Item(id: id, name: 'Prueba', category: 'Demo');
      await repo.save(item);
      expect((await repo.load()).singleWhere((e) => e.id == id).active, isNull);
      await repo.save(item.lend('Alias demo', DateTime(2027), DateTime(2026)));
      expect(
        (await repo.load()).singleWhere((e) => e.id == id).active!.borrower,
        'Alias demo',
      );
    } else {
      final item = (await repo.load()).singleWhere((e) => e.id == id);
      expect(item.active!.borrower, 'Alias demo');
      await repo.save(item.receive());
      expect(
        (await repo.load())
            .singleWhere((e) => e.id == id)
            .loans
            .single
            .returned,
        true,
      );
      await repo.delete(id);
      expect((await repo.load()).any((e) => e.id == id), false);
    }
  });
}
