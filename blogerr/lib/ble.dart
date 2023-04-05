import 'dart:async';

import 'package:blogerr/definitions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

final bleAdapterProvider = Provider((ref) => FlutterReactiveBle());

final bleDevicesProvider = StreamProvider.autoDispose((ref) async* {
  final bleAdapter = ref.watch(bleAdapterProvider);

  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetooth,
    Permission.locationWhenInUse,
  ].request();

  final stream = bleAdapter.scanForDevices(withServices: [brainServiceId]);

  var allResults = const <DiscoveredDevice>[];
  await for (final scanResult in stream) {
    if (allResults.map((e) => e.id).contains(scanResult.id)) continue;
    allResults = [...allResults, scanResult];
    yield allResults;
  }
});

final bleConfigurationStateProvider = StreamProvider.autoDispose((ref) {
  final bleAdapter = ref.watch(bleAdapterProvider);

  return bleAdapter.statusStream;
});

final bleConnectionProvider =
    NotifierProvider<BleConnectionNotifier, ConnectionStateUpdate>(
        BleConnectionNotifier.new);

class BleConnectionNotifier extends Notifier<ConnectionStateUpdate> {
  var _connection = const Stream<ConnectionStateUpdate>.empty();
  StreamSubscription<ConnectionStateUpdate>? _subscription;
  final _disconnected = const ConnectionStateUpdate(
      deviceId: '',
      connectionState: DeviceConnectionState.disconnected,
      failure: null);

  @override
  build() {
    ref.watch(bleAdapterProvider);
    ref.onDispose(disconnect);

    return _disconnected;
  }

  String _id = "";
  String get id => _id;

  void connect(String id, {Duration? timeout = const Duration(seconds: 5)}) {
    final bleAdapter = ref.read(bleAdapterProvider);
    _connection = bleAdapter.connectToDevice(id: id, connectionTimeout: timeout);

    disconnect();

    _subscription = _connection.listen((newState) {
      _id = id;
      state = newState;
    }, onError: (e) {
      print(e);
    }, cancelOnError: true, onDone: disconnect);
  }

  Future<void> disconnect() async {
    var future = _subscription?.cancel();
    _subscription = null;
    state = _disconnected;
    await future;
  }
}
