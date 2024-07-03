use color_eyre::eyre::Result;
use owo_colors::OwoColorize;
use serde::{Deserialize, Serialize};
use serde_with::skip_serializing_none;
use tokio;

//const ENDPOINT: &str = "http://localhost:1337";

#[derive(Serialize, Deserialize, Debug)]
struct Test {
    action_name: String,
    valid_input_responses: Vec<(Request, Response)>,

}

#[skip_serializing_none]
#[derive(Serialize, Deserialize, Debug)]
struct Request {
    action: Option<String>,
    input: Option<String>,
    hxml: Option<String>,
}

impl Request {
    pub fn from_input(input: &str) -> Request {
        Request {
            action: None,
            input: Some(input.into()),
            hxml: None,
        }
    }
}

#[derive(Serialize, Deserialize, Debug)]
enum Status {
    Ok,
    OhNo,
}

#[skip_serializing_none]
#[derive(Serialize, Deserialize, Debug)]
struct Response {
    status: Status,
    output: Option<String>,
    error: Option<String>,
}

impl Response {
    pub fn from_success(output: &str) -> Response {
        Response {
            status: Status::Ok,
            output: Some(output.into()),
            error: None,
        }
    }
}

// Steps
// - Do concurrent valid requests
// - Do concurrent valid variables with random input
// - Do both random variables and random input

#[tokio::main]
async fn main() -> Result<()> {
    color_eyre::install()?;

    let tests = [
        Test {
            action_name: "run".into(),
            valid_input_responses: vec![(
                Request::from_input("class Main {static function main() {trace(9+10);}}"),
                Response::from_success("Main.hx:1: 19\n"),
            )],
        },
        Test {
            action_name: "haxelib_run".into(),
            valid_input_responses: vec![
                (
                    Request::from_input("install littleBigInt"),
                    Response::from_success("*Done\n"),
                ),
                (
                    Request::from_input("help"),
                    Response::from_success("*Haxe Library Manager"),
                ),
            ],
        },
    ];

    // Generate valid requests to test
    println!("{}", "> Generating valid requests".yellow());
    let mut valid_requests: Vec<String> = vec![];
    for mut test in tests {
        for r in &mut test.valid_input_responses {
            r.0.action = Some(test.action_name.to_owned());
            valid_requests.push(serde_json::to_string(&r.0)?);
        }
    }
    println!("{:?}", valid_requests);
    println!(
        "{} ({})",
        "> Done generating valid requests".green(),
        valid_requests.len().to_string().yellow()
    );

    Ok(())
}
