package;

import haxe.io.Bytes;
import js.node.ChildProcess;

using StringTools;

enum abstract Action(String) {
	var Run = "run";
}

enum abstract Status(String) {
	var Ok;
	var OhNo;
}

typedef Request = {
	action: Action,
	input: String,
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
					var body: Request = haxe.Json.parse(request.body);
					var r: Response;
					if (body.action != Run) throw "Invalid Action";
					runHaxe(body.input, (output) -> {
						r = {
							status: Ok,
							output: output,
						}
						sendResponse(response, r);
						resolve(response);
					}, (error) -> {
						r = {
							status: OhNo,
							error: error,
						};
						sendResponse(response, r);
						resolve(response);
					});
					
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

	static function runHaxe(src: String, onOutput: (String) -> Void, onError: (String) -> Void) {
		// Create a temporary folder in memory for holding the source
		final dir = new String(ChildProcess.spawnSync("mktemp", ["-d", "-p", "/dev/shm/"]).stdout).trim();
		sys.io.File.saveContent('$dir/Main.hx', src);
		ChildProcess.exec('haxe params.hxml -cp $dir', {timeout: 10000}, (error, stdout, stderr) -> {
			if (stderr != "") onError((cast stderr : js.node.Buffer).toString());
			if (stdout != "") onOutput((cast stdout : js.node.Buffer).toString());
			if (error?.signal == "SIGTERM") onError("Timed out, try again");
			ChildProcess.exec('rm -rf $dir', null, null);
		});
	}
}
