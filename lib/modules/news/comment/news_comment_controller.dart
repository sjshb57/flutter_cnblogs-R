import 'package:flutter/material.dart';
import 'package:flutter_cnblogs/app/app_error.dart';
import 'package:flutter_cnblogs/app/controller/base_controller.dart';
import 'package:flutter_cnblogs/generated/locales.g.dart';
import 'package:flutter_cnblogs/models/news/news_comment_item_model.dart';
import 'package:flutter_cnblogs/requests/news_request.dart';
import 'package:flutter_cnblogs/services/user_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class NewsCommentController extends BasePageController<NewsCommentItemModel> {
  final int newsId;
  NewsCommentController({
    required this.newsId,
  });
  final NewsRequest newsRequest = NewsRequest();

  @override
  Future<List<NewsCommentItemModel>> getData(int page, int pageSize) async {
    return await newsRequest.getNewsComment(
      pageIndex: page,
      pageSize: pageSize,
      newsId: newsId,
    );
  }

  @override
  void handleError(Object exception, {bool showPageError = false}) {
    super.handleError(AppError("博客园API只支持显示2022以后的评论"),
        showPageError: showPageError);
  }

  void showAddCommentDialog() async {
    if (!UserService.instance.logined.value &&
        !await UserService.instance.login()) {
      return;
    }
    TextEditingController controller = TextEditingController();
    var result = await Get.dialog(
      AlertDialog(
        title: Text(LocaleKeys.add_comment_title.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              minLines: 3,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: LocaleKeys.add_comment_tip.tr,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(result: false);
            },
            child: Text(LocaleKeys.dialog_cancel.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back(result: true);
            },
            child: Text(LocaleKeys.dialog_confirm.tr),
          ),
        ],
      ),
    );
    if (!(result ?? false)) {
      return;
    }
    if (controller.text.isEmpty) {
      return;
    }
    sendComment(controller.text);
  }

  void sendComment(String text) async {
    try {
      SmartDialog.showLoading(msg: '');
      await newsRequest.postNewsComment(
        body: text,
        newsId: newsId,
      );
      refreshData();
    } catch (e) {
      SmartDialog.showToast(e.toString());
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }
}
