import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cnblogs/app/app_style.dart';
import 'package:flutter_cnblogs/generated/locales.g.dart';
import 'package:flutter_cnblogs/modules/user/home/user_home_controller.dart';
import 'package:flutter_cnblogs/services/user_service.dart';
import 'package:flutter_cnblogs/widgets/net_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UserHomePage extends GetView<UserHomeController> {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: Get.isDarkMode
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: EasyRefresh(
            header: const MaterialHeader(),
            onRefresh: UserService.instance.refreshProfile,
            child: ListView(
              padding: AppStyle.edgeInsetsA4,
              children: [
                AppStyle.vGap12,
                // 用户名、头像
                Obx(
                  () => UserService.instance.logined.value
                      ? _buildCard(
                          context,
                          children: [
                            ListTile(
                              leading: _buildPhoto(
                                  context,
                                  UserService.instance.userProfile.value
                                          ?.avatar ??
                                      ""),
                              title: Text(
                                UserService.instance.userProfile.value
                                        ?.displayName ??
                                    "",
                                style: const TextStyle(height: 1.0),
                              ),
                              subtitle: Text(
                                  LocaleKeys.user_home_seniority.trParams({
                                "seniority": (UserService.instance.userProfile
                                        .value?.seniority ??
                                    ""),
                              })),
                              trailing: IconButton(
                                onPressed: controller.logout,
                                icon: const Icon(Remix.logout_box_r_line),
                              ),
                            ),
                          ],
                        )
                      : _buildCard(
                          context,
                          children: [
                            ListTile(
                              leading: _buildPhoto(context, ""),
                              title: Text(
                                LocaleKeys.user_home_not_login.tr,
                                style: const TextStyle(height: 1.0),
                              ),
                              subtitle: Text(
                                LocaleKeys.user_home_to_login.tr,
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onTap: controller.login,
                            ),
                          ],
                        ),
                ),
                _buildCard(
                  context,
                  children: [
                    ListTile(
                      leading: const Icon(Remix.article_line),
                      title: Text(LocaleKeys.user_home_my_blog.tr),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.myBlog,
                    ),
                    ListTile(
                      leading: const Icon(Remix.star_line),
                      title: Text(LocaleKeys.user_home_bookmark.tr),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.myBookmark,
                    ),
                  ],
                ),
                _buildCard(
                  context,
                  children: [
                    ListTile(
                      leading: Icon(
                          Get.isDarkMode ? Remix.moon_line : Remix.sun_line),
                      title: Text(LocaleKeys.user_home_theme.tr),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.setTheme,
                    ),
                    ListTile(
                      leading: const Icon(Remix.translate),
                      title: Text(LocaleKeys.user_home_language.tr),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.setLanguage,
                    ),
                  ],
                ),
                _buildCard(
                  context,
                  children: [
                    ListTile(
                      leading: const Icon(Remix.github_fill),
                      title: Text(LocaleKeys.user_home_github.tr),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        launchUrlString(
                          "https://github.com/sjshb57/flutter_cnblogs-R",
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Remix.upload_2_line),
                      title: Text(LocaleKeys.user_home_update.tr),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.checkUpdate,
                    ),
                    ListTile(
                      leading: const Icon(Remix.information_line),
                      title: Text(LocaleKeys.user_home_about.tr),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.about,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(BuildContext context, String? photo) {
    // 白天跟随顶部 tab 栏的藏蓝(primary)，深色沿用之前那个深蓝(primaryContainer)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark
        ? AppColors.darkColorScheme.primaryContainer
        : AppColors.lightColorScheme.primary;
    final Color fg = isDark
        ? AppColors.darkColorScheme.onPrimaryContainer
        : AppColors.lightColorScheme.onPrimary;
    const double size = 54;
    if (photo == null || photo.isEmpty) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Remix.user_fill,
          color: fg,
          size: 28,
        ),
      );
    }
    // 已登录：固定方形盒 + 圆形裁剪，保证始终是正圆而非椭圆
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: NetImage(
          photo,
          width: size,
          height: size,
          borderRadius: 0,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      margin: AppStyle.edgeInsetsH16.copyWith(top: 16),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: theme.brightness == Brightness.dark ? .4 : .6),
        borderRadius: AppStyle.radius12,
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(
            iconTheme: theme.iconTheme.copyWith(size: 24),
            listTileTheme: ListTileThemeData(
              shape:
                  RoundedRectangleBorder(borderRadius: AppStyle.radius12),
              minVerticalPadding: 18,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
