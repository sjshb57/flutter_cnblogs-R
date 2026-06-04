import 'package:flutter_cnblogs/app/controller/base_controller.dart';
import 'package:flutter_cnblogs/models/blogs/blog_category_model.dart';
import 'package:flutter_cnblogs/requests/blogs_request.dart';
import 'package:get/get.dart';

class BlogsCategoryController extends BaseController {
  final BlogsRequest blogsRequest = BlogsRequest();

  final RxList<BlogCategoryGroup> groups = <BlogCategoryGroup>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      pageError.value = false;
      pageLoadding.value = true;
      final result = await blogsRequest.getCategories();
      groups.value = result;
      pageEmpty.value = result.isEmpty;
    } catch (e) {
      pageError.value = true;
      errorMsg.value = e.toString();
    } finally {
      pageLoadding.value = false;
    }
  }
}
