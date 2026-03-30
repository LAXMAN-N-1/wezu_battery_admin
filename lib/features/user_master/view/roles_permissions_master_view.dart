import 'package:flutter/material.dart';
import '../../../../core/widgets/admin_ui_components.dart';
import 'tabs/roles_list_tab.dart';
import 'tabs/role_form_tab.dart';
import 'tabs/permission_matrix_tab.dart';

class RolesPermissionsMasterView extends StatefulWidget {
  const RolesPermissionsMasterView({super.key});

  @override
  State<RolesPermissionsMasterView> createState() => _RolesPermissionsMasterViewState();
}

class _RolesPermissionsMasterViewState extends State<RolesPermissionsMasterView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchToTab(int index) {
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: PageHeader(
              title: 'Roles & Permissions',
              subtitle: 'Manage system roles, create custom access levels, and visually configure the permission matrix.',
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(iconMargin: EdgeInsets.only(right: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.list_alt, size: 18), SizedBox(width: 8), Text('All Roles')])),
                  Tab(iconMargin: EdgeInsets.only(right: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_moderator, size: 18), SizedBox(width: 8), Text('Create Custom Role')])),
                  Tab(iconMargin: EdgeInsets.only(right: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.grid_on, size: 18), SizedBox(width: 8), Text('Permission Matrix')])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RolesListTab(onEditRole: () => _switchToTab(1)),
                RoleFormTab(onCancel: () => _switchToTab(0)),
                const PermissionMatrixTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
