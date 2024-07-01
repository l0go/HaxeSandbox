FROM quay.io/fedora/fedora AS build
RUN dnf install -y haxe
WORKDIR /app/src
COPY src ./src/
COPY vendor ./vendor/
copy build.hxml ./
RUN haxe build.hxml -w -WDeprecated

FROM quay.io/fedora/fedora
RUN dnf install -y nodejs haxe
RUN useradd runner
RUN haxelib setup /var/haxelib
RUN mkdir /var/haxe
RUN chmod 755 /var/haxe
WORKDIR /app/
COPY params.hxml /home/runner/params.hxml
COPY --from=build /app/src/bin/main.js ./
ENV HAXE_USER runner
ENV SOURCE_REPO /var/haxe/
CMD node main.js
