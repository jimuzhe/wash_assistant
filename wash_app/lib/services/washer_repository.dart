import '../models/washer_config.dart';
import '../models/washer_device.dart';
import 'washer_api.dart';

class WasherRepository {
  WasherRepository({WasherApi? api}) : _api = api ?? WasherApi();

  final WasherApi _api;

  void updateConfig(WasherConfig config) {
    _api.applyConfig(config);
  }

  Future<List<WasherDevice>> fetchDevices(List<String> deviceCodes) async {
    if (deviceCodes.isEmpty) {
      return const [];
    }
    final devices = <WasherDevice>[];
    for (final code in deviceCodes) {
      final device = await _api.fetchDevice(code);
      devices.add(device);
    }
    return devices;
  }
}
