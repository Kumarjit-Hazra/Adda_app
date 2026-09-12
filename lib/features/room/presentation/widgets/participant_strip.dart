import 'package:flutter/material.dart';
import '../../domain/models/participant.dart';
import 'participant_tile.dart';

class ParticipantStrip extends StatelessWidget {
  final List<Participant> participants;
  final String localUserId;

  const ParticipantStrip({
    super.key,
    required this.participants,
    required this.localUserId,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final p = participants[index];
          return ParticipantTile(participant: p, isLocal: p.id == localUserId);
        },
      ),
    );
  }
}
