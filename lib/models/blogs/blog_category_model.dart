/// 博客园分类（一个顶级分组 + 其下的子分类）
class BlogCategoryGroup {
  /// 分组名称，如「后端开发」
  final String name;

  /// 分组本身的分类路径，如 /cate/2/
  final String path;

  /// 子分类
  final List<BlogCategoryItem> children;

  BlogCategoryGroup({
    required this.name,
    required this.path,
    required this.children,
  });
}

/// 单个分类项
class BlogCategoryItem {
  /// 分类名称，如「.NET」
  final String name;

  /// 分类路径，如 /cate/108698/ 或 /cate/java/
  final String path;

  BlogCategoryItem({required this.name, required this.path});
}
