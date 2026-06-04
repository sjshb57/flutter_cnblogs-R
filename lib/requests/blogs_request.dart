import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_cnblogs/models/blogs/blog_category_model.dart';
import 'package:flutter_cnblogs/models/blogs/blog_comment_item_model.dart';
import 'package:flutter_cnblogs/models/blogs/blog_content_model.dart';
import 'package:flutter_cnblogs/models/blogs/blog_list_item_model.dart';
import 'package:flutter_cnblogs/models/blogs/knowledge_list_item_model.dart';
import 'package:flutter_cnblogs/models/blogs/user_blog_info_model.dart';
import 'package:flutter_cnblogs/requests/base/http_client.dart';

class BlogsRequest {
  // ---- 网页片段解析用的正则（只编译一次）----
  static final RegExp _rePickedItem = RegExp(
      r'<article class="post-item editorpick-item">(.*?)</article>',
      dotAll: true);
  static final RegExp _reRankItem = RegExp(
      r'<article class="post-item" data-post-id="(\d+)">(.*?)</article>',
      dotAll: true);
  static final RegExp _reTitle = RegExp(
      r'class="post-item-title"\s+href="([^"]+)"[^>]*>(.*?)</a>',
      dotAll: true);
  static final RegExp _rePickedDate =
      RegExp(r'class="editorpick-item-meta">([^<]+)</span>');
  static final RegExp _reAvatar = RegExp(r'<img src="([^"]+)"\s+class="avatar"');
  static final RegExp _reAuthor =
      RegExp(r'class="post-item-author"[^>]*>\s*<span>([^<]+)</span>');
  static final RegExp _reSummary =
      RegExp(r'<p class="post-item-summary">(.*?)</p>', dotAll: true);
  static final RegExp _reSummaryAnchor = RegExp(r'<a\b.*?</a>', dotAll: true);
  static final RegExp _reRankDate =
      RegExp(r'class="post-meta-item">\s*<span>([\d\-: ]+)</span>');
  static final RegExp _reIdFromUrl = RegExp(r'/p/(\d+)');
  static final RegExp _reBlogapp = RegExp(r'cnblogs\.com/([^/]+)/p/');
  static final RegExp _reTag = RegExp(r'<[^>]+>');
  static final RegExp _reSpaces = RegExp(r'\s+');
  static final Map<String, RegExp> _reMeta = {
    '阅读': RegExp(r'title="阅读 (\d+)"'),
    '评论': RegExp(r'title="评论 (\d+)"'),
    '推荐': RegExp(r'title="推荐 (\d+)"'),
  };

  /// 分页获取网站首页博文列表
  /// - https://api.cnblogs.com/api/blogposts/@sitehome?pageIndex={pageIndex}&pageSize={pageSize}
  Future<List<BlogListItemModel>> getSitehome(
      {required int pageIndex, int pageSize = 20}) async {
    List<BlogListItemModel> ls = [];
    var result = await HttpClient.instance.get(
      '/api/blogposts/@sitehome',
      queryParameters: {
        'pageIndex': pageIndex,
        'pageSize': pageSize,
      },
      withApiAuth: true,
    );
    if (result is List) {
      for (var item in result) {
        ls.add(BlogListItemModel.fromJson(item));
      }
    }
    return ls;
  }

  /// 分页获取精华区博文列表
  /// 官方 OAuth 接口 /api/blogposts/@picked 已下线（返回空），
  /// 改用博客园网页版精华接口 /aggsite/EditorpickList（POST + JSON，无需鉴权）。
  Future<List<BlogListItemModel>> getPicked(
      {required int pageIndex, int pageSize = 20}) async {
    final html = await _fetchWebFragment(
      '/aggsite/EditorpickList',
      {'pageIndex': pageIndex, 'pageSize': pageSize},
    );
    final ls = _parsePickedFragment(html);
    // EditorpickList 只返回 标题/链接/日期，逐篇并发用详情接口补全
    // 作者、头像、阅读/评论/推荐数、简介（每篇一个请求，与原先补简介开销相同）
    await Future.wait(ls.map((item) async {
      await _enrichPickedItem(item);
    }));
    return ls;
  }

  /// 用详情接口补全精华文章的作者/头像/计数/简介（精华接口本身不带这些）
  Future<void> _enrichPickedItem(BlogListItemModel item) async {
    if (item.url.isEmpty) return;
    try {
      var data = await HttpClient.instance.get(
        '/api/blog/v2/blogposts/url/${Uri.encodeComponent(item.url)}',
        queryParameters: {'includeTags': false, 'includeCategories': false},
        withApiAuth: true,
      );
      if (data is! Map) return;
      item.author = (data['author'] ?? '').toString();
      item.avatar = (data['avatar'] ?? '').toString();
      item.blogapp = (data['blogApp'] ?? item.blogapp).toString();
      item.viewcount = (data['viewCount'] ?? 0) as int;
      item.commentcount = (data['commentCount'] ?? 0) as int;
      item.diggcount = (data['diggCount'] ?? 0) as int;
      var desc = (data['description'] ?? '').toString();
      desc = desc.replaceAll(_reTag, ' ').replaceAll(_reSpaces, ' ').trim();
      if (item.title.isNotEmpty && desc.startsWith(item.title)) {
        desc = desc.substring(item.title.length).trim();
      }
      if (desc.length > 100) desc = '${desc.substring(0, 100)}…';
      item.description = desc;
    } catch (_) {
      // 取不到就保持精华接口给的基本信息，不报错
    }
  }

  /// 分页获取「10天推荐排行」博文列表
  /// 官方 v2 接口已失效，改用网页版 /aggsite/topdiggs（固定 Top 榜单，不分页）
  Future<List<BlogListItemModel>> getMostliked(
      {required int pageIndex, int pageSize = 20}) async {
    if (pageIndex > 1) return [];
    final html = await _fetchWebPage('/aggsite/topdiggs');
    return _parseRankingArticles(html);
  }

  /// 分页获取「24小时阅读排行」博文列表
  /// 官方 v2 接口已失效，改用网页版 /aggsite/topviews（固定 Top 榜单，不分页）
  Future<List<BlogListItemModel>> getMostRead(
      {required int pageIndex, int pageSize = 20}) async {
    if (pageIndex > 1) return [];
    final html = await _fetchWebPage('/aggsite/topviews');
    return _parseRankingArticles(html);
  }

  /// POST 抓取博客园网页版聚合接口，返回 HTML 片段字符串
  Future<String> _fetchWebFragment(
      String path, Map<String, dynamic> body) async {
    var result = await HttpClient.instance.post(
      path,
      baseUrl: 'https://www.cnblogs.com',
      data: body,
      responseType: ResponseType.plain,
      withApiAuth: false,
    );
    return result is String ? result : '';
  }

  /// GET 抓取博客园网页版整页（排行榜页），返回 HTML 字符串
  Future<String> _fetchWebPage(String path) async {
    var result = await HttpClient.instance.get(
      path,
      baseUrl: 'https://www.cnblogs.com',
      responseType: ResponseType.plain,
      withApiAuth: false,
    );
    return result is String ? result : '';
  }

  /// 解析「精华」HTML 片段（仅含 标题/链接/日期）
  List<BlogListItemModel> _parsePickedFragment(String html) {
    List<BlogListItemModel> ls = [];
    for (final m in _rePickedItem.allMatches(html)) {
      final blk = m.group(1) ?? '';
      final t = _reTitle.firstMatch(blk);
      if (t == null) continue;
      final url = t.group(1)!.trim();
      ls.add(BlogListItemModel(
        id: int.tryParse(_reIdFromUrl.firstMatch(url)?.group(1) ?? '') ?? 0,
        title: _unescapeHtml(_stripTags(t.group(2) ?? '')),
        url: url,
        description: '',
        author: '',
        blogapp: _reBlogapp.firstMatch(url)?.group(1) ?? '',
        avatar: '',
        postdate: _rePickedDate.firstMatch(blk)?.group(1)?.trim() ?? '',
        viewcount: 0,
        commentcount: 0,
        diggcount: 0,
      ));
    }
    return ls;
  }

  /// 解析排行榜（阅读/推荐）HTML 中的文章卡片（字段齐全）
  List<BlogListItemModel> _parseRankingArticles(String html) {
    List<BlogListItemModel> ls = [];
    for (final m in _reRankItem.allMatches(html)) {
      final pid = int.tryParse(m.group(1) ?? '') ?? 0;
      final blk = m.group(2) ?? '';
      final t = _reTitle.firstMatch(blk);
      if (t == null) continue;
      final url = t.group(1)!.trim();

      String description = '';
      final sm = _reSummary.firstMatch(blk);
      if (sm != null) {
        final s = (sm.group(1) ?? '').replaceAll(_reSummaryAnchor, '');
        description = _unescapeHtml(_stripTags(s));
      }

      int metaCount(String label) =>
          int.tryParse(_reMeta[label]!.firstMatch(blk)?.group(1) ?? '') ?? 0;

      ls.add(BlogListItemModel(
        id: pid,
        title: _unescapeHtml(_stripTags(t.group(2) ?? '')),
        url: url,
        description: description,
        author: _reAuthor.firstMatch(blk)?.group(1)?.trim() ?? '',
        blogapp: _reBlogapp.firstMatch(url)?.group(1) ?? '',
        avatar: _reAvatar.firstMatch(blk)?.group(1) ?? '',
        postdate: _reRankDate.firstMatch(blk)?.group(1)?.trim() ?? '',
        viewcount: metaCount('阅读'),
        commentcount: metaCount('评论'),
        diggcount: metaCount('推荐'),
      ));
    }
    return ls;
  }

  String _stripTags(String s) => s.replaceAll(_reTag, '').trim();

  /// 解码常见 HTML 实体，含十进制/十六进制数字实体
  String _unescapeHtml(String s) {
    var r = s
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&nbsp;', ' ');
    r = r.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1)!);
      return (code != null && code >= 0 && code <= 0x10FFFF)
          ? String.fromCharCode(code)
          : m.group(0)!;
    });
    r = r.replaceAllMapped(RegExp(r'&#[xX]([0-9a-fA-F]+);'), (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      return (code != null && code >= 0 && code <= 0x10FFFF)
          ? String.fromCharCode(code)
          : m.group(0)!;
    });
    // &amp; 最后解码，避免把 &amp;lt; 之类二次解码
    return r.replaceAll('&amp;', '&').trim();
  }

  /// 「15天热门博文」列表
  /// 网页版 /aggsite/popular（固定 Top 榜单，不分页）
  Future<List<BlogListItemModel>> getMostPopular(
      {required int pageIndex, int pageSize = 20}) async {
    if (pageIndex > 1) return [];
    final html = await _fetchWebPage('/aggsite/popular');
    return _parseRankingArticles(html);
  }

  /// 获取全站分类（分组结构）
  /// 网页版 /aggsite/allsitecategories
  Future<List<BlogCategoryGroup>> getCategories() async {
    final html = await _fetchWebPage('/aggsite/allsitecategories');
    List<BlogCategoryGroup> groups = [];
    final reGroup = RegExp(
        r'<li>\s*<a href="([^"]+)">([^<]+)</a>\s*(?:<ul>(.*?)</ul>)?\s*</li>',
        dotAll: true);
    final reChild = RegExp(r'<li><a href="([^"]+)">([^<]+)</a></li>');
    for (final g in reGroup.allMatches(html)) {
      final children = <BlogCategoryItem>[];
      for (final c in reChild.allMatches(g.group(3) ?? '')) {
        children.add(BlogCategoryItem(
          name: _unescapeHtml(c.group(2) ?? ''),
          path: c.group(1)!.trim(),
        ));
      }
      groups.add(BlogCategoryGroup(
        name: _unescapeHtml(g.group(2) ?? ''),
        path: g.group(1)!.trim(),
        children: children,
      ));
    }
    return groups;
  }

  /// 获取某个分类下的文章列表
  /// 网页版 /cate/{path}，翻页为路径式 /cate/{slug}/{page}
  Future<List<BlogListItemModel>> getCategoryPosts(
      {required String path, required int pageIndex, int pageSize = 20}) async {
    var p = path.startsWith('/') ? path : '/$path';
    // 第 2 页起在路径后追加页码：/cate/java/ -> /cate/java/2
    if (pageIndex > 1) {
      if (!p.endsWith('/')) p = '$p/';
      p = '$p$pageIndex';
    }
    final html = await _fetchWebPage(p);
    return _parseRankingArticles(html);
  }

  /// 分页获取知识库文章列表
  /// - https://api.cnblogs.com/api/KbArticles?pageIndex={pageIndex}&pageSize={pageSize}
  Future<List<KnowledgeListItemModel>> getKbArticles(
      {required int pageIndex, int pageSize = 20}) async {
    List<KnowledgeListItemModel> ls = [];
    var result = await HttpClient.instance.get(
      '/api/KbArticles',
      queryParameters: {
        'pageIndex': pageIndex,
        'pageSize': pageSize,
      },
      withApiAuth: true,
    );
    if (result is List) {
      for (var item in result) {
        ls.add(KnowledgeListItemModel.fromJson(item));
      }
    }
    return ls;
  }

  /// 获取博文内容
  /// - https://api.cnblogs.com/api/blog/v2/blogposts/url/{url}
  Future<BlogContentModel?> getBlogContent({required String url}) async {
    try {
      var result = await HttpClient.instance.get(
        '/api/blog/v2/blogposts/url/${Uri.encodeComponent(url)}',
        queryParameters: {
          'includeTags': true,
          'includeCategories': true,
        },
        withApiAuth: true,
      );

      return BlogContentModel.fromJson(result);
    } catch (e) {
      return null;
    }
  }

  /// 通过完整 URL 获取网页正文
  Future<String> getBlogContentByWeb({required String url}) async {
    var result = await HttpClient.instance.get(
      url,
      baseUrl: "",
      responseType: ResponseType.plain,
      withApiAuth: true,
    );

    return result;
  }

  /// 获取知识库内容
  /// - https://api.cnblogs.com/api/kbarticles/{id}/body
  Future<String> getKnowledgeContent({required int id}) async {
    var result = await HttpClient.instance.get(
      '/api/kbarticles/$id/body',
      queryParameters: {},
      withApiAuth: true,
      responseType: ResponseType.plain,
    );
    var jsonContent = json.decode('{"content":$result}');
    return jsonContent["content"];
  }

  /// 获取个人博客随笔列表
  /// - https://api.cnblogs.com/api/blogs/{blogApp}/posts?pageIndex={pageIndex}
  Future<List<BlogListItemModel>> getUserBlogs(
      {required String blogApp,
      required int pageIndex,
      int pageSize = 20}) async {
    List<BlogListItemModel> ls = [];
    var result = await HttpClient.instance.get(
      '/api/blogs/$blogApp/posts',
      queryParameters: {
        'pageIndex': pageIndex,
        'pageSize': pageSize,
      },
      withApiAuth: true,
    );
    if (result is List) {
      for (var item in result) {
        ls.add(BlogListItemModel.fromJson(item));
      }
    }
    return ls;
  }

  /// 获取个人博客信息
  /// - https://api.cnblogs.com/api/blogs/{blogApp}
  Future<UserBlogInfoModel> getUserBlogsInfo(String blogApp) async {
    var result = await HttpClient.instance.get(
      '/api/blogs/$blogApp',
      withApiAuth: true,
    );
    return UserBlogInfoModel.fromJson(result);
  }

  /// 获取博文的评论列表
  /// -https://api.cnblogs.com/api/blogs/{blogApp}/posts/{postId}/comments?pageIndex={pageIndex}&pageSize={pageSize}
  Future<List<BlogCommentItemModel>> getBlogComment({
    required String blogApp,
    required int postId,
    required int pageIndex,
    int pageSize = 20,
  }) async {
    List<BlogCommentItemModel> ls = [];
    var result = await HttpClient.instance.get(
      '/api/blogs/$blogApp/posts/$postId/comments',
      queryParameters: {
        'pageIndex': pageIndex,
        'pageSize': pageSize,
      },
      withApiAuth: true,
    );
    if (result is List) {
      for (var item in result) {
        ls.add(BlogCommentItemModel.fromJson(item));
      }
    }
    return ls;
  }

  /// 添加博文评论
  /// -https://api.cnblogs.com/api/blogs/{blogApp}/posts/{postId}/comments
  Future<bool> postBlogComment({
    required String blogApp,
    required int postId,
    required String body,
  }) async {
    //TODO 403
    await HttpClient.instance.post(
      '/api/blogs/$blogApp/posts/$postId/comments',
      data: {"body": body},
      withUserAuth: true,
    );

    return true;
  }
}
