import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../services/audio_importer.dart';
import '../theme/app_theme.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({Key? key}) : super(key: key);

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _copyToVault = true;
  bool _isImporting = false;
  int _currentProgress = 0;
  int _totalProgress = 0;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Offline Songs'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informative Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3E62), Color(0xFF121212)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.offline_pin_rounded, color: AppTheme.primary, size: 36),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Offline & Private',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'All downloaded songs stay right on your device. No cloud, no tracking, no internet required.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Option Toggle: Save to App Vault
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primary,
                title: const Text(
                  'Copy to App Offline Vault',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: const Text(
                  'Recommended: Keeps your song safe inside this app even if you clean or delete it from your phone’s Downloads folder.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                value: _copyToVault,
                onChanged: _isImporting ? null : (val) => setState(() => _copyToVault = val),
              ),
            ),
            const SizedBox(height: 24),

            // Import Progress Indicator
            if (_isImporting) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _statusMessage,
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        if (_totalProgress > 0)
                          Text(
                            '$_currentProgress / $_totalProgress',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _totalProgress > 0 ? _currentProgress / _totalProgress : null,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Card 1: Import Files
            _buildActionCard(
              title: 'Select Audio Files',
              description: 'Pick one or multiple audio tracks (.mp3, .m4a, .flac, .wav, .aac, .ogg) from your device.',
              icon: Icons.audio_file_rounded,
              iconColor: AppTheme.primary,
              buttonText: 'Pick Audio Files',
              onPressed: _isImporting ? null : _importFiles,
            ),
            const SizedBox(height: 16),

            // Action Card 2: Import Entire Folder
            _buildActionCard(
              title: 'Select Music Folder',
              description: 'Choose a folder (such as Downloads or Music) to automatically scan and import all songs inside.',
              icon: Icons.folder_copy_rounded,
              iconColor: const Color(0xFF1E88E5),
              buttonText: 'Scan Entire Folder',
              onPressed: _isImporting ? null : _importFolder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
    required VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceElevated,
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
              onPressed: onPressed,
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importFiles() async {
    final hasPermission = await AudioImporter.requestStoragePermission();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required to import songs')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _statusMessage = 'Importing selected songs...';
      _currentProgress = 0;
      _totalProgress = 0;
    });

    final imported = await AudioImporter.pickAndImportFiles(
      copyToAppVault: _copyToVault,
      onProgress: (current, total) {
        if (mounted) {
          setState(() {
            _currentProgress = current;
            _totalProgress = total;
          });
        }
      },
    );

    if (mounted) {
      await context.read<LibraryProvider>().refreshLibrary();
      setState(() => _isImporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imported.isNotEmpty
                ? 'Successfully added ${imported.length} songs to your library!'
                : 'No new songs were added.',
          ),
          backgroundColor: imported.isNotEmpty ? AppTheme.primary : AppTheme.surfaceElevated,
        ),
      );

      if (imported.isNotEmpty) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _importFolder() async {
    final hasPermission = await AudioImporter.requestStoragePermission();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required to import folders')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _statusMessage = 'Scanning folder and extracting metadata...';
      _currentProgress = 0;
      _totalProgress = 0;
    });

    final imported = await AudioImporter.pickAndImportFolder(
      copyToAppVault: _copyToVault,
      onProgress: (current, total) {
        if (mounted) {
          setState(() {
            _currentProgress = current;
            _totalProgress = total;
          });
        }
      },
    );

    if (mounted) {
      await context.read<LibraryProvider>().refreshLibrary();
      setState(() => _isImporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imported.isNotEmpty
                ? 'Successfully imported ${imported.length} songs from folder!'
                : 'No audio files found in selected folder.',
          ),
          backgroundColor: imported.isNotEmpty ? AppTheme.primary : AppTheme.surfaceElevated,
        ),
      );

      if (imported.isNotEmpty) {
        Navigator.pop(context);
      }
    }
  }
}
