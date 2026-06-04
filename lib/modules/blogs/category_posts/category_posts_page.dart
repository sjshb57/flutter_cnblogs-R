import 'package:flutter/material.dart';
import 'package:flutter_cnblogs/app/app_style.dart';
import 'package:flutter_cnblogs/modules/blogs/category_posts/category_posts_controller.dart';
import 'package:flutter_cnblogs/widgets/items/blog_item_widget.dart';
import 'package:flutter_cnblogs/widgets/page_list_view.dart';
import 'package:get/get.dart';

class CategoryPostsPage extends GetView<CategoryPostsController> {
  const CategoryPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.name),
        centerTitle: false,
      ),
      body: PageListView(
        pageController: controller,
        padding: AppStyle.edgeInsetsA4,
        firstRefresh: true,
        itemBuilder: (_, i) => BlogItemWidget(controller.list[i]),
      ),
    );
  }
}
