import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/album_model.dart';
import '../../controllers/music_controller.dart';
import '../../controllers/playlist_controller.dart';
import '../../controllers/player_controller.dart';

class AlbumCard extends StatelessWidget {
  final AlbumModel album;
  final VoidCallback onTap;
  final VoidCallback? onPlayTap;
  final double width;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
    this.onPlayTap,
    this.width = 130,
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
    final coverBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9);
    final iconColor = isDark ? Colors.white24 : Colors.black26;
    final optionsIconColor = isDark ? Colors.white38 : Colors.black45;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork Image Stack
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  // Rounded square cover
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: coverBgColor,
                        child: album.artworkPath != null
                            ? (album.artworkPath!.startsWith('http')
                                ? Image.network(
                                    album.artworkPath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Icon(
                                        Icons.album,
                                        size: 40,
                                        color: iconColor,
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    album.artworkPath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Icon(
                                        Icons.album,
                                        size: 40,
                                        color: iconColor,
                                      ),
                                    ),
                                  ))
                            : Center(
                                child: Icon(
                                  Icons.album,
                                  size: 40,
                                  color: iconColor,
                                ),
                              ),
                      ),
                    ),
                  ),
                  // Floating circular Play button (Bottom-right)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onPlayTap ?? onTap,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.65),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Title & More Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        album.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Options menu icon wrapped in a gesture detector
                GestureDetector(
                  onTap: () => _showAlbumOptionsSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: optionsIconColor,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAlbumOptionsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF6B728E);
    final coverBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9);
    final sheetBgColor = isDark ? const Color(0xFF141416) : Colors.white;

    final musicController = context.read<MusicController>();
    final playlistController = context.read<PlaylistController>();
    final playerController = context.read<PlayerController>();

    final albumSongs = musicController.songs.where((s) => album.songIds.contains(s.id)).toList();

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
                // Header (Artwork, Album Title, Artist)
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
                          child: album.artworkPath != null
                              ? (album.artworkPath!.startsWith('http')
                                  ? Image.network(album.artworkPath!, fit: BoxFit.cover)
                                  : Image.asset(album.artworkPath!, fit: BoxFit.cover))
                              : const Icon(Icons.album_rounded, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.name,
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
                              "${album.artist} • ${albumSongs.length} songs",
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

                // Option: Play Album
                ListTile(
                  leading: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF389F38)),
                  title: Text("Play Album", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    if (albumSongs.isNotEmpty) {
                      playerController.playSong(albumSongs.first, albumSongs);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No songs in this album.")),
                      );
                    }
                  },
                ),

                // Option: Add all to Playlist
                ListTile(
                  leading: const Icon(Icons.add_box_rounded, color: nupeBlue),
                  title: Text("Add Album to Playlist", style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddPlaylistDialog(context, playlistController, albumSongs);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddPlaylistDialog(BuildContext context, PlaylistController playlistController, List<dynamic> songsList) {
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
                    "Add all songs to Playlist",
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
                            for (var song in songsList) {
                              playlistController.addSongToPlaylist(playlist.id, song.id);
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Added ${songsList.length} songs to ${playlist.name}"),
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
