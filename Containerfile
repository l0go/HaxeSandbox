FROM quay.io/fedora/fedora-minimal AS build
RUN microdnf install -y haxe
WORKDIR /app/src
COPY src ./src/
COPY vendor ./vendor/
COPY build.hxml ./
RUN haxe build.hxml -w -WDeprecated

FROM quay.io/fedora/fedora-minimal
RUN microdnf install -y nodejs haxe git
RUN useradd runner
RUN haxelib setup /var/haxelib
RUN mkdir /var/haxe
RUN chmod 755 /var/haxe
RUN chmod 755 /var/haxelib
WORKDIR /app/
COPY params.hxml /home/runner/params.hxml
COPY --from=build /app/src/bin/main.js ./
ENV HAXE_USER runner
ENV SOURCE_REPO /var/haxe/
CMD node main.js
