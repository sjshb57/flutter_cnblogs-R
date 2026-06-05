import 'package:flutter/widgets.dart';
import 'package:flutter_cnblogs/app/controller/base_controller.dart';
import 'package:flutter_cnblogs/app/log.dart';
import 'package:flutter_cnblogs/requests/base/api.dart';
import 'package:flutter_cnblogs/requests/oauth_request.dart';
import 'package:flutter_cnblogs/services/user_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class LoginController extends BaseController {
  final UniqueKey webViewkey = UniqueKey();
  final OAuthRequest request = OAuthRequest();
  late InAppWebViewController? webViewController;
  final InAppWebViewSettings webViewSettings = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    // 登录页是 JS 渲染的 SPA，需要 JS / DOM storage / 三方 cookie 才能正常显示与获取验证码
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    thirdPartyCookiesEnabled: true,
    useHybridComposition: true,
    // 不用透明背景/不每次清缓存：避免 SPA 出现整页空白
    transparentBackground: false,
    clearCache: false,
  );
  /// 登录授权地址（作为 WebView 的初始请求，避免创建后立刻 loadUrl 导致首次连接失败）
  URLRequest get initialUrlRequest => URLRequest(
        url: WebUri(
          Uri(
            scheme: "https",
            host: "oauth.cnblogs.com",
            path: "connect/authorize",
            queryParameters: {
              "client_id": Api.kClientID,
              "scope": "openid profile CnBlogsApi offline_access",
              "response_type": "code id_token",
              "redirect_uri": "https://oauth.cnblogs.com/auth/callback",
              "state": DateTime.now().millisecondsSinceEpoch.toString(),
              "nonce": DateTime.now().millisecondsSinceEpoch.toString(),
            },
          ).toString(),
        ),
      );

  void onWebViewCreated(InAppWebViewController controller) async {
    webViewController = controller;
  }

  void goLogin() {
    webViewController?.loadUrl(urlRequest: initialUrlRequest);
  }

  void refreshWeb() {
    _retried = false;
    webViewController?.reload();
  }

  void onLoadStart(InAppWebViewController controller, Uri? uri) {
    pageLoadding.value = true;
    pageError.value = false;
  }

  void onLoadStop(InAppWebViewController controller, Uri? uri) async {
    pageLoadding.value = false;
  }

  // 首次加载有时因 WebView 引擎冷启动导致连接被关闭，自动重试一次，避免用户手动刷新
  bool _retried = false;

  void onReceivedError(InAppWebViewController controller,
      WebResourceRequest request, WebResourceError error) async {
    if (!_retried) {
      _retried = true;
      pageError.value = false;
      pageLoadding.value = true;
      await Future.delayed(const Duration(milliseconds: 500));
      controller.loadUrl(urlRequest: initialUrlRequest);
      return;
    }
    pageLoadding.value = false;
    pageError.value = true;
    errorMsg.value = "${error.type} ${error.description}";
  }

  Future<NavigationActionPolicy?> shouldOverrideUrlLoading(
      InAppWebViewController controller, NavigationAction action) async {
    var uri = action.request.url!;
    var url = uri.toString();
    if (url.contains('oauth.cnblogs.com/auth/callback')) {
      var code = RegExp(r"code=(.*?)&").firstMatch(url)?.group(1) ?? "";
      Log.i(code);
      getToken(code);
      return NavigationActionPolicy.CANCEL;
    }

    Log.i(url);
    return NavigationActionPolicy.ALLOW;
  }

  void getToken(String code) async {
    try {
      pageLoadding.value = true;
      var userToken = await request.getUserToken(code);
      UserService.instance.setAuthInfo(userToken);
      Get.back(result: true);
    } catch (e) {
      Log.logPrint(e);
    } finally {
      pageLoadding.value = false;
    }
  }
}
