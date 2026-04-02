FROM quay.io/fedora/fedora-minimal:43 AS build
RUN microdnf install -y aria2 tar gzip
WORKDIR /app/haxe
RUN aria2c https://github.com/HaxeFoundation/haxe/releases/download/4.3.7/haxe-4.3.7-linux64.tar.gz --out=haxe.tar.gz
RUN tar -xzf haxe.tar.gz -C . --strip-components=1
RUN rm haxe.tar.gz
WORKDIR /app/src
ENV PATH="$PATH:/app/haxe"
ENV HAXE_STD_PATH="/app/haxe/std/"
COPY src ./src/
COPY vendor ./vendor/
COPY build.hxml ./
RUN haxe build.hxml -w -WDeprecated

FROM quay.io/fedora/fedora-minimal:43
RUN microdnf install -y nodejs git neko
COPY --from=build /app/haxe /app/haxe
ENV PATH="$PATH:/app/haxe"
ENV HAXE_STD_PATH="/app/haxe/std/"
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
