import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_typography.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _themeIndex = 1; // 0: Light, 1: Dark, 2: System
  bool _autoplay = true;
  bool _gapless = false;
  String _equalizer = 'Pop';
  String _wifiQuality = 'Lossless (Hi-Res)';
  String _cellularQuality = 'High';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40.0, top: 12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF211F24).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: const Color(0xFF494551).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuARoM2SSVtM-3HyqtbWDXaeT_n6tuxzwWpKsO7Mqr8SIMae3S7idcYoIbf_9vbTMBZjJ0-QXJS5dcR0yohYfTar_lQo00U50ptTmYAWTS5FeWQc836SPr9r7ytyqkIWuD7w1i9md-kwJEZsRr1Zv0g_ywtNVs5uNiGvi5xpfQUA3pKDKsPUwp0Wbgj-wkzdXnY08X_tsildBtJ2CIUg7mRI_O4Ll6BFKIFxZnmLG5OOqi6cVp9HkgQ5eRzfyJt3uxOoJBvzMRVAVk0',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alex Mercer',
                            style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Premium Member',
                            style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF494551)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                      ),
                      child: Text(
                        'Edit',
                        style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Appearance
              _buildSectionHeader('Appearance'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF211F24).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFF494551).withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dark_mode_outlined, color: AppColors.darkOnSurfaceVariant),
                          const SizedBox(width: 16),
                          Text('Theme', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                        ],
                      ),
                      // Segmented control
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0D13),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(color: const Color(0xFF494551).withOpacity(0.3)),
                        ),
                        padding: const EdgeInsets.all(2.0),
                        child: Row(
                          children: [
                            _buildSegmentButton('Light', 0),
                            _buildSegmentButton('Dark', 1),
                            _buildSegmentButton('System', 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Playback
              _buildSectionHeader('Playback'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF211F24).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFF494551).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.all_inclusive, color: AppColors.darkOnSurfaceVariant),
                      title: Text('Autoplay Similar Music', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                      subtitle: Text('Keep listening when your queue ends',
                          style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant)),
                      trailing: Switch(
                        value: _autoplay,
                        onChanged: (val) => setState(() => _autoplay = val),
                        activeColor: AppColors.primary,
                      ),
                    ),
                    const Divider(color: Color(0xFF494551), height: 1),
                    ListTile(
                      leading: const Icon(Icons.graphic_eq, color: AppColors.darkOnSurfaceVariant),
                      title: Text('Gapless Playback', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                      trailing: Switch(
                        value: _gapless,
                        onChanged: (val) => setState(() => _gapless = val),
                        activeColor: AppColors.primary,
                      ),
                    ),
                    const Divider(color: Color(0xFF494551), height: 1),
                    ListTile(
                      leading: const Icon(Icons.tune, color: AppColors.darkOnSurfaceVariant),
                      title: Text('Equalizer', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_equalizer, style: AppTypography.caption.copyWith(color: AppColors.primary)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: AppColors.darkOnSurfaceVariant),
                        ],
                      ),
                      onTap: () => _showSingleSelectorDialog('Equalizer', ['Pop', 'Rock', 'Electronic', 'Jazz', 'Classical'], _equalizer, (val) {
                        setState(() => _equalizer = val);
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Audio Quality
              _buildSectionHeader('Audio Quality'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF211F24).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFF494551).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.wifi, color: AppColors.darkOnSurfaceVariant),
                      title: Text('Wi-Fi Streaming', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_wifiQuality, style: AppTypography.caption.copyWith(color: AppColors.primary)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: AppColors.darkOnSurfaceVariant),
                        ],
                      ),
                      onTap: () => _showSingleSelectorDialog('Wi-Fi Quality', ['Standard', 'High', 'Lossless (Hi-Res)'], _wifiQuality, (val) {
                        setState(() => _wifiQuality = val);
                      }),
                    ),
                    const Divider(color: Color(0xFF494551), height: 1),
                    ListTile(
                      leading: const Icon(Icons.cell_tower, color: AppColors.darkOnSurfaceVariant),
                      title: Text('Cellular Streaming', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_cellularQuality, style: AppTypography.caption.copyWith(color: AppColors.primary)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: AppColors.darkOnSurfaceVariant),
                        ],
                      ),
                      onTap: () => _showSingleSelectorDialog('Cellular Quality', ['Low', 'Standard', 'High'], _cellularQuality, (val) {
                        setState(() => _cellularQuality = val);
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Diagnostics
              _buildSectionHeader('Diagnostics'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF211F24).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFF494551).withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.network_ping, color: AppColors.primary),
                  title: Text('Ping Backend Server', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                  subtitle: Text('Check if the backend is awake', style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant)),
                  onTap: _pingBackend,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pingBackend() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF1D1B20),
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 20),
            Text('Pinging server...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(Uri.parse(ApiConfig.baseUrl)).timeout(const Duration(seconds: 15));
      stopwatch.stop();
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showResultDialog('Success', 'Status: ${response.statusCode}\nLatency: ${stopwatch.elapsedMilliseconds}ms', Colors.green);
      }
    } catch (e) {
      stopwatch.stop();
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showResultDialog('Error', 'Failed to reach server: $e', Colors.redAccent);
      }
    }
  }

  void _showResultDialog(String title, String message, Color titleColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1B20),
        title: Text(title, style: AppTypography.titleMedium.copyWith(color: titleColor)),
        content: Text(message, style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String text, int index) {
    final isSelected = _themeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _themeIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6750A4) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: AppTypography.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.darkOnSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showSingleSelectorDialog(String title, List<String> options, String currentSelection, ValueChanged<String> onSelect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1B20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: AppTypography.titleMedium.copyWith(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final isSelected = opt == currentSelection;
            return RadioListTile<String>(
              value: opt,
              groupValue: currentSelection,
              title: Text(opt, style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  onSelect(val);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
