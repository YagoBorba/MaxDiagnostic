import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../../core/error/exceptions.dart';
import '../../domain/entities/final_results_entity.dart';

abstract class DeviceInfoLocalDataSource {
	Future<DeviceInfoEntity> getDeviceInfo();
}

class DeviceInfoLocalDataSourceImpl implements DeviceInfoLocalDataSource {
	final DeviceInfoPlugin deviceInfo;

	DeviceInfoLocalDataSourceImpl({required this.deviceInfo});

	@override
	Future<DeviceInfoEntity> getDeviceInfo() async {
		try {
			if (kIsWeb) {
				final webInfo = await deviceInfo.webBrowserInfo;
				return DeviceInfoEntity(
					deviceModel: '${webInfo.browserName.name} ${webInfo.platform?.toString() ?? 'Web'}',
					deviceBrand: webInfo.vendor ?? 'Web Browser',
					operatingSystem: 'Web',
					osVersion: webInfo.userAgent ?? 'Unknown',
					deviceId: null,
				);
			}

			if (Platform.isAndroid) {
				final info = await deviceInfo.androidInfo;
				return DeviceInfoEntity(
					deviceModel: info.model,
					deviceBrand: info.brand,
					operatingSystem: 'Android',
					osVersion: info.version.release,
					deviceId: null,
				);
			} else if (Platform.isIOS) {
				final info = await deviceInfo.iosInfo;
				return DeviceInfoEntity(
					deviceModel: info.utsname.machine,
					deviceBrand: 'Apple',
					operatingSystem: 'iOS',
					osVersion: info.systemVersion,
					deviceId: null,
				);
			}

			return const DeviceInfoEntity(
				deviceModel: 'Unknown Device',
				deviceBrand: 'Unknown',
				operatingSystem: 'Unknown',
				osVersion: 'Unknown',
				deviceId: null,
			);
		} catch (e) {
			throw DeviceInfoException('Failed to get device info: ${e.toString()}');
		}
	}
}

