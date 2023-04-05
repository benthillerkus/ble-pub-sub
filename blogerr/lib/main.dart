import 'dart:convert';
import 'dart:io';

import 'package:blogerr/ble.dart';
import 'package:blogerr/logs.dart';
import 'package:blogerr/widgets/blurred_drawer.dart';
import 'package:blogerr/widgets/logs_viewer.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const kExtremeElevation = 24.0;
const kExtremeRadius = Radius.circular(32.0);

void main() {
  runApp(ProviderScope(overrides: [
    if (!(Platform.isAndroid || Platform.isIOS) || kIsWeb)
      logProvider.overrideWith((ref) async* {
        final stream =
            Stream.periodic(const Duration(milliseconds: 800), (index) {
          if (index % 2 == 0) {
            return '''{
              "MAC": "Brain",
              "User": [1001, 1003],
              "Backend": [1102, 1105],
              "Ble": [1202, 1204],
              "Espnow": [1301, 1303]
            }''';
          } else {
            return '''{
              "MAC": "34:88:32:wv:ki:1m",
              "User": [2001, 2003],
              "Dev": [2102, 2105],
              "Cap_errors": [
                {
                  "User": [2001],
                  "Dev": [2103]
                },
                {
                  "User": [2001],
                  "Dev": [2103]
                }
              ]
            }''';
          }
        })
                .asyncMap((text) => compute(jsonDecode, text))
                .map((log) => Log.fromJson(log));
        var allResults = const <Log>[];

        yield allResults;
        await for (final log in stream) {
          allResults = [...allResults, log];
          yield allResults;
        }
      }),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: FlexThemeData.light(
          scheme: FlexScheme.bahamaBlue,
          appBarElevation: 0.0,
          appBarStyle: FlexAppBarStyle.background,
          textTheme: GoogleFonts.poppinsTextTheme(),
          primaryTextTheme: GoogleFonts.robotoTextTheme()),
      themeMode: ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleConnection = (!(Platform.isAndroid || Platform.isIOS) || kIsWeb)
        ? const ConnectionStateUpdate(
            deviceId: '',
            connectionState: DeviceConnectionState.connected,
            failure: null)
        : ref.watch(bleConnectionProvider);

    return Scaffold(
      appBar: AppBar(
        // leading: const IconButton(onPressed: ScaffoldState, icon: Icon(Icons.menu)),
        centerTitle: true,
        title: const Text("COMPLIANCE"),
        actions: [
          if (bleConnection.connectionState == DeviceConnectionState.connected)
            IconButton(
                tooltip: "Disconnect",
                onPressed: () {
                  ref.read(bleConnectionProvider.notifier).disconnect();
                },
                icon: const Icon(Icons.bluetooth_disabled))
        ],
      ),
      drawer: const BlurredDrawer(),
      drawerScrimColor: Colors.transparent,
      body: Builder(builder: (context) {
        if (bleConnection.connectionState == DeviceConnectionState.connected) {
          return const LogsScreen();
        } else if (bleConnection.connectionState ==
            DeviceConnectionState.connecting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return const ListBLEDevicesScreen();
        }
      }),
    );
  }
}

class ListBLEDevicesScreen extends HookConsumerWidget {
  const ListBLEDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(bleDevicesProvider);

    return results.when(
        data: (devices) => ListView.builder(
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  onTap: () {
                    ref.read(bleConnectionProvider.notifier).connect(device.id);
                  },
                  leading: Text(device.id),
                  title: Text(device.name),
                  subtitle: Text(device.serviceUuids.toString()),
                );
              },
              itemCount: devices.length,
            ),
        error: ((error, stackTrace) => Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()));
  }
}

class LogsScreen extends HookConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mustConserveSpace = MediaQuery.of(context).size.aspectRatio < 0.8;

    return Center(
      child: Card(
        margin: mustConserveSpace
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 32)
            : const EdgeInsets.all(64),
        elevation: (mustConserveSpace ? 0.05 : 1) * kExtremeElevation,
        shadowColor: Theme.of(context).shadowColor.withOpacity(0.5),
        color: Theme.of(context).colorScheme.tertiaryContainer,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(kExtremeRadius)),
        child: Padding(
          padding: EdgeInsets.symmetric(
              vertical: kExtremeRadius.y, horizontal: kExtremeRadius.x),
          child: const LogsViewer(),
        ),
      ),
    );
  }
}
