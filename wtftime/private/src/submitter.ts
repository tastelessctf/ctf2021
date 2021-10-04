import readline from "readline";
import os from "os";
import * as kue from "kue";

let rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false,
});

let host = process.env['HOST'];
let port = process.env['PORT'];

const queue = kue.createQueue({
  redis: process.env.REDIS || "redis://localhost:6379",
});

console.log(
  `Hello! Your WTFTime instance is listening on http://${host}.wtftime.tasteless.eu:${port}/`
);
console.log(
  `If you find some interesting WTFs, just paste them here. I'll go take a look at them.`
);

rl.on("line", function (line) {
  try {
    new URL(line);
  } catch (_) {
    console.log("That doesn't look like a URL to me!");
    return;
  }

  let url = new URL(line);
  if (
    url.hostname != `${host}.wtftime.tasteless.eu` ||
    url.protocol != "http:" ||
    url.port != `${port}`
  ) {
    console.log(`I am only interested in WTFs!`);
  } else
    queue
      .create("report", {
        url: line,
      })
      .save(function (err: any) {
        if (err) {
          console.log(`Nope, not going to look at it right now.`);
        } else {
          console.log(`Going to take a look at it.`);
        }
      });
});
