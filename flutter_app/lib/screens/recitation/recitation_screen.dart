import 'dart:async';
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
import '../../services/recitation_api_service.dart';
import '../../services/recitation_history_service.dart';
import '../../services/schedule_service.dart';
import '../../widgets/app_icons.dart';

class RecitationScreen extends StatefulWidget {
  final int? surahNumber;
  final String? surahName;
  final String mode; // 'free', 'memorization', 'tahfeez', or 'tasmee3'

  const RecitationScreen({
    super.key,
    this.surahNumber,
    this.surahName,
    this.mode = 'free',
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

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.surahNumber ?? 1;
    _selectedSurahName =
        widget.surahName ?? AppConstants.surahNames[_selectedSurah - 1];
    _showReference = widget.mode == 'free' || widget.mode == 'tahfeez';
    _verseTextVisible = widget.mode != 'tahfeez';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _audioService.requestPermission();
    _initSpeech();
    _loadVerses();
  }

  /// Initialize speech recognition
  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
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
          if (status == 'notListening' && _isRecording && _usingSpeechRecognition) {
            _restartSpeechListening();
          }
        },
      );
      if (_speechAvailable) {
        debugPrint('Speech recognition initialized - Arabic available');
      }
    } catch (e) {
      debugPrint('Speech init failed: $e');
      _speechAvailable = false;
    }
  }

  /// Restart speech listening (called when engine auto-stops)
  void _restartSpeechListening() {
    if (!_isRecording || !_speechAvailable) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isRecording && mounted) {
        _startSpeechListening();
      }
    });
  }

  bool get _isVerseMode => widget.mode == 'tahfeez' || widget.mode == 'tasmee3';

  /// Whole-surah modes for a backend-supported surah can use server analysis.
  bool get _serverAnalysisEligible =>
      (widget.mode == 'free' || widget.mode == 'memorization') &&
      AppConstants.serverSupportedSurahs.contains(_selectedSurah);

  /// Start the speech listening session
  void _startSpeechListening() {
    if (!_speechAvailable) return;
    debugPrint('Starting speech listening...');
    _speech.listen(
      onResult: _onSpeechResult,
      localeId: 'ar',
      listenFor: const Duration(seconds: 120),
      pauseFor: const Duration(seconds: 5),
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
      _updateWordMatching(recognizedText);
    });
  }

  Future<void> _loadVerses() async {
    setState(() => _isLoadingVerses = true);
    final quranService = context.read<QuranService>();
    final verses = await quranService.getSurahVerses(_selectedSurah);
    if (mounted) {
      setState(() {
        _verses = verses;
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

  Future<void> _startRecording() async {
    // Keep screen on while recording
    WakelockPlus.enable();

    _pulseController.repeat(reverse: true);

    // Pre-populate matchedWords with all reference words in "pending" state
    // so the highlighted view is shown immediately during recording
    final allRefWords = (widget.mode == 'free' && _verses.isNotEmpty)
      ? _verses.map((v) => v.text).join(' ').split(' ').where((w) => w.isNotEmpty).toList()
      : <String>[];

    setState(() {
      _isRecording = true;
      _hasShownErrorAlarm = false;
      _tasmee3HintCount = 0;
      _liveTranscription = '';
      _matchedWords = allRefWords
          .map((w) => _WordMatch(word: w, status: _MatchStatus.pending))
          .toList();
      _statusText = 'جاري التسجيل... اقرأ الآن';
    });

    // Use on-device speech recognition for live transcription
    _usingSpeechRecognition = false;

    // Capture raw audio in parallel for server-side (faster-whisper) analysis.
    // Best-effort: on platforms where the speech recognizer holds the mic
    // exclusively this may fail, in which case we silently fall back to the
    // on-device transcript/comparison.
    _recordedAudioPath = null;
    if (_serverAnalysisEligible) {
      try {
        final started = await _audioService.startRecording();
        if (started) {
          _amplitudeSubscription?.cancel();
          _amplitudeSubscription =
              _audioService.amplitudeStream.listen((amp) {
            if (!mounted) return;
            setState(() {
              _amplitudes = [..._amplitudes.skip(1), amp];
            });
          });
        }
      } catch (e) {
        debugPrint('Parallel audio capture unavailable: $e');
      }
    }

    if (_speechAvailable) {
      _startSpeechListening();
      _durationSubscription = Stream.periodic(
        const Duration(seconds: 1),
        (i) => i + 1,
      ).listen((dur) {
        if (mounted) setState(() => _recordingSeconds = dur);
      });
    } else {
      _pulseController.stop();
      _pulseController.reset();
      WakelockPlus.disable();
      setState(() {
        _isRecording = false;
        _statusText =
            'التعرف على الكلام غير متاح على هذا الجهاز. تأكد من إعطاء إذن الميكروفون.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'التعرف على الكلام غير متاح. تأكد من إعطاء إذن الميكروفون.',
            ),
            backgroundColor: QuranyTheme.errorRed,
          ),
        );
      }
      return;
    }
  }

  // ─────────────────── Husary Audio (حصري) ───────────────────

  /// Play Al-Husary's recitation for the current verse in Tahfeez mode
  Future<void> _playHusaryVerse() async {
    if (_verses.isEmpty || _isPlayingHusary) return;

    final verse = _verses[_currentVerseIndex];
    final audioUrl = verse.husaryAudioUrl;

    setState(() {
      _isPlayingHusary = true;
      _husaryFinished = false;
      _husaryProgress = 0.0;
      _statusText = 'استمع للشيخ الحصري...';
    });

    try {
      // Listen for position updates (progress bar)
      _husaryPositionSub?.cancel();
      _husaryPositionSub = _husaryPlayer.onPositionChanged.listen((pos) {
        _husaryPlayer.getDuration().then((dur) {
          if (dur != null && dur.inMilliseconds > 0 && mounted) {
            setState(() {
              _husaryProgress = pos.inMilliseconds / dur.inMilliseconds;
            });
          }
        });
      });

      // Listen for completion
      _husaryCompleteSub?.cancel();
      _husaryCompleteSub = _husaryPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlayingHusary = false;
            _husaryFinished = true;
            _husaryProgress = 1.0;
            _statusText = 'دورك الآن — اقرأ الآية';
          });
        }
      });

      await _husaryPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      debugPrint('Husary playback error: $e');
      if (mounted) {
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
      }
    }
  }

  /// Stop Husary playback
  Future<void> _stopHusary() async {
    await _husaryPlayer.stop();
    _husaryPositionSub?.cancel();
    _husaryCompleteSub?.cancel();
    if (mounted) {
      setState(() {
        _isPlayingHusary = false;
        _husaryFinished = true;
        _husaryProgress = 0.0;
        _statusText = 'دورك الآن — اقرأ الآية';
      });
    }
  }

  /// Start recording user's recitation after Husary finishes (Tahfeez mode)
  Future<void> _startUserTurnRecording() async {
    setState(() {
      _husaryFinished = false;
    });
    await _startRecording();
  }

  /// Navigate to next verse in Tahfeez mode, resetting Husary state
  void _tahfeezNextVerse() {
    if (_currentVerseIndex < _verses.length - 1) {
      _husaryPlayer.stop();
      setState(() {
        _currentVerseIndex++;
        _resetVerseState();
      });
    }
  }

  /// Navigate to previous verse in Tahfeez mode
  void _tahfeezPrevVerse() {
    if (_currentVerseIndex > 0) {
      _husaryPlayer.stop();
      setState(() {
        _currentVerseIndex--;
        _resetVerseState();
      });
    }
  }

  void _tasmee3NextVerse() {
    if (_currentVerseIndex < _verses.length - 1) {
      _husaryPlayer.stop();
      setState(() {
        _currentVerseIndex++;
        _resetVerseState();
      });
    }
  }

  void _tasmee3PrevVerse() {
    if (_currentVerseIndex > 0) {
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
    _isPlayingHusary = false;
    _husaryFinished = false;
    _husaryProgress = 0.0;
    _tasmee3HintCount = 0;
    _statusText = 'استمع للحصري ثم اقرأ الآية';
  }

  /// Compare transcribed words with reference to build word matches
  void _updateWordMatching(String transcribedText) {
    if (_verses.isEmpty) return;

    final refText = _verses.map((v) => v.text).join(' ');
    final refWords = _normalizeArabic(refText).split(' ');
    final transWords = _normalizeArabic(transcribedText).split(' ');
    final originalRefWords = refText.split(' ');
    final bool liveFreeMode = widget.mode == 'free' && _isRecording;
    final bool liveTasmee3Mode = widget.mode == 'tasmee3' && _isRecording;
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
              recitedAs: (liveFreeMode || liveTasmee3Mode) ? null : transWords[ti],
            ));
            if (liveFreeMode || liveTasmee3Mode) errorDetected = true;
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

    if (errorDetected && !_hasShownErrorAlarm && (liveFreeMode || liveTasmee3Mode)) {
      _hasShownErrorAlarm = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(liveTasmee3Mode ? 'خطأ في التلاوة، يمكنك استخدام التلميح' : 'كلمة خاطئة، يرجى إعادة قراءتها'),
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
    _pulseController.stop();
    _pulseController.reset();
    _amplitudeSubscription?.cancel();
    _durationSubscription?.cancel();

    if (_usingSpeechRecognition) {
      await _speech.stop();
      _usingSpeechRecognition = false;
    }

    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _statusText = 'جاري تحليل التلاوة...';
    });

    WakelockPlus.disable();

    // Stop the parallel WAV capture (if it was running).
    try {
      final stopped = await _audioService.stopRecording();
      if (stopped != null) _recordedAudioPath = stopped;
    } catch (_) {}

    if (widget.mode == 'tasmee3') {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = _liveTranscription.isEmpty
              ? 'لم يتم التعرف على نص الآية. حاول مرة أخرى.'
              : 'اكتملت الآية — راجع التصحيح ثم انتقل للتالية';
        });
      }
      return;
    }

    if (widget.mode == 'tahfeez') {
      if (mounted) {
        _validateTahfeez();
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
      );
      if (serverResult != null && mounted) {
        _saveAndNavigateToResult(serverResult);
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

  void _validateTahfeez() {
    if (_liveTranscription.isEmpty) {
      setState(() {
        _isProcessing = false;
        _statusText = 'لم يتم التعرف على الصوت. حاول مرة أخرى.';
        _husaryFinished = true;
      });
      return;
    }

    final verseText = _verses[_currentVerseIndex].text;
    final refWords = verseText.split(' ').where((w) => w.isNotEmpty).toList();
    final transWords = _normalizeArabic(_liveTranscription).split(' ').where((w) => w.isNotEmpty).toList();
    final normalizedRef = refWords.map((w) => _normalizeArabic(w)).toList();

    int matchedCount = 0;
    int ti = 0;
    for (int ri = 0; ri < refWords.length; ri++) {
      if (ti < transWords.length && ri < normalizedRef.length) {
        if (normalizedRef[ri] == transWords[ti] || _isSimilar(normalizedRef[ri], transWords[ti])) {
          matchedCount++;
          ti++;
        } else {
          // Allow skipping a wrong transcribed word
          bool foundAhead = false;
          for (int ahead = 1; ahead <= 2 && ti + ahead < transWords.length; ahead++) {
             if (normalizedRef[ri] == transWords[ti + ahead] || _isSimilar(normalizedRef[ri], transWords[ti + ahead])) {
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

    final double similarity = refWords.isNotEmpty ? matchedCount / refWords.length : 0;
    
    if (similarity >= 0.8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تلاوة صحيحة! ننتقل للآية التالية...'),
          backgroundColor: QuranyTheme.correctGreen,
        ),
      );
      
      setState(() {
        _isProcessing = false;
      });
      
      _tahfeezNextVerse();
      
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _playHusaryVerse();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تلاوة غير صحيحة، حاول مرة أخرى'),
          backgroundColor: QuranyTheme.errorRed,
        ),
      );
      setState(() {
        _isProcessing = false;
        _statusText = 'حاول مرة أخرى';
        _husaryFinished = true; 
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

  void _saveAndNavigateToResult(Map<String, dynamic> result) {
    final session = RecitationSession(
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
              ?.map((e) => RecitationError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
          widget.mode == 'memorization'
              ? 'مراجعة الحفظ'
              : widget.mode == 'tahfeez'
                  ? 'تحفيظ'
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
            'سورة $_selectedSurahName',
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
              '${AppConstants.surahVerseCount[_selectedSurah - 1]} آية',
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
    switch (widget.mode) {
      case 'tahfeez':
        return 'تحفيظ';
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
            child: _buildTahfeezBlankVerse(),
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
