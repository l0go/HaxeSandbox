build-podman:
	podman build -t=haxesandbox .
run-podman:
	podman run --rm -p=1337:1111 --mount type=tmpfs,destination=/var/haxelib,tmpfs-size=500000000 --mount type=tmpfs,destination=/var/haxe,tmpfs-size=500000000 --read-only --read-only-tmpfs=False haxesandbox:latest
