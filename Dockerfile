FROM google/dart:2.5.2

ADD home-files/** /root

WORKDIR /app

ADD pubspec.* /app/
RUN pub get
ADD . /app
RUN pub get --offline

RUN dart2aot /app/bin/server.dart /app/bin/server.dart.aot

CMD []
ENTRYPOINT ["dartaotruntime", "/app/bin/server.dart.aot"]