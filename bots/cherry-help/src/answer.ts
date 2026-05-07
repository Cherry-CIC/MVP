import * as fs from 'fs';
import * as path from 'path';

const FAQ_PATH = path.join(__dirname, '..', 'content', 'volunteer-faq.md');

const REFUSED_PATTERNS = [
  /secret/i,
  /password/i,
  /token/i,
  /api[_\s-]?key/i,
  /credential/i,
  /admin.{0,20}bypass/i,
];

const NO_SOURCE_REPLY =
  "I don't know from the approved cherry docs yet. " +
  'Please ask the volunteer lead, and we can add the answer to the volunteer FAQ afterwards.';

const LEAD_FOOTER = '\n\nIf this doesn\'t look right, ask the volunteer lead to check it.';

function loadFaq(): string {
  try {
    return fs.readFileSync(FAQ_PATH, 'utf8');
  } catch {
    return '';
  }
}

function findFaqAnswer(question: string, faq: string): string | null {
  const lines = faq.split('\n');
  const q = question.toLowerCase();
  let currentHeading = '';
  let capture = false;
  const snippets: string[] = [];

  for (const line of lines) {
    if (line.startsWith('#')) {
      if (capture && snippets.length) break;
      currentHeading = line.replace(/^#+\s*/, '');
      capture = currentHeading.toLowerCase().split(/\s+/).some((w) => q.includes(w) && w.length > 3);
    } else if (capture && line.trim()) {
      snippets.push(line.trim());
      if (snippets.length >= 4) break;
    }
  }

  if (!snippets.length) return null;
  return `${snippets.join(' ')}\n\nSource: volunteer-faq.md – ${currentHeading}`;
}

export function getAnswer(question: string): string {
  if (REFUSED_PATTERNS.some((p) => p.test(question))) {
    return 'I can\'t help with that — it looks like it might involve credentials or security details. Please speak to the volunteer lead directly.';
  }

  const faq = loadFaq();
  const faqAnswer = findFaqAnswer(question, faq);
  if (faqAnswer) {
    return faqAnswer + LEAD_FOOTER;
  }

  return NO_SOURCE_REPLY;
}
