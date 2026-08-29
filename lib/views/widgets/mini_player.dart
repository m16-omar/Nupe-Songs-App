import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/song_model.dart';

class MiniPlayer extends StatelessWidget {
  final SongModel song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlayPauseTap;
  final VoidCallback onNextTap;
  final VoidCallback? onPreviousTap;
  final double progress; // Value between 0.0 and 1.0

  const MiniPlayer({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    required this.onPlayPauseTap,
    required this.onNextTap,
    this.onPreviousTap,
    required this.progress,
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
    final playerBgColor = isDark ? const Color(0xFF111116).withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.88);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);
    final coverBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9);
    final noCoverIconColor = isDark ? Colors.white30 : Colors.black26;
    final controlIconColor = isDark ? Colors.white70 : const Color(0xFF33374B);
    final progressTrackColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            decoration: BoxDecoration(
              color: playerBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: isDark ? Offset.zero : const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      // Cover Artwork
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          color: coverBgColor,
                          child: song.artworkPath != null
                              ? (song.artworkPath!.startsWith('http')
                                  ? Image.network(
                                      song.artworkPath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.music_note,
                                        color: noCoverIconColor,
                                      ),
                                    )
                                  : Image.asset(
                                      song.artworkPath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.music_note,
                                        color: noCoverIconColor,
                                      ),
                                    ))
                              : Icon(
                                  Icons.music_note,
                                  color: noCoverIconColor,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Track Details
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Controls Row on the Right
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Previous button
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.skip_previous_rounded,
                              color: controlIconColor,
                              size: 24,
                            ),
                            onPressed: onPreviousTap,
                          ),
                          const SizedBox(width: 12),
                          // Filled circular Play/Pause button
                          GestureDetector(
                            onTap: onPlayPauseTap,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: nupeBlue, // Brand Blue
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Next button
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.skip_next_rounded,
                              color: controlIconColor,
                              size: 24,
                            ),
                            onPressed: onNextTap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Custom Slim Slider progress line (bottom)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Align(
                     alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 2.0,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: progressTrackColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            color: nupeBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
