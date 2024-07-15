# HaxeSandbox
Use Podman to run untrusted Haxe code in a read-only container.

## Why?
Once upon a time there was a man who made a chatbot that ran arbitrary Haxe code. He thought that he did enough precautions, he even ran the code in a V8 "sandbox!" While most used it for good, a certain individual (we'll call them B) decided to utilize a known vulnerability in the sandbox to create inappropriate (absolutely despicable!) files on the server. B's actions made the Man furious! He shut down that feature of the chatbot for good. All hope was saved when the heroic logo spent a hour making a Podman container that runs a http api for Haxe compilation.

## How?
1. Install Podman, it is included on Fedora Server installs and presumably most RHEL-based distros
2. Run this command and save the outputs somewhere safe
```bash
b64=`cat /dev/urandom | head -c 24 | base64`; echo "BASE64: $b64\n"; sum=`printf "%s" $b64 | sha256sum | cut -f 1 -d " "`; echo "SHA256: $sum"
```
3. Run the magic command to download and run the container. Make sure to replace ``{SHA256_KEY}`` with the SHA256 key from the previous command.
```bash
podman run --rm --env -p=1337:1111 --env `AUTH_KEY={SHA256_KEY}` --mount type=tmpfs,destination=/var/haxelib,tmpfs-size=500000000 --mount type=tmpfs,destination=/var/haxe,tmpfs-size=500000000 --read-only --read-only-tmpfs=False ghcr.io/l0go/haxesandbox:latest
```
- Alternatively if you wish to run the container on server boot, you can utilize systemd's Quadlet feature. Just copy ``etc/haxesandbox.container`` in this repository to ``/etc/containers/systemd/`` and run ``systemctl daemon-reload``. This will generate a systemd service. Make sure to replace the ``SHA256_KEY`` in the ``haxesandbox.container`` file too.
4. Send a request to the server, change {BASE64} to the base64 key generated from the second command.
```bash
curl -d '
{
    "action": "run",
    "input" : "class Main {static function main() {trace(9+10);}}"
}' -H "Authorization: Basic {BASE64}" http://localhost:1337/
```
- In the real world, you can use Haxe's http functionality or the core-haxe/http library

## Things to note
- While the Haxe code is being ran, it will be readable by any other Haxe code. Treat any input as if it was public.
- Docker should work as well for most of the above steps, I just prefer Podman and it is what I test with.
- Consider using a distribution with SELinux such as a RHEL derivative or Fedora. Podman integrates well with it better than AppArmor which Ubuntu uses.
