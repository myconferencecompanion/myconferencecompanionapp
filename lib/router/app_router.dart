import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/features/admin/admin_screens.dart';
import 'package:nse_mobile/features/admin/admin_crud_screen.dart';
import 'package:nse_mobile/features/auth/auth_screen.dart';
import 'package:nse_mobile/features/chatbot/chatbot_screen.dart';
import 'package:nse_mobile/features/concierge/concierge_hub_screen.dart';
import 'package:nse_mobile/features/concierge/concierge_screens.dart';
import 'package:nse_mobile/features/home/home_screen.dart' show HomeScreen;
import 'package:nse_mobile/features/info/info_screens.dart';
import 'package:nse_mobile/features/location/hotel_detail_screen.dart';
import 'package:nse_mobile/features/location/location_screens.dart';
import 'package:nse_mobile/features/location/maidguide_screen.dart';
import 'package:nse_mobile/features/map/map_screen.dart';
import 'package:nse_mobile/features/more/more_screen.dart';
import 'package:nse_mobile/features/network/network_screens.dart';
import 'package:nse_mobile/features/program/program_screens.dart';
import 'package:nse_mobile/features/shell/main_shell.dart';
import 'package:nse_mobile/features/search/global_search_screen.dart';
import 'package:nse_mobile/features/transport/transport_screens.dart';
import 'package:nse_mobile/features/waitlist/waitlist_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(WidgetRef ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.loading) return null;
      final onAuth = state.matchedLocation == '/auth';
      if (!auth.isLoggedIn && !onAuth) return '/auth';
      if (auth.isLoggedIn && onAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/waitlist', pageBuilder: (context, state) => const NoTransitionPage(child: WaitlistScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/more', pageBuilder: (context, state) => const NoTransitionPage(child: MoreScreen())),
          ]),
        ],
      ),
      GoRoute(path: '/search', builder: (_, s) => GlobalSearchScreen(initialQuery: s.uri.queryParameters['q'])),
      GoRoute(path: '/schedule', builder: (context, state) => const ScheduleScreen()),
      GoRoute(path: '/schedule/:id', builder: (_, s) => SessionDetailScreen(sessionId: s.pathParameters['id']!)),
      GoRoute(path: '/agenda', builder: (context, state) => const MyAgendaScreen()),
      GoRoute(path: '/speakers', builder: (context, state) => const SpeakersListScreen()),
      GoRoute(path: '/speakers/:id', builder: (_, s) => SpeakerDetailScreen(speakerId: s.pathParameters['id']!)),
      GoRoute(path: '/accommodation', builder: (context, state) => const AccommodationScreen()),
      GoRoute(
        path: '/accommodation/:id',
        builder: (_, s) => HotelDetailScreen(hotelId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/maidguide', builder: (context, state) => const MaidguideScreen()),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(path: '/directions', builder: (context, state) => const DirectionsScreen()),
      GoRoute(path: '/nearby', builder: (context, state) => const NearbyScreen()),
      GoRoute(path: '/map', builder: (_, s) => MapScreen(room: s.uri.queryParameters['room'])),
      GoRoute(path: '/announcements', builder: (context, state) => const AnnouncementsScreen()),
      GoRoute(path: '/emergency', builder: (context, state) => const EmergencyScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/network', builder: (context, state) => const NetworkScreen()),
      GoRoute(path: '/network/room/:id', builder: (_, s) => RoomChatScreen(roomId: s.pathParameters['id']!)),
      GoRoute(path: '/network/user/:id', builder: (_, s) => DmScreen(userId: s.pathParameters['id']!)),
      GoRoute(path: '/transport', builder: (context, state) => const MyTransportScreen()),
      GoRoute(path: '/transport/admin', builder: (context, state) => const TransportAdminScreen()),
      GoRoute(path: '/concierge', builder: (context, state) => const ConciergeHubScreen()),
      GoRoute(path: '/concierge/usher', builder: (context, state) => const UsherScreen()),
      GoRoute(path: '/concierge/food', builder: (context, state) => const FoodScreen()),
      GoRoute(path: '/concierge/errands', builder: (context, state) => const ErrandsScreen()),
      GoRoute(path: '/concierge/orders', builder: (context, state) => const OrdersScreen()),
      GoRoute(path: '/chatbot', builder: (context, state) => const ChatbotScreen()),
      GoRoute(
        path: '/faq',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatbotScreen(
            initialQuestion: extra?['question'] as String?,
            initialAnswer: extra?['answer'] as String?,
          );
        },
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminHomeScreen()),
      GoRoute(
        path: '/admin/sessions',
        builder: (context, state) => const AdminCrudScreen(
          title: 'Sessions',
          itemNoun: 'session',
          table: 'sessions',
          roles: ['program'],
          titleKey: 'title',
          subtitleKeys: ['track', 'room'],
          badgeKey: 'track',
          orderColumn: 'starts_at',
          orderAscending: true,
          fields: [
            CrudField(key: 'title', label: 'Title', required: true),
            CrudField(key: 'description', label: 'Description', type: CrudFieldType.multiline),
            CrudField(key: 'day', label: 'Day (1-5)', type: CrudFieldType.number, required: true, defaultValue: 1),
            CrudField(key: 'track', label: 'Track', type: CrudFieldType.select, options: [
              CrudOption('Plenary', 'Plenary'),
              CrudOption('Technical', 'Technical'),
              CrudOption('Professional', 'Professional'),
              CrudOption('Social', 'Social'),
            ]),
            CrudField(key: 'room', label: 'Room', hint: 'e.g. Grand Hall'),
            CrudField(key: 'starts_at', label: 'Starts at', type: CrudFieldType.datetime),
            CrudField(key: 'ends_at', label: 'Ends at', type: CrudFieldType.datetime),
          ],
        ),
      ),
      GoRoute(
        path: '/admin/speakers',
        builder: (context, state) => const AdminCrudScreen(
          title: 'Speakers',
          itemNoun: 'speaker',
          table: 'speakers',
          roles: ['program'],
          titleKey: 'name',
          subtitleKeys: ['title', 'company'],
          fields: [
            CrudField(key: 'name', label: 'Full name', required: true),
            CrudField(key: 'title', label: 'Role / title'),
            CrudField(key: 'company', label: 'Organisation'),
            CrudField(key: 'bio', label: 'Bio', type: CrudFieldType.multiline),
            CrudField(key: 'avatar_url', label: 'Photo URL'),
            CrudField(key: 'is_keynote', label: 'Keynote speaker', type: CrudFieldType.boolean),
          ],
        ),
      ),
      GoRoute(
        path: '/admin/accommodations',
        builder: (context, state) => const AdminCrudScreen(
          title: 'Hotels',
          itemNoun: 'hotel',
          table: 'accommodations',
          roles: ['logistics'],
          titleKey: 'name',
          subtitleKeys: ['address', 'price_range'],
          fields: [
            CrudField(key: 'name', label: 'Hotel name', required: true),
            CrudField(key: 'address', label: 'Address'),
            CrudField(key: 'distance_km', label: 'Distance from ICC (km)', type: CrudFieldType.number),
            CrudField(key: 'price_range', label: 'Price range'),
            CrudField(key: 'booking_url', label: 'Booking URL'),
          ],
        ),
      ),
      GoRoute(
        path: '/admin/emergency',
        builder: (context, state) => const AdminCrudScreen(
          title: 'Emergency contacts',
          itemNoun: 'contact',
          table: 'emergency_contacts',
          roles: ['logistics'],
          titleKey: 'label',
          subtitleKeys: ['phone', 'description'],
          badgeKey: 'category',
          orderColumn: 'sort_order',
          orderAscending: true,
          fields: [
            CrudField(key: 'label', label: 'Label', required: true),
            CrudField(key: 'phone', label: 'Phone number', required: true, hint: '+234...'),
            CrudField(key: 'description', label: 'Description'),
            CrudField(key: 'category', label: 'Category', type: CrudFieldType.select, defaultValue: 'emergency', options: [
              CrudOption('emergency', 'Emergency'),
              CrudOption('medical', 'Medical'),
              CrudOption('security', 'Security'),
            ]),
            CrudField(key: 'sort_order', label: 'Sort order', type: CrudFieldType.number, defaultValue: 0),
          ],
        ),
      ),
      GoRoute(
        path: '/admin/announcements',
        builder: (context, state) => const AdminCrudScreen(
          title: 'Announcements',
          itemNoun: 'announcement',
          table: 'announcements',
          roles: ['comms'],
          titleKey: 'title',
          subtitleKeys: ['body'],
          badgeKey: 'priority',
          fields: [
            CrudField(key: 'title', label: 'Title', required: true),
            CrudField(key: 'body', label: 'Message', type: CrudFieldType.multiline, required: true),
            CrudField(key: 'priority', label: 'Priority', type: CrudFieldType.select, defaultValue: 'normal', options: [
              CrudOption('normal', 'Normal'),
              CrudOption('high', 'High priority'),
            ]),
          ],
        ),
      ),
      GoRoute(
        path: '/admin/menu',
        builder: (context, state) => const AdminCrudScreen(
          title: 'Menu items',
          itemNoun: 'item',
          table: 'menu_items',
          roles: ['kitchen'],
          titleKey: 'name',
          subtitleKeys: ['description'],
          orderColumn: 'sort_order',
          orderAscending: true,
          fields: [
            CrudField(key: 'name', label: 'Item name', required: true),
            CrudField(key: 'description', label: 'Description', type: CrudFieldType.multiline),
            CrudField(
              key: 'category_id',
              label: 'Category',
              type: CrudFieldType.select,
              optionsTable: 'menu_categories',
              optionsLabelKey: 'name',
            ),
            CrudField(key: 'is_available', label: 'Available', type: CrudFieldType.boolean, defaultValue: true),
            CrudField(key: 'sort_order', label: 'Sort order', type: CrudFieldType.number, defaultValue: 1),
            CrudField(key: 'max_per_item', label: 'Max per order', type: CrudFieldType.number, defaultValue: 1),
          ],
        ),
      ),
      GoRoute(
        path: '/admin/delegates',
        builder: (context, state) => const AdminListScreen(
          title: 'Delegates',
          table: 'profiles',
          roles: ['super_admin'],
          labelField: 'display_name',
        ),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminQueueScreen(
          title: 'Food orders',
          table: 'food_orders',
          statusField: 'status',
          statuses: ['pending', 'preparing', 'ready', 'delivered'],
          roles: ['kitchen'],
        ),
      ),
      GoRoute(
        path: '/admin/ushers',
        builder: (context, state) => const AdminQueueScreen(
          title: 'Usher queue',
          table: 'usher_requests',
          statusField: 'status',
          statuses: ['pending', 'acknowledged', 'resolved'],
          roles: ['front_desk'],
        ),
      ),
      GoRoute(
        path: '/admin/errands',
        builder: (context, state) => const AdminQueueScreen(
          title: 'Errands',
          table: 'errand_requests',
          statusField: 'status',
          statuses: ['requested', 'accepted', 'in_progress', 'completed'],
          roles: ['front_desk'],
        ),
      ),
    ],
  );
}
