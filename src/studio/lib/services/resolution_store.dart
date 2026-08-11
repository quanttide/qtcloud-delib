// 决议数据源抽象与本地实现
//
// 前后端解耦：客户端直接内置 profile 决议标本（assets/data/*.json），
// 离线可用，不依赖服务端 API。ResolutionApi（服务端对接）代码保留，
// 作为 ResolutionStore 的另一实现，未来恢复 API 时切换注入即可。

import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../models/resolution.dart';

/// 数据源异常。
class ResolutionStoreException implements Exception {
  const ResolutionStoreException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 决议数据源抽象：UI 只依赖此接口。
abstract class ResolutionStore {
  /// 决议清单（按 name 排序，与标本文件一致）
  Future<List<Resolution>> fetchResolutions();

  /// 创建决议（本地标本只读，抛 [ResolutionStoreException]）。
  Future<Resolution> createResolution({
    required String name,
    required String title,
    String content = '',
    String category = '',
  });
}

/// 本地标本数据源：读取打包进客户端的 profile 决议标本。
///
/// 经 AssetManifest 动态发现 assets/data/*.json，新增标本无需改代码。
class AssetResolutionStore implements ResolutionStore {
  const AssetResolutionStore();

  static const String _assetDir = 'assets/data';

  @override
  Future<Resolution> createResolution({
    required String name,
    required String title,
    String content = '',
    String category = '',
  }) {
    throw const ResolutionStoreException('本地标本只读，请登录后创建');
  }

  @override
  Future<List<Resolution>> fetchResolutions() async {
    final AssetManifest manifest =
        await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> keys = manifest
        .listAssets()
        .where((String key) =>
            key.startsWith('$_assetDir/') && key.endsWith('.json'))
        .toList()
      ..sort();

    final List<Resolution> resolutions = [];
    for (final String key in keys) {
      final String raw = await rootBundle.loadString(key);
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      resolutions.add(Resolution.fromJson(json));
    }
    return resolutions;
  }
}
