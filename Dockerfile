FROM google/dart:2.6.1

ADD home-files/** /root

WORKDIR /app

ADD pubspec.* /app/
RUN pub get
ADD . /app
RUN pub get --offline

RUN dart2native /app/bin/server.dart -k aot

CMD []
ENTRYPOINT ["dartaotruntime", "/app/bin/server.aot"]