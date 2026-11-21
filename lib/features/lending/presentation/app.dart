import 'package:material_ui/material_ui.dart';

import '../domain/item.dart';
import '../data/mobilelab_repository.dart';
import 'controller.dart';

class LendingApp extends StatelessWidget {
  const LendingApp({
    super.key,
    required this.controller,
    required this.endpoint,
  });
  final LendingController controller;
  final String endpoint;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Presta Cerca',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff126e71)),
      useMaterial3: true,
    ),
    home: Home(controller: controller, endpoint: endpoint),
  );
}

class Home extends StatefulWidget {
  const Home({super.key, required this.controller, required this.endpoint});
  final LendingController controller;
  final String endpoint;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  String query = '';
  bool availableOnly = false;
  LendingController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    c.refresh();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, child) {
      final active = c.items.where((item) => item.active != null).toList();
      final overdue = active
          .where((item) => item.active!.overdue(DateTime.now()))
          .length;
      final filtered = c.items
          .where(
            (item) =>
                (!availableOnly || item.active == null) &&
                '${item.name} ${item.category}'.toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();
      return Scaffold(
        appBar: AppBar(
          title: const Text('Presta Cerca'),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: c.busy ? null : c.refresh,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Conexión',
              icon: const Icon(Icons.info_outline),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sandbox local'),
                  content: Text(
                    'Datos de demostración. MobileLab debe estar activo.\n${widget.endpoint}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (c.busy) const LinearProgressIndicator(),
                  if (c.error != null)
                    Card(
                      child: ListTile(
                        title: Text(c.error!),
                        trailing: TextButton(
                          onPressed: c.refresh,
                          child: const Text('Reintentar'),
                        ),
                      ),
                    ),
                  if (tab == 0) ...[
                    Text(
                      'Compartir es multiplicar.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Text(
                      'Controla lo prestado y recupera tus objetos a tiempo.',
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        metric(
                          'Disponibles',
                          c.items.length - active.length,
                          Icons.inventory_2_outlined,
                        ),
                        metric(
                          'Prestados',
                          active.length,
                          Icons.handshake_outlined,
                        ),
                        metric('Vencidos', overdue, Icons.schedule),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Préstamos activos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (active.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No hay préstamos activos.'),
                      ),
                    ...active.map(tile),
                  ] else if (tab == 1) ...[
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nombre o categoría',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => query = value),
                    ),
                    FilterChip(
                      label: const Text('Solo disponibles'),
                      selected: availableOnly,
                      onSelected: (value) =>
                          setState(() => availableOnly = value),
                    ),
                    if (filtered.isEmpty && !c.busy)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No hay objetos para mostrar.'),
                      ),
                    ...filtered.map(tile),
                  ] else ...[
                    Text(
                      'Historial de devoluciones',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (!c.items.any(
                      (item) => item.loans.any((loan) => loan.returned),
                    ))
                      const Text('Todavía no hay devoluciones.'),
                    for (final item in c.items)
                      for (final loan in item.loans.where(
                        (entry) => entry.returned,
                      ))
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(item.name),
                            subtitle: Text(
                              '${loan.borrower} · plazo ${ItemDto.date(loan.due)}',
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: tab == 1
            ? FloatingActionButton.extended(
                onPressed: c.busy ? null : () => edit(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo objeto'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) => setState(() => tab = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Objetos',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              label: 'Historial',
            ),
          ],
        ),
      );
    },
  );

  Widget metric(String label, int number, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          Text('$number', style: Theme.of(context).textTheme.headlineMedium),
          Text(label),
        ],
      ),
    ),
  );

  Widget tile(Item item) => Card(
    child: ListTile(
      leading: Icon(
        item.active == null
            ? Icons.inventory_2_outlined
            : Icons.handshake_outlined,
      ),
      title: Text(item.name),
      subtitle: Text(
        item.active == null
            ? '${item.category} · Disponible'
            : '${item.active!.borrower} · ${ItemDto.date(item.active!.due)}${item.active!.overdue(DateTime.now()) ? ' · Vencido' : ''}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => Detail(controller: c, id: item.id, edit: edit),
        ),
      ),
    ),
  );

  Future<void> edit(BuildContext context, [Item? item]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ItemForm(controller: c, item: item),
      ),
    );
  }
}

class ItemForm extends StatefulWidget {
  const ItemForm({super.key, required this.controller, this.item});
  final LendingController controller;
  final Item? item;
  @override
  State<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> {
  final key = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.item?.name);
  late final category = TextEditingController(text: widget.item?.category);
  @override
  void dispose() {
    name.dispose();
    category.dispose();
    super.dispose();
  }

  String? validate(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.item == null ? 'Nuevo objeto' : 'Editar objeto'),
    ),
    body: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) => Form(
        key: key,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: validate,
            ),
            TextFormField(
              controller: category,
              decoration: const InputDecoration(labelText: 'Categoría'),
              validator: validate,
            ),
            const SizedBox(height: 24),
            if (widget.controller.error != null) Text(widget.controller.error!),
            FilledButton(
              onPressed: widget.controller.busy
                  ? null
                  : () async {
                      if (!key.currentState!.validate()) {
                        return;
                      }
                      final item =
                          widget.item?.rename(name.text, category.text) ??
                          Item(
                            id: DateTime.now().microsecondsSinceEpoch
                                .toString(),
                            name: name.text.trim(),
                            category: category.text.trim(),
                          );
                      if (await widget.controller.save(item) &&
                          context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    ),
  );
}

class Detail extends StatelessWidget {
  const Detail({
    super.key,
    required this.controller,
    required this.id,
    required this.edit,
  });
  final LendingController controller;
  final String id;
  final Future<void> Function(BuildContext, Item) edit;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, child) {
      final item = controller.items.where((item) => item.id == id).firstOrNull;
      if (item == null) {
        return const Scaffold(body: Center(child: Text('Objeto eliminado')));
      }
      final loan = item.active;
      return Scaffold(
        appBar: AppBar(
          title: Text(item.name),
          actions: [
            IconButton(
              tooltip: 'Editar',
              onPressed: controller.busy ? null : () => edit(context, item),
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(item.category, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              loan == null
                  ? 'Disponible'
                  : 'Prestado a ${loan.borrower} · ${ItemDto.date(loan.due)}',
            ),
            if (controller.error != null) Text(controller.error!),
            const SizedBox(height: 20),
            if (loan == null)
              FilledButton.icon(
                onPressed: controller.busy
                    ? null
                    : () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LoanForm(controller: controller, item: item),
                        ),
                      ),
                icon: const Icon(Icons.handshake),
                label: const Text('Registrar préstamo'),
              )
            else
              FilledButton(
                onPressed: controller.busy
                    ? null
                    : () => controller.save(item.receive()),
                child: const Text('Registrar devolución'),
              ),
            const SizedBox(height: 20),
            Text('Actividad', style: Theme.of(context).textTheme.titleLarge),
            if (item.loans.isEmpty) const Text('Sin movimientos'),
            ...item.loans.reversed.map(
              (loan) => ListTile(
                title: Text(loan.borrower),
                subtitle: Text(ItemDto.date(loan.due)),
                trailing: Text(loan.returned ? 'Devuelto' : 'Activo'),
              ),
            ),
            if (loan == null)
              OutlinedButton(
                onPressed: controller.busy
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar objeto'),
                            content: const Text(
                              'Se eliminará también su historial.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true &&
                            await controller.remove(item) &&
                            context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                child: const Text('Eliminar objeto'),
              ),
          ],
        ),
      );
    },
  );
}

class LoanForm extends StatefulWidget {
  const LoanForm({super.key, required this.controller, required this.item});
  final LendingController controller;
  final Item item;
  @override
  State<LoanForm> createState() => _LoanFormState();
}

class _LoanFormState extends State<LoanForm> {
  final key = GlobalKey<FormState>();
  final borrower = TextEditingController();
  DateTime due = DateTime.now().add(const Duration(days: 7));
  @override
  void dispose() {
    borrower.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Registrar préstamo')),
    body: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) => Form(
        key: key,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Objeto: ${widget.item.name}'),
            TextFormField(
              controller: borrower,
              decoration: const InputDecoration(
                labelText: 'Alias de quien recibe',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Campo obligatorio'
                  : null,
            ),
            ListTile(
              title: const Text('Fecha de devolución'),
              subtitle: Text(ItemDto.date(due)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: due,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (selected != null && mounted) {
                  setState(() => due = selected);
                }
              },
            ),
            if (widget.controller.error != null) Text(widget.controller.error!),
            FilledButton(
              onPressed: widget.controller.busy
                  ? null
                  : () async {
                      if (!key.currentState!.validate()) {
                        return;
                      }
                      final item = widget.item.lend(
                        borrower.text,
                        due,
                        DateTime.now(),
                      );
                      if (await widget.controller.save(item) &&
                          context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              child: const Text('Confirmar préstamo'),
            ),
          ],
        ),
      ),
    ),
  );
}
