import 'dart:io';

Future<void> buildRepository(String name, String url) =>
    Process.start("./build-repository.sh", [name, url]).then((p) async {
      p.stdout.listen(stdout.add);
      p.stderr.listen(stderr.add);
      await p.exitCode;
    });
