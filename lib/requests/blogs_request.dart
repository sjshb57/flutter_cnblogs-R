import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_cnblogs/models/blogs/blog_comment_item_model.dart';
import 'package:flutter_cnblogs/models/blogs/blog_content_model.dart';
import 'package:flutter_cnblogs/models/blogs/blog_list_item_model.dart';
import 'package:flutter_cnblogs/models/blogs/knowledge_list_item_model.dart';
import 'package:flutter_cnblogs/models/blogs/user_blog_info_model.dart';
import 'package:flutter_cnblogs/requests/base/http_client.dart';

class BlogsRequest {
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
    for (var item in result) {
      ls.add(BlogListItemModel.fromJson(item));
    }
    return ls;
  }

  /// 分页获取精华区博文列表
  /// - https://api.cnblogs.com/api/blogposts/@picked?pageIndex={pageIndex}&pageSize={pageSize}
  Future<List<BlogListItemModel>> getPicked(
      {required int pageIndex, int pageSize = 20}) async {
    // 官方 OAuth 接口 /api/blogposts/@picked 已下线（返回空），
    // 改用博客园网页版精华接口 /aggsite/EditorpickList（POST + JSON，无需鉴权）。
    final html = await _fetchWebFragment(
      '/aggsite/EditorpickList',
      {'pageIndex': pageIndex, 'pageSize': pageSize},
    );
    final ls = _parsePickedFragment(html);
    // EditorpickList 不返回简介，逐篇并发取正文开头补上（每篇一个请求）
    await Future.wait(ls.map((item) async {
      item.description = await _fetchPostSummary(item.id, item.title);
    }));
    return ls;
  }

  /// 取单篇文章正文开头作为简介（精华接口不带简介，用此补全）
  Future<String> _fetchPostSummary(int id, String title) async {
    if (id <= 0) return '';
    try {
      var body = await HttpClient.instance.get(
        '/api/blogposts/$id/body',
        withApiAuth: true,
      );
      if (body is! String) return '';
      var text = body.replaceAll(RegExp(r'<[^>]+>'), ' ');
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (title.isNotEmpty && text.startsWith(title)) {
        text = text.substring(title.length).trim();
      }
      if (text.length > 100) text = '${text.substring(0, 100)}…';
      return text;
    } catch (_) {
      return '';
    }
  }

  /// 抓取博客园网页版聚合接口，返回 HTML 片段字符串
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
    final items = RegExp(
            r'<article class="post-item editorpick-item">(.*?)</article>',
            dotAll: true)
        .allMatches(html);
    for (final m in items) {
      final blk = m.group(1) ?? '';
      final t = RegExp(r'class="post-item-title"\s+href="([^"]+)"[^>]*>(.*?)</a>',
              dotAll: true)
          .firstMatch(blk);
      if (t == null) continue;
      final url = t.group(1)!.trim();
      final title = _unescapeHtml(_stripTags(t.group(2) ?? ''));
      final date = RegExp(r'class="editorpick-item-meta">([^<]+)</span>')
              .firstMatch(blk)
              ?.group(1)
              ?.trim() ??
          '';
      ls.add(BlogListItemModel(
        id: int.tryParse(
                RegExp(r'/p/(\d+)').firstMatch(url)?.group(1) ?? '') ??
            0,
        title: title,
        url: url,
        description: '',
        author: '',
        blogapp: RegExp(r'cnblogs\.com/([^/]+)/p/').firstMatch(url)?.group(1) ??
            '',
        avatar: '',
        postdate: date,
        viewcount: 0,
        commentcount: 0,
        diggcount: 0,
      ));
    }
    return ls;
  }

  /// 解析「48小时阅读排行」HTML 片段（字段齐全）
  List<BlogListItemModel> _parseTopViewsFragment(String html) {
    List<BlogListItemModel> ls = [];
    final arts = RegExp(
            r'<article class="post-item" data-post-id="(\d+)">(.*?)</article>',
            dotAll: true)
        .allMatches(html);
    for (final m in arts) {
      final pid = int.tryParse(m.group(1) ?? '') ?? 0;
      final blk = m.group(2) ?? '';
      final t = RegExp(r'class="post-item-title"\s+href="([^"]+)"[^>]*>(.*?)</a>',
              dotAll: true)
          .firstMatch(blk);
      if (t == null) continue;
      final url = t.group(1)!.trim();
      final title = _unescapeHtml(_stripTags(t.group(2) ?? ''));
      final avatar = RegExp(r'<img src="([^"]+)"\s+class="avatar"')
              .firstMatch(blk)
              ?.group(1) ??
          '';
      final author = RegExp(
                  r'class="post-item-author"[^>]*>\s*<span>([^<]+)</span>')
              .firstMatch(blk)
              ?.group(1)
              ?.trim() ??
          '';
      String description = '';
      final sm = RegExp(r'<p class="post-item-summary">(.*?)</p>', dotAll: true)
          .firstMatch(blk);
      if (sm != null) {
        var s = sm.group(1) ?? '';
        s = s.replaceAll(RegExp(r'<a\b.*?</a>', dotAll: true), '');
        description = _unescapeHtml(_stripTags(s));
      }
      final date = RegExp(r'class="post-meta-item">\s*<span>([\d\-: ]+)</span>')
              .firstMatch(blk)
              ?.group(1)
              ?.trim() ??
          '';
      int metaCount(String label) =>
          int.tryParse(RegExp('title="$label (\\d+)"').firstMatch(blk)?.group(1) ??
              '') ??
          0;
      ls.add(BlogListItemModel(
        id: pid,
        title: title,
        url: url,
        description: description,
        author: author,
        blogapp: RegExp(r'cnblogs\.com/([^/]+)/p/').firstMatch(url)?.group(1) ??
            '',
        avatar: avatar,
        postdate: date,
        viewcount: metaCount('阅读'),
        commentcount: metaCount('评论'),
        diggcount: metaCount('推荐'),
      ));
    }
    return ls;
  }

  String _stripTags(String s) => s.replaceAll(RegExp(r'<[^>]+>'), '').trim();

  String _unescapeHtml(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&nbsp;', ' ')
      .trim();

  /// 分页获取10天推荐博文列表
  /// - https://api.cnblogs.com/api/blog/v2/blogposts/aggsites/mostliked?pageIndex=1&pageSize=10
  Future<List<BlogListItemModel>> getMostliked(
      {required int pageIndex, int pageSize = 20}) async {
    // 10 天推荐排行：网页版 /aggsite/topdiggs，固定 Top 榜单，不分页
    if (pageIndex > 1) return [];
    final html = await _fetchWebPage('/aggsite/topdiggs');
    return _parseTopViewsFragment(html);
  }

  /// 分页获取48小时阅读排行博文列表
  /// - https://api.cnblogs.com/api/blog/v2/blogposts/aggsites/mostread?pageIndex=1&pageSize=10
  Future<List<BlogListItemModel>> getMostRead(
      {required int pageIndex, int pageSize = 20}) async {
    // 24 小时阅读排行：网页版 /aggsite/topviews，固定 Top 榜单，不分页
    if (pageIndex > 1) return [];
    final html = await _fetchWebPage('/aggsite/topviews');
    return _parseTopViewsFragment(html);
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
    for (var item in result) {
      ls.add(KnowledgeListItemModel.fromJson(item));
    }
    return ls;
  }

  /// 获取博文内容
  /// - https://api.cnblogs.com/api/blogposts/{id}/body
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

  /// 获取博文内容
  /// - https://api.cnblogs.com/api/blogposts/{id}/body
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
    for (var item in result) {
      ls.add(BlogListItemModel.fromJson(item));
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
    for (var item in result) {
      ls.add(BlogCommentItemModel.fromJson(item));
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
