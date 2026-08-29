import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/player_controller.dart';
import '../../../controllers/music_controller.dart';
import '../../../models/artist_model.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  // Brand Colors
  static const Color nupeBlue = Color(0xFF001199);
  static const Color nupeGreen = Color(0xFF389F38);
  static const Color nupeRed = Color(0xFFE52A1A);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _showLyrics = false;
  final ScrollController _lyricScrollController = ScrollController();
  int _lastActiveIndex = -1;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _lyricScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerController>();
    final musicController = context.watch<MusicController>();

    final song = playerController.currentSong;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B728E);
    final backgroundColor = isDark ? const Color(0xFF03040B) : const Color(0xFFF6F8FD);
    final appBarTextColor = isDark ? Colors.white70 : const Color(0xFF6B728E);
    final appIconColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final appFavIconColor = isDark ? Colors.white70 : const Color(0xFF33374B);
    final coverBgColor = isDark ? const Color(0xFF151824) : const Color(0xFFEFF2F9);
    final coverIconColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05);
    final sliderInactiveColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08);
    final sliderThumbColor = isDark ? Colors.white : PlayerScreen.nupeBlue;
    final controlIconColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final secondaryControlIconColor = isDark ? Colors.white54 : const Color(0xFF757A90);

    final coverShadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 35,
              spreadRadius: 5,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: PlayerScreen.nupeGreen.withValues(alpha: 0.08),
              blurRadius: 50,
              spreadRadius: 2,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ];

    if (song == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            "No active playback",
            style: TextStyle(color: subtitleColor),
          ),
        ),
      );
    }

    final isPlaying = playerController.isPlaying;
    final position = playerController.position;
    final duration = playerController.duration;
    
    // Check if the current song is favorited
    final isFavorite = musicController.songs.firstWhere((s) => s.id == song.id, orElse: () => song).isFavorite;

    // Retrieve active ArtistModel for avatar display
    final artist = musicController.artists.firstWhere(
      (a) => a.name.toLowerCase() == song.artist.toLowerCase(),
      orElse: () => ArtistModel(id: '', name: song.artist, songIds: [], albumIds: []),
    );

    // Synced Lyrics Calculation
    final lyricLines = song.parsedLyrics;
    int activeIndex = -1;
    for (int i = 0; i < lyricLines.length; i++) {
      if (position >= lyricLines[i].time) {
        activeIndex = i;
      } else {
        break;
      }
    }

    // Trigger auto-scrolling when active index updates
    if (activeIndex != _lastActiveIndex && _showLyrics) {
      _lastActiveIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_lyricScrollController.hasClients && activeIndex >= 0) {
          const double itemHeight = 64.0; // height of each container
          final double viewportHeight = _lyricScrollController.position.viewportDimension;
          final double targetOffset = (activeIndex * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
          final double maxScroll = _lyricScrollController.position.maxScrollExtent;
          
          _lyricScrollController.animateTo(
            targetOffset.clamp(0.0, maxScroll),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: backgroundColor, // Matching adaptive background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: appIconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "${song.title} by ${song.artist}",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: appBarTextColor,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              playerController.volume == 0.0
                  ? Icons.volume_off_rounded
                  : (playerController.volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
              color: appFavIconColor,
              size: 24,
            ),
            tooltip: "Volume Control",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black.withValues(alpha: 0.4),
                builder: (context) {
                  return Consumer<PlayerController>(
                    builder: (context, pc, _) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
                      final cardColor = isDark ? const Color(0xFF1E1E22) : Colors.white;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Grabber handle
                            Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white24 : Colors.black12,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Title row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Volume Control",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  "${(pc.volume * 100).toInt()}%",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: PlayerScreen.nupeGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Slider Row
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    pc.volume == 0.0 ? Icons.volume_off_rounded : Icons.volume_down_rounded,
                                    color: pc.volume == 0.0 ? PlayerScreen.nupeRed : (isDark ? Colors.white70 : Colors.black54),
                                  ),
                                  onPressed: () => pc.toggleMute(),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                      activeTrackColor: PlayerScreen.nupeBlue,
                                      inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
                                      thumbColor: isDark ? Colors.white : PlayerScreen.nupeBlue,
                                      overlayColor: PlayerScreen.nupeBlue.withValues(alpha: 0.2),
                                    ),
                                    child: Slider(
                                      value: pc.volume,
                                      min: 0.0,
                                      max: 1.0,
                                      onChanged: (value) {
                                        pc.setVolume(value);
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.volume_up_rounded,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                  onPressed: () => pc.setVolume(1.0),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showLyrics ? Icons.music_note_rounded : Icons.lyrics_rounded,
              color: _showLyrics ? PlayerScreen.nupeGreen : appFavIconColor,
              size: 24,
            ),
            tooltip: _showLyrics ? "Show Artwork" : "Show Lyrics",
            onPressed: () {
              setState(() {
                _showLyrics = !_showLyrics;
                if (_showLyrics) {
                  _lastActiveIndex = -1; // Reset to force scroll on open
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              color: isFavorite ? PlayerScreen.nupeRed : appFavIconColor,
              size: 26,
            ),
            onPressed: () {
              musicController.toggleFavorite(song.id);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: 100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: PlayerScreen.nupeBlue.withValues(alpha: isDark ? 0.12 : 0.05),
                    blurRadius: 120,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: PlayerScreen.nupeRed.withValues(alpha: isDark ? 0.08 : 0.03),
                    blurRadius: 120,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          // Player Main Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 1. Large Rounded Album Art or Dynamic Scrolling Synced Lyrics View
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: _showLyrics
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.black.withValues(alpha: 0.015),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.04),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: ShaderMask(
                                shaderCallback: (rect) {
                                  return const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black,
                                      Colors.black,
                                      Colors.transparent
                                    ],
                                    stops: [0.0, 0.15, 0.85, 1.0],
                                  ).createShader(rect);
                                },
                                blendMode: BlendMode.dstIn,
                                child: lyricLines.isEmpty
                                    ? Center(
                                        child: Text(
                                          "Lyrics not available for this song.",
                                          style: TextStyle(color: subtitleColor, fontSize: 16),
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: _lyricScrollController,
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(vertical: 140),
                                        itemCount: lyricLines.length,
                                        itemBuilder: (context, index) {
                                          final line = lyricLines[index];
                                          final isActive = index == activeIndex;
                                          return Container(
                                            height: 64.0,
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: Text(
                                              line.text,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isActive
                                                    ? (isDark ? Colors.white : PlayerScreen.nupeBlue)
                                                    : (isDark
                                                        ? Colors.white.withValues(alpha: 0.3)
                                                        : const Color(0xFF0C1026).withValues(alpha: 0.35)),
                                                fontSize: isActive ? 20 : 16,
                                                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: coverShadow,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Container(
                                color: coverBgColor,
                                child: song.artworkPath != null
                                    ? (song.artworkPath!.startsWith('http')
                                        ? Image.network(
                                            song.artworkPath!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.music_note_rounded,
                                              size: 140,
                                              color: coverIconColor,
                                            ),
                                          )
                                        : Image.asset(
                                            song.artworkPath!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.music_note_rounded,
                                              size: 140,
                                              color: coverIconColor,
                                            ),
                                          ))
                                    : Icon(
                                        Icons.music_note_rounded,
                                        size: 140,
                                        color: coverIconColor,
                                      ),
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Song Title & Artist info
                  Column(
                    children: [
                      Text(
                        song.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (artist.imagePath != null) ...[
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: artist.imagePath!.startsWith('http')
                                      ? NetworkImage(artist.imagePath!)
                                      : AssetImage(artist.imagePath!) as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            song.artist,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 3. Progress Bar & Timers
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: PlayerScreen.nupeBlue,
                          inactiveTrackColor: sliderInactiveColor,
                          thumbColor: sliderThumbColor,
                          overlayColor: PlayerScreen.nupeBlue.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: position.inMilliseconds.toDouble().clamp(
                                0.0,
                                duration.inMilliseconds.toDouble(),
                              ),
                          min: 0.0,
                          max: duration.inMilliseconds.toDouble() > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (value) {
                            playerController.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 4. Playback Controls Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Shuffle
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: playerController.isShuffle ? PlayerScreen.nupeGreen : secondaryControlIconColor,
                          size: 26,
                        ),
                        onPressed: () => playerController.toggleShuffle(),
                      ),
                      // Previous
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: controlIconColor,
                          size: 38,
                        ),
                        onPressed: () => playerController.previous(),
                      ),
                      // Glowing Play/Pause Center Action
                      GestureDetector(
                        onTap: () {
                          if (isPlaying) {
                            playerController.pause();
                          } else {
                            playerController.resume();
                          }
                        },
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [PlayerScreen.nupeBlue, PlayerScreen.nupeGreen, PlayerScreen.nupeRed],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isPlaying ? PlayerScreen.nupeGreen : PlayerScreen.nupeBlue).withValues(alpha: 0.35),
                                blurRadius: 25,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Next
                      IconButton(
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: controlIconColor,
                          size: 38,
                        ),
                        onPressed: () => playerController.next(),
                      ),
                      // Repeat Mode
                      IconButton(
                        icon: Icon(
                          playerController.repeatMode == RepeatMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: playerController.repeatMode != RepeatMode.off ? PlayerScreen.nupeRed : secondaryControlIconColor,
                          size: 26,
                        ),
                        onPressed: () => playerController.toggleRepeatMode(),
                      ),
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
}
