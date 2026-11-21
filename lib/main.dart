import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;

import 'features/lending/data/mobilelab_repository.dart';
import 'features/lending/presentation/controller.dart';
import 'features/lending/presentation/app.dart';

void main() => runApp(const Bootstrap());

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late final http.Client client;
  late final LendingController controller;
  late final String endpoint;
  @override
  void initState() {
    super.initState();
    const configured = String.fromEnvironment('MOBILELAB_URL');
    endpoint = configured.isNotEmpty
        ? configured
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:4566'
        : 'http://127.0.0.1:4566';
    client = http.Client();
    controller = LendingController(
      MobileLabRepository(client, Uri.parse(endpoint)),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LendingApp(controller: controller, endpoint: endpoint);
}
