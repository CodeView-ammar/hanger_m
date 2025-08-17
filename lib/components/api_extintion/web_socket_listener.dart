import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketListener {
  final WebSocketChannel channel;

  WebSocketListener(String url) : channel = WebSocketChannel.connect(Uri.parse(url));

  void listen(Function(String) onMessage, {required Null Function() onDone, required Null Function(dynamic error) onError}) {
    channel.stream.listen((message) => onMessage(message as String));
  }

  void send(String message) {
    channel.sink.add(message);
  }

  void dispose() {
    channel.sink.close();
  }
}