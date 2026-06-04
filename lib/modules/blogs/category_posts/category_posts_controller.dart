import 'package:flutter_cnblogs/app/controller/base_controller.dart';
import 'package:flutter_cnblogs/models/blogs/blog_list_item_model.dart';
import 'package:flutter_cnblogs/requests/blogs_request.dart';

class CategoryPostsController extends BasePageController<BlogListItemModel> {
  final String name;
  final String path;
  CategoryPostsController({required this.name, required this.path});

  final BlogsRequest blogsRequest = BlogsRequest();

  @override
  Future<List<BlogListItemModel>> getData(int page, int pageSize) async {
    return await blogsRequest.getCategoryPosts(path: path, pageIndex: page);
  }
}
