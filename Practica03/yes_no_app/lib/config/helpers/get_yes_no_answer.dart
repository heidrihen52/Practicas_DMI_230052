import 'dart:math';

import 'package:dio/dio.dart';
import 'package:yes_no_app/domain/entities/message.dart';
import 'package:yes_no_app/infrastructure/models/yes_no_model.dart';

class GetYesNoAnswer {
  GetYesNoAnswer({Dio? dio, Random? random})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          ),
      _random = random ?? Random();

  final Dio _dio;
  final Random _random;

  Future<Message> getAnswer() async {
    // Diez resultados equiprobables: cuatro sí, cuatro no y dos tal vez.
    final value = _random.nextInt(10);
    final answer = value < 4 ? 'yes' : (value < 8 ? 'no' : 'maybe');
    final response = await _dio.get<Map<String, dynamic>>(
      'https://yesno.wtf/api',
      queryParameters: {'force': answer},
    );
    final yesNoModel = YesNoModel.fromJsonMap(response.data!);
    return yesNoModel.toMessageEntity();
  }
}
