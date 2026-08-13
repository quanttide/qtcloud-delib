// 本地标本数据源单元测试
//
// 验证 AssetResolutionStore 从打包资产（assets/data/*.json）加载
// profile 决议标本（前后端解耦后的默认数据源）。

import 'package:flutter_test/flutter_test.dart';

import 'package:studio/models/resolution.dart';
import 'package:studio/services/resolution_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AssetResolutionStore 加载全部内置标本且字段完整', () async {
    const AssetResolutionStore store = AssetResolutionStore();

    final List<Resolution> resolutions = await store.fetchResolutions();

    expect(resolutions, hasLength(4));
    expect(
      resolutions.map((r) => r.name).toList(),
      containsAll([
        'data-contract',
        'institutionalization',
        'object-storage-visualization',
        'recuirtment',
      ]),
    );
    for (final Resolution r in resolutions) {
      expect(r.id, isNotEmpty);
      expect(r.title, isNotEmpty);
      expect(r.content, isNotEmpty);
      expect(r.category, isNotEmpty);
    }
  });
}
