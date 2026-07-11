import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_typography.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _dynamicTheme = true;

  Future<void> _handleLogout() async {
    const secureStorage = SecureStorageService();
    await secureStorage.delete(SecureStorageKeys.accessToken);
    if (mounted) {
      context.go(AppRoutePaths.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: replace with real backend once auth + DB endpoints exist
    final recentTracks = [
      const _RecentTrack(
        title: 'Neon Nights',
        artist: 'The Midnight',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDViTXZLuJdHDQFI70O_0uLI3PiHt2t2B9nMAcNZLPBPoIEOMWNQYPh8X9cVkrcY1tW1wZhzCIm-RntDE6VBWPJnI2Q8rghpJdKy0fN4zyIgf8lcrLme8qTigYq1kkhw2PTuuyjafOvEbPsyPF8OF_CAGh3ewrsLgNzgQMnJ-Al_yw9muzxFcOA_VUfpOIWfV5jgeN18KHANCx_dorCdTZyA5HtlWTBMNnZYY3SkutVjS9VxUXd5CC_kxJRmYUE7xwPDj7VBaNbdLM',
      ),
      const _RecentTrack(
        title: 'Deep Space',
        artist: 'Jon Hopkins',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuA8rp2ppBzpH3rxWtlzC96PTnPzLSBJRMRoTtWeRzW_Z8jydP654B5bG7grPqPfRI5wmq78hT9g19jIqDgrpmZaEBoXc8G1EU7gx8j99WLTO0qpP2-xjuU6Cj7tqj-KleBgv1_HxjZ3GIcWDnBVVD7EnTCfhJHVRnYMwKlarQC023l9oRxg7xVk99vu0I2RfdRHcaEAQAr07B9zW7fJcPaL-XNo0kNdAUVrjRHl5cUGSBps146_yGIVFJkF2I860bH1jIKIlxlEXFc',
      ),
      const _RecentTrack(
        title: 'Velocity',
        artist: 'Kavinsky',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDUlM6DZeJzJ-fWqKcAUKlszHYJjJ4pfMmykunwI4cxi-9Zm_9h47M2EI6IJcKfKUTgQ93lM0qb0Wt8D2XO_TxfGF_hKAE7jwDZFoW9fRWKA61bhCD4L0ggC1ijJHQk2vv13sMQ25YIPB8qjs3C7yUZPFGzyrMpOwZAYE7OyiFQjMYrhNnZs0l78Uh94FHdwmJECxvZqG8dtP36-RXTyRrVKFb9CXzs08ghFpu6NRplWzp1rzEhBnTqe1ena1OcoqtfbTShriqjLos',
      ),
    ];

    final genres = ['Synthwave', 'Electro', 'Ambient', 'Lo-Fi', 'Cyberpunk'];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.darkOnSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 140.0, top: 12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow backdrop
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFF43F5E)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.3),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        // Inner Image
                        Container(
                          width: 128,
                          height: 128,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl:
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAFfSs_6hyAFfdG28rMOOCMA7HPkmKV74ZyVNQ9Di72YY6smGDsXx8ISlsBUhJMHn_SeEuhT_lfI36jycBPtXq47j7N_WayJqBAkfU0h3eyvwmLjWafOlcNuuraVVYsOxs28YtxWzxdU7yZfp5MPj5SWgENb0tKxhuTv13LOtvI_TKcCPL_WNjkghgXEXkkJ8sSZyx4UcEQDKmjJMWGqdHQZJdnHFbgqQpR8Hu8AOTgZ5B2exRSpZ0axN-fdLBp8PDd2h66WGGnCVs',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Edit badge overlay
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: const Icon(Icons.edit, color: Colors.black, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aria Vance',
                      style: AppTypography.headlineMedium.copyWith(color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Premium Member',
                      style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Stat Chips (Glassmorphic)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.timer_outlined,
                      value: '12,450',
                      label: 'Min',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.graphic_eq,
                      value: 'Synth',
                      label: 'Top Vibe',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.local_fire_department,
                      value: '14',
                      label: 'Day Streak',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Top Genres Section
              Text('Top Genres', style: AppTypography.titleMedium.copyWith(color: Colors.white)),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: genres.length,
                  itemBuilder: (context, index) {
                    final isFirst = index == 0;
                    return Container(
                      margin: const EdgeInsets.only(right: 12.0),
                      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: isFirst ? const Color(0xFF6750A4).withOpacity(0.3) : const Color(0xFF211F24),
                        borderRadius: BorderRadius.circular(19.0),
                        border: Border.all(
                          color: isFirst ? AppColors.primary.withOpacity(0.5) : const Color(0xFF494551),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          genres[index],
                          style: AppTypography.caption.copyWith(
                            color: isFirst ? AppColors.primary : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Recently Played Section
              Text('Recently Played', style: AppTypography.titleMedium.copyWith(color: Colors.white)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentTracks.length,
                  itemBuilder: (context, index) {
                    final item = recentTracks[index];
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.artist,
                            style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Quick Access Settings List
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF211F24).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(28.0),
                  border: Border.all(color: const Color(0xFF494551).withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    // Settings Item
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF36343A)),
                        child: const Icon(Icons.settings, color: Colors.white70),
                      ),
                      title: Text('Settings', style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 16)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () => context.push(AppRoutePaths.settings),
                    ),
                    const Divider(color: Color(0xFF494551), height: 1),

                    // Piped Streamer Item
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF36343A)),
                        child: const Icon(Icons.music_video, color: Colors.purpleAccent),
                      ),
                      title: Text('Piped Music Streamer', style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 16)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () => context.push(AppRoutePaths.pipedPlayer),
                    ),
                    const Divider(color: Color(0xFF494551), height: 1),

                    // Dynamic Theme Switch
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF36343A)),
                        child: const Icon(Icons.palette, color: Colors.white70),
                      ),
                      title: Text('Dynamic Theme', style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 16)),
                      trailing: Switch(
                        value: _dynamicTheme,
                        onChanged: (val) => setState(() => _dynamicTheme = val),
                        activeColor: AppColors.primary,
                      ),
                    ),
                    const Divider(color: Color(0xFF494551), height: 1),

                    // Storage Usage Item
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF36343A)),
                                child: const Icon(Icons.storage, color: Colors.white70),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Storage Usage', style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text('4.2 GB of 10 GB used', style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Linear progress indicator
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: const LinearProgressIndicator(
                              value: 0.42,
                              backgroundColor: Color(0xFF36343A),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              ElevatedButton.icon(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF93000A).withOpacity(0.2),
                  foregroundColor: const Color(0xFFFFA9A3),
                  side: const BorderSide(color: Color(0xFF93000A)),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1B20).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF494551).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _RecentTrack {
  final String title;
  final String artist;
  final String imageUrl;

  const _RecentTrack({
    required this.title,
    required this.artist,
    required this.imageUrl,
  });
}
