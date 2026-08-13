// 量潮议事云入口

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'screens/login_screen.dart';
import 'screens/resolution_list.dart';
import 'screens/topic_list.dart';
import 'services/topic_api.dart';
import 'services/api_resolution_store.dart';
import 'services/auth_service.dart';
import 'services/resolution_store.dart';

void main() {
  runApp(const DelibApp());
}

class DelibApp extends StatelessWidget {
  const DelibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '量潮议事云',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const AuthGate(),
    );
  }
}

// 登录门禁：未登录显示登录页；登录后进入主框架（数据源切 ApiResolutionStore）。
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _auth = AuthService();
  ResolutionStore? _store; // 非空 = 已登录（ApiResolutionStore）
  String? _token;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await _auth.storedToken();
    if (token != null && token.isNotEmpty) {
      // 验证 token 有效性（旧 token 过期会导致 401——失效则清除回登录页）
      if (await _validateToken(token)) {
        setState(() {
          _token = token;
          _store = ApiResolutionStore(
            baseUrl: _apiBaseUrl(),
            token: token,
          );
        });
      } else {
        await _auth.logout();
      }
    }
  }

  /// 调 userinfo 验证 token；401 视为失效。
  Future<bool> _validateToken(String token) async {
    try {
      final resp = await http.get(
        Uri.parse('${_AuthGateState._apiBaseUrl()}/userinfo'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 议事云 API 地址：与登录地址同网关（QTCLOUD_DELIB_API_BASE_URL 注入生产网关）。
  static String _apiBaseUrl() {
    const String fromEnv = String.fromEnvironment('QTCLOUD_DELIB_API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return 'http://localhost:8080';
  }

  @override
  Widget build(BuildContext context) {
    if (_store == null) {
      return LoginScreen(
        auth: _auth,
        onSuccess: () async {
          final token = await _auth.storedToken();
          setState(() {
            _token = token;
            _store = ApiResolutionStore(
              baseUrl: _apiBaseUrl(),
              token: token ?? '',
            );
          });
        },
      );
    }
    return MainShell(store: _store, token: _token);
  }
}

// 主框架：侧边导航栏（议题 / 决议）+ 内容区
//
// 桌面端采用 NavigationRail（Material 3）；后续如需响应式，
// 可用 LayoutBuilder 在窄屏降级为 Drawer。

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.store, this.token});

  /// 决议数据源（测试可注入替身，默认本地标本）
  final ResolutionStore? store;

  /// 登录 JWT（议题/决议 API 用）
  final String? token;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    TopicScreen(api: _topicApi()),
    ResolutionScreen(store: widget.store),
  ];

  TopicApi? _topicApi() {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      return null;
    }
    return TopicApi(baseUrl: _AuthGateState._apiBaseUrl(), token: token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.topic_outlined),
                selectedIcon: Icon(Icons.topic),
                label: Text('议题'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.gavel_outlined),
                selectedIcon: Icon(Icons.gavel),
                label: Text('决议'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
