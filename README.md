# 博客园 Flutter（R 分支版）

使用 Flutter 编写的博客园（cnblogs）客户端，支持 iOS 及 Android。

本项目 fork 自 [xiaoyaocz/flutter_cnblogs](https://github.com/xiaoyaocz/flutter_cnblogs)，在原项目基础上做了现代化适配与一系列问题修复，主要包括：

- 适配最新 Flutter 3.44 及 Android 新版构建工具链（AGP / Kotlin / Gradle / JDK 21），更新已弃用接口；
- 修复因博客园接口变更导致的「精华」「24 小时阅读排行」「10 天推荐排行」等页面失效问题；
- 界面细节打磨与若干稳定性修复。

> 基于[博客园开放 API](https://api.cnblogs.com/help) 开发；部分数据源改用博客园网页端接口获取，受限于接口能力，部分功能（如精华文章的阅读 / 评论 / 推荐数）可能并不完善。

详细改动见 [更新日志](CHANGELOG.md)。

## 安装

- Android：前往 [Releases](https://github.com/sjshb57/flutter_cnblogs-R/releases/latest) 下载 `app-release.apk` 安装即可。

## 开发

### 环境

- Flutter：3.44
- JDK：21
- Android：AGP 9.0.1 / Kotlin 2.4.0 / Gradle 9.1.0

### 说明

开发前请先[申请博客园 API KEY](https://oauth.cnblogs.com/)，在根目录创建 `.env` 文件并写入以下内容：

```
CLIENT_ID=【申请的 CLIENT_ID】
CLIENT_SECRET=【申请的 CLIENT_SECRET】
```

### 框架

- `GetX` 状态管理、路由管理、国际化
- `Dio` 网络请求
- `Hive` 数据存储

### 目录结构

- `app` 一些通用的类及样式
- `services` 提供数据存储等服务
- `requests` 请求的封装
- `generated` 生成的国际化文件，使用 `get generate locales` 生成
- `modules` 模块，每个会有两个文件，view 及 controller
- `widgets` 自定义的小组件
- `routes` 路由定义
- `models` 实体类

## 致谢

- 原项目：[xiaoyaocz/flutter_cnblogs](https://github.com/xiaoyaocz/flutter_cnblogs)

## 许可

本项目遵循原项目的开源许可，详见 [LICENSE](LICENSE)。