import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';

import 'git.dart';

final _secureRand = math.Random.secure();

Future<Response> handleWebhook(Request request) async {
  var body = await collectBytes(request.read());

  // verify X-Hub-Signature
  try {
    verifyKey(request.headers["x-hub-signature"], body);
  } on Response catch (r) {
    // don't leak timing information
    // this is apparently v important
    print("got a bad signature bro");
    await Future.delayed(
        Duration(microseconds: _secureRand.nextInt(100 * 1000)));
    return r;
  }

  var bodyText = utf8.decode(body);

  print("got an event: ${request.headers["x-github-event"]}");
  print(bodyText);

  if (request.headers["x-github-event"] == "push") {
    var bodyJson = jsonDecode(utf8.decode(body));

    if (bodyJson["ref"] == "refs/heads/master") {
      print("looks like you just pushed to master on "
          "${bodyJson["repository"]["full_name"]}");

      _unawaited(buildRepository(
          bodyJson["repository"]["full_name"], bodyJson["repository"]["url"]));
    } else {
      print("looks like you just pushed to NOT master on "
          "${bodyJson["repository"]["full_name"]}");
    }
  }

  return Response(204);
}

final _sig = RegExp("sha1=([0-9A-Fa-f]{40})");
final _key =
    UnmodifiableListView(utf8.encode(Platform.environment["WEBHOOK_SECRET"]));
final _hmac = Hmac(sha1, _key);
const _lequal = ListEquality();

void verifyKey(String xHubSignature, List<int> body) {
  var match = _sig.firstMatch(xHubSignature);
  if (match == null) {
    throw Response(400, body: "bad X-Hub-Signature header");
  }

  var sigBytes = hex.decode(match.group(1));
  var digest = _hmac.convert(body);
  if (!_lequal.equals(sigBytes, digest.bytes)) {
    throw Response.forbidden("incorrect signature, nice try");
  }
}

// Importing pedantic is for suckers.
void _unawaited(Future f) {}
