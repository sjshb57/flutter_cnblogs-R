import 'package:flutter/material.dart';
import 'package:flutter_cnblogs/app/controller/base_controller.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class AppWebViewController extends BaseController {
  final String url;
  AppWebViewController(this.url);

  var title = "".obs;
  final UniqueKey webViewkey = UniqueKey();
  late InAppWebViewController? webViewController;
  final InAppWebViewSettings webViewSettings = InAppWebViewSettings(
    transparentBackground: true,
      useShouldOverrideUrlLoading: true,
  );
  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;
    pageLoadding.value = true;
  }

  void refreshWeb() {
    webViewController?.reload();
  }

  void onTitleChanged(InAppWebViewController controller, String? e) {
    title.value = e ?? "";
  }

  void onLoadStart(InAppWebViewController controller, Uri? uri) {
    pageLoadding.value = true;
    pageError.value = false;
  }

  void onLoadStop(InAppWebViewController controller, Uri? uri) async {
    pageLoadding.value = false;
  }

  void onReceivedError(InAppWebViewController controller,
      WebResourceRequest request, WebResourceError error) {
    pageLoadding.value = false;
    pageError.value = true;
    errorMsg.value = "${error.type} ${error.description}";
  }
}
