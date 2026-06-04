import 'package:flutter/material.dart';
import 'package:flutter_cnblogs/app/app_style.dart';
import 'package:flutter_cnblogs/app/controller/app_settings_controller.dart';
import 'package:flutter_cnblogs/app/utils.dart';
import 'package:flutter_cnblogs/generated/locales.g.dart';
import 'package:flutter_cnblogs/routes/app_navigation.dart';
import 'package:flutter_cnblogs/routes/route_path.dart';
import 'package:flutter_cnblogs/services/user_service.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UserHomeController extends GetxController {
  final AppSettingsController settingController =
      Get.find<AppSettingsController>();
  @override
  void onInit() {
    UserService.instance.refreshProfile();
    super.onInit();
  }

  /// 登录
  void login() {
    UserService.instance.login();
  }

  /// 退出登录
  void logout() async {
    var result = await Utils.showAlertDialog(
      LocaleKeys.user_home_logout_msg.tr,
      title: LocaleKeys.user_home_logout.tr,
    );
    if (result) {
      UserService.instance.logout();
    }
  }

  /// 我的博客
  void myBlog() async {
    if (!UserService.instance.logined.value &&
        !(await UserService.instance.login())) {
      return;
    }
    var blogApp = UserService.instance.userProfile.value?.blogApp ?? "";
    if (blogApp.isNotEmpty) {
      AppNavigator.toUserBlog(blogApp);
    }
  }

  /// 我的收藏
  void myBookmark() {
    Get.toNamed(RoutePath.kUserBookmark);
  }

  /// 主题设置
  void setTheme() {
    settingController.changeTheme();
  }

  /// 语言设置
  void setLanguage() {
    settingController.changeLanguage();
  }

  /// 关于我们
  void about() {
    Get.dialog(AboutDialog(
      applicationIcon: Image.asset(
        'assets/images/logo.png',
        width: 48,
        height: 48,
      ),
      applicationName: LocaleKeys.app_name.tr,
      applicationVersion: 'v${Utils.packageInfo.version}',
      applicationLegalese: '© 2026 sjshb57 · 基于 MIT 协议开源',
      children: [
        AppStyle.vGap12,
        const Text(
          '使用 Flutter 编写的博客园第三方客户端。\n'
          '本项目 fork 自 xiaoyaocz/flutter_cnblogs，'
          '在其基础上做了现代化适配与功能修复。',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        AppStyle.vGap12,
        _aboutLink('本项目主页', 'https://github.com/sjshb57/flutter_cnblogs-R'),
        _aboutLink('原项目', 'https://github.com/xiaoyaocz/flutter_cnblogs'),
        _aboutLink('数据来源', 'https://www.cnblogs.com'),
      ],
    ));
  }

  Widget _aboutLink(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => launchUrlString(url, mode: LaunchMode.externalApplication),
        child: Row(
          children: [
            Text('$label：', style: const TextStyle(fontSize: 13)),
            Expanded(
              child: Text(
                url,
                style: const TextStyle(fontSize: 13, color: Colors.blue),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 检查更新
  void checkUpdate() {
    Utils.checkUpdate(showMsg: true);
  }
}
