import 'package:flutter/material.dart';
import 'package:flutter_cnblogs/app/app_style.dart';
import 'package:flutter_cnblogs/models/blogs/blog_category_model.dart';
import 'package:flutter_cnblogs/modules/blogs/home/category/blogs_category_controller.dart';
import 'package:flutter_cnblogs/routes/app_navigation.dart';
import 'package:flutter_cnblogs/widgets/keep_alive_wrapper.dart';
import 'package:flutter_cnblogs/widgets/status/app_error_widget.dart';
import 'package:flutter_cnblogs/widgets/status/app_loadding_widget.dart';
import 'package:get/get.dart';

class BlogsCategoryView extends GetView<BlogsCategoryController> {
  const BlogsCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: Obx(() {
        if (controller.pageLoadding.value) {
          return const AppLoaddingWidget();
        }
        if (controller.pageError.value) {
          return AppErrorWidget(
            errorMsg: controller.errorMsg.value,
            onRefresh: controller.loadData,
          );
        }
        return ListView.builder(
          padding: AppStyle.edgeInsetsA12.copyWith(bottom: 24),
          itemCount: controller.groups.length,
          itemBuilder: (_, i) => _buildGroup(context, controller.groups[i]),
        );
      }),
    );
  }

  Widget _buildGroup(BuildContext context, BlogCategoryGroup group) {
    final theme = Theme.of(context);
    return Padding(
      padding: AppStyle.edgeInsetsV8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分组标题
          Padding(
            padding: AppStyle.edgeInsetsH4.copyWith(top: 4, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // 子分类标签流
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.children
                .map((e) => _buildChip(context, e))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, BlogCategoryItem item) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
      borderRadius: AppStyle.radius8,
      child: InkWell(
        borderRadius: AppStyle.radius8,
        onTap: () => AppNavigator.toCategoryPosts(
          name: item.name,
          path: item.path,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            item.name,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
