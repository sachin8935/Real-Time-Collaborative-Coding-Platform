import { CronJob } from "cron";
import https from "https";

const backendUrl: string =
  "https://real-time-collaborative-coding-platform.onrender.com";

const job: CronJob = new CronJob("0 */14 * * * *", function () {
  // This function will be executed every 14 seconds.
  console.log("Restarting server");

  // Perform an HTTPS GET request to hit any backend API.
  https
    .get(backendUrl, (res) => {
      if (res.statusCode === 200) {
        console.log("Server restarted");
      } else {
        console.error(
          `Failed to restart server with status code: ${res.statusCode}`
        );
      }
    })
    .on("error", (err: Error) => {
      console.error("Error during Restart:", err.message);
    });
});

// Export the cron job.
export { job };
