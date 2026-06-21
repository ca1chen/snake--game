import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/schedule/week_schedule_page.dart';
import '../pages/schedule/day_schedule_page.dart';
import '../pages/course/course_list_page.dart';
import '../pages/course/course_edit_page.dart';
import '../pages/course/course_detail_page.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';
import '../pages/todo/todo_list_page.dart';
import '../pages/todo/todo_edit_page.dart';
import '../pages/todo/todo_detail_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/settings/semester_manage_page.dart';

/// 全局导航 Key（用于 NotificationService 回调、跨 async 操作的 dialog 等场景）
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// 路由路径常量
class AppRoutes {
  static const home = '/';
  static const schedule = '/schedule';
  static const scheduleDay = '/schedule/day';
  static const courseList = '/courses';
  static const courseAdd = '/courses/add';
  static const courseDetail = '/courses/detail';
  static const courseEdit = '/courses/edit';
  static const todoList = '/todos';
  static const todoAdd = '/todos/add';
  static const todoDetail = '/todos/detail';
  static const todoEdit = '/todos/edit';
  static const settings = '/settings';
  static const semesters = '/settings/semesters';
}

/// GoRouter 配置
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.schedule,
  redirect: (context, state) {
    if (state.uri.path == AppRoutes.home) {
      return AppRoutes.schedule;
    }
    return null;
  },
  routes: [
    // ShellRoute 包裹主页（底部三 Tab）
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomePage(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: 课程表
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.schedule,
              builder: (context, state) => const WeekSchedulePage(),
              routes: [
                GoRoute(
                  path: 'day',
                  builder: (context, state) {
                    final day = int.tryParse(state.uri.queryParameters['day'] ?? '');
                    return DaySchedulePage(dayOfWeek: day);
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 1: 待办
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.todoList,
              builder: (context, state) => const TodoListPage(),
            ),
          ],
        ),

        // Tab 2: 设置
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),

    // 全局路由（不受 Tab 约束，全屏 push）
    GoRoute(
      path: AppRoutes.courseList,
      builder: (context, state) => const CourseListPage(),
    ),
    GoRoute(
      path: AppRoutes.courseAdd,
      builder: (context, state) => const CourseEditPage(),
    ),
    GoRoute(
      path: '${AppRoutes.courseDetail}/:courseId',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['courseId'] ?? '');
        if (id == null) {
          return const Scaffold(body: Center(child: Text('缺少课程ID')));
        }
        return CourseDetailPage(courseId: id);
      },
    ),
    GoRoute(
      path: '${AppRoutes.courseEdit}/:courseId',
      builder: (context, state) {
        final courseId = int.tryParse(state.pathParameters['courseId'] ?? '');
        if (courseId == null) {
          return const Scaffold(body: Center(child: Text('缺少课程ID')));
        }
        final repo = CourseRepository();
        return FutureBuilder<Course?>(
          future: repo.getById(courseId),
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return CourseEditPage(course: snap.data);
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.todoAdd,
      builder: (context, state) {
        final courseId = int.tryParse(state.uri.queryParameters['courseId'] ?? '');
        return TodoEditPage(courseId: courseId);
      },
    ),
    GoRoute(
      path: '${AppRoutes.todoDetail}/:todoId',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['todoId'] ?? '');
        if (id == null) {
          return const Scaffold(body: Center(child: Text('缺少待办ID')));
        }
        return TodoDetailPage(todoId: id);
      },
    ),
    GoRoute(
      path: '${AppRoutes.todoEdit}/:todoId',
      builder: (context, state) {
        // 需要从 state.extra 传入 todo，简化为重新加载
        return const TodoEditPage();
      },
    ),
    GoRoute(
      path: AppRoutes.semesters,
      builder: (context, state) => const SemesterManagePage(),
    ),
  ],
);

/// 便捷导航方法（用于页面间跳转）
class AppRouter {
  // 课程表相关
  static void goScheduleDay(BuildContext context, {int? dayOfWeek}) {
    final uri = dayOfWeek != null ? '${AppRoutes.scheduleDay}?day=$dayOfWeek' : AppRoutes.scheduleDay;
    context.push(uri);
  }
  // 课程相关
  static void goCourseList(BuildContext context) => context.push(AppRoutes.courseList);
  static void goCourseAdd(BuildContext context) => context.push(AppRoutes.courseAdd);
  static void goCourseDetail(BuildContext context, int id) => context.push('${AppRoutes.courseDetail}/$id');
  static void goCourseEdit(BuildContext context, int id) => context.push('${AppRoutes.courseEdit}/$id');

  // 待办相关
  static void goTodoAdd(BuildContext context, {int? courseId}) {
    final uri = courseId != null ? '${AppRoutes.todoAdd}?courseId=$courseId' : AppRoutes.todoAdd;
    context.push(uri);
  }
  static void goTodoDetail(BuildContext context, int id) => context.push('${AppRoutes.todoDetail}/$id');
  static void goTodoEdit(BuildContext context, int id) => context.push('${AppRoutes.todoEdit}/$id');

  // 设置相关
  static void goSemesters(BuildContext context) => context.push(AppRoutes.semesters);
}
