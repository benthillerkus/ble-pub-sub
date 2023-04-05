import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

enum Device {
  brain(Icons.memory, "Brain"),
  node(Icons.account_tree, "Node");

  const Device(this.icon, this.label);

  final IconData icon;
  final String label;
}

final brainServiceId = Uuid.parse("ca30c812-3ed5-44ea-961e-196a8c601de7");
final errorCharacteristicId =
    Uuid.parse("1db9a7de-135f-4509-b226-bd19d42126fd");

enum Category {
  unknown(Icons.help, "Unknown"),
  user(Icons.person, "User"),
  backend(Icons.cloud, "Backend"),
  ble(Icons.bluetooth, "Bluetooth"),
  kswitch(Icons.power, "Switch"),
  dev(Icons.code, "Dev"),
  temperature(Icons.thermostat, "Temperature"),
  ambient(Icons.wb_sunny, "Ambient"),
  battery(Icons.battery_full, "Battery"),
  espNow(Icons.drag_indicator_sharp, "Espnow"),
  level(Icons.trending_up, "Level");

  const Category(this.icon, this.label);

  final IconData icon;
  final String label;
}

enum Error {
  unknownUnknown(0x0000, Device.node, Category.unknown, "Unknown error"),
  brainUserUnknown(0x1000, Device.brain, Category.user, "User unknown error"),
  brainUserMemoryPowerCycleReq(0x1001, Device.brain, Category.user,
      "Memory error, power cycle required"),
  brainUserTechnicalPowerCycleReq(0x1002, Device.brain, Category.user,
      "Technical error, power cycle required"),
  brainUserNoNetwork(
      0x1003, Device.brain, Category.user, "No network connection"),
  brainUserNoGPS(0x1004, Device.brain, Category.user, "No GPS connection"),
  brainUserNodeNotAvailable(
      0x1005, Device.brain, Category.user, "Node not available"),

  brainBackendUnknown(0x1100, Device.brain, Category.backend, "Unknown error"),
  brainBackendCommunicationTimeout(
      0x1101, Device.brain, Category.backend, "Communication timeouts"),
  brainBackendFile(0x1102, Device.brain, Category.backend, "File error"),
  brainBackendGNSS(0x1103, Device.brain, Category.backend, "GNSS error"),
  brainBackendIP(0x1104, Device.brain, Category.backend, "IP error"),
  brainBackendHTTP(0x1105, Device.brain, Category.backend, "HTTP error"),

  brainBLEUnknown(0x1200, Device.brain, Category.ble, "BLE unknown error"),
  brainBLESettingAdvertisementData(
      0x1201, Device.brain, Category.ble, "Error setting advertisement data"),
  brainBLEEnablingAdvertisement(
      0x1202, Device.brain, Category.ble, "Error enabling advertisement"),
  brainBLEInitialisingSecurity(
      0x1203, Device.brain, Category.ble, "Error initialising security"),
  brainBLEDeviceDisconnect(
      0x1204, Device.brain, Category.ble, "Device disconnect error"),
  brainBLEMoreThan3Devices(
      0x1205, Device.brain, Category.ble, "More than 3 devices"),

  nodeSwitchUnknown(
      0x2000, Device.node, Category.kswitch, "Switch unknown error"),
  nodeUserEfuse(0x2001, Device.node, Category.user, "Efuse error"),
  nodeDevUnknown(0x2101, Device.node, Category.dev,
      "Unknown error"), // In the spreadsheet the hex code is not the decimal code for this error -- probably a typo

  nodeTemperatureUnknown(0x3000, Device.node, Category.temperature,
      "Unknown temperature related error"),
  nodeTemperatureSensorNotConnected(
      0x3001, Device.node, Category.temperature, "Sensor not connected"),
  nodeTemperatureLowerLimit(0x3002, Device.node, Category.temperature,
      "Lower limit temperature warning"),
  nodeTemperatureUpperLimit(0x3003, Device.node, Category.temperature,
      "Upper limit temperature warning"),

  nodeAmbientUnknown(
      0x4000, Device.node, Category.ambient, "Unknown ambient related error"),

  nodeBatteryUnknown(
      0x5000, Device.node, Category.battery, "Unknown battery related error"),
  nodeBatteryTemperatureSensorNotConnected(0x5001, Device.node,
      Category.battery, "Temperature sensor not connected"),
  nodeBatteryLowerLimitSocWarning(
      0x5002, Device.node, Category.battery, "Lower limit SOC warning (<20%)"),
  nodeBatteryLowerLimitSocError(
      0x5003, Device.node, Category.battery, "Lower limit SOC error (<10%)"),
  nodeBatteryTemperatureWarning(0x5004, Device.node, Category.battery,
      "Battery temperature warning (>60°C)"),
  nodeBatteryTemperatureError(0x5005, Device.node, Category.battery,
      "Battery temperature error (>90°C)"),
  nodeBatteryFuseWarning(0x5006, Device.node, Category.battery,
      "Fuse warning -> Min. one fuse not connected"),

  nodeLevelUnknown(0x6000, Device.node, Category.level, "Unknown level error"),
  nodeLevelSensorNotConnected(
      0x6001, Device.node, Category.level, "Sensor not connected"),
  nodeLevelLowerLimit(
      0x6002, Device.node, Category.level, "Lower limit level warning"),
  nodeLevelUpperLimit(
      0x6003, Device.node, Category.level, "Upper limit level warning"),
  ;

  final int code;
  final Device device;
  final Category category;
  final String message;

  const Error(this.code, this.device, this.category, this.message);

  static Error fromCode(int code) {
    try {
      return Error.values.firstWhere((e) => e.code == code);
    } catch (e) {
      if (code >= Error.brainUserUnknown.code &&
          code < Error.brainBackendUnknown.code) {
        return Error.brainUserUnknown;
      } else if (code >= Error.brainBackendUnknown.code &&
          code < Error.brainBLEUnknown.code) {
        return Error.brainBackendUnknown;
      } else if (code >= Error.brainBLEUnknown.code &&
          code < Error.nodeSwitchUnknown.code) {
        return Error.brainBLEUnknown;
      } else if (code >= Error.nodeSwitchUnknown.code &&
          code < Error.nodeTemperatureUnknown.code) {
        return Error.nodeSwitchUnknown;
      } else if (code >= Error.nodeTemperatureUnknown.code &&
          code < Error.nodeAmbientUnknown.code) {
        return Error.nodeTemperatureUnknown;
      } else if (code >= Error.nodeAmbientUnknown.code &&
          code < Error.nodeBatteryUnknown.code) {
        return Error.nodeAmbientUnknown;
      } else if (code >= Error.nodeBatteryUnknown.code &&
          code < Error.nodeLevelUnknown.code) {
        return Error.nodeBatteryUnknown;
      } else if (code >= Error.nodeLevelUnknown.code) {
        return Error.nodeLevelUnknown;
      }

      return Error.unknownUnknown;
    }
  }
}
