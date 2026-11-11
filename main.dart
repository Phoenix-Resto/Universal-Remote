import 'dart:async';
import 'dart:convert';
import 'dart:io';

const tvIp = '192.168.29.179';
const tvPort = 8002;
const appName = 'MyUniversalRemote';

final tokenFile = File('.secrets/samsung_token.txt');

const commands = <String, String>{
  'vol+': 'KEY_VOLUP',
  'vol-': 'KEY_VOLDOWN',
  'mute': 'KEY_MUTE',
  'ch+': 'KEY_CHUP',
  'ch-': 'KEY_CHDOWN',
  'home': 'KEY_HOME',
  'menu': 'KEY_MENU',
  'source': 'KEY_SOURCE',
  'up': 'KEY_UP',
  'down': 'KEY_DOWN',
  'left': 'KEY_LEFT',
  'right': 'KEY_RIGHT',
  'ok': 'KEY_ENTER',
  'back': 'KEY_RETURN',
  'exit': 'KEY_EXIT',
  'power': 'KEY_POWER',
};

Future<String?> loadToken() async {
  if (!await tokenFile.exists()) return null;

  final token = (await tokenFile.readAsString()).trim();
  return token.isEmpty ? null : token;
}

Future<void> saveToken(String token) async {
  await tokenFile.parent.create(recursive: true);
  await tokenFile.writeAsString(token);
}

Future<void> main() async {
  print('=== Samsung Universal Remote ===');

  final savedToken = await loadToken();

  print(
    savedToken == null
        ? 'No saved token. Pairing may be required.'
        : 'Saved token found.',
  );

  final name = base64Encode(utf8.encode(appName));

  final query = <String, String>{
    'name': name,
    if (savedToken != null) 'token': savedToken,
  };

  final url = Uri(
    scheme: 'wss',
    host: tvIp,
    port: tvPort,
    path: '/api/v2/channels/samsung.remote.control',
    queryParameters: query,
  ).toString();

  // Local development only.
  // This does NOT verify the TV's identity.
  final client = HttpClient()
    ..badCertificateCallback = (cert, host, port) =>
        host == tvIp && port == tvPort;

  WebSocket? socket;
  StreamSubscription<dynamic>? subscription;

  try {
    print('Connecting to Samsung TV...');

    socket = await WebSocket.connect(
      url,
      customClient: client,
    ).timeout(const Duration(seconds: 10));

    final pairing = Completer<bool>();

    subscription = socket.listen(
      (message) async {
        try {
          final response =
              jsonDecode(message.toString()) as Map<String, dynamic>;

          final event = response['event'];

          if (event == 'ms.channel.connect') {
            final data = response['data'];

            if (data is Map && data['token'] != null) {
              final token = data['token'].toString();
              await saveToken(token);
              print('Pairing token saved locally.');
            }

            if (!pairing.isCompleted) {
              pairing.complete(true);
            }
          } else if (event == 'ms.channel.unauthorized') {
            print('TV rejected the connection.');

            if (!pairing.isCompleted) {
              pairing.complete(false);
            }
          } else if (event == 'ms.error') {
            print('TV error: ${response['data']}');
          }
        } catch (e) {
          print('TV event processing error: $e');
          if (!pairing.isCompleted) {
            pairing.completeError(e);
          }
        }
      },
      onError: (Object error) {
        print('Connection error: $error');

        if (!pairing.isCompleted) {
          pairing.completeError(error);
        }
      },
      onDone: () {
        print('TV connection closed.');

        if (!pairing.isCompleted) {
          pairing.complete(false);
        }
      },
    );

    print('Approve on TV if prompted.');

    final approved = await pairing.future.timeout(const Duration(seconds: 60));

    if (!approved) {
      print('Pairing failed.');
      return;
    }

    print('\nTV CONNECTED!\n');
    print('Available commands:');
    print(commands.keys.join(', '));
    print('Type "quit" to exit.\n');

    stdout.write('Remote > ');

    await for (final line
        in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      final input = line.trim().toLowerCase();

      if (input == 'quit') break;

      final key = commands[input];

      if (key == null) {
        print('Unknown command: $input');
      } else if (socket.readyState != WebSocket.open) {
        print('TV connection is no longer open.');
        break;
      } else {
        final command = {
          'method': 'ms.remote.control',
          'params': {
            'Cmd': 'Click',
            'DataOfCmd': key,
            'Option': 'false',
            'TypeOfRemote': 'SendRemoteKey',
          },
        };

        socket.add(jsonEncode(command));
        print('Sent: $key');
      }

      stdout.write('Remote > ');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await subscription?.cancel();
    await socket?.close();
    client.close(force: true);
    print('\nRemote disconnected.');
  }
}
