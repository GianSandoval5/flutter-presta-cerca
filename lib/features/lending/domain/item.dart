class Loan {
  const Loan({
    required this.borrower,
    required this.due,
    this.returned = false,
  });
  final String borrower;
  final DateTime due;
  final bool returned;

  bool overdue(DateTime now) =>
      !returned &&
      DateTime(
        due.year,
        due.month,
        due.day,
      ).isBefore(DateTime(now.year, now.month, now.day));
}

class Item {
  Item({
    required this.id,
    required this.name,
    required this.category,
    List<Loan> loans = const [],
  }) : loans = List.unmodifiable(loans) {
    if (id.trim().isEmpty ||
        name.trim().isEmpty ||
        category.trim().isEmpty ||
        loans.where((loan) => !loan.returned).length > 1) {
      throw ArgumentError('Objeto inválido');
    }
  }
  final String id;
  final String name;
  final String category;
  final List<Loan> loans;
  Loan? get active => loans.where((loan) => !loan.returned).firstOrNull;

  Item rename(String name, String category) =>
      Item(id: id, name: name.trim(), category: category.trim(), loans: loans);

  Item lend(String borrower, DateTime due, DateTime today) {
    if (active != null ||
        borrower.trim().isEmpty ||
        DateTime(
          due.year,
          due.month,
          due.day,
        ).isBefore(DateTime(today.year, today.month, today.day))) {
      throw StateError('Préstamo no válido');
    }
    return Item(
      id: id,
      name: name,
      category: category,
      loans: [
        ...loans,
        Loan(borrower: borrower.trim(), due: due),
      ],
    );
  }

  Item receive() {
    if (active == null) {
      throw StateError('No hay préstamo activo');
    }
    return Item(
      id: id,
      name: name,
      category: category,
      loans: loans
          .map(
            (loan) => loan.returned
                ? loan
                : Loan(borrower: loan.borrower, due: loan.due, returned: true),
          )
          .toList(),
    );
  }
}

abstract interface class ItemRepository {
  Future<List<Item>> load();
  Future<void> save(Item item);
  Future<void> delete(String id);
}
