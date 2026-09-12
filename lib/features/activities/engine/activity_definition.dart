enum ActivityCategory { cards, party, brain, mystery, creative, couple, study }

class ActivityDefinition {
  final String id;
  final String title;
  final String description;
  final ActivityCategory category;
  final int minPlayers;
  final int maxPlayers;
  final Duration estimatedDuration;
  final String rules;

  const ActivityDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.minPlayers,
    required this.maxPlayers,
    required this.estimatedDuration,
    required this.rules,
  });
}
