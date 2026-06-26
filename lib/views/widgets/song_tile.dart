import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song_model.dart';
import '../../controllers/music_controller.dart';
import '../../controllers/playlist_controller.dart';
import '../../controllers/settings_controller.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final int? index;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.onFavoriteTap,
    this.index,
  });

  // Brand Colors
  static const Color nupeBlue = Color(0xFF001199);
  static const Color nupeGreen = Color(0xFF389F38);
  static const Color nupeRed = Color(0xFFE52A1A);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF6B728E);
    final indexColor = isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black26;
    final coverBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9);
    final iconColor = isDark ? Colors.white24 : Colors.black26;
    final playBgColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);
    final playIconColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final optionsIconColor = isDark ? Colors.white38 : Colors.black45;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            // 1. Index number (Optional)
            if (index != null) ...[
              Text(
                index.toString(),
                style: TextStyle(
                  color: indexColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
            ],

            // 2. Cover Art
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 50,
                height: 50,
                color: coverBgColor,
                child: song.artworkPath != null
                    ? (song.artworkPath!.startsWith('http')
                        ? Image.network(song.artworkPath!, fit: BoxFit.cover)
                        : Image.asset(song.artworkPath!, fit: BoxFit.cover))
                    : Icon(
                        Icons.music_note,
                        size: 24,
                        color: iconColor,
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // 3. Title & Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // 4. Action Row (Play Icon + More Menu)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clean circular Play icon
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: playBgColor,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: playIconColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                 IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: optionsIconColor,
                    size: 20,
                  ),
                  onPressed: () => _showOptionsSheet(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF6B728E);
    final coverBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9);
    final sheetBgColor = isDark ? const Color(0xFF141416) : Colors.white;

    final musicController = context.read<MusicController>();
    final playlistController = context.read<PlaylistController>();
    final settingsController = context.read<SettingsController>();

    final bool isFav = musicController.songs.firstWhere((s) => s.id == song.id, orElse: () => song).isFavorite;
    final bool isDownloaded = musicController.downloadedSongIds.contains(song.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (Artwork, Title, Artist)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 50,
                          height: 50,
                          color: coverBgColor,
                          child: song.artworkPath != null
                              ? (song.artworkPath!.startsWith('http')
                                  ? Image.network(song.artworkPath!, fit: BoxFit.cover)
                                  : Image.asset(song.artworkPath!, fit: BoxFit.cover))
                              : const Icon(Icons.music_note, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24, thickness: 1, indent: 20, endIndent: 20),

                // Option: Add to Playlist
                ListTile(
                  leading: const Icon(Icons.add_box_rounded, color: nupeBlue),
                  title: Text("Add to Playlist", style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddPlaylistDialog(context, playlistController);
                  },
                ),

                // Option: Download or Delete from Downloads
                if (isDownloaded)
                  ListTile(
                    leading: const Icon(Icons.download_done_rounded, color: nupeGreen),
                    title: Text("Delete from Downloads", style: TextStyle(color: textColor)),
                    onTap: () {
                      musicController.deleteDownloadedSong(song.id);
                      settingsController.removeDownloadedBytes(257698037);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Removed '${song.title}' from downloads"),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.download_rounded, color: nupeBlue),
                    title: Text("Download", style: TextStyle(color: textColor)),
                    onTap: () async {
                      Navigator.pop(context);
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text("Downloading '${song.title}'..."),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      await Future.delayed(const Duration(seconds: 1));
                      musicController.downloadSong(song.id);
                      settingsController.addDownloadedBytes(257698037);
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: nupeGreen,
                          content: Text("'${song.title}' downloaded successfully", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                // Option: Toggle Favorite
                ListTile(
                  leading: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? nupeRed : textColor,
                  ),
                  title: Text(
                    isFav ? "Remove from Favorites" : "Add to Favorites",
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () {
                    musicController.toggleFavorite(song.id);
                    if (onFavoriteTap != null) {
                      onFavoriteTap!();
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFav ? "Removed from Favorites" : "Added to Favorites"),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddPlaylistDialog(BuildContext context, PlaylistController playlistController) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final sheetBgColor = isDark ? const Color(0xFF141416) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Add to Playlist",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                if (playlistController.playlists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        "No playlists found. Create one first!",
                        style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlistController.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlistController.playlists[index];
                        return ListTile(
                          leading: const Icon(Icons.music_video_rounded, color: nupeBlue),
                          title: Text(playlist.name, style: TextStyle(color: textColor)),
                          onTap: () {
                            playlistController.addSongToPlaylist(playlist.id, song.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Added to ${playlist.name}"),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
