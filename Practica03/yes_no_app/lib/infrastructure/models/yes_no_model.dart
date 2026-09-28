import 'package:yes_no_app/domain/entities/message.dart';

class YesNoModel {
  YesNoModel({required this.answer, required this.forced, required this.image});

  final String answer;
  final bool forced;
  final String image;

  factory YesNoModel.fromJsonMap(Map<String, dynamic> json) => YesNoModel(
    answer: json["answer"],
    forced: json["forced"],
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "answer": answer,
    "forced": forced,
    "image": image,
  };

  Message toMessageEntity() => Message(
    text: switch (answer) {
      'yes' => 'Sí',
      'no' => 'No',
      'maybe' => 'Tal vez',
      _ => throw FormatException('Respuesta desconocida: $answer'),
    },
    fromWho: FromWho.hers,
    imageUrl: image,
  );
}
