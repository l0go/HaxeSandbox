FROM quay.io/fedora/fedora AS build
RUN dnf install -y haxe
WORKDIR /app/src
COPY src ./src/
COPY vendor ./vendor/
copy build.hxml ./
RUN ls
RUN haxe build.hxml -w -WDeprecated

FROM quay.io/fedora/fedora
RUN dnf install -y nodejs haxe
WORKDIR /app/
COPY params.hxml ./
COPY --from=build /app/src/bin/main.js ./
CMD node main.js
