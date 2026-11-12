import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../theme/app_theme.dart';

class LyricsSheet extends StatefulWidget {
  const LyricsSheet({Key? key}) : super(key: key);

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  final TextEditingController _editController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isEditing = false;
  int _lastAutoScrolledIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(int index) {
    if (index != _lastAutoScrolledIndex && _scrollController.hasClients) {
      _lastAutoScrolledIndex = index;
      _scrollController.animateTo(
        (index * 44.0).clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final currentSong = musicProvider.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final hasLyrics = currentSong.lyrics != null && currentSong.lyrics!.trim().isNotEmpty;
    final parsedKaraoke = musicProvider.parsedLyrics;
    final activeLyricIndex = musicProvider.currentLyricIndex;

    if (parsedKaraoke.isNotEmpty && activeLyricIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveLine(activeLyricIndex);
      });
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Lyrics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (parsedKaraoke.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                          ),
                          child: const Text(
                            'KARAOKE SYNC',
                            style: TextStyle(color: AppTheme.primary, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    currentSong.title,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.check_rounded : Icons.edit_note_rounded,
                  color: AppTheme.primary,
                  size: 26,
                ),
                onPressed: () {
                  if (_isEditing) {
                    musicProvider.updateLyrics(currentSong, _editController.text);
                    setState(() => _isEditing = false);
                  } else {
                    _editController.text = currentSong.lyrics ?? '';
                    setState(() => _isEditing = true);
                  }
                },
              ),
            ],
          ),
          const Divider(color: AppTheme.dividerColor, height: 20),

          // Content: Karaoke / Static / Editor
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: _editController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.6),
                    decoration: const InputDecoration(
                      hintText: 'Type or paste lyrics here (or LRC format with [01:23.45])...',
                      hintStyle: TextStyle(color: AppTheme.textMuted),
                      border: InputBorder.none,
                    ),
                  )
                : parsedKaraoke.isNotEmpty
                    ? ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: parsedKaraoke.length,
                        itemBuilder: (context, idx) {
                          final line = parsedKaraoke[idx];
                          final isActive = idx == activeLyricIndex;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              line.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isActive ? AppTheme.primaryBright : (idx < activeLyricIndex ? AppTheme.textMuted : AppTheme.textSecondary),
                                fontSize: isActive ? 20 : 16,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          );
                        },
                      )
                    : hasLyrics
                        ? SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              currentSong.lyrics!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 1.9,
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lyrics_outlined, size: 54, color: AppTheme.textMuted),
                                const SizedBox(height: 12),
                                const Text(
                                  'No lyrics found',
                                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Paste or add offline lyrics anytime',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.black,
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Lyrics'),
                                  onPressed: () {
                                    _editController.text = '';
                                    setState(() => _isEditing = true);
                                  },
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
