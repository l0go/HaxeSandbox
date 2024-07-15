package;

import haxe.io.Bytes;
import haxe.crypto.Sha256;
import js.node.ChildProcess;

using StringTools;

enum abstract Action(String) {
	var Run = "run";
	var HaxeVersion = "haxe_version";
	var HaxelibRun = "haxelib_run";
}

enum abstract Status(String) {
	var Ok;
	var OhNo;
}

typedef Request = {
	action: Action,
	?input: String,
	?hxml: String,
};

typedef Response = {
	status: Status,
	?output: Null<String>,
	?error: Null<String>,
};

class Main {
	static function main() {
		logging.LogManager.instance.addAdaptor(new logging.adaptors.ConsoleLogAdaptor({
			formatter: new logging.formatters.PrettyANSIFormatter(),
		}));
		var log = new logging.Logger(Main);

		var server = new http.server.HttpServer();
		server.onRequest = (request, response) -> {
			return new promises.Promise((resolve, reject) -> {
				final authKey = Sys.getEnv("AUTH_KEY");
				if (authKey != null && Sha256.encode(Std.string(request.headers.get("authorization")).split(" ")[1]) != authKey) {
					throw "Authorization Token Invalid";
				}
				if (request.method == http.HttpMethod.Post) {
					final body: Request = haxe.Json.parse(request.body);
					switch (body.action) {
						case Run:
							if (body.action != Run) throw "Invalid Action";
							runHaxe(body.input, body.hxml ?? "", (output) -> {
								final r = {
									status: Ok,
									output: output,
								}
								sendResponse(response, r);
								resolve(response);
							}, (error) -> {
								final r = {
									status: OhNo,
									error: error,
								};
								sendResponse(response, r);
								resolve(response);
							});
						case HaxeVersion:
							final hl = ChildProcess.spawn("haxe", ["--version"]);

							var version: String;
							hl.stdout.on("data", (d) -> {
								version = (cast d : js.node.Buffer).toString();
							});

							hl.on('exit', (code) -> {
								final r = {
									status: Ok,
									output: version.trim(),
								};
								sendResponse(response, r);
								resolve(response);
							});
						case HaxelibRun:
							var process = ChildProcess.spawn("haxelib", body.input.split(" "), untyped {timeout: 60000});
							var stdout = "";
							process.stdout.on('data', (data) -> {
								stdout += data;
							});

							process.on("close", (code) -> {
								var r: Response = if (code == 0) {
									status: Ok,
									output: (cast stdout : js.node.Buffer).toString(),
								} else {
									status: OhNo,
									error: (cast stdout : js.node.Buffer).toString(),
								};
								sendResponse(response, r);
								resolve(response);
							});
						default:
							throw "Action doesn't exist";
					}
				} else {
					var error = new http.HttpError(405);
					error.body = Bytes.ofString("405, method not found");
					reject(error);
					return;
				}
			});
		};

		final port = Std.parseInt(Sys.getEnv("PORT")) ?? 1111;
		server.start(port);
		log.info(":)");
		log.info("Server running!", {address: "127.0.0.1", port: port});
	}

	static function sendResponse(response: http.HttpResponse, with: Response) {
		response.headers.set("Content-Type", "application/json");
		response.httpStatus = http.HttpStatus.Success;
		response.write(haxe.Json.stringify(with));
	}

	static function runHaxe(src: String, hxml: String, onOutput: (String) -> Void, onError: (String) -> Void) {
		// This is the folder where we keep the different source folders
		final sourceRepository = Sys.getEnv("SOURCE_REPO") ?? "/dev/shm/";

		// Create a temporary folder in memory for holding the source
		final dir = new String(ChildProcess.spawnSync("mktemp", ["-d", "-p", sourceRepository]).stdout).trim();

		sys.io.File.saveContent('$dir/Main.hx', src);
		ChildProcess.exec('chmod 755 $dir/', null, null);
		ChildProcess.exec('chmod 755 $dir/Main.hx', null, null);

		final user = Sys.getEnv("HAXE_USER") ?? Sys.getEnv("USER");
		final uid = Std.parseInt(ChildProcess.execSync('id -u $user'));

		final hxmlSplit = [for (c in hxml.split(" ")) if (c.trim() != "") c];
		final process = ChildProcess.spawn("haxe", ["params.hxml"].concat(hxmlSplit).concat(["-cp", dir]), untyped {uid: uid, timeout: 3000, cwd: '/home/$user'});

		var stdout = "";
		process.stdout.on('data', (data) -> {
			stdout += data;
		});

		var stderr = "";
		process.stderr.on('data', (data) -> {
			stderr += data;
		});

		process.on("close", (code) -> {
			switch (code) {
				case 0: onOutput((cast stdout : js.node.Buffer).toString());
				case null: onError("Timed out, try again");
				default: onError((cast stderr : js.node.Buffer).toString());
			}
			ChildProcess.exec('rm -rf $dir', null, null);
		});
	}
}
