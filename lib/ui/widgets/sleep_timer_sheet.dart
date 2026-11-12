import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sleep_timer_service.dart';
import '../theme/app_theme.dart';

class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sleepTimer = context.watch<SleepTimerService>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Row(
            children: [
              Icon(Icons.bedtime_rounded, color: AppTheme.primary, size: 24),
              SizedBox(width: 10),
              Text(
                'Sleep Timer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Timer Status Banner
          if (sleepTimer.isActive) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Timer Active',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Music stops in: ${sleepTimer.formattedRemaining}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      sleepTimer.cancelTimer();
                      Navigator.pop(context);
                    },
                    child: const Text('Turn Off'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (sleepTimer.mode == SleepTimerMode.endOfSong) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Music stops at end of track',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      sleepTimer.cancelTimer();
                      Navigator.pop(context);
                    },
                    child: const Text('Turn Off'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Timer Options
          _buildOption(
            context,
            title: '15 Minutes',
            onTap: () {
              sleepTimer.startTimer(const Duration(minutes: 15), SleepTimerMode.minutes15);
              Navigator.pop(context);
            },
          ),
          _buildOption(
            context,
            title: '30 Minutes',
            onTap: () {
              sleepTimer.startTimer(const Duration(minutes: 30), SleepTimerMode.minutes30);
              Navigator.pop(context);
            },
          ),
          _buildOption(
            context,
            title: '45 Minutes',
            onTap: () {
              sleepTimer.startTimer(const Duration(minutes: 45), SleepTimerMode.minutes45);
              Navigator.pop(context);
            },
          ),
          _buildOption(
            context,
            title: '1 Hour',
            onTap: () {
              sleepTimer.startTimer(const Duration(minutes: 60), SleepTimerMode.minutes60);
              Navigator.pop(context);
            },
          ),
          _buildOption(
            context,
            title: 'End of Track',
            onTap: () {
              sleepTimer.setEndOfSongMode();
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, {required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 16),
      onTap: onTap,
    );
  }
}
