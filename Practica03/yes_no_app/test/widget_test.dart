import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_no_app/config/helpers/get_yes_no_answer.dart';
import 'package:yes_no_app/domain/entities/message.dart';
import 'package:yes_no_app/presentation/providers/chat_provider.dart';
import 'package:yes_no_app/presentation/widgets/chat/her_message_bubble.dart';
import 'package:yes_no_app/presentation/widgets/chat/my_message_bubble.dart';

class SequenceRandom implements Random {
  int value = 0;
  @override
  int nextInt(int max) => value++ % max;
  @override
  bool nextBool() => throw UnimplementedError();
  @override
  double nextDouble() => throw UnimplementedError();
}

void main() {
  test(
    '40% Sí, 40% No y 20% Tal vez solicitan su GIF correspondiente',
    () async {
      final dio = Dio();
      final requested = <String>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final answer = options.queryParameters['force'] as String;
            requested.add(answer);
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'answer': answer,
                  'forced': true,
                  'image': 'https://example.com/$answer.gif',
                },
              ),
            );
          },
        ),
      );
      final service = GetYesNoAnswer(dio: dio, random: SequenceRandom());
      final counts = <String, int>{};
      for (var i = 0; i < 10; i++) {
        final before = DateTime.now();
        final message = await service.getAnswer();
        counts.update(message.text, (count) => count + 1, ifAbsent: () => 1);
        expect(message.imageUrl, 'https://example.com/${requested.last}.gif');
        expect(message.sentAt.isBefore(before), isFalse);
      }
      expect(counts, {'Sí': 4, 'No': 4, 'Tal vez': 2});
      dio.close();
    },
  );

  test(
    'Solo las preguntas generan respuestas y los fallos se muestran en el chat',
    () async {
      final dio = Dio();
      var calls = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            calls++;
            handler.reject(DioException(requestOptions: options));
          },
        ),
      );
      final provider = ChatProvider(getYesNoAnswer: GetYesNoAnswer(dio: dio));
      await provider.sendMessage('   ');
      expect(provider.messageList, isEmpty);
      await provider.sendMessage('Hola');
      expect(calls, 0);
      await provider.sendMessage('¿Está funcionando?   ');
      expect(calls, 1);
      expect(provider.messageList[1].text, '¿Está funcionando?');
      expect(provider.messageList.last.text, contains('Revisa tu conexión'));
      expect(provider.messageList.last.imageUrl, isNull);
      provider.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      dio.close();
    },
  );

  testWidgets('Ambas burbujas muestran la hora guardada en formato HH:mm', (
    tester,
  ) async {
    final sentAt = DateTime(2026, 9, 28, 9, 5);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MyMessageBubble(
                message: Message(
                  text: '¿Hola?',
                  fromWho: FromWho.me,
                  sentAt: sentAt,
                ),
              ),
              HerMessageBubble(
                message: Message(
                  text: 'Tal vez',
                  fromWho: FromWho.hers,
                  sentAt: sentAt,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('09:05'), findsNWidgets(2));
    expect(find.text('Tal vez'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
