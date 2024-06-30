build-podman:
	podman build -t=haxesandbox .
run-podman:
	podman run --rm -p=1337:8000 --read-only haxesandbox:latest
