package;

import haxe.io.Bytes;
import js.node.ChildProcess;

using StringTools;

enum abstract Action(String) {
	var Run = "run";
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
						case HaxelibRun:
							ChildProcess.exec("haxelib " + body.input, null, (_, stdout, stderr) -> {
								var r: Response = if (stderr.trim() == "") {
									status: Ok,
									output: (cast stdout : js.node.Buffer).toString(),
								} else {
									status: OhNo,
									error: (cast stderr : js.node.Buffer).toString(),
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
		var user = Sys.getEnv("HAXE_USER") ?? Sys.getEnv("USER");

		ChildProcess.exec('runuser -l $user -c "haxe params.hxml $hxml -cp $dir"', {timeout: 10000}, (error, stdout, stderr) -> {
			if (error?.signal == "SIGTERM") onError("Timed out, try again");
			if (stderr.trim() != "") onError((cast stderr : js.node.Buffer).toString());
			else onOutput((cast stdout : js.node.Buffer).toString());
			ChildProcess.exec('rm -rf $dir', null, null);
		});
	}
}
