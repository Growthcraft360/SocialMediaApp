import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// GitHub par yeh JSON file upload karo:
/// https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/version.json
///
/// version.json content:
/// {
///   "version": "1.0.1",
///   "build": 2,
///   "apk_url": "https://github.com/YOUR_USERNAME/YOUR_REPO/releases/download/v1.0.1/app-release.apk",
///   "release_notes": "Bug fixes aur improvements"
/// }

class UpdateInfo {
  final String latestVersion;
  final int latestBuild;
  final String apkUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.latestBuild,
    required this.apkUrl,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
    latestVersion: json['version']?.toString() ?? '',
    latestBuild: int.tryParse(json['build']?.toString() ?? '0') ?? 0,
    apkUrl: json['apk_url']?.toString() ?? '',
    releaseNotes: json['release_notes']?.toString() ?? '',
  );
}

class UpdateService {
  static const String _versionCheckUrl =
      'https://raw.githubusercontent.com/Growthcraft360/SocialMediaApp/main/version.json';
  static final Dio _dio = Dio();

  /// Startup par call karo — agar update available ho to UpdateInfo return karta hai
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final res = await _dio
          .get(_versionCheckUrl)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200 || res.data == null) return null;

      final info = UpdateInfo.fromJson(
        res.data is Map ? res.data as Map<String, dynamic> : {},
      );

      if (info.latestBuild > currentBuild) return info;
      return null;
    } catch (_) {
      return null; // silently fail — update check optional hai
    }
  }

  /// APK download karo aur install prompt show karo
  static Future<void> downloadAndInstall(
      UpdateInfo info, {
        required void Function(double progress) onProgress,
        required void Function(String error) onError,
      }) async {
    try {
      // Android 8+ ke liye install permission
      if (!await Permission.requestInstallPackages.isGranted) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          onError('Install permission nahi mili. Settings mein jaake allow karo.');
          return;
        }
      }

      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/growthcraft_update.apk';

      await _dio.download(
        info.apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        onError('APK open nahi hua: ${result.message}');
      }
    } on DioException catch (e) {
      onError('Download fail: ${e.message ?? 'Network error'}');
    } catch (e) {
      onError('Kuch galat hua. Dobara try karo.');
    }
  }
}