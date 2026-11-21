import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:presta_cerca/features/lending/domain/item.dart';
import 'package:presta_cerca/features/lending/presentation/app.dart';
import 'package:presta_cerca/features/lending/presentation/controller.dart';

class Memory implements ItemRepository {
  final items = <Item>[
    Item(id: 'seed', name: 'Proyector demo', category: 'Tecnología'),
  ];
  @override
  Future<List<Item>> load() async => List.of(items);
  @override
  Future<void> save(Item item) async {
    items.removeWhere((old) => old.id == item.id);
    items.add(item);
  }

  @override
  Future<void> delete(String id) async =>
      items.removeWhere((item) => item.id == id);
}

void main() {
  testWidgets('catalog search, loan, return and history', (tester) async {
    final controller = LendingController(Memory());
    await tester.pumpWidget(
      LendingApp(controller: controller, endpoint: 'demo'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objetos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proyector demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar préstamo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar préstamo'));
    await tester.pumpAndSettle();
    expect(find.text('Campo obligatorio'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Vecino demo');
    await tester.tap(find.text('Confirmar préstamo'));
    await tester.pumpAndSettle();
    expect(find.text('Registrar devolución'), findsOneWidget);
    await tester.tap(find.text('Registrar devolución'));
    await tester.pumpAndSettle();
    expect(find.text('Devuelto'), findsOneWidget);
    expect(controller.items.single.active, isNull);
  });
}
