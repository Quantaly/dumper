import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'webhook.dart';

const _hostname = '0.0.0.0';

Future<void> main(List<String> args) async {
  var port = int.tryParse(Platform.environment["PORT"] ?? "8080") ?? 8080;

  var app = Router();

  app.get("/", serveIndex);
  app.post("/webhook", handleWebhook);

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addMiddleware(denullify)
      .addHandler(app.handler);

  var server = await io.serve(handler, _hostname, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

shelf.Handler denullify(shelf.Handler innerHandler) => (request) {
      var maybeResp = innerHandler(request);
      if (maybeResp == null) {
        return shelf.Response.notFound("404 not found");
      } else if (maybeResp is Future<shelf.Response>) {
        return maybeResp
            .then((r) => r ?? shelf.Response.notFound("404 not found"));
      } else {
        return maybeResp;
      }
    };

Future<shelf.Response> serveIndex(shelf.Request request) async {
  var htmls = await Future.wait([
    File("templates/index.html").readAsString(),
    File("README.md").readAsString().then((s) =>
        md.markdownToHtml(s, extensionSet: md.ExtensionSet.gitHubFlavored))
  ]);
  var body = htmls[0].replaceFirst("{{README}}", htmls[1]);
  return shelf.Response.ok(body, headers: {
    "Content-Type": "text/html",
  });
}
