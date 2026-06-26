import 'package:flutter/material.dart';
import '../../controllers/player_controller.dart';

class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final bool isShuffle;
  final RepeatMode repeatMode;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.isShuffle,
    required this.repeatMode,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onShuffle,
    required this.onRepeat,
  });

  IconData _getRepeatIcon() {
    switch (repeatMode) {
      case RepeatMode.one:
        return Icons.repeat_one;
      case RepeatMode.all:
      default:
        return Icons.repeat;
    }
  }

  Color? _getRepeatColor(BuildContext context) {
    return repeatMode != RepeatMode.off
        ? Theme.of(context).colorScheme.primary
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: isShuffle ? Theme.of(context).colorScheme.primary : null,
          ),
          onPressed: onShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 36),
          onPressed: onPrevious,
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: onPlayPause,
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            size: 40,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 36),
          onPressed: onNext,
        ),
        IconButton(
          icon: Icon(
            _getRepeatIcon(),
            color: _getRepeatColor(context),
          ),
          onPressed: onRepeat,
        ),
      ],
    );
  }
}
