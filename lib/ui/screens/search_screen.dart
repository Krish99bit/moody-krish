import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _activeGenreFilter;
  String? _activeLanguageFilter;

  final List<String> _genres = ['All', 'Punjabi', 'Pop', 'Hip-Hop', 'Rock', 'Electronic', 'Acoustic', 'Classical', 'Chill'];
  final List<String> _languages = ['All', 'Hindi', 'Punjabi', 'English', 'Tamil', 'Telugu', 'Spanish'];

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final isSearching = _searchController.text.trim().isNotEmpty || _activeGenreFilter != null || _activeLanguageFilter != null;
    final results = library.searchResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Explore'),
      ),
      body: Column(
        children: [
          // Search Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                style: const TextStyle(color: Colors.black, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Songs, artists, albums, or genres...',
                  hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.black, size: 24),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.black, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _triggerFilter(library);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) => _triggerFilter(library),
              ),
            ),
          ),

          // Horizontal Genre Filter Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _genres.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = _genres[index];
                final isSelected = (_activeGenreFilter == null && genre == 'All') || (_activeGenreFilter == genre);

                return ChoiceChip(
                  label: Text(genre),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _activeGenreFilter = (genre == 'All' || !selected) ? null : genre;
                    });
                    _triggerFilter(library);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Search Results or Categories
          Expanded(
            child: isSearching
                ? results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.music_off_rounded, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No matching tracks found',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try checking spelling or clear filters',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final song = results[index];
                          return SongTile(
                            song: song,
                            contextQueue: results,
                            index: index,
                          );
                        },
                      )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Browse by Mood & Genre',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
                          children: [
                            _buildBrowseCard('Punjabi Beats 🔥', const Color(0xFFE65100), () => _quickFilterGenre('Punjabi', library)),
                            _buildBrowseCard('Hip-Hop & Rap', const Color(0xFF8D67AB), () => _quickFilterGenre('Hip-Hop', library)),
                            _buildBrowseCard('Pop Hits', const Color(0xFFBA5D07), () => _quickFilterGenre('Pop', library)),
                            _buildBrowseCard('Rock & Metal', const Color(0xFFE91429), () => _quickFilterGenre('Rock', library)),
                            _buildBrowseCard('Acoustic & Chill', const Color(0xFF006450), () => _quickFilterGenre('Acoustic', library)),
                            _buildBrowseCard('Electronic & EDM', const Color(0xFF1E3264), () => _quickFilterGenre('Electronic', library)),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _triggerFilter(LibraryProvider library) {
    library.searchWithFilters(
      query: _searchController.text.trim(),
      genre: _activeGenreFilter,
      language: _activeLanguageFilter,
    );
  }

  void _quickFilterGenre(String genre, LibraryProvider library) {
    setState(() {
      _activeGenreFilter = genre;
      _searchController.text = genre;
    });
    _triggerFilter(library);
  }

  Widget _buildBrowseCard(String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
