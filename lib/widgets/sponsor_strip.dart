import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class SponsorStrip extends StatefulWidget {
  final List<String> imagePaths;
  final int intervalSeconds;
  final int perScreen;

  const SponsorStrip({
    super.key,
    required this.imagePaths,
    required this.intervalSeconds,
    this.perScreen = 1,
  });

  @override
  State<SponsorStrip> createState() => _SponsorStripState();
}

class _SponsorStripState extends State<SponsorStrip> {
  Timer? _timer;
  int _groupIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant SponsorStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intervalSeconds != widget.intervalSeconds ||
        oldWidget.imagePaths.length != widget.imagePaths.length ||
        oldWidget.perScreen != widget.perScreen) {
      _groupIndex = 0;
      _startTimer();
    }
  }

  List<List<String>> get _groups {
    if (widget.imagePaths.isEmpty) return [];
    final perScreen = widget.perScreen.clamp(1, 6);
    final groups = <List<String>>[];
    for (var i = 0; i < widget.imagePaths.length; i += perScreen) {
      final end = (i + perScreen < widget.imagePaths.length)
          ? i + perScreen
          : widget.imagePaths.length;
      groups.add(widget.imagePaths.sublist(i, end));
    }
    return groups;
  }

  void _startTimer() {
    _timer?.cancel();
    final groups = _groups;
    if (groups.length <= 1) return;
    _timer = Timer.periodic(Duration(seconds: widget.intervalSeconds), (_) {
      if (!mounted) return;
      setState(() {
        _groupIndex = (_groupIndex + 1) % _groups.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    if (groups.isEmpty) {
      return const SizedBox(height: 70);
    }

    final safeIndex = _groupIndex < groups.length ? _groupIndex : 0;
    final currentGroup = groups[safeIndex];

    return SizedBox(
      height: 70,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Row(
          key: ValueKey(currentGroup.join('|')),
          mainAxisAlignment: MainAxisAlignment.center,
          children: currentGroup.map((path) {
            // Expanded garante que cada logo divida o espaço disponível,
            // não importa se são 1 ou 6 ao mesmo tempo.
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Image.file(
                  File(path),
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(height: 70),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
