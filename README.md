# HaxeSandbox
Use podman to run untrusted Haxe code in a read-only container.

## Why?
Once upon a time there was a man who made a chatbot that ran arbitrary Haxe code. He thought that he did enough precautions, he even ran the code in a V8 "sandbox!" While most used it for good, a certain individual (we'll call them B) decided to utilize a known vulnerability in the sandbox to create inappropriate (absolutely despicable!) files on the server. B's actions made the Man furious! He shut down that feature of the chatbot for good. All hope was saved when the heroic logo spent a hour making a Podman container that runs a http api for Haxe compilation.

## How?
1. Install Podman, it is included on Fedora Server installs and presumably most RHEL-based distros
2. Run the magic command to download and run the container:
```bash
podman run --rm -d -p=1337:1111 --read-only ghcr.io/l0go/haxesandbox:latest
```
- Alternatively if you wish to run the container on server boot, you can utilize systemd's Quadlet feature. Just copy ``etc/haxesandbox.container`` in this repository to ``/etc/containers/systemd/`` and run ``systemctl daemon-reload``. This will generate a systemd service.
3. Send a request to the server
```bash
curl -d '
{
    "action": "run",
    "input" : "class Main {static function main() {trace(9+10);}}"
}' http://localhost:1337/
```
- In the real world, you can use Haxe's http functionality or the core-haxe/http library

## Things to note
There are temporary filesystems inside the container that can still be read and written to from a Haxe program, even in read-only mode. One of these, ``/dev/shm/`` is used to temporarily store the Haxe program source while it is running. Hence, treat any source provided over the request as public when it is getting ran.
