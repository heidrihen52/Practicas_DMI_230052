import 'package:flutter/material.dart';
import 'package:yes_no_app/config/helpers/get_yes_no_answer.dart';
import 'package:yes_no_app/domain/entities/message.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({GetYesNoAnswer? getYesNoAnswer})
    : getYesNoAnswer = getYesNoAnswer ?? GetYesNoAnswer();

  final chatScrollController = ScrollController();
  final GetYesNoAnswer getYesNoAnswer;
  bool _disposed = false;

  final List<Message> messageList = [];

  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _disposed) return;

    messageList.add(Message(text: trimmedText, fromWho: FromWho.me));
    notifyListeners();
    moveScrollToBottom();

    if (trimmedText.endsWith('?')) {
      await herReply();
    }
  }

  Future<void> herReply() async {
    Message reply;
    try {
      reply = await getYesNoAnswer.getAnswer();
    } catch (_) {
      reply = Message(
        text: 'No pude obtener una respuesta. Revisa tu conexión e inténtalo de nuevo.',
        fromWho: FromWho.hers,
      );
    }
    if (_disposed) return;
    messageList.add(reply);
    notifyListeners();
    moveScrollToBottom();
  }

  Future<void> moveScrollToBottom() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (_disposed || !chatScrollController.hasClients) return;
    await chatScrollController.animateTo(
      chatScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    chatScrollController.dispose();
    super.dispose();
  }
}
