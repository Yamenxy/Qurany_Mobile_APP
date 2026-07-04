import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../models/verse.dart';
import '../../models/recitation_session.dart';
import '../../services/audio_service.dart';
import '../../services/quran_service.dart';
import '../../services/al_bazzi_service.dart';
import '../../services/qiraat_service.dart';
import '../../services/recitation_api_service.dart';
import '../../services/recitation_history_service.dart';
import '../../services/schedule_service.dart';
import '../../services/learning_plan_service.dart';
import '../../utils/recitation_modes.dart';
import '../../utils/recitation_result_mapper.dart';
import '../../utils/user_facing_error.dart';
import '../../widgets/app_icons.dart';
class RecitationScreen extends StatefulWidget {
  final int? surahNumber;
  final String? surahName;
  final String mode; // 'free', 'memorization', 'tahfeez', or 'tasmee3'
  final int? planDayNumber;
  final String? planId;
  final int? startAyah;
  final int? endAyah;
  /// Qira'a label: `حفص` or `البزي`. Falls back to [QiraatService] when null.
  final String? qiraat;

  const RecitationScreen({
    super.key,
    this.surahNumber,
    this.surahName,
    this.mode = 'free',
    this.qiraat,
    this.planDayNumber,
    this.planId,
    this.startAyah,
    this.endAyah,
  });

  @override
  State<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends State<RecitationScreen>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();

  // Speech recognition
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _usingSpeechRecognition = false;
  String _arabicLocaleId = 'ar';
  bool _hasShownErrorAlarm = false;

  // Recording state
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _showReference = true;
  String _statusText = 'اضغط على الزر للبدء بالتسجيل';

  // Captured WAV path for server-side analysis (best-effort, runs alongside
  // on-device speech recognition; may be null if capture was unavailable).
  String? _recordedAudioPath;

  // Surah data
  List<Verse> _verses = [];
  bool _isLoadingVerses = true;
  int _selectedSurah = 1;
  String _selectedSurahName = 'الفاتحة';
  late String _qiraat;

  // Real-time transcription
  String _liveTranscription = '';
  List<_WordMatch> _matchedWords = [];

  // Audio visualization
  StreamSubscription<double>? _amplitudeSubscription;
  List<double> _amplitudes = List.filled(40, 0.0);
  StreamSubscription<int>? _durationSubscription;
  int _recordingSeconds = 0;

  // Tahfeez mode state
  int _currentVerseIndex = 0;
  bool _verseTextVisible = true;
  int _tasmee3HintCount = 0;

  // Husary audio for Tahfeez listen-then-repeat
  final AudioPlayer _husaryPlayer = AudioPlayer();
  bool _isPlayingHusary = false;
  bool _husaryFinished = false;
  double _husaryProgress = 0.0;
  StreamSubscription? _husaryPositionSub;
  StreamSubscription? _husaryCompleteSub;
  /// Invalidates stale [onPlayerComplete] callbacks when a new ayah starts.
  int _husaryPlayToken = 0;

  // Speech session guards — prevent duplicate listen() calls (Android mic beep).
  bool _speechIsListening = false;
  int _speechRestartCount = 0;
  DateTime? _lastSpeechRestartAt;
  static const int _maxSpeechRestartsPerTurn = 8;
  static const Duration _speechRestartCooldown = Duration(milliseconds: 1500);

  /// True once amplitude crosses the voice threshold during a verse-mode turn.
  bool _voiceDetectedDuringTurn = false;
  static const double _voiceAmplitudeThreshold = 0.12;

  /// Hardware WAV capture via the record plugin (Android privacy mic indicator).
  bool _usingHardwareMic = false;
  bool _husaryCompletionHandled = false;
  bool _startingRecording = false;

  static const Duration _verseSilenceTimeout = Duration(seconds: 4);
  static const Duration _husaryToMicHandoffDelay = Duration(milliseconds: 600);

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;

  // Automated flow & stats state
  bool _hasStarted = false;
  Timer? _silenceTimer;
  final Map<int, int> _verseFaults = {};

  // Tahfeez background tashkeel analysis: one pending server result per
  // accepted ayah, resolved while Husary recites the next ayah. Rendered as
  // an aggregated tashkeel report on the statistics screen at session end.
  final List<Future<Map<String, dynamic>?>> _tashkeelFutures = [];
  final List<Map<String, dynamic>> _tashkeelAyahLabels = [];

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    if (!_isVerseMode || !_isRecording) return;
    _silenceTimer = Timer(_verseSilenceTimeout, () async {
      debugPrint('Silence timeout. Automatically stopping recording.');
      if (mounted && _isRecording) {
        await _stopRecording();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.surahNumber ?? 1;
    _selectedSurahName = (widget.surahName != null && widget.surahName!.isNotEmpty)
        ? widget.surahName!
        : AppConstants.surahNames[_selectedSurah < 1 ? 0 : _selectedSurah - 1];
    _qiraat = widget.qiraat ?? 'حفص';
    _showReference = widget.mode == 'free' ||
        widget.mode == 'tahfeez' ||
        RecitationModes.isAiAnalysisMode(widget.mode);
    _verseTextVisible = widget.mode != 'tasmee3';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _husaryPlayer.setReleaseMode(ReleaseMode.stop);
    _initMicAndSpeech();
    _loadVerses();
  }

  /// Request the microphone permission and only then initialize speech
  /// recognition. Sequencing matters: on a fresh install, calling
  /// _speech.initialize() while the permission dialog is still pending makes
  /// it fail, and the two concurrent permission requests (permission_handler
  /// + speech_to_text's own) can race each other. If the user denies here,
  /// the recording paths re-request and re-init on the next record tap.
  Future<void> _initMicAndSpeech() async {
    final granted = await _audioService.requestPermission();
    if (!granted) return;
    await _initSpeech();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.qiraat == null) {
      _qiraat = context.read<QiraatService>().selectedQiraat;
    }
  }

  bool get _isBazzi => _qiraat == 'البزي';

  String get _riwayah => QiraatService.riwayahFromQiraat(_qiraat);

  /// Initialize speech recognition
  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          _speechIsListening = false;
          if (_isRecording &&
              (error.errorMsg == 'error_no_match' ||
               error.errorMsg == 'error_speech_timeout' ||
               error.errorMsg == 'error_busy' ||
               error.errorMsg == 'error_client')) {
            _restartSpeechListening();
          }
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'listening') {
            _speechIsListening = true;
          } else if (status == 'notListening' || status == 'done') {
            _speechIsListening = false;
            if (status == 'notListening' &&
                _isRecording &&
                _usingSpeechRecognition) {
              _restartSpeechListening();
            }
          }
        },
      );
      if (_speechAvailable) {
        final locales = await _speech.locales();
        final arabicLocales = locales
            .where((l) => l.localeId.toLowerCase().startsWith('ar'))
            .toList();
        if (arabicLocales.isNotEmpty) {
          const preferred = ['ar-sa', 'ar-eg', 'ar-ae', 'ar'];
          for (final pref in preferred) {
            final match = arabicLocales.where(
              (l) => l.localeId.toLowerCase().startsWith(pref),
            );
            if (match.isNotEmpty) {
              _arabicLocaleId = match.first.localeId;
              break;
            }
          }
          if (_arabicLocaleId == 'ar' && arabicLocales.isNotEmpty) {
            _arabicLocaleId = arabicLocales.first.localeId;
          }
        }
        debugPrint(
          'Speech recognition initialized — locale: $_arabicLocaleId',
        );
      }
    } catch (e) {
      debugPrint('Speech init failed: $e');
      _speechAvailable = false;
    }
  }

  /// Restart speech listening (called when engine auto-stops).
  /// Debounced to avoid Android mic-start beep spam.
  void _restartSpeechListening() {
    if (!_isRecording || !_speechAvailable) return;

    final now = DateTime.now();
    if (_lastSpeechRestartAt != null &&
        now.difference(_lastSpeechRestartAt!) < _speechRestartCooldown) {
      return;
    }
    if (_speechRestartCount >= _maxSpeechRestartsPerTurn) {
      debugPrint('Speech restart limit reached for this turn.');
      return;
    }

    _lastSpeechRestartAt = now;
    _speechRestartCount++;

    Future.delayed(const Duration(milliseconds: 400), () {
      if (_isRecording && mounted && !_speechIsListening) {
        _startSpeechListening();
      }
    });
  }

  bool get _isVerseMode => widget.mode == 'tahfeez' || widget.mode == 'tasmee3';

  bool get _isAiAnalysisMode => RecitationModes.isAiAnalysisMode(widget.mode);

  /// Whole-surah modes for a backend-supported surah can use server analysis.
  bool get _serverAnalysisEligible {
    if (widget.mode != 'free' && widget.mode != 'memorization') return false;
    if (!AppConstants.serverSupportedSurahs.contains(_selectedSurah)) {
      return false;
    }
    // Bazzi model + reference are scoped to Surah Al-Baqarah only.
    if (_isBazzi && _selectedSurah != 2) return false;
    return true;
  }

  /// Tahfeez mode: per-ayah recordings are uploaded in the background for
  /// tashkeel (harakat) analysis while Husary recites the next ayah.
  bool get _tahfeezTashkeelEligible {
    if (widget.mode != 'tahfeez' || _verses.isEmpty) return false;
    final surah = _verses[_currentVerseIndex].surahNumber;
    if (!AppConstants.serverSupportedSurahs.contains(surah)) return false;
    if (_isBazzi && surah != 2) return false;
    return true;
  }

  bool get _currentVerseServerEligible {
    if (_verses.isEmpty) return false;
    final surah = _verses[_currentVerseIndex].surahNumber;
    if (!AppConstants.serverSupportedSurahs.contains(surah)) return false;
    if (_isBazzi && surah != 2) return false;
    return true;
  }

  bool get _hasUsableRecording =>
      _recordedAudioPath != null &&
      (_voiceDetectedDuringTurn || _recordingSeconds >= 1);

  /// Apply server analyze result to word highlights and live transcript.
  void _applyCorrectionFromServer(Map<String, dynamic> result) {
    final transcript = result['transcribed_text']?.toString() ??
        result['transcribedText']?.toString() ??
        '';
    if (transcript.isNotEmpty) {
      _liveTranscription = transcript;
      _updateWordMatching(transcript);
      return;
    }

    final errors = (result['errors'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];
    if (errors.isEmpty || _verses.isEmpty) return;

    final refText = _verses[_currentVerseIndex].text;
    final originalRefWords =
        refText.split(' ').where((w) => w.isNotEmpty).toList();
    final errorByIndex = <int, Map<String, dynamic>>{};
    for (final e in errors) {
      final idx = (e['wordIndex'] as num?)?.toInt();
      if (idx != null && idx >= 0 && idx < originalRefWords.length) {
        errorByIndex[idx] = e;
      }
    }

    final matches = <_WordMatch>[];
    for (int i = 0; i < originalRefWords.length; i++) {
      final err = errorByIndex[i];
      if (err == null) {
        matches.add(_WordMatch(
          word: originalRefWords[i],
          status: _MatchStatus.correct,
        ));
      } else {
        final type = err['type']?.toString() ?? 'substitution';
        final recited = err['recitedWord']?.toString() ??
            err['recited_word']?.toString() ??
            '';
        matches.add(_WordMatch(
          word: originalRefWords[i],
          status: type == 'omission'
              ? _MatchStatus.error
              : _MatchStatus.error,
          recitedAs: recited.isEmpty ? null : recited,
        ));
      }
    }
    if (mounted) setState(() => _matchedWords = matches);
  }

  /// Start the speech listening session (fire-and-forget — do NOT await listen()).
  void _startSpeechListening() {
    if (!_speechAvailable) return;
    debugPrint('Starting speech listening (locale: $_arabicLocaleId)...');
    try {
      if (_speech.isListening) {
        _speech.stop();
      }
    } catch (_) {}
    _speechIsListening = false;

    final pauseFor = _isVerseMode
        ? const Duration(seconds: 8)
        : const Duration(seconds: 5);

    _speech.listen(
      onResult: _onSpeechResult,
      localeId: _arabicLocaleId,
      listenFor: const Duration(seconds: 120),
      pauseFor: pauseFor,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
    _usingSpeechRecognition = true;
  }

  /// Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted || !_isRecording) return;

    final recognizedText = result.recognizedWords;
    debugPrint('Speech result: "$recognizedText" (final: ${result.finalResult})');
    if (recognizedText.isEmpty) return;

    setState(() {
      _liveTranscription = recognizedText;
      _voiceDetectedDuringTurn = true;
      if (_usingHardwareMic && mounted) {
        _statusText = 'جاري التصحيح... اقرأ الآن';
      }
      _updateWordMatching(recognizedText);
    });

    _resetSilenceTimer();
  }

  Future<void> _loadVerses() async {
    setState(() => _isLoadingVerses = true);
    final quranService = context.read<QuranService>();
    List<Verse> loadedVerses = [];

    Future<List<Verse>> loadSurahVerses(int surahNumber) async {
      if (_isBazzi && surahNumber == 2) {
        return AlBazziService().getBaqaraVerses();
      }
      return quranService.getSurahVerses(surahNumber);
    }
    
    if (widget.planDayNumber != null && widget.planId != null) {
      final planService = context.read<LearningPlanService>();
      final plan = planService.getPlanById(widget.planId!);
      final task = plan?.dailyTasks.firstWhere((t) => t.dayNumber == widget.planDayNumber);
      if (task != null) {
        if (task.startSurah == task.endSurah) {
          final verses = await loadSurahVerses(task.startSurah);
          loadedVerses = verses.where((v) => v.verseNumber >= task.startVerse && v.verseNumber <= task.endVerse).toList();
        } else {
          for (int s = task.startSurah; s <= task.endSurah; s++) {
            final verses = await loadSurahVerses(s);
            if (s == task.startSurah) {
              loadedVerses.addAll(verses.where((v) => v.verseNumber >= task.startVerse));
            } else if (s == task.endSurah) {
              loadedVerses.addAll(verses.where((v) => v.verseNumber <= task.endVerse));
            } else {
              loadedVerses.addAll(verses);
            }
          }
        }
        _selectedSurah = task.startSurah;
        _selectedSurahName = AppConstants.surahNames[task.startSurah < 1 ? 0 : task.startSurah - 1];
      } else {
        loadedVerses = await loadSurahVerses(_selectedSurah);
      }
    } else if (widget.startAyah != null && widget.endAyah != null) {
      final verses = await loadSurahVerses(_selectedSurah);
      loadedVerses = verses.where((v) => v.verseNumber >= widget.startAyah! && v.verseNumber <= widget.endAyah!).toList();
    } else {
      loadedVerses = await loadSurahVerses(_selectedSurah);
    }

    if (mounted) {
      setState(() {
        _verses = loadedVerses;
        _isLoadingVerses = false;
        if (widget.mode == 'free' && _verses.isNotEmpty) {
          _matchedWords = _buildPendingMatches();
        }
      });
    }
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _durationSubscription?.cancel();
    _husaryPositionSub?.cancel();
    _husaryCompleteSub?.cancel();
    _silenceTimer?.cancel();
    _husaryPlayer.dispose();
    _speech.stop();
    _audioService.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      // In tahfeez mode: if Husary hasn't been played yet, play Husary first
      if (widget.mode == 'tahfeez' && !_husaryFinished && !_isPlayingHusary) {
        _playHusaryVerse();
        return;
      }
      // In tahfeez: if Husary is playing, stop and let user record
      if (widget.mode == 'tahfeez' && _isPlayingHusary) {
        await _stopHusary();
        return;
      }
      // In tasmee3 mode: if Husary hasn't been played yet, play Husary first
      if (widget.mode == 'tasmee3' && !_husaryFinished && !_isPlayingHusary) {
        _playHusaryVerse();
        return;
      }
      // In tasmee3: if Husary is playing, stop and let user record
      if (widget.mode == 'tasmee3' && _isPlayingHusary) {
        await _stopHusary();
        return;
      }
      await _startRecording();
    }
  }

  /// Stop playback and release audio focus so the mic can open.
  Future<void> _releaseAudioForMic() async {
    try {
      await _husaryPlayer.stop();
    } catch (_) {}
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}
    try {
      await _audioService.cancelRecording();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _attachMicAmplitudeListener() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _audioService.amplitudeStream.listen((amp) {
      if (!mounted || !_isRecording) return;
      final voiceActive = amp > _voiceAmplitudeThreshold;
      setState(() {
        _amplitudes = [..._amplitudes.skip(1), amp];
        if (voiceActive) {
          _voiceDetectedDuringTurn = true;
          if (_usingHardwareMic) {
            _statusText = 'الميكروفون يعمل — اقرأ الآن';
          }
        }
      });
      if (voiceActive) {
        _resetSilenceTimer();
      }
    });
  }

  /// Verse-mode mic: hardware recorder first (Android privacy), then best-effort STT.
  Future<void> _acquireMicForVerseTurn() async {
    await _releaseAudioForMic();

    final hasMic = await _audioService.requestPermission();
    if (!hasMic) {
      _abortRecordingTurn(
        'يلزم إذن الميكروفون. افتح إعدادات التطبيق وفعّل الميكروفون.',
      );
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
    }

    _usingHardwareMic = false;
    _usingSpeechRecognition = false;

    // Android grants the mic to ONE consumer: running the hardware recorder
    // and SpeechRecognizer together means the second one hears silence (the
    // old "best-effort" dual start left live matching dead on most devices).
    // So each turn has exactly one deterministic mic owner:
    //   - STT turn (preferred): live word highlighting; the transcript is
    //     sent to /analyze-text when the turn is validated.
    //   - Recorder turn (fallback when the device has no working speech
    //     engine): WAV captured and sent to /analyze on stop.
    if (_speechAvailable) {
      _startSpeechListening();
      _durationSubscription?.cancel();
      _durationSubscription = Stream.periodic(
        const Duration(seconds: 1),
        (i) => i + 1,
      ).listen((dur) {
        if (mounted) setState(() => _recordingSeconds = dur);
      });
      if (mounted) {
        setState(() => _statusText = 'الميكروفون يعمل — اقرأ الآن');
      }
      return;
    }

    final started = await _audioService.startRecording();
    if (!started) {
      _abortRecordingTurn(
        'تعذر فتح الميكروفون. تحقق من الإذن في إعدادات الجهاز.',
      );
      return;
    }

    _usingHardwareMic = true;
    _attachMicAmplitudeListener();
    _durationSubscription?.cancel();
    _durationSubscription = _audioService.durationStream.listen((dur) {
      if (mounted) setState(() => _recordingSeconds = dur);
    });
    if (mounted) {
      setState(() => _statusText = 'الميكروفون يعمل — اقرأ الآن');
    }
  }

  Future<void> _abortRecordingTurn(String message) async {
    _startingRecording = false;
    _pulseController.stop();
    _pulseController.reset();
    _amplitudeSubscription?.cancel();
    _durationSubscription?.cancel();
    _silenceTimer?.cancel();
    WakelockPlus.disable();
    // Release the hardware recorder if the parallel WAV capture already
    // started; otherwise the OS mic stays occupied after an aborted turn.
    if (_usingHardwareMic) {
      _usingHardwareMic = false;
      await _audioService.cancelRecording();
    }
    // After "don't ask again", the permission dialog can never reappear --
    // give the user a working shortcut to the app-settings screen instead
    // of only telling them about it in the message text.
    final permanentlyDenied = await _audioService.isPermanentlyDenied();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _statusText = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: QuranyTheme.errorRed,
          action: permanentlyDenied
              ? SnackBarAction(
                  label: 'الإعدادات',
                  textColor: Colors.white,
                  onPressed: () => _audioService.openSettings(),
                )
              : null,
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || _startingRecording || _isProcessing) return;
    _startingRecording = true;
    try {
      // Keep screen on while recording
      WakelockPlus.enable();

      _pulseController.repeat(reverse: true);
      _speechRestartCount = 0;
      _lastSpeechRestartAt = null;
      _voiceDetectedDuringTurn = false;

      // Pre-populate matchedWords with reference words in "pending" state.
      final List<String> refWordsForUi;
      if (widget.mode == 'free' && _verses.isNotEmpty) {
        refWordsForUi = _verses
            .map((v) => v.text)
            .join(' ')
            .split(' ')
            .where((w) => w.isNotEmpty)
            .toList();
      } else if (_isVerseMode && _verses.isNotEmpty) {
        refWordsForUi = _verses[_currentVerseIndex]
            .text
            .split(' ')
            .where((w) => w.isNotEmpty)
            .toList();
      } else {
        refWordsForUi = <String>[];
      }

      setState(() {
        _isRecording = true;
        _hasShownErrorAlarm = false;
        _tasmee3HintCount = 0;
        _liveTranscription = '';
        _matchedWords = refWordsForUi
            .map((w) => _WordMatch(word: w, status: _MatchStatus.pending))
            .toList();
        _statusText = _isAiAnalysisMode
            ? 'سجّل تلاوتك ثم اضغط إيقاف للتحليل بالذكاء الاصطناعي'
            : 'جاري التسجيل... اقرأ الآن';
      });

      _silenceTimer?.cancel();
      if (_isAiAnalysisMode) {
        final hasMic = await _audioService.requestPermission();
        if (!hasMic) {
          await _abortRecordingTurn('يلزم إذن الميكروفون للتسجيل');
          return;
        }
        try {
          final started = await _audioService.startRecording();
          if (started) {
            _usingHardwareMic = true;
            _attachMicAmplitudeListener();
          }
        } catch (e) {
          debugPrint('Audio capture unavailable: $e');
        }
        _durationSubscription?.cancel();
        _durationSubscription = Stream.periodic(
          const Duration(seconds: 1),
          (i) => i + 1,
        ).listen((dur) {
          if (mounted) setState(() => _recordingSeconds = dur);
        });
        return;
      }

      if (_isVerseMode) {
        _silenceTimer = Timer(const Duration(seconds: 18), () async {
          if (!mounted || !_isRecording) return;
          final noInput = _usingHardwareMic
              ? !_voiceDetectedDuringTurn
              : _liveTranscription.isEmpty;
          if (noInput) {
            debugPrint('Silence timeout. Automatically stopping recording.');
            await _stopRecording();
          }
        });
      }

      _usingSpeechRecognition = false;
      _usingHardwareMic = false;
      _recordedAudioPath = null;

      if (_isVerseMode) {
        await _acquireMicForVerseTurn();
        return;
      }

      final hasMic = await _audioService.requestPermission();
      if (!hasMic) {
        await _abortRecordingTurn('يلزم إذن الميكروفون للتسجيل');
        return;
      }

      // Parallel WAV for server analysis in free/memorization only.
      if (_serverAnalysisEligible) {
        try {
          final started = await _audioService.startRecording();
          if (started) {
            _usingHardwareMic = true;
            _attachMicAmplitudeListener();
          }
        } catch (e) {
          debugPrint('Parallel audio capture unavailable: $e');
        }
      }

      if (!_speechAvailable) {
        await _initSpeech();
      }

      if (_speechAvailable) {
        _startSpeechListening();
        _durationSubscription?.cancel();
        _durationSubscription = Stream.periodic(
          const Duration(seconds: 1),
          (i) => i + 1,
        ).listen((dur) {
          if (mounted) setState(() => _recordingSeconds = dur);
        });
      } else {
        await _abortRecordingTurn(
          'التعرف على الكلام غير متاح على هذا الجهاز. تأكد من إعطاء إذن الميكروفون.',
        );
      }
    } finally {
      _startingRecording = false;
    }
  }

  // ─────────────────── Husary Audio (حصري) ───────────────────

  void _cancelHusarySubscriptions() {
    _husaryPositionSub?.cancel();
    _husaryPositionSub = null;
    _husaryCompleteSub?.cancel();
    _husaryCompleteSub = null;
  }

  void _onHusaryPlaybackFinished(int playToken) async {
    if (!mounted || playToken != _husaryPlayToken) return;
    if (_isRecording || _isProcessing || _startingRecording) return;
    if (_husaryCompletionHandled) return;
    _husaryCompletionHandled = true;
    _cancelHusarySubscriptions();
    setState(() {
      _isPlayingHusary = false;
      _husaryFinished = true;
      _husaryProgress = 1.0;
      _statusText = 'دورك الآن — جاري التسجيل...';
    });
    // Let the speaker release audio focus before opening the mic.
    await Future.delayed(_husaryToMicHandoffDelay);
    if (!mounted ||
        playToken != _husaryPlayToken ||
        _isRecording ||
        _isProcessing) {
      return;
    }
    await _startRecording();
  }

  /// Play Al-Husary's recitation for the current verse in Tahfeez mode
  Future<void> _playHusaryVerse() async {
    if (_verses.isEmpty || _isPlayingHusary) return;

    _silenceTimer?.cancel();

    final verse = _verses[_currentVerseIndex];
    final audioUrl = verse.husaryAudioUrl;
    final playToken = ++_husaryPlayToken;
    _husaryCompletionHandled = false;

    _cancelHusarySubscriptions();
    try {
      await _husaryPlayer.stop();
    } catch (_) {}

    setState(() {
      _isPlayingHusary = true;
      _husaryFinished = false;
      _husaryProgress = 0.0;
      _statusText = 'استمع للشيخ الحصري...';
    });

    try {
      _husaryPositionSub = _husaryPlayer.onPositionChanged.listen((pos) {
        if (playToken != _husaryPlayToken) return;
        _husaryPlayer.getDuration().then((dur) {
          if (dur != null &&
              dur.inMilliseconds > 0 &&
              mounted &&
              playToken == _husaryPlayToken) {
            setState(() {
              _husaryProgress = pos.inMilliseconds / dur.inMilliseconds;
            });
          }
        });
      });

      _husaryCompleteSub = _husaryPlayer.onPlayerComplete.listen((_) {
        _onHusaryPlaybackFinished(playToken);
      });

      await _husaryPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      debugPrint('Husary playback error: $e');
      if (mounted && playToken == _husaryPlayToken) {
        setState(() {
          _isPlayingHusary = false;
          _husaryFinished = true;
          _statusText = 'تعذر تشغيل الصوت — اقرأ الآية';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تعذر تشغيل صوت الحصري. تأكد من الاتصال بالإنترنت.'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
        await _startRecording();
      }
    }
  }

  /// Stop Husary playback and begin the user's recitation turn.
  Future<void> _stopHusary() async {
    _husaryPlayToken++;
    _cancelHusarySubscriptions();
    await _husaryPlayer.stop();
    if (mounted) {
      setState(() {
        _isPlayingHusary = false;
        _husaryFinished = true;
        _husaryProgress = 0.0;
        _statusText = 'دورك الآن — جاري التسجيل...';
      });
      if (!_isRecording) {
        await _startRecording();
      }
    }
  }

  /// Start recording user's recitation after Husary finishes (Tahfeez mode)
  Future<void> _startUserTurnRecording() async {
    setState(() {
      _husaryFinished = false;
    });
    await _startRecording();
  }

  void _scheduleHusaryAfterVerseChange() {
    if (!_hasStarted || widget.mode != 'tahfeez') return;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_isRecording && !_isPlayingHusary && !_isProcessing) {
        _playHusaryVerse();
      }
    });
  }

  /// Navigate to next verse in Tahfeez mode, resetting Husary state
  void _tahfeezNextVerse({bool autoPlayHusary = true}) {
    if (_currentVerseIndex < _verses.length - 1) {
      _husaryPlayToken++;
      _cancelHusarySubscriptions();
      _husaryPlayer.stop();
      setState(() {
        _currentVerseIndex++;
        _resetVerseState();
      });
      if (autoPlayHusary) {
        _scheduleHusaryAfterVerseChange();
      }
    }
  }

  /// Navigate to previous verse in Tahfeez mode
  void _tahfeezPrevVerse({bool autoPlayHusary = true}) {
    if (_currentVerseIndex > 0) {
      _husaryPlayToken++;
      _cancelHusarySubscriptions();
      _husaryPlayer.stop();
      setState(() {
        _currentVerseIndex--;
        _resetVerseState();
      });
      if (autoPlayHusary) {
        _scheduleHusaryAfterVerseChange();
      }
    }
  }

  void _tasmee3NextVerse() {
    if (_currentVerseIndex < _verses.length - 1) {
      _husaryPlayToken++;
      _cancelHusarySubscriptions();
      _husaryPlayer.stop();
      setState(() {
        _currentVerseIndex++;
        _resetVerseState();
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_isRecording && !_isPlayingHusary && !_isProcessing) {
          _playHusaryVerse();
        }
      });
    }
  }

  void _tasmee3PrevVerse() {
    if (_currentVerseIndex > 0) {
      _husaryPlayToken++;
      _cancelHusarySubscriptions();
      _husaryPlayer.stop();
      setState(() {
        _currentVerseIndex--;
        _resetVerseState();
      });
    }
  }

  void _resetVerseState() {
    _matchedWords = [];
    _liveTranscription = '';
    _voiceDetectedDuringTurn = false;
    _usingHardwareMic = false;
    _husaryCompletionHandled = false;
    _isPlayingHusary = false;
    _husaryFinished = false;
    _husaryProgress = 0.0;
    _tasmee3HintCount = 0;
    _statusText = 'استمع للحصري ثم اقرأ الآية';
  }

  /// Compare transcribed words with reference to build word matches
  void _updateWordMatching(String transcribedText) {
    if (_verses.isEmpty) return;

    final refText = _isVerseMode
        ? _verses[_currentVerseIndex].text
        : _verses.map((v) => v.text).join(' ');
    final refWords = _normalizeArabic(refText).split(' ');
    final transWords = _normalizeArabic(transcribedText).split(' ');
    final originalRefWords = refText.split(' ');
    final bool liveFreeMode = widget.mode == 'free' && _isRecording;
    final bool liveTasmee3Mode = widget.mode == 'tasmee3' && _isRecording;
    final bool liveTahfeezMode = widget.mode == 'tahfeez' && _isRecording;
    bool errorDetected = false;

    final matches = <_WordMatch>[];
    int ti = 0;

    for (int ri = 0; ri < originalRefWords.length; ri++) {
      if (ti < transWords.length && ri < refWords.length) {
        if (refWords[ri] == transWords[ti]) {
          matches.add(_WordMatch(
            word: originalRefWords[ri],
            status: _MatchStatus.correct,
          ));
          ti++;
        } else if (_isSimilar(refWords[ri], transWords[ti])) {
          matches.add(_WordMatch(
            word: originalRefWords[ri],
            status: liveFreeMode ? _MatchStatus.pending : _MatchStatus.partial,
            recitedAs: liveFreeMode ? null : transWords[ti],
          ));
          ti++;
        } else {
          // Check if it's an omission or substitution
          if (ti + 1 < transWords.length &&
              ri < refWords.length &&
              refWords[ri] == transWords[ti + 1]) {
            matches.add(_WordMatch(
              word: originalRefWords[ri],
              status: liveFreeMode ? _MatchStatus.pending : _MatchStatus.correct,
            ));
            ti += 2;
          } else {
            matches.add(_WordMatch(
              word: originalRefWords[ri],
              status: _MatchStatus.error,
              recitedAs: liveFreeMode ? null : transWords[ti],
            ));
            if (liveFreeMode || liveTasmee3Mode || liveTahfeezMode) {
              errorDetected = true;
            }
            ti++;
          }
        }
      } else if (ti >= transWords.length) {
        matches.add(_WordMatch(
          word: originalRefWords[ri],
          status: _MatchStatus.pending,
        ));
      } else {
        matches.add(_WordMatch(
          word: originalRefWords[ri],
          status: _MatchStatus.pending,
        ));
      }
    }

    if (errorDetected &&
        !_hasShownErrorAlarm &&
        (liveFreeMode || liveTasmee3Mode || liveTahfeezMode)) {
      _hasShownErrorAlarm = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            liveTasmee3Mode
                ? 'خطأ في التلاوة، يمكنك استخدام التلميح'
                : liveTahfeezMode
                    ? 'خطأ في التلاوة، حاول مرة أخرى'
                    : 'كلمة خاطئة، يرجى إعادة قراءتها',
          ),
          backgroundColor: QuranyTheme.errorRed,
          duration: const Duration(seconds: 2),
        ),
      );
      // Reset alarm after delay to allow future alarms
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _hasShownErrorAlarm = false;
        }
      });
    }

    setState(() => _matchedWords = matches);
  }

  List<_WordMatch> _buildPendingMatches() {
    final words = _verses
        .map((v) => v.text)
        .join(' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    return words.map((w) => _WordMatch(word: w, status: _MatchStatus.pending)).toList();
  }

  bool _isSimilar(String a, String b) {
    if (a == b) return true;
    final setA = a.runes.toSet();
    final setB = b.runes.toSet();
    final intersection = setA.intersection(setB);
    final union = setA.union(setB);
    if (union.isEmpty) return false;
    return intersection.length / union.length > 0.6;
  }

  String _normalizeArabic(String text) {
    // Remove diacritics
    text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    // Remove tatweel
    text = text.replaceAll('\u0640', '');
    // Normalize alef variants
    text = text.replaceAll(RegExp(r'[\u0625\u0623\u0622\u0627]'), '\u0627');
    // Remove non-Arabic
    text = text.replaceAll(RegExp(r'[^\u0621-\u064A\s]'), '');
    // Normalize spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _silenceTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    _amplitudeSubscription?.cancel();
    _durationSubscription?.cancel();

    if (_usingSpeechRecognition) {
      await _speech.stop();
      _usingSpeechRecognition = false;
    }
    _speechIsListening = false;

    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _statusText = 'جاري تحليل التلاوة...';
    });

    WakelockPlus.disable();

    // Mark that we captured audio even if amplitude stayed low.
    if (_usingHardwareMic && _recordingSeconds >= 1) {
      _voiceDetectedDuringTurn = true;
    }

    // Stop the WAV capture -- only when this turn actually owned the
    // hardware recorder. AudioService.stopRecording() returns the LAST
    // recorded file path even when idle, so calling it on an STT-only turn
    // would resurrect a stale (already deleted) path and misroute the
    // backend call from /analyze-text to a dead audio upload.
    if (_usingHardwareMic) {
      try {
        final stopped = await _audioService.stopRecording();
        if (stopped != null) _recordedAudioPath = stopped;
      } catch (_) {}
    }

    if (_isAiAnalysisMode) {
      await _runAiServerAnalysis();
      return;
    }

    if (widget.mode == 'tasmee3') {
      await _finishTasmee3Turn();
      return;
    }

    if (widget.mode == 'tahfeez') {
      if (mounted) {
        await _validateTahfeez();
      }
      return;
    }

    // Prefer server-side analysis (faster-whisper) when a recording was
    // captured and the surah is supported; otherwise fall back to the
    // on-device speech-recognition comparison.
    if (_serverAnalysisEligible && _recordedAudioPath != null && mounted) {
      final api = context.read<RecitationApiService>();
      setState(() => _statusText = 'يتم تحليل التلاوة على الخادم...');
      final serverResult = await api.tryAnalyzeRecitation(
        audioFilePath: _recordedAudioPath!,
        surahNumber: _selectedSurah,
        riwayah: _riwayah,
      );
      if (serverResult != null && mounted) {
        _saveAndNavigateToResult(
          serverResult,
          fromBackend: true,
          riwayah: _riwayah,
        );
        return;
      }
    }

    // Use on-device speech recognition for comparison
    if (_liveTranscription.isNotEmpty && mounted) {
      _performLocalComparison();
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _statusText = 'لم يتم التعرف على النص. حاول:\n'
            '• القراءة بصوت واضح وقريب من الميكروفون\n'
            '• استخدام جهاز حقيقي بدلاً من المحاكي';
      });
    }
  }

  /// Upload the accepted ayah for tashkeel analysis in the background.
  void _queueTashkeelAnalysis(String transcript) {
    if (!_tahfeezTashkeelEligible) return;

    final audioPath = _recordedAudioPath;
    if (audioPath == null && transcript.trim().isEmpty) return;

    final verse = _verses[_currentVerseIndex];
    final api = context.read<RecitationApiService>();
    final riwayah = _riwayah;

    _tashkeelAyahLabels.add({
      'surahNumber': verse.surahNumber,
      'verseNumber': verse.verseNumber,
      'text': verse.text,
    });
    _tashkeelFutures.add(() async {
      try {
        if (audioPath != null) {
          return await api.analyzeRecitation(
            audioFilePath: audioPath,
            surahNumber: verse.surahNumber,
            riwayah: riwayah,
            startAyah: verse.verseNumber,
            endAyah: verse.verseNumber,
            timeout: const Duration(seconds: 180),
          );
        }
        return await api.analyzeText(
          surahNumber: verse.surahNumber,
          transcribedText: transcript,
          riwayah: riwayah,
          startAyah: verse.verseNumber,
          endAyah: verse.verseNumber,
        );
      } catch (e) {
        debugPrint('Tashkeel analysis failed for ayah ${verse.verseNumber}: $e');
        return null;
      } finally {
        if (audioPath != null) {
          try {
            await File(audioPath).delete();
          } catch (_) {}
        }
      }
    }());
    _recordedAudioPath = null;
  }

  /// Reuse an analyze response from tahfeez validation (avoids a second upload).
  void _queueTashkeelFromAnalyzeResult(
    Map<String, dynamic> result,
    Verse verse,
  ) {
    if (!_tahfeezTashkeelEligible) return;
    _tashkeelAyahLabels.add({
      'surahNumber': verse.surahNumber,
      'verseNumber': verse.verseNumber,
      'text': verse.text,
    });
    _tashkeelFutures.add(Future.value(result));
  }

  Future<void> _finishTasmee3Turn() async {
    if (_liveTranscription.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'اكتملت الآية — راجع التصحيح ثم انتقل للتالية';
        });
      }
      return;
    }

    final audioPath = _recordedAudioPath;
    if (audioPath != null &&
        (_hasUsableRecording || _usingHardwareMic) &&
        _currentVerseServerEligible) {
      if (mounted) {
        setState(() => _statusText = 'جاري التعرف على الصوت...');
      }
      try {
        final verse = _verses[_currentVerseIndex];
        final api = context.read<RecitationApiService>();
        final result = await api.analyzeRecitation(
          audioFilePath: audioPath,
          surahNumber: verse.surahNumber,
          riwayah: _riwayah,
          startAyah: verse.verseNumber,
          endAyah: verse.verseNumber,
          timeout: const Duration(seconds: 180),
        );
        if (mounted) {
          _applyCorrectionFromServer(result);
        }
      } catch (e) {
        debugPrint('Tasmee3 server transcription failed: $e');
      } finally {
        try {
          await File(audioPath).delete();
        } catch (_) {}
        _recordedAudioPath = null;
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _statusText = _liveTranscription.isEmpty
            ? 'لم يتم التعرف على نص الآية. حاول مرة أخرى.'
            : 'اكتملت الآية — راجع التصحيح ثم انتقل للتالية';
      });
    }
  }

  Future<void> _validateTahfeez() async {
    // Live STT produced a transcript during the turn.
    if (_liveTranscription.isNotEmpty) {
      await _validateTahfeezWithSimilarity(
        _computeLocalSimilarity(_liveTranscription),
        tashkeelTranscript: _liveTranscription,
      );
      return;
    }

    // Hardware recording — analyze WAV on the server for transcript + correction.
    Map<String, dynamic>? serverResult;
    final audioPath = _recordedAudioPath;

    if (audioPath != null &&
        (_hasUsableRecording || _usingHardwareMic) &&
        _currentVerseServerEligible) {
      if (mounted) {
        setState(() => _statusText = 'جاري تحليل التلاوة على الخادم...');
      }
      try {
        final verse = _verses[_currentVerseIndex];
        final api = context.read<RecitationApiService>();
        serverResult = await api.analyzeRecitation(
          audioFilePath: audioPath,
          surahNumber: verse.surahNumber,
          riwayah: _riwayah,
          startAyah: verse.verseNumber,
          endAyah: verse.verseNumber,
          timeout: const Duration(seconds: 180),
        );
        if (mounted) {
          _applyCorrectionFromServer(serverResult);
        }
      } catch (e) {
        debugPrint('Tahfeez server analysis failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تعذر الاتصال بخادم التحليل. تحقق من عنوان الخادم في الإعدادات.',
              ),
              backgroundColor: QuranyTheme.errorRed,
            ),
          );
        }
      } finally {
        try {
          await File(audioPath).delete();
        } catch (_) {}
        _recordedAudioPath = null;
      }
    }

    if (_liveTranscription.isEmpty) {
      _verseFaults[_currentVerseIndex] =
          (_verseFaults[_currentVerseIndex] ?? 0) + 1;
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = serverResult == null && audioPath != null
              ? 'تعذر الاتصال بالخادم. تحقق من الشبكة وحاول مرة أخرى.'
              : 'لم يتم التعرف على الصوت. جاري إعادة تشغيل الشيخ...';
        });
      }
      if (serverResult == null) {
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) _playHusaryVerse();
        });
      }
      return;
    }

    final similarity = serverResult != null
        ? ((serverResult['similarity_score'] as num?) ?? 0).toDouble() / 100
        : _computeLocalSimilarity(_liveTranscription);

    // Brief pause so the user can see word highlights before advancing.
    if (mounted) {
      setState(() => _isProcessing = false);
    }
    await Future.delayed(const Duration(milliseconds: 1500));

    await _validateTahfeezWithSimilarity(
      similarity,
      serverResult: serverResult,
      tashkeelTranscript: _liveTranscription,
    );
  }

  double _computeLocalSimilarity(String transcription) {
    final verseText = _verses[_currentVerseIndex].text;
    final refWords = verseText.split(' ').where((w) => w.isNotEmpty).toList();
    final transWords = _normalizeArabic(transcription)
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    final normalizedRef = refWords.map((w) => _normalizeArabic(w)).toList();

    int matchedCount = 0;
    int ti = 0;
    for (int ri = 0; ri < refWords.length; ri++) {
      if (ti < transWords.length && ri < normalizedRef.length) {
        if (normalizedRef[ri] == transWords[ti] ||
            _isSimilar(normalizedRef[ri], transWords[ti])) {
          matchedCount++;
          ti++;
        } else {
          bool foundAhead = false;
          for (int ahead = 1;
              ahead <= 2 && ti + ahead < transWords.length;
              ahead++) {
            if (normalizedRef[ri] == transWords[ti + ahead] ||
                _isSimilar(normalizedRef[ri], transWords[ti + ahead])) {
              matchedCount++;
              ti += ahead + 1;
              foundAhead = true;
              break;
            }
          }
          if (!foundAhead) {
            ti++;
          }
        }
      }
    }
    return refWords.isNotEmpty ? matchedCount / refWords.length : 0;
  }

  Future<void> _validateTahfeezWithSimilarity(
    double similarity, {
    Map<String, dynamic>? serverResult,
    required String tashkeelTranscript,
  }) async {
    if (similarity >= 0.8) {
      if (serverResult != null) {
        _queueTashkeelFromAnalyzeResult(
          serverResult,
          _verses[_currentVerseIndex],
        );
      } else {
        _queueTashkeelAnalysis(tashkeelTranscript);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تلاوة صحيحة!'),
            backgroundColor: QuranyTheme.correctGreen,
            duration: Duration(milliseconds: 800),
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }

      final isLastVerse = _currentVerseIndex == _verses.length - 1;
      if (isLastVerse) {
        if (widget.planDayNumber != null && widget.planId != null) {
          if (mounted) {
            await context
                .read<LearningPlanService>()
                .markTaskCompleted(widget.planId!, widget.planDayNumber!);
          }
        }

        final totalVerses = _verses.length;
        final totalCorrectedFaults =
            _verseFaults.values.fold(0, (sum, val) => sum + val);
        final Map<String, int> faultsDetail = {};
        _verseFaults.forEach((idx, count) {
          if (idx < _verses.length) {
            final v = _verses[idx];
            final sIdx = v.surahNumber < 1 ? 0 : v.surahNumber - 1;
            faultsDetail[
                '${AppConstants.surahNames[sIdx]} آية ${v.verseNumber}'] = count;
          }
        });

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.statistics,
            arguments: {
              'totalVerses': totalVerses,
              'totalCorrectedFaults': totalCorrectedFaults,
              'faultsDetail': faultsDetail,
              'tashkeelFutures': _tashkeelFutures,
              'tashkeelAyahLabels': _tashkeelAyahLabels,
            },
          );
        }
        return;
      }

      _tahfeezNextVerse();
    } else {
      _verseFaults[_currentVerseIndex] =
          (_verseFaults[_currentVerseIndex] ?? 0) + 1;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تلاوة غير صحيحة، استمع للشيخ وحاول مرة أخرى'),
            backgroundColor: QuranyTheme.errorRed,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _isProcessing = false;
          _statusText = 'تلاوة غير صحيحة، استمع للشيخ...';
        });
      }

      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) _playHusaryVerse();
      });
    }
  }

  /// Perform real comparison using actual transcribed text from speech recognition
  void _performLocalComparison() {
    final referenceText = _verses.map((v) => v.text).join(' ');
    final transcribedText = _liveTranscription;

    if (transcribedText.isEmpty) {
      setState(() {
        _isProcessing = false;
        _statusText = 'لم يتم التعرف على أي نص. حاول مرة أخرى.';
      });
      return;
    }

    // Normalize both texts for comparison
    final refNorm = _normalizeArabic(referenceText);
    final transNorm = _normalizeArabic(transcribedText);

    final refWords = refNorm.split(' ').where((w) => w.isNotEmpty).toList();
    final transWords = transNorm.split(' ').where((w) => w.isNotEmpty).toList();
    final originalRefWords = referenceText.split(' ').where((w) => w.isNotEmpty).toList();

    // Dynamic programming alignment (LCS-based)
    final errors = <Map<String, dynamic>>[];
    int matchedCount = 0;
    int i = 0, j = 0;

    while (i < refWords.length && j < transWords.length) {
      if (refWords[i] == transWords[j]) {
        matchedCount++;
        i++;
        j++;
      } else if (_isSimilar(refWords[i], transWords[j])) {
        matchedCount++;
        i++;
        j++;
      } else {
        bool foundOmission = false;
        bool foundAddition = false;

        if (i + 1 < refWords.length) {
          if (refWords[i + 1] == transWords[j] || _isSimilar(refWords[i + 1], transWords[j])) {
            foundOmission = true;
          }
        }

        if (j + 1 < transWords.length) {
          if (refWords[i] == transWords[j + 1] || _isSimilar(refWords[i], transWords[j + 1])) {
            foundAddition = true;
          }
        }

        if (foundOmission && !foundAddition) {
          errors.add({
            'type': 'omission',
            'expectedWord': i < originalRefWords.length ? originalRefWords[i] : refWords[i],
            'recitedWord': '',
            'wordIndex': i,
          });
          i++;
        } else if (foundAddition && !foundOmission) {
          errors.add({
            'type': 'addition',
            'expectedWord': '',
            'recitedWord': transWords[j],
            'wordIndex': i,
          });
          j++;
        } else {
          errors.add({
            'type': 'substitution',
            'expectedWord': i < originalRefWords.length ? originalRefWords[i] : refWords[i],
            'recitedWord': transWords[j],
            'wordIndex': i,
          });
          i++;
          j++;
        }
      }
    }

    // Remaining reference words are omissions
    while (i < refWords.length) {
      errors.add({
        'type': 'omission',
        'expectedWord': i < originalRefWords.length ? originalRefWords[i] : refWords[i],
        'recitedWord': '',
        'wordIndex': i,
      });
      i++;
    }

    // Remaining transcribed words are additions
    while (j < transWords.length) {
      errors.add({
        'type': 'addition',
        'expectedWord': '',
        'recitedWord': transWords[j],
        'wordIndex': refWords.length,
      });
      j++;
    }

    final totalWords = refWords.length;
    final mistakes = errors.length;
    matchedCount = totalWords - errors.where((e) => e['type'] != 'addition').length;
    if (matchedCount < 0) matchedCount = 0;

    final similarity = totalWords > 0
        ? (matchedCount / totalWords * 100).clamp(0.0, 100.0)
        : 0.0;

    final result = {
      'transcribed_text': transcribedText,
      'reference_text': referenceText,
      'similarity_score': similarity,
      'total_words': totalWords,
      'matched_words': matchedCount,
      'mistakes': mistakes,
      'errors': errors,
      'segments': <Map<String, dynamic>>[],
    };

    _saveAndNavigateToResult(result);
  }

  Future<void> _runAiServerAnalysis() async {
    if (_recordedAudioPath == null) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'لم يتم حفظ التسجيل الصوتي. حاول مرة أخرى.';
        });
      }
      return;
    }

    final api = context.read<RecitationApiService>();
    if (!api.supportsSurah(_selectedSurah)) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText =
              'التحليل بالذكاء الاصطناعي متاح لسورتي النبأ والبقرة فقط.';
        });
      }
      return;
    }

    final healthy = await api.isHealthy();
    if (!healthy) {
      final msg = UserFacingError.networkUnavailable;
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = msg;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
      return;
    }

    final riwayah = context.read<QiraatService>().riwayah;
    if (riwayah == 'bazzi' && _selectedSurah != 2) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'قراءة البزي متاحة لسورة البقرة فقط.';
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() => _statusText = 'جاري التحليل بالذكاء الاصطناعي...');
      }
      final result = await api.analyzeRecitation(
        audioFilePath: _recordedAudioPath!,
        surahNumber: _selectedSurah,
        riwayah: riwayah,
        startAyah: widget.startAyah,
        endAyah: widget.endAyah,
        autoDetectAyahRange: widget.startAyah == null,
      );
      if (mounted) {
        _saveAndNavigateToResult(result, fromBackend: true, riwayah: riwayah);
      }
    } on RecitationApiException catch (e) {
      final msg =
          UserFacingError.fromRecitationFailure(statusCode: e.statusCode);
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = msg;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  void _saveAndNavigateToResult(
    Map<String, dynamic> result, {
    bool fromBackend = false,
    String? riwayah,
  }) {
    final session = fromBackend
        ? recitationSessionFromAnalysisResult(
            result: result,
            id: const Uuid().v4(),
            surahNumber: _selectedSurah,
            surahName: _selectedSurahName,
            mode: widget.mode,
            versesRecited: _verses.length,
            riwayah: riwayah,
          )
        : RecitationSession(
            id: const Uuid().v4(),
            surahNumber: _selectedSurah,
            surahName: _selectedSurahName,
            mode: widget.mode,
            dateTime: DateTime.now(),
            similarityScore: (result['similarity_score'] ?? 0).toDouble(),
            totalWords: result['total_words'] ?? 0,
            matchedWords: result['matched_words'] ?? 0,
            mistakes: result['mistakes'] ?? 0,
            versesRecited: _verses.length,
            transcribedText: result['transcribed_text'],
            referenceText: result['reference_text'],
            errors: (result['errors'] as List?)
                    ?.map((e) =>
                        RecitationError.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                [],
            harakatScore: () {
              final raw = result['harakatScore'] ?? result['harakat_score'];
              if (raw == null) return null;
              return (raw as num).toDouble();
            }(),
            harakatMistakes:
                (result['harakatMistakes'] ?? result['harakat_mistakes'] as num?)
                    ?.toInt() ??
                0,
            harakatChecked:
                (result['harakatChecked'] ?? result['harakat_checked'] as num?)
                    ?.toInt() ??
                0,
            riwayah: context.read<QiraatService>().riwayah,
          );

    // Save to history
    context.read<RecitationHistoryService>().addSession(session);

    // Update streak
    try {
      context.read<ScheduleService>().updateStreak();
    } catch (_) {}

    setState(() {
      _isProcessing = false;
      _statusText = 'اضغط على الزر للبدء بالتسجيل';
      _recordingSeconds = 0;
      _amplitudes = List.filled(40, 0.0);
      _liveTranscription = '';
      _matchedWords = [];
    });

    Navigator.pushNamed(
      context,
      AppRoutes.recitationResult,
      arguments: session.toJson(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuranyTheme.background,
      appBar: AppBar(
        title: Text(
          widget.planDayNumber != null
              ? 'متابعة الخطة'
              : RecitationModes.isAiAnalysisMode(widget.mode)
                  ? 'تحليل بالذكاء الاصطناعي'
                  : widget.mode == 'tahfeez'
                  ? 'تعلم حر'
                  : widget.mode == 'tasmee3'
                      ? 'تسميع'
                      : 'التلاوة',
        ),
        leading: AppIcons.backButton(
          context: context,
          onPressed: () {
            if (_isRecording) {
              _audioService.cancelRecording();
              _speech.stop();
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          if (widget.mode == 'free')
            IconButton(
              icon: Icon(
                  _showReference ? Icons.visibility : Icons.visibility_off),
              tooltip: _showReference ? 'إخفاء النص' : 'إظهار النص',
              onPressed: () =>
                  setState(() => _showReference = !_showReference),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSurahInfoBar(),
          Expanded(
            child: _isLoadingVerses
                ? const Center(child: CircularProgressIndicator())
                : _buildMainContent(),
          ),
          _buildRecordingControls(),
        ],
      ),
    );
  }

  String get _currentSurahName {
    if (_verses.isEmpty || _currentVerseIndex >= _verses.length) {
      return _selectedSurahName;
    }
    final verse = _verses[_currentVerseIndex];
    if (verse.surahNumber < 1 || verse.surahNumber > 114) {
      return _selectedSurahName;
    }
    return AppConstants.surahNames[verse.surahNumber - 1];
  }

  int get _currentSurahVerseCount {
    if (_verses.isEmpty || _currentVerseIndex >= _verses.length) {
      return AppConstants.surahVerseCount[_selectedSurah < 1 ? 0 : _selectedSurah - 1];
    }
    final verse = _verses[_currentVerseIndex];
    if (verse.surahNumber < 1 || verse.surahNumber > 114) {
      return AppConstants.surahVerseCount[_selectedSurah < 1 ? 0 : _selectedSurah - 1];
    }
    return AppConstants.surahVerseCount[verse.surahNumber - 1];
  }

  Widget _buildSurahInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: QuranyTheme.primaryGreen.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: QuranyTheme.primaryGreen.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book,
              color: QuranyTheme.primaryGreen, size: 18),
          const SizedBox(width: 8),
          Text(
            'سورة $_currentSurahName',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: QuranyTheme.darkGreen,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: QuranyTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_currentSurahVerseCount آية',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          if (widget.mode == 'memorization' ||
              widget.mode == 'tahfeez' ||
              widget.mode == 'tasmee3') ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _modeBadgeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_modeBadgeIcon, size: 12, color: _modeBadgeColor),
                  const SizedBox(width: 4),
                  Text(
                    _modeBadgeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: _modeBadgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isVerseMode && _verses.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'آية ${_currentVerseIndex + 1} / ${_verses.length}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _modeBadgeColor {
    switch (widget.mode) {
      case 'tahfeez':
        return const Color(0xFF1565C0);
      case 'tasmee3':
        return const Color(0xFF6A1B9A);
      default:
        return QuranyTheme.primaryGold;
    }
  }

  IconData get _modeBadgeIcon {
    switch (widget.mode) {
      case 'tahfeez':
        return Icons.school_rounded;
      case 'tasmee3':
        return Icons.record_voice_over_rounded;
      default:
        return Icons.psychology;
    }
  }

  String get _modeBadgeLabel {
    if (widget.planDayNumber != null) {
      return 'متابعة الخطة';
    }
    switch (widget.mode) {
      case 'tahfeez':
        return 'تعلم حر';
      case 'tasmee3':
        return 'تسميع';
      default:
        return 'حفظ';
    }
  }

  Widget _buildMainContent() {
    switch (widget.mode) {
      case 'tahfeez':
        return _buildTahfeezMode();
      case 'tasmee3':
        return _buildTasmee3Mode();
      case 'memorization':
        return _buildMemorizationMode();
      case 'free':
      default:
        if (_showReference) {
          return _buildReferenceWithLiveHighlighting();
        } else {
          return _buildMemorizationMode();
        }
    }
  }

  /// Reference text with real-time word highlighting (Tarteel-like)
  Widget _buildReferenceWithLiveHighlighting() {
    final words = _matchedWords.isNotEmpty ? _matchedWords : _buildPendingMatches();
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuranyTheme.cream,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: QuranyTheme.primaryGold.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              textDirection: TextDirection.rtl,
              spacing: 6,
              runSpacing: 10,
              children: words.map((match) {
                return _buildHighlightedWord(match);
              }).toList(),
            ),
            const SizedBox(height: 24),
            _buildLiveTranscriptionArea(),
            const SizedBox(height: 16),
            _buildErrorLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedWord(_WordMatch match) {
    Color bgColor;
    Color textColor;

    if (widget.mode == 'free') {
      switch (match.status) {
        case _MatchStatus.correct:
          bgColor = QuranyTheme.darkGreen;
          textColor = Colors.white;
          break;
        case _MatchStatus.partial:
        case _MatchStatus.error:
          bgColor = QuranyTheme.errorRed.withValues(alpha: 0.15);
          textColor = QuranyTheme.errorRed;
          break;
        case _MatchStatus.pending:
        default:
          bgColor = Colors.transparent;
          textColor = Colors.grey.shade400;
          break;
      }
    } else if (widget.mode == 'tasmee3') {
      switch (match.status) {
        case _MatchStatus.correct:
          bgColor = Colors.transparent;
          textColor = QuranyTheme.darkGreen;
          break;
        case _MatchStatus.partial:
          bgColor = Colors.transparent;
          textColor = QuranyTheme.warningOrange; // Hinted words
          break;
        case _MatchStatus.error:
        case _MatchStatus.pending:
        default:
          bgColor = Colors.transparent;
          textColor = Colors.transparent;
          break;
      }
    } else {
      switch (match.status) {
        case _MatchStatus.correct:
          bgColor = QuranyTheme.correctGreen.withValues(alpha: 0.15);
          textColor = QuranyTheme.correctGreen;
          break;
        case _MatchStatus.partial:
          bgColor = QuranyTheme.warningOrange.withValues(alpha: 0.15);
          textColor = QuranyTheme.warningOrange;
          break;
        case _MatchStatus.error:
          bgColor = QuranyTheme.errorRed.withValues(alpha: 0.15);
          textColor = QuranyTheme.errorRed;
          break;
        case _MatchStatus.pending:
          bgColor = Colors.transparent;
          textColor = Colors.grey.shade600;
          break;
      }
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(
          begin: 0.0,
          end: match.status != _MatchStatus.pending ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Color.lerp(Colors.transparent, bgColor, value),
            borderRadius: BorderRadius.circular(6),
            border: match.status == _MatchStatus.error
                ? Border.all(
                    color: QuranyTheme.errorRed.withValues(alpha: value * 0.5))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                match.word,
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: 'Amiri',
                  height: 1.8,
                  color: textColor,
                  fontWeight: match.status == _MatchStatus.correct
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                textDirection: TextDirection.rtl,
              ),
              if (match.status == _MatchStatus.error &&
                  match.recitedAs != null) ...[
                Text(
                  match.recitedAs!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: QuranyTheme.errorRed,
                    decoration: TextDecoration.lineThrough,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveTranscriptionArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isRecording
              ? QuranyTheme.primaryGreen.withValues(alpha: 0.4)
              : QuranyTheme.primaryGreen.withValues(alpha: 0.15),
          width: _isRecording ? 1.5 : 1,
        ),
        boxShadow: _isRecording
            ? [
                BoxShadow(
                  color: QuranyTheme.primaryGreen.withValues(alpha: 0.06),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_isRecording)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, value, _) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: QuranyTheme.errorRed
                            .withValues(alpha: value),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: QuranyTheme.errorRed
                                .withValues(alpha: value * 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                _isRecording ? 'يُكتب مباشرة...' : 'نص التلاوة',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _isRecording
                      ? QuranyTheme.primaryGreen
                      : Colors.grey,
                ),
              ),
              const Spacer(),
              if (_liveTranscription.isNotEmpty)
                Text(
                  '${_liveTranscription.split(' ').where((w) => w.isNotEmpty).length} كلمة',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: Alignment.topRight,
            child: SizedBox(
              width: double.infinity,
              child: _liveTranscription.isEmpty
                  ? Text(
                      _isRecording ? 'في انتظار النص...' : '',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Amiri',
                        height: 1.8,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    )
                  : Text(
                      _liveTranscription,
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Amiri',
                        height: 1.8,
                        color: QuranyTheme.darkGreen,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('صحيح', QuranyTheme.correctGreen),
        const SizedBox(width: 16),
        _legendItem('قريب', QuranyTheme.warningOrange),
        const SizedBox(width: 16),
        _legendItem('خطأ', QuranyTheme.errorRed),
        const SizedBox(width: 16),
        _legendItem('لم يُقرأ', Colors.grey),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  // ─────────────────── Tahfeez Mode (تحفيظ) ───────────────────
  /// Verse-by-verse memorization with Al-Husary listen-then-repeat flow
  Widget _buildTahfeezMode() {
    if (_verses.isEmpty) {
      return const Center(child: Text('لا توجد آيات'));
    }

    if (!_hasStarted) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: QuranyTheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: QuranyTheme.shadow,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
            border: Border.all(color: QuranyTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 80,
                color: QuranyTheme.primaryGreen,
              ),
              const SizedBox(height: 16),
              const Text(
                'مصحف التكرار والتعلم',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: QuranyTheme.darkGreen),
              ),
              const SizedBox(height: 8),
              const Text(
                'اضغط على زر البدء للاستماع لتلاوة الشيخ الحصري ثم الترديد بعده تلقائياً.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasStarted = true;
                    });
                    _playHusaryVerse();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuranyTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('ابدأ التعلم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final verse = _verses[_currentVerseIndex];

    return Column(
      children: [
        // Verse navigation header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: AppIcons.navPrevious(
                  color: _currentVerseIndex > 0
                      ? const Color(0xFF1565C0)
                      : Colors.grey.shade300,
                ),
                onPressed: _currentVerseIndex > 0 && !_isRecording && !_isPlayingHusary
                    ? _tahfeezPrevVerse
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'الآية ${verse.verseNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: AppIcons.navNext(
                  color: _currentVerseIndex < _verses.length - 1
                      ? const Color(0xFF1565C0)
                      : Colors.grey.shade300,
                ),
                onPressed: _currentVerseIndex < _verses.length - 1 &&
                        !_isRecording &&
                        !_isPlayingHusary
                    ? _tahfeezNextVerse
                    : null,
              ),
            ],
          ),
        ),

        // Step indicator
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isRecording
                  ? [Colors.red.shade50, Colors.red.shade100]
                  : _isPlayingHusary
                      ? [Colors.green.shade50, Colors.green.shade100]
                      : _husaryFinished
                          ? [Colors.orange.shade50, Colors.orange.shade100]
                          : [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _isRecording
                    ? Icons.mic
                    : _isPlayingHusary
                        ? Icons.volume_up_rounded
                        : _husaryFinished
                            ? Icons.record_voice_over
                            : Icons.headphones_rounded,
                color: _isRecording
                    ? Colors.red
                    : _isPlayingHusary
                        ? Colors.green.shade700
                        : _husaryFinished
                            ? Colors.orange.shade700
                            : const Color(0xFF1565C0),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isRecording
                      ? 'جاري التسجيل — اقرأ الآن'
                      : _isPlayingHusary
                          ? 'استمع للشيخ الحصري...'
                          : _husaryFinished
                              ? 'دورك! اقرأ الآن تلقائياً'
                              : 'اضغط للاستماع للحصري أولاً',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isRecording
                        ? Colors.red.shade800
                        : _isPlayingHusary
                            ? Colors.green.shade800
                            : _husaryFinished
                                ? Colors.orange.shade800
                                : const Color(0xFF1565C0),
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              if (_isPlayingHusary) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: _husaryProgress,
                    strokeWidth: 3,
                    backgroundColor: Colors.green.shade100,
                    valueColor: AlwaysStoppedAnimation(Colors.green.shade700),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),

        if (!_isRecording && !_isPlayingHusary && !_husaryFinished)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _playHusaryVerse,
                icon: const Icon(Icons.play_circle_fill, size: 28),
                label: const Text(
                  'استمع للشيخ الحصري',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuranyTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),

        if (_isPlayingHusary)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _stopHusary,
                icon: const Icon(Icons.skip_next_rounded, size: 28),
                label: const Text(
                  'تخطي — أنا جاهز للقراءة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuranyTheme.accent,
                  foregroundColor: QuranyTheme.forest,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),

        if (_husaryFinished && !_isRecording && !_isProcessing)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startUserTurnRecording,
                    icon: const Icon(Icons.mic, size: 28),
                    label: const Text(
                      'أعد التسجيل يدوياً',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _playHusaryVerse,
                  icon: Icon(Icons.replay, size: 18, color: Colors.green.shade700),
                  label: Text(
                    'أعد الاستماع للحصري',
                    style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Mushaf blank area
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF9F3E4),
                  const Color(0xFFFDF7EE),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.brown.withValues(alpha: 0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildTahfeezHighlightedVerse(),
          ),
        ),

        if (!_isRecording &&
            !_isPlayingHusary &&
            _currentVerseIndex < _verses.length - 1 &&
            _liveTranscription.isNotEmpty &&
            !_isProcessing)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _tahfeezNextVerse,
              icon: AppIcons.actionForward(color: Colors.white),
              label: const Text('الآية التالية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTahfeezHighlightedVerse() {
    final verseText = _verses[_currentVerseIndex].text;
    final refWords = verseText.split(' ');
    final transWords = _normalizeArabic(_liveTranscription).split(' ');
    final normalizedRef = refWords.map((w) => _normalizeArabic(w)).toList();

    final localMatches = <_WordMatch>[];
    int ti = 0;
    for (int ri = 0; ri < refWords.length; ri++) {
      if (ti < transWords.length && ri < normalizedRef.length) {
        if (normalizedRef[ri] == transWords[ti]) {
          localMatches.add(_WordMatch(word: refWords[ri], status: _MatchStatus.correct));
          ti++;
        } else if (_isSimilar(normalizedRef[ri], transWords[ti])) {
          localMatches
              .add(_WordMatch(word: refWords[ri], status: _MatchStatus.partial, recitedAs: transWords[ti]));
          ti++;
        } else {
          localMatches
              .add(_WordMatch(word: refWords[ri], status: _MatchStatus.error, recitedAs: transWords[ti]));
          ti++;
        }
      } else {
        localMatches.add(_WordMatch(word: refWords[ri], status: _MatchStatus.pending));
      }
    }

    return Wrap(
      alignment: WrapAlignment.center,
      textDirection: TextDirection.rtl,
      spacing: 6,
      runSpacing: 10,
      children: localMatches.map((m) => _buildHighlightedWord(m)).toList(),
    );
  }

  Widget _buildTahfeezBlankVerse() {
    final verseText = _verses[_currentVerseIndex].text;
    final refWords = verseText.split(' ').where((w) => w.isNotEmpty).toList();
    final transWords = _normalizeArabic(_liveTranscription).split(' ');
    final normalizedRef = refWords.map((w) => _normalizeArabic(w)).toList();

    final visibleWords = <_WordMatch>[];
    int ti = 0;
    for (int ri = 0; ri < refWords.length; ri++) {
      bool matched = false;
      while (ti < transWords.length) {
        if (normalizedRef[ri] == transWords[ti]) {
          matched = true;
          ti++;
          break;
        }
        ti++;
      }
      visibleWords.add(_WordMatch(
        word: refWords[ri],
        status: matched ? _MatchStatus.correct : _MatchStatus.pending,
      ));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final lineCount = (constraints.maxHeight / 36).floor().clamp(8, 12);
        return Column(
          children: [
            _buildMushafOrnament(),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(lineCount, (i) {
                      return Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: Colors.brown.withValues(alpha: 0.12),
                      );
                    }),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        textDirection: TextDirection.rtl,
                        spacing: 8,
                        runSpacing: 12,
                        children: visibleWords.map((m) {
                          final color = m.status == _MatchStatus.correct
                              ? QuranyTheme.darkGreen
                              : Colors.transparent;
                          return Text(
                            m.word,
                            style: TextStyle(
                              fontSize: 24,
                              fontFamily: 'Amiri',
                              height: 2.0,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                            textDirection: TextDirection.rtl,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildMushafOrnament(),
          ],
        );
      },
    );
  }

  Widget _buildMushafOrnament() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 36, height: 1, color: Colors.brown.withValues(alpha: 0.25)),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.brown.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 36, height: 1, color: Colors.brown.withValues(alpha: 0.25)),
      ],
    );
  }

  // ─────────────────── Tasmee3 Mode (تسميع) ───────────────────
  /// Listen then repeat, ayah-by-ayah, with per-ayah highlighting
  Widget _buildTasmee3Mode() {
    if (_verses.isEmpty) {
      return const Center(child: Text('لا توجد آيات'));
    }

    final verse = _verses[_currentVerseIndex];

    return Column(
      children: [
        // Verse navigation header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: AppIcons.navPrevious(
                  color: _currentVerseIndex > 0
                      ? const Color(0xFF6A1B9A)
                      : Colors.grey.shade300,
                  size: 18,
                ),
                onPressed: _currentVerseIndex > 0 && !_isRecording && !_isPlayingHusary
                    ? _tasmee3PrevVerse
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'الآية ${verse.verseNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: AppIcons.navNext(
                  color: _currentVerseIndex < _verses.length - 1
                      ? const Color(0xFF6A1B9A)
                      : Colors.grey.shade300,
                  size: 18,
                ),
                onPressed: _currentVerseIndex < _verses.length - 1 &&
                        !_isRecording &&
                        !_isPlayingHusary
                    ? _tasmee3NextVerse
                    : null,
              ),
            ],
          ),
        ),

        // Step indicator
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isRecording
                  ? [Colors.red.shade50, Colors.red.shade100]
                  : _isPlayingHusary
                      ? [Colors.green.shade50, Colors.green.shade100]
                      : _husaryFinished
                          ? [Colors.orange.shade50, Colors.orange.shade100]
                          : [Colors.purple.shade50, Colors.purple.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _isRecording
                    ? Icons.mic
                    : _isPlayingHusary
                        ? Icons.volume_up_rounded
                        : _husaryFinished
                            ? Icons.record_voice_over
                            : Icons.headphones_rounded,
                color: _isRecording
                    ? Colors.red
                    : _isPlayingHusary
                        ? Colors.green.shade700
                        : _husaryFinished
                            ? Colors.orange.shade700
                            : const Color(0xFF6A1B9A),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isRecording
                      ? 'جاري التسجيل — اقرأ الآن'
                      : _isPlayingHusary
                          ? 'استمع للشيخ الحصري...'
                          : _husaryFinished
                              ? 'دورك! اضغط زر التسجيل'
                              : 'اضغط للاستماع للحصري أولاً',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isRecording
                        ? Colors.red.shade800
                        : _isPlayingHusary
                            ? Colors.green.shade800
                            : _husaryFinished
                                ? Colors.orange.shade800
                                : const Color(0xFF6A1B9A),
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              if (_isPlayingHusary) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: _husaryProgress,
                    strokeWidth: 3,
                    backgroundColor: Colors.green.shade100,
                    valueColor: AlwaysStoppedAnimation(Colors.green.shade700),
                  ),
                ),
              ],
            ],
          ),
        ),

        if (!_isRecording && !_isPlayingHusary && !_husaryFinished)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _playHusaryVerse,
                icon: const Icon(Icons.play_circle_fill, size: 28),
                label: const Text(
                  'استمع للشيخ الحصري',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuranyTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),

        if (_isPlayingHusary)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _stopHusary,
                icon: const Icon(Icons.skip_next_rounded, size: 28),
                label: const Text(
                  'تخطي — أنا جاهز للقراءة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuranyTheme.accent,
                  foregroundColor: QuranyTheme.forest,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),

        if (_husaryFinished && !_isRecording && !_isProcessing)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startUserTurnRecording,
                icon: const Icon(Icons.mic, size: 28),
                label: const Text(
                  'دورك — ابدأ القراءة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),

        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: QuranyTheme.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPlayingHusary
                    ? Colors.green.shade300
                    : _isRecording
                        ? Colors.red.shade300
                        : const Color(0xFF6A1B9A).withValues(alpha: 0.2),
                width: _isPlayingHusary || _isRecording ? 2 : 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_isRecording || _liveTranscription.isNotEmpty)
                    _buildTasmee3HighlightedVerse()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        '\uFD3F${verse.verseNumber}\uFD3E',
                        style: const TextStyle(
                          fontSize: 26,
                          fontFamily: 'Amiri',
                          height: 2.2,
                          color: QuranyTheme.darkGreen,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),

                  if (_isRecording && _liveTranscription.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildLiveTranscriptionArea(),
                  ],

                  if (_isRecording || _liveTranscription.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildErrorLegend(),
                    if (_isRecording) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _tasmee3HintCount++;
                          });
                        },
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('تلميح'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),

        if (!_isRecording &&
            !_isPlayingHusary &&
            _currentVerseIndex < _verses.length - 1 &&
            _liveTranscription.isNotEmpty &&
            !_isProcessing)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _tasmee3NextVerse,
              icon: AppIcons.actionForward(color: Colors.white),
              label: const Text('الآية التالية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTasmee3HighlightedVerse() {
    final verseText = _verses[_currentVerseIndex].text;
    final refWords = verseText.split(' ');
    final transWords = _normalizeArabic(_liveTranscription).split(' ');
    final normalizedRef = refWords.map((w) => _normalizeArabic(w)).toList();

    final localMatches = <_WordMatch>[];
    int ti = 0;
    int hintsUsed = 0;

    for (int ri = 0; ri < refWords.length; ri++) {
      if (ti < transWords.length && ri < normalizedRef.length) {
        if (normalizedRef[ri] == transWords[ti]) {
          localMatches.add(_WordMatch(word: refWords[ri], status: _MatchStatus.correct));
          ti++;
        } else if (_isSimilar(normalizedRef[ri], transWords[ti])) {
          localMatches.add(_WordMatch(
            word: refWords[ri],
            status: _MatchStatus.partial,
            recitedAs: transWords[ti],
          ));
          ti++;
        } else {
          localMatches.add(_WordMatch(
            word: refWords[ri],
            status: _MatchStatus.error,
            recitedAs: transWords[ti],
          ));
          ti++;
        }
      } else {
        if (hintsUsed < _tasmee3HintCount) {
          localMatches.add(_WordMatch(word: refWords[ri], status: _MatchStatus.partial));
          hintsUsed++;
        } else {
          localMatches.add(_WordMatch(word: refWords[ri], status: _MatchStatus.pending));
        }
      }
    }

    // Add verse number at the end
    localMatches.add(_WordMatch(
      word: '\uFD3F${_verses[_currentVerseIndex].verseNumber}\uFD3E',
      status: _MatchStatus.correct,
    ));

    return Wrap(
      alignment: WrapAlignment.center,
      textDirection: TextDirection.rtl,
      spacing: 6,
      runSpacing: 10,
      children: localMatches.map((m) => _buildHighlightedWord(m)).toList(),
    );
  }

  Widget _buildMemorizationMode() {
    // Before recording: show instruction
    if (!_isRecording && _liveTranscription.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_rounded,
              size: 80,
              color: QuranyTheme.primaryGold.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'وضع الحفظ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: QuranyTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اقرأ السورة من حفظك — سيظهر التصحيح أثناء القراءة',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // During/after recording: show highlighted reference + transcription
    return _buildReferenceWithLiveHighlighting();
  }

  Widget _buildRecordingControls() {
    if (widget.mode == 'tahfeez' && !_hasStarted) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: QuranyTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording)
            SizedBox(
              height: 50,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(double.infinity, 50),
                    painter: _WaveformPainter(
                      amplitudes: _amplitudes,
                      color: QuranyTheme.primaryGreen,
                      animationValue: _waveController.value,
                    ),
                  );
                },
              ),
            ),
          if (_isRecording && _usingHardwareMic)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '● الميكروفون نشط',
                style: TextStyle(
                  fontSize: 12,
                  color: QuranyTheme.correctGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_isRecording) const SizedBox(height: 8),
          if (_isRecording)
            Text(
              _audioService.formatDuration(_recordingSeconds),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: QuranyTheme.darkGreen,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          Text(
            _statusText,
            style: TextStyle(
              fontSize: 14,
              color: _isRecording ? QuranyTheme.errorRed : Colors.grey[600],
              fontWeight:
                  _isRecording ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isRecording && widget.mode == 'free')
            TextButton(
              onPressed: _stopRecording,
              child: const Text(
                'انتهيت',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: QuranyTheme.primaryGreen,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_isProcessing)
            Column(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: QuranyTheme.primaryGreen,
                    backgroundColor:
                        QuranyTheme.primaryGreen.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'جاري تحليل التلاوة...',
                  style: TextStyle(
                    fontSize: 14,
                    color: QuranyTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRecording)
                  GestureDetector(
                    onTap: () {
                      _audioService.cancelRecording();
                      _speech.stop();
                      _usingSpeechRecognition = false;
                      _amplitudeSubscription?.cancel();
                      _durationSubscription?.cancel();
                      _pulseController.stop();
                      _pulseController.reset();
                      WakelockPlus.disable();
                      setState(() {
                        _isRecording = false;
                        _statusText = 'اضغط على الزر للبدء بالتسجيل';
                        _recordingSeconds = 0;
                        _amplitudes = List.filled(40, 0.0);
                        _liveTranscription = '';
                        _matchedWords = [];
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ),
                if (_isRecording) const SizedBox(width: 24),
                GestureDetector(
                  onTap: _isProcessing ? null : _toggleRecording,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulseSize = _isRecording
                          ? _pulseController.value * 16
                          : 0.0;

                      Color btnColor;
                      IconData btnIcon;
                      if (_isRecording) {
                        btnColor = QuranyTheme.errorRed;
                        btnIcon = Icons.stop_rounded;
                      } else if (widget.mode == 'tahfeez' && _isPlayingHusary) {
                        btnColor = QuranyTheme.accent;
                        btnIcon = Icons.skip_next_rounded;
                      } else if (widget.mode == 'tahfeez' && !_husaryFinished) {
                        btnColor = QuranyTheme.primary;
                        btnIcon = Icons.play_circle_fill;
                      } else {
                        btnColor = QuranyTheme.primaryGreen;
                        btnIcon = Icons.mic_rounded;
                      }

                      return Container(
                        width: 80 + pulseSize,
                        height: 80 + pulseSize,
                        decoration: BoxDecoration(
                          color: btnColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: btnColor.withValues(alpha: 0.3),
                              blurRadius: 20 + pulseSize,
                              spreadRadius: pulseSize / 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          btnIcon,
                          color: Colors.white,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
                if (_isRecording) const SizedBox(width: 24),
                if (_isRecording)
                  const SizedBox(width: 48, height: 48),
              ],
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────── Helper classes ───────────────────

enum _MatchStatus { correct, partial, error, pending }

class _WordMatch {
  final String word;
  final _MatchStatus status;
  final String? recitedAs;

  const _WordMatch({
    required this.word,
    required this.status,
    this.recitedAs,
  });
}

/// Custom waveform painter for audio visualization
class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final double animationValue;

  _WaveformPainter({
    required this.amplitudes,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final barCount = amplitudes.length;
    final barWidth = size.width / barCount;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final amp = amplitudes[i];
      final waveOffset =
          sin((i / barCount * 2 * pi) + (animationValue * 2 * pi)) * 0.2;
      final height = max(4.0, (amp + waveOffset.abs()) * size.height * 0.8);

      final opacity = 0.3 + (amp * 0.7);
      paint.color = color.withValues(alpha: opacity.clamp(0.0, 1.0));

      final x = i * barWidth + barWidth / 2;
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}
