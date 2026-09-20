import '../../activities/engine/bot_player.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/activity_definition.dart';
import '../../games/twenty_nine/twenty_nine_engine.dart';
import '../../games/twenty_nine/twenty_nine_bot.dart';
import '../../games/uno/uno_engine.dart';
import '../../games/uno/uno_bot.dart';
import '../../games/bluff/bluff_engine.dart';
import '../../games/bluff/bluff_bot.dart';
import '../../games/rummy/rummy_engine.dart';
import '../../games/teen_patti/teen_patti_engine.dart';
import '../../games/brain_arena/brain_arena_engine.dart';
import '../../games/quiz/quiz_engine.dart';
import '../../games/draw_guess/draw_guess_engine.dart';
import '../../games/mafia/mafia_engine.dart';
import '../../games/coop_puzzle/coop_puzzle_engine.dart';
import '../../games/couple_mode/couple_mode_engine.dart';
import '../../games/watch_together/watch_together_engine.dart';

/// Central registry for all game definitions and engines.
/// Single source of truth for game metadata.
class GameRegistry {
  static final Map<String, GameDefinition> _definitions = {};
  static final Map<String, ActivityEngine Function()> _engineFactories = {};
  static final Map<String, BotPlayer Function(String, BotDifficulty)> _botFactories = {};
  static bool _initialized = false;

  /// Initializes the registry with all built-in games.
  static void initialize() {
    if (_initialized) return;

    // Card Classics
    _register(
      id: 'twenty_nine',
      title: '29 (Twenty-Nine)',
      activityId: 'twenty_nine',
      category: ActivityCategory.cards,
      minPlayers: 4,
      maxPlayers: 4,
      estimatedDuration: const Duration(minutes: 15),
      engineFactory: () => TwentyNineEngine(),
      botFactory: (playerId, difficulty) => TwentyNineBotPlayer(playerId: playerId, difficulty: difficulty),
    );

    _register(
      id: 'uno',
      title: 'UNO Clash',
      activityId: 'uno',
      category: ActivityCategory.cards,
      minPlayers: 2,
      maxPlayers: 6,
      estimatedDuration: const Duration(minutes: 10),
      engineFactory: () => UnoEngine(),
      botFactory: (playerId, difficulty) => UnoBotPlayer(playerId: playerId, difficulty: difficulty),
    );

    _register(
      id: 'rummy',
      title: 'Rummy Rush',
      activityId: 'rummy',
      category: ActivityCategory.cards,
      minPlayers: 2,
      maxPlayers: 4,
      estimatedDuration: const Duration(minutes: 15),
      engineFactory: () => RummyEngine(),
    );

    _register(
      id: 'teen_patti',
      title: 'Teen Patti',
      activityId: 'teen_patti',
      category: ActivityCategory.cards,
      minPlayers: 3,
      maxPlayers: 6,
      estimatedDuration: const Duration(minutes: 8),
      engineFactory: () => TeenPattiEngine(),
    );

    // Party & Deception
    _register(
      id: 'bluff',
      title: 'Bluff Masters',
      activityId: 'bluff',
      category: ActivityCategory.party,
      minPlayers: 3,
      maxPlayers: 8,
      estimatedDuration: const Duration(minutes: 12),
      engineFactory: () => BluffEngine(),
      botFactory: (playerId, difficulty) => BluffBotPlayer(playerId: playerId, difficulty: difficulty),
    );

    _register(
      id: 'mafia',
      title: 'Mafia: Nightfall',
      activityId: 'mafia',
      category: ActivityCategory.party,
      minPlayers: 5,
      maxPlayers: 12,
      estimatedDuration: const Duration(minutes: 20),
      engineFactory: () => MafiaEngine(),
    );

    // Brain & Logic
    _register(
      id: 'brain_arena',
      title: 'Brain Arena',
      activityId: 'brain_arena',
      category: ActivityCategory.brain,
      minPlayers: 1,
      maxPlayers: 8,
      estimatedDuration: const Duration(minutes: 5),
      engineFactory: () => BrainArenaEngine(),
    );

    _register(
      id: 'quiz',
      title: 'Quiz Clash',
      activityId: 'quiz_clash',
      category: ActivityCategory.brain,
      minPlayers: 2,
      maxPlayers: 8,
      estimatedDuration: const Duration(minutes: 10),
      engineFactory: () => QuizEngine(),
    );

    // Co-op Mystery
    _register(
      id: 'coop_puzzle',
      title: 'Mystery Crypt',
      activityId: 'coop_puzzle',
      category: ActivityCategory.mystery,
      minPlayers: 2,
      maxPlayers: 4,
      estimatedDuration: const Duration(minutes: 18),
      engineFactory: () => CoopPuzzleEngine(),
    );

    // Creative
    _register(
      id: 'draw_guess',
      title: 'Draw & Guess',
      activityId: 'draw_guess',
      category: ActivityCategory.creative,
      minPlayers: 3,
      maxPlayers: 8,
      estimatedDuration: const Duration(minutes: 12),
      engineFactory: () => DrawGuessEngine(),
    );

    // Couple
    _register(
      id: 'couple_mode',
      title: 'Couple Mode',
      activityId: 'couple_mode',
      category: ActivityCategory.couple,
      minPlayers: 2,
      maxPlayers: 2,
      estimatedDuration: const Duration(minutes: 10),
      engineFactory: () => CoupleModeEngine(),
    );

    // Study / Watch Together
    _register(
      id: 'watch_together',
      title: 'Watch Together',
      activityId: 'watch_together',
      category: ActivityCategory.study,
      minPlayers: 2,
      maxPlayers: 10,
      estimatedDuration: const Duration(minutes: 30),
      engineFactory: () => WatchTogetherEngine(),
    );

    _initialized = true;
  }

  static void _register({
    required String id,
    required String title,
    required String activityId,
    required ActivityCategory category,
    required int minPlayers,
    required int maxPlayers,
    required Duration estimatedDuration,
    required ActivityEngine Function() engineFactory,
    BotPlayer Function(String, BotDifficulty)? botFactory,
  }) {
    _definitions[id] = GameDefinition(
      id: id,
      activityId: activityId,
      title: title,
      category: category,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      estimatedDuration: estimatedDuration,
    );
    _engineFactories[id] = engineFactory;
    if (botFactory != null) {
      _botFactories[id] = botFactory;
    }
  }

  /// Returns the game definition for a given game ID.
  static GameDefinition? getDefinition(String gameId) {
    initialize();
    return _definitions[gameId];
  }

  /// Creates a new engine instance for the given game ID.
  static ActivityEngine createEngine(String gameId) {
    initialize();
    final factory = _engineFactories[gameId];
    if (factory == null) {
      throw ArgumentError('Unknown game: $gameId');
    }
    return factory();
  }
  
  /// Creates a new bot instance for the given game ID.
  static BotPlayer? createBot(String gameId, String playerId, [BotDifficulty difficulty = BotDifficulty.medium]) {
    initialize();
    final factory = _botFactories[gameId];
    if (factory == null) return null;
    return factory(playerId, difficulty);
  }

  /// Returns all registered game definitions.
  static List<GameDefinition> getAllDefinitions() {
    initialize();
    return _definitions.values.toList();
  }

  /// Returns definitions filtered by category.
  static List<GameDefinition> getDefinitionsByCategory(ActivityCategory category) {
    initialize();
    return _definitions.values.where((d) => d.category == category).toList();
  }

  /// Checks if a game ID is registered.
  static bool hasGame(String gameId) {
    initialize();
    return _definitions.containsKey(gameId);
  }
}

/// Extended game definition with metadata for the Play arcade.
class GameDefinition {
  final String id;
  final String activityId;
  final String title;
  final ActivityCategory category;
  final int minPlayers;
  final int maxPlayers;
  final Duration estimatedDuration;
  final String? badge; // e.g., 'FLAGSHIP', 'POPULAR', 'NEW'
  final String? description;
  final String? iconName; // Material icon name

  const GameDefinition({
    required this.id,
    required this.activityId,
    required this.title,
    required this.category,
    required this.minPlayers,
    required this.maxPlayers,
    required this.estimatedDuration,
    this.badge,
    this.description,
    this.iconName,
  });

  /// Creates a copy with additional metadata.
  GameDefinition copyWith({
    String? badge,
    String? description,
    String? iconName,
  }) {
    return GameDefinition(
      id: id,
      activityId: activityId,
      title: title,
      category: category,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      estimatedDuration: estimatedDuration,
      badge: badge ?? this.badge,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
    );
  }

  String get playerRange {
    if (minPlayers == maxPlayers) {
      return '$minPlayers Players';
    }
    return '$minPlayers-$maxPlayers Players';
  }

  String get durationLabel {
    final minutes = estimatedDuration.inMinutes;
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}