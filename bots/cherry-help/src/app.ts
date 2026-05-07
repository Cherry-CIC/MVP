import { App } from '@slack/bolt';
import { getAnswer } from './answer';

const SLACK_BOT_TOKEN = process.env.SLACK_BOT_TOKEN ?? '';
const SLACK_APP_TOKEN = process.env.SLACK_APP_TOKEN ?? '';
const ALLOWED_CHANNELS = (process.env.ALLOWED_CHANNEL_IDS ?? '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

if (!SLACK_BOT_TOKEN || !SLACK_APP_TOKEN) {
  console.error('Missing SLACK_BOT_TOKEN or SLACK_APP_TOKEN');
  process.exit(1);
}

const app = new App({
  token: SLACK_BOT_TOKEN,
  appToken: SLACK_APP_TOKEN,
  socketMode: true,
});

function isAllowedChannel(channelId: string): boolean {
  if (ALLOWED_CHANNELS.length === 0) return true;
  return ALLOWED_CHANNELS.includes(channelId);
}

// Handle @mentions in channels
app.event('app_mention', async ({ event, say }) => {
  if (!isAllowedChannel(event.channel)) return;
  const question = event.text.replace(/<@[^>]+>\s*/g, '').trim();
  const reply = getAnswer(question);
  await say({ text: reply, thread_ts: event.ts });
});

// Handle direct messages
app.message(async ({ message, say }) => {
  const msg = message as { bot_id?: string; text?: string; channel_type?: string };
  if (msg.bot_id) return; // ignore bots
  if (msg.channel_type !== 'im') return; // DMs only
  const question = (msg.text ?? '').trim();
  if (!question) return;
  const reply = getAnswer(question);
  await say({ text: reply });
});

(async () => {
  await app.start();
  console.log('cherry-help is running');
})();
