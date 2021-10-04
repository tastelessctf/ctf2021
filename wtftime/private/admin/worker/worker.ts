import * as kue from "kue";
import * as selenium from "selenium-webdriver";
import * as firefox from "selenium-webdriver/firefox";
import * as prom from "prom-client";
import * as sleep from "sleep";

const username = process.env.USERNAME || "admin";
const password = process.env.ADMIN_PW || "secret";
const worker_id = process.env.WORKER_ID || "default"

const gateway = new prom.Pushgateway(process.env.PUSHGATEWAY || "https://pushgateway:9091");
const execution_time = new prom.Histogram({
  name: 'wtftime_worker_execution_time',
  help: 'Worker Execution Time'
});

const executions = new prom.Counter({
  name: 'wtftime_worker_executions',
  help: 'Number of executions',
  labelNames: ['state']
})

const collectDefaultMetrics = prom.collectDefaultMetrics;
collectDefaultMetrics({ prefix: 'wtftime_' });

async function check_page(user_url: string) {
  const options = new firefox.Options();
  options.headless();
  let driver = await new selenium.Builder()
    .forBrowser("firefox")
    .setFirefoxOptions(options)
    .build();
  //driver.manage().timeouts().implicitlyWait(5, selenium.TimeUnit.SECONDS);
  try {
    let base_url = new URL(user_url);
    base_url.hash = '';
    console.log(`navigate to ${base_url.toString()}`)
    await driver.get(base_url.toString());
    sleep.sleep(1);
    console.log(`login("${username}", "${password}");`);
    await driver.executeScript(`console.log(login("${username}", "${password}"));`);
    sleep.sleep(1);
    console.log(`base`);
    await driver.get(user_url);
    sleep.sleep(1);
    console.log(`done`);
  } catch(e) {
    console.log("fail", e);
    executions.inc({state: 'failed'});
  } finally {
    await driver.quit();
  }
}

const queue = kue.createQueue({
  redis: process.env.REDIS || "redis://localhost:6379"
});

queue.process("report", function(
  job: { data: { url: string } },
  done: () => void
) {
  console.log(`checking page ${job.data.url}`);
  const stopTimer = execution_time.startTimer();
  check_page(job.data.url).then(() => {
    gateway.pushAdd({ jobName: worker_id }, function(_err, _resp, _body) {
      console.log(_err);
    });
    stopTimer();
    done();
  });
});
