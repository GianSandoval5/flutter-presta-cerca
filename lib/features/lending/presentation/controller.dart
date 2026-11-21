import 'package:flutter/foundation.dart';

import '../domain/item.dart';

class LendingController extends ChangeNotifier {
  LendingController(this.repository);
  final ItemRepository repository;
  List<Item> items = [];
  bool busy = false;
  String? error;

  Future<bool> _run(Future<void> Function() action) async {
    if (busy) {
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (_) {
      error = 'No se pudo conectar con MobileLab. Revisa el servicio y vuelve a intentar.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> refresh() => _run(() async {
    items = await repository.load();
  });
  Future<bool> save(Item item) => _run(() async {
    await repository.save(item);
    items = [...items.where((value) => value.id != item.id), item];
  });
  Future<bool> remove(Item item) => _run(() async {
    if (item.active != null) {
      throw StateError('Devuelve primero el objeto');
    }
    await repository.delete(item.id);
    items = items.where((value) => value.id != item.id).toList();
  });
}
