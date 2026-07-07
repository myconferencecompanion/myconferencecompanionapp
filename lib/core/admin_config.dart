import 'package:flutter/material.dart';

/// Staff sub-roles — mirrors `src/routes/_authenticated/admin/route.tsx`.
const staffSubRoles = <String>{
  'program',
  'kitchen',
  'front_desk',
  'logistics',
  'comms',
};

const roleLabels = <String, String>{
  'attendee': 'Delegate',
  'admin': 'Admin',
  'super_admin': 'Super Admin',
  'front_desk': 'Front Desk',
  'kitchen': 'Catering',
  'program': 'Program',
  'logistics': 'Logistics',
  'comms': 'Comms',
};

class AdminTool {
  const AdminTool({
    required this.label,
    required this.route,
    required this.icon,
    required this.roles,
    this.countKey,
  });

  final String label;
  final String route;
  final IconData icon;
  final List<String> roles;
  final String? countKey;
}

class AdminSection {
  const AdminSection({
    required this.title,
    required this.subtitle,
    required this.roles,
    required this.tools,
  });

  final String title;
  final String subtitle;
  final List<String> roles;
  final List<AdminTool> tools;
}

const adminSections = <AdminSection>[
  AdminSection(
    title: 'Program & speakers',
    subtitle: 'Sessions and speaker profiles',
    roles: ['program'],
    tools: [
      AdminTool(
        label: 'Sessions',
        route: '/admin/sessions',
        icon: Icons.event_rounded,
        roles: ['program'],
        countKey: 'sessions',
      ),
      AdminTool(
        label: 'Speakers',
        route: '/admin/speakers',
        icon: Icons.mic_rounded,
        roles: ['program'],
        countKey: 'speakers',
      ),
    ],
  ),
  AdminSection(
    title: 'Catering',
    subtitle: 'Menu and delegate food orders',
    roles: ['kitchen'],
    tools: [
      AdminTool(
        label: 'Menu items',
        route: '/admin/menu',
        icon: Icons.restaurant_menu_rounded,
        roles: ['kitchen'],
        countKey: 'menu',
      ),
      AdminTool(
        label: 'Open orders',
        route: '/admin/orders',
        icon: Icons.receipt_long_rounded,
        roles: ['kitchen'],
        countKey: 'openOrders',
      ),
    ],
  ),
  AdminSection(
    title: 'Front desk & security',
    subtitle: 'Usher calls and delegate errands',
    roles: ['front_desk'],
    tools: [
      AdminTool(
        label: 'Usher queue',
        route: '/admin/ushers',
        icon: Icons.support_agent_rounded,
        roles: ['front_desk'],
        countKey: 'openUshers',
      ),
      AdminTool(
        label: 'Errands queue',
        route: '/admin/errands',
        icon: Icons.local_laundry_service_rounded,
        roles: ['front_desk'],
        countKey: 'openErrands',
      ),
    ],
  ),
  AdminSection(
    title: 'Logistics',
    subtitle: 'Hotels, transport, and emergency contacts',
    roles: ['logistics'],
    tools: [
      AdminTool(
        label: 'Hotels',
        route: '/admin/accommodations',
        icon: Icons.hotel_rounded,
        roles: ['logistics'],
        countKey: 'accommodations',
      ),
      AdminTool(
        label: 'Transport',
        route: '/transport/admin',
        icon: Icons.directions_bus_rounded,
        roles: ['logistics'],
      ),
      AdminTool(
        label: 'Emergency',
        route: '/admin/emergency',
        icon: Icons.health_and_safety_rounded,
        roles: ['logistics'],
        countKey: 'emergency',
      ),
    ],
  ),
  AdminSection(
    title: 'Communications',
    subtitle: 'Conference announcements',
    roles: ['comms'],
    tools: [
      AdminTool(
        label: 'Announcements',
        route: '/admin/announcements',
        icon: Icons.campaign_rounded,
        roles: ['comms'],
        countKey: 'announcements',
      ),
    ],
  ),
  AdminSection(
    title: 'Delegates & guests',
    subtitle: 'Registered attendees',
    roles: ['super_admin'],
    tools: [
      AdminTool(
        label: 'Delegate profiles',
        route: '/admin/delegates',
        icon: Icons.groups_rounded,
        roles: ['super_admin'],
        countKey: 'attendees',
      ),
    ],
  ),
];

bool canAccessAdminConsole(List<String> roles) =>
    roles.contains('admin') ||
    roles.contains('super_admin') ||
    roles.any(staffSubRoles.contains);

List<String> staffRoleBadges(List<String> roles) {
  final badges = <String>[];
  if (roles.contains('super_admin')) badges.add(roleLabels['super_admin']!);
  for (final r in staffSubRoles) {
    if (roles.contains(r)) badges.add(roleLabels[r] ?? r);
  }
  return badges;
}
