enum FromWho { me, hers }

class Message {
  final String text;
  final String? imageUrl;
  final FromWho fromWho;
  final DateTime sentAt;

  Message({
    required this.text,
    this.imageUrl,
    required this.fromWho,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();
}
