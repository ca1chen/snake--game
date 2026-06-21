import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

/// 主页 — BottomNavigationBar 三 Tab 容器
class HomePage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomePage({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view),
            label: '课程表',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: '待办',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget? _buildFAB(BuildContext context) {
    switch (navigationShell.currentIndex) {
      case 0: // 课程表 Tab
        return FloatingActionButton(
          heroTag: 'add_course',
          onPressed: () => AppRouter.goCourseAdd(context),
          tooltip: '添加课程',
          child: const Icon(Icons.add),
        );
      case 1: // 待办 Tab
        return FloatingActionButton(
          heroTag: 'add_todo',
          onPressed: () => AppRouter.goTodoAdd(context),
          tooltip: '添加待办',
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }
}
