import { WebClient } from "@slack/web-api";

const slack = new WebClient(process.env.SLACK_BOT_TOKEN);

type SlackEvent =
  | { type: "CHECK_IN" | "CHECK_OUT" | "BREAK_IN" | "BREAK_OUT"; user: string; time: string; report?: string }
  | { type: "LEAVE_REQUEST"; user: string; start: string; end: string; reason: string }
  | { type: "LINKEDIN_PENDING"; adminSlackId: string; userName: string; preview: string }
  | { type: "LINKEDIN_APPROVED"; userSlackId: string; adminName: string; scheduledAt?: Date | null }
  | { type: "LINKEDIN_REJECTED"; userSlackId: string; adminName: string; reason: string };

export async function sendSlackNotification(event: SlackEvent) {
  if (!process.env.SLACK_BOT_TOKEN || process.env.SLACK_BOT_TOKEN.includes("your-token")) {
    console.log("Slack token not configured. Skipping notification.");
    return;
  }

  const reportChannel = process.env.SLACK_REPORT_CHANNEL || "";
  const testChannel = process.env.SLACK_TEST_CHANNEL || "";

  let text = "";
  let channel = testChannel;

  switch (event.type) {
    case "CHECK_IN":
      text = `🚀 *Check-In*: ${event.user} started their day at ${event.time}.`;
      channel = reportChannel;
      break;
    case "CHECK_OUT":
      text = `🏁 *Check-Out*: ${event.user} finished their day at ${event.time}.\n\n*Daily Report*:\n${event.report || "No report provided."}`;
      channel = reportChannel;
      break;
    case "BREAK_IN":
      text = `☕ *Break-In*: ${event.user} is taking a break at ${event.time}.`;
      break;
    case "BREAK_OUT":
      text = `💻 *Break-Out*: ${event.user} is back to work at ${event.time}.`;
      break;
    case "LEAVE_REQUEST":
      text = `📅 *New Leave Request*\n*User*: ${event.user}\n*Period*: ${event.start} to ${event.end}\n*Reason*: ${event.reason}`;
      break;
    case "LINKEDIN_PENDING":
      channel = event.adminSlackId;
      text = `📝 *New LinkedIn post awaiting approval* from ${event.userName}\nPreview: ${event.preview}...\nReview at: /dashboard/admin/linkedin`;
      break;
    case "LINKEDIN_APPROVED":
      channel = event.userSlackId;
      text = `✅ Your LinkedIn post was *approved* by ${event.adminName}${
        event.scheduledAt
          ? ` and scheduled for ${new Date(event.scheduledAt).toDateString()}`
          : " and will publish soon"
      }.`;
      break;
    case "LINKEDIN_REJECTED":
      channel = event.userSlackId;
      text = `❌ Your LinkedIn post was *rejected* by ${event.adminName}.\nReason: ${event.reason}`;
      break;
  }

  try {
    await slack.chat.postMessage({
      channel,
      text,
      blocks: [
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text,
          },
        },
      ],
    });
  } catch (error) {
    console.error("Failed to send Slack notification:", error);
  }
}
