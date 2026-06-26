import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/music_controller.dart';
import '../../../controllers/player_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/playlist_controller.dart';
import '../../../models/artist_model.dart';
import '../../../models/album_model.dart';
import '../../../models/playlist_model.dart';
import '../../../models/song_model.dart';
import '../auth/auth_screen.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/album_card.dart';
import '../player/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Brand Colors
  static const Color nupeBlue = Color(0xFF001199);
  static const Color nupeGreen = Color(0xFF389F38);
  static const Color nupeRed = Color(0xFFE52A1A);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  int _librarySubTab = 0;

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final musicController = context.watch<MusicController>();
    final isGuest = authController.isGuest;
    final hasDownloadedSongs = musicController.downloadedSongIds.isNotEmpty;

    if (isGuest && !hasDownloadedSongs) {
      return _buildNoDownloadsGuestScreen(context, authController);
    }

    if (isGuest && hasDownloadedSongs) {
      if (_currentTab != 2 && _currentTab != 3) {
        _currentTab = 2;
      }
    }

    final playerController = context.watch<PlayerController>();
    final currentSong = playerController.currentSong;
    final isPlaying = playerController.isPlaying;
    final progress = playerController.duration.inMilliseconds > 0
        ? playerController.position.inMilliseconds /
              playerController.duration.inMilliseconds
        : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF08080A)
        : const Color(0xFFF6F8FD);

    return Scaffold(
      backgroundColor: backgroundColor, // Adaptive background
      body: Stack(
        children: [
          // Dynamic Tab view body
          IndexedStack(
            index: _currentTab,
            children: [
              _HomeTabView(
                onProfileTap: () {
                  setState(() {
                    _currentTab = 3; // Navigate to Profile / Settings
                  });
                },
                onLibraryTap: () {
                  setState(() {
                    _currentTab = 2; // Navigate to Library
                    _librarySubTab = 0; // Reset to Playlists
                  });
                },
                onCategoryTap: (subTabIndex) {
                  setState(() {
                    _currentTab = 2; // Navigate to Library
                    _librarySubTab = subTabIndex;
                  });
                },
              ),
              const _SearchTabView(),
              _LibraryTabView(
                initialSubTab: isGuest ? 4 : _librarySubTab,
                onProfileTap: () {
                  setState(() {
                    _currentTab = 3; // Navigate to Profile / Settings
                  });
                },
              ),
              const _ProfileTabView(),
            ],
          ),

          // Persistent Floating Mini Player (Positions above bottom nav)
          if (currentSong != null)
            Positioned(
              bottom: 92, // Floats exactly above the 5-tab bottom bar
              left: 12,
              right: 12,
              child: MiniPlayer(
                song: currentSong,
                isPlaying: isPlaying,
                progress: progress,
                onTap: () {
                  // Push full PlayerScreen with a slide-up animation
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const PlayerScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOutQuad;
                            var tween = Tween(
                              begin: begin,
                              end: end,
                            ).chain(CurveTween(curve: curve));
                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                    ),
                  );
                },
                onPlayPauseTap: () {
                  if (isPlaying) {
                    playerController.pause();
                  } else {
                    playerController.resume();
                  }
                },
                onNextTap: () => playerController.next(),
                onPreviousTap: () => playerController.previous(),
              ),
            ),

          // Floating Glassmorphism 5-Tab Navigation Bar (Mockup Style)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFloatingBottomBar(),
          ),
        ],
      ),
    );
  }

  // 5-Tab Docked Bottom Navigation Bar
  Widget _buildFloatingBottomBar() {
    final isGuest = context.watch<AuthController>().isGuest;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBgColor = isDark
        ? const Color(0xFF08080A).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.88);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: 84,
          padding: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: barBgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border(top: BorderSide(color: borderColor, width: 1.0)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, -4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isGuest
                ? [
                    _buildNavButton(Icons.my_library_music_rounded, 2, "Library"),
                    _buildNavButton(Icons.settings_rounded, 3, "Settings"),
                  ]
                : [
                    _buildNavButton(Icons.home_filled, 0, "Home"),
                    _buildNavButton(Icons.search_rounded, 1, "Search"),
                    _buildNavButton(Icons.my_library_music_rounded, 2, "Library"),
                    _buildNavButton(Icons.settings_rounded, 3, "Settings"),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDownloadsGuestScreen(BuildContext context, AuthController authController) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B728E);
    final backgroundColor = isDark ? const Color(0xFF08080A) : const Color(0xFFF6F8FD);
    final cardColor = isDark ? const Color(0xFF141416) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: HomeScreen.nupeBlue.withValues(alpha: isDark ? 0.18 : 0.08),
                    blurRadius: 130,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: HomeScreen.nupeRed.withValues(alpha: isDark ? 0.12 : 0.05),
                    blurRadius: 120,
                    spreadRadius: 35,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Emblem
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                        border: Border.all(
                          color: HomeScreen.nupeGreen.withValues(alpha: 0.3),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Access Restricted",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: isDark ? 0.65 : 0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 54,
                                color: HomeScreen.nupeRed.withValues(alpha: 0.8),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Offline Mode Only",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Guest accounts are only permitted to play downloaded music offline. Since you have no downloaded tracks in this device, online catalog browsing is restricted.\n\nPlease login or register to search, play, and download music.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtitleColor,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [HomeScreen.nupeBlue, HomeScreen.nupeGreen, HomeScreen.nupeRed],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: HomeScreen.nupeBlue.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          authController.logout();
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                              transitionDuration: const Duration(milliseconds: 600),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign In / Register",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, int index, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentTab == index;
    final activeColor = isSelected
        ? HomeScreen.nupeGreen
        : (isDark ? Colors.white38 : const Color(0xFF757A90));

    return InkWell(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: activeColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: activeColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTabView extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onLibraryTap;
  final ValueChanged<int>? onCategoryTap;
  const _HomeTabView({this.onProfileTap, this.onLibraryTap, this.onCategoryTap});

  @override
  State<_HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<_HomeTabView> {
  String _selectedGenre = "All";
  String _sortBy = "Popularity"; // "Popularity" | "Latest Uploads" | "Alphabetical"

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  void _showFilterSheet(BuildContext context, MusicController musicController) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF6B728E);
    final sheetBgColor = isDark ? const Color(0xFF141416) : Colors.white;
    final innerContainerColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9);

    // Extract unique genres
    final uniqueGenres = ["All"];
    for (final song in musicController.songs) {
      if (song.genre != null && song.genre!.isNotEmpty) {
        if (!uniqueGenres.contains(song.genre)) {
          uniqueGenres.add(song.genre!);
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Filter & Sort",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              _sortBy = "Popularity";
                              _selectedGenre = "All";
                            });
                            setState(() {}); // Rebuild home tab
                          },
                          child: const Text(
                            "Reset",
                            style: TextStyle(
                              color: HomeScreen.nupeGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sort By Header
                    Text(
                      "Sort By",
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Sort Options Row
                    Wrap(
                      spacing: 8,
                      children: [
                        "Popularity",
                        "Latest Uploads",
                        "Alphabetical",
                      ].map((sortOption) {
                        final isSelected = _sortBy == sortOption;
                        return ChoiceChip(
                          label: Text(
                            sortOption,
                            style: TextStyle(
                              color: isSelected ? Colors.white : textColor,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: HomeScreen.nupeGreen,
                          backgroundColor: innerContainerColor,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() {
                                _sortBy = sortOption;
                              });
                              setState(() {}); // Rebuild home tab
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Genre Header
                    Text(
                      "Genre",
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Genres Wrap
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: uniqueGenres.map((genreOption) {
                        final isSelected = _selectedGenre == genreOption;
                        return ChoiceChip(
                          label: Text(
                            genreOption,
                            style: TextStyle(
                              color: isSelected ? Colors.white : textColor,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: HomeScreen.nupeGreen,
                          backgroundColor: innerContainerColor,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() {
                                _selectedGenre = genreOption;
                              });
                              setState(() {}); // Rebuild home tab
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Close/Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeScreen.nupeGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Apply",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicController = context.watch<MusicController>();
    final playerController = context.watch<PlayerController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);

    final filteredPopularSongs = List<SongModel>.from(musicController.songs);

    // Apply Genre Filter
    if (_selectedGenre != "All") {
      filteredPopularSongs.retainWhere((song) => song.genre?.toLowerCase() == _selectedGenre.toLowerCase());
    }

    // Apply Sorting
    if (_sortBy == "Popularity") {
      filteredPopularSongs.sort((a, b) {
        final scoreA = a.streamCount + a.downloadCount;
        final scoreB = b.streamCount + b.downloadCount;
        return scoreB.compareTo(scoreA); // Descending
      });
    } else if (_sortBy == "Latest Uploads") {
      filteredPopularSongs.sort((a, b) {
        final idA = int.tryParse(a.id) ?? 0;
        final idB = int.tryParse(b.id) ?? 0;
        return idB.compareTo(idA); // Descending
      });
    } else if (_sortBy == "Alphabetical") {
      filteredPopularSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase())); // Ascending
    }
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF6B728E);
    final innerContainerColor = isDark
        ? const Color(0xFF1E1E22)
        : const Color(0xFFEFF2F9);
    final searchBgColor = isDark ? const Color(0xFF151518) : Colors.white;
    final searchBorder = isDark
        ? null
        : Border.all(color: Colors.black.withValues(alpha: 0.05));
    final searchShadow = isDark
        ? null
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ];
    final searchIconColor = isDark ? Colors.white30 : Colors.black38;
    final searchHintColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black38;
    final backgroundColor = isDark
        ? const Color(0xFF08080A)
        : const Color(0xFFF6F8FD);

    return RefreshIndicator(
      color: HomeScreen.nupeGreen,
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      onRefresh: () async {
        await musicController.loadMusic();
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
        // Header AppBar area
        SliverPadding(
          padding: const EdgeInsets.only(
            top: 60,
            left: 20,
            right: 20,
            bottom: 10,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Avatar & Greetings Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text("👋", style: TextStyle(fontSize: 22)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Enjoy your favorite music",
                        style: TextStyle(color: subtitleColor, fontSize: 13),
                      ),
                    ],
                  ),
                  // Quick Theme Toggle Button & User Avatar picture
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isDark
                              ? Icons.wb_sunny_rounded
                              : Icons.nights_stay_rounded,
                          color: isDark
                              ? Colors.orangeAccent
                              : const Color(0xFF757A90),
                        ),
                        onPressed: () {
                          final settings = context.read<SettingsController>();
                          settings.toggleTheme(!isDark);
                        },
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onProfileTap,
                        child: Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: innerContainerColor,
                                border: Border.all(
                                  color: HomeScreen.nupeGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1.5,
                                ),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/avatar.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: HomeScreen
                                      .nupeRed, // Active notification dot
                                  border: Border.all(
                                    color: backgroundColor,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar & Filter Row
              Row(
                children: [
                  // Search Pill
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: searchBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: searchBorder,
                        boxShadow: searchShadow,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: searchIconColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Search songs, artists, albums...",
                                hintStyle: TextStyle(
                                  color: searchHintColor,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                              ),
                              style: TextStyle(color: textColor, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Tuner button
                  GestureDetector(
                    onTap: () => _showFilterSheet(context, musicController),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: HomeScreen.nupeBlue.withValues(
                              alpha: 0.15,
                            ), // Dark blue tinted background
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color:
                                HomeScreen.nupeGreen, // Filter Icon matching mockup
                            size: 20,
                          ),
                        ),
                        if (_selectedGenre != "All" || _sortBy != "Popularity")
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: HomeScreen.nupeGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Cards (Horizontal Row)
              _buildCategoryRow(context),
              const SizedBox(height: 28),

              // Recently Played Header
              _buildSectionHeader(
                context,
                "Recently Played",
                onTap: widget.onLibraryTap,
              ),
              const SizedBox(height: 14),

              // Recently Played horizontal list (songs)
              Builder(builder: (context) {
                final recentSongs = playerController.recentlyPlayed.isNotEmpty
                    ? playerController.recentlyPlayed
                    : musicController.latestSongs;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final coverBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9);
                final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
                final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);

                return SizedBox(
                  height: 160,
                  child: musicController.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : recentSongs.isEmpty
                          ? Center(
                              child: Text(
                                "No songs played yet",
                                style: TextStyle(color: subtitleColor),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemCount: recentSongs.length,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              itemBuilder: (context, index) {
                                final song = recentSongs[index];
                                return GestureDetector(
                                  onTap: () {
                                    playerController.playSong(song, recentSongs);
                                  },
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Artwork
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Container(
                                            width: 120,
                                            height: 112,
                                            color: coverBgColor,
                                            child: song.artworkPath != null && song.artworkPath!.isNotEmpty
                                                ? (song.artworkPath!.startsWith('http')
                                                    ? Image.network(
                                                        song.artworkPath!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (ctx, err, _) => const Icon(
                                                          Icons.music_note_rounded,
                                                          size: 40,
                                                          color: Colors.white24,
                                                        ),
                                                      )
                                                    : Image.asset(
                                                        song.artworkPath!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (ctx, err, _) => const Icon(
                                                          Icons.music_note_rounded,
                                                          size: 40,
                                                          color: Colors.white24,
                                                        ),
                                                      ))
                                                : const Icon(
                                                    Icons.music_note_rounded,
                                                    size: 40,
                                                    color: Colors.white24,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Song title
                                        Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        // Artist
                                        Text(
                                          song.artist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: subtitleColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                );
              }),
              const SizedBox(height: 28),

              // Made For You Header
              _buildSectionHeader(
                context,
                "Made For You",
                onTap: widget.onLibraryTap,
              ),
              const SizedBox(height: 14),

              // Made For You vertical scrolling horizontal mix list
              _buildMadeForYouList(playerController, musicController),
              const SizedBox(height: 28),

              // Popular This Week Header
              _buildSectionHeader(
                context,
                _selectedGenre == "All" && _sortBy == "Popularity"
                    ? "Popular This Week"
                    : "Popular This Week ($_selectedGenre)",
                onTap: () => widget.onCategoryTap?.call(1),
              ),
              const SizedBox(height: 14),
            ]),
          ),
        ),

        // Vertical popular song list
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index >= filteredPopularSongs.length) return null;
            final song = filteredPopularSongs[index];
            return SongTile(
              index: index + 1, // 1-based index matching mockup
              song: song,
              onTap: () {
                playerController.playSong(song, filteredPopularSongs);
              },
            );
          }, childCount: filteredPopularSongs.length),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 180), // Padding above navigation
        ),
      ],
    ),
  );
}

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              const Text(
                "See all",
                style: TextStyle(
                  color: HomeScreen.nupeGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: HomeScreen.nupeGreen.withValues(alpha: 0.8),
                size: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Category Icon buttons
  Widget _buildCategoryRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBgColor = isDark ? const Color(0xFF141416) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFEBEFFB);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF33374B);

    final titles = ["Songs", "Albums", "Artists", "Downloads", "Favorites"];
    final icons = [
      Icons.music_note_rounded,
      Icons.album_rounded,
      Icons.person_rounded,
      Icons.download_rounded,
      Icons.favorite_rounded,
    ];
    final colors = [
      HomeScreen.nupeBlue, // Songs - Brand Blue
      HomeScreen.nupeGreen, // Albums - Brand Green
      HomeScreen.nupeBlue, // Artists - Brand Blue
      HomeScreen.nupeGreen, // Downloads - Brand Green
      HomeScreen.nupeRed, // Favorites - Brand Red
    ];

    return SizedBox(
      height: 74,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: titles.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                final subTabIndex = index + 1; // Songs=1, Albums=2, Artists=3, Downloads=4, Favorites=5
                if (widget.onCategoryTap != null) {
                  widget.onCategoryTap!(subTabIndex);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: containerBgColor,
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icons[index], color: colors[index], size: 22),
                    const SizedBox(height: 6),
                    Text(
                      titles[index],
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Made For You gradient mixes cards - dynamically displaying latest uploads
  Widget _buildMadeForYouList(PlayerController player, MusicController music) {
    final latestSongs = music.latestSongs;
    if (latestSongs.isEmpty) {
      return const SizedBox(
        height: 165,
        child: Center(
          child: CircularProgressIndicator(color: HomeScreen.nupeGreen),
        ),
      );
    }

    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: latestSongs.length,
        itemBuilder: (context, index) {
          final song = latestSongs[index];
          return GestureDetector(
            onTap: () {
              player.playSong(song, latestSongs);
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const PlayerScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOutQuad;
                        var tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                ),
              );
            },
            child: Container(
              width: 145,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(2, 4),
                  ),
                ],
                image: DecorationImage(
                  image: song.artworkPath != null
                      ? (song.artworkPath!.startsWith('http')
                          ? NetworkImage(song.artworkPath!)
                          : AssetImage(song.artworkPath!) as ImageProvider)
                      : const AssetImage('assets/images/chill_mix_bg.png') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            song.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 36.0),
                            child: Text(
                              song.artist,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 10.5,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Floating circular Play button (Bottom-right)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          player.playSong(song, latestSongs);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.55),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------
// TAB 1: INTERACTIVE SEARCH VIEW
// --------------------------------------------------
class _SearchTabView extends StatefulWidget {
  const _SearchTabView();

  @override
  State<_SearchTabView> createState() => _SearchTabViewState();
}

class _SearchTabViewState extends State<_SearchTabView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = "";
  String _selectedFilter = "All";

  final List<String> _filters = const ["All", "Songs", "Albums", "Artists"];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildAlbumCategoryCard(AlbumModel album, int index, Color textColor) {
    final List<List<Color>> gradientPresets = const [
      [HomeScreen.nupeBlue, HomeScreen.nupeGreen],
      [HomeScreen.nupeGreen, HomeScreen.nupeRed],
      [HomeScreen.nupeRed, HomeScreen.nupeBlue],
      [HomeScreen.nupeBlue, Color(0xFF1A33FF)], // Shade of blue
      [HomeScreen.nupeGreen, Color(0xFF4BB543)], // Shade of green
      [HomeScreen.nupeRed, Color(0xFFFF4D4D)], // Shade of red
    ];
    
    final colors = gradientPresets[index % gradientPresets.length];

    return GestureDetector(
      onTap: () {
        _searchController.text = album.name;
        _focusNode.requestFocus();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              bottom: 16,
              left: 16,
              right: 50,
              child: Text(
                album.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              bottom: -15,
              right: -15,
              child: Transform.rotate(
                angle: 0.4,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: album.artworkPath != null && album.artworkPath!.isNotEmpty
                        ? (album.artworkPath!.startsWith('http')
                            ? Image.network(album.artworkPath!, fit: BoxFit.cover)
                            : Image.asset(album.artworkPath!, fit: BoxFit.cover))
                        : const Icon(Icons.album_rounded, size: 40, color: Colors.white24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAllTap, required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAllTap != null)
            GestureDetector(
              onTap: onSeeAllTap,
              child: Text(
                "See All",
                style: TextStyle(
                  color: HomeScreen.nupeGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArtistTile(
    ArtistModel artist,
    MusicController musicController,
    PlayerController playerController,
    Color textColor,
    Color subtitleColor,
    Color coverBgColor,
    bool isDark,
  ) {
    final artistSongs = musicController.songs.where((s) => artist.songIds.contains(s.id)).toList();

    return InkWell(
      onTap: () {
        _showArtistSongsBottomSheet(context, artist, artistSongs, playerController);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                width: 50,
                height: 50,
                color: coverBgColor,
                child: artist.imagePath != null && artist.imagePath!.isNotEmpty
                    ? (artist.imagePath!.startsWith('http')
                        ? Image.network(artist.imagePath!, fit: BoxFit.cover)
                        : Image.asset(artist.imagePath!, fit: BoxFit.cover))
                    : const Icon(Icons.person_rounded, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${artistSongs.length} songs",
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumListTile(
    AlbumModel album,
    MusicController musicController,
    PlayerController playerController,
    Color textColor,
    Color subtitleColor,
    Color coverBgColor,
    bool isDark,
  ) {
    final albumSongs = musicController.songs.where((s) => album.songIds.contains(s.id)).toList();

    return InkWell(
      onTap: () {
        _showAlbumSongsBottomSheet(context, album, albumSongs, playerController);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 50,
                height: 50,
                color: coverBgColor,
                child: album.artworkPath != null && album.artworkPath!.isNotEmpty
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
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${album.artist} • ${albumSongs.length} songs",
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicController = context.watch<MusicController>();
    final playerController = context.watch<PlayerController>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF6B728E);
    final coverBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9);
    final searchBgColor = isDark ? const Color(0xFF151518) : Colors.white;
    final searchBorder = isDark ? null : Border.all(color: Colors.black.withValues(alpha: 0.05));
    final searchShadow = isDark ? null : [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
    final searchIconColor = isDark ? Colors.white30 : Colors.black38;
    final searchHintColor = isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black38;

    // Filter results
    final query = _searchQuery.trim().toLowerCase();
    final List<SongModel> filteredSongs = musicController.songs.where((song) =>
        song.title.toLowerCase().contains(query) ||
        song.artist.toLowerCase().contains(query) ||
        song.album.toLowerCase().contains(query)).toList();

    final List<AlbumModel> filteredAlbums = musicController.albums.where((album) =>
        album.name.toLowerCase().contains(query) ||
        album.artist.toLowerCase().contains(query)).toList();

    final List<ArtistModel> filteredArtists = musicController.artists.where((artist) =>
        artist.name.toLowerCase().contains(query)).toList();

    final bool hasResults = filteredSongs.isNotEmpty || filteredAlbums.isNotEmpty || filteredArtists.isNotEmpty;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Title and Search Bar Header
        SliverPadding(
          padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 10),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                "Search",
                style: TextStyle(
                  color: textColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Search Input Box
              Container(
                decoration: BoxDecoration(
                  color: searchBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: searchBorder,
                  boxShadow: searchShadow,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: InputDecoration(
                    icon: Icon(Icons.search_rounded, color: searchIconColor),
                    hintText: "Search songs, artists, albums...",
                    hintStyle: TextStyle(color: searchHintColor),
                    border: InputBorder.none,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: textColor.withValues(alpha: 0.6), size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _focusNode.unfocus();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Horizontal Filter Chips
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? HomeScreen.nupeGreen
                                : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),

        // Body Content
        if (_searchQuery.isEmpty) ...[
          // BROWSE CATEGORIES
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  "Browse All",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final album = musicController.albums[index];
                  return _buildAlbumCategoryCard(album, index, textColor);
                },
                childCount: musicController.albums.length,
              ),
            ),
          ),
        ] else if (!hasResults) ...[
          // NO RESULTS FOUND
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 80,
                  color: textColor.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 16),
                Text(
                  "No results found",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Check spelling or try search terms",
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // RESULTS LIST
          if (_selectedFilter == "All") ...[
            // Songs segment
            if (filteredSongs.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  "Songs",
                  textColor: textColor,
                  onSeeAllTap: () => setState(() => _selectedFilter = "Songs"),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = filteredSongs[index];
                    return SongTile(
                      song: song,
                      onTap: () {
                        playerController.playSong(song, filteredSongs);
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(0.0, 1.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOutQuad;
                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                              return SlideTransition(position: animation.drive(tween), child: child);
                            },
                          ),
                        );
                      },
                    );
                  },
                  childCount: filteredSongs.length > 5 ? 5 : filteredSongs.length,
                ),
              ),
            ],

            // Albums segment
            if (filteredAlbums.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: const SizedBox(height: 16),
              ),
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  "Albums",
                  textColor: textColor,
                  onSeeAllTap: () => setState(() => _selectedFilter = "Albums"),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 20),
                    itemCount: filteredAlbums.length,
                    itemBuilder: (context, index) {
                      final album = filteredAlbums[index];
                      final albumSongs = musicController.songs.where((s) => album.songIds.contains(s.id)).toList();
                      return AlbumCard(
                        album: album,
                        onTap: () {
                          _showAlbumSongsBottomSheet(context, album, albumSongs, playerController);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],

            // Artists segment
            if (filteredArtists.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: const SizedBox(height: 16),
              ),
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  "Artists",
                  textColor: textColor,
                  onSeeAllTap: () => setState(() => _selectedFilter = "Artists"),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final artist = filteredArtists[index];
                    return _buildArtistTile(
                      artist,
                      musicController,
                      playerController,
                      textColor,
                      subtitleColor,
                      coverBgColor,
                      isDark,
                    );
                  },
                  childCount: filteredArtists.length > 5 ? 5 : filteredArtists.length,
                ),
              ),
            ],
          ] else if (_selectedFilter == "Songs") ...[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = filteredSongs[index];
                  return SongTile(
                    song: song,
                    onTap: () {
                      playerController.playSong(song, filteredSongs);
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOutQuad;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            return SlideTransition(position: animation.drive(tween), child: child);
                          },
                        ),
                      );
                    },
                  );
                },
                childCount: filteredSongs.length,
              ),
            ),
          ] else if (_selectedFilter == "Albums") ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final album = filteredAlbums[index];
                    return _buildAlbumListTile(
                      album,
                      musicController,
                      playerController,
                      textColor,
                      subtitleColor,
                      coverBgColor,
                      isDark,
                    );
                  },
                  childCount: filteredAlbums.length,
                ),
              ),
            ),
          ] else if (_selectedFilter == "Artists") ...[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final artist = filteredArtists[index];
                  return _buildArtistTile(
                    artist,
                    musicController,
                    playerController,
                    textColor,
                    subtitleColor,
                    coverBgColor,
                    isDark,
                  );
                },
                childCount: filteredArtists.length,
              ),
            ),
          ],
        ],

        // Spacer to push content above floating mini player
        const SliverToBoxAdapter(
          child: SizedBox(height: 180),
        ),
      ],
    );
  }
}

class BrowseCategory {
  final String title;
  final String query;
  final List<Color> colors;

  const BrowseCategory({
    required this.title,
    required this.query,
    required this.colors,
  });
}

// ----------------------------------------------------
// TAB 2: MOCK LIBRARY VIEW
// ----------------------------------------------------
class _LibraryTabView extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final int initialSubTab;
  const _LibraryTabView({this.onProfileTap, this.initialSubTab = 0});

  @override
  State<_LibraryTabView> createState() => _LibraryTabViewState();
}

class _LibraryTabViewState extends State<_LibraryTabView> {
  int _activeSubTab = 0;

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.initialSubTab;
  }

  @override
  void didUpdateWidget(covariant _LibraryTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubTab != oldWidget.initialSubTab) {
      setState(() {
        _activeSubTab = widget.initialSubTab;
      });
    }
  }

  // Playlists are fetched live from PlaylistController — no hardcoded list needed.

  @override
  Widget build(BuildContext context) {
    final musicController = context.watch<MusicController>();
    final playerController = context.watch<PlayerController>();
    final authController = context.watch<AuthController>();
    final playlistController = context.watch<PlaylistController>();
    final realPlaylists = playlistController.playlists;
    final isGuest = authController.isGuest;
    // For guests: always show Downloads sub-tab (index 4)
    final effectiveSubTab = isGuest ? 4 : _activeSubTab;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
    final backgroundColor = isDark
        ? const Color(0xFF08080A)
        : const Color(0xFFF6F8FD);
    final coverBgColor = isDark
        ? const Color(0xFF1E1E22)
        : const Color(0xFFEFF2F9);

    return RefreshIndicator(
      color: HomeScreen.nupeGreen,
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      onRefresh: () async {
        await Future.wait([
          context.read<PlaylistController>().loadPlaylists(),
          context.read<MusicController>().loadMusic(),
        ]);
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(
            top: 60,
            left: 20,
            right: 20,
            bottom: 10,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Title & Avatar Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Library",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: coverBgColor,
                            border: Border.all(
                              color: HomeScreen.nupeGreen.withValues(
                                alpha: 0.3,
                              ),
                              width: 1.5,
                            ),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/avatar.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  HomeScreen.nupeRed, // Active notification dot
                              border: Border.all(
                                color: backgroundColor,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sub-navigation bar (hidden for guests)
              if (!isGuest) _buildSubTabBar(),
              if (!isGuest) const SizedBox(height: 20),

              // Create New Playlist Card (Only show if Playlists sub-tab is selected, and not a guest)
              if (!isGuest && effectiveSubTab == 0) ...[
                _buildCreatePlaylistTile(),
                const SizedBox(height: 24),
              ],

              // Dynamic Library Section Header
              _buildLibrarySectionHeaderForTab(effectiveSubTab),
              const SizedBox(height: 12),
            ]),
          ),
        ),

        // Vertical List depending on active sub-tab
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final activeSubTab = effectiveSubTab;
              if (activeSubTab == 0) {
                return _buildPlaylistTile(realPlaylists[index]);
              } else if (activeSubTab == 1) {
                final song = musicController.songs[index];
                return SongTile(
                  song: song,
                  onTap: () {
                    playerController.playSong(song, musicController.songs);
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const PlayerScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOutQuad;
                          var tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                );
              } else if (activeSubTab == 2) {
                final album = musicController.albums[index];
                return _buildLibraryAlbumTile(album, musicController, playerController);
              } else if (activeSubTab == 3) {
                final artist = musicController.artists[index];
                return _buildArtistTile(artist, musicController, playerController);
              } else if (activeSubTab == 4) {
                // Downloads: show only downloaded songs
                final downloadedSongs = musicController.songs.where((s) => musicController.downloadedSongIds.contains(s.id)).toList();
                if (downloadedSongs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.download_for_offline_rounded,
                            size: 64,
                            color: textColor.withValues(alpha: 0.15),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No Downloaded Tracks",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Your downloaded music will appear here.",
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final song = downloadedSongs[index];
                return SongTile(
                  song: song,
                  onTap: () {
                    playerController.playSong(song, downloadedSongs);
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const PlayerScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOutQuad;
                          var tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                );
              } else {
                // Favorites sub-tab
                final favSongs = musicController.songs.where((s) => s.isFavorite).toList();
                if (favSongs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        "No favorite songs yet.",
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ),
                  );
                }
                final song = favSongs[index];
                return SongTile(
                  song: song,
                  onTap: () {
                    playerController.playSong(song, favSongs);
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const PlayerScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOutQuad;
                          var tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                );
              }
            }, childCount: _getSubTabCount(musicController, effectiveSubTab)),
          ),
        ),

        // Recently Played Header & Horizontal Carousel (Only for authenticated users on Playlists tab)
        if (!isGuest && effectiveSubTab == 0)
          SliverPadding(
            padding: const EdgeInsets.only(
              top: 28,
              left: 20,
              right: 20,
              bottom: 180,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildRecentlyPlayedHeader(),
                const SizedBox(height: 14),
                _buildRecentlyPlayedRow(musicController, playerController),
              ]),
            ),
          )
        else
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 180),
          ),
      ],
    ),
  );
}

  Widget _buildSubTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF757A90);

    final tabs = ["Playlists", "Songs", "Albums", "Artists", "Downloads", "Favorites"];
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isActive = _activeSubTab == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeSubTab = index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tabs[index],
                    style: TextStyle(
                      color: isActive ? textColor : subtitleColor,
                      fontSize: 15,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isActive)
                    Container(
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        color: HomeScreen.nupeGreen,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
    final cardColor = isDark ? const Color(0xFF141416) : Colors.white;

    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Create New Playlist",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: TextStyle(color: textColor),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Playlist Name",
                    labelStyle: TextStyle(color: subtitleColor),
                    hintText: "Enter name (e.g. My Favorites)",
                    hintStyle: TextStyle(color: subtitleColor.withValues(alpha: 0.5)),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: HomeScreen.nupeGreen, width: 2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Playlist name is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: "Description (Optional)",
                    labelStyle: TextStyle(color: subtitleColor),
                    hintText: "Enter a brief description",
                    hintStyle: TextStyle(color: subtitleColor.withValues(alpha: 0.5)),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: HomeScreen.nupeGreen, width: 2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final name = nameController.text.trim();
                  final desc = descController.text.trim();
                  
                  context.read<PlaylistController>().createPlaylist(
                    name,
                    desc.isEmpty ? null : desc,
                  );
                  
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Playlist '$name' created!"),
                      backgroundColor: HomeScreen.nupeGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text(
                "Create",
                style: TextStyle(
                  color: HomeScreen.nupeGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreatePlaylistTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBgColor = isDark ? const Color(0xFF141416) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.04);
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
    final arrowColor = isDark ? Colors.white24 : Colors.black26;

    return InkWell(
      onTap: () => _showCreatePlaylistDialog(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: containerBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: HomeScreen.nupeBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: HomeScreen.nupeGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create New Playlist",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Build your own playlist",
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: arrowColor, size: 14),
          ],
        ),
      ),
    );
  }

  int _getSubTabCount(MusicController musicController, int tabIndex) {
    final playlistController = context.read<PlaylistController>();
    if (tabIndex == 0) return playlistController.playlists.length;
    if (tabIndex == 1) return musicController.songs.length;
    if (tabIndex == 2) return musicController.albums.length;
    if (tabIndex == 3) return musicController.artists.length;
    if (tabIndex == 4) {
      final count = musicController.songs.where((s) => musicController.downloadedSongIds.contains(s.id)).length;
      return count == 0 ? 1 : count;
    }
    if (tabIndex == 5) {
      final favCount = musicController.songs.where((s) => s.isFavorite).length;
      return favCount == 0 ? 1 : favCount; // If 0, show a single placeholder tile
    }
    return 1;
  }


  Widget _buildLibrarySectionHeaderForTab(int tabIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    
    String title = "My Playlists";
    if (tabIndex == 1) title = "All Songs";
    if (tabIndex == 2) title = "All Albums";
    if (tabIndex == 3) title = "All Artists";
    if (tabIndex == 4) title = "Downloaded Tracks";
    if (tabIndex == 5) title = "My Favorites";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (tabIndex == 0)
          Row(
            children: [
              const Text(
                "Recently Added",
                style: TextStyle(
                  color: HomeScreen.nupeGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: HomeScreen.nupeGreen.withValues(alpha: 0.8),
                size: 16,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLibraryAlbumTile(
    AlbumModel album,
    MusicController musicController,
    PlayerController playerController,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
    final coverBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9);

    final albumSongs = musicController.songs.where((s) => album.songIds.contains(s.id)).toList();

    return InkWell(
      onTap: () {
        _showAlbumSongsBottomSheet(context, album, albumSongs, playerController);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 58,
                height: 58,
                color: coverBgColor,
                child: album.artworkPath != null
                    ? (album.artworkPath!.startsWith('http')
                        ? Image.network(album.artworkPath!, fit: BoxFit.cover)
                        : Image.asset(album.artworkPath!, fit: BoxFit.cover))
                    : const Icon(Icons.album_rounded, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${album.artist} • ${albumSongs.length} songs",
                    style: TextStyle(color: subtitleColor, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistTile(
    ArtistModel artist,
    MusicController musicController,
    PlayerController playerController,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
    final coverBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9);

    final artistSongs = musicController.songs.where((s) => artist.songIds.contains(s.id)).toList();

    return InkWell(
      onTap: () {
        _showArtistSongsBottomSheet(context, artist, artistSongs, playerController);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Circular Artist Avatar
            ClipOval(
              child: Container(
                width: 58,
                height: 58,
                color: coverBgColor,
                child: artist.imagePath != null
                    ? (artist.imagePath!.startsWith('http')
                        ? Image.network(artist.imagePath!, fit: BoxFit.cover)
                        : Image.asset(artist.imagePath!, fit: BoxFit.cover))
                    : const Icon(Icons.person_rounded, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${artistSongs.length} songs",
                    style: TextStyle(color: subtitleColor, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistTile(PlaylistModel playlist) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
    final coverBgColor = isDark
        ? const Color(0xFF1E1E22)
        : const Color(0xFFEFF2F9);
    final arrowColor = isDark ? Colors.white38 : Colors.black45;

    final isFavorites = playlist.name.toLowerCase().contains('favorite');
    final songCount = playlist.songIds.length;
    final songLabel = songCount == 1 ? '1 song' : '$songCount songs';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Cover Art
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 58,
              height: 58,
              color: coverBgColor,
              child: isFavorites
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7A1CA8), Color(0xFF1B072B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    )
                  : (playlist.artworkPath != null && playlist.artworkPath!.isNotEmpty
                      ? (playlist.artworkPath!.startsWith('http')
                          ? Image.network(playlist.artworkPath!, fit: BoxFit.cover,
                              errorBuilder: (ctx, err, _) => Icon(Icons.queue_music_rounded, color: subtitleColor, size: 28))
                          : Image.asset(playlist.artworkPath!, fit: BoxFit.cover,
                              errorBuilder: (ctx, err, _) => Icon(Icons.queue_music_rounded, color: subtitleColor, size: 28)))
                      : Icon(Icons.queue_music_rounded, color: subtitleColor, size: 28)),
            ),
          ),
          const SizedBox(width: 16),
          // Title & Song Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  songLabel,
                  style: TextStyle(color: subtitleColor, fontSize: 12.5),
                ),
              ],
            ),
          ),
          // More Action
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: arrowColor, size: 20),
            onPressed: () => _showPlaylistOptions(playlist, isFavorites),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(PlaylistModel playlist, bool isFavorites) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF141416) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF6B728E);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Playlist name header
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9),
                        child: isFavorites
                            ? Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF7A1CA8), Color(0xFF1B072B)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                              )
                            : Icon(Icons.queue_music_rounded, color: subtitleColor, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(playlist.name,
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                          Text('${playlist.songIds.length} songs',
                              style: TextStyle(color: subtitleColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 8),
                // Options
                if (!isFavorites)
                  _sheetOption(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete Playlist',
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDeletePlaylist(playlist);
                    },
                  ),
                _sheetOption(
                  icon: Icons.playlist_remove_rounded,
                  label: 'Clear Playlist',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmClearPlaylist(playlist);
                  },
                ),
                _sheetOption(
                  icon: Icons.close_rounded,
                  label: 'Cancel',
                  color: subtitleColor,
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.w500)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
      onTap: onTap,
    );
  }

  void _confirmDeletePlaylist(PlaylistModel playlist) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Playlist?',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0C1026),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        content: Text(
          '"${playlist.name}" will be permanently deleted.',
          style: TextStyle(
            color: isDark ? Colors.white54 : const Color(0xFF6B728E),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: HomeScreen.nupeGreen)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PlaylistController>().deletePlaylist(playlist.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmClearPlaylist(PlaylistModel playlist) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear Playlist?',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0C1026),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        content: Text(
          '"${playlist.name}" songs will be removed. The playlist itself will remain.',
          style: TextStyle(
            color: isDark ? Colors.white54 : const Color(0xFF6B728E),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: HomeScreen.nupeGreen)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PlaylistController>().clearPlaylist(playlist.id);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }



  Widget _buildRecentlyPlayedHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Recently Played",
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("All recently played history loaded."),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Row(
            children: [
              const Text(
                "See all",
                style: TextStyle(
                  color: HomeScreen.nupeGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: HomeScreen.nupeGreen.withValues(alpha: 0.8),
                size: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyPlayedRow(
    MusicController musicController,
    PlayerController playerController,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coverBgColor = isDark
        ? const Color(0xFF1E1E22)
        : const Color(0xFFEFF2F9);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);

    final recentSongs = playerController.recentlyPlayed.isNotEmpty
        ? playerController.recentlyPlayed
        : musicController.latestSongs;

    if (recentSongs.isEmpty) {
      return SizedBox(
        height: 90,
        child: Center(
          child: Text(
            "No songs played yet",
            style: TextStyle(color: subtitleColor, fontSize: 14),
          ),
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: recentSongs.length,
        itemBuilder: (context, index) {
          final song = recentSongs[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                playerController.playSong(song, recentSongs);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      color: coverBgColor,
                      child: song.artworkPath != null && song.artworkPath!.isNotEmpty
                          ? (song.artworkPath!.startsWith('http')
                              ? Image.network(
                                  song.artworkPath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, _) => Icon(
                                    Icons.music_note_rounded,
                                    color: subtitleColor,
                                    size: 36,
                                  ),
                                )
                              : Image.asset(
                                  song.artworkPath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, _) => Icon(
                                    Icons.music_note_rounded,
                                    color: subtitleColor,
                                    size: 36,
                                  ),
                                ))
                          : Icon(Icons.music_note_rounded, color: subtitleColor, size: 36),
                    ),
                    // Gradient overlay for title
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------
// TAB 4: PROFILE / SETTINGS VIEW (MAPPED TO SETTINGS)
// ----------------------------------------------------
class _ProfileTabView extends StatelessWidget {
  const _ProfileTabView();

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: HomeScreen.nupeGreen,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.04),
            height: 1,
            indent: 54,
          ),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141416) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(children: dividedChildren),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
    final defaultIconColor = isDark ? Colors.white70 : const Color(0xFF33374B);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? defaultIconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountProfileTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
    final arrowColor = isDark ? Colors.white24 : Colors.black26;
    final authController = context.watch<AuthController>();

    String name = authController.isAuthenticated
        ? (authController.userName ?? "Nupe User")
        : "Guest User";

    if (authController.isAuthenticated && name.contains('@')) {
      final namePart = name.split('@')[0];
      name = namePart[0].toUpperCase() + namePart.substring(1);
    }

    final String email = authController.isAuthenticated
        ? (authController.userEmail ?? "")
        : "Tap to login or register";

    return InkWell(
      onTap: () {
        if (!authController.isAuthenticated) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
              title: Text(
                "Profile Photo",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/avatar.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      color: HomeScreen.nupeGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/avatar.png'),
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
                    name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: arrowColor, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
    final arrowColor = isDark ? Colors.white24 : Colors.black26;

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            const Icon(
              Icons.stars_rounded,
              color: HomeScreen.nupeRed,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Go Premium",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Unlock ad-free music experience",
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: HomeScreen.nupeBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "PREMIUM",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: arrowColor,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytesToGB(int bytes) {
    if (bytes <= 0) return "0.0 GB";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
  }

  void _showNotificationsBottomSheet(
    BuildContext context,
    SettingsController settings,
    bool isDark,
    Color textColor,
    Color subtitleColor,
  ) {
    // Mark notifications read
    settings.markNotificationsRead();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 450,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    "Notifications",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        _buildNotificationItem(
                          icon: Icons.notifications_active_rounded,
                          title: "Welcome to Nupe Songs!",
                          subtitle: "Enjoy the ultimate premium music experience preserving Nupe heritage.",
                          time: "Just now",
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        _buildNotificationItem(
                          icon: Icons.sync_rounded,
                          title: "Django Backend Connected",
                          subtitle: "Real-time synchronization loaded 5 songs, 3 albums, and 4 artists.",
                          time: "10 mins ago",
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        _buildNotificationItem(
                          icon: Icons.equalizer_rounded,
                          title: "Audio Equalizer Ready",
                          subtitle: "Try Rock, Pop, or Hip Hop equalizer presets under Playback settings.",
                          time: "2 hours ago",
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        _buildNotificationItem(
                          icon: Icons.system_update_rounded,
                          title: "App Updated: v1.0.1",
                          subtitle: "Sleep timer now shuts down the application completely when it ends.",
                          time: "Yesterday",
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: HomeScreen.nupeGreen.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: HomeScreen.nupeGreen, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: subtitleColor, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(color: subtitleColor.withValues(alpha: 0.6), fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showDownloadQualityBottomSheet(
    BuildContext context,
    SettingsController settings,
    bool isDark,
    Color textColor,
    Color subtitleColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Consumer<SettingsController>(
              builder: (context, settingsCtrl, _) {
                final sheetIconColor = isDark ? Colors.white70 : const Color(0xFF33374B);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      "Download Quality",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.high_quality_rounded, color: settingsCtrl.downloadQuality == 'High' ? HomeScreen.nupeGreen : sheetIconColor),
                      title: Text("High", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text("Highest audio fidelity (320kbps)", style: TextStyle(color: subtitleColor, fontSize: 12)),
                      trailing: settingsCtrl.downloadQuality == 'High'
                          ? const Icon(Icons.check_circle_rounded, color: HomeScreen.nupeGreen)
                          : null,
                      onTap: () {
                        settingsCtrl.setDownloadQuality("High");
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.branding_watermark_rounded, color: settingsCtrl.downloadQuality == 'Medium' ? HomeScreen.nupeGreen : sheetIconColor),
                      title: Text("Medium", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text("Standard audio quality (192kbps)", style: TextStyle(color: subtitleColor, fontSize: 12)),
                      trailing: settingsCtrl.downloadQuality == 'Medium'
                          ? const Icon(Icons.check_circle_rounded, color: HomeScreen.nupeGreen)
                          : null,
                      onTap: () {
                        settingsCtrl.setDownloadQuality("Medium");
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.network_check_rounded, color: settingsCtrl.downloadQuality == 'Low' ? HomeScreen.nupeGreen : sheetIconColor),
                      title: Text("Low", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text("Data saver quality (96kbps)", style: TextStyle(color: subtitleColor, fontSize: 12)),
                      trailing: settingsCtrl.downloadQuality == 'Low'
                          ? const Icon(Icons.check_circle_rounded, color: HomeScreen.nupeGreen)
                          : null,
                      onTap: () {
                        settingsCtrl.setDownloadQuality("Low");
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showDownloadLocationBottomSheet(
    BuildContext context,
    SettingsController settings,
    bool isDark,
    Color textColor,
    Color subtitleColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Consumer<SettingsController>(
              builder: (context, settingsCtrl, _) {
                final sheetIconColor = isDark ? Colors.white70 : const Color(0xFF33374B);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      "Download Location",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.phone_android_rounded, color: settingsCtrl.downloadLocation == 'Internal Storage/Music' ? HomeScreen.nupeGreen : sheetIconColor),
                      title: Text("Internal Storage", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text("Internal Storage/Music", style: TextStyle(color: subtitleColor, fontSize: 12)),
                      trailing: settingsCtrl.downloadLocation == 'Internal Storage/Music'
                          ? const Icon(Icons.check_circle_rounded, color: HomeScreen.nupeGreen)
                          : null,
                      onTap: () {
                        settingsCtrl.setDownloadLocation("Internal Storage/Music");
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.sd_storage_rounded, color: settingsCtrl.downloadLocation == 'SD Card/Music' ? HomeScreen.nupeGreen : sheetIconColor),
                      title: Text("SD Card", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text("SD Card/Music", style: TextStyle(color: subtitleColor, fontSize: 12)),
                      trailing: settingsCtrl.downloadLocation == 'SD Card/Music'
                          ? const Icon(Icons.check_circle_rounded, color: HomeScreen.nupeGreen)
                          : null,
                      onTap: () {
                        settingsCtrl.setDownloadLocation("SD Card/Music");
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showManageDownloadsBottomSheet(
    BuildContext context,
    SettingsController settings,
    bool isDark,
    Color textColor,
    Color subtitleColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Consumer<SettingsController>(
              builder: (context, settingsCtrl, _) {
                final sizeStr = _formatBytesToGB(settingsCtrl.downloadedBytes);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      "Manage Downloads",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Storage Used: $sizeStr",
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                      title: const Text("Clear Downloaded Cache", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      subtitle: Text("Permanently delete all offline music assets", style: TextStyle(color: subtitleColor, fontSize: 12)),
                      onTap: () {
                        settingsCtrl.clearDownloads();
                        context.read<MusicController>().clearDownloadedSongIds();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: HomeScreen.nupeGreen,
                            content: const Text(
                              "Downloads cleared successfully",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final authController = context.watch<AuthController>();
    final playerController = context.watch<PlayerController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
    final arrowColor = isDark ? Colors.white24 : Colors.black26;
    final backgroundColor = isDark
        ? const Color(0xFF08080A)
        : const Color(0xFFF6F8FD);

    final String name = authController.isAuthenticated
        ? (authController.userName ?? "Nupe User")
        : "Guest User";
    final String email = authController.isAuthenticated
        ? (authController.userEmail ?? "")
        : "Tap to login or register";

    return RefreshIndicator(
      color: HomeScreen.nupeGreen,
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      onRefresh: () async {
        await authController.tryAutoLogin();
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(
            top: 60,
            left: 20,
            right: 20,
            bottom: 10,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Title & Avatar Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Settings",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Notifications Button
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.notifications_rounded,
                              color: isDark ? Colors.white70 : const Color(0xFF33374B),
                              size: 26,
                            ),
                            onPressed: () {
                              _showNotificationsBottomSheet(context, settings, isDark, textColor, subtitleColor);
                            },
                          ),
                          if (settings.hasUnreadNotifications)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: HomeScreen.nupeRed,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (!authController.isAuthenticated) {
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 600),
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: isDark
                                    ? const Color(0xFF141416)
                                    : Colors.white,
                                title: Text(
                                  "Profile Photo",
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipOval(
                                      child: Image.asset(
                                        'assets/images/avatar.png',
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text(
                                      "Close",
                                      style: TextStyle(
                                        color: HomeScreen.nupeGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF1E1E22)
                                    : const Color(0xFFEFF2F9),
                                border: Border.all(
                                  color: HomeScreen.nupeGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1.5,
                                ),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/avatar.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (settings.hasUnreadNotifications)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: HomeScreen.nupeRed,
                                    border: Border.all(
                                      color: backgroundColor,
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Category 1: Account
              _buildSectionHeader(context, "Account"),
              _buildSectionContainer(
                context,
                children: [
                  _buildAccountProfileTile(context),
                  _buildPremiumTile(context),
                  _buildSettingsTile(
                    context,
                    icon: authController.isAuthenticated ? Icons.logout_rounded : Icons.login_rounded,
                    iconColor: authController.isAuthenticated ? HomeScreen.nupeRed : HomeScreen.nupeGreen,
                    title: authController.isAuthenticated ? "Sign Out" : "Login / Register",
                    subtitle: authController.isAuthenticated ? "Log out of your account" : "Sync playlists and favorites",
                    onTap: () {
                      if (authController.isAuthenticated) {
                        authController.logout();
                      }
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 600),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category 2: Playback
              _buildSectionHeader(context, "Playback"),
              _buildSectionContainer(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.graphic_eq_rounded,
                    title: "Audio Quality",
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settings.audioQuality,
                          style: TextStyle(color: subtitleColor, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: arrowColor,
                          size: 14,
                        ),
                      ],
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) {
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Consumer<SettingsController>(
                                builder: (context, settingsCtrl, _) {
                                  final sheetIconColor = isDark ? Colors.white70 : const Color(0xFF33374B);
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 4,
                                        margin: const EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white24 : Colors.black12,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      Text(
                                        "Audio Quality",
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ListTile(
                                        leading: Icon(Icons.high_quality_rounded, color: settingsCtrl.audioQuality == 'High' ? HomeScreen.nupeGreen : sheetIconColor),
                                        title: Text("High", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                        subtitle: Text("Highest audio fidelity (320kbps)", style: TextStyle(color: subtitleColor, fontSize: 12)),
                                        trailing: settingsCtrl.audioQuality == 'High'
                                            ? const Icon(Icons.check_circle_rounded, color: HomeScreen.nupeGreen)
                                            : null,
                                        onTap: () {
                                          settingsCtrl.setAudioQuality("High");
                                          Navigator.pop(context);
                                        },
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.branding_watermark_rounded, color: settingsCtrl.audioQuality == 'Medium' ? HomeScreen.nupeGreen : sheetIconColor),
                                        title: Text("Medium", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                        subtitle: Text("Standard audio quality (192kbps)", style: TextStyle(color: subtitleColor, fontSize: 12)),
                                        trailing: settingsCtrl.audioQuality == 'Medium'
                                            ? const Icon(Icons.check_circle_rounded, color: HomeScreen.nupeGreen)
                                            : null,
                                        onTap: () {
                                          settingsCtrl.setAudioQuality("Medium");
                                          Navigator.pop(context);
                                        },
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.network_check_rounded, color: settingsCtrl.audioQuality == 'Low' ? HomeScreen.nupeGreen : sheetIconColor),
                                        title: Text("Low", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                        subtitle: Text("Data saver quality (96kbps)", style: TextStyle(color: subtitleColor, fontSize: 12)),
                                        trailing: settingsCtrl.audioQuality == 'Low'
                                            ? const Icon(Icons.check_circle_rounded, color: HomeScreen.nupeGreen)
                                            : null,
                                        onTap: () {
                                          settingsCtrl.setAudioQuality("Low");
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.tune_rounded,
                    title: "Equalizer",
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settings.useEqualizer ? settings.equalizerPreset : "Off",
                          style: TextStyle(
                            color: settings.useEqualizer ? HomeScreen.nupeGreen : subtitleColor,
                            fontWeight: settings.useEqualizer ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: arrowColor,
                          size: 14,
                        ),
                      ],
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) {
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Consumer<SettingsController>(
                                builder: (context, settingsCtrl, _) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 4,
                                        margin: const EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white24 : Colors.black12,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      Text(
                                        "Equalizer",
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SwitchListTile.adaptive(
                                        activeTrackColor: HomeScreen.nupeGreen,
                                        title: Text(
                                          "Enable Equalizer",
                                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          "Apply custom sound preset profiles",
                                          style: TextStyle(color: subtitleColor, fontSize: 12),
                                        ),
                                        value: settingsCtrl.useEqualizer,
                                        onChanged: (val) {
                                          settingsCtrl.toggleEqualizer(val);
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: GridView.count(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: 2.2,
                                          children: [
                                            "Normal", "Pop", "Rock", "Jazz", "Classical", "Hip Hop"
                                          ].map((preset) {
                                            final isSelected = settingsCtrl.useEqualizer && settingsCtrl.equalizerPreset == preset;
                                            final isEnabled = settingsCtrl.useEqualizer;
                                            
                                            return InkWell(
                                              onTap: isEnabled
                                                  ? () {
                                                      settingsCtrl.setEqualizerPreset(preset);
                                                    }
                                                  : null,
                                              borderRadius: BorderRadius.circular(12),
                                              child: Opacity(
                                                opacity: isEnabled ? 1.0 : 0.4,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? HomeScreen.nupeGreen.withValues(alpha: 0.15)
                                                        : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9)),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? HomeScreen.nupeGreen
                                                          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    preset,
                                                    style: TextStyle(
                                                      color: isSelected ? HomeScreen.nupeGreen : textColor,
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.play_circle_outline_rounded,
                    title: "Playback Options",
                    subtitle: "Shuffle: ${playerController.isShuffle ? 'On' : 'Off'}, Repeat: ${playerController.repeatMode == RepeatMode.off ? 'Off' : playerController.repeatMode == RepeatMode.one ? 'One' : 'All'}${settings.crossfadeSeconds > 0 ? ', Crossfade: ${settings.crossfadeSeconds}s' : ''}",
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: arrowColor,
                      size: 14,
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) {
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Consumer2<SettingsController, PlayerController>(
                                builder: (context, settingsCtrl, playerCtrl, _) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 40,
                                          height: 4,
                                          margin: const EdgeInsets.only(bottom: 20),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white24 : Colors.black12,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          "Playback Options",
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SwitchListTile.adaptive(
                                        activeTrackColor: HomeScreen.nupeGreen,
                                        title: Text("Shuffle", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                        subtitle: Text("Randomize playback order", style: TextStyle(color: subtitleColor, fontSize: 12)),
                                        value: playerCtrl.isShuffle,
                                        onChanged: (val) {
                                          playerCtrl.toggleShuffle();
                                        },
                                      ),
                                      const Divider(height: 24, indent: 16, endIndent: 16),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          "Repeat Mode",
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Row(
                                          children: [
                                            RepeatMode.off,
                                            RepeatMode.all,
                                            RepeatMode.one,
                                          ].map((mode) {
                                            final isSelected = playerCtrl.repeatMode == mode;
                                            final modeText = mode == RepeatMode.off
                                                ? "Off"
                                                : mode == RepeatMode.all
                                                    ? "All"
                                                    : "One";
                                            final modeIcon = mode == RepeatMode.off
                                                ? Icons.repeat_rounded
                                                : mode == RepeatMode.all
                                                    ? Icons.repeat_rounded
                                                    : Icons.repeat_one_rounded;
                                            
                                            return Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: InkWell(
                                                  onTap: () {
                                                    playerCtrl.setRepeatMode(mode);
                                                  },
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? HomeScreen.nupeGreen.withValues(alpha: 0.15)
                                                          : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9)),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? HomeScreen.nupeGreen
                                                            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          modeIcon,
                                                          color: isSelected ? HomeScreen.nupeGreen : textColor.withValues(alpha: 0.7),
                                                          size: 20,
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Text(
                                                          modeText,
                                                          style: TextStyle(
                                                            color: isSelected ? HomeScreen.nupeGreen : textColor,
                                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      const Divider(height: 24, indent: 16, endIndent: 16),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "Crossfade",
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  settingsCtrl.crossfadeSeconds == 0
                                                      ? "Off"
                                                      : "${settingsCtrl.crossfadeSeconds}s",
                                                  style: TextStyle(
                                                    color: settingsCtrl.crossfadeSeconds > 0 ? HomeScreen.nupeGreen : subtitleColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Slider.adaptive(
                                              min: 0.0,
                                              max: 12.0,
                                              divisions: 12,
                                              activeColor: HomeScreen.nupeGreen,
                                              inactiveColor: isDark ? Colors.white10 : Colors.black12,
                                              value: settingsCtrl.crossfadeSeconds.toDouble(),
                                              onChanged: (val) {
                                                settingsCtrl.setCrossfadeSeconds(val.toInt());
                                              },
                                            ),
                                            Text(
                                              "Smoothly fade between tracks to eliminate gaps.",
                                              style: TextStyle(
                                                color: subtitleColor,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.nights_stay_rounded,
                    title: "Sleep Timer",
                    subtitle: "Set a sleep timer",
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settings.isSleepTimerActive
                              ? "${(settings.sleepTimerDuration?.inMinutes ?? 0).toString().padLeft(2, '0')}:${((settings.sleepTimerDuration?.inSeconds ?? 0) % 60).toString().padLeft(2, '0')}"
                              : "Off",
                          style: TextStyle(
                            color: settings.isSleepTimerActive ? HomeScreen.nupeGreen : subtitleColor,
                            fontWeight: settings.isSleepTimerActive ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: arrowColor,
                          size: 14,
                        ),
                      ],
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
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
                                  Text(
                                    "Set Sleep Timer",
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (settings.isSleepTimerActive)
                                    ListTile(
                                      leading: const Icon(Icons.timer_off_rounded, color: Colors.redAccent),
                                      title: const Text("Turn Off Timer", style: TextStyle(color: Colors.redAccent)),
                                      onTap: () {
                                        settings.cancelSleepTimer();
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ...[1, 5, 15, 30, 45, 60].map((minutes) => ListTile(
                                    leading: Icon(Icons.alarm_rounded, color: HomeScreen.nupeGreen),
                                    title: Text("$minutes ${minutes == 1 ? 'Minute' : 'Minutes'}", style: TextStyle(color: textColor)),
                                    onTap: () {
                                      settings.startSleepTimer(Duration(minutes: minutes));
                                      Navigator.pop(context);
                                    },
                                  )),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category 3: Downloads
              _buildSectionHeader(context, "Downloads"),
              _buildSectionContainer(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.download_rounded,
                    title: "Download Quality",
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settings.downloadQuality,
                          style: TextStyle(color: subtitleColor, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: arrowColor,
                          size: 14,
                        ),
                      ],
                    ),
                    onTap: () {
                      _showDownloadQualityBottomSheet(context, settings, isDark, textColor, subtitleColor);
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.wifi_rounded,
                    title: "Download over Wi-Fi only",
                    trailing: Switch(
                      value: settings.downloadOverWifi,
                      onChanged: (val) {
                        settings.toggleDownloadOverWifi(val);
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: HomeScreen.nupeGreen,
                    ),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.folder_open_rounded,
                    title: "Download Location",
                    subtitle: settings.downloadLocation,
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: arrowColor,
                      size: 14,
                    ),
                    onTap: () {
                      _showDownloadLocationBottomSheet(context, settings, isDark, textColor, subtitleColor);
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.storage_rounded,
                    title: "Manage Downloads",
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatBytesToGB(settings.downloadedBytes),
                          style: TextStyle(color: subtitleColor, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: arrowColor,
                          size: 14,
                        ),
                      ],
                    ),
                    onTap: () {
                      _showManageDownloadsBottomSheet(context, settings, isDark, textColor, subtitleColor);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category 4: General
              _buildSectionHeader(context, "General"),
              _buildSectionContainer(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.color_lens_rounded,
                    title: "Dark Mode",
                    trailing: Switch(
                      value: isDark,
                      activeThumbColor: Colors.white,
                      activeTrackColor: HomeScreen.nupeGreen,
                      onChanged: (val) {
                        settings.toggleTheme(val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category 5: About
              _buildSectionHeader(context, "About"),
              _buildSectionContainer(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: "About Nupe Songs",
                    subtitle: "Developer & App Details",
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: arrowColor,
                      size: 14,
                    ),
                    onTap: () => _showAboutAppDialog(context),
                  ),
                ],
              ),
              const SizedBox(
                height: 180,
              ), // Padding above mini player / nav bar
            ]),
          ),
        ),
      ],
    ),
  );
}

  void _showAboutAppDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
    final cardColor = isDark ? const Color(0xFF141416) : Colors.white;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular logo with app branding
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF1E1E22)
                      : const Color(0xFFEFF2F9),
                  border: Border.all(
                    color: HomeScreen.nupeGreen.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/app_logo.jpeg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Nupe Songs",
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Version 1.0.0 (Build 1)",
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                color: isDark ? Colors.white10 : Colors.black12,
                height: 1,
              ),
              const SizedBox(height: 16),
              Text(
                "A premium music player dedicated to preserving and enjoying the rich musical heritage of the Nupe culture, complete with interactive time-synced lyrics and dynamic theme customization.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Developer Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.code_rounded,
                          color: HomeScreen.nupeGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "DEVELOPER DETAILS",
                          style: TextStyle(
                            color: HomeScreen.nupeGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Developed By
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: textColor.withValues(alpha: 0.5),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "Developed by: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontSize: 13,
                                  ),
                                ),
                                TextSpan(
                                  text: "Umar Emifogi",
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.95),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Powered By
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: HomeScreen.nupeGreen.withValues(alpha: 0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "Powered by: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontSize: 13,
                                  ),
                                ),
                                TextSpan(
                                  text: "Nupe Heritage Tech Team",
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.95),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    const SizedBox(height: 16),
                    // Email
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: subtitleColor.withValues(alpha: 0.6),
                          size: 15,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "Email: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: subtitleColor,
                                    fontSize: 12,
                                  ),
                                ),
                                TextSpan(
                                  text: "developer@nupeheritage.com",
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Website
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.language_rounded,
                          color: subtitleColor.withValues(alpha: 0.6),
                          size: 15,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "Website: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: subtitleColor,
                                    fontSize: 12,
                                  ),
                                ),
                                TextSpan(
                                  text: "www.nupeheritage.com",
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Close",
                style: TextStyle(
                  color: HomeScreen.nupeGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

void _showAlbumSongsBottomSheet(
  BuildContext context,
  AlbumModel album,
  List<SongModel> albumSongs,
  PlayerController playerController,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
  final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
  final sheetBgColor = isDark ? const Color(0xFF141416) : Colors.white;
  final coverBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9);

  showModalBottomSheet(
    context: context,
    backgroundColor: sheetBgColor,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SafeArea(
            child: Column(
              children: [
                // Handle
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Album Header Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Album Cover Art
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 70,
                          height: 70,
                          color: coverBgColor,
                          child: album.artworkPath != null && album.artworkPath!.isNotEmpty
                              ? (album.artworkPath!.startsWith('http')
                                  ? Image.network(album.artworkPath!, fit: BoxFit.cover)
                                  : Image.asset(album.artworkPath!, fit: BoxFit.cover))
                              : const Icon(Icons.album_rounded, size: 36),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Album Title & Artist
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.name,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              album.artist,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${albumSongs.length} songs",
                              style: const TextStyle(
                                color: HomeScreen.nupeGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Play All Button
                      if (albumSongs.isNotEmpty)
                        IconButton.filled(
                          onPressed: () {
                            Navigator.pop(context);
                            playerController.playSong(albumSongs.first, albumSongs);
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(0.0, 1.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOutQuad;
                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                  return SlideTransition(position: animation.drive(tween), child: child);
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          style: IconButton.styleFrom(
                            backgroundColor: HomeScreen.nupeGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 0.5),

                // Songs List
                Expanded(
                  child: albumSongs.isEmpty
                      ? Center(
                          child: Text(
                            "No songs in this album",
                            style: TextStyle(color: subtitleColor, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: albumSongs.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final song = albumSongs[index];
                            return SongTile(
                              song: song,
                              onTap: () {
                                Navigator.pop(context);
                                playerController.playSong(song, albumSongs);
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const begin = Offset(0.0, 1.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOutQuad;
                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      return SlideTransition(position: animation.drive(tween), child: child);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showArtistSongsBottomSheet(
  BuildContext context,
  ArtistModel artist,
  List<SongModel> artistSongs,
  PlayerController playerController,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
  final subtitleColor = isDark ? Colors.white38 : const Color(0xFF6B728E);
  final sheetBgColor = isDark ? const Color(0xFF141416) : Colors.white;
  final coverBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEFF2F9);

  showModalBottomSheet(
    context: context,
    backgroundColor: sheetBgColor,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SafeArea(
            child: Column(
              children: [
                // Handle
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Artist Header Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Circular Artist Avatar
                      ClipOval(
                        child: Container(
                          width: 70,
                          height: 70,
                          color: coverBgColor,
                          child: artist.imagePath != null && artist.imagePath!.isNotEmpty
                              ? (artist.imagePath!.startsWith('http')
                                  ? Image.network(artist.imagePath!, fit: BoxFit.cover)
                                  : Image.asset(artist.imagePath!, fit: BoxFit.cover))
                              : const Icon(Icons.person_rounded, size: 36),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Artist Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artist.name,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              artist.bio ?? "Artist",
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${artistSongs.length} songs",
                              style: const TextStyle(
                                color: HomeScreen.nupeBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Play All Button
                      if (artistSongs.isNotEmpty)
                        IconButton.filled(
                          onPressed: () {
                            Navigator.pop(context);
                            playerController.playSong(artistSongs.first, artistSongs);
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(0.0, 1.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOutQuad;
                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                  return SlideTransition(position: animation.drive(tween), child: child);
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          style: IconButton.styleFrom(
                            backgroundColor: HomeScreen.nupeBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 0.5),

                // Songs List
                Expanded(
                  child: artistSongs.isEmpty
                      ? Center(
                          child: Text(
                            "No songs by this artist",
                            style: TextStyle(color: subtitleColor, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: artistSongs.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final song = artistSongs[index];
                            return SongTile(
                              song: song,
                              onTap: () {
                                Navigator.pop(context);
                                playerController.playSong(song, artistSongs);
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const begin = Offset(0.0, 1.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOutQuad;
                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      return SlideTransition(position: animation.drive(tween), child: child);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
