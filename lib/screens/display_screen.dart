import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:window_manager/window_manager.dart';
import '../models/drawn_entry.dart';
import '../widgets/number_display.dart';
import '../widgets/prize_label.dart';
import '../widgets/editing_banner.dart';
import '../widgets/history_strip.dart';
import '../widgets/help_overlay.dart';
import '../widgets/full_history_overlay.dart';
import '../widgets/final_results_overlay.dart';
import '../widgets/live_share_overlay.dart';
import '../widgets/reset_confirm_overlay.dart';
import '../widgets/duplicate_warning_banner.dart';
import '../widgets/sponsor_strip.dart';
import '../widgets/sponsor_config_overlay.dart';
import '../widgets/dev_credit.dart';
import '../services/sponsor_storage.dart';
import '../services/theme_storage.dart';
import '../services/entries_storage.dart';
import '../services/live_share_firebase.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  static const int _maxDigits = 5; // permite até 99999
  static const Duration _cursorHideDelay = Duration(seconds: 3);

  final FocusNode _focusNode = FocusNode();

  // Lista única de sorteios, mais recente primeiro.
  // O item [0] é o número grande em exibição (o prêmio mais recente).
  final List<DrawnEntry> _entries = [];
  int _idCounter = 0;

  String _currentInput = '';
  bool _isEditingCurrent = false; // true quando 'E' foi apertado

  bool _showHelp = false;
  bool _showHistory = false;
  bool _showFinalResults = false;
  bool _showLiveShare = false;
  // QR pequeno fixo no canto (tecla W), independente da tela cheia (Q) —
  // fica visível o tempo todo pra quem quiser escanear sem interromper a
  // exibição do número atual.
  bool _showCornerQr = false;
  bool _showResetConfirm = false;
  bool _showSponsorConfig = false;

  bool _pendingDuplicateConfirm = false;
  String? _pendingDuplicateNumber;

  List<String> _sponsorPaths = [];
  int _sponsorInterval = 6;
  int _sponsorPerScreen = 1;
  int _historySize = 3;
  int _numberSize = 3;

  Color _backgroundColor = ThemeStorage.defaultBackground;
  Color _numberColor = ThemeStorage.defaultNumberColor;
  Color _historyTextColor = ThemeStorage.defaultHistoryTextColor;
  Color _typingColor = ThemeStorage.defaultTypingColor;

  bool _cursorVisible = true;
  Timer? _cursorHideTimer;

  bool _isFullScreen = false;

  // window_manager só funciona em Windows/Linux/macOS — em Android, iOS ou
  // Web nem mostramos o botão nem tentamos chamar a API.
  bool get _isDesktopPlatform =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _loadSponsorConfig();
    _loadThemeConfig();
    _loadEntries();
    _restartCursorTimer();
  }

  Future<void> _loadSponsorConfig() async {
    final paths = await SponsorStorage.loadPaths();
    final interval = await SponsorStorage.loadInterval();
    final perScreen = await SponsorStorage.loadPerScreen();
    final historySize = await SponsorStorage.loadHistorySize();
    final numberSize = await SponsorStorage.loadNumberSize();
    if (!mounted) return;
    setState(() {
      _sponsorPaths = paths;
      _sponsorInterval = interval;
      _sponsorPerScreen = perScreen;
      _historySize = historySize;
      _numberSize = numberSize;
    });
  }

  Future<void> _loadThemeConfig() async {
    final bg = await ThemeStorage.loadBackground();
    final numberColor = await ThemeStorage.loadNumberColor();
    final historyColor = await ThemeStorage.loadHistoryTextColor();
    final typingColor = await ThemeStorage.loadTypingColor();
    if (!mounted) return;
    setState(() {
      _backgroundColor = bg;
      _numberColor = numberColor;
      _historyTextColor = historyColor;
      _typingColor = typingColor;
    });
  }

  /// Recupera o progresso do rifão salvo no disco (se houver). É isso que
  /// garante que uma queda de energia ou um fechamento inesperado do
  /// programa não perca os números já sorteados: na próxima abertura eles
  /// voltam automaticamente.
  Future<void> _loadEntries() async {
    final savedEntries = await EntriesStorage.loadEntries();
    final savedCounter = await EntriesStorage.loadIdCounter();
    if (!mounted) return;
    setState(() {
      _entries
        ..clear()
        ..addAll(savedEntries);
      _idCounter = savedCounter;
    });
  }

  /// Grava o estado atual dos sorteios no disco. Chamado depois de toda
  /// alteração (confirmar, editar, excluir, resetar) pra que nada dependa
  /// só da memória RAM.
  void _persistEntries() {
    EntriesStorage.saveEntries(_entries);
    EntriesStorage.saveIdCounter(_idCounter);
    // Também manda pra plateia acompanhar pelo celular (se configurado).
    LiveShareFirebase.updateState(_entries);
  }

  void _updateSponsorPaths(List<String> paths) {
    setState(() => _sponsorPaths = paths);
    SponsorStorage.savePaths(paths);
  }

  void _updateSponsorInterval(int seconds) {
    setState(() => _sponsorInterval = seconds);
    SponsorStorage.saveInterval(seconds);
  }

  void _updateSponsorPerScreen(int count) {
    setState(() => _sponsorPerScreen = count);
    SponsorStorage.savePerScreen(count);
  }

  void _updateHistorySize(int size) {
    setState(() => _historySize = size);
    SponsorStorage.saveHistorySize(size);
  }

  void _updateNumberSize(int size) {
    setState(() => _numberSize = size);
    SponsorStorage.saveNumberSize(size);
  }

  void _updateBackgroundColor(Color color) {
    setState(() => _backgroundColor = color);
    ThemeStorage.saveBackground(color);
  }

  void _updateNumberColor(Color color) {
    setState(() => _numberColor = color);
    ThemeStorage.saveNumberColor(color);
  }

  void _updateHistoryTextColor(Color color) {
    setState(() => _historyTextColor = color);
    ThemeStorage.saveHistoryTextColor(color);
  }

  void _updateTypingColor(Color color) {
    setState(() => _typingColor = color);
    ThemeStorage.saveTypingColor(color);
  }

  Future<void> _resetColors() async {
    await ThemeStorage.resetAll();
    setState(() {
      _backgroundColor = ThemeStorage.defaultBackground;
      _numberColor = ThemeStorage.defaultNumberColor;
      _historyTextColor = ThemeStorage.defaultHistoryTextColor;
      _typingColor = ThemeStorage.defaultTypingColor;
    });
  }

  /// Reinicia a contagem pra esconder o cursor. Chamado sempre que o mouse
  /// se move. Se o cursor estiver escondido, mostra ele de novo primeiro.
  void _restartCursorTimer() {
    if (!_cursorVisible) {
      setState(() => _cursorVisible = true);
    }
    _cursorHideTimer?.cancel();
    _cursorHideTimer = Timer(_cursorHideDelay, () {
      if (!mounted) return;
      setState(() => _cursorVisible = false);
    });
  }

  /// Liga/desliga o modo tela cheia de verdade (sem borda, cobrindo a barra
  /// de tarefas do Windows) — importante na hora de espelhar o notebook num
  /// telão ou TV, pra não aparecer nada do sistema operacional.
  Future<void> _toggleFullScreen() async {
    if (!_isDesktopPlatform) return;
    final next = !_isFullScreen;
    await windowManager.setFullScreen(next);
    if (!mounted) return;
    setState(() => _isFullScreen = next);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _cursorHideTimer?.cancel();
    super.dispose();
  }

  String? get _currentNumber =>
      _entries.isNotEmpty ? _entries.first.number : null;

  /// Prêmio Nº a mostrar: o do registro sendo editado ou já confirmado (mesma
  /// posição), ou o próximo prêmio (length + 1) quando está digitando um
  /// número novo do zero.
  int get _displayedPrizeNumber {
    if (_currentInput.isNotEmpty && !_isEditingCurrent) {
      return _entries.length + 1;
    }
    return _entries.length;
  }

  Set<String> _drawnNumbersExcluding(String? excludeId) =>
      _entries.where((e) => e.id != excludeId).map((e) => e.number).toSet();

  int? _digitFromKey(LogicalKeyboardKey key) {
    final digitKeys = {
      LogicalKeyboardKey.digit0: 0,
      LogicalKeyboardKey.digit1: 1,
      LogicalKeyboardKey.digit2: 2,
      LogicalKeyboardKey.digit3: 3,
      LogicalKeyboardKey.digit4: 4,
      LogicalKeyboardKey.digit5: 5,
      LogicalKeyboardKey.digit6: 6,
      LogicalKeyboardKey.digit7: 7,
      LogicalKeyboardKey.digit8: 8,
      LogicalKeyboardKey.digit9: 9,
      LogicalKeyboardKey.numpad0: 0,
      LogicalKeyboardKey.numpad1: 1,
      LogicalKeyboardKey.numpad2: 2,
      LogicalKeyboardKey.numpad3: 3,
      LogicalKeyboardKey.numpad4: 4,
      LogicalKeyboardKey.numpad5: 5,
      LogicalKeyboardKey.numpad6: 6,
      LogicalKeyboardKey.numpad7: 7,
      LogicalKeyboardKey.numpad8: 8,
      LogicalKeyboardKey.numpad9: 9,
    };
    return digitKeys[key];
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (_showSponsorConfig) {
      if (key == LogicalKeyboardKey.escape) {
        setState(() => _showSponsorConfig = false);
      }
      return;
    }

    if (_showResetConfirm) {
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        _performReset();
      } else if (key == LogicalKeyboardKey.escape) {
        setState(() => _showResetConfirm = false);
      }
      return;
    }

    if (_showHelp) {
      if (key == LogicalKeyboardKey.f1 || key == LogicalKeyboardKey.escape) {
        setState(() => _showHelp = false);
      }
      return;
    }

    if (_showHistory) {
      if (key == LogicalKeyboardKey.keyH || key == LogicalKeyboardKey.escape) {
        setState(() => _showHistory = false);
      }
      return;
    }

    if (_showFinalResults) {
      if (key == LogicalKeyboardKey.keyR || key == LogicalKeyboardKey.escape) {
        setState(() => _showFinalResults = false);
      }
      return;
    }

    if (_showLiveShare) {
      if (key == LogicalKeyboardKey.keyQ || key == LogicalKeyboardKey.escape) {
        setState(() => _showLiveShare = false);
      }
      return;
    }

    final digit = _digitFromKey(key);
    if (digit != null) {
      setState(() {
        if (_currentInput.length < _maxDigits) {
          _currentInput += digit.toString();
        }
        _clearPendingDuplicate();
      });
      return;
    }

    if (key == LogicalKeyboardKey.backspace) {
      setState(() {
        if (_currentInput.isNotEmpty) {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        }
        _clearPendingDuplicate();
      });
      return;
    }

    if (key == LogicalKeyboardKey.escape) {
      setState(() {
        _currentInput = '';
        _isEditingCurrent = false;
        _clearPendingDuplicate();
      });
      return;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _confirmNumber();
      return;
    }

    if (key == LogicalKeyboardKey.keyE) {
      if (_entries.isNotEmpty) {
        setState(() {
          _currentInput = _entries.first.number;
          _isEditingCurrent = true;
          _clearPendingDuplicate();
        });
      }
      return;
    }

    if (key == LogicalKeyboardKey.f1) {
      setState(() => _showHelp = true);
      return;
    }

    if (key == LogicalKeyboardKey.keyH) {
      setState(() => _showHistory = true);
      return;
    }

    if (key == LogicalKeyboardKey.keyR) {
      setState(() => _showFinalResults = true);
      return;
    }

    if (key == LogicalKeyboardKey.keyQ) {
      setState(() => _showLiveShare = true);
      return;
    }

    if (key == LogicalKeyboardKey.keyW) {
      setState(() => _showCornerQr = !_showCornerQr);
      return;
    }

    if (key == LogicalKeyboardKey.keyN) {
      setState(() => _showResetConfirm = true);
      return;
    }

    if (key == LogicalKeyboardKey.keyC) {
      setState(() => _showSponsorConfig = true);
      return;
    }

    if (key == LogicalKeyboardKey.f11) {
      _toggleFullScreen();
      return;
    }
  }

  void _clearPendingDuplicate() {
    _pendingDuplicateConfirm = false;
    _pendingDuplicateNumber = null;
  }

  void _confirmNumber() {
    if (_currentInput.isEmpty) return;
    final candidate = _currentInput;

    if (_pendingDuplicateConfirm && _pendingDuplicateNumber == candidate) {
      _reallyConfirm(candidate);
      return;
    }

    final excludeId = _isEditingCurrent && _entries.isNotEmpty
        ? _entries.first.id
        : null;
    final checkSet = _drawnNumbersExcluding(excludeId);

    if (checkSet.contains(candidate)) {
      setState(() {
        _pendingDuplicateConfirm = true;
        _pendingDuplicateNumber = candidate;
      });
      return;
    }

    _reallyConfirm(candidate);
  }

  void _reallyConfirm(String candidate) {
    setState(() {
      if (_isEditingCurrent && _entries.isNotEmpty) {
        _entries[0] = _entries[0].copyWith(number: candidate);
      } else {
        _idCounter++;
        _entries.insert(
          0,
          DrawnEntry(id: 'entry_$_idCounter', number: candidate),
        );
      }
      _currentInput = '';
      _isEditingCurrent = false;
      _clearPendingDuplicate();
    });
    _persistEntries();
  }

  void _cancelEdit() {
    setState(() {
      _currentInput = '';
      _isEditingCurrent = false;
      _clearPendingDuplicate();
    });
  }

  void _deleteEntry(String id) {
    setState(() {
      _entries.removeWhere((e) => e.id == id);
    });
    _persistEntries();
  }

  void _editEntry(String id, String newNumber) {
    setState(() {
      final index = _entries.indexWhere((e) => e.id == id);
      if (index != -1) {
        _entries[index] = _entries[index].copyWith(number: newNumber);
      }
    });
    _persistEntries();
  }

  void _performReset() {
    setState(() {
      _entries.clear();
      _currentInput = '';
      _isEditingCurrent = false;
      _showResetConfirm = false;
      _clearPendingDuplicate();
    });
    EntriesStorage.clear();
  }

  @override
  Widget build(BuildContext context) {
    final anyOverlayOpen =
        _showHelp ||
        _showHistory ||
        _showFinalResults ||
        _showLiveShare ||
        _showResetConfirm ||
        _showSponsorConfig;

    return MouseRegion(
      cursor: (_cursorVisible || anyOverlayOpen)
          ? SystemMouseCursors.basic
          : SystemMouseCursors.none,
      onHover: (_) => _restartCursorTimer(),
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Scaffold(
          backgroundColor: _backgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          // Protege contra estouro tanto de largura quanto
                          // de altura: se o prêmio + número + faixa de
                          // aviso juntos não couberem no espaço disponível
                          // (em vez de cortar/gerar erro de overflow),
                          // tudo encolhe junto, mantendo a proporção entre
                          // eles — nada fica um em cima do outro.
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PrizeLabel(
                                prizeNumber: _displayedPrizeNumber,
                                color: _numberColor,
                              ),
                              NumberDisplay(
                                number: _currentNumber,
                                typing: _currentInput,
                                warning: _pendingDuplicateConfirm,
                                color: _numberColor,
                                typingColor: _typingColor,
                                sizeLevel: _numberSize,
                              ),
                              if (_pendingDuplicateConfirm)
                                DuplicateWarningBanner(
                                  number: _pendingDuplicateNumber!,
                                ),
                              if (_isEditingCurrent &&
                                  !_pendingDuplicateConfirm)
                                EditingBanner(
                                  prizeNumber: _displayedPrizeNumber,
                                  onConfirm: _confirmNumber,
                                  onCancel: _cancelEdit,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    HistoryStrip(
                      entries: _entries,
                      maxItems: 5,
                      sizeLevel: _historySize,
                      textColor: _historyTextColor,
                    ),
                    const SizedBox(height: 8),
                    SponsorStrip(
                      imagePaths: _sponsorPaths,
                      intervalSeconds: _sponsorInterval,
                      perScreen: _sponsorPerScreen,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                const DevCredit(),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 150,
                    // Se o arquivo ainda não existir, não quebra a tela —
                    // só não mostra nada no lugar.
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
                if (_showCornerQr && LiveShareFirebase.isConfigured)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        Tooltip(
                          message: 'Clique para ampliar',
                          child: GestureDetector(
                            // Clicar no QR pequeno abre a mesma tela cheia
                            // da tecla Q, pra quem quiser um QR maior pra
                            // escanear.
                            onTap: () => setState(() => _showLiveShare = true),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: liveShareUrl,
                                size: 150,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Acompanhe pelo celular',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_showHelp) const HelpOverlay(),
                if (_showHistory)
                  FullHistoryOverlay(
                    entries: _entries,
                    onDelete: _deleteEntry,
                    onEdit: _editEntry,
                  ),
                if (_showFinalResults)
                  FinalResultsOverlay(
                    entries: _entries,
                    numberColor: _numberColor,
                  ),
                if (_showLiveShare) const LiveShareOverlay(),
                if (_showResetConfirm) const ResetConfirmOverlay(),
                if (_showSponsorConfig)
                  SponsorConfigOverlay(
                    imagePaths: _sponsorPaths,
                    intervalSeconds: _sponsorInterval,
                    perScreen: _sponsorPerScreen,
                    historySize: _historySize,
                    numberSize: _numberSize,
                    backgroundColor: _backgroundColor,
                    numberColor: _numberColor,
                    historyTextColor: _historyTextColor,
                    typingColor: _typingColor,
                    onPathsChanged: _updateSponsorPaths,
                    onIntervalChanged: _updateSponsorInterval,
                    onPerScreenChanged: _updateSponsorPerScreen,
                    onHistorySizeChanged: _updateHistorySize,
                    onNumberSizeChanged: _updateNumberSize,
                    onBackgroundColorChanged: _updateBackgroundColor,
                    onNumberColorChanged: _updateNumberColor,
                    onHistoryTextColorChanged: _updateHistoryTextColor,
                    onTypingColorChanged: _updateTypingColor,
                    onResetColors: _resetColors,
                    onClose: () => setState(() => _showSponsorConfig = false),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
