import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../camera/presentation/screens/camera_screen.dart';
import '../../../gallery/presentation/screens/gallery_picker_screen.dart';
import '../../../upload/presentation/bloc/upload_bloc.dart';
import '../../../upload/presentation/bloc/upload_state.dart';
import '../../../upload/presentation/screens/upload_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated && state.infoMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.infoMessage!),
                backgroundColor: AppTheme.primaryColor,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    state.message ?? 'Loading profile...',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
          }

          if (state is! AuthAuthenticated) {
            return const Center(child: Text('Session not active.'));
          }

          final user = state.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Profile Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                              child: Text(
                                (user.name ?? user.username).isNotEmpty
                                    ? (user.name ?? user.username)[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name ?? user.username,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.email ?? 'No email provided',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Text(
                                      'Role: ${user.role ?? 'user'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Claims details
                        if (user.claims.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Divider(),
                          Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                'JWT Claims (${user.claims.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              children: user.claims.map((claim) {
                                final shortType = claim.type.contains('/')
                                    ? claim.type.split('/').last
                                    : claim.type;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$shortType: ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          claim.value,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main Navigation Modules Header
                Text(
                  'Media Modules',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Module 1: Camera
                _buildActionCard(
                  context,
                  title: 'Device Camera',
                  subtitle: 'Capture photo or record video with audio',
                  icon: Icons.camera_alt_outlined,
                  color: AppTheme.primaryColor,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CameraScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Module 2: Gallery
                _buildActionCard(
                  context,
                  title: 'Media Gallery',
                  subtitle: 'Select multiple photos & videos using Android Photo Picker',
                  icon: Icons.photo_library_outlined,
                  color: AppTheme.secondaryColor,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GalleryPickerScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Module 3: Upload Manager
                BlocBuilder<UploadBloc, UploadState>(
                  builder: (context, uploadState) {
                    final badgeCount = uploadState.items.length;
                    return _buildActionCard(
                      context,
                      title: 'Upload Manager',
                      subtitle: 'Multipart upload to /api/echo, track progress & echo response',
                      icon: Icons.cloud_upload_outlined,
                      color: const Color(0xFF6C5CE7),
                      badgeText: badgeCount > 0 ? '$badgeCount item(s)' : null,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UploadScreen()),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),

                // JWT Refresh & Expiry Test Lab Card
                Card(
                  color: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.amber.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.science_outlined, color: Colors.amber.shade900),
                            const SizedBox(width: 8),
                            Text(
                              'JWT Refresh Testing Lab',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Test Acceptance Scenarios 4 & 5 against https://api.testingapis.com',
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 42),
                          ),
                          onPressed: () {
                            context.read<AuthBloc>().add(const AuthTestTokenExpiryRequested());
                          },
                          icon: const Icon(Icons.autorenew, size: 18),
                          label: const Text('Test Token Expiry & Auto-Refresh (Scenario 4)'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber.shade900,
                            side: BorderSide(color: Colors.amber.shade800),
                            minimumSize: const Size(double.infinity, 42),
                          ),
                          onPressed: () {
                            context.read<AuthBloc>().add(const AuthTestRefreshFailureRequested());
                          },
                          icon: const Icon(Icons.no_accounts_outlined, size: 18),
                          label: const Text('Test Refresh Failure -> Auto Logout (Scenario 5)'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out and clear stored tokens?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              minimumSize: const Size(90, 36),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
