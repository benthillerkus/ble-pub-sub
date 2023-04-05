import 'dart:convert';

import 'package:blogerr/ble.dart';
import 'package:blogerr/definitions.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final logProvider = StreamProvider.autoDispose((ref) async* {
  final bleAdapter = ref.watch(bleAdapterProvider);
  final deviceId = ref.watch(bleConnectionProvider.notifier).id;
  final stream = bleAdapter
      .subscribeToCharacteristic(QualifiedCharacteristic(
          characteristicId: errorCharacteristicId,
          serviceId: brainServiceId,
          deviceId: deviceId))
      .map((bytes) => utf8.decode(bytes))
      .asyncMap((text) => compute(jsonDecode, text))
      .map((log) => Log.fromJson(log));

  var allResults = const <Log>[];

  yield allResults;
  await for (final log in stream) {
    allResults = [...allResults, log];
    yield allResults;
  }
});

class Log {
  DateTime received = DateTime.now();
  late String mac;
  late Map<Category, List<Error>> errors = {};
  late List<Log> capErrors = [];

  Log.fromJson(Map<String, dynamic> json) {
    mac = json['MAC'];

    for (final entry in json.entries) {
      if (entry.key == 'MAC') continue;
      final category = Category.values.firstWhere(
          (category) => category.label == entry.key,
          orElse: () => Category.unknown);
      final entries = <Error>[];
      try {
        for (final e in entry.value) {
          entries.add(Error.fromCode(int.parse('0x$e')));
        }
      } catch (e) {
        try {
          for (final e in entry.value) {
            capErrors.add(Log.fromJson(e));
          }
        } catch (e) {}
      }

      errors[category] = entries;
    }
  }
}
